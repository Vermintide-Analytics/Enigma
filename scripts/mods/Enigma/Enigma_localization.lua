local loc = {
	mod_description = {
		en = "Enigma description",
	},
	auto = {
		en = "Auto",
	},
	channel = {
		en = "Channel (%is)",
	},
	condition = {
		en = "Condition",
	},
	double_agent = {
		en = "Double Agent",
	},
	ephemeral = {
		en = "Ephemeral",
	},
	infinite = {
		en = "Infinite",
	},
	unplayable = {
		en = "Unplayable",
	},
	warp_hungry = {
		en = "Warp-Hungry (%is)"
	},

	-- UI

	-- Deck Editor
	deck_editor_window_title = {
		en = "Deck Planner"
	},
	deck_list = {
		en = "Deck List"
	}
}

local base_card_pack_localizations = local_require("scripts/mods/Enigma/CardPacks/Base_localization")

table.merge(loc, base_card_pack_localizations)

return loc
