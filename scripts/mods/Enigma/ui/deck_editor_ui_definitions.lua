local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local enigma = get_mod("Enigma")

local window_default_settings = UISettings.game_start_windows
local large_window_frame = window_default_settings.large_window_frame
local large_window_frame_width = UIFrameSettings[large_window_frame].texture_sizes.vertical[1] + 25

local WINDOW_WIDTH = UISettings.game_start_windows.large_window_size[1]
local WINDOW_HEIGHT = UISettings.game_start_windows.large_window_size[2]

local INNER_WINDOW_WIDTH = WINDOW_WIDTH - large_window_frame_width
local INNER_WINDOW_HEIGHT = WINDOW_HEIGHT - large_window_frame_width

local TOP_PANEL_HEIGHT = INNER_WINDOW_HEIGHT*0.15
local LEFT_PANEL_WIDTH = INNER_WINDOW_WIDTH*0.3
local LEFT_PANEL_HEIGHT = INNER_WINDOW_HEIGHT - TOP_PANEL_HEIGHT
local RIGHT_PANEL_WIDTH = INNER_WINDOW_WIDTH - LEFT_PANEL_WIDTH
local RIGHT_PANEL_HEIGHT = INNER_WINDOW_HEIGHT - TOP_PANEL_HEIGHT

local PAGINATION_PANEL_WIDTH = RIGHT_PANEL_WIDTH*0.2
local PAGINATION_PANEL_HEIGHT = TOP_PANEL_HEIGHT*0.5

