local enigma = get_mod("Enigma")

local bm = {
    unit_buff_extensions = {},
    unit_stat_buff_indexes = {},
    global_stat_updated_callbacks = {},
    unit_stat_updated_callbacks = {},

    unit_custom_buffs = {},
    unit_stat_surges = {},

    _internal = {},
}
enigma.managers.buff = bm

local custom_buff_definitions = {
    chance_ignore_assassin = 0,
    chance_ignore_leech = 0,
    chance_ignore_packmaster = 0,
    chance_instantly_slay_man_sized_enemy = 0,
    dodge_range = 0,
    dodge_speed = 0,
    temporary_healing_received = 1.0,
}

-- Define global callbacks for when stats are updated
local update_ammo_extension = function(unit, stat, new)
    local ammo_ext = enigma:get_ammo_extension(unit)
    if not ammo_ext then
        return
    end
    ammo_ext:refresh_buffs()
end
bm.global_stat_updated_callbacks.clip_size = {
    update_ammo_extension
}
bm.global_stat_updated_callbacks.total_ammo = {
    update_ammo_extension
}

local update_movement_stat = function(unit, stat, new, old, path_to_setting)
    local bonus
    local multiplier
    if old == 0 then
        bonus = new - old
    else
        multiplier = new / old
    end

    local buff = {
        template = {
            path_to_movement_setting_to_modify = path_to_setting
        }
    }
    local params = {
        bonus = bonus,
        multiplier = multiplier
    }
    BuffFunctionTemplates.functions.apply_movement_buff(unit, buff, params)
end
local update_movement_speed = function(unit, stat, new, old)
    update_movement_stat(unit, stat, new, old, { "move_speed" })
end
local update_dodge_range = function(unit, stat, new, old)
    update_movement_stat(unit, stat, new, old, { "dodging", "distance_modifier" })
end
local update_dodge_speed = function(unit, stat, new, old)
    update_movement_stat(unit, stat, new, old, { "dodging", "speed_modifier" })
end
bm.global_stat_updated_callbacks.movement_speed = {
    update_movement_speed
}
bm.global_stat_updated_callbacks.dodge_range = {
    update_dodge_range
}
bm.global_stat_updated_callbacks.dodge_speed = {
    update_dodge_speed
}

bm._update_proc_buff = function(self, buff_extension, stat, difference, index)
	local stat_buffs = buff_extension._stat_buffs
	local stat_buff = stat_buffs[stat]
	index = index or 1

    local current_proc_chance = stat_buff[index].proc_chance
    stat_buff[index].proc_chance = current_proc_chance + difference

    return stat_buff[index].proc_chance
end

local invoke_stat_updated_callbacks = function(unit, stat, new_value, old_value)
    if bm.global_stat_updated_callbacks[stat] then
        for _,cb in pairs(bm.global_stat_updated_callbacks[stat]) do
            enigma:pcall(cb, unit, stat, new_value, old_value)
        end
    end
    if bm.unit_stat_updated_callbacks[unit] and bm.unit_stat_updated_callbacks[unit][stat] then
        for _,cb in pairs(bm.unit_stat_updated_callbacks[unit][stat]) do
            enigma:pcall(cb, unit, stat, new_value, old_value)
        end
    end
end

bm.update_stat = function(self, unit, stat, difference)
    local old_value
    local new_value

    local custom_buffs = self.unit_custom_buffs[unit]
    if custom_buffs and custom_buffs[stat] then
        old_value = custom_buffs[stat]
        custom_buffs[stat] = old_value + difference
        new_value = custom_buffs[stat]
        enigma:info("Changed custom stat by: "..tostring(difference))
    else
        local index = self.unit_stat_buff_indexes[unit] and self.unit_stat_buff_indexes[unit][stat]
        local buff_extension = self.unit_buff_extensions[unit]
        if not unit or not stat or not buff_extension then
            enigma:echo("Could not update stat")
            return
        end
        if not index then
            enigma:echo("unit does not have that stat")
            enigma:dump(self.unit_stat_buff_indexes[unit], "STAT BUFFS", 2)
            return
        end
        
        local application_method = StatBuffApplicationMethods[stat]
        if application_method == "min" then
            enigma:warning("Cannot update min buff ["..stat.."]. You must remove the existing buff and re-apply it with a different value")
            return
        end

        if application_method == "proc" then
            new_value = self:_update_proc_buff(buff_extension, stat, difference, index)
            old_value = new_value - difference
        else
            new_value = buff_extension:update_stat_buff(stat, difference, index)
            old_value = new_value - difference
        end
    end
    invoke_stat_updated_callbacks(unit, stat, new_value, old_value)
end

