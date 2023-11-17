local enigma = get_mod("Enigma")

local bm = {
    unit_buff_extensions = {},
    unit_stat_buff_indexes = {},
    global_stat_updated_callbacks = {},
    unit_stat_updated_callbacks = {},
}
enigma.managers.buff = bm

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

local update_movement_speed = function(unit, stat, new, old)
    local bonus
    local multiplier
    if old == 0 then
        bonus = new - old
    else
        multiplier = new / old
    end

    local buff = {
        template = {
            path_to_movement_setting_to_modify = {
                "move_speed"
            }
        }
    }
    local params = {
        bonus = bonus,
        multiplier = multiplier
    }
    BuffFunctionTemplates.functions.apply_movement_buff(unit, buff, params)
end
bm.global_stat_updated_callbacks.movement_speed = {
    update_movement_speed
}

bm._multiply_stat_buff = function (self, buff_extension, stat, factor, index)
	local stat_buffs = buff_extension._stat_buffs
	local stat_buff = stat_buffs[stat]
	local application_method = StatBuffApplicationMethods[stat]
	index = index or 1

	if application_method == "stacking_bonus" then
		local current_bonus = stat_buff[index].bonus
		stat_buff[index].bonus = current_bonus * factor

		return stat_buff[index].bonus
	elseif application_method == "stacking_multiplier" or application_method == "stacking_multiplier_multiplicative" then
		local current_multiplier = stat_buff[index].multiplier
		stat_buff[index].multiplier = current_multiplier * factor

		return stat_buff[index].multiplier
	else
		fassert(false, "trying to multiply a stat with an incompatible application method")
	end
end

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

bm.update_stat = function(self, unit, stat, difference, change_type)
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
    change_type = change_type or "add"
    
    local application_method = StatBuffApplicationMethods[stat]
    if application_method == "min" then
        enigma:warning("Cannot update min buff ["..stat.."]. You must remove the existing buff and re-apply it with a different value")
        return
    end

    local new_value
    local old_value
    if application_method == "proc" then
        if change_type == "multiply" then
            enigma:warning("Attempted to multiply proc chance for ["..stat.."]. This is not possible, defaulting to addition.")
        end
        new_value = self:_update_proc_buff(buff_extension, stat, difference, index)
        old_value = new_value - difference
    elseif change_type == "multiply" then
        new_value = self:_multiply_stat_buff(buff_extension, stat, difference, index)
        old_value = new_value - difference
    else
        new_value = buff_extension:update_stat_buff(stat, difference, index)
        old_value = new_value - difference
    end
    invoke_stat_updated_callbacks(unit, stat, new_value, old_value)
end

enigma:command("buff_self", "", function(stat, value, change_type)
    local local_player_unit = enigma:local_player_unit()
    if not local_player_unit then
        return
    end
    bm:update_stat(local_player_unit, stat, value, change_type)
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
            bm.unit_stat_buff_indexes[self._unit] = {}
            enigma:hook_enable(BuffExtension, "_add_stat_buff")
            self:add_buff(ENIGMA_UMBRELLA_BUFF)
            enigma:hook_disable(BuffExtension, "_add_stat_buff")
            bm.unit_buff_extensions[unit] = self
        end
    end
    return func(self, world, unit)
end)

-- Events
bm.on_game_state_changed = function(self, status, state_name)
    if state_name == "StateLoading" and status == "enter" then
        self.unit_stat_buff_indexes = {}
        self.unit_buff_extensions = {}
	end
end
enigma:register_event_callback("on_game_state_changed", bm, "on_game_state_changed")

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