local enigma = get_mod("Enigma")

local horizontal_anchor_options = {
	{ text = "left", value = "left" },
	{ text = "center", value = "center" },
	{ text = "right", value = "right" },
}
local vertical_anchor_options = {
	{ text = "top", value = "top" },
	{ text = "center", value = "center" },
	{ text = "bottom", value = "bottom" },
}

return {
	name = "Enigma",
	description = enigma:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "added_difficulty",
				type = "numeric",
				title = "added_difficulty_title",
				tooltip = "added_difficulty_description",
				default_value = 0,
				range = { 0, 100 },
				decimals_number = 0
			},
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
						keybind_trigger = "held",
						keybind_type = "function_call",
						function_name = "card_mode_key_pressed",
						default_value = {}
					},
					{
						setting_id = "card_mode_show_mode",
						type = "dropdown",
						title = "card_mode_show_mode_title",
						tooltip = "card_mode_show_mode_description",
						default_value = "toggle",
						options = {
							{ text = "keypress_hold", value = "hold" },
							{ text = "keypress_toggle", value = "toggle" }
						}
					},
					{
						setting_id = "hide_card_mode_on_card_play",
						type = "checkbox",
						title = "hide_card_mode_on_card_play_title",
						tooltip = "hide_card_mode_on_card_play_description",
						default_value = true,
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
			{
				setting_id = "ui_customization_group",
				type = "group",
				title = "ui_customization_group_title",
				sub_widgets = {
					{
						setting_id = "hud_customization_group",
						type = "group",
						title = "hud_customization_group_title",
						sub_widgets = {
							{
								setting_id = "hand_customization_group",
								type = "group",
								title = "hand_customization_group_title",
								sub_widgets = {
									{
										setting_id = "hand_anchor_vertical",
										type = "dropdown",
										title = "anchor_vertical_title",
										tooltip = "anchor_vertical_description",
										default_value = "top",
										options = table.clone(vertical_anchor_options)
									},
									{
										setting_id = "hand_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = 0,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "hand_anchor_horizontal",
										type = "dropdown",
										title = "anchor_horizontal_title",
										tooltip = "anchor_horizontal_description",
										default_value = "right",
										options = table.clone(horizontal_anchor_options)
									},
									{
										setting_id = "hand_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = 0,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "hand_scale",
										type = "numeric",
										title = "scale_title",
										tooltip = "scale_description",
										default_value = 1,
										range = { 0, 2 },
										decimals_number = 3
									},
								},
							},
							{
								setting_id = "info_customization_group",
								type = "group",
								title = "info_customization_group_title",
								sub_widgets = {
									{
										setting_id = "info_anchor_vertical",
										type = "dropdown",
										title = "anchor_vertical_title",
										tooltip = "anchor_vertical_description",
										default_value = "top",
										options = table.clone(vertical_anchor_options)
									},
									{
										setting_id = "info_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = 0,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "info_anchor_horizontal",
										type = "dropdown",
										title = "anchor_horizontal_title",
										tooltip = "anchor_horizontal_description",
										default_value = "left",
										options = table.clone(horizontal_anchor_options)
									},
									{
										setting_id = "info_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = 12.24,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "info_scale",
										type = "numeric",
										title = "scale_title",
										tooltip = "scale_description",
										default_value = 1,
										range = { 0, 2 },
										decimals_number = 3
									},
								},
							},
							{
								setting_id = "channel_bar_customization_group",
								type = "group",
								title = "channel_bar_customization_group_title",
								sub_widgets = {
									{
										setting_id = "channel_bar_anchor_vertical",
										type = "dropdown",
										title = "anchor_vertical_title",
										tooltip = "anchor_vertical_description",
										default_value = "top",
										options = table.clone(vertical_anchor_options)
									},
									{
										setting_id = "channel_bar_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = -21.94,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "channel_bar_anchor_horizontal",
										type = "dropdown",
										title = "anchor_horizontal_title",
										tooltip = "anchor_horizontal_description",
										default_value = "right",
										options = table.clone(horizontal_anchor_options)
									},
									{
										setting_id = "channel_bar_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = -2.6,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "channel_bar_scale",
										type = "numeric",
										title = "scale_title",
										tooltip = "scale_description",
										default_value = 1,
										range = { 0, 2 },
										decimals_number = 3
									},
								},
							},
							{
								setting_id = "played_card_customization_group",
								type = "group",
								title = "played_card_customization_group_title",
								sub_widgets = {
									{
										setting_id = "played_card_anchor_vertical",
										type = "dropdown",
										title = "anchor_vertical_title",
										tooltip = "anchor_vertical_description",
										default_value = "top",
										options = table.clone(vertical_anchor_options)
									},
									{
										setting_id = "played_card_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = -27,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "played_card_anchor_horizontal",
										type = "dropdown",
										title = "anchor_horizontal_title",
										tooltip = "anchor_horizontal_description",
										default_value = "right",
										options = table.clone(horizontal_anchor_options)
									},
									{
										setting_id = "played_card_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = -2.6,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "played_card_scale",
										type = "numeric",
										title = "scale_title",
										tooltip = "scale_description",
										default_value = 1,
										range = { 0, 2 },
										decimals_number = 3
									},
								},
							},
							{
								setting_id = "kill_feed_customization_group",
								type = "group",
								title = "kill_feed_customization_group_title",
								sub_widgets = {
									{
										setting_id = "kill_feed_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = -20,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "kill_feed_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = 0,
										range = { -100, 100 },
										decimals_number = 2
									},
								},
							},
							{
								setting_id = "deus_coins_customization_group",
								type = "group",
								title = "deus_coins_customization_group_title",
								sub_widgets = {
									{
										setting_id = "deus_coins_offset_vertical",
										type = "numeric",
										title = "offset_vertical_title",
										tooltip = "offset_vertical_description",
										default_value = -20,
										range = { -100, 100 },
										decimals_number = 2
									},
									{
										setting_id = "deus_coins_offset_horizontal",
										type = "numeric",
										title = "offset_horizontal_title",
										tooltip = "offset_horizontal_description",
										default_value = 0,
										range = { -100, 100 },
										decimals_number = 2
									},
								},
							},
						},
					},
				},
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
