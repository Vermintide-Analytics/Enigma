local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local ui_common = local_require("scripts/mods/Enigma/ui/ui_common")

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
	delete_deck_button = {
		parent = "window",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			380,
			42
		},
		position = {
			135,
			16,
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
			PRETTY_MARGIN*-4 - 4 - TOP_PANEL_HEIGHT / 4,
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
			PRETTY_MARGIN*2,
			PRETTY_MARGIN*-3 - 4 - TOP_PANEL_HEIGHT / 2,
			0
		}
	},
	deck_avg_cost = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			WINDOW_WIDTH / 8,
			TOP_PANEL_HEIGHT / 4
		},
		position = {
			LEFT_PANEL_WIDTH - PRETTY_MARGIN - WINDOW_WIDTH / 8,
			PRETTY_MARGIN*-3 - 4 - TOP_PANEL_HEIGHT / 2,
			0
		}
	},
	equip_deck_button = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			WINDOW_WIDTH / 8,
			TOP_PANEL_HEIGHT / 3
		},
		position = {
			WINDOW_WIDTH / 4 + PRETTY_MARGIN*3,
			PRETTY_MARGIN*-2 - 4,
			1
		}
	},
	card_name_search = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = {
			WINDOW_WIDTH / 6,
			TOP_PANEL_HEIGHT / 3
		},
		position = {
			PRETTY_MARGIN*-2,
			PRETTY_MARGIN*-2 - 4,
			1
		}
	},
	card_name_search_inner = {
		parent = "card_name_search",
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
	filters_button = {
		parent = "top_panel",
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		size = {
			42,
			42
		},
		position = {
			0,
			10,
			1
		}
	},
	show_hidden_cards = {
		parent = "top_panel",
		horizontal_alignment = "right",
		vertical_alignment = "bottom",
		size = {
			140,
			42
		},
		position = {
			-100,
			10,
			1
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
	filters_panel = {
		parent = "right_panel",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			RIGHT_PANEL_WIDTH * 0.9,
			RIGHT_PANEL_HEIGHT * 0.5
		},
		position = {
			0,
			0,
			10
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

local text_color_valid = {
	255,
	0,
	255,
	0
}

local text_color_invalid = {
	255,
	255,
	0,
	0
}

local widgets = {
	background = {
		scenegraph_id = "screen",
		element = {
			passes = {
				{
					pass_type = "hotspot",
					content_id = "screen_hotspot"
				},
				{
					pass_type = "rect",
					style_id = "fullscreen_shade"
				}
			}
		},
		content = {
			screen_hotspot = {},
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
			hotspot = {
				size = {
					1920,
					1080
				},
				offset = {
					0,
					0,
					1
				}
			}
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
	delete_deck_button = UIWidgets.create_default_button("delete_deck_button", scenegraph_definition.delete_deck_button.size, nil, nil, enigma:localize("delete"), 24, nil, nil, nil, true, true),
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
	filters_button = {
		scenegraph_id = "filters_button",
		element = {
			passes = {
				{
					style_id = "search_filters_hotspot",
					pass_type = "hotspot",
					content_id = "search_filters_hotspot",
					content_check_function = function ()
						return not Managers.input:is_device_active("gamepad")
					end,
					content_change_function = function (content, style)
						local filters_active = content.parent.filters_active
	
						if filters_active ~= content.filters_active then
							content.filters_active = filters_active
	
							if filters_active then
								Colors.copy_to(style.parent.search_filters_glow.color, Colors.color_definitions.white)
							else
								Colors.copy_to(style.parent.search_filters_glow.color, Colors.color_definitions.font_title)
							end
						end
	
						local alpha = 0
	
						if content.is_hover then
							alpha = 255
						elseif content.filters_active then
							alpha = 200
						end
	
						style.parent.search_filters_glow.color[1] = alpha
					end
				},
				{
					pass_type = "texture",
					style_id = "search_filters_bg",
					texture_id = "search_filters_bg"
				},
				{
					pass_type = "texture",
					style_id = "search_filters_icon",
					texture_id = "search_filters_icon"
				},
				{
					pass_type = "texture",
					style_id = "search_filters_glow",
					texture_id = "search_filters_glow"
				},
			}
		},
		content = {
			search_filters_icon = "search_filters_icon",
			search_filters_bg = "search_filters_bg",
			search_filters_glow = "search_filters_icon_glow",
			frame = UIFrameSettings.button_frame_01.texture,
			glow = UIFrameSettings.frame_outer_glow_01.texture,
			search_filters_hotspot = {},
		},
		style = {
			search_filters_hotspot = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				area_size = {
					96,
					96
				},
				offset = {
					-42,
					28,
					7
				}
			},
			search_filters_bg = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				color = {
					255,
					255,
					255,
					255
				},
				texture_size = {
					128,
					128
				},
				offset = {
					-80,
					-4,
					8
				}
			},
			search_filters_icon = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				color = Colors.get_color_table_with_alpha("white", 255),
				texture_size = {
					128,
					128
				},
				offset = {
					-80,
					-4,
					8
				}
			},
			search_filters_glow = {
				vertical_alignment = "center",
				horizontal_alignment = "left",
				color = Colors.get_color_table_with_alpha("font_title", 255),
				texture_size = {
					128,
					128
				},
				offset = {
					-80,
					-4,
					9
				}
			},
		}
	},
	show_hidden_cards = ui_common.create_checkbox_widget(enigma:localize("show_hidden"), "", "show_hidden_cards", 0, nil, nil),
	deck_name = ui_common.create_text_input("deck_name", "deck_name_inner", "screen", "--- DECK NAME ---"),
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
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_size = 24,
				font_type = "hell_shark",
				text_color = text_color_valid,
				text_color_valid = text_color_valid,
				text_color_invalid = text_color_invalid
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
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_size = 24,
				font_type = "hell_shark",
				text_color = text_color_valid,
				text_color_valid = text_color_valid,
				text_color_invalid = text_color_invalid
			}
		}
	},
	deck_avg_cost = {
		scenegraph_id = "deck_avg_cost",
		element = {
			passes = {
				{
					pass_type = "text",
					style_id = "deck_avg_cost",
					text_id = "deck_avg_cost"
				}
			}
		},
		content = {
			deck_avg_cost = "Avg Cost: 0"
		},
		style = {
			deck_avg_cost = {
				horizontal_alignment = "right",
				vertical_alignment = "center",
				font_size = 24,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				}
			}
		}
	},
	equipped_deck_text = {
		scenegraph_id = "equip_deck_button",
		element = {
			passes = {
				{
					pass_type = "text",
					style_id = "text",
					text_id = "text"
				}
			}
		},
		content = {
			text = enigma:localize("equipped")
		},
		style = {
			text = {
				horizontal_alignment = "center",
				vertical_alignment = "center",
				font_size = 32,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				}
			}
		}
	},
	equip_deck_button = UIWidgets.create_default_button("equip_deck_button", scenegraph_definition.equip_deck_button.size, nil, nil, enigma:localize("equip"), 24, nil, nil, nil, true, true),
	card_name_search = ui_common.create_text_input("card_name_search", "card_name_search_inner", "screen", "", enigma:localize("search")),
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
	card_ui_common.add_card_display(scenegraph_definition, widgets, scenegraph_id, card_scenegraph_id, CARD_TILE_WIDTH, true)
	scenegraph_definition[card_scenegraph_id].vertical_alignment = "top"
	scenegraph_definition[card_scenegraph_id].horizontal_alignment = "left"
	scenegraph_definition[card_scenegraph_id].position[1] = horizontal_offset
	scenegraph_definition[card_scenegraph_id].position[2] = vertical_offset * -1
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
