local enigma = get_mod("Enigma")

enigma:hook(BTTeleportToCommanderAction, "run", function(func, self, unit, blackboard, t, dt)
    -- Override the game's base behavior of killing the pet and summoning a new one nearby
    -- Instead, actually teleport this unit
    local locomotion = ScriptUnit.extension(unit, "locomotion_system")
    if not locomotion or not locomotion.teleport_to then
        return func(self, unit, blackboard, t, dt)
    end
    local ai_system = Managers.state.entity:system("ai_system")
    if not ai_system then
        return func(self, unit, blackboard, t, dt)
    end
	local nav_world = ai_system:nav_world()
    if not nav_world then
        return func(self, unit, blackboard, t, dt)
    end

	local commander_unit = self.commander_system:get_commander_unit(unit)

	if not ALIVE[commander_unit] then
		return "done"
	end

    local relative_position = Vector3(0, 2, 0)

    local fp_rotation_flat = nil
    
    local first_person = ScriptUnit.extension(commander_unit, "first_person_system")
	if first_person then
		fp_rotation_flat = first_person:current_rotation()
		fp_rotation_flat = Quaternion.look(Vector3.flat(Quaternion.forward(fp_rotation_flat)), Vector3.up())
	else
        local game_object_id = Managers.state.unit_storage:go_id(commander_unit)
        local game = Managers.state.network:game()
        local aim_direction = GameSession.game_object_field(game, game_object_id, "aim_direction")
        fp_rotation_flat = Quaternion.look(Vector3.flat(aim_direction), Vector3.up())
	end

    if type(POSITION_LOOKUP[commander_unit]) == "userdata" then
        POSITION_LOOKUP[commander_unit] = Unit.world_position(commander_unit, 0)
    end
	local position = POSITION_LOOKUP[commander_unit] + Quaternion.rotate(fp_rotation_flat, relative_position)
	local unit_is_on_navmesh, z = GwNavQueries.triangle_from_position(nav_world, position, 2, 2)

	if unit_is_on_navmesh then
		position.z = z
	else
		position = GwNavQueries.inside_position_from_outside_position(nav_world, position, 2, 2, 5, 1)
	end

	if not position then
		return "running"
	end

    locomotion:teleport_to(position)

    return "done"
end)