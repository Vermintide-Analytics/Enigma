local enigma = get_mod("Enigma")

local WARP_DUST_PER_WARPSTONE = 1000.0
local MAX_WARPSTONE = 5

local wm = {
    warpstone = 0,
    warp_dust = 0.0,
    deferred_warp_dust = 0.0,

    warp_dust_per_second = 3.0,
    warp_dust_per_damage_dealt = 0.14,
    warp_dust_per_damage_taken = 2.0,
    warp_dust_per_stagger_seconds = {
        trash = 1.5,
        elite = 5.0,
        special = 5.0,
        boss = 20.0
    },
    warp_dust_per_level_progress = {
        adventure = 5000,
        deus = 3000
    }
}
enigma.managers.warp = wm

local on_warpstone_amount_changed = function()
    enigma.managers.game:on_warpstone_amount_changed()
end

wm.start_game = function(self, game_mode)
    self.game_mode = game_mode
    self.warpstone = enigma.mega_resource_start and 99 or 0
    self.warp_dust = 0.0

    self.statistics = {
        earned_warp_dust = {
            passive = 0,
            damage_dealt = 0,
            damage_taken = 0,
            stagger = 0,
            level_progress = 0,
            debug = 0,
            other = 0
        }
    }

    enigma:register_mod_event_callback("update", self, "update")
end

wm.end_game = function(self)
    enigma:dump(self.statistics, "ENIGMA WARP DUST STATISTICS", 5)
    enigma:unregister_mod_event_callback("update", self, "update")
end

local condense_warpstone = function(warpstone, warp_dust)
    if warpstone >= MAX_WARPSTONE then
        return warpstone, 0
    end
    if warp_dust > WARP_DUST_PER_WARPSTONE then
        return warpstone + 1, warp_dust - WARP_DUST_PER_WARPSTONE
    end
    return warpstone, warp_dust
end

wm.add_warp_dust = function(self, amount, source, raw)
    if not raw then
        local local_unit = enigma.managers.game.local_data and enigma.managers.game.local_data.unit
        if local_unit then
            local custom_buffs = enigma.managers.buff.unit_custom_buffs[local_unit]
            if custom_buffs and custom_buffs.warp_dust_multiplier then
                amount = amount * custom_buffs.warp_dust_multiplier
            end
        end
    end

    self.warp_dust = self.warp_dust + amount
    self.statistics.earned_warp_dust[source] = self.statistics.earned_warp_dust[source] + amount
    local previouos_warpstone_amount = self.warpstone
    self.warpstone, self.warp_dust = condense_warpstone(self.warpstone, self.warp_dust)
    if self.warpstone ~= previouos_warpstone_amount then
        on_warpstone_amount_changed()
    end
end

wm.can_pay_cost = function(self, cost)
    local floor = math.floor(cost)
    return self.warpstone >= floor
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

wm._process_accumulated_stagger = function(self, trash, elite, special, boss)
    local gain_lut = self.warp_dust_per_stagger_seconds
    local gain = trash * gain_lut.trash + elite * gain_lut.elite + special * gain_lut.special + boss * gain_lut.boss
    self:add_warp_dust(gain, "stagger")
    -- if gain > 0 then
    --     enigma:info("Added "..gain.." warp dust from recently staggered enemies")
    -- end
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
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end


local handle_damage_dealt = function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    if self.dead then
        return
    end
    local self_unit = enigma.managers.game.local_data and enigma.managers.game.local_data.unit
    if attacker_unit == self_unit or source_attacker_unit == self_unit then
        local gain = damage_amount * wm.warp_dust_per_damage_dealt
        wm:add_warp_dust(gain, "damage_dealt")
        -- enigma:info("Added "..gain.." warp dust from DEALING damage")
    end
end
reg_hook_safe(GenericHealthExtension, "add_damage", handle_damage_dealt, "enigma_warp_manager_damage_dealt")
reg_hook_safe(RatOgreHealthExtension, "add_damage", handle_damage_dealt, "enigma_warp_manager_damage_dealt")

local handle_damage_taken = function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, ...)
    if self.unit == (enigma.managers.game.local_data and enigma.managers.game.local_data.unit) and damage_type ~= "temporary_health_degen" then
        local gain = damage_amount * wm.warp_dust_per_damage_taken
        wm:add_warp_dust(gain, "damage_taken")
        -- enigma:info("Added "..gain.." warp dust from RECEIVING damage")
    end
end
reg_hook_safe(PlayerUnitHealthExtension, "add_damage", handle_damage_taken, "enigma_warp_manager_damage_taken")

-- Dev
enigma:command("gain_warpstone", "", function(num)
    num = num or 1
    wm.warpstone = wm.warpstone + num
    on_warpstone_amount_changed()
end)