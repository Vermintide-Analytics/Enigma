local enigma = get_mod("Enigma")

local hm = {
    prehooks = {},
    hooks = {},
    complex_hooks = {}
}
enigma.managers.hook = hm

local hook_target = function(object, func_name)
    return tostring(object).."."..tostring(func_name)
end

local init_hook_safe = function(hook_manager, object, func_name)
    local hook_target_key = hook_target(object, func_name)
    hook_manager.prehooks[hook_target_key] = {}
    hook_manager.hooks[hook_target_key] = {}
    enigma:hook(object, func_name, function(func, ...)
        for _,hook in ipairs(hook_manager.prehooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        local _1,_2,_3,_4,_5,_6,_7,_8,_9,_10 = func(...)
        for _,hook in ipairs(hook_manager.hooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        -- Guess I'll have to find out the hard way if someone ever hooks a function that returns more than 10 values
        -- But it's probably not worth it to always pack and unpack the return value
        return _1,_2,_3,_4,_5,_6,_7,_8,_9,_10
    end)
end

hm.prehook_safe = function(self, mod_id, object, func_name, func, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.prehooks[hook_target_key]
    if not hook_target_table then
        init_hook_safe(self, object, func_name)
        hook_target_table = self.prehooks[hook_target_key]
    end
    local new_hook = {
        mod_id= mod_id,
        object=  object,
        func_name = func_name,
        func = func,
        hook_id = hook_id
    }
    table.insert(self.prehooks[hook_target_key], new_hook)
end

hm.unprehook_safe = function(self, mod_id, object, func_name, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.prehooks[hook_target_key]
    if not hook_target_table then
        return
    end
    local index
    for i,v in ipairs(hook_target_table) do
        if (v.mod_id == mod_id) and (v.hook_id == hook_id) then
            index = i
            break
        end
    end
    if index then
        table.remove(hook_target_table, index)
    end
end

hm.hook_safe = function(self, mod_id, object, func_name, func, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.hooks[hook_target_key]
    if not hook_target_table then
        init_hook_safe(self, object, func_name)
        hook_target_table = self.hooks[hook_target_key]
    end
    local new_hook = {
        mod_id= mod_id,
        object=  object,
        func_name = func_name,
        func = func,
        hook_id = hook_id
    }
    table.insert(self.hooks[hook_target_key], new_hook)
end

hm.unhook_safe = function(self, mod_id, object, func_name, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.hooks[hook_target_key]
    if not hook_target_table then
        return
    end
    local index
    for i,v in ipairs(hook_target_table) do
        if (v.mod_id == mod_id) and (v.hook_id == hook_id) then
            index = i
            break
        end
    end
    if index then
        table.remove(hook_target_table, index)
    end
end

local add_complex_hook = function(object, func_name, func)
    local hook_target_key = hook_target(object, func_name)
    hm.prehooks[hook_target_key] = {}
    hm.hooks[hook_target_key] = {}

    enigma:hook(object, func_name, function(orig_func, ...)
        for _,hook in ipairs(hm.prehooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        local _1,_2,_3,_4,_5,_6,_7,_8,_9,_10 = func(orig_func, ...)
        for _,hook in ipairs(hm.hooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        -- Guess I'll have to find out the hard way if someone ever hooks a function that returns more than 10 values
        -- But it's probably not worth it to always pack and unpack the return value
        return _1,_2,_3,_4,_5,_6,_7,_8,_9,_10
    end)
end

add_complex_hook(PlayerUnitHealthExtension, "add_damage", function(func, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    local player_unit = self.unit
    local attacker = attacker_unit or source_attacker_unit

    local buff_ext = player_unit and Unit.alive(player_unit) and ScriptUnit.extension(player_unit, "buff_system")
    if buff_ext and buff_ext:has_buff_perk("invincible") then
        return
    end

    local can_only_damage_unit = attacker and Unit.has_data(attacker, "can_only_damage_unit") and Unit.get_data(attacker, "can_only_damage_unit")
    if can_only_damage_unit and can_only_damage_unit ~= player_unit then
        return
    end
    local can_only_be_damaged_by = Unit.has_data(player_unit, "can_only_be_damaged_by_unit") and Unit.get_data(player_unit, "can_only_be_damaged_by_unit")
    if can_only_be_damaged_by and can_only_be_damaged_by ~= attacker then
        return
    end

    local custom_buffs = player_unit and enigma.managers.buff.unit_custom_buffs[player_unit]

    if custom_buffs then
        if (attack_type == "warpfire" or damage_type == "warpfire_ground") then
            if custom_buffs.chance_ignore_fire_rat > 0 and enigma:test_chance(custom_buffs.chance_ignore_fire_rat) then
                return -- Ignore the damage entirely
            end
        elseif damage_source_name == "skaven_poison_wind_globadier" then
            if custom_buffs.chance_ignore_globadier > 0 and enigma:test_chance(custom_buffs.chance_ignore_globadier) then
                return -- Ignore the damage entirely
            end
        elseif damage_source_name == "chaos_vortex_sorcerer" then
            if custom_buffs.chance_ignore_blightstormer > 0 and enigma:test_chance(custom_buffs.chance_ignore_blightstormer) or
            custom_buffs.chance_ignore_blightstorm_damage > 0 and enigma:test_chance(custom_buffs.chance_ignore_blightstorm_damage) then
                return -- Ignore the damage entirely
            end
        end
    end

    func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end)

local handle_damage_dealt = function(func, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    local ai_unit = self.unit
    local attacker = attacker_unit or source_attacker_unit

    local can_only_damage_unit = attacker and Unit.has_data(attacker, "can_only_damage_unit") and Unit.get_data(attacker, "can_only_damage_unit")
    if can_only_damage_unit and can_only_damage_unit ~= ai_unit then
        return
    end
    local can_only_be_damaged_by = Unit.has_data(ai_unit, "can_only_be_damaged_by_unit") and Unit.get_data(ai_unit, "can_only_be_damaged_by_unit")
    if can_only_be_damaged_by and can_only_be_damaged_by ~= attacker then
        return
    end

    return func(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end
add_complex_hook(GenericHealthExtension, "add_damage", handle_damage_dealt)
add_complex_hook(RatOgreHealthExtension, "add_damage", handle_damage_dealt)