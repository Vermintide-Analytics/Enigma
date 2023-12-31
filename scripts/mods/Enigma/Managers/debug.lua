local enigma = get_mod("Enigma")

local dm = {
    aura_color = ColorBox(255, 255, 255, 0),
    aura_radius = nil,

    cone_color = ColorBox(255, 255, 0, 255),
    cone_length = nil,
    cone_degrees = nil,

    damage_debug = false
}
enigma.managers.debug = dm

-- Util
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end
local unhook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:unhook_safe("Enigma", obj, func_name, func, hook_id)
end

local print_health_ext_damage = function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    enigma:info("-------------------------")
    enigma:info("Add damage: "..tostring(damage_amount))
    enigma:info("    hit_zone_name: "..tostring(hit_zone_name))
    enigma:info("    damage_type: "..tostring(damage_type))
    enigma:info("    hit_position: "..tostring(hit_position))
    enigma:info("    damage_direction: "..tostring(damage_direction))
    enigma:info("    damage_source_name: "..tostring(damage_source_name))
    enigma:info("    hit_react_type: "..tostring(hit_react_type))
    enigma:info("    is_critical_strike: "..tostring(is_critical_strike))
    enigma:info("    added_dot: "..tostring(added_dot))
    enigma:info("    first_hit: "..tostring(first_hit))
    enigma:info("    total_hits: "..tostring(total_hits))
    enigma:info("    attack_type: "..tostring(attack_type))
    enigma:info("    backstab_multiplier: "..tostring(backstab_multiplier))
end

local print_add_damage_network_player = function(damage_profile, target_index, power_level, hit_unit, attacker_unit, hit_zone_name, hit_position, attack_direction, damage_source, hit_ragdoll_actor, boost_curve_multiplier, is_critical_strike, added_dot, first_hit, total_hits, backstab_multiplier, source_attacker_unit)
    enigma:info("+++++++++++++++++++++++++")
    enigma:info("Add damage: "..tostring(damage_profile))
    enigma:info("    hit_zone_name: "..tostring(hit_zone_name))
    enigma:info("    target_index: "..tostring(target_index))
    enigma:info("    hit_position: "..tostring(hit_position))
    enigma:info("    power_level: "..tostring(power_level))
    enigma:info("    damage_source: "..tostring(damage_source))
    enigma:info("    boost_curve_multiplier: "..tostring(boost_curve_multiplier))
    enigma:info("    is_critical_strike: "..tostring(is_critical_strike))
    enigma:info("    added_dot: "..tostring(added_dot))
    enigma:info("    first_hit: "..tostring(first_hit))
    enigma:info("    total_hits: "..tostring(total_hits))
    enigma:info("    backstab_multiplier: "..tostring(backstab_multiplier))
end

-- Commands
enigma:command("enigma_draw_aura", "Draw a sphere of a specific radius around you. If no radius provided, hides the sphere", function(radius)
    if not radius then
        dm.aura_radius = nil
        LineObject.reset(dm.line_object)
        LineObject.dispatch(dm.line_object_world, dm.line_object)
        enigma:echo("Debug aura visualization turned off")
        return
    end
    if dm.aura_radius then
        LineObject.reset(dm.line_object)
        LineObject.dispatch(dm.line_object_world, dm.line_object)
    end
    dm.aura_radius = radius
    if dm.line_object then
        World.destroy_line_object(dm.line_object_world, dm.line_object)
    end
    dm.line_object_world = Managers.world:world("level_world")
    dm.line_object = World.create_line_object(dm.line_object_world)
    enigma:echo("Debug aura visualization radius set to "..tostring(radius))
end)

enigma:command("enigma_draw_front_cone", "", function(length, degrees)
    length = tonumber(length)
    degrees = tonumber(degrees)
    if length and degrees then
        if dm.cone_length then
            LineObject.reset(dm.line_object)
            LineObject.dispatch(dm.line_object_world, dm.line_object)
        end
        dm.cone_length = length
        dm.cone_degrees = math.clamp(degrees/2, 0, 89)
    else
        dm.cone_length = nil
        dm.cone_degrees = nil
    end
    if dm.line_object then
        World.destroy_line_object(dm.line_object_world, dm.line_object)
    end
    dm.line_object_world = Managers.world:world("level_world")
    dm.line_object = World.create_line_object(dm.line_object_world)
end)

enigma:command("enigma_debug_damage", "Toggle verbose debug print to console of damage events", function()
    dm.damage_debug = not dm.ddamage_debug
    if dm.damage_debug then
        reg_hook_safe(GenericHealthExtension, "add_damage", print_health_ext_damage, "debug_enemy_damaged")
        reg_hook_safe(DamageUtils, "add_damage_network_player", print_add_damage_network_player, "debug_add_damage_network_player")
    else
        unhook_safe(GenericHealthExtension, "add_damage", print_health_ext_damage, "debug_enemy_damaged")
        unhook_safe(DamageUtils, "add_damage_network_player", print_add_damage_network_player, "debug_add_damage_network_player")
    end
end)

-- Events
dm.update = function(self, dt)
    local dispatch = false
    if self.aura_radius then
        local local_player_unit = enigma:local_player_unit()
        if local_player_unit then
            local center = Unit.world_position(local_player_unit, 0)
            LineObject.add_sphere(self.line_object, self.aura_color:unbox(), center, self.aura_radius, 50, 10)
            dispatch = true
        end
    end
    if self.cone_length then
        local local_player_unit = enigma:local_player_unit()
        if local_player_unit then
            if ScriptUnit.has_extension(local_player_unit, "first_person_system") then
                local_player_unit = ScriptUnit.extension(local_player_unit, "first_person_system"):get_first_person_unit()
            end
            local center = Unit.world_position(local_player_unit, 0)
            local direction = Vector3.normalize(Quaternion.forward(Unit.world_rotation(local_player_unit, 0)))
            local radius = self.cone_length * math.tan(math.rad(self.cone_degrees))
            LineObject.add_cone(self.line_object, self.cone_color:unbox(), center, center + (direction * self.cone_length), radius, 50, 10)
            dispatch = true
        end
    end
    if dispatch then
        LineObject.dispatch(self.line_object_world, self.line_object)
        LineObject.reset(self.line_object)
    end
end
enigma:register_mod_event_callback("update", dm, "update")
