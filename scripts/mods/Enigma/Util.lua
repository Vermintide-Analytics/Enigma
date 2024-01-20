local enigma = get_mod("Enigma")

local buff_perk_functions = require("scripts/unit_extensions/default_player_unit/buffs/settings/buff_perk_functions")

-- Table functions
table.deep_copy = function(tbl, max_depth, exclude_table_keys)
    local inst = table.shallow_copy(tbl)
    if max_depth <= 0 then
        return inst
    end
    for k,v in pairs(tbl) do
        if type(v) == "table" and (not exclude_table_keys or not exclude_table_keys[k]) then
            inst[k] = table.deep_copy(v, max_depth-1)
        end
    end
    return inst
end


-- Retrieve Game State
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
    return level_key == "map_deus"
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
    return game_mode_key or Managers.state and Managers.state.game_mode and Managers.state.game_mode:game_mode_key()
end
enigma.is_game_mode_supported = function(self, game_mode_key)
    return game_mode_key == "adventure" or game_mode_key == "deus"
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

-- Retrieve Unit/Player data
local monster_breeds = {
	chaos_troll = true,
	chaos_spawn = true,
	skaven_rat_ogre = true,
	skaven_stormfiend = true,
	beastmen_minotaur = true
}
enigma.breed_is_monster = function(self, breed)
    if not breed then
        return false
    end
    return monster_breeds[breed.name]
end
enigma.distance_between_units = function(self, unit1, unit2)
    if not unit1 or not unit2 then
        enigma:warning("Cannot get the distance between units: "..tostring(unit1).." and "..tostring(unit2))
        return
    end
    return Vector3.distance(Unit.world_position(unit1, 0), Unit.world_position(unit2, 0))
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
enigma.get_controlled_unit_data = function(self, owner_unit)
    if not owner_unit then
        return
    end
    local commander_extension = ScriptUnit.extension(owner_unit, "ai_commander_system")
    if not commander_extension then
        return
    end
    return commander_extension:get_controlled_units(), commander_extension:get_controlled_units_count()
end
enigma.local_player = function(self)
    return Managers.player and Managers.player:local_human_player()
end
enigma.local_player_career_name = function(self)
    local player = self:local_player()
    return player and player:career_name()
end
enigma.local_player_unit = function(self)
    local player = self:local_player()
    return player and player.player_unit
end
enigma.player_and_bot_units = function(self)
    local side = Managers.state and Managers.state.side and Managers.state.side:get_side_from_name("heroes")
	return side and side.PLAYER_AND_BOT_UNITS
end
enigma.unit_position = function(self, unit)
    return unit and Unit.alive(unit) and Unit.world_position(unit, 0)
end
enigma.on_ground = function(self, unit)
    if not unit then
        return false
    end
    if not ScriptUnit.has_extension(unit, "locomotion_system") then
        enigma:warning("Cannot get "..tostring(unit).." on_ground. No locomotion extension attached to it")
        return false
    end
    return ScriptUnit.extension(unit, "locomotion_system").on_ground
end


-- Affect Units/Players
enigma.add_dot = function(self, unit, attacker_unit, custom_dot, power_multiplier, is_critical_strike)
    if not unit or not Unit.alive(unit) or not attacker_unit or not Unit.alive(attacker_unit) then
        return
    end

    local career_ext = ScriptUnit.extension(attacker_unit, "career_system")
    local power_level = career_ext and career_ext:get_career_power_level() or 600
    power_level = power_level * (power_multiplier or 1)
    local hit_zone_name = nil
    local damage_source = nil
    local boost_curve_multiplier = nil

    if type(custom_dot) == "string" then
        local dot_template_name = custom_dot
        custom_dot = {
            dot_template_name = dot_template_name
        }
    end

    DamageUtils.apply_dot(nil, nil, power_level, unit, attacker_unit, hit_zone_name, damage_source, boost_curve_multiplier, is_critical_strike, nil, attacker_unit, custom_dot)
end
local adjust_direction_by_first_person_rotation = function(unit, direction, include_pitch_roll)
    local first_person = ScriptUnit.extension(unit, "first_person_system")
    local rotation = first_person:current_rotation()
    rotation = not include_pitch_roll and Quaternion.flat_no_roll(rotation) or rotation
    return Quaternion.rotate(rotation, direction)