bm.surge_stat = function(self, unit, stat, difference, card)
    self:update_stat(unit, stat, difference)
    table.insert(self.unit_stat_surges[unit], {
        stat = stat,
        difference = difference,
        remaining_duration = card.duration
    })
end

enigma:command("buff_self", "", function(stat, value)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit then
        return
    end
    bm:update_stat(local_player_unit, stat, value)
end)

-- Umbrella Buff
local ENIGMA_UMBRELLA_BUFF = "enigma_umbrella_buff"

local umbrella_stat_buffs = {}
local set_default_value_based_on_application_method = function(buff_table, application_method)
    local stat = buff_table.stat_buff
    if not stat then
        return
    end
    if not application_method then
        return
    end
    if (application_method == "stacking_multiplier") or (application_method == "stacking_multiplier_multiplicative") then
        buff_table.multiplier = 0.0
    elseif application_method == "stacking_bonus" then
        buff_table.bonus = 0.0
    elseif application_method == "stacking_bonus_and_multiplier" then
        buff_table.bonus = 0
        buff_table.multiplier = 0.0
    elseif application_method == "proc" then
        buff_table.proc_chance = 0.0
    end
end
local include_stat = function(stat, method)
    if type(stat) ~= "string" then
        return false
    end
    if method == "min" then
        return false
    end
    local weapon_damage_to_include = {
        increased_weapon_damage_melee = true,
        increased_weapon_damage_melee_1h = true,
        increased_weapon_damage_melee_2h = true,
        increased_weapon_damage_heavy_attack = true,
        increased_weapon_damage_poisoned_or_bleeding = true,
        increased_weapon_damage_ranged = true,
        increased_weapon_damage_ranged_to_wounded = true,
    }
    if weapon_damage_to_include[stat] then
        return true
    end
    if stat:find("increased_weapon_damage_") then
        return false -- Exclude a bunch of weapon-specific damage multipliers
    end
    return true
end
local apply_stat_specific_properties = function(stat, buff_table)
    if stat == "movement_speed" then
        buff_table.multiplier = 1.0
        buff_table.apply_buff_func = "apply_movement_buff"
        buff_table.remove_buff_func = "remove_movement_buff"
        buff_table.path_to_movement_setting_to_modify = {
            "move_speed"
        }
    end
end
for stat,method in pairs(StatBuffApplicationMethods) do
    if include_stat(stat, method) then
        local new_buff_table = {
            stat_buff = stat,
            name = "enigma_umbrella_stat_"..stat
        }
        set_default_value_based_on_application_method(new_buff_table, method)
        apply_stat_specific_properties(stat, new_buff_table)
        table.insert(umbrella_stat_buffs, new_buff_table)
    end
end

local umbrella_events = {}
for _,event in ipairs(ProcEvents) do
    table.insert(umbrella_events, {
        event = event,
        buff_func = "?"
    })
end

local index = #NetworkLookup.buff_templates + 1
NetworkLookup.buff_templates[index] = ENIGMA_UMBRELLA_BUFF
NetworkLookup.buff_templates[ENIGMA_UMBRELLA_BUFF] = index

BuffTemplates[ENIGMA_UMBRELLA_BUFF] = {
    buffs = {}
}

table.append(BuffTemplates[ENIGMA_UMBRELLA_BUFF].buffs, umbrella_stat_buffs)
--table.append(BuffTemplates[ENIGMA_UMBRELLA_BUFF].buffs, umbrella_events)



-- Hooks
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

enigma:hook(BuffExtension, "clear", function(func, self)
    bm.unit_buff_extensions[self._unit] = nil
    bm.unit_stat_buff_indexes[self._unit] = nil
    return func(self)
end)

enigma:hook(BuffExtension, "_add_stat_buff", function(func, self, sub_buff_template, buff)
    local index = func(self, sub_buff_template, buff)
    bm.unit_stat_buff_indexes[self._unit][sub_buff_template.stat_buff] = index
    return func(self, sub_buff_template, buff)
end)
enigma:hook_disable(BuffExtension, "_add_stat_buff")

enigma:hook(BuffExtension, "extensions_ready", function(func, self, world, unit)
    local breed = Unit.get_data(unit, "breed")
	if breed and breed.is_player and breed.is_hero then
        if enigma:is_server() or unit == enigma:local_player_unit() then
            enigma:info("Adding buff data for ("..tostring(breed and breed.name)..")")
            bm.unit_stat_buff_indexes[self._unit] = {}
            bm.unit_custom_buffs[self._unit] = table.shallow_copy(custom_buff_definitions)
            bm.unit_stat_surges[self._unit] = {}
            enigma:hook_enable(BuffExtension, "_add_stat_buff")
            self:add_buff(ENIGMA_UMBRELLA_BUFF)
            enigma:hook_disable(BuffExtension, "_add_stat_buff")
            bm.unit_buff_extensions[unit] = self
        end
    end
    return func(self, world, unit)
end)

