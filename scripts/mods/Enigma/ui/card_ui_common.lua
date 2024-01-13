local enigma = get_mod("Enigma")

-- Values for a 512x828 card display
local DEFAULT_CARD_WIDTH = 512
local DEFAULT_CARD_HEIGHT = 828
local DEFAULT_CARD_FRAME_THICKNESS = 4
local DEFAULT_PRETTY_MARGIN = 6

local DEFAULT_CARD_GLOW_WIDTH = DEFAULT_CARD_WIDTH + 80
local DEFAULT_CARD_GLOW_HEIGHT = DEFAULT_CARD_HEIGHT + 80

local DEFAULT_CARD_NAME_BOX_WIDTH = 226
local DEFAULT_CARD_NAME_BOX_HEIGHT = 86

local DEFAULT_CARD_IMAGE_WIDTH = DEFAULT_CARD_WIDTH - DEFAULT_CARD_FRAME_THICKNESS*2
local DEFAULT_CARD_IMAGE_HEIGHT = 310

local DEFAULT_CARD_DETAILS_WIDTH = DEFAULT_CARD_WIDTH - DEFAULT_CARD_FRAME_THICKNESS*2 - DEFAULT_PRETTY_MARGIN*2
local DEFAULT_CARD_DETAILS_HEIGHT = 366

local DEFAULT_CARD_PACK_WIDTH = 328
local DEFAULT_CARD_PACK_HEIGHT = 40

local DEFAULT_COST_CIRCLE_DIAMETER = 128

local DEFAULT_CARD_NAME_FONT_SIZE = 64
local DEFAULT_COST_FONT_SIZE = 128
local DEFAULT_DURATION_FONT_SIZE = 72
local DEFAULT_CHARGES_FONT_SIZE = 96
local DEFAULT_CARD_DETAILS_FONT_SIZE = 32
local DEFAULT_CARD_PACK_FONT_SIZE = 28

local CARD_NAME_FONT = "hell_shark_header"
local CARD_DETAILS_FONT = "hell_shark"

-- Card vertical breakdown
-- Frame 4
-- Name Box 86
-- Margin 6
-- Image 310
-- Margin 6
-- Details 366
-- Margin 6
-- Pack Box 40
-- Frame 4

local card_ui_common = {
    card_colors = {
        passive = {
            255,
            205,
            198,
            111
        },
		passive_highlight = {
			255,
			245,
			239,
			169
		},
        attack = {
            255,
            187,
            124,
            118
        },
		attack_highlight = {
			255,
			223,
			173,
			168
		},
        ability = {
            255,
            130,
            174,
            216
        },
		ability_highlight = {
			255,
			176,
			207,
			237
		},
        chaos = {
            255,
            50,
            55,
            50
        },
		chaos_highlight = {
			255,
			80,
			80,
			80
		},
        default = {
            255,
            200,
            200,
            200
        },
		default_highlight = {
			255,
			255,
			255,
			255
		}
    },
	rarity_colors = {
		[enigma.CARD_RARITY.common] = {
			255,
			255,
			255,
			255
		},
		[enigma.CARD_RARITY.rare] = {
			255,
			50,
			127,
			255
		},
		[enigma.CARD_RARITY.epic] = {
			255,
			147,
			112,
			219
		},
		[enigma.CARD_RARITY.legendary] = {
			255,
			255,
			165,
			0
		},
		unknown = {
			0,
			128,
			128,
			128
		}
	}
}

