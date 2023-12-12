local enigma = get_mod("Enigma")

return {
	name = "Enigma",
	description = enigma:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "hotkeys_group",
				type = "group",
				title = "hotkeys_group_title",
				sub_widgets = {
					{
						setting_id = "card_mode_hotkey",
						type = "keybind",
						title = "card_mode_hotkey_title",
						tooltip = "card_mode_hotkey_description",
						keybind_global = true,
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "card_mode_key_pressed",
						default_value = {}
					},
					{
						setting_id = "draw_card_hotkey",
						type = "keybind",
						title = "draw_card_hotkey_title",
						tooltip = "draw_card_hotkey_description",
						keybind_global = true,
						keybind_trigger = "pressed",
						keybind_type = "function_call",
						function_name = "draw_card_hotkey_pressed",
						default_value = {}
					},
					{
						setting_id = "play_hotkeys_group",
						type = "group",
						title = "play_hotkeys_group_title",
						description = "play_hotkeys_group_description",
						sub_widgets = {
							{
								setting_id = "play_1_hotkey",
								type = "keybind",
								title = "card_1_title",
								tooltip = "play_1_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "play_1_hotkey_pressed",
								default_value = {"1"}
							},
							{
								setting_id = "play_2_hotkey",
								type = "keybind",
								title = "card_2_title",
								tooltip = "play_2_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "play_2_hotkey_pressed",
								default_value = {"2"}
							},
							{
								setting_id = "play_3_hotkey",
								type = "keybind",
								title = "card_3_title",
								tooltip = "play_3_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "play_3_hotkey_pressed",
								default_value = {"3"}
							},
							{
								setting_id = "play_4_hotkey",
								type = "keybind",
								title = "card_4_title",
								tooltip = "play_4_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "play_4_hotkey_pressed",
								default_value = {"4"}
							},
							{
								setting_id = "play_5_hotkey",
								type = "keybind",
								title = "card_5_title",
								tooltip = "play_5_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "play_5_hotkey_pressed",
								default_value = {"5"}
							},
						}
					},
					{
						setting_id = "quick_play_hotkeys_group",
						type = "group",
						title = "quick_play_hotkeys_group_title",
						description = "quick_play_hotkeys_group_description",
						sub_widgets = {
							{
								setting_id = "quick_play_1_hotkey",
								type = "keybind",
								title = "card_1_title",
								tooltip = "quick_play_1_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "quick_play_1_hotkey_pressed",
								default_value = {}
							},
							{
								setting_id = "quick_play_2_hotkey",
								type = "keybind",
								title = "card_2_title",
								tooltip = "quick_play_2_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "quick_play_2_hotkey_pressed",
								default_value = {}
							},
							{
								setting_id = "quick_play_3_hotkey",
								type = "keybind",
								title = "card_3_title",
								tooltip = "quick_play_3_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "quick_play_3_hotkey_pressed",
								default_value = {}
							},
							{
								setting_id = "quick_play_4_hotkey",
								type = "keybind",
								title = "card_4_title",
								tooltip = "quick_play_4_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "quick_play_4_hotkey_pressed",
								default_value = {}
							},
							{
								setting_id = "quick_play_5_hotkey",
								type = "keybind",
								title = "card_5_title",
								tooltip = "quick_play_5_hotkey_description",
								keybind_global = true,
								keybind_trigger = "pressed",
								keybind_type = "function_call",
								function_name = "quick_play_5_hotkey_pressed",
								default_value = {}
							},
						}
					}
				}
			},
		}
	},
	custom_gui_textures = {
		atlases = {
			{
				"img/Enigma/art/base/base_atlas",
				"base_atlas"
			},
			{
				"img/Enigma/card/card_atlas",
				"card_atlas"
			},
		},
		textures = {
			"enigma_test_material"
		},
		ui_renderer_injections = {
			{
				"ingame_ui",
				"materials/Enigma/enigma_test_material"
			},
			{
				"ingame_ui",
				"materials/Enigma/art/base/base_atlas"
			},
			{
				"ingame_ui",
				"materials/Enigma/card/card_atlas"
			},
		}
	}
}
