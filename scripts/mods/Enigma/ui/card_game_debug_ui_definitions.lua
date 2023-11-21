local VERTICAL_ALIGNMENT = "top"
local HORIZONTAL_ALIGNMENT = "left"
local FIRST_ROW_OFFSET = { 192, -10 }
local TEXT_COLUMN_WIDTH = 200
local TEXT_ROW_HEIGHT = 25
local FONT_SIZE = 20

local scenegraph_definition = {
	fullscreen_display = {
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
	}
}
local widgets = {
	fullscreen_display = {
		scenegraph_id = "fullscreen_display",
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "draws_label",
					style_id = "draws_label"
				},
				{
					pass_type = "text",
					text_id = "draws_text",
					style_id = "draws_text"
				},
				{
					pass_type = "text",
					text_id = "warpstone_label",
					style_id = "warpstone_label"
				},
				{
					pass_type = "text",
					text_id = "warpstone_text",
					style_id = "warpstone_text"
				},
				{
					pass_type = "text",
					text_id = "warp_dust_label",
					style_id = "warp_dust_label"
				},
				{
					pass_type = "text",
					text_id = "warp_dust_text",
					style_id = "warp_dust_text"
				},
				{
					pass_type = "text",
					text_id = "card_1_text",
					style_id = "card_1_text"
				},
				{
					pass_type = "text",
					text_id = "card_2_text",
					style_id = "card_2_text"
				},
				{
					pass_type = "text",
					text_id = "card_3_text",
					style_id = "card_3_text"
				},
				{
					pass_type = "text",
					text_id = "card_4_text",
					style_id = "card_4_text"
				},
				{
					pass_type = "text",
					text_id = "card_5_text",
					style_id = "card_5_text"
				},
			}
		},
		content = {
			draws_label = "Draws:",
			draws_text = 0,
			warpstone_label = "Warpstone:",
			warpstone_text = 0,
			warp_dust_label = "Warp Dust:",
			warp_dust_tet = 0,
			card_1_text = "",
			card_2_text = "",
			card_3_text = "",
			card_4_text = "",
			card_5_text = "",
		},
		style = {
			
			draws_label = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2],
					0
				}
			},
			draws_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1] + TEXT_COLUMN_WIDTH,
					FIRST_ROW_OFFSET[2],
					0
				}
			},
			warpstone_label = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT,
					0
				}
			},
			warpstone_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1] + TEXT_COLUMN_WIDTH,
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT,
					0
				}
			},
			warp_dust_label = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*2,
					0
				}
			},
			warp_dust_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1] + TEXT_COLUMN_WIDTH,
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*2,
					0
				}
			},
			card_1_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*3,
					0
				}
			},
			card_2_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*4,
					0
				}
			},
			card_3_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*5,
					0
				}
			},
			card_4_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*6,
					0
				}
			},
			card_5_text = {
				vertical_alignment = VERTICAL_ALIGNMENT,
				horizontal_alignment = HORIZONTAL_ALIGNMENT,
				font_size = FONT_SIZE,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				},
				offset = {
					FIRST_ROW_OFFSET[1],
					FIRST_ROW_OFFSET[2] - TEXT_ROW_HEIGHT*7,
					0
				}
			},
		}
	}
}

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