local add_card_scenegraph_nodes = function(scenegraph_defs, parent_id, card_scenegraph_id, sizes)
	local card_width = sizes.card_width
	local card_height = sizes.card_height
	local card_frame_thickness = sizes.card_frame_thickness
	local pretty_margin = sizes.pretty_margin

	scenegraph_defs[card_scenegraph_id] = {
		parent = parent_id,
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			card_width,
			card_height
		},
		position = {
			0,
			0,
			1
		}
	}

	local card_glow_scenegraph_id = card_scenegraph_id.."_glow"
	scenegraph_defs[card_glow_scenegraph_id] = {
		parent = card_scenegraph_id,
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			sizes.card_glow_width,
			sizes.card_glow_height
		},
		position = {
			0,
			0,
			0
		}
	}

	local card_inner_scenegraph_id = card_scenegraph_id.."_inner"
	scenegraph_defs[card_inner_scenegraph_id] = {
		parent = card_scenegraph_id,
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			card_width - card_frame_thickness*2,
			card_height - card_frame_thickness*2
		},
		position = {
			0,
			0,
			1
		}
	}

	local name_scenegraph_id = card_scenegraph_id.."_name"
	scenegraph_defs[name_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_name_box_width,
			sizes.card_name_box_height
		},
		position = {
			0,
			0,
			2
		}
	}

	local cost_scenegraph_id = card_scenegraph_id.."_cost"
	scenegraph_defs[cost_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_cost_circle_diameter,
			sizes.card_cost_circle_diameter
		},
		position = {
			sizes.card_name_box_width/2 + sizes.card_cost_circle_diameter/1.6,
			sizes.card_cost_circle_diameter * 0.34,
			2
		}
	}

	local duration_scenegraph_id = card_scenegraph_id.."_duration"
	scenegraph_defs[duration_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_cost_circle_diameter,
			sizes.card_cost_circle_diameter
		},
		position = {
			sizes.card_name_box_width/-2 - sizes.card_cost_circle_diameter/1.6,
			sizes.card_cost_circle_diameter * 0.34,
			2
		}
	}
	
	local charges_scenegraph_id = card_scenegraph_id.."_charges"
	scenegraph_defs[charges_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			sizes.card_cost_circle_diameter,
			sizes.card_cost_circle_diameter
		},
		position = {
			sizes.card_name_box_width/-2 - sizes.card_cost_circle_diameter/1.6,
			sizes.card_cost_circle_diameter * -0.34,
			2
		}
	}

	local image_scenegraph_id = card_scenegraph_id.."_image"
	scenegraph_defs[image_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_image_width,
			sizes.card_image_height
		},
		position = {
			0,
			pretty_margin*-1 - sizes.card_name_box_height,
			1
		}
	}

	local pack_scenegraph_id = card_scenegraph_id.."_pack"
	scenegraph_defs[pack_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			sizes.card_pack_width,
			sizes.card_pack_height
		},
		position = {
			0,
			0,
			1
		}
	}

	local details_scenegraph_id = card_scenegraph_id.."_details"
	scenegraph_defs[details_scenegraph_id] = {
		parent = card_inner_scenegraph_id,
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			sizes.card_details_width,
			sizes.card_details_height
		},
		position = {
			0,
			pretty_margin + sizes.card_pack_height,
			1
		}
	}

	local details_row_height = scenegraph_defs[details_scenegraph_id].size[2] / 7

	local basic_details_scenegraph_id = card_scenegraph_id.."_basic_details"
	scenegraph_defs[basic_details_scenegraph_id] = {
		parent = details_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_details_width,
			details_row_height
		},
		position = {
			0,
			0,
			1
		}
	}
	
	for i=1,5 do
		local keyword_details_id = card_scenegraph_id.."_keyword_details_"..i
		scenegraph_defs[keyword_details_id] = {
			parent = details_scenegraph_id,
			vertical_alignment = "top",
			horizontal_alignment = "center",
			size = {
				sizes.card_details_width,
				details_row_height
			},
			position = {
				0,
				details_row_height*i,
				1
			}
		}
	end
	
	local additional_keywords_scenegraph_id = card_scenegraph_id.."_additional_keywords"
	scenegraph_defs[additional_keywords_scenegraph_id] = {
		parent = details_scenegraph_id,
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			sizes.card_details_width,
			details_row_height
		},
		position = {
			0,
			details_row_height*6,
			1
		}
	}
end

local TEXT_COLOR = {
	255,
	0,
	0,
	0
}
local TEXT_COLOR_WHITE = {
	255,
	255,
	255,
	255
}
local KEYWORD_COLOR = {
	255,
	25,
	230,
	15
}

local GLOW_PLAYABLE = {
	255,
	30,
	255,
	0
}
local GLOW_RETAIN = {
	255,
	255,
	255,
	142
}
local GLOW_RETAIN_PLAYABLE = {
	255,
	201,
	244,
	136
}

local add_black_box_test_passes = function(widget, pass_id, area_size, font_size, font, color, outline_color)
	local passes = widget.element.passes
	local styles = widget.style
	local content = widget.content
	
	local rect_id = pass_id.."_box"
	table.insert(passes, {
		pass_type = "texture",
		texture_id = rect_id,
		style_id = rect_id
	})
	content[rect_id] = "enigma_card_card_glow"
	styles[rect_id] = {
		color = outline_color,
		texture_size = area_size or {0, 0},
		vertical_alignment = "center",
		horizontal_alignment = "center",
		offset = {
			0,
			0,
			0
		}
	}

	table.insert(passes, {
		pass_type = "text",
		text_id = pass_id,
		style_id = pass_id
	})
	content[pass_id] = ""
	styles[pass_id] = {
		vertical_alignment = "center",
		horizontal_alignment = "center",
		font_size = font_size,
		allow_fractions = true,
		localize = false,
		word_wrap = true,
		area_size = area_size,
		dynamic_font_size_word_wrap = true,
		font_type = font,
		text_color = color,
		offset = {
			0,
			0,
			1
		}
	}

end

local add_keyword_text_passes = function(widget, pass_id, area_size, font_size)
	add_black_box_test_passes(widget, pass_id, area_size, font_size, CARD_DETAILS_FONT, KEYWORD_COLOR, { 150, 0, 0, 0})
end

local add_described_keyword_widget = function(widget_defs, card_scenegraph_id, index, sizes)
	local scenegraph_id = card_scenegraph_id.."_keyword_details_"..index

	widget_defs[scenegraph_id] = {
		scenegraph_id = scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "details",
					style_id = "details"
				},
			}
		},
		content = {
			details = ""
		},
		style = {
			details = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_details_font_size,
				allow_fractions = true,
				localize = false,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				area_size = {
					sizes.card_inner_width,
					0
				},
				font_type = CARD_DETAILS_FONT,
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					1
				}
			}
		}
	}
	local title_area_size = {
		sizes.card_inner_width,
		0
	}
	add_keyword_text_passes(widget_defs[scenegraph_id], "title", title_area_size, sizes.card_details_font_size)
end

