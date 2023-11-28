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
		parent = "inner_window",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = {
			PAGINATION_PANEL_WIDTH,
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
}

local TOTAL_DECK_LIST_ITEMS = 8
local DECK_LIST_ITEM_HEIGHT = math.floor(DECK_LIST_HEIGHT/TOTAL_DECK_LIST_ITEMS)

local define_deck_list_item_widget = function(scenegraph_id, slot_index)
	local vertical_offset = DECK_LIST_ITEM_HEIGHT * (slot_index-1)
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
	background_color[1] = background_color[1] + slot_index * 8

	local widget_name = "deck_slot_"..slot_index
	widgets[widget_name] = {
		scenegraph_id = scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "text",
					style_id = "card_name",
					text_id = "card_name"
				}
			}
		},
		content = {
			card_name = "Deck Name "..slot_index
		},
		style = {
			background = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				size = {
					DECK_LIST_WIDTH,
					DECK_LIST_ITEM_HEIGHT
				},
				offset = {
					0,
					DECK_LIST_HEIGHT - DECK_LIST_ITEM_HEIGHT * (slot_index),
					1
				},
				color = background_color
			},
			card_name = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				font_size = DECK_LIST_ITEM_HEIGHT - 5,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					PRETTY_MARGIN,
					vertical_offset*-1,
					2
				}
			}
		}
	}
end

for i=1,TOTAL_DECK_LIST_ITEMS do
	define_deck_list_item_widget("deck_list", i)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
