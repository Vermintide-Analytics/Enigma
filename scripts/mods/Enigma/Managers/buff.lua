local enigma = get_mod("Enigma")

local ENIGMA_UMBRELLA_BUFF = "enigma_umbrella_buff"
local umbrella_stat_buffs = {}

local net = {
    surge_stat = "surge_stat",
    update_stat = "update_stat"
}

local bm = {
    player_units = {},

    unit_buff_extensions = {},
    unit_stat_buff_indexes = {},
    global_stat_updated_callbacks = {},
    unit_stat_updated_callbacks = {},
    unit_custom_buffs = {},

    unit_builtin_buffs = {},
    unit_stat_surges = {},

    _internal = {},
}
enigma.managers.buff = bm

local custom_buff_definitions = {
    added_card_cost = 0,
    added_card_cost_ability = 0,
    added_card_cost_attack = 0,
    added_card_cost_chaos = 0,
    added_card_cost_passive = 0,
    aggro = 0,
    aggro_beastmen = 0,
    aggro_chaos = 0,
    aggro_elite = 0,
    aggro_skaven = 0,
    aggro_trash = 0,
    attack_card_power_multiplier = 1.0,
    cannot_use_career_skill = 0,
    card_draw_multiplier = 1.0,
    chance_ignore_assassin = 0,
    chance_ignore_blightstorm_damage = 0,
    chance_ignore_blightstormer = 0,
    chance_ignore_fire_rat = 0,
    chance_ignore_globadier = 0,
    chance_ignore_gunner = 0,
    chance_ignore_leech = 0,
    chance_ignore_packmaster = 0,
    chance_instantly_slay_man_sized_enemy = 0,
    dodge_range = 1.0,
    dodge_speed = 1.0,
    temporary_healing_received = 1.0,
    warp_dust_multiplier = 1.0,
}
local builtin_buff_definitions = {
    movement_speed = 1
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
    if new == 0 then
        enigma:warning(tostring(stat).." multiplier became 0, movement will not behave correctly after this point")
        new = 0.001
    end
    old = (old == 0 and 0.001) or old
    local multiplier = new / old

    local buff = {
        template = {
            path_to_movement_setting_to_modify = path_to_setting
        }
    }
    local params = {
        multiplier = multiplier,
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

-- Set card UI dirty when cost modifier has updated
local set_all_ingame_card_ui_dirty = function(card_predicate)
    if not enigma.managers.game:is_in_game() then
        return
    end
    for _,card in ipairs(enigma.managers.game.local_data.all_cards) do
        if not card_predicate or card_predicate(card) then
            enigma.managers.game:card_cost_changed(card)
            card:set_dirty()
        end
    end
end
local card_cost_stat_updated = function(unit, stat, new, old, card_type)
    if unit ~= enigma:local_player_unit() then
        return
    end
    local predicate = nil
    if card_type then
        predicate = function(card)
            return card.card_type == card_type
        end
    end
    set_all_ingame_card_ui_dirty(predicate)
end
local ability_card_cost_updated = function(unit, stat, new, old)
    card_cost_stat_updated(unit, stat, new, old, enigma.CARD_TYPE.ability)
end
local attack_card_cost_updated = function(unit, stat, new, old)
    card_cost_stat_updated(unit, stat, new, old, enigma.CARD_TYPE.attack)
end
local chaos_card_cost_updated = function(unit, stat, new, old)
    card_cost_stat_updated(unit, stat, new, old, enigma.CARD_TYPE.chaos)
end
local passive_card_cost_updated = function(unit, stat, new, old)
    card_cost_stat_updated(unit, stat, new, old, enigma.CARD_TYPE.passive)
end
bm.global_stat_updated_callbacks.added_card_cost = {
    card_cost_stat_updated
}
bm.global_stat_updated_callbacks.added_card_cost_ability = {
    ability_card_cost_updated
}
bm.global_stat_updated_callbacks.added_card_cost_attack = {
    attack_card_cost_updated
}
bm.global_stat_updated_callbacks.added_card_cost_chaos = {
    chaos_card_cost_updated
}
bm.global_stat_updated_callbacks.added_card_cost_passive = {
    passive_card_cost_updated
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

local handle_update_stat = function(unit, stat, difference)
    local old_value
    local new_value

    local custom_buffs = bm.unit_custom_buffs[unit]
    local builtin_buffs = bm.unit_builtin_buffs[unit]
    if custom_buffs and custom_buffs[stat] then
        old_value = custom_buffs[stat]
        custom_buffs[stat] = old_value + difference
        new_value = custom_buffs[stat]
    elseif builtin_buffs and builtin_buffs[stat] then
        old_value = builtin_buffs[stat]
        builtin_buffs[stat] = old_value + difference
        new_value = builtin_buffs[stat]

        local index = bm.unit_stat_buff_indexes[unit] and bm.unit_stat_buff_indexes[unit][stat]
        local buff_extension = bm.unit_buff_extensions[unit]
        if not unit or not stat or not buff_extension then
            enigma:echo("Could not update stat... buff: "..tostring(unit).." | stat: "..tostring(stat).." | buff_extension: "..tostring(buff_extension))
            return
        end
        if not index then
            enigma:echo("unit does not have that stat")
            enigma:dump(bm.unit_stat_buff_indexes[unit], "STAT BUFFS", 2)
            return
        end
        
        local application_method = StatBuffApplicationMethods[stat]
        if application_method == "min" then
            enigma:warning("Cannot update min buff ["..stat.."]. You must remove the existing buff and re-apply it with a different value")
            return
        end

        if application_method == "proc" then
            bm:_update_proc_buff(buff_extension, stat, difference, index)
        else
            buff_extension:update_stat_buff(stat, difference, index)
        end
    end
    enigma:info("Unit: "..tostring(unit)..": Stat "..stat.." updated from "..old_value.." to "..new_value)
    invoke_stat_updated_callbacks(unit, stat, new_value, old_value)
end

enigma:network_register(net.update_stat, function(sender, unit_go_id, stat, difference)
    local unit = Managers.state.unit_storage:unit(unit_go_id)
    if not unit then
        enigma:info("Could not find unit to buff per request from "..tostring(sender))
        return
    end
    handle_update_stat(unit, stat, difference)
end)
bm.update_stat = function(self, unit, stat, difference)
    handle_update_stat(unit, stat, difference)
    local unit_go_id = Managers.state.unit_storage:go_id(unit)
    enigma:network_send(net.update_stat, "others", unit_go_id, stat, difference)
end
bm.update_stat_locally = function(self, unit, stat, difference)
    handle_update_stat(unit, stat, difference)
end

local handle_surge_stat = function(unit, stat, difference, duration)
    if not bm.unit_stat_surges[unit] then
        enigma:warning("Cannot surge stat")
    end
    handle_update_stat(unit, stat, difference)
    table.insert(bm.unit_stat_surges[unit], {
        stat = stat,
        difference = difference,
        remaining_duration = duration
    })
end

enigma:network_register(net.surge_stat, function(sender, unit_go_id, stat, difference, duration)
    local unit = Managers.state.unit_storage:unit(unit_go_id)
    if not unit then
        enigma:info("Could not find unit to buff per request from "..tostring(sender))
        return
    end
    handle_surge_stat(unit, stat, difference, duration)
end)
bm.surge_stat = function(self, unit, stat, difference, duration)
    handle_surge_stat(unit, stat, difference, duration)
    local unit_go_id = Managers.state.unit_storage:go_id(unit)
    enigma:network_send(net.surge_stat, "others", unit_go_id, stat, difference, duration)
end
bm.surge_stat_locally = function(self, unit, stat, difference, duration)
    handle_surge_stat(unit, stat, difference, duration)
end

bm._register_player = function(self, player)
    self:_register_player_unit(player, player.player_unit)
end

bm._register_player_unit = function(self, player, unit)
    local previous_player_unit = self.player_units[player]
    self.player_units[player] = unit

    local buff_ext = ScriptUnit.extension(unit, "buff_system")
    bm.unit_buff_extensions[unit] = buff_ext
    bm.unit_stat_buff_indexes[unit] = {}
    enigma:hook_enable(BuffExtension, "_add_stat_buff")
    buff_ext:add_buff(ENIGMA_UMBRELLA_BUFF)
    enigma:hook_disable(BuffExtension, "_add_stat_buff")
    
    local breed = Unit.get_data(unit, "breed")

    if previous_player_unit and previous_player_unit ~= unit then
        enigma:info("Persisting buff data for "..tostring(unit).." ("..tostring(breed and breed.name)..")")
        bm.unit_custom_buffs[unit] = bm.unit_custom_buffs[previous_player_unit]
        bm.unit_builtin_buffs[unit] = bm.unit_builtin_buffs[previous_player_unit]
        bm.unit_stat_surges[unit] = bm.unit_stat_surges[previous_player_unit]
        
        bm.unit_custom_buffs[previous_player_unit] = nil
        bm.unit_builtin_buffs[previous_player_unit] = nil
        bm.unit_stat_surges[previous_player_unit] = nil

        for stat,current_value in pairs(bm.unit_custom_buffs[unit]) do
            local difference = current_value - custom_buff_definitions[stat]
            if difference ~= 0 then
                bm.unit_custom_buffs[unit][stat] = custom_buff_definitions[stat]
                enigma:info("Updating "..tostring(stat).." by "..tostring(difference).." when persisting buffs")
                handle_update_stat(unit, stat, difference)
            end
        end
        for stat,current_value in pairs(bm.unit_builtin_buffs[unit]) do
            local difference = current_value - builtin_buff_definitions[stat]
            if difference ~= 0 then
                bm.unit_builtin_buffs[unit][stat] = builtin_buff_definitions[stat]
                enigma:info("Updating "..tostring(stat).." by "..tostring(difference).." when persisting buffs")
                handle_update_stat(unit, stat, difference)
            end
        end
    else
        enigma:info("Adding buff data for "..tostring(unit).." ("..tostring(breed and breed.name)..")")
        bm.unit_custom_buffs[unit] = table.shallow_copy(custom_buff_definitions)
        bm.unit_builtin_buffs[unit] = table.shallow_copy(builtin_buff_definitions)
        bm.unit_stat_surges[unit] = {}
    end
end

bm._reset_player = function(self, player)
    if not self.unit_stat_buff_indexes then
        return
    end
    local unit = player.player_unit
    local buff_ext = ScriptUnit.extension(unit, "buff_system")
    if not unit or not buff_ext then
        enigma:echo("No player buffs to reset")
        return
    end
    for stat,current_value in pairs(self.unit_custom_buffs[unit]) do
        local difference = custom_buff_definitions[stat] - current_value
        if difference ~= 0 then
            enigma:info("Updating "..tostring(stat).." by "..tostring(difference).." when resetting buffs")
            handle_update_stat(unit, stat, difference)
        end
    end
    for stat,current_value in pairs(self.unit_builtin_buffs[unit]) do
        local difference = builtin_buff_definitions[stat] - current_value
        if difference ~= 0 then
            enigma:info("Updating "..tostring(stat).." by "..tostring(difference).." when resetting buffs")
            handle_update_stat(unit, stat, difference)
        end
    end
    buff_ext:remove_buff(ENIGMA_UMBRELLA_BUFF)
    self.unit_stat_surges[unit] = {}
end

bm._reset_players = function(self)
    for player,_ in pairs(self.player_units) do
        self:_reset_player(player)
    end
end

local buff_params = {}

enigma.add_dot = function(dot_template_name, hit_unit, attacker_unit, damage_source, power_level, source_attacker_unit)
	if ScriptUnit.has_extension(hit_unit, "buff_system") then
		table.clear(buff_params)

		buff_params.attacker_unit = attacker_unit
		buff_params.damage_source = damage_source
		buff_params.power_level = power_level
		buff_params.source_attacker_unit = source_attacker_unit
		local buff_extension = ScriptUnit.extension(hit_unit, "buff_system")

		buff_extension:add_buff(dot_template_name, buff_params)
	end
end


-- Umbrella Buff

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
        builtin_buff_definitions[stat] = builtin_buff_definitions[stat] or 0
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
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_assassin) then
        enigma:execute_unit(unit, pounced_unit)
        return
    end
    return func(self, unit, blackboard, t)
end)

enigma:hook(BTPackMasterAttackAction, "attack_success", function(func, self, unit, blackboard)
    local hook_target = blackboard.target_unit
    local custom_buffs = hook_target and bm.unit_custom_buffs[hook_target]
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_packmaster) then
        enigma:execute_unit(unit, hook_target)
        return
    end
    return func(self, unit, blackboard)
end)