local add_card_widgets = function(widget_defs, card_scenegraph_id, sizes, enable_hotspot)
	local card_width = sizes.card_width
	local card_height = sizes.card_height

	local card_widget_name = card_scenegraph_id
	widget_defs[card_widget_name] = {
		scenegraph_id = card_widget_name,
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
					card_width,
					card_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					1
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
					card_width,
					card_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					1
				},
			},
		}
	}

	if enable_hotspot then
		widget_defs[card_widget_name.."_interaction"] = {
			scenegraph_id = card_scenegraph_id,
			element = {
				passes = {
					{
						pass_type = "hotspot",
						content_id = "hotspot"
					}
				}
			},
			content = {
				hotspot = {}
			},
			style = {
				background = {
					offset = {
						0,
						0,
						10
					}
				}
			}
		}
	end

	local card_glow_widget_name = card_scenegraph_id.."_glow"
	widget_defs[card_glow_widget_name] = {
		scenegraph_id = card_glow_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "glow",
					style_id = "glow"
				}
			}
		},
		content ={
			glow = "enigma_card_card_glow",
			visible = false
		},
		style = {
			glow = {
				texture_size = {
					sizes.card_glow_width,
					sizes.card_glow_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					0
				},
				color = GLOW_PLAYABLE
			}
		}
	}

	local card_name_widget_name = card_scenegraph_id.."_name"
	widget_defs[card_name_widget_name] = {
		scenegraph_id = card_name_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "rarity_box",
					style_id = "rarity"
				},
				{
					pass_type = "text",
					text_id = "card_name",
					style_id = "card_name"
				},
			}
		},
		content = {
			rarity_box = "enigma_card_name_box",
			card_name = ""
		},
		style = {
			rarity = {
				texture_size = {
					sizes.card_name_box_width,
					sizes.card_name_box_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
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
				horizontal_alignment = "center",
				font_size = sizes.card_name_font_size,
				allow_fractions = true,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = CARD_NAME_FONT,
				text_color = TEXT_COLOR,
				area_size = {
					sizes.card_name_box_width,
					sizes.card_name_box_height
				},
				offset = {
					0,
					0,
					2
				}
			},
		}
	}

	local card_cost_widget_name = card_scenegraph_id.."_cost"
	widget_defs[card_cost_widget_name] = {
		scenegraph_id = card_cost_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "background",
					style_id = "background"
				},
				{
					pass_type = "text",
					text_id = "cost",
					style_id = "shadow"
				},
				{
					pass_type = "text",
					text_id = "cost",
					style_id = "cost"
				},
			}
		},
		content = {
			background = "enigma_card_warpstone",
			cost = ""
		},
		style = {
			background = {
				texture_size = {
					sizes.card_cost_circle_diameter,
					sizes.card_cost_circle_diameter
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				color = {
					255,
					190,
					190,
					190
				},
				offset = {
					0,
					0,
					1
				}
			},
			shadow = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_cost_font_size,
				font_type = CARD_NAME_FONT,
				text_color = {
					255,
					0,
					0,
					0
				},
				offset = {
					1,
					sizes.card_cost_font_size / -7,
					2
				}
			},
			cost = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_cost_font_size,
				font_type = CARD_NAME_FONT,
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					sizes.card_cost_font_size / -8,
					2
				}
			},
		}
	}

	local card_duration_widget_name = card_scenegraph_id.."_duration"
	widget_defs[card_duration_widget_name] = {
		scenegraph_id = card_duration_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "background",
					style_id = "background"
				},
				{
					pass_type = "text",
					text_id = "duration",
					style_id = "duration"
				},
			}
		},
		content = {
			background = "enigma_card_duration_icon",
			duration = ""
		},
		style = {
			background = {
				texture_size = {
					sizes.card_cost_circle_diameter,
					sizes.card_cost_circle_diameter
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				color = {
					255,
					217,
					123,
					84
				},
				offset = {
					0,
					0,
					1
				}
			},
			duration = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_duration_font_size,
				font_type = CARD_NAME_FONT,
				text_color = TEXT_COLOR,
				offset = {
					0,
					sizes.card_duration_font_size / -8,
					2
				}
			},
		}
	}

	local card_charges_widget_name = card_scenegraph_id.."_charges"
	widget_defs[card_charges_widget_name] = {
		scenegraph_id = card_charges_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "background",
					style_id = "background"
				},
				{
					pass_type = "text",
					text_id = "charges",
					style_id = "charges"
				},
			}
		},
		content = {
			background = "enigma_card_charges_icon",
			charges = ""
		},
		style = {
			background = {
				texture_size = {
					sizes.card_cost_circle_diameter,
					sizes.card_cost_circle_diameter
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				color = {
					255,
					214,
					214,
					30
				},
				offset = {
					0,
					0,
					1
				}
			},
			charges = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_charges_font_size,
				font_type = CARD_NAME_FONT,
				text_color = TEXT_COLOR,
				offset = {
					0,
					sizes.card_charges_font_size / -8,
					2
				}
			},
		}
	}

	local card_image_widget_name = card_scenegraph_id.."_image"
	widget_defs[card_image_widget_name] = {
		scenegraph_id = card_image_widget_name,
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
					sizes.card_image_width,
					sizes.card_image_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					1
				},
			},
		}
	}

	local card_pack_widget_name = card_scenegraph_id.."_pack"
	widget_defs[card_pack_widget_name] = {
		scenegraph_id = card_pack_widget_name,
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "background",
					style_id = "background"
				},
				{
					pass_type = "text",
					text_id = "pack_name",
					style_id = "pack_name"
				}
			}
		},
		content = {
			background = "enigma_card_pack_box",
			pack_name = ""
		},
		style = {
			background = {
				texture_size = {
					sizes.card_pack_width,
					sizes.card_pack_height
				},
				vertical_alignment = "center",
				horizontal_alignment = "center",
				offset = {
					0,
					0,
					1
				},
				color = {
					255,
					190,
					190,
					190
				},
			},
			pack_name = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_pack_font_size,
				allow_fractions = true,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = CARD_NAME_FONT,
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					2
				}
			},
		}
	}

	local basic_details_widget_name = card_scenegraph_id.."_basic_details"
	widget_defs[basic_details_widget_name] = {
		scenegraph_id = basic_details_widget_name,
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "details",
					style_id = "details"
				}
			}
		},
		content = {
			details = ""
		},
		style = {
			details = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_details_font_size,
				allow_fractions = true,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = CARD_DETAILS_FONT,
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					1
				}
			},
		}
	}

	for i=1,5 do
		add_described_keyword_widget(widget_defs, card_scenegraph_id, i, sizes)
	end

	local additional_keywords_widget_name = card_scenegraph_id.."_additional_keywords"
	widget_defs[additional_keywords_widget_name] = {
		scenegraph_id = additional_keywords_widget_name,
		element = {
			passes = {
			}
		},
		content = {
		},
		style = {
		}
	}
	add_keyword_text_passes(widget_defs[additional_keywords_widget_name], "keywords", nil, sizes.card_details_font_size)