end
enigma.leap_first_person = function(self, unit, direction, distance, speed, initial_vertical_speed, leap_events)
    if not ScriptUnit.has_extension(unit, "first_person_system") then
        enigma:warning("Cannot leap "..tostring(unit).." first person. No first person extension attached to it")
        return false
    end
    if not ScriptUnit.has_extension(unit, "status_system") then
        enigma:warning("Cannot leap "..tostring(unit).." first person. No status extension attached to it")
        return false
    end
    local first_person = ScriptUnit.extension(unit, "first_person_system")
    direction = adjust_direction_by_first_person_rotation(unit, direction, false)

    local direction_normalized = Vector3.normalize(direction)
    local status = ScriptUnit.extension(unit, "status_system")
    local world = Managers.world:world("level_world")
	local physics_world = World.get_data(world, "physics_world")
    local result, landing_position = WeaponHelper:ground_target(physics_world, unit, first_person:current_position(), direction_normalized * distance, Vector3(0, 0, -10), "filter_slayer_leap")
    status.do_leap = {
        move_function = "leap",
        direction = Vector3Box(direction_normalized),
        speed = speed,
        initial_vertical_speed = initial_vertical_speed or 10,
        projected_hit_pos = Vector3Box(landing_position),
        leap_events = leap_events
    }
    return true
end
enigma.leap_forward = function(self, player_unit, distance, speed, initial_vertical_speed, leap_events)
    enigma:leap_first_person(player_unit, Vector3(0, 1, 1), distance, speed, initial_vertical_speed, leap_events)
end
enigma.apply_no_clip = function(self, unit, reason)
    self:apply_no_clip_filter(unit, reason, true, true, true, true, true, true)
end
enigma.apply_no_clip_filter = function(self, unit, reason, infantry, armored, monster, hero, berserker, super_armor)
    if not unit then
        return
    end
    if not ScriptUnit.has_extension(unit, "locomotion_system") then
        enigma:warning("Cannot add "..tostring(unit).." no clip filter \""..tostring(reason).."\". No locomotion extension attached to it")
        return
    end
    local locomotion = ScriptUnit.extension(unit, "locomotion_system")
    if not locomotion.apply_no_clip_filter then
        enigma:warning("Cannot add "..tostring(unit).." no clip filter \""..tostring(reason).."\". No apply_no_clip_filter function in its locomotion extension")
        return
    end
    locomotion:apply_no_clip_filter({
        not not infantry,
        not not armored,
        not not monster,
        not not hero,
        not not berserker,
        not not super_armor
    }, reason)
end
enigma.apply_perk = function(self, unit, perk_name)
    if not unit or not Unit.alive(unit) then
        return
    end
    local buff_ext = ScriptUnit.extension(unit, "buff_system")
    if not buff_ext then
        enigma:warning("Cannot apply perk to "..tostring(unit)..". No buff extension attached to it")
        return
    end
    local perks = buff_ext._perks
    local perk_count = perks[perk_name] or 0
    if perk_count == 0 then
        local perk_funcs = buff_perk_functions[perk_name]

        if perk_funcs and perk_funcs.added then
            perk_funcs.added(buff_ext, unit, nil, self:is_server())
        end
    end
    perks[perk_name] = perk_count + 1
end
enigma.create_explosion = function(self, owner_unit, position, rotation, explosion_template_name, scale, damage_source, attacker_power_level, is_critical_strike)
    if not self:is_server() then
        enigma:warning("Only the server can create explosions")
        return
    end
    if not owner_unit or not Unit.alive(owner_unit) then
        return
    end
    if not enigma.managers.game:is_in_game() then
        enigma:warning("Could not create an explosion, not in a game")
        return
    end
    table.insert(enigma.managers.game.queued_explosions, {
        owner_unit = owner_unit,
        position = Vector3Box(position),
        rotation = QuaternionBox(rotation),
        explosion_template_name = explosion_template_name,
        scale = scale,
        damage_source = damage_source,
        attacker_power_level = attacker_power_level,
        is_critical_strike = is_critical_strike
    })
