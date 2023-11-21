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

enigma.self_peer_id = function(self)
    return Network and Network.peer_id()
end
enigma.is_peer_self = function(self, peer_id)
    return peer_id == self:self_peer_id()
end

enigma.level_key = function(self)
    return Managers.state and Managers.state.game_mode:level_key() or Managers.level_transition_handler and Managers.level_transition_handler:get_current_level_key()
end
enigma.in_inn = function(self)
    local level_key = Managers.state and Managers.state.game_mode:game_mode_key()
    return level_key:find("inn_level")
end
enigma.in_morris_hub = function(self)
    local level_key = Managers.state and Managers.state.game_mode:game_mode_key()
    return level_key == "morris_hub"
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

enigma.game_mode_key = function(self)
    return Managers.state and Managers.state.game_mode:game_mode_key()
end
enigma.detect_game_mode = function(self)
    local level_key = self:level_key()
    local game_mode_key
    if level_key == "inn_level" then
        game_mode_key = "adventure"
    elseif level_key == "morris_hub" or level_key == "dlc_morris_map" then
        game_mode_key = "deus"
    end
    return game_mode_key or self:game_mode_key()
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
    local breed = Unit.get_data(unit, "breed")
    return not breed or breed.boss
end
enigma.execute_man_sized_enemy = function (self, unit, params)
    local hit_unit = params[1]
    if not self:is_enemy_man_sized(hit_unit) then
        return
    end
    return enigma:execute_unit(hit_unit, unit)
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
    enigma:info("Enigma random roll: "..tostring(result))
    return result
end
enigma.random_range = function(self, min, max)
    local result
    enigma.random_seed, result = math.next_random_range(enigma.random_seed, min, max)
    return result
end
enigma.test_chance = function(self, chance)
    local rand = self:random()
    if rand < chance then
        enigma:info("Succeeded roll (result < "..tostring(chance)..")")
    else
        enigma:info("Failed roll (result >= "..tostring(chance)..")")
    end
    return rand < chance
end