end

local calculate_card_sizes = function(card_width)
	local scaling_from_default = card_width / DEFAULT_CARD_WIDTH
	local card_frame_thickness = DEFAULT_CARD_FRAME_THICKNESS * scaling_from_default
	local card_height = DEFAULT_CARD_HEIGHT * scaling_from_default
	local sizes = {
		card_width = card_width,
		card_height = card_height,
		card_glow_width = DEFAULT_CARD_GLOW_WIDTH * scaling_from_default,
		card_glow_height = DEFAULT_CARD_GLOW_HEIGHT * scaling_from_default,
		scaling_from_default = scaling_from_default,
		card_frame_thickness = card_frame_thickness,
		pretty_margin = DEFAULT_PRETTY_MARGIN * scaling_from_default,
		card_inner_width = card_width - card_frame_thickness*2,
		card_inner_height = card_height - card_frame_thickness*2,
		card_name_box_width = DEFAULT_CARD_NAME_BOX_WIDTH * scaling_from_default,
		card_name_box_height = DEFAULT_CARD_NAME_BOX_HEIGHT * scaling_from_default,
		card_name_font_size = DEFAULT_CARD_NAME_FONT_SIZE * scaling_from_default,
		card_cost_circle_diameter = DEFAULT_COST_CIRCLE_DIAMETER * scaling_from_default,
		card_cost_font_size = DEFAULT_COST_FONT_SIZE * scaling_from_default,
		card_duration_font_size = DEFAULT_DURATION_FONT_SIZE * scaling_from_default,
		card_charges_font_size = DEFAULT_CHARGES_FONT_SIZE * scaling_from_default,
		card_image_width = DEFAULT_CARD_IMAGE_WIDTH * scaling_from_default,
		card_image_height = DEFAULT_CARD_IMAGE_HEIGHT * scaling_from_default,
		card_details_width = DEFAULT_CARD_DETAILS_WIDTH * scaling_from_default,
		card_details_height = DEFAULT_CARD_DETAILS_HEIGHT * scaling_from_default,
		card_details_font_size = DEFAULT_CARD_DETAILS_FONT_SIZE * scaling_from_default,
		card_pack_width = DEFAULT_CARD_PACK_WIDTH * scaling_from_default,
		card_pack_height = DEFAULT_CARD_PACK_HEIGHT * scaling_from_default,
		card_pack_font_size = DEFAULT_CARD_PACK_FONT_SIZE * scaling_from_default
	}
	return sizes
end

card_ui_common.add_card_display = function(scenegraph_defs, widget_defs, scenegraph_parent_id, card_scenegraph_id, card_width, enable_hotspot)
	local sizes = calculate_card_sizes(card_width)
	add_card_scenegraph_nodes(scenegraph_defs, scenegraph_parent_id, card_scenegraph_id, sizes)
	add_card_widgets(widget_defs, card_scenegraph_id, sizes, enable_hotspot)
end

local set_widgets_visibility = function(widgets, card_node_id, visible, has_duration, has_charges, glow)
	visible = not not visible
	has_duration = not not has_duration
	has_charges = not not has_charges
	glow = not not glow

	widgets[card_node_id].content.visible = visible
	
	local card_glow_node_id = card_node_id.."_glow"
	local card_name_node_id = card_node_id.."_name"
	local card_image_node_id = card_node_id.."_image"
	local card_pack_node_id = card_node_id.."_pack"
	local card_cost_node_id = card_node_id.."_cost"
	local card_duration_node_id = card_node_id.."_duration"
	local card_charges_node_id = card_node_id.."_charges"
	
	local card_widget = widgets[card_node_id]
	card_widget.content.visible = visible
	local card_glow_widget = widgets[card_glow_node_id]
	card_glow_widget.content.visible = visible and glow
	local card_name_widget = widgets[card_name_node_id]
	card_name_widget.content.visible = visible
	local card_cost_widget = widgets[card_cost_node_id]
	card_cost_widget.content.visible = visible
	local card_duration_widget = widgets[card_duration_node_id]
	card_duration_widget.content.visible = visible and has_duration
	local card_charges_widget = widgets[card_charges_node_id]
	card_charges_widget.content.visible = visible and has_charges
	local card_image_widget = widgets[card_image_node_id]
	card_image_widget.content.visible = visible
	local card_pack_widget = widgets[card_pack_node_id]
	card_pack_widget.content.visible = visible
	local basic_details_widget = widgets[card_node_id.."_basic_details"]
	basic_details_widget.content.visible = visible
	for i=1,5 do
		local keyword_details_widget = widgets[card_node_id.."_keyword_details_"..i]
		keyword_details_widget.content.visible = visible
	end
	local additional_keywords_widget = widgets[card_node_id.."_additional_keywords"]
	additional_keywords_widget.content.visible = visible