local PRETTY_MARGIN = 10

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
	deck_list_button = {
		parent = "window",
		vertical_alignment = "bottom",
		horizontal_alignment = "left",
		size = {
			380,
			42
		},
		position = {
			135,
			-16,
			10
		}
	},
	close_window_button = {
		parent = "window",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = {
			380,
			42
		},
		position = {
			-135,
			-16,
			10
		}
	},
	top_panel = {
		parent = "inner_window",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			INNER_WINDOW_WIDTH,
			TOP_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	deck_name = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			WINDOW_WIDTH / 4,
			TOP_PANEL_HEIGHT / 3
		},
		position = {
			PRETTY_MARGIN*2,
			PRETTY_MARGIN*-2 - 4,
			1
		}
	},
	deck_name_inner = {
		parent = "deck_name",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			-4,
			-4
		},
		position = {
			0,
			0,
			1
		}
	},
	deck_card_count = {
		parent ="top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			WINDOW_WIDTH / 8,
			TOP_PANEL_HEIGHT / 4
		},
		position = {
			PRETTY_MARGIN*2,
			PRETTY_MARGIN*-3 - 4 - TOP_PANEL_HEIGHT / 3,
			0
		}
	},
	deck_cp_count = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			WINDOW_WIDTH / 8,
			TOP_PANEL_HEIGHT / 4
		},
		position = {
			PRETTY_MARGIN*4 + WINDOW_WIDTH / 8,
			PRETTY_MARGIN*-3 - 4 - TOP_PANEL_HEIGHT / 3,
			0
		}
	},
	left_panel = {
		parent = "inner_window",
		vertical_alignment = "bottom",
		horizontal_alignment = "left",
		size = {
			LEFT_PANEL_WIDTH,
			LEFT_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	right_panel = {
		parent = "inner_window",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = {
			RIGHT_PANEL_WIDTH,
			RIGHT_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	pagination_panel = {
		parent = "right_panel",
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
	window_title_text = UIWidgets.create_simple_text(enigma:localize("deck_editor_window_title"), "window_title_text", nil, nil, {
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
	deck_list_button = UIWidgets.create_default_button("deck_list_button", scenegraph_definition.deck_list_button.size, nil, nil, enigma:localize("deck_list"), 24, nil, "button_detail_04", 34, true),
	close_window_button = UIWidgets.create_default_button("close_window_button", scenegraph_definition.close_window_button.size, nil, nil, Localize("interaction_action_close"), 24, nil, "button_detail_04", 34, true),
	top_panel = {
		scenegraph_id = "top_panel",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "top_panel_background"
				}
			}
		},
		style = {
			top_panel_background = {
				color = {
					35,
					100,
					100,
					100
				}
			},
		}
	},
	deck_name = {
		scenegraph_id = "deck_name",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "name_input_background"
				},
				{
					pass_type = "rect",
					style_id = "name_input_inner_background"
				},
				{
					pass_type = "hotspot",
					content_id = "deck_name_input_hotspot"
				},
				{
					pass_type = "hotspot",
					scenegraph_id = "screen",
					content_id = "screen_hotspot"
				},
				{
					pass_type = "text",
					style_id = "deck_name",
					text_id = "deck_name",
					content_check_function = function(content, style)
						if not content.deck_name_input_active then
							style.caret_color[1] = 0
						else
							style.caret_color[1] = 128 + math.sin(Managers.time:time("ui") * 5) * 128
						end
						return true
					end
				}
			}
		},
		content = {
			deck_name_input_hotspot = {},
			screen_hotspot = {},
			text_start_offset = 0,
			text_index = 1,
			deck_name_input_active = false,
			deck_name = "-- DECK NAME --",
			caret_index = 1
		},
		style = {
			name_input_background = {
				scenegraph_id = "deck_name",
				color = {
					255,
					128,
					128,
					128
				},
			},
			name_input_inner_background = {
				scenegraph_id = "deck_name",
				color = {
					255,
					0,
					0,
					0
				},
			},
			deck_name = {
				scenegraph_id = "deck_name_inner",
				horizontal_scroll = true,
				word_wrap = false,
				pixel_perfect = true,
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_size = 32,
				dynamic_font = true,
				font_type = "hell_shark_arial",
				text_color = Colors.get_table("white"),
				offset = {
					2,
					2,
					1
				},
				caret_size = {
					2,
					30
				},
				caret_offset = {
					0,
					-4,
					4
				},
				caret_color = Colors.get_table("white")
			}
		}
	},
	deck_card_count = {
		scenegraph_id = "deck_card_count",
		element = {
			passes = {
				{
					pass_type = "text",
					style_id = "deck_card_count",
					text_id = "deck_card_count"
				}
			}
		},
		content = {
			deck_card_count = "Cards: 0 / 0"
		},
		style = {
			deck_card_count = {
				horizontal_alignment = "center",
				vertical_alignment = "center",
				font_size = 28,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				}
			}
		}
	},
	deck_cp_count = {
		scenegraph_id = "deck_cp_count",
		element = {
			passes = {
				{
					pass_type = "text",
					style_id = "deck_cp_count",
					text_id = "deck_cp_count"
				}
			}
		},
		content = {
			deck_cp_count = "CP: 0 / 0"
		},
		style = {
			deck_cp_count = {
				horizontal_alignment = "center",
				vertical_alignment = "center",
				font_size = 28,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				}
			}
		}
	},
	left_panel = {
		scenegraph_id = "left_panel",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "left_panel_background"
				}
			}
		},
		style = {
			left_panel_background = {
				color = {
					35,
					118,
					118,
					208
				}
			},
		}
	},
	right_panel = {
		scenegraph_id = "right_panel",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "right_panel_background"
				}
			}
		},
		style = {
			right_panel_background = {
				color = {
					35,
					161,
					40,
					40
				},
				offset = {
					0,
					0,
					-1
				}
			},
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

local TOTAL_DECK_SLOTS = 25
local DECK_SLOT_HEIGHT = math.floor(LEFT_PANEL_HEIGHT/TOTAL_DECK_SLOTS)

local define_deck_card_items = function(item_index)
	local item_name = "deck_slot_"..item_index

	local item_vertical_offset = DECK_SLOT_HEIGHT * (item_index-1)
	local background_color = {
		180,
		0,
		0,
		0
	}
	if item_index % 2 == 0 then
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
	
	scenegraph_definition[item_name] = {
		parent = "left_panel",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			LEFT_PANEL_WIDTH,
			DECK_SLOT_HEIGHT
		},
		position = {
			0,
			item_vertical_offset*-1,
			2
		}
	}

	local rarity_box_width = 16
	local cost_text_width = 20

	widgets[item_name] = {
		scenegraph_id = item_name,
		element = {
			passes = {
				{
					style_id = "background",
					pass_type = "hotspot",
					content_id = "item_hotspot",
				},
				{
					pass_type = "rect",
					style_id = "background",
				},
				{
					pass_type = "rect",
					style_id = "card_rarity",
				},
				{
					pass_type = "text",
					style_id = "card_name",
					text_id = "card_name"
				},
				{
					pass_type = "text",
					style_id = "card_cost",
					text_id = "card_cost"
				}
			}
		},
		content = {
			item_hotspot = {},
			card_name = "Card Name "..item_index,
			card_cost = "0"
		},
		style = {
			background = {
				color = background_color,
				normal_color = background_color,
				hover_color = hover_color
			},
			card_rarity = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				size = {
					rarity_box_width,
					DECK_SLOT_HEIGHT*0.65
				},
				offset = {
					PRETTY_MARGIN,
					5,
					1
				},
				color = {
					255,
					255,
					255,
					255
				}
			},
			card_name = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				font_size = DECK_SLOT_HEIGHT - 5,
				dynamic_font_size = true,
				area_size = {
					LEFT_PANEL_WIDTH - PRETTY_MARGIN*4 - cost_text_width - rarity_box_width,
					DECK_SLOT_HEIGHT
				},
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					PRETTY_MARGIN*2 + 16,
					0,
					2
				}
			},
			card_cost = {
				vertical_alignment = "center",
				horizontal_alignment = "right",
				font_size = DECK_SLOT_HEIGHT - 5,
				dynamic_font_size = true,
				area_size = {
					cost_text_width,
					DECK_SLOT_HEIGHT
				},
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					PRETTY_MARGIN*-1,
					0,
					2
				}
			}
		}
	}