enigma:hook(BTCorruptorGrabAction, "grab_player", function(func, self, t, unit, blackboard)
    local leech_target = blackboard.corruptor_target
    local custom_buffs = leech_target and bm.unit_custom_buffs[leech_target]
    if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_leech) then
        enigma:execute_unit(unit, leech_target)
        return
    end
    return func(self, t, unit, blackboard)
end)

enigma:hook(CareerExtension, "can_use_activated_ability", function(func, self, ability_id)
    local unit = self._unit
    local custom_buffs = unit and bm.unit_custom_buffs[unit]
    if custom_buffs and custom_buffs.cannot_use_career_skill > 0 then
        return false
    end
    return func(self, ability_id)
end)

enigma:hook(DamageUtils, "_projectile_hit_character", function(func, current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, current_num_penetrations, current_amount_of_mass_hit, target_number)
    local shooter_breed = owner_unit and Unit.get_data(owner_unit, "breed")
    if shooter_breed and shooter_breed.name == "skaven_ratling_gunner" then
        local custom_buffs = hit_unit and bm.unit_custom_buffs[hit_unit]
        if custom_buffs and enigma:test_chance(custom_buffs.chance_ignore_gunner) then
            return 0, 0, 0, true
        end
    end
    return func(current_action, owner_unit, owner_player, owner_buff_extension, target_settings, hit_unit, hit_actor, hit_position, hit_rotation, hit_normal, is_husk, breed, is_server, check_buffs, is_critical_strike, difficulty_rank, power_level, ranged_boost_curve_multiplier, damage_profile, damage_source, critical_hit_effect, world, hit_effect, attack_direction, damage_source_id, damage_profile_id, max_targets, current_num_penetrations, current_amount_of_mass_hit, target_number)
end)