end
enigma.create_gas_cloud = function(self, owner_unit, position, duration, init_radius, init_damage, dot_radius, dot_damage, dot_damage_interval, damage_players)
    if not enigma:is_server() then
        enigma:warning("Only the server can create gas clouds")
        return
    end
    if not owner_unit or not position then
        return
    end

    local owner_unit_breed = Unit.get_data(owner_unit, "breed")
    local damage_source = owner_unit_breed and owner_unit_breed.name or "dot_debuff"

    local nav_tag_volume_layer = damage_players and "bot_poison_wind" or nil
    local extension_init_data = {
        area_damage_system = {
            area_damage_template = "globadier_area_dot_damage",
            invisible_unit = true,
            player_screen_effect_name = "fx/screenspace_poison_globe_impact",
            area_ai_random_death_template = "area_poison_ai_random_death",
            dot_effect_name = "fx/wpnfx_poison_wind_globe_impact",
            extra_dot_effect_name = "fx/chr_gutter_death",
            damage_players = damage_players,
            aoe_dot_damage = dot_damage or 0,
            aoe_init_damage = init_damage or 0,
            aoe_dot_damage_interval = dot_damage_interval or 1,
            radius = dot_radius or 0,
            initial_radius = init_radius or 0,
            life_time = duration,
            damage_source = damage_source,
            create_nav_tag_volume = damage_players,
            nav_tag_volume_layer = nav_tag_volume_layer,
            source_attacker_unit = owner_unit
        }
    }
    local aoe_unit_name = "units/weapons/projectile/poison_wind_globe/poison_wind_globe"
    local aoe_unit = Managers.state.unit_spawner:spawn_network_unit(aoe_unit_name, "aoe_unit", extension_init_data, position)
    local unit_id = Managers.state.unit_storage:go_id(aoe_unit)

    Unit.set_unit_visibility(aoe_unit, false)
    Managers.state.network.network_transmit:send_rpc_all("rpc_area_damage", unit_id, position)
end
enigma.force_damage = function(self, unit, damage, damager, damage_source)
    if not self:is_server() then
        enigma:warning("Only the server can damage")
        return false
    end
    if not unit then
        return false
    end
    damager = damager or unit
    damage_source = damage_source or "life_tap"

    -- attacked_unit, attacker_unit, original_damage_amount, hit_zone_name, damage_type, hit_position, damage_direction,
    -- damage_source, hit_ragdoll_actor, source_attacker_unit, buff_attack_type, hit_react_type, is_critical_strike,
    -- added_dot, first_hit, total_hits, backstab_multiplier, skip_buffs
    DamageUtils.add_damage_network(unit, damager, damage, "full", "forced", Unit.world_position(unit, 0), Vector3.up(), damage_source, nil, damager, "n/a", "light", false, false, false, 1, 1, true)
end
enigma.heal = function(self, unit, heal, healer, heal_type)
    if not self:is_server() then
        enigma:warning("Only the server can heal")
        return false
    end
    if not unit or not ALIVE[unit] then
        return false
    end
    healer = healer or unit
    heal_type = heal_type or "health_regen"

    DamageUtils.heal_network(unit, healer, heal, heal_type)
end
enigma._hit_enemy = function(self, hit_unit, attacker_unit, hit_zone_name, hit_position, attack_direction, damage_source, power_level, damage_profile, target_index, boost_curve_multiplier, is_critical_strike, can_damage, can_stagger, blocking, shield_breaking_hit, backstab_multiplier, first_hit, total_hits)
    local hit_ragdoll_actor = nil
    if attacker_unit and type(POSITION_LOOKUP[attacker_unit]) == "userdata" then
        POSITION_LOOKUP[attacker_unit] = Unit.world_position(attacker_unit, 0)
    end
    DamageUtils.server_apply_hit(Managers.time:time("game"), attacker_unit, hit_unit, hit_zone_name, hit_position, attack_direction, hit_ragdoll_actor, damage_source, power_level, damage_profile, target_index, boost_curve_multiplier, is_critical_strike, can_damage, can_stagger, blocking, shield_breaking_hit, backstab_multiplier, first_hit, total_hits)
