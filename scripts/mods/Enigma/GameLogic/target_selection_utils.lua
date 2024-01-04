local enigma = get_mod("Enigma")

local HEALTH_ALIVE = HEALTH_ALIVE
local unit_knocked_down = AiUtils.unit_knocked_down
local vector3_distance = Vector3.distance
local POSITION_LOOKUP = POSITION_LOOKUP
local AI_TARGET_UNITS = AI_TARGET_UNITS
local AI_UTILS = AI_UTILS
local ScriptUnit_extension = ScriptUnit.extension
local result_table = {}

local HEAR_DISTANCE = 1
local raycast_points = {
	"j_hips",
	"j_leftforearm",
	"j_rightforearm",
	"j_head"
}

local function _line_of_sight_from_random_point(from_pos, target_unit)
	local random_point = raycast_points[Math.random(1, #raycast_points)]
	local has_node = Unit.has_node(target_unit, random_point)
	local tp = nil

	if has_node then
		local node = Unit.node(target_unit, random_point)
		local physics_world = World.get_data(Unit.world(target_unit), "physics_world")
		local target_pos = Unit.world_position(target_unit, node)
		local distance = Vector3.distance(from_pos, target_pos)
		tp = target_pos

		if HEAR_DISTANCE < distance then
			local direction = (target_pos - from_pos) / distance
			local result, pos = PhysicsWorld.immediate_raycast(physics_world, from_pos, direction, distance, "closest", "types", "statics", "collision_filter", "filter_ai_line_of_sight_check")

			if result then
				return false
			end
		end
	end

	return true
end

local DOGPILE_SCORE = 2.5
local DISABLED_SLOT_SCORE = 2.5
local ALL_SLOTS_DISABLED_SCORE = 600
local STICKY_AGGRO_RANGE_SQUARED = 5.0625
local HIGHER_STICKINESS_RANGE_SQUARED = 4
local DISTANCE_SCORE = 0.25
local COMBO_TARGET_SCORE = 5

local dogpile_score = {
	[0] = 0,
	4,
	9,
	16,
	25,
	36
}

local function get_lean_score(blackboard, position, ai_unit, target_unit)
	local lean_dogpile = blackboard.lean_dogpile
	local dogpiled_attackers = nil

	if USE_ENGINE_SLOID_SYSTEM then
		dogpiled_attackers = Managers.state.conflict.dogpiled_attackers_on_unit[target_unit]
	else
		dogpiled_attackers = Managers.state.conflict.gathering.dogpiled_attackers_on_unit[target_unit]
	end

	local already_attacking = dogpiled_attackers and dogpiled_attackers[ai_unit]

	if already_attacking then
		lean_dogpile = lean_dogpile - 1
	end

	local dogpile_score = dogpile_score[lean_dogpile] or 64
	local target_position = POSITION_LOOKUP[target_unit]
	local dist_sq = Vector3.distance_squared(position, target_position)
	local target_score = dogpile_score + dist_sq

	return target_score, dist_sq
end

local LEAN_TARGET_STICKYNESS = 0.5
local function get_lean_target(blackboard, position, side, ai_unit, check_for_walls, t, ignored_breed_filter)
	local breed = blackboard.breed
	local radius = blackboard.override_detection_radius or blackboard.detection_radius or breed.minion_detection_radius or breed.detection_radius or 7
	local num_ai_units, target_unit = nil, nil
	local lean_unit_list = blackboard.lean_unit_list
	local unit_index, time_index, score_index = nil, nil, nil
	local next_lean_index = blackboard.next_lean_index

	if blackboard.next_lean_index <= 0 then
		num_ai_units = AiUtils.broadphase_query(position, radius, result_table, side.enemy_broadphase_categories)

		if num_ai_units > 0 then
			local max_iterations = nil

			if math.random() < 0.9 then
				max_iterations = math.min(num_ai_units, 5)
			else
				max_iterations = math.min(num_ai_units, 12)
			end

			for i = 1, max_iterations do
				lean_unit_list[i] = result_table[i]
			end

			blackboard.next_lean_index = 1
			lean_unit_list.size = max_iterations
			target_unit = lean_unit_list[1]
		end
	else
		target_unit = lean_unit_list[next_lean_index]
		next_lean_index = next_lean_index + 1
		blackboard.next_lean_index = lean_unit_list.size <= next_lean_index and 0 or next_lean_index
	end

	local best_score = math.huge
	local target_blackboard, best_target_unit = nil, nil
	local previous_target = blackboard.target_unit

	if HEALTH_ALIVE[previous_target] then
		local prev_target_blackboard = BLACKBOARDS[previous_target]

		if prev_target_blackboard and prev_target_blackboard.lean_dogpile then
			local target_score = get_lean_score(prev_target_blackboard, position, ai_unit, previous_target)
			best_score = target_score * LEAN_TARGET_STICKYNESS
			best_target_unit = previous_target
		end
	end

	if HEALTH_ALIVE[target_unit] then
		if target_unit == best_target_unit then
			-- Nothing
		else
			target_blackboard = BLACKBOARDS[target_unit]
			local target_breed_name = target_blackboard.breed.name

			if ignored_breed_filter[target_breed_name] then
				-- Nothing
			else
				local dogpile = target_blackboard.lean_dogpile

				if target_blackboard.crowded_slots <= dogpile then
					-- Nothing
				else
					local target_position = POSITION_LOOKUP[target_unit]
					local target_score = get_lean_score(target_blackboard, position, ai_unit, target_unit)

					if target_score < best_score then
						if check_for_walls then
							local node = Unit.node(ai_unit, "j_head")
							local from_pos = Unit.world_position(ai_unit, node)
						else
							best_score = target_score
							best_target_unit = target_unit
						end
					end
				end
			end
		end
	end

	if best_target_unit then
		return best_target_unit, best_score * 0.95
	else
		return nil, math.huge
	end
end

local function _calculate_closest_target_with_spillover_score(ai_unit, target_unit, target_current, previous_attacker, ai_unit_position, raycast_pos, breed, detection_radius_sq, perception_previous_attacker_stickyness_value, is_horde, group_targets)
	local target_type = Unit.get_data(target_unit, "target_type")
	local exceptions = target_type and breed.perception_exceptions and breed.perception_exceptions[target_type]

	if exceptions then
		return
	end

	local target_unit_position = POSITION_LOOKUP[target_unit]

	if not target_unit_position then
		return
	end

	local distance_sq = Vector3.distance_squared(ai_unit_position, target_unit_position)
	local should_check_los = not target_current or group_targets and not group_targets[target_unit]

	if should_check_los then
		if target_unit ~= target_current and detection_radius_sq < distance_sq then
			return
		end

		if not is_horde then
			local has_los = _line_of_sight_from_random_point(raycast_pos, target_unit)

			if not has_los then
				return
			end
		end
	end

	local dogpile_count = 0
	local disabled_slots_count = 0
	local all_slots_disabled = false
	local is_previous_attacker = previous_attacker and previous_attacker == target_unit
	local target_of_combo_score = 0
	local target_slot_extension = ScriptUnit.has_extension(target_unit, "ai_slot_system")

	if target_slot_extension then
		local target_blackboard = BLACKBOARDS[target_unit]
		local target_is_player = target_blackboard and target_blackboard.is_player

		if target_is_player and not target_slot_extension.valid_target then
			return
		end

		local slot_type = breed.use_slot_type
		local ai_slot_system = Managers.state.entity:system("ai_slot_system")
		local total_slots_count = ai_slot_system:total_slots_count(target_unit, slot_type)
		dogpile_count = ai_slot_system:slots_count(target_unit, slot_type)
		disabled_slots_count = ai_slot_system:disabled_slots_count(target_unit, slot_type)
		all_slots_disabled = disabled_slots_count == total_slots_count
		local status_ext = ScriptUnit.has_extension(target_unit, "status_system")
		local on_ladder = status_ext and status_ext:get_is_on_ladder()

		if on_ladder then
			local max_allowed = is_previous_attacker and total_slots_count or total_slots_count - 1

			if dogpile_count > max_allowed then
				all_slots_disabled = true
			end
		end

		target_of_combo_score = (status_ext and status_ext:get_combo_target_count() or 0) * COMBO_TARGET_SCORE
	end

	local aggro_extension = ScriptUnit.has_extension(target_unit, "aggro_system")
	local aggro_modifier = aggro_extension and aggro_extension.aggro_modifier or 0
	local is_knocked_down = unit_knocked_down(target_unit)

	if distance_sq < STICKY_AGGRO_RANGE_SQUARED and not is_knocked_down then
		dogpile_count = math.max(dogpile_count - 4, 0)
	end

	local stickyness_modifier = breed.target_stickyness_modifier or -5

	if HIGHER_STICKINESS_RANGE_SQUARED < distance_sq then
		stickyness_modifier = stickyness_modifier * 0.5
	end

	local score_dogpile = dogpile_count * DOGPILE_SCORE
	local score_distance = distance_sq * DISTANCE_SCORE
	local score_stickyness = target_unit == target_current and stickyness_modifier or 0
	local knocked_down_modifer = is_knocked_down and 5 or 0
	local previous_attacker_stickyness_value = is_previous_attacker and perception_previous_attacker_stickyness_value or 0
	local score_disabled_slots = disabled_slots_count * DISABLED_SLOT_SCORE
	local score_all_slots_disabled = all_slots_disabled and ALL_SLOTS_DISABLED_SCORE or 0
	local score = score_dogpile + score_disabled_slots + score_all_slots_disabled + score_distance + score_stickyness + previous_attacker_stickyness_value + knocked_down_modifer + aggro_modifier + target_of_combo_score

    -- Enigma Buff Logic
    local custom_buffs = enigma.managers.buff.unit_custom_buffs and enigma.managers.buff.unit_custom_buffs[target_unit]
    if not custom_buffs then
        return score, distance_sq
    end

    score = score - custom_buffs.aggro

    local ai_breed = Unit.get_data(ai_unit, "breed")
    if not ai_breed then
        return score, distance_sq
    end
    local race = ai_breed.race
    if race == "skaven" then
        score = score - custom_buffs.aggro_skaven
    elseif race == "chaos" then
        score = score - custom_buffs.aggro_chaos
    elseif race == "beastmen" then
        score = score - custom_buffs.aggro_beastmen
    end

    if ai_breed.elite then
        score = score - custom_buffs.aggro_elite
    elseif not ai_breed.special and not ai_breed.boss then
        score = score - custom_buffs.aggro_trash
    end

	return score, distance_sq
end
enigma:hook_origin(PerceptionUtils, "pick_closest_target_with_spillover", function(ai_unit, blackboard, breed, t)
    fassert(ScriptUnit.has_extension(ai_unit, "ai_slot_system"), "Error! Trying to use slot_system perception for non-slot system unit!")

	local detection_radius = nil
	local during_horde_detection_radius = breed.during_horde_detection_radius
	local is_horde = false

	if during_horde_detection_radius and Managers.state.conflict:has_horde() then
		detection_radius = 45
		is_horde = true
	else
		detection_radius = breed.detection_radius
	end

	local POSITION_LOOKUP = POSITION_LOOKUP
	local detection_radius_sq = detection_radius * detection_radius
	local ai_unit_position = POSITION_LOOKUP[ai_unit]
	local target_current = blackboard.target_unit
	local best_target_unit = nil
	local best_score = math.huge
	local distance_to_target_sq = nil
	local side = blackboard.side
	local enemy_player_targets = side.AI_TARGET_UNITS
	local perception_previous_attacker_stickyness_value = breed.perception_previous_attacker_stickyness_value
	local previous_attacker = blackboard.previous_attacker
	local raycast_pos = Unit.world_position(ai_unit, Unit.node(ai_unit, "j_head"))
	local using_override_target = false
	local override_targets = blackboard.override_targets
	local valid_players = side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS
	local enemy_units = side.enemy_units_lookup

	for target_unit, end_of_override_t in pairs(override_targets) do
		local status_extension = ScriptUnit.has_extension(target_unit, "status_system")
		local is_player = status_extension
		local is_valid = nil
		is_valid = is_player and valid_players[target_unit] or enemy_units[target_unit] and HEALTH_ALIVE[target_unit]
        is_valid = is_valid and not Unit.has_data(target_unit, "untargetable")

		if not is_valid or end_of_override_t < t or status_extension and status_extension:is_disabled() then
			override_targets[target_unit] = nil
		else
			local score, distance_sq = nil, nil

			if is_player then
				score, distance_sq = _calculate_closest_target_with_spillover_score(ai_unit, target_unit, target_current, previous_attacker, ai_unit_position, raycast_pos, breed, detection_radius_sq, perception_previous_attacker_stickyness_value, is_horde)
			else
				local target_blackboard = BLACKBOARDS[target_unit]
				score, distance_sq = get_lean_score(target_blackboard, ai_unit_position, ai_unit, target_unit)
			end

			if score and score < best_score then
				best_score = score
				best_target_unit = target_unit
				distance_to_target_sq = distance_sq
				using_override_target = true
			end
		end
	end

	blackboard.using_override_target = using_override_target

	if not using_override_target then
		best_target_unit, best_score = get_lean_target(blackboard, ai_unit_position, side, ai_unit, true, t, breed.infighting.ignored_breed_filter)
		local num_player_targets = #enemy_player_targets
		local group_extension = ScriptUnit.has_extension(ai_unit, "ai_group_system")
		local group_targets = nil

		if group_extension and group_extension.use_patrol_perception then
			local group = group_extension.group
			group_targets = group.target_units
		end

		for i = 1, num_player_targets do
			local target_unit = enemy_player_targets[i]
			local is_unwanted = AiUtils.is_unwanted_target(side, target_unit)

			if not is_unwanted then
				local score, distance_sq = _calculate_closest_target_with_spillover_score(ai_unit, target_unit, target_current, previous_attacker, ai_unit_position, raycast_pos, breed, detection_radius_sq, perception_previous_attacker_stickyness_value, is_horde, group_targets)

				if score and score < best_score then
					best_score = score
					best_target_unit = target_unit
					distance_to_target_sq = distance_sq
				end
			end
		end
	end

	return best_target_unit, distance_to_target_sq
end)

enigma:hook(AISystem, "_update_taunt", function(func, self, t, blackboard)
    if blackboard.indefinite_taunt and blackboard.taunt_unit and Unit.alive(blackboard.taunt_unit) then
        blackboard.target_unit = blackboard.taunt_unit
        return
    end
    func(self, t, blackboard)
end)

enigma:hook(AiUtils, "is_unwanted_target", function(func, side, enemy_unit)
    if enemy_unit and Unit.has_data(enemy_unit, "untargetable") then
        return true
    end
    return func(side, enemy_unit)
end)