local enigma = get_mod("Enigma")

-- Table functions
table.deep_copy = function(tbl, max_depth)
    local inst = table.shallow_copy(tbl)
    if max_depth <= 0 then
        return inst
    end
    for k,v in pairs(tbl) do
        if type(v) == "table" then
            inst[k] = table.deep_copy(v, max_depth-1)
        end
    end
    return inst
end



enigma.echo_bad_function_call = function(self, func_name, bad_param_name, details)
    local params_details = "("
    local first = true
    for k,v in pairs(details) do
        local name = tostring(k)
        local val = tostring(v)
        if not first then
            params_details = params_details..","
        end
        params_details = params_details..name.."=\""..val.."\""
        first = false
    end
    params_details = params_details..")"
    enigma:echo("Enigma function call \""..func_name.."\" called with invalid parameter \""..bad_param_name.."\" "..params_details)
end

enigma.is_server = function(self)
    return Managers.player and Managers.player.is_server
end

enigma.local_peer_id = function(self)
    return Network and Network.peer_id()
end
enigma.is_peer_local = function(self, peer_id)
    return peer_id == self:local_peer_id()
end

enigma.level_key = function(self)
    return Managers.state and Managers.state.game_mode:level_key() or Managers.level_transition_handler and Managers.level_transition_handler:get_current_level_key()
end
enigma.in_inn = function(self)
    local level_key = Managers.state and Managers.state.game_mode:game_mode_key()
    return level_key and level_key:find("inn")
end
enigma.in_morris_hub = function(self)
    local level_key = Managers.state and Managers.state.game_mode:game_mode_key()
    return level_key == "morris_hub"
end
enigma.in_keep = function(self)
    return enigma:in_inn() or enigma:in_morris_hub()
end
enigma.in_morris_map = function(self)
    local level_key = Managers.state and Managers.state.game_mode:game_mode_key()
    return level_key == "dlc_morris_map"
end
enigma.traveling_to_inn = function(self)
    local level_key = Managers.level_transition_handler and Managers.level_transition_handler:get_current_level_key()
    return level_key:find("inn_level")
end
enigma.traveling_to_morris_hub = function(self)
    local level_key = Managers.level_transition_handler and Managers.level_transition_handler:get_current_level_key()
    return level_key == "morris_hub"
end
enigma.traveling_to_morris_map = function(self)
    local level_key = Managers.level_transition_handler and Managers.level_transition_handler:get_current_level_key()
    return level_key == "dlc_morris_map"
end

enigma.game_mode = function(self)
    local level_key = self:level_key()
    local game_mode_key
    if level_key == "inn_level" then
        game_mode_key = "adventure"
    elseif level_key == "morris_hub" or level_key == "dlc_morris_map" then
        game_mode_key = "deus"
    end
    enigma:info("Game mode: "..tostring(game_mode_key or Managers.state and Managers.state.game_mode and Managers.state.game_mode:game_mode_key()))
    return game_mode_key or Managers.state and Managers.state.game_mode and Managers.state.game_mode:game_mode_key()
end
enigma.is_game_mode_supported = function(self, game_mode_key)
    return game_mode_key == "adventure" or game_mode_key == "deus"
end

enigma.local_player = function(self)
    return Managers.player and Managers.player:local_human_player()
end

enigma.local_player_unit = function(self)
    local player = self:local_player()
    return player and player.player_unit
end

enigma.local_player_career_name = function(self)
    local player = self:local_player()
    return player and player:career_name()
end

enigma.player_and_bot_units = function(self)
    local side = Managers.state and Managers.state.side and Managers.state.side:get_side_from_name("heroes")
	return side and side.PLAYER_AND_BOT_UNITS
end
enigma.force_damage = function(self, unit, damage, damager)
    damager = damager or unit
    local health_ext = ScriptUnit.extension(unit, "health_system")
    
    local breed = Unit.get_data(unit, "breed")
    local breed_name = breed and breed.name
    enigma:info("DAMAGING "..tostring(breed_name).." for "..tostring(damage))

    health_ext:add_damage(damager, damage, "full", "forced", nil, Vector3.up())
end
enigma.heal = function(self, unit, heal, healer, heal_type)
    if not enigma:is_server() then
        enigma:warning("Only the server can heal")
        return false
    end
    healer = healer or unit
    heal_type = heal_type or "health_regen"

    local breed = Unit.get_data(unit, "breed")
    local breed_name = breed and breed.name
    enigma:info("HEALING "..tostring(breed_name).." for "..tostring(heal))

    DamageUtils.heal_network(unit, healer, heal, heal_type)
end

enigma.get_ammo_extension = function(self, unit)
    if ScriptUnit.has_extension(unit, "ammo_system") then
        return ScriptUnit.extension(unit, "ammo_system")
    end
    if ScriptUnit.has_extension(unit, "inventory_system") then
        local weapon_slot = "slot_ranged"
        local inv_ext = ScriptUnit.extension(unit, "inventory_system")
        local slot_data = inv_ext:get_slot_data(weapon_slot)
        local right_unit_1p = slot_data.right_unit_1p
        local left_unit_1p = slot_data.left_unit_1p
        local right_hand_ammo_extension = ScriptUnit.has_extension(right_unit_1p, "ammo_system")
        local left_hand_ammo_extension = ScriptUnit.has_extension(left_unit_1p, "ammo_system")
        return right_hand_ammo_extension or left_hand_ammo_extension
    end
end

enigma.execute_unit = function(self, to_execute, executor)
    if not HEALTH_ALIVE[to_execute] then
        return false
    end
    AiUtils.kill_unit(to_execute, executor, nil, "execute")
    return true
end