enigma:hook(GenericStatusExtension, "is_valid_vortex_target", function(func, self)
    local custom_buffs = self.unit and bm.unit_custom_buffs and bm.unit_custom_buffs[self.unit]
    if custom_buffs and custom_buffs.chance_ignore_blightstormer > 0 then
        if enigma:test_chance(custom_buffs.chance_ignore_blightstormer) then
            return false
        end
    end
    return func(self)
end)

reg_hook_safe(GenericHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    local unit = self.unit
    local breed = ALIVE[unit] and Unit.get_data(unit, "breed")
    if attacker_unit and breed and not breed.boss and damage_type ~= "execute" then
        local attacker_custom_buffs = bm.unit_custom_buffs[attacker_unit]
        if attacker_custom_buffs and enigma:test_chance(attacker_custom_buffs.chance_instantly_slay_man_sized_enemy) then
            enigma:execute_man_sized_enemy(unit, attacker_unit)
        end
    end
end, "enigma_buff")

--reg_hook_safe(PlayerUnitHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
--    enigma:info("Player damaged, damage_type="..tostring(damage_type)..", damage_amount="..tostring(damage_amount)..", attack_type="..tostring(attack_type)..", damage_source_name="..tostring(damage_source_name))
--end, "enigma_buff_debug")

-- Events
bm.on_game_state_changed = function(self, status, state_name)
    if state_name == "StateLoading" and status == "enter" then
        enigma:info("Resetting stat buff data for all units")
        self.player_units = {}
        self.unit_stat_buff_indexes = {}
        self.unit_buff_extensions = {}
        self.unit_custom_buffs = {}
        self.unit_builtin_buffs = {}
        self.unit_stat_surges = {}
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
            local surge = unit_stat_surges[finished_surges[i]]
            self:update_stat(unit, surge.stat, -1*surge.difference)
            table.remove(unit_stat_surges, finished_surges[i])
        end
        if #finished_surges > 0 then
            enigma:debug("Unit now has "..#unit_stat_surges.." active stat surges")
        end
    end
end
enigma:register_mod_event_callback("update", bm, "update")



-- Util
bm.get_warpstone_cost_modifier_from_buffs = function(self, card)
    local unit = card.context.unit
    local modifier = 0
    local card_type = card.card_type
    if not unit or not self.unit_custom_buffs[unit] then
        return 0
    end
    local custom_buffs = self.unit_custom_buffs[unit]
    modifier = modifier + custom_buffs.added_card_cost
    if card_type == enigma.CARD_TYPE.ability then
        modifier = modifier + custom_buffs.added_card_cost_ability
    elseif card_type == enigma.CARD_TYPE.attack then
        modifier = modifier + custom_buffs.added_card_cost_attack
    elseif card_type == enigma.CARD_TYPE.chaos then
        modifier = modifier + custom_buffs.added_card_cost_chaos
    elseif card_type == enigma.CARD_TYPE.passive then
        modifier = modifier + custom_buffs.added_card_cost_passive
    end
    return modifier
end
bm.get_final_warpstone_cost = function(self, card)
    local modifier_from_buffs = card.fixed_cost and 0 or self:get_warpstone_cost_modifier_from_buffs(card)
    local cost = card.cost
    if cost == "X" then
        cost = card.cost_modifier + modifier_from_buffs
        return "X", cost
    end
    return math.max(0, cost + modifier_from_buffs)
end


-- Debug
enigma:command("enigma_buff_self", "", function(stat, value)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit then
        return
    end
    bm:update_stat(local_player_unit, stat, value)
end)

enigma:command("enigma_add_perk", "", function(perk)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit then
        return
    end
    if not perk then
        return
    end
    enigma:apply_perk(local_player_unit, perk)
end)
enigma:command("enigma_remove_perk", "", function(perk)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit then
        return
    end
    if not perk then
        return
    end
    enigma:remove_perk(local_player_unit, perk)
end)

enigma:command("enigma_dump_buffs", "", function()
    local buff_extension = ScriptUnit.extension(enigma:local_player_unit(), "buff_system")
    enigma:dump(buff_extension._stat_buffs, "STAT BUFFS", 3)
end)

enigma:command("enigma_dump_network_constants", "", function()
    for k,v in pairs(NetworkConstants) do
        if type(v) == "table" then
            enigma:dump(v, "NetworkConstants."..k, 1)
        end
    end
end)

-- enigma:hook(BuffExtension, "apply_buffs_to_value", function(func, self, value, stat_buff)
--     local final_value, procced, id = func(self, value, stat_buff)
--     if stat_buff and stat_buff:find("damage") then
--         enigma:info("VALUE ("..tostring(stat_buff)..") ::: "..tostring(value).." -> "..tostring(final_value))
--     end
--     -- if stat_buff ~= "damage_taken" then
--     --     return func(self, value, stat_buff)
--     -- end
-- 	-- local stat_buffs = self._stat_buffs[stat_buff]
-- 	-- local final_value = value
-- 	-- local procced = false
-- 	-- local is_proc = StatBuffApplicationMethods[stat_buff] == "proc"
-- 	-- local id = nil
-- 	-- for name, stat_buff_data in pairs(stat_buffs) do
--     --     enigma:info("--------------------")
--     --     enigma:info("Stat Buff \""..tostring(name).."\"")
-- 	-- 	local proc_chance = stat_buff_data.proc_chance
--     --     enigma:info("proc_chance: "..tostring(proc_chance))
-- 	-- 	if self:has_procced(proc_chance, stat_buff) then
-- 	-- 		local bonus = stat_buff_data.bonus
--     --         enigma:info("bonus: "..tostring(bonus))
-- 	-- 		local multiplier = stat_buff_data.multiplier
--     --         enigma:info("multiplier: "..tostring(multiplier))
-- 	-- 		if type(multiplier) == "table" then
-- 	-- 			local wind_strength = Managers.weave:get_wind_strength()
-- 	-- 			multiplier = multiplier[wind_strength]
-- 	-- 		end
-- 	-- 		multiplier = multiplier + 1
-- 	-- 		final_value = final_value * multiplier + bonus
-- 	-- 		if is_proc then
-- 	-- 			procced = true
-- 	-- 			id = stat_buff_data.id
-- 	-- 			break
-- 	-- 		end
-- 	-- 	end
-- 	-- end
--     -- enigma:info("final_value: "..tostring(final_value))
-- 	return final_value, procced, id
-- end)