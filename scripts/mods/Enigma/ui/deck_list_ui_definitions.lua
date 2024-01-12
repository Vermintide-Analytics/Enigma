local enigma = get_mod("Enigma")

local window_default_settings = UISettings.game_start_windows
local large_window_frame = window_default_settings.large_window_frame
local large_window_frame_width = UIFrameSettings[large_window_frame].texture_sizes.vertical[1] + 25

local WINDOW_WIDTH = UISettings.game_start_windows.large_window_size[1] / 2
local WINDOW_HEIGHT = UISettings.game_start_windows.large_window_size[2]

local INNER_WINDOW_WIDTH = WINDOW_WIDTH - large_window_frame_width
local INNER_WINDOW_HEIGHT = WINDOW_HEIGHT - large_window_frame_width

local PRETTY_MARGIN = 10

local DECK_LIST_WIDTH = INNER_WINDOW_WIDTH - PRETTY_MARGIN*2
local DECK_LIST_HEIGHT = (INNER_WINDOW_HEIGHT - PRETTY_MARGIN*2) * 0.7

local PAGINATION_PANEL_WIDTH = INNER_WINDOW_WIDTH*0.5
local PAGINATION_PANEL_HEIGHT = INNER_WINDOW_HEIGHT*0.1

local BUTTON_HEIGHT = 70

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
			UILayer.hud+1
		}
	},
	window = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			WINDOW_WIDTH,
			WINDOW_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	window_background = {
		parent = "window",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			WINDOW_WIDTH - 5,
			WINDOW_HEIGHT - 5
		},
		position = {
			0,
			0,
			0
		}
	},
	window_title = {
		vertical_alignment = "top",
		parent = "window",
		horizontal_alignment = "center",
		size = {
			658,
			60
		},
		position = {
			0,
			34,
			10
		}
	},
	window_title_bg = {
		vertical_alignment = "top",
		parent = "window_title",
		horizontal_alignment = "center",
		size = {
			410,
			40
		},
		position = {
			0,
			-15,
			-1
		}
	},
	window_title_text = {
		vertical_alignment = "center",
		parent = "window_title",
		horizontal_alignment = "center",
		size = {
			350,
			50
		},
		position = {
			0,
			-3,
			2
		}
	},
	inner_window = {
		parent = "window",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			INNER_WINDOW_WIDTH,
			INNER_WINDOW_HEIGHT
		},
		position = {
			0,
			0,
			0
		}
	},
	close_window_button = {
		parent = "window",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			380,
			42
		},
		position = {
			0,
			-16,
			10
		}
	},
	start_test_game_button = {
		parent = "inner_window",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			DECK_LIST_WIDTH/2,
			BUTTON_HEIGHT
		},
		position = {
			0,
			PRETTY_MARGIN*-1,
			1
		}
	},
	create_deck_button = {
		parent = "inner_window",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			DECK_LIST_WIDTH/2,
			BUTTON_HEIGHT
		},
		position = {
			0,
			PRETTY_MARGIN*-2 - BUTTON_HEIGHT,
			1
		}
	},
	deck_list = {
		parent = "inner_window",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			DECK_LIST_WIDTH,
			DECK_LIST_HEIGHT
		},
		position = {
			0,
			PRETTY_MARGIN,
			1
		}
	},
	pagination_panel = {
		parent = "deck_list",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			PAGINATION_PANEL_WIDTH,
			PAGINATION_PANEL_HEIGHT
		},
		position = {
			0,
			PAGINATION_PANEL_HEIGHT,
			1
		}
	},
	page_left_button = {
		parent = "pagination_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			PAGINATION_PANEL_HEIGHT,
			PAGINATION_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	page_right_button = {
		parent = "pagination_panel",
		vertical_alignment = "center",
		horizontal_alignment = "right",
		size = {
			PAGINATION_PANEL_HEIGHT,
			PAGINATION_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	}
}

local widgets = {
	background = {
		scenegraph_id = "screen",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "fullscreen_shade"
				},
			}
		},
		content = {
		},
		style = {
			fullscreen_shade = {
				color = {
					100,
					0,
					0,
					0
				}
			},
		}
	},
	window = UIWidgets.create_frame("window", scenegraph_definition.window.size, "menu_frame_11"),
	window_background_mask = UIWidgets.create_tiled_texture("window_background", "menu_frame_bg_01", {
		960,
		1080
	}, nil, true),
	window_background = UIWidgets.create_tiled_texture("window_background", "menu_frame_bg_01", {
		960,
		1080
	}, nil, nil, {
		255,
		100,
		100,
		100
	}),
	window_title = UIWidgets.create_simple_texture("frame_title_bg", "window_title"),
	window_title_bg = UIWidgets.create_background("window_title_bg", scenegraph_definition.window_title_bg.size, "menu_frame_bg_02"),
	window_title_text = UIWidgets.create_simple_text(enigma:localize("deck_list"), "window_title_text", nil, nil, {
		use_shadow = true,
		upper_case = true,
		localize = false,
		font_size = 28,
		horizontal_alignment = "center",
		vertical_alignment = "center",
		dynamic_font_size = true,
		font_type = "hell_shark_header",
		text_color = Colors.get_color_table_with_alpha("font_title", 255),
		offset = {
			0,
			0,
			2
		}
	}),
	close_window_button = UIWidgets.create_default_button("close_window_button", scenegraph_definition.close_window_button.size, nil, nil, Localize("interaction_action_close"), 24, nil, "button_detail_04", 34, true),
	start_test_game_button = UIWidgets.create_default_button("start_test_game_button", scenegraph_definition.start_test_game_button.size, nil, nil, enigma:localize("start_test_game"), 24, nil, nil, nil, true, true),
	create_deck_button = UIWidgets.create_default_button("create_deck_button", scenegraph_definition.create_deck_button.size, nil, nil, enigma:localize("create_deck"), 24, nil, nil, nil, true, true),
	deck_list = {
		scenegraph_id = "deck_list",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				}
			}
		},
		style = {
			background = {
				color = {
					35,
					70,
					70,
					150
				}
			}
		}
	},
	pagination_panel = {
		scenegraph_id = "pagination_panel",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "text",
					style_id = "page_text",
					text_id = "page_text"
				}
			}
		},
		content = {
			page_text = "0 of 0"
		},
		style = {
			background = {
				color = {
					128,
					0,
					0,
					0
				}
			},
			page_text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 36,
				dynamic_font_size = true,
				area_size = {
					PAGINATION_PANEL_WIDTH/2,
					PAGINATION_PANEL_HEIGHT
				},
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					0,
					2
				}
			}
		}
	},
	page_left_button = UIWidgets.create_default_button("page_left_button", scenegraph_definition.page_left_button.size, nil, nil, "<-", 24, nil, nil, nil, true, true),
	page_right_button = UIWidgets.create_default_button("page_right_button", scenegraph_definition.page_right_button.size, nil, nil, "->", 24, nil, nil, nil, true, true),
}

