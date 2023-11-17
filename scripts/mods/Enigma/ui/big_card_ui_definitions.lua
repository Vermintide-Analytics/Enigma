local CARD_WIDTH = 512
local CARD_HEIGHT = 828

local CARD_IMAGE_WIDTH = 504
local CARD_IMAGE_HEIGHT = 310


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
					pass_type = "rect",
					style_id = "fullscreen_shade"
				},
				{
					pass_type = "texture",
					texture_id = "card_background",
					style_id = "card_background"
				},
				{
					pass_type = "texture",
					texture_id = "card_frame",
					style_id = "card_frame"
				},
				{
					pass_type = "text",
					text_id = "card_name",
					style_id = "card_name"
				},
				{
					pass_type = "texture",
					texture_id = "card_image",
					style_id = "card_image"
				}
			}
		},
		content = {
			card_name = "",
			card_background = "enigma_card_background",
			card_frame = "enigma_card_frame",
			card_image = "enigma_card_image_placeholder"
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
			card_background = {
				texture_size = {
					CARD_WIDTH,
					CARD_HEIGHT
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0
				},
				color = {
					255,
					255,
					255,
					255
				}
			},
			card_frame = {
				texture_size = {
					CARD_WIDTH,
					CARD_HEIGHT
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0
				},
			},
			card_name = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = 42,
				localize = false,
				word_wrap = true,
				font_type = "hell_shark_header",
				text_color = {
					255,
					0,
					0,
					0
				},
				offset = {
					0,
					-146,
					0
				}
			},
			card_image = {
				texture_size = {
					CARD_IMAGE_WIDTH,
					CARD_IMAGE_HEIGHT
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					109,
					0
				},
			}
		}
	}
}

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
