local enigma = get_mod("Enigma")

enigma:hook_safe(AICommanderExtension, "add_controlled_unit", function(self, controlled_unit, template_name, t, skip_sync)
    self._controlled_units[controlled_unit].breed_name = Unit.get_data(controlled_unit, "breed").breed_name
end)