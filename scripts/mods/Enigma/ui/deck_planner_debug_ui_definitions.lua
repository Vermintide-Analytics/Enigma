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
					text_id = "equipped_deck_label",
					style_id = "equipped_deck_label"
				},
				{
					pass_type = "text",
					text_id = "equipped_deck_name",
					style_id = "equipped_deck_name"
				},
				{
					pass_type = "text",
					text_id = "editing_deck_label",
					style_id = "editing_deck_label"
				},
				{
					pass_type = "text",
					text_id = "editing_deck_name",
					style_id = "editing_deck_name"
				},
				{
					pass_type = "text",
					text_id = "editing_deck_num_cards_label",
					style_id = "editing_deck_num_cards_label"
				},
				{
					pass_type = "text",
					text_id = "editing_deck_num_cards_text",
					style_id = "editing_deck_num_cards_text"
				},
				{
					pass_type = "text",
					text_id = "card_list_text",
					style_id = "card_list_text"
				},
			}
		},
		content = {
			equipped_deck_label = "Equipped Deck:",
			editing_deck_label = "Editing Deck:",
			editing_deck_num_cards_label = "# Cards:",

			equipped_deck_name = "",
			editing_deck_name = "",
			editing_deck_num_cards_text = "",
			card_list_text = ""
		},
		style = {
			
			equipped_deck_label = {
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
			equipped_deck_name = {
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
			editing_deck_label = {
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
			editing_deck_name = {
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
			editing_deck_num_cards_label = {
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
			editing_deck_num_cards_text = {
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
			card_list_text = {
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
		}
	}
}

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