local TOTAL_DECK_LIST_ITEMS = 8
local DECK_LIST_ITEM_HEIGHT = math.floor(DECK_LIST_HEIGHT/TOTAL_DECK_LIST_ITEMS)

local define_deck_list_items = function(slot_index)
	local item_vertical_offset = DECK_LIST_ITEM_HEIGHT * (slot_index-1)
	local background_color = {
		180,
		0,
		0,
		0
	}
	if slot_index % 2 == 0 then
		background_color = {
			90,
			0,
			0,
			0
		}
	end
	local hover_color = {
		background_color[1],
		64,
		64,
		64
	}
	local item_name = "deck_slot_"..slot_index
	local equip_button_name = item_name.."_equip_button"
	scenegraph_definition[item_name] = {
		parent = "deck_list",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			DECK_LIST_WIDTH,
			DECK_LIST_ITEM_HEIGHT
		},
		position = {
			0,
			item_vertical_offset*-1,
			2
		}
	}
	scenegraph_definition[equip_button_name] = {
		parent = item_name,
		vertical_alignment = "center",
		horizontal_alignment = "right",
		size = {
			DECK_LIST_WIDTH / 5,
			DECK_LIST_ITEM_HEIGHT - 2
		},
		position = {
			PRETTY_MARGIN*-1,
			0,
			1
		}
	}
	local deck_name_area_width = scenegraph_definition[item_name].size[1] - scenegraph_definition[equip_button_name].size[1] - PRETTY_MARGIN*2
	widgets[item_name] = {
		scenegraph_id = item_name,
		index = slot_index,
		element = {
			passes = {
				{
					style_id = "background",
					pass_type = "hotspot",
					content_id = "item_hotspot"
				},
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "text",
					style_id = "deck_name",
					text_id = "deck_name"
				}
			}
		},
		content = {
			deck_name = "Deck Name "..slot_index,
			item_hotspot = {}
		},
		style = {
			background = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0
				},
				color = background_color,
				normal_color = background_color,
				hover_color = hover_color
			},
			deck_name = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				font_size = DECK_LIST_ITEM_HEIGHT - 5,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				area_size = {
					deck_name_area_width,
					DECK_LIST_ITEM_HEIGHT
				},
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					PRETTY_MARGIN,
					0,
					2
				}
			}
		}
	}
	widgets[equip_button_name] = UIWidgets.create_default_button(equip_button_name, scenegraph_definition[equip_button_name].size, nil, nil, enigma:localize("equip"), 24, nil, nil, nil, true, true)
	widgets[equip_button_name].index = slot_index
end

for i=1,TOTAL_DECK_LIST_ITEMS do
	define_deck_list_items(i)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	decks_per_page = TOTAL_DECK_LIST_ITEMS
}