end
enigma.hit_enemy = function(self, hit_unit, attacking_player_unit, hit_zone_name, damage_profile, power_multiplier, is_critical_strike, break_shields)
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
enigma.multiply_player_gravity_scale = function(self, unit, multiplier)
    if not unit or not Unit.alive(unit) then
        return
    end
    local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
    if not locomotion_extension then
        enigma:warning("Could not multiply player gravity for "..tostring(unit)..", no locomotion extension")
        return
    end
    if not locomotion_extension.set_script_driven_gravity_scale then
        enigma:warning("Could not multiply player gravity for "..tostring(unit)..", cannot set script driven gravity scale")
        return
    end
    local current_gravity = locomotion_extension:get_script_driven_gravity_scale()
    locomotion_extension:set_script_driven_gravity_scale(current_gravity * multiplier)
    
end
enigma.multiply_player_movement_speed = function(self, unit, multiplier)
    if not unit or not Unit.alive(unit) then
        return
    end
    local move_settings = PlayerUnitMovementSettings.get_movement_settings_table(unit)
    if not move_settings then
        enigma:warning("Could not multiply player movement speed for "..tostring(unit)..", no movement settings table")
        return
    end
    move_settings.player_speed_scale = move_settings.player_speed_scale * multiplier
    move_settings.move_acceleration_up = move_settings.move_acceleration_up * multiplier
    move_settings.move_acceleration_down = move_settings.move_acceleration_down * multiplier
end
enigma.pop_unit_untargetable = function(self, unit)
    if not unit then
        return
    end
    local current_untargetable = Unit.has_data(unit, "untargetable") and Unit.get_data(unit, "untargetable")
    if current_untargetable then
        local new_value = current_untargetable > 1 and current_untargetable - 1 or nil
        Unit.set_data(unit, "untargetable", new_value)
    end
end
enigma.push_unit_untargetable = function(self, unit)
    if not unit then
        return
    end
    local current_untargetable = Unit.has_data(unit, "untargetable") and Unit.get_data(unit, "untargetable") or 0
    Unit.set_data(unit, "untargetable", current_untargetable + 1)
end
enigma.remove_no_clip = function(self, unit, reason)
    enigma:remove_no_clip_filter(unit, reason)
end
enigma.remove_no_clip_filter = function(self, unit, reason)
    if not unit then
        return
    end
    if not ScriptUnit.has_extension(unit, "locomotion_system") then
        enigma:warning("Cannot remove "..tostring(unit).." no clip filter \""..tostring(reason).."\". No locomotion extension attached to it")
        return
    end
    local locomotion = ScriptUnit.extension(unit, "locomotion_system")
    if not locomotion.remove_no_clip_filter then
        enigma:warning("Cannot remove "..tostring(unit).." no clip filter \""..tostring(reason).."\". No remove_no_clip_filter function in its locomotion extension")
        return
    end
    locomotion:remove_no_clip_filter(reason)
end
enigma.remove_overcharge_fraction = function(self, unit, fraction)
    if not unit or not Unit.alive(unit) then
        return
    end
    local overcharge = ScriptUnit.extension(unit, "overcharge_system")
    if not overcharge then
        enigma:warning("Cannot remove overcharge from "..tostring(unit)..". No overcharge extension attached to it")
        return
    end
    overcharge:remove_charge_fraction(fraction)
end
enigma.remove_perk = function(self, unit, perk_name)
    if not unit or not Unit.alive(unit) then
        return
    end
    local buff_ext = ScriptUnit.extension(unit, "buff_system")
    if not buff_ext then
        enigma:warning("Cannot remove perk from "..tostring(unit)..". No buff extension attached to it")
        return
    end
    local perks = buff_ext._perks
    local perk_count = perks[perk_name] - 1
    if perk_count == 0 then
        local perk_funcs = buff_perk_functions[perk_name]

        if perk_funcs and perk_funcs.removed then
            perk_funcs.removed(buff_ext, unit, nil, self:is_server())
        end
    end
    perks[perk_name] = perk_count
end
enigma.set_first_person_rotation = function(self, unit, rotation)
    if not unit then
        return
    end
    if not ScriptUnit.has_extension(unit, "first_person_system") then
        enigma:warning("Cannot lerp "..tostring(unit).." first person rotation. No first person extension attached to it")
        return
    end
    local first_person = ScriptUnit.extension(unit, "first_person_system")
    first_person:set_rotation(rotation)
