local enigma = get_mod("Enigma")

enigma:hook(StatusUtils, "set_catapulted_network", function(func, unit, catapulted, velocity)
    local buff_ext = unit and Unit.alive(unit) and ScriptUnit.extension(unit, "buff_system")
    if buff_ext and buff_ext:has_buff_perk("immovable") then
        return
    end

    return func(unit, catapulted, velocity)
end)

local handle_add_external_velocity = function(func, self, velocity_delta, upper_limit)
    local unit = self.unit
    local buff_ext = unit and Unit.alive(unit) and ScriptUnit.extension(unit, "buff_system")
    if buff_ext and buff_ext:has_buff_perk("immovable") then
        return
    end

    return func(self, velocity_delta, upper_limit)
end
enigma:hook(PlayerUnitLocomotionExtension, "add_external_velocity", handle_add_external_velocity)
enigma:hook(PlayerHuskLocomotionExtension, "add_external_velocity", handle_add_external_velocity)
