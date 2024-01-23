local enigma = get_mod("Enigma")

local WARP_DUST_PER_WARPSTONE = 1000.0
local MAX_WARPSTONE = 5

local wm = {
    warpstone = 0,
    warp_dust = 0.0,
    deferred_warp_dust = 0.0,

    warp_dust_per_second = 1.5,
    warp_dust_per_damage_dealt = {
        trash = 0.18,
        elite = 0.37,
        special = 1.35,
        boss = 0.54
    },
    warp_dust_per_damage_taken = 1.5,
    warp_dust_per_stagger_seconds = {
        trash = 2.2,
        elite = 9.0,
        special = 10.0,
        boss = 22.0
    },
    base_warp_dust_per_level_progress = {
        adventure = 10000,
        deus = 6000
    },

    ranged_damage_warp_dust_multiplier = 1.2,
}
wm.warp_dust_per_level_progress = table.clone(wm.base_warp_dust_per_level_progress)
enigma.managers.warp = wm

wm.get_warpstone = function(self)
    return self.warpstone
end
wm.get_warp_dust = function(self)
    return self.warp_dust
end

local on_warpstone_amount_changed = function()
    enigma.managers.game:on_warpstone_amount_changed()
end

wm.start_game = function(self, game_mode)
    self.game_mode = game_mode
    self.warpstone = 0
    self.warp_dust = 0.0

    if self.game_mode == "deus" then
        self.warp_dust_per_level_progress.deus = self.warp_dust_per_level_progress.deus + enigma.managers.deus.extra_cards_taken*WARP_DUST_PER_WARPSTONE
        enigma:info("Increased level progress warpstone gain by "..tostring(enigma.managers.deus.extra_cards_taken).." for extra cards taken during deus run")
    end

    self.statistics = {
        earned_warp_dust = {
            passive = 0,

            damage_dealt_trash = 0,
            damage_dealt_elite = 0,
            damage_dealt_special = 0,
            damage_dealt_boss = 0,
            
            damage_taken = 0,

            stagger_trash = 0,
            stagger_elite = 0,
            stagger_special = 0,
            stagger_boss = 0,

            level_progress = 0,
            debug = 0,
            other = 0
        }
    }

    enigma:register_mod_event_callback("update", self, "update")
end

wm.end_game = function(self)
    local total_earned_warpdust = 0
    local total_stagger_warpdust = 0
    local total_damage_warpdust = 0
    for source,amount in pairs(self.statistics.earned_warp_dust) do
        if source:find("stagger_") then
            total_stagger_warpdust = total_stagger_warpdust + amount
        end
        if source:find("damage_dealt_") then
            total_damage_warpdust = total_damage_warpdust + amount
        end
        total_earned_warpdust = total_earned_warpdust + amount
    end
    self.statistics.earned_warp_dust.TOTAL = total_earned_warpdust
    self.statistics.earned_warp_dust.STAGGER_TOTAL = total_stagger_warpdust
    self.statistics.earned_warp_dust.DAMAGE_DEALT_TOTAL = total_damage_warpdust
    
    self.warp_dust_per_level_progress = table.clone(self.base_warp_dust_per_level_progress)

    enigma:dump(self.statistics, "ENIGMA WARP DUST STATISTICS", 5)
    enigma:unregister_mod_event_callback("update", self, "update")
end

wm.add_warpstone = function(self, amount, source)
    source = source or "other"
    local ipart = math.floor(amount)
    local fpart = amount - ipart

    local previous_warpstone = self.warpstone
    self.warpstone = self.warpstone + ipart
    self.statistics.earned_warp_dust[source] = self.statistics.earned_warp_dust[source] + ipart*WARP_DUST_PER_WARPSTONE

    if fpart > 0 then
        self:add_warp_dust(fpart*WARP_DUST_PER_WARPSTONE, source, true)
    end

    if self.warpstone ~= previous_warpstone then
        on_warpstone_amount_changed()
    end
end

wm.remove_warpstone = function(self, amount)
    local source = "other"
    amount = math.floor(amount)
    amount = math.min(amount, self.warpstone)
    self.warpstone = self.warpstone - amount
    self.statistics.earned_warp_dust[source] = self.statistics.earned_warp_dust[source] - amount*WARP_DUST_PER_WARPSTONE
    if amount ~= 0 then
        on_warpstone_amount_changed()
    end
    return amount
end

local condense_warpstone = function(warpstone, warp_dust)
    if warp_dust > WARP_DUST_PER_WARPSTONE then
        return warpstone + 1, warp_dust - WARP_DUST_PER_WARPSTONE
    end
    return warpstone, warp_dust
end

wm.add_warp_dust = function(self, amount, source, raw)
    source = source or "other"
    if not raw then
        local local_unit = enigma.managers.game.local_data and enigma.managers.game.local_data.unit
        if local_unit then
            local custom_buffs = enigma.managers.buff.unit_custom_buffs[local_unit]
            if custom_buffs and custom_buffs.warp_dust_multiplier then
                amount = amount * custom_buffs.warp_dust_multiplier
            end
            if source == "passive" and custom_buffs and custom_buffs.warp_dust_per_second_multiplier then
                amount = amount * custom_buffs.warp_dust_per_second_multiplier
            end
        end
    end

    if self.warpstone >= MAX_WARPSTONE and source ~= "debug" and source ~= "other" then
        -- Disable most common forms of warp dust gain when at the maximum amount of warpstone
        -- The goal is to discourage hoarding all the warpstone for specific events, but
        -- it should still allow for cards to add warpstone/warpdust beyond the maximum.
        return
    end

    self.warp_dust = self.warp_dust + amount
    self.statistics.earned_warp_dust[source] = self.statistics.earned_warp_dust[source] + amount
    local previous_warpstone_amount = self.warpstone
    self.warpstone, self.warp_dust = condense_warpstone(self.warpstone, self.warp_dust)
    if self.warpstone ~= previous_warpstone_amount then
        on_warpstone_amount_changed()
    end