end
enigma.set_ignore_next_fall_damage = function(self, unit, ignore)
    if not unit then
        return
    end
    if not ScriptUnit.has_extension(unit, "status_system") then
        enigma:warning("Cannot set "..tostring(unit).." to ignore next fall damage. No status extension attached to it")
        return
    end
    local status = ScriptUnit.extension(unit, "status_system")
    status:set_ignore_next_fall_damage(ignore)
end
enigma.set_taunt_unit = function (self, ai_unit, taunt_unit, taunt_bosses)
	local blackboard = BLACKBOARDS[ai_unit]

	if blackboard then
		local breed = blackboard.breed
		local taunt_target = breed and not breed.ignore_taunts and (not breed.boss or taunt_bosses)

		if taunt_target then
			if blackboard.taunt_unit ~= taunt_unit then
				blackboard.taunt_unit = taunt_unit
				blackboard.indefinite_taunt = true
                local t = Managers.time:time("game")
				blackboard.target_unit_found_time = t
			end
        end
    end
end
enigma.spawn_orb = function(self, orb_name, owner_player_unit)
    enigma:spawn_orb_at_unit(orb_name, owner_player_unit, owner_player_unit)
end
enigma.spawn_orb_at_unit = function(self, orb_name, owner_player_unit, out_of_unit)
    local orb_system = Managers.state.entity:system("orb_system")
    if not orb_system then
        enigma:warning("Could not spawn orb: "..tostring(orb_name)..", no orb system")
        return
    end
    local player = Managers.player:owner(owner_player_unit)
    if not player then
        enigma:warning("Orb owner unit must be a player unit")
        return
    end
    if not out_of_unit then
        enigma:warning("spawn_orb_at_unit missing \"out_of_unit\"")
        return
    end
    orb_system:spawn_orb(orb_name, player.peer_id, Unit.world_position(out_of_unit, 0), Vector3(0, 0, 1), 2 * math.pi)
end
enigma.spawn_pet = function(self, owner_unit, breed_name, template_name, relative_position)
    if not self:is_server() then
        enigma:warning("Only the server can spawn pets")
        return
    end
    if not owner_unit or not Unit.alive(owner_unit) then
        return
    end
    if not Managers.state or not Managers.state.entity then
        enigma:warning("Could not spawn pet, no entity state manager")
        return
    end

    local ai_system = Managers.state.entity:system("ai_system")
    if not ai_system then
        enigma:warning("Could not spawn pet, no ai system")
        return
    end
	local nav_world = ai_system:nav_world()
    if not nav_world then
        enigma:warning("Could not spawn pet, no nav world")
        return
    end

	local owner_buff_extension = ScriptUnit.extension(owner_unit, "buff_system")
    if not owner_buff_extension then
        enigma:warning("Owner of a spawned pet must have a buff extension")
        return
    end
    local owner_commander_extension = ScriptUnit.extension(owner_unit, "ai_commander_system")
    if not owner_commander_extension then
        enigma:warning("Owner of a spawned pet must have an ai commander extension")
        return
    end
    
    relative_position = relative_position or Vector3.zero()

	local side_id = Managers.state.side.side_by_unit[owner_unit].side_id
	local spawn_category = "resurrected"
	local spawn_animation = "spawn_floor"
	local breed = Breeds[breed_name]
	local optional_data = {
		ignore_breed_limits = true,
		side_id = side_id,
		spawned_func = function (pet_unit, breed, optional_data)
			if ALIVE[owner_unit] then

				owner_buff_extension:trigger_procs("on_pet_spawned", pet_unit)

				local t = Managers.time:time("game")
				owner_commander_extension:add_controlled_unit(pet_unit, template_name, t)
                
				local params = FrameTable.alloc_table()
				params.source_attacker_unit = owner_unit

				Managers.state.entity:system("buff_system"):add_buff_synced(pet_unit, "sienna_necromancer_pet_attack_sfx", BuffSyncType.Local, params, owner_commander_extension._player.peer_id)
			end
		end
	}
	local fp_rotation_flat = nil
    
    local first_person = ScriptUnit.extension(owner_unit, "first_person_system")
	if first_person then
		fp_rotation_flat = first_person:current_rotation()
		fp_rotation_flat = Quaternion.look(Vector3.flat(Quaternion.forward(fp_rotation_flat)), Vector3.up())
	else
        local game_object_id = Managers.state.unit_storage:go_id(owner_unit)
        local game = Managers.state.network:game()
        local aim_direction = GameSession.game_object_field(game, game_object_id, "aim_direction")
        fp_rotation_flat = Quaternion.look(Vector3.flat(aim_direction), Vector3.up())
	end

    if type(POSITION_LOOKUP[owner_unit]) == "userdata" then
        POSITION_LOOKUP[owner_unit] = Unit.world_position(owner_unit, 0)
    end
	local position = POSITION_LOOKUP[owner_unit] + Quaternion.rotate(fp_rotation_flat, relative_position)
	local unit_is_on_navmesh, z = GwNavQueries.triangle_from_position(nav_world, position, 2, 2)

	if unit_is_on_navmesh then
		position.z = z
	else
		position = GwNavQueries.inside_position_from_outside_position(nav_world, position, 2, 2, 5, 1)
	end

	if not position then
		return false
	end

	--queued_pets[optional_data] = 
    Managers.state.conflict:spawn_queued_unit(breed, Vector3Box(position), QuaternionBox(fp_rotation_flat), spawn_category, spawn_animation, nil, optional_data)

	return true
