local enigma = get_mod("Enigma")

ControlledUnitTemplates.hireling = table.clone(ControlledUnitTemplates.necromancer_pet)
ControlledUnitTemplates.hireling.duration = nil
local index = #NetworkLookup.controlled_unit_templates + 1
NetworkLookup.controlled_unit_templates[index] = "hireling"
NetworkLookup.controlled_unit_templates.hireling = index
