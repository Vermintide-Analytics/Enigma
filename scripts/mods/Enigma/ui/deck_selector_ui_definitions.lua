local WINDOW_WIDTH = 1920*0.8
local WINDOW_HEIGHT = 1080*0.8

local TOP_PANEL_HEIGHT = WINDOW_HEIGHT*0.15
local LEFT_PANEL_WIDTH = WINDOW_WIDTH*0.25
local LEFT_PANEL_HEIGHT = WINDOW_HEIGHT - TOP_PANEL_HEIGHT
local RIGHT_PANEL_WIDTH = WINDOW_WIDTH - LEFT_PANEL_WIDTH
local RIGHT_PANEL_HEIGHT = WINDOW_HEIGHT - TOP_PANEL_HEIGHT

local PAGINATION_PANEL_WIDTH = WINDOW_WIDTH*0.25
local PAGINATION_PANEL_HEIGHT = TOP_PANEL_HEIGHT*0.25

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
	top_panel = {
		parent = "window",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			WINDOW_WIDTH,
			TOP_PANEL_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	close_window_button = {
		parent = "top_panel",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = {
			150,
			70
		},
		position = {
			PRETTY_MARGIN*-1,
			PRETTY_MARGIN*-1,
			1
		}
	},
	left_panel = {
		parent = "window",
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
		parent = "window",
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
		parent = "top_panel",
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
	window = {
		scenegraph_id = "window",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "window_background"
				},
			}
		},
		content = {
		},
		style = {
			window_background = {
				color = {
					255,
					50,
					50,
					50
				}
			},
		}
	},
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
					255,
					100,
					100,
					100
				}
			},
		}
	},
	close_window_button = UIWidgets.create_default_button("close_window_button", scenegraph_definition.close_window_button.size, nil, nil, "Close", 32, nil, nil, nil, true, true),
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
					255,
					85,
					85,
					149
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
					255,
					44,
					0,
					0
				}
			},
		}
	},
}

local TOTAL_DECK_SLOTS = 25
local DECK_SLOT_HEIGHT = math.floor(LEFT_PANEL_HEIGHT/TOTAL_DECK_SLOTS)

local define_deck_slot_widget = function(scenegraph_id, slot_index)
	local vertical_offset = DECK_SLOT_HEIGHT * (slot_index-1)
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
	background_color[1] = background_color[1] + slot_index * 3

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
			card_name = "Card Name "..slot_index
		},
		style = {
			background = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				size = {
					LEFT_PANEL_WIDTH,
					DECK_SLOT_HEIGHT
				},
				offset = {
					0,
					LEFT_PANEL_HEIGHT - DECK_SLOT_HEIGHT * (slot_index),
					1
				},
				color = background_color
			},
			card_name = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				font_size = DECK_SLOT_HEIGHT - 5,
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

for i=1,TOTAL_DECK_SLOTS do
	define_deck_slot_widget("left_panel", i)
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

	local vertical_offset = PRETTY_MARGIN*row + CARD_TILE_HEIGHT*(row - 1)
	local horizontal_offset = PRETTY_MARGIN*column + CARD_TILE_WIDTH*(column - 1)

	local widget_name = "card_tile_"..tile_index
	widgets[widget_name] = {
		scenegraph_id = scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				}
			}
		},
		content = {
		},
		style = {
			background = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				size = {
					CARD_TILE_WIDTH,
					CARD_TILE_HEIGHT
				},
				offset = {
					horizontal_offset,
					vertical_offset,
					1
				},
				color = {
					128,
					0,
					0,
					0
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
	widgets = widgets
}
