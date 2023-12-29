-- Info Panel Sizing
local INFO_PANEL_WIDTH = 414
local INFO_PANEL_HEIGHT = 250

local COLUMN_WIDTH = 64
local BAR_WIDTH = 12
local FONT_SIZE = 64
local PRETTY_MARGIN = 10

local CHANNEL_BAR_WIDTH = 600
local CHANNEL_BAR_HEIGHT = 28

-- Hand Panel Sizing
local CARD_WIDTH = 128

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
			UILayer.hud+100
		}
	},
	info_panel = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "left",
		size = {
			INFO_PANEL_WIDTH,
			INFO_PANEL_HEIGHT
		},
		position = {
			235,
			0,
			0
		}
	},
}

local widgets = {
	info_panel = {
		scenegraph_id = "info_panel",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
			}
		},
		content = {
		},
		style = {
			background = {
				color = {
					130,
					0,
					0,
					0
				}
			},
		}
	},
}

local ROW_HEIGHT = INFO_PANEL_HEIGHT / 5
local TEXT_SIZE = (ROW_HEIGHT - 10) / 2

local add_player_row = function(index)
	local row_id = "player_row_"..index
	local vertical_offset = ROW_HEIGHT * (index - 1) * -1
	scenegraph_definition[row_id] = {
		parent = "info_panel",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			INFO_PANEL_WIDTH,
			ROW_HEIGHT
		},
		position = {
			0,
			vertical_offset,
			1
		}
	}
	widgets[row_id] = {
		scenegraph_id = row_id,
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "player_name",
					style_id = "player_name"
				},
				{
					pass_type = "texture",
					texture_id = "validity_icon",
					style_id = "validity_icon"
				},
				{
					pass_type = "text",
					text_id = "deck_name",
					style_id = "deck_name"
				},
			}
		},
		content = {
			player_name = "Player",
			deck_name = "Deck",
			validity_icon = "enigma_card_x"
		},
		style = {
			player_name = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				font_size = TEXT_SIZE,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					10,
					0,
					1
				}
			},
			validity_icon = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				font_size = TEXT_SIZE,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				texture_size = {
					TEXT_SIZE,
					TEXT_SIZE
				},
				offset = {
					30,
					TEXT_SIZE * -1 - 2,
					1
				}
			},
			deck_name = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				font_size = TEXT_SIZE,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					30 + TEXT_SIZE + 5,
					TEXT_SIZE * -1 - 2,
					1
				}
			}
		}
	}
end

for i=1,5 do
	add_player_row(i)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	info_panel_height = INFO_PANEL_HEIGHT
}