end
enigma.stagger_enemy = function(self, hit_unit, unit, distance, impact, direction, blocked)
    if not hit_unit or not Unit.alive(hit_unit) or not unit or not Unit.alive(unit) then
        return
    end
    local stagger_type, stagger_duration = DamageUtils.calculate_stagger(impact, nil, hit_unit, unit, nil, nil, blocked)
    if stagger_type > 0 then
		local hit_unit_blackboard = BLACKBOARDS[hit_unit]

        local t = Managers.time:time("game")
		AiUtils.stagger(hit_unit, hit_unit_blackboard, unit, direction, distance, stagger_type, stagger_duration, nil, t)
	end
end
enigma.stun_enemy = function(self, hit_unit, unit, duration)
    if not hit_unit or not Unit.alive(hit_unit) or not unit or not Unit.alive(unit) then
        return
    end
    local hit_unit_blackboard = BLACKBOARDS[hit_unit]

    local direction = Unit.world_position(hit_unit, 0) - Unit.world_position(unit, 0)

    local t = Managers.time:time("game")
    AiUtils.stagger(hit_unit, hit_unit_blackboard, unit, direction, 0, 6, duration, nil, t)
end
enigma.unset_taunt_unit = function(self, ai_unit)
	local blackboard = BLACKBOARDS[ai_unit]
    if blackboard then
        blackboard.indefinite_taunt = false
    end
end


-- Execution
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