enigma:hook(DamageUtils, "apply_buffs_to_heal", function(func, healed_unit, healer_unit, heal_amount, heal_type, healed_units)
    local healed_unit_custom_buffs = bm.unit_custom_buffs[healed_unit]
    if healed_unit_custom_buffs and healed_unit_custom_buffs.temporary_healing_received then
        local status_ext = ScriptUnit.has_extension(healed_unit, "status_system")
        if status_ext and not status_ext:is_permanent_heal(heal_type) then
            heal_amount = heal_amount * healed_unit_custom_buffs.temporary_healing_received
        end
    end

    return func(healed_unit, healer_unit, heal_amount, heal_type, healed_units)
end)

enigma:hook(BTTargetPouncedAction, "enter", function(func, self, unit, blackboard, t)
    local pounced_unit = blackboard.jump_data and blackboard.jump_data.target_unit
    local custom_buffs = pounced_unit and bm.unit_custom_buffs[pounced_unit]
    enigma:info("Attempting to enter target pounced action")
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_assassin) then
        enigma:info("Skipping entering target pounced action")
        enigma:execute_unit(unit, pounced_unit)
        return
    end
    return func(self, unit, blackboard, t)
end)

enigma:hook(BTPackMasterAttackAction, "attack_success", function(func, self, unit, blackboard)
    local hook_target = blackboard.target_unit
    local custom_buffs = hook_target and bm.unit_custom_buffs[hook_target]
    enigma:info("Attempting to enter hook attack action")
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_packmaster) then
        enigma:info("Skipping entering hook attack action")
        enigma:execute_unit(unit, hook_target)
        return
    end
    return func(self, unit, blackboard)
end)

enigma:hook(BTCorruptorGrabAction, "grab_player", function(func, self, t, unit, blackboard)
    local leech_target = blackboard.corruptor_target
    local custom_buffs = leech_target and bm.unit_custom_buffs[leech_target]
    enigma:info("Attempting to enter leech grab action")
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_leech) then
        enigma:info("Skipping entering leech grab action")
        enigma:execute_unit(unit, leech_target)
        return
    end
    return func(self, t, unit, blackboard)
end)

reg_hook_safe(GenericHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    local unit = self.unit
    local breed = ALIVE[unit] and Unit.get_data(unit, "breed")
    if attacker_unit and breed and not breed.boss and damage_type ~= "execute" then
        local attacker_custom_buffs = bm.unit_custom_buffs[attacker_unit]
        enigma:info("Chance to instantly slay = "..tostring(attacker_custom_buffs and attacker_custom_buffs.chance_instantly_slay_man_sized_enemy))
        if attacker_custom_buffs and math.random() < attacker_custom_buffs.chance_instantly_slay_man_sized_enemy then
            enigma:execute_man_sized_enemy(attacker_unit, {unit})
        end
    end
end, "enigma_buff")

--reg_hook_safe(PlayerUnitHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
--    enigma:info("Player damaged, damage_type="..tostring(damage_type)..", damage_amount="..tostring(damage_amount)..", attack_type="..tostring(attack_type)..", damage_source_name="..tostring(damage_source_name))
--end, "enigma_buff_debug")

-- Events
bm.on_game_state_changed = function(self, status, state_name)
    if state_name == "StateLoading" and status == "enter" then
        self.unit_stat_buff_indexes = {}
        self.unit_buff_extensions = {}
        self.unit_custom_buffs = {}
        self.unit_stat_surges = {}
        self._internal.assassin_immunity_tokens = {}
	end
end
enigma:register_mod_event_callback("on_game_state_changed", bm, "on_game_state_changed")

bm.update = function(self, dt)
    for unit,unit_stat_surges in pairs(self.unit_stat_surges) do
        local finished_surges = {}
        for i,surge in ipairs(unit_stat_surges) do
            surge.remaining_duration = surge.remaining_duration - dt
            if surge.remaining_duration <= 0 then
                table.insert(finished_surges, i)
            end
        end
        for i=#finished_surges,1,-1 do
            local surge = unit_stat_surges[i]
            self:update_stat(unit, surge.stat, -1*surge.difference)
        end
    end
end
enigma:register_mod_event_callback("update", bm, "update")

-- Debug
enigma:command("dump_buffs", "", function()
    local buff_extension = ScriptUnit.extension(enigma:local_player_unit(), "buff_system")
    enigma:dump(buff_extension._stat_buffs, "STAT BUFFS", 3)
end)

enigma:command("dump_network_constants", "", function()
    for k,v in pairs(NetworkConstants) do
        if type(v) == "table" then
            enigma:dump(v, "NetworkConstants."..k, 1)
        end
    end
end)