end

wm._add_warp_dust_from_multiple_sources = function(self, data, raw)
    local multiplier = 1
    if not raw then
        local local_unit = enigma.managers.game.local_data and enigma.managers.game.local_data.unit
        if local_unit then
            local custom_buffs = enigma.managers.buff.unit_custom_buffs[local_unit]
            if custom_buffs and custom_buffs.warp_dust_multiplier then
                multiplier = custom_buffs.warp_dust_multiplier
            end
        end
    end

    for source,amount in pairs(data) do
        local multiplied = amount * multiplier
        self.warp_dust = self.warp_dust + multiplied
        self.statistics.earned_warp_dust[source] = self.statistics.earned_warp_dust[source] + multiplied
    end
    local previous_warpstone_amount = self.warpstone
    self.warpstone, self.warp_dust = condense_warpstone(self.warpstone, self.warp_dust)
    if self.warpstone ~= previous_warpstone_amount then
        on_warpstone_amount_changed()
    end
end

wm.can_pay_cost = function(self, cost, cost_modifier)
    if cost == "X" then
        return self.warpstone > math.floor(cost_modifier)
    end
    return self.warpstone >= math.floor(cost)
end

wm.pay_cost = function(self, cost, reason)
    local floor = math.floor(cost)
    if not self:can_pay_cost(floor) then
        return false
    end
    reason = reason or "unknown"
    enigma:info("Paying warpstone cost "..tostring(floor).." for reason: "..tostring(reason))
    self.warpstone = self.warpstone - floor
    if floor ~= 0 then
        on_warpstone_amount_changed()
    end
    return true
end

local stagger_warp_dust_data = {
    stagger_trash = 0,
    stagger_elite = 0,
    stagger_special = 0,
    stagger_boss = 0
}
wm._process_accumulated_stagger = function(self, trash, elite, special, boss)
    local gain_lut = self.warp_dust_per_stagger_seconds
    stagger_warp_dust_data.stagger_trash = trash * gain_lut.trash
    stagger_warp_dust_data.stagger_elite = elite * gain_lut.elite
    stagger_warp_dust_data.stagger_special = special * gain_lut.special
    stagger_warp_dust_data.stagger_boss = boss * gain_lut.boss
    self:_add_warp_dust_from_multiple_sources(stagger_warp_dust_data)
end

wm._handle_level_progress_gained = function(self, new_progress)
    local gain = new_progress * self.warp_dust_per_level_progress[self.game_mode]
    self.deferred_warp_dust = self.deferred_warp_dust + gain
end

wm.update = function(self, dt)
    local gain = dt * self.warp_dust_per_second
    self:add_warp_dust(gain, "passive")

    local pull_from_deferred = self.deferred_warp_dust * dt * 0.5
    self.deferred_warp_dust = self.deferred_warp_dust - pull_from_deferred
    self:add_warp_dust(pull_from_deferred, "level_progress")
end

wm.get_warp_dust_per_warpstone = function(self)
    return WARP_DUST_PER_WARPSTONE
end

-- Hooks
local reg_prehook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:prehook_safe("Enigma", obj, func_name, func, hook_id)
end
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end


local handle_damage_dealt = function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    if self.dead then
        return
    end
    local self_unit = enigma.managers.game.local_data and enigma.managers.game.local_data.unit
    if not self_unit or (attacker_unit ~= self_unit and source_attacker_unit ~= self_unit) then
        return
    end
    local breed = Unit.get_data(self.unit, "breed")
    if breed then
        local enemy_type = breed.boss and "boss" or breed.special and "special" or breed.elite and "elite" or "trash"
        local gain = damage_amount * wm.warp_dust_per_damage_dealt[enemy_type]

        if attack_type and RangedAttackTypes[attack_type] and attack_type ~= "grenade" then
            gain = gain * wm.ranged_damage_warp_dust_multiplier
        end

        wm:add_warp_dust(gain, "damage_dealt_"..enemy_type)
    end
end
reg_prehook_safe(GenericHealthExtension, "add_damage", handle_damage_dealt, "enigma_warp_manager_damage_dealt")
reg_prehook_safe(RatOgreHealthExtension, "add_damage", handle_damage_dealt, "enigma_warp_manager_damage_dealt")

local handle_damage_taken = function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, ...)
    if self.unit == (enigma.managers.game.local_data and enigma.managers.game.local_data.unit) and damage_type ~= "temporary_health_degen" then
        local gain = damage_amount * wm.warp_dust_per_damage_taken
        wm:add_warp_dust(gain, "damage_taken")
        -- enigma:info("Added "..gain.." warp dust from RECEIVING damage")
    end
end
reg_hook_safe(PlayerUnitHealthExtension, "add_damage", handle_damage_taken, "enigma_warp_manager_damage_taken")

-- Dev
wm.dump = function(self)
    enigma:dump(self, "WARP MANAGER", 3)
end

enigma:command("gain_warpstone", "", function(num)
    num = num or 1
    wm.warpstone = wm.warpstone + num
    on_warpstone_amount_changed()
end)