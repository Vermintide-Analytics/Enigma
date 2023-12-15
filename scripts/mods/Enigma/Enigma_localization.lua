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
	charges = {
		en = "Charges (%i)"
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
	retain = {
		en = "Retain",
	},
	unplayable = {
		en = "Unplayable",
	},
	warp_hungry = {
		en = "Warp-Hungry (%is)",
	},

	-- Settings
	hotkeys_group_title = {
		en = "Hotkeys",
	},
	card_mode_hotkey_title = {
		en = "Card Mode / Deck Editor",
	},
	card_mode_hotkey_description = {
		en = "In the keep, this will open the Deck Editor. In a game, this will open Card Mode"
	},
	draw_card_hotkey_title = {
		en = "Draw Card",
	},
	card_mode_show_mode_title = {
		en = "Hold/Toggle Card Mode"
	},
	card_mode_show_mode_description = {
		en = "Hold: Card Mode will be active while you have the keybind pressed\nToggle: Pressing the keybind will toggle whether or not Card Mode is active"
	},
	keypress_hold = {
		en = "Hold"
	},
	keypress_toggle = {
		en = "Toggle"
	},
	hide_card_mode_on_card_play_title = {
		en = "Hide Card Mode when Card Played"
	},
	hide_card_mode_on_card_play_description = {
		en = "If enabled, Card Mode will be hidden if you play a card"
	},
	play_hotkeys_group_title = {
		en = "Play Card Hotkeys"
	},
	play_hotkeys_group_description = {
		en = "Hotkeys for playing cards from your hand while in Card Mode"
	},
	card_1_title = {
		en = "Card 1"
	},
	play_1_hotkey_description = {
		en = "Play the 1st card from your hand while in Card Mode"
	},
	card_2_title = {
		en = "Card 2"
	},
	play_2_hotkey_description = {
		en = "Play the 2nd card from your hand while in Card Mode"
	},
	card_3_title = {
		en = "Card 3"
	},
	play_3_hotkey_description = {
		en = "Play the 3rd card from your hand while in Card Mode"
	},
	card_4_title = {
		en = "Card 4"
	},
	play_4_hotkey_description = {
		en = "Play the 4th card from your hand while in Card Mode"
	},
	card_5_title = {
		en = "Card 5"
	},
	play_5_hotkey_description = {
		en = "Play the 5th card from your hand while in Card Mode"
	},
	quick_play_hotkeys_group_title = {
		en = "Quick-Play Card Hotkeys"
	},
	quick_play_hotkeys_group_description = {
		en = "Hotkeys for playing cards from your hand at any time (outside of Card Mode)"
	},
	quick_play_1_hotkey_description = {
		en = "Play the 1st card from your hand"
	},
	quick_play_2_hotkey_description = {
		en = "Play the 2nd card from your hand"
	},
	quick_play_3_hotkey_description = {
		en = "Play the 3rd card from your hand"
	},
	quick_play_4_hotkey_description = {
		en = "Play the 4th card from your hand"
	},
	quick_play_5_hotkey_description = {
		en = "Play the 5th card from your hand"
	},

	-- UI
	channeling = {
		en = "Channeling..."
	},
	channeling_cancelled = {
		en = "Channel Cancelled"
	},
	channeling_complete = {
		en = "Channel Complete"
	},
	delete = {
		en = "Delete",
	},
	edit = {
		en = "Edit",
	},
	equip = {
		en = "Equip",
	},
	page_count = {
		en = "%i of %i",
	},
	not_yet_implemented = {
		en = "Does not do anything... yet",
	},

	-- Deck List
	create_deck = {
		en = "Create Deck",
	},

	-- Deck Editor
	deck_editor_window_title = {
		en = "Deck Planner",
	},
	deck_list = {
		en = "Deck List",
	}
}

local base_card_pack_localizations = local_require("scripts/mods/Enigma/CardPacks/Base_localization")

table.merge(loc, base_card_pack_localizations)

return loc
