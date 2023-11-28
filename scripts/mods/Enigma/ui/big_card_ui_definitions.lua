local CARD_WIDTH = 512
local CARD_HEIGHT = 828

local CARD_FRAME_THICKNESS = 4

local PRETTY_MARGIN = 10
local CARD_NAME_BOX_WIDTH = CARD_WIDTH - 180
local CARD_NAME_BOX_HEIGHT = 110

local CARD_INNER_WIDTH = CARD_WIDTH - CARD_FRAME_THICKNESS*2
local CARD_INNER_HEIGHT = CARD_HEIGHT - CARD_FRAME_THICKNESS*2

local CARD_IMAGE_HEIGHT = 310

local KEYWORD_COLOR = {
	255,
	25,
	230,
	15
}

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
	card = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			CARD_WIDTH,
			CARD_HEIGHT
		},
		position = {
			0,
			0,
			1
		}
	},
	card_name = {
		parent = "card",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			CARD_NAME_BOX_WIDTH,
			CARD_NAME_BOX_HEIGHT
		},
		position = {
			0,
			PRETTY_MARGIN*-1 - CARD_FRAME_THICKNESS,
			1
		}
	},
	card_image = {
		parent = "card",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			CARD_INNER_WIDTH,
			CARD_IMAGE_HEIGHT
		},
		position = {
			0,
			PRETTY_MARGIN*-2 - CARD_NAME_BOX_HEIGHT - CARD_FRAME_THICKNESS,
			1
		}
	},
	card_details = {
		parent = "card",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			CARD_INNER_WIDTH - PRETTY_MARGIN*2,
			CARD_INNER_HEIGHT - CARD_NAME_BOX_HEIGHT - CARD_IMAGE_HEIGHT - PRETTY_MARGIN*4
		},
		position = {
			0,
			CARD_FRAME_THICKNESS + PRETTY_MARGIN,
			1
		}
	}
}

local add_described_keyword_passes = function(widget_def, index)
	local title_name = "described_keyword_title_"..index
	table.insert(widget_def.element.passes, {
		pass_type = "text",
		text_id = title_name,
		style_id = title_name
	})
	widget_def.content[title_name] = ""
	widget_def.style[title_name] = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		font_size = 32,
		localize = false,
		word_wrap = true,
		area_size = {
			CARD_INNER_WIDTH,
			0
		},
		dynamic_font_size_word_wrap = true,
		font_type = "hell_shark",
		text_color = KEYWORD_COLOR,
		offset = {
			0,
			0,
			0
		}
	}
	local text_name = "described_keyword_text_"..index
	table.insert(widget_def.element.passes, {
		pass_type = "text",
		text_id = text_name,
		style_id = text_name
	})
	widget_def.content[text_name] = ""
	widget_def.style[text_name] = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		font_size = 32,
		localize = false,
		word_wrap = true,
		dynamic_font_size_word_wrap = true,
		area_size = {
			CARD_INNER_WIDTH,
			0
		},
		font_type = "hell_shark",
		text_color = {
			255,
			0,
			0,
			0
		},
		offset = {
			0,
			0,
			0
		}
	}
end

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
	card = {
		scenegraph_id = "card",
		element = {
			passes = {
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
			}
		},
		content = {
			card_background = "enigma_card_background",
			card_frame = "enigma_card_frame",
		},
		style = {
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
		}
	},
	card_name = {
		scenegraph_id = "card_name",
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "card_name",
					style_id = "card_name"
				},
			}
		},
		content = {
			card_name = ""
		},
		style = {
			card_name = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 64,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = "hell_shark_header",
				text_color = {
					255,
					0,
					0,
					0
				},
				offset = {
					0,
					0,
					0
				}
			},
		}
	},
	card_image = {
		scenegraph_id = "card_image",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "card_image",
					style_id = "card_image"
				},
			}
		},
		content = {
			card_image = "enigma_card_image_placeholder"
		},
		style = {
			card_image = {
				texture_size = {
					CARD_INNER_WIDTH,
					CARD_IMAGE_HEIGHT
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0
				},
			},
		}
	},
	card_details = {
		scenegraph_id = "card_details",
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "card_text",
					style_id = "card_text"
				},
				{
					pass_type = "text",
					text_id = "simple_keywords_text",
					style_id = "simple_keywords_text"
				},
			}
		},
		content = {
			card_text = "",
			simple_keywords_text = ""
		},
		style = {
			card_text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 32,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				area_size = {
					CARD_INNER_WIDTH,
					0
				},
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					0,
					0
				},
				offset = {
					0,
					0,
					0
				}
			},
			simple_keywords_text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 32,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				area_size = {
					CARD_INNER_WIDTH,
					0
				},
				font_type = "hell_shark",
				text_color = KEYWORD_COLOR,
				offset = {
					0,
					0,
					0
				}
			}
		}
	},
}

for i=1,5 do
	add_described_keyword_passes(widgets.card_details, i)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