end

for i=1,TOTAL_DECK_SLOTS do
	define_deck_card_items(i)
end

local CARD_TILE_ROWS = 2
local CARD_TILES_PER_ROW = 5
local TOTAL_CARD_TILES = CARD_TILE_ROWS * CARD_TILES_PER_ROW

local CARD_TILE_HEIGHT = (RIGHT_PANEL_HEIGHT - PRETTY_MARGIN*(CARD_TILE_ROWS+1))/CARD_TILE_ROWS
local CARD_TILE_WIDTH = (RIGHT_PANEL_WIDTH - PRETTY_MARGIN*(CARD_TILES_PER_ROW+1))/CARD_TILES_PER_ROW
local CARD_TILE_TARGET_ASPECT = 858/512
if CARD_TILE_HEIGHT/CARD_TILE_WIDTH > CARD_TILE_TARGET_ASPECT then
	CARD_TILE_HEIGHT = CARD_TILE_WIDTH * CARD_TILE_TARGET_ASPECT
elseif CARD_TILE_HEIGHT/CARD_TILE_WIDTH < CARD_TILE_TARGET_ASPECT then
	CARD_TILE_WIDTH = CARD_TILE_HEIGHT / CARD_TILE_TARGET_ASPECT
end

local define_card_tile_widget = function(scenegraph_id, tile_index)
	local row = math.ceil(tile_index/CARD_TILES_PER_ROW)
	local column = ((tile_index-1) % CARD_TILES_PER_ROW) + 1

	local horizontal_offset = PRETTY_MARGIN*column + CARD_TILE_WIDTH*(column - 1)
	local vertical_offset = PRETTY_MARGIN*row + CARD_TILE_HEIGHT*(row - 1)

	local card_scenegraph_id = "card_"..tile_index
	ui_common.add_card_display(scenegraph_definition, widgets, scenegraph_id, card_scenegraph_id, CARD_TILE_WIDTH)
	scenegraph_definition[card_scenegraph_id].vertical_alignment = "top"
	scenegraph_definition[card_scenegraph_id].horizontal_alignment = "left"
	scenegraph_definition[card_scenegraph_id].position[1] = horizontal_offset
	scenegraph_definition[card_scenegraph_id].position[2] = vertical_offset * -1

	local background_color = {
		180,
		0,
		0,
		0
	}
	if tile_index % 2 == 0 then
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

	widgets[card_scenegraph_id.."_deck_editor_interaction"] = {
		scenegraph_id = card_scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "hotspot",
					content_id = "hotspot"
				},
				-- {
				-- 	pass_type = "rect",
				-- 	style = "background"
				-- }
			}
		},
		content = {
			hotspot = {}
		},
		style = {
			background = {
				color = background_color,
				normal_color = background_color,
				hover_color = hover_color,
				offset = {
					0,
					0,
					10
				}
			}
		}
	}
end

for i=1,TOTAL_CARD_TILES do
	define_card_tile_widget("right_panel", i)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	max_cards_in_deck = TOTAL_DECK_SLOTS,
	num_card_tiles = TOTAL_CARD_TILES,
	card_tile_width = CARD_TILE_WIDTH
}
