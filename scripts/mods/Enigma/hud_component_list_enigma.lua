local enigma = get_mod("Enigma")

local adventure_settings = require("scripts/ui/hud_ui/component_list_definitions/hud_component_list_adventure")

local enigma_components = {
	{
		use_hud_scale = true,
		class_name = "EnigmaDeckPrepHud",
		filename = "scripts/mods/Enigma/ui/deck_prep_hud",
		visibility_groups = {
			"alive",
			"dead",
			"mission_vote"
		}
	},
	{
		use_hud_scale = true,
		class_name = "EnigmaBigCardUI",
		filename = "scripts/mods/Enigma/ui/big_card_ui",
		visibility_groups = {
			"alive",
			"dead",
			"entering_mission",
			"mission_vote",
			"in_menu"
		}
	},
	{
		use_hud_scale = true,
		class_name = "EnigmaCardGameHud",
		filename = "scripts/mods/Enigma/ui/card_game_hud",
		visibility_groups = {
			"alive",
			"dead",
			"mission_vote"
		}
	},
	{
		use_hud_scale = true,
		class_name = "EnigmaCardModeUI",
		filename = "scripts/mods/Enigma/ui/card_mode_ui",
		visibility_groups = {
			"alive",
			"dead"
		}
	},
}

local components = {}

table.append(components, adventure_settings.components)
table.append(components, enigma_components)

local visibility_groups = {}

table.append(visibility_groups, adventure_settings.visibility_groups)

for i = 1, #enigma_components do
	require(enigma_components[i].filename)
end

return {
	components = components,
	visibility_groups = visibility_groups
}
