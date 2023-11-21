local enigma = get_mod("Enigma")

local WARP_DUST_PER_WARPSTONE = 1000.0
local MAX_WARPSTONE = 5

local wm = {
    warpstone = 0,
    warp_dust = 0.0,

    warp_dust_per_second = 5.0,
    warp_dust_per_damage_dealt = 1.0,
    warp_dust_per_damage_taken = 5.0,
    warp_dust_per_stagger_seconds = 2.0
}
enigma.managers.warp = wm

local on_warpstone_amount_changed = function()
    enigma.managers.game:on_warpstone_amount_changed()
end

wm.start_game = function(self)
    self.warpstone = enigma.mega_resource_start and 500 or 0
    self.warp_dust = 0.0
    enigma:register_mod_event_callback("update", self, "update")
end

wm.end_game = function(self)
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

wm.add_warp_dust = function(self, amount)
    self.warp_dust = self.warp_dust + amount
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

wm.pay_cost = function(self, cost)
    local floor = math.floor(cost)
    if not self:can_pay_cost(floor) then
        return false
    end
    self.warpstone = self.warpstone - floor
    if floor ~= 0 then
        on_warpstone_amount_changed()
    end
    return true
end

wm.update = function(self, dt)
    self:add_warp_dust(dt * self.warp_dust_per_second)
end

-- Dev
enigma:command("gain_warpstone", "", function(num)
    num = num or 1
    wm.warpstone = wm.warpstone + num
    on_warpstone_amount_changed()
end)