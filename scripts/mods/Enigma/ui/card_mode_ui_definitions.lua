local enigma = get_mod("Enigma")
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local CARD_WIDTH = 300

local scenegraph_definition = {
	screen = {
		scale = "fit",
		size = {
			1920,
			1080
		},
		position = {
			0,
			0,
			UILayer.hud+110
		}
	},
	hand_panel = {
		parent = "screen",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			1536,
			486
		},
		position = {
			0,
			128,
			1
		}
	},
	test_game_warpstone_panel = {
		parent = "screen",
		vertical_alignment = "bottom",
		horizontal_alignment = "left",
		size = {
			410,
			100
		},
		position = {
			10,
			10,
			1
		}
	},
	test_game_warpstone_icon = {
		parent = "test_game_warpstone_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			80,
			80
		},
		position = {
			10,
			0,
			1
		}
	},
	test_game_warpstone_zero_button = {
		parent = "test_game_warpstone_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			80,
			80
		},
		position = {
			110,
			0,
			1
		}
	},
	test_game_warpstone_plus_one_button = {
		parent = "test_game_warpstone_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			80,
			80
		},
		position = {
			200,
			0,
			1
		}
	},
	test_game_warpstone_plus_hundred_button = {
		parent = "test_game_warpstone_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			110,
			80
		},
		position = {
			290,
			0,
			1
		}
	},
	end_test_game_button = {
		parent = "screen",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = {
			500,
			100
		},
		position = {
			-10,
			10,
			1
		}
	},
}

local widgets = {
	background = {
		scenegraph_id = "screen",
		element = {
			passes = {
				{
					pass_type = "hotspot",
					scenegraph_id = "screen",
					content_id = "screen_hotspot"
				},
				{
					pass_type = "rect",
					style_id = "fullscreen_shade"
				},
			}
		},
		content = {
			screen_hotspot = {}
		},
		style = {
			fullscreen_shade = {
				color = {
					150,
					0,
					0,
					0
				}
			},
		}
	},
	test_game_warpstone_icon = {
		scenegraph_id = "test_game_warpstone_icon",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "icon",
					style_id = "icon"
				},
			}
		},
		content = {
			icon = "enigma_card_warpstone",
		},
		style = {
			icon = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				texture_size = {
					80,
					80
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
		}
	},
	test_game_warpstone_zero_button = UIWidgets.create_default_button("test_game_warpstone_zero_button", scenegraph_definition.test_game_warpstone_zero_button.size, nil, nil, "0", 34, nil, nil, nil, true, true),
	test_game_warpstone_plus_one_button = UIWidgets.create_default_button("test_game_warpstone_plus_one_button", scenegraph_definition.test_game_warpstone_plus_one_button.size, nil, nil, "+1", 34, nil, nil, nil, true, true),
	test_game_warpstone_plus_hundred_button = UIWidgets.create_default_button("test_game_warpstone_plus_hundred_button", scenegraph_definition.test_game_warpstone_plus_hundred_button.size, nil, nil, "+99", 34, nil, nil, nil, true, true),
	end_test_game_button = UIWidgets.create_default_button("end_test_game_button", scenegraph_definition.end_test_game_button.size, nil, nil, enigma:localize("end_test_game"), 34, nil, nil, nil, true, true),
}

card_ui_common.add_hand_display(scenegraph_definition, widgets, "hand_panel", CARD_WIDTH, true)

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = CARD_WIDTH
}