-- Misc
enigma.camera_shake = function(self, shake_name, origin, near_dist, far_dist, near_value, far_value)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit or not Unit.alive(local_player_unit) or not origin then
        return
    end
    
    near_value = near_value or 1
    far_value = far_value or 0

    local scale = 1

    local d = Vector3.distance(origin, enigma:unit_position(local_player_unit))
    scale = 1 - math.clamp((d - near_dist) / (far_dist - near_dist), 0, 1)
    scale = far_value + scale * (near_value - far_value)

    Managers.state.camera:camera_effect_shake_event(shake_name, Managers.time:time("game"), scale)
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
enigma.get_all_enemies = function(self)
    local units = {}
	local ai_system = Managers.state.entity:system("ai_system")
    if not ai_system then
        return units
    end
	local broadphase = ai_system.group_blackboard.broadphase
    if not broadphase then
        return units
    end
	local entries = Broadphase.all(broadphase)
    for i,entry in ipairs(entries) do
        if entry[3] then
            table.insert(units, entry[3])
        end
    end
    return units
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
enigma.get_random_card_definition = function(self, predicate)
    local cards = enigma.managers.card_template.ALL_CARDS:where(function(template)
        return not template.exclude_from_random_card_effects and (not predicate or predicate(template))
    end)
    if #cards < 1 then
        return
    end
    return cards[enigma:random_range_int(1, #cards)]
end
enigma.invoke_delayed = function(self, func, delay)
    enigma.managers.game:_add_delayed_function_call(func, delay)
end
enigma.lerp_yaw_pitch_roll = function(self, initial_yaw, initial_pitch, initial_roll, target_yaw, target_pitch, target_roll, t)
    local lerped_yaw = math.lerp(initial_yaw, target_yaw, t)
    local lerped_pitch = math.lerp(initial_pitch, target_pitch, t)
    local lerped_roll = math.lerp(initial_roll, target_roll, t)

    local yaw_rot = Quaternion(Vector3.up(), lerped_yaw)
    local pitch_rot = Quaternion(Vector3.right(), lerped_pitch)
    local roll_rot = Quaternion(Vector3.forward(), lerped_roll)

    return Quaternion.multiply(Quaternion.multiply(yaw_rot, pitch_rot), roll_rot)
end
local enigma_time_scale_multiplier = 1
enigma._reset_time_scale_multiplier = function(self)
    if not Managers.time then
        enigma:warning("Could not reset time scale, no time manager")
        return
    end

    Managers.time:set_global_time_scale(Managers.time._global_time_scale / enigma_time_scale_multiplier)
    enigma_time_scale_multiplier = 1
end
enigma.multiply_time_scale = function(self, multiplier)
    if not Managers.time then
        enigma:warning("Could not multiply time scale, no time manager")
        return
    end
    if multiplier <= 0 then
        enigma:warning("Cannot multiply time by: "..tostring(multiplier))
        return
    end
    
    enigma_time_scale_multiplier = enigma_time_scale_multiplier * multiplier
    Managers.time:set_global_time_scale(Managers.time._global_time_scale * multiplier)
end



-- Shapecasting

-- Sphere
enigma.get_units_in_sphere = function(self, center, radius, unit_type)
    unit_type = unit_type or "all"
    local results = {}
    if unit_type == "all" or unit_type == "ai" then
        AiUtils.broadphase_query(center, radius, results)
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

-- Cone
enigma.get_units_in_cone = function(self, origin, direction, length, angle_degrees, unit_type)
    unit_type = unit_type or "all"
    local nearby = self:get_units_in_sphere(origin, length, unit_type)

    local in_cone = {}
    direction = Vector3.normalize(direction)
    local threshold_cos = math.cos(math.rad(angle_degrees/2))

    for _,target in ipairs(nearby) do
        local to_target = Vector3.normalize(Unit.world_position(target, 0) - origin)
        local cos = Vector3.dot(to_target, direction)
        if cos >= threshold_cos then
            table.insert(in_cone, target)
        end
    end
    return in_cone
end

enigma.get_units_in_front_of_unit = function(self, unit, length, angle_degrees, unit_type)
    if ScriptUnit.has_extension(unit, "first_person_system") then
        unit = ScriptUnit.extension(unit, "first_person_system"):get_first_person_unit()
    end
    local unit_position = Unit.world_position(unit, 0)
    local unit_rotation = Unit.world_rotation(unit, 0)
	local unit_direction = Quaternion.forward(unit_rotation)
    return self:get_units_in_cone(unit_position, unit_direction, length, angle_degrees, unit_type)
end

enigma.get_ai_units_in_front_of_unit = function(self, unit, length, angle_degrees)
    return self:get_units_in_front_of_unit(unit, length, angle_degrees, "ai")
end
enigma.get_player_and_bot_units_in_front_of_unit = function(self, unit, length, angle_degrees)
    return self:get_units_in_front_of_unit(unit, length, angle_degrees, "player")
end




enigma.wwise_event = function(self, event_name)
    if not event_name then
        return
    end
    local world = Managers.world and (
		Managers.world:has_world("level_world") and Managers.world:world("level_world") or
		Managers.world:has_world("loading_world") and Managers.world:world("loading_world") or
		Managers.world:has_world("top_ingame_view") and Managers.world:world("top_ingame_view"))
	if not world then
		return
	end
	local wwise_world = Wwise.wwise_world(world)
	if not wwise_world then
		return
	end
    WwiseWorld.trigger_event(wwise_world, event_name)
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