enigma.is_enemy_man_sized = function(self, unit)
    if not HEALTH_ALIVE[unit] then
        return false
    end
    local breed = Unit.get_data(unit, "breed")
    return breed and not breed.boss
end
enigma.execute_man_sized_enemy = function (self, to_execute, executor)
    if not self:is_enemy_man_sized(to_execute) then
        return false
    end
    return enigma:execute_unit(to_execute, executor)
end

enigma.distance_between_units = function(self, unit1, unit2)
    if not unit1 or not unit2 then
        enigma:warning("Cannot get the distance between units: "..tostring(unit1).." and "..tostring(unit2))
        return
    end
    return Vector3.distance(Unit.world_position(unit1, 0), Unit.world_position(unit2, 0))
end

enigma.get_level_progress = function(self)
    local conflict = Managers.state.conflict

    local traveled = conflict and conflict.main_path_info and conflict.main_path_info.ahead_travel_dist
    local total = conflict and conflict.level_analysis and conflict.level_analysis.main_path_data and conflict.level_analysis.main_path_data.total_dist
    if traveled and total then
        return traveled/total
    end

    return nil
end

enigma.get_units_in_sphere = function(self, center, radius, unit_type)
    unit_type = unit_type or "all"
    local results = {}
    enigma:info("Getting units in sphere. radius="..tostring(radius)..", center="..tostring(center))
    if unit_type == "all" or unit_type == "ai" then
        AiUtils.broadphase_query(center, radius, results)
        enigma:info("ai units in radius: "..tostring(#results))
    end
    if unit_type == "all" or unit_type == "player" then
        local side = Managers.state.side:get_side_from_name("heroes")
        local other_player_positions = side.PLAYER_AND_BOT_POSITIONS
    
        for i = 1, #other_player_positions do
            local other_player_position = other_player_positions[i]
            local radius_squared = math.pow(radius, 2)
            local distance_squared = Vector3.distance_squared(center, other_player_position)
    
            if distance_squared <= radius_squared then
                table.insert(results, side.PLAYER_AND_BOT_UNITS[i])
                local breed = Unit.get_data(side.PLAYER_AND_BOT_UNITS[i], "breed")
                enigma:info("player unit in radius: "..tostring(breed and breed.name or "unknown career"))
            end
        end
    end
    return results
end

enigma.get_ai_units_in_sphere = function(self, center, radius)
    return enigma:get_units_in_sphere(center, radius, "ai")
end
enigma.get_player_and_bot_units_in_sphere = function(self, center, radius)
    return enigma:get_units_in_sphere(center, radius, "player")
end
enigma.get_ai_units_around_unit = function(self, unit, radius)
    local center = Unit.world_position(unit, 0)
    return enigma:get_ai_units_in_sphere(center, radius)
end
enigma.get_player_and_bot_units_around_unit = function(self, unit, radius)
    local center = Unit.world_position(unit, 0)
    return enigma:get_player_and_bot_units_in_sphere(center, radius)
end

enigma._hit_enemy = function(self, hit_unit, attacker_unit, hit_zone_name, hit_position, attack_direction, damage_source, power_level, damage_profile, target_index, boost_curve_multiplier, is_critical_strike, can_damage, can_stagger, blocking, shield_breaking_hit, backstab_multiplier, first_hit, total_hits)
    local hit_ragdoll_actor = nil
    DamageUtils.server_apply_hit(Managers.time:time("game"), attacker_unit, hit_unit, hit_zone_name, hit_position, attack_direction, hit_ragdoll_actor, damage_source, power_level, damage_profile, target_index, boost_curve_multiplier, is_critical_strike, can_damage, can_stagger, blocking, shield_breaking_hit, backstab_multiplier, first_hit, total_hits)
end
enigma.hit_enemy = function(hit_unit, attacking_player_unit, hit_zone_name, damage_profile, power_multiplier, is_critical_strike, break_shields)
    power_multiplier = power_multiplier or 1
    hit_zone_name = hit_zone_name or "full"
    damage_profile = damage_profile or DamageProfileTemplates.default
    local career_ext = ScriptUnit.extension(attacking_player_unit, "career_system")
    local power_level = career_ext and career_ext:get_career_power_level() or 0
    power_level = power_level * power_multiplier
    local hit_position = Unit.world_position(hit_unit, 0)
    local attacker_breed = career_ext._breed and career_ext._breed.name or "debug"

    enigma:_hit_enemy(hit_unit, attacking_player_unit, hit_zone_name, hit_position, Vector3.zero(), attacker_breed, power_level, damage_profile, 0, power_multiplier, is_critical_strike, true, true, false, break_shields, 1, false, 0)
end

-- File IO
enigma.save = function(self, file_name, data, callback)
    return Managers.save:auto_save(file_name, data, callback, true)
end
enigma.load = function(self, file_name, callback)
    return Managers.save:auto_load(file_name, callback, true)
end

-- Math/Random
enigma.random = function(self)
    local result
    enigma.random_seed, result = Math.next_random(enigma.random_seed)
    return result
end
enigma.random_range = function(self, min, max)
    local result
    enigma.random_seed, result = math.next_random_range(enigma.random_seed, min, max)
    return result
end
enigma.random_range_int = function(self, min, max)
    return math.floor(self:random_range(min, max+1))
end
enigma.shuffle = function(self, array)
    enigma.random_seed = table.shuffle(array, enigma.random_seed)
end
enigma.test_chance = function(self, chance)
    local rand = self:random()
    return rand < chance
end
enigma.n_random_indexes = function(self, array_size, n)
    local selected = {}
    for i=1,array_size do
        local chance_to_select = n / (array_size - i)
        if self:test_chance(chance_to_select) then
            table.insert(selected, i)
            n = n - 1
            if n <= 0 then
                return selected
            end
        end
    end
    return selected
end