end

local update_outline_text_widget = function(widget, pass_id, width, height, vertical_offset, font_size, scaling)
	scaling = scaling or 1
	local text_style = widget.style[pass_id]
	if text_style.area_size then
		text_style.area_size[1] = width or text_style.area_size[1]
		text_style.area_size[2] = height or text_style.area_size[2]
	end
	text_style.offset[2] = vertical_offset or text_style.offset[2]
	text_style._dynamic_wraped_text = ""
	text_style.font_size = font_size or text_style.font_size

	local box_style = widget.style[pass_id.."_box"]
	box_style.texture_size[1] = width or box_style.texture_size[1]
	box_style.texture_size[2] = height or box_style.texture_size[2]
	box_style.offset[2] = vertical_offset or box_style.offset[2]
end

card_ui_common.update_card_display = function(ui_renderer, scenegraph_nodes, widgets, card_node_id, card, card_width, dirty_property_name, card_glow_override)
	local scaling_from_default = card_width / DEFAULT_CARD_WIDTH
	local sizes = calculate_card_sizes(card_width)
	local pretty_margin = sizes.pretty_margin

	local playable = card and not card.unplayable and card.condition_met and card.can_pay_warpstone
	local has_retain = card and #card.retain_descriptions > 0
	local in_hand = card and card.location == enigma.CARD_LOCATION.hand
	local show_glow = playable or (has_retain and in_hand)
	if card_glow_override ~= nil then
		show_glow = card_glow_override
	end
	set_widgets_visibility(widgets, card_node_id, card, card and card.duration, card and card.charges, show_glow)
	if not card then
		return
	end
	
	dirty_property_name = dirty_property_name or "dirty"
	card[dirty_property_name] = false

	local basic_text_color = (card.card_type == enigma.CARD_TYPE.chaos) and TEXT_COLOR_WHITE or TEXT_COLOR

	-- Set scenegraph node sizes and positions
	scenegraph_nodes[card_node_id].size[1] = card_width
	scenegraph_nodes[card_node_id].size[2] = sizes.card_height

	local card_inner_node_id = card_node_id.."_inner"
	scenegraph_nodes[card_inner_node_id].size[1] = sizes.card_inner_width
	scenegraph_nodes[card_inner_node_id].size[2] = sizes.card_inner_height

	local card_name_node_id = card_node_id.."_name"
	scenegraph_nodes[card_name_node_id].size[1] = sizes.card_name_box_width
	scenegraph_nodes[card_name_node_id].size[2] = sizes.card_name_box_height

	local card_cost_node_id = card_node_id.."_cost"
	scenegraph_nodes[card_cost_node_id].size[1] = sizes.card_cost_circle_diameter
	scenegraph_nodes[card_cost_node_id].size[2] = sizes.card_cost_circle_diameter

	local card_duration_node_id = card_node_id.."_duration"
	scenegraph_nodes[card_duration_node_id].size[1] = sizes.card_cost_circle_diameter
	scenegraph_nodes[card_duration_node_id].size[2] = sizes.card_cost_circle_diameter
	
	local card_charges_node_id = card_node_id.."_charges"
	scenegraph_nodes[card_charges_node_id].size[1] = sizes.card_cost_circle_diameter
	scenegraph_nodes[card_charges_node_id].size[2] = sizes.card_cost_circle_diameter

	local card_image_node_id = card_node_id.."_image"
	scenegraph_nodes[card_image_node_id].size[1] = sizes.card_image_width
	scenegraph_nodes[card_image_node_id].size[2] = sizes.card_image_height
	scenegraph_nodes[card_image_node_id].position[2] = pretty_margin*-1 - sizes.card_name_box_height

	local card_pack_node_id = card_node_id.."_pack"
	scenegraph_nodes[card_pack_node_id].size[1] = sizes.card_pack_width
	scenegraph_nodes[card_pack_node_id].size[2] = sizes.card_pack_height

	local card_details_node_id = card_node_id.."_details"
	scenegraph_nodes[card_details_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[card_details_node_id].size[2] = sizes.card_details_height
	scenegraph_nodes[card_details_node_id].position[2] = pretty_margin + sizes.card_pack_height

	local details_font_material = Fonts[CARD_DETAILS_FONT][1]

	local num_description_lines = #card.description_lines
	local description_vertical_spacing = 0
	for _,description_line_table in ipairs(card.description_lines) do
		local line_lines = UIRenderer.word_wrap(ui_renderer, description_line_table.localized, details_font_material, sizes.card_details_font_size, sizes.card_details_width, nil, CARD_DETAILS_FONT)
		description_vertical_spacing = description_vertical_spacing + #line_lines
	end

	local described_keyword_line_counts = {}
	local num_retain_descriptions = #card.retain_descriptions
	local retain_vertical_spacing = 0
	for _,retain_line_table in ipairs(card.retain_descriptions) do
		if #described_keyword_line_counts < 5 then
			local retain_lines = UIRenderer.word_wrap(ui_renderer, retain_line_table.localized, details_font_material, sizes.card_details_font_size, sizes.card_details_width)
			retain_vertical_spacing = retain_vertical_spacing + #retain_lines + 1
			table.insert(described_keyword_line_counts, #retain_lines + 1)
		end
	end

	local num_auto_descriptions = #card.auto_descriptions
	local auto_vertical_spacing = 0
	for _,auto_line_table in ipairs(card.auto_descriptions) do
		if #described_keyword_line_counts < 5 then
			local auto_lines = UIRenderer.word_wrap(ui_renderer, auto_line_table.localized, details_font_material, sizes.card_details_font_size, sizes.card_details_width)
			auto_vertical_spacing = auto_vertical_spacing + #auto_lines + 1
			table.insert(described_keyword_line_counts, #auto_lines + 1)
		end
	end

	local num_condition_descriptions = #card.condition_descriptions
	local condition_vertical_spacing = 0
	for _,condition_line_table in ipairs(card.condition_descriptions) do
		if #described_keyword_line_counts < 5 then
			local condition_lines = UIRenderer.word_wrap(ui_renderer, condition_line_table.localized, details_font_material, sizes.card_details_font_size, sizes.card_details_width)
			condition_vertical_spacing = condition_vertical_spacing + #condition_lines + 1
			table.insert(described_keyword_line_counts, #condition_lines + 1)
		end
	end

	local any_simple_keywords = card.channel or card.charges or card.double_agent or card.ephemeral or card.echo or card.primordial or card.unplayable or card.warp_hungry
	local simple_keywords_vertical_spacing = any_simple_keywords and 1 or 0
	
	local additional_keywords_text = ""
	if any_simple_keywords then
		local keywords = {}
		if card.channel then
			table.insert(keywords, enigma:localize("channel", card.channel))
		end
		if card.charges then
			table.insert(keywords, enigma:localize("charges", card.charges))
		end
		if card.double_agent then
			table.insert(keywords, enigma:localize("double_agent"))
		end
		if card.ephemeral then
			table.insert(keywords, enigma:localize("ephemeral"))
		end
		if card.echo then
			table.insert(keywords, enigma:localize("echo"))
		end
		if card.primordial then
			table.insert(keywords, enigma:localize("primordial"))
		end
		if card.unplayable then
			table.insert(keywords, enigma:localize("unplayable"))
		end
		if card.warp_hungry then
			table.insert(keywords, enigma:localize("warp_hungry", card.warp_hungry))
		end
		additional_keywords_text = table.concat(keywords, ", ")
	end

	local simple_keyword_lines = UIRenderer.word_wrap(ui_renderer, additional_keywords_text, details_font_material, sizes.card_details_font_size * RESOLUTION_LOOKUP.scale, sizes.card_details_width, nil, CARD_DETAILS_FONT)

	local total_vertical_spacing = math.max(description_vertical_spacing + retain_vertical_spacing + auto_vertical_spacing + condition_vertical_spacing + simple_keywords_vertical_spacing, 1)

	local num_detailed_keywords = math.min(num_retain_descriptions + num_auto_descriptions + num_condition_descriptions, 5)
	local num_section_padding = math.max((num_description_lines > 0 and 1 or 0) + num_detailed_keywords + (any_simple_keywords and 1 or 0) - 1, 0)

	local total_section_vertical_space = scenegraph_nodes[card_details_node_id].size[2] - num_section_padding*pretty_margin

	local basic_details_node_id = card_node_id.."_basic_details"
	local desired_descriptions_height = description_vertical_spacing / total_vertical_spacing * total_section_vertical_space
	scenegraph_nodes[basic_details_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[basic_details_node_id].size[2] = desired_descriptions_height

	if num_description_lines <= 0 then
		scenegraph_nodes[basic_details_node_id].size[2] = 0
	end

	local current_vertical_offset = 0
	if num_description_lines > 0 and num_section_padding > 0 then
		current_vertical_offset = current_vertical_offset - pretty_margin - desired_descriptions_height
		num_section_padding = num_section_padding - 1
	end

	for i=1,5 do
		local keyword_details_node_id = card_node_id.."_keyword_details_"..i
		local desired_height = (described_keyword_line_counts[i] or 0) / total_vertical_spacing * total_section_vertical_space
		scenegraph_nodes[keyword_details_node_id].size[1] = sizes.card_details_width
		scenegraph_nodes[keyword_details_node_id].size[2] = desired_height
		scenegraph_nodes[keyword_details_node_id].position[2] = current_vertical_offset

		if num_section_padding > 0 then
			current_vertical_offset = current_vertical_offset - pretty_margin - desired_height
			num_section_padding = num_section_padding - 1
		end
	end

	local additional_keywords_node_id = card_node_id.."_additional_keywords"
	local additional_keywords_desired_height = simple_keywords_vertical_spacing / total_vertical_spacing * total_section_vertical_space
	scenegraph_nodes[additional_keywords_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[additional_keywords_node_id].size[2] = additional_keywords_desired_height
	scenegraph_nodes[additional_keywords_node_id].position[2] = current_vertical_offset

	-- Set widget contents/styles
	local card_widget = widgets[card_node_id]
	local card_glow_widget = widgets[card_node_id.."_glow"]
	local card_name_widget = widgets[card_name_node_id]
	local card_cost_widget = widgets[card_cost_node_id]
	local card_duration_widget = widgets[card_duration_node_id]
	local card_charges_widget = widgets[card_charges_node_id]
	local card_image_widget = widgets[card_image_node_id]
	local basic_details_widget = widgets[card_node_id.."_basic_details"]
	local additional_keywords_widget = widgets[card_node_id.."_additional_keywords"]
	local card_pack_widget = widgets[card_pack_node_id]

	card_widget.style.card_background.texture_size[1] = sizes.card_width
	card_widget.style.card_background.texture_size[2] = sizes.card_height
	card_widget.style.card_frame.texture_size[1] = sizes.card_width
	card_widget.style.card_frame.texture_size[2] = sizes.card_height

	card_widget.style.card_background.color = card_ui_common.card_colors[card.card_type] or card_ui_common.card_colors.default

	-- Glow color
	local glow_color = GLOW_PLAYABLE
	if has_retain and in_hand then
		glow_color = playable and GLOW_RETAIN_PLAYABLE or GLOW_RETAIN
	end
	card_glow_widget.style.glow.color = glow_color


	card_name_widget.style.card_name._dynamic_wraped_text = ""
	card_name_widget.style.card_name.font_size = sizes.card_name_font_size
	card_name_widget.style.rarity.texture_size[1] = sizes.card_name_box_width*1.15
	card_name_widget.style.rarity.texture_size[2] = sizes.card_name_box_height
	card_name_widget.style.card_name.area_size[1] = sizes.card_name_box_width
	card_name_widget.style.card_name.area_size[2] = sizes.card_name_box_height
	card_name_widget.content.card_name = card.name

	card_name_widget.style.rarity.color = card_ui_common.rarity_colors[card.rarity]
	
	card_cost_widget.style.background.texture_size[1] = sizes.card_cost_circle_diameter
	card_cost_widget.style.background.texture_size[2] = sizes.card_cost_circle_diameter
	card_cost_widget.style.cost.font_size = sizes.card_cost_font_size
	card_cost_widget.content.cost = card.cost
	if card.local_id then
		card_cost_widget.content.cost = enigma.managers.buff:get_final_warpstone_cost(card)
	end
	
	card_duration_widget.style.background.texture_size[1] = sizes.card_cost_circle_diameter
	card_duration_widget.style.background.texture_size[2] = sizes.card_cost_circle_diameter
	card_duration_widget.style.duration.font_size = sizes.card_duration_font_size
	if card.duration_localized then
		card_duration_widget.content.duration = card.duration_localized
	elseif card.duration then
		if math.floor(card.duration) ~= card.duration then
			card_duration_widget.content.duration = string.format("%.1fs", card.duration)
		else
			card_duration_widget.content.duration = string.format("%is", card.duration)
		end
	else
		card_duration_widget.content.duration = ""
	end

	card_charges_widget.style.background.texture_size[1] = sizes.card_cost_circle_diameter
	card_charges_widget.style.background.texture_size[2] = sizes.card_cost_circle_diameter
	card_charges_widget.style.charges.font_size = sizes.card_charges_font_size
	if card.charges then
		card_charges_widget.content.charges = string.format("%i", card.charges)
	else
		card_charges_widget.content.charges = ""
	end

	card_image_widget.style.card_image.texture_size[1] = sizes.card_image_width
	card_image_widget.style.card_image.texture_size[2] = sizes.card_image_height
	if card.texture then
		card_image_widget.content.card_image = card.texture
	else
		card_image_widget.content.card_image = "enigma_card_image_placeholder"
	end
	if type(card.texture_tint) == "function" then
		card_image_widget.style.card_image.color = card:texture_tint()
	else
		card_image_widget.style.card_image.color = card.texture_tint
	end

	card_pack_widget.content.pack_name = card.card_pack.name

	if num_description_lines > 0 then
		local lines = {}
		for _,description_line_table in ipairs(card.description_lines) do
			table.insert(lines, description_line_table.localized)
		end
		basic_details_widget.content.details = table.concat(lines, "\n")
		basic_details_widget.style.details._dynamic_wraped_text = ""
		basic_details_widget.style.details.font_size = sizes.card_details_font_size
		basic_details_widget.style.details.text_color = basic_text_color
	else
		basic_details_widget.content.details = ""
	end

	for i=1,5 do
		local widget_name = card_node_id.."_keyword_details_"..i
		local total_vertical_size = scenegraph_nodes[widget_name].size[2]
		local keyword_details_widget = widgets[widget_name]

		local text_style = keyword_details_widget.style.details

		local total_lines = (described_keyword_line_counts[i] or 1)
		local max_full_size_lines = math.max(total_vertical_size / (sizes.card_details_font_size*1.6), 1)
		local required_height_usage = math.clamp(total_lines / max_full_size_lines, 0, 1)
		local required_height = required_height_usage * total_vertical_size
		local title_height = math.clamp((1 / total_lines), 1/5, 1/2) * required_height
		local description_height = required_height - title_height

		update_outline_text_widget(keyword_details_widget, "title", sizes.card_inner_width - pretty_margin*2, title_height, (required_height - title_height - pretty_margin)/2, sizes.card_details_font_size, scaling_from_default)		
		
		text_style.area_size[1] = sizes.card_inner_width - pretty_margin*2
		text_style.area_size[2] = description_height
		text_style.offset[2] = (description_height - required_height + pretty_margin)/2
		text_style._dynamic_wraped_text = ""
		text_style.font_size = sizes.card_details_font_size
		text_style.text_color = basic_text_color

		local content = keyword_details_widget.content
		content.title = ""
		content.details = ""
	end

	local described_keyword_index = 1
	local set_described_keyword_content = function(title_localized, details_localized)
		local widget_name = card_node_id.."_keyword_details_"..described_keyword_index
		local keyword_details_widget = widgets[widget_name]
		local content = keyword_details_widget.content

		content.title = title_localized
		content.details = details_localized
		
		described_keyword_index = described_keyword_index + 1

		local font_material, font_size = nil, nil
		if keyword_details_widget.style.title.font_type then
			local font, size_of_font = UIFontByResolution(keyword_details_widget.style.title)
			font_size = size_of_font
			font_material = font[1]
		end
		-- Update width/height of keyword box here, based on UIRenderer.text_size
		local title_text_width, title_text_height = UIRenderer.text_size(ui_renderer, content.title, font_material, font_size)
		keyword_details_widget.style.title_box.texture_size[1] = title_text_width*1.2 + 12*scaling_from_default
		keyword_details_widget.style.title_box.texture_size[2] = title_text_height*1.45 + 6*scaling_from_default
	end
	for _,retain_description_table in ipairs(card.retain_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		set_described_keyword_content(enigma:localize("retain"), retain_description_table.localized)
	end
	for _,auto_description_table in ipairs(card.auto_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		set_described_keyword_content(enigma:localize("auto"), auto_description_table.localized)
	end
	for _,condition_description_table in ipairs(card.condition_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		set_described_keyword_content(enigma:localize("condition"), condition_description_table.localized)
	end

	update_outline_text_widget(additional_keywords_widget, "keywords", nil, nil, nil, sizes.card_details_font_size, scaling_from_default)
	additional_keywords_widget.content.keywords = additional_keywords_text
	
	local font_material, font_size = nil, nil
	if additional_keywords_widget.style.keywords.font_type then
		local font, size_of_font = UIFontByResolution(additional_keywords_widget.style.keywords)
		font_size = size_of_font
		font_material = font[1]
	end
	-- Update width/height of keyword box here, based on UIRenderer.text_size
	local keywords_text_width, keywords_text_height = UIRenderer.text_size(ui_renderer, additional_keywords_widget.content.keywords, font_material, font_size)
	additional_keywords_widget.style.keywords_box.texture_size[1] = any_simple_keywords and math.min(keywords_text_width*1.2 + 12*scaling_from_default, sizes.card_details_width) or 0
	local keywords_box_height = any_simple_keywords and (keywords_text_height*1.45 + 6*scaling_from_default) or 0
	if any_simple_keywords then
		keywords_box_height = keywords_box_height * #simple_keyword_lines
	end
	additional_keywords_widget.style.keywords_box.texture_size[2] = keywords_box_height
end

card_ui_common.update_card_display_if_needed = function(ui_renderer, scenegraph_nodes, widgets, card_node_id, card, card_width, dirty_property_name, card_glow_override)
	if not card then
		if widgets[card_node_id].cached_card then
			widgets[card_node_id].cached_card = nil
			widgets[card_node_id].cached_card_width = -1
			return card_ui_common.update_card_display(ui_renderer, scenegraph_nodes, widgets, card_node_id, nil, card_width, card_glow_override)
		end
		return
	end
	dirty_property_name = dirty_property_name or "dirty"
	if card[dirty_property_name] or card ~= widgets[card_node_id].cached_card or card_width ~= widgets[card_node_id].cached_card_width or card.always_dirty then
		widgets[card_node_id].cached_card = card
		widgets[card_node_id].cached_card_width = card_width
		return card_ui_common.update_card_display(ui_renderer, scenegraph_nodes, widgets, card_node_id, card, card_width, dirty_property_name, card_glow_override)
	end
end

card_ui_common.handle_card_input = function(widgets, card_node_id, card, wwise_world)
	if not card then
		return
	end
	local interaction_widget = widgets[card_node_id.."_interaction"]
	if interaction_widget then
		if interaction_widget.content.hotspot.on_hover_enter then
			WwiseWorld.trigger_event(wwise_world, "Play_hud_hover")
		end
		local background_color = card_ui_common.card_colors[card.card_type] or card_ui_common.card_colors.default
		if interaction_widget.content.hotspot.is_hover then
			background_color = card_ui_common.card_colors[card.card_type.."_highlight"] or card_ui_common.card_colors.default_highlight
		end
		widgets[card_node_id].style.card_background.color = background_color
	end
end

card_ui_common.add_hand_display = function(scenegraph_defs, widget_defs, scenegraph_parent_id, card_width, enable_hotspots)
	for i=1,5 do
		card_ui_common.add_card_display(scenegraph_defs, widget_defs, scenegraph_parent_id, "hand_card_"..i, card_width, enable_hotspots)
	end
end

card_ui_common.update_hand_display = function(ui_renderer, scenegraph_nodes, widgets_by_name, card_width, card_margin, hand_ui_data, card_dirty_property_name)
	local hand = enigma.managers.game.local_data.hand
	local hand_size = #hand
	local desired_horizontal_position = (card_margin + card_width)/2 * (hand_size-1) * -1
	local removed_card_shift = 0
	for i=1,5 do
		local card = hand[i]
		local node_id = "hand_card_"..i
		card_ui_common.update_card_display_if_needed(ui_renderer, scenegraph_nodes, widgets_by_name, node_id, card, card_width, card_dirty_property_name)
		local card_scenegraph_node = scenegraph_nodes[node_id]
		
		if hand_ui_data.hand_indexes_just_removed[i] then
			-- Without this, playing a card in a lower index causes this card to instantly jolt to the left, which is
			-- visually confusing about which card was removed from the hand.
			removed_card_shift = removed_card_shift + card_margin + card_width
			hand_ui_data.hand_indexes_just_removed[i] = false
		end
		card_scenegraph_node.position[1] = card_scenegraph_node.position[1] + removed_card_shift

		local current_horizontal_position = card_scenegraph_node.position[1]
		card_scenegraph_node.position[1] = math.lerp(current_horizontal_position, desired_horizontal_position, 0.1)
		desired_horizontal_position = desired_horizontal_position + card_margin + card_width
	end
end

card_ui_common.handle_hand_input = function(widgets, wwise_world)
	local hand = enigma.managers.game.local_data.hand
	local hand_size = #hand

	for i=1,hand_size do
		card_ui_common.handle_card_input(widgets, "hand_card_"..i, hand[i], wwise_world)
	end
end

return card_ui_common