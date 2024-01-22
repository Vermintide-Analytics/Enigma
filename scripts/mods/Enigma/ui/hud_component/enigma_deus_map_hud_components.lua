local enigma = get_mod("Enigma")

local components = {
	{
		use_hud_scale = true,
		class_name = "EnigmaDeusCardChoiceUI",
		filename = "scripts/mods/Enigma/ui/deus_card_choice_ui",
		visibility_groups = {
			"alive",
			"dead"
		}
	},
}

local visibility_groups = {}

for i = 1, #components do
	require(components[i].filename)
end

return {
	components = components,
	visibility_groups = visibility_groups
}
