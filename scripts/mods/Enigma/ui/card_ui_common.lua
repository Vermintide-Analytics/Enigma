local enigma = get_mod("Enigma")

-- Values for a 512x828 card display
local DEFAULT_CARD_WIDTH = 512
local DEFAULT_CARD_HEIGHT = 828
local DEFAULT_CARD_FRAME_THICKNESS = 4
local DEFAULT_PRETTY_MARGIN = 6

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
local DEFAULT_CARD_DETAILS_FONT_SIZE = 32
local DEFAULT_CARD_PACK_FONT_SIZE = 28

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

local ui_common = {
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
        surge = {
            255,
            187,
            124,
            118
        },
		surge_highlight = {
			255,
			223,
			173,
			168
		},
        ability = {
            255,
            162,
            180,
            242
        },
		ability_highlight = {
			255,
			207,
			217,
			251
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
			sizes.card_name_box_width * 0.195,
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
local KEYWORD_COLOR = {
	255,
	25,
	230,
	15
}

local add_described_keyword_widget = function(widget_defs, card_scenegraph_id, index, sizes)
	local scenegraph_id = card_scenegraph_id.."_keyword_details_"..index

	widget_defs[scenegraph_id] = {
		scenegraph_id = scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "title",
					style_id = "title"
				},
				{
					pass_type = "text",
					text_id = "details",
					style_id = "details"
				},
			}
		},
		content = {
			title = "",
			details = ""
		},
		style = {
			title = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_details_font_size,
				allow_fractions = true,
				localize = false,
				word_wrap = true,
				area_size = {
					sizes.card_inner_width,
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
			},
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
				font_type = "hell_shark",
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					0
				}
			}
		}
	}
end

local add_card_widgets = function(widget_defs, card_scenegraph_id, sizes)
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
					card_width,
					card_height
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
					0
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
				font_type = "hell_shark_header",
				text_color = TEXT_COLOR,
				area_size = {
					sizes.card_name_box_width,
					sizes.card_name_box_height
				},
				offset = {
					0,
					0,
					1
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
					0
				}
			},
			cost = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_cost_font_size,
				font_type = "hell_shark_header",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					sizes.card_cost_font_size / -8,
					1
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
					0
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
					0
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
				font_type = "hell_shark_header",
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					1
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
				font_type = "hell_shark",
				text_color = TEXT_COLOR,
				offset = {
					0,
					0,
					0
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
				{
					pass_type = "text",
					text_id = "keywords",
					style_id = "keywords"
				}
			}
		},
		content = {
			keywords = ""
		},
		style = {
			keywords = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = sizes.card_details_font_size,
				allow_fractions = true,
				word_wrap = true,
				dynamic_font_size_word_wrap = true,
				font_type = "hell_shark",
				text_color = KEYWORD_COLOR,
				offset = {
					0,
					0,
					0
				}
			},
		}
	}
end

local calculate_card_sizes = function(card_width)
	local scaling_from_default = card_width / DEFAULT_CARD_WIDTH
	local card_frame_thickness = DEFAULT_CARD_FRAME_THICKNESS * scaling_from_default
	local card_height = DEFAULT_CARD_HEIGHT * scaling_from_default
	local sizes = {
		card_width = card_width,
		card_height = card_height,
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

ui_common.add_card_display = function(scenegraph_defs, widget_defs, scenegraph_parent_id, card_scenegraph_id, card_width)
	local sizes = calculate_card_sizes(card_width)
	add_card_scenegraph_nodes(scenegraph_defs, scenegraph_parent_id, card_scenegraph_id, sizes)
	add_card_widgets(widget_defs, card_scenegraph_id, sizes)
end

local set_widgets_visibility = function(widgets, card_node_id, visible)
	visible = not not visible
	
	widgets[card_node_id].content.visible = visible
	
	local card_name_node_id = card_node_id.."_name"
	local card_image_node_id = card_node_id.."_image"
	local card_pack_node_id = card_node_id.."_pack"
	local card_cost_node_id = card_node_id.."_cost"
	
	local card_widget = widgets[card_node_id]
	card_widget.content.visible = visible
	local card_name_widget = widgets[card_name_node_id]
	card_name_widget.content.visible = visible
	local card_cost_widget = widgets[card_cost_node_id]
	card_cost_widget.content.visible = visible
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

ui_common.update_card_display = function(scenegraph_nodes, widgets, card_node_id, card, card_width)
	local sizes = calculate_card_sizes(card_width)
	local pretty_margin = sizes.pretty_margin

	set_widgets_visibility(widgets, card_node_id, card)
	if not card then
		return
	end

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

	local card_image_node_id = card_node_id.."_image"
	scenegraph_nodes[card_image_node_id].size[1] = sizes.card_image_width
	scenegraph_nodes[card_image_node_id].size[2] = sizes.card_image_height
	scenegraph_nodes[card_image_node_id].position[2] = pretty_margin*-1 - sizes.card_name_box_height

	local card_details_node_id = card_node_id.."_pack"
	scenegraph_nodes[card_details_node_id].size[1] = sizes.card_pack_width
	scenegraph_nodes[card_details_node_id].size[2] = sizes.card_pack_height

	local card_details_node_id = card_node_id.."_details"
	scenegraph_nodes[card_details_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[card_details_node_id].size[2] = sizes.card_details_height
	scenegraph_nodes[card_details_node_id].position[2] = pretty_margin + sizes.card_pack_height


	local num_description_lines = #card.description_lines
	local num_retain_descriptions = #card.retain_descriptions
	local num_auto_descriptions = #card.auto_descriptions
	local num_condition_descriptions = #card.condition_descriptions
	local any_simple_keywords = card.channel or card.double_agent or card.ephemeral or card.infinite or card.unplayable or card.warp_hungry

	local num_detailed_keywords = math.min(num_retain_descriptions + num_auto_descriptions + num_condition_descriptions, 5)
	local num_rows = num_description_lines + num_detailed_keywords*2 + (any_simple_keywords and 1 or 0)
	local num_row_padding = math.max((num_description_lines > 0 and 1 or 0) + num_detailed_keywords + (any_simple_keywords and 1 or 0) - 1, 0)

	local total_row_vertical_space = scenegraph_nodes[card_details_node_id].size[2] - num_row_padding*pretty_margin
	local row_height = total_row_vertical_space / math.max(num_rows, 1)

	local basic_details_node_id = card_node_id.."_basic_details"
	scenegraph_nodes[basic_details_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[basic_details_node_id].size[2] = row_height * num_description_lines

	if num_description_lines <= 0 then
		scenegraph_nodes[basic_details_node_id].size[2] = 0
	end

	local current_vertical_offset = 0
	if num_row_padding > 0 and num_description_lines > 0 then
		current_vertical_offset = current_vertical_offset - pretty_margin - row_height * num_description_lines
		num_row_padding = num_row_padding - 1
	end

	for i=1,5 do
		local keyword_details_node_id = card_node_id.."_keyword_details_"..i
		scenegraph_nodes[keyword_details_node_id].size[1] = sizes.card_details_width
		scenegraph_nodes[keyword_details_node_id].size[2] = row_height * 2
		scenegraph_nodes[keyword_details_node_id].position[2] = current_vertical_offset
		
		if num_detailed_keywords <= 0 then
			scenegraph_nodes[keyword_details_node_id].size[2] = 0
			num_detailed_keywords = num_detailed_keywords - 1
		end

		if num_row_padding > 0 then
			current_vertical_offset = current_vertical_offset - pretty_margin - row_height * 2
			num_row_padding = num_row_padding - 1
		end
	end

	local additional_keywords_node_id = card_node_id.."_additional_keywords"
	scenegraph_nodes[additional_keywords_node_id].size[1] = sizes.card_details_width
	scenegraph_nodes[additional_keywords_node_id].size[2] = row_height
	scenegraph_nodes[additional_keywords_node_id].position[2] = current_vertical_offset

	if not any_simple_keywords then
		scenegraph_nodes[additional_keywords_node_id].size[2] = 0
	end

	-- Set widget contents/styles
	local card_widget = widgets[card_node_id]
	local card_name_widget = widgets[card_name_node_id]
	local card_cost_widget = widgets[card_cost_node_id]
	local card_image_widget = widgets[card_image_node_id]
	local basic_details_widget = widgets[card_node_id.."_basic_details"]
	local additional_keywords_widget = widgets[card_node_id.."_additional_keywords"]
	local card_pack_widget = widgets[card_node_id.."_pack"]

	card_widget.style.card_background.texture_size[1] = sizes.card_width
	card_widget.style.card_background.texture_size[2] = sizes.card_height
	card_widget.style.card_frame.texture_size[1] = sizes.card_width
	card_widget.style.card_frame.texture_size[2] = sizes.card_height

	card_widget.style.card_background.color = ui_common.card_colors[card.card_type] or ui_common.card_colors.default

	card_name_widget.style.card_name._dynamic_wraped_text = ""
	card_name_widget.style.card_name.font_size = sizes.card_name_font_size
	card_name_widget.style.rarity.texture_size[1] = sizes.card_name_box_width*1.15
	card_name_widget.style.rarity.texture_size[2] = sizes.card_name_box_height
	card_name_widget.style.card_name.area_size[1] = sizes.card_name_box_width
	card_name_widget.style.card_name.area_size[2] = sizes.card_name_box_height
	card_name_widget.content.card_name = card.name

	card_name_widget.style.rarity.color = ui_common.rarity_colors[card.rarity]
	
	card_cost_widget.style.background.texture_size[1] = sizes.card_cost_circle_diameter
	card_cost_widget.style.background.texture_size[2] = sizes.card_cost_circle_diameter
	card_cost_widget.style.cost.font_size = sizes.card_cost_font_size
	card_cost_widget.content.cost = card.cost

	card_image_widget.style.card_image.texture_size[1] = sizes.card_image_width
	card_image_widget.style.card_image.texture_size[2] = sizes.card_image_height
	if card.texture then
		card_image_widget.content.card_image = card.texture
	else
		card_image_widget.content.card_image = "enigma_card_image_placeholder"
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
	else
		basic_details_widget.content.details = ""
	end

	for i=1,5 do
		local widget_name = card_node_id.."_keyword_details_"..i
		local total_vertical_size = scenegraph_nodes[widget_name].size[2]
		local keyword_details_widget = widgets[widget_name]

		local title_style = keyword_details_widget.style.title
		local text_style = keyword_details_widget.style.details

		title_style.area_size[1] = sizes.card_inner_width - pretty_margin*2
		title_style.area_size[2] = total_vertical_size
		title_style.offset[2] = sizes.card_details_font_size*0.5
		title_style._dynamic_wraped_text = ""
		title_style.font_size = sizes.card_details_font_size
		
		text_style.area_size[1] = sizes.card_inner_width - pretty_margin*2
		text_style.area_size[2] = total_vertical_size
		text_style.offset[2] = sizes.card_details_font_size*-0.5
		text_style._dynamic_wraped_text = ""
		text_style.font_size = sizes.card_details_font_size

		local content = keyword_details_widget.content
		content.title = ""
		content.details = ""
	end

	local described_keyword_index = 1
	for _,retain_description_table in ipairs(card.retain_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local widget_name = card_node_id.."_keyword_details_"..described_keyword_index
		local keyword_details_widget = widgets[widget_name]
		local title_style = keyword_details_widget.style.title
		local text_style = keyword_details_widget.style.details
		local content = keyword_details_widget.content

		content.title = enigma:localize("retain")
		content.details = retain_description_table.localized
		
		described_keyword_index = described_keyword_index + 1
	end
	for _,auto_description_table in ipairs(card.auto_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local widget_name = card_node_id.."_keyword_details_"..described_keyword_index
		local keyword_details_widget = widgets[widget_name]
		local title_style = keyword_details_widget.style.title
		local text_style = keyword_details_widget.style.details
		local content = keyword_details_widget.content

		content.title = enigma:localize("auto")
		content.details = auto_description_table.localized
		
		described_keyword_index = described_keyword_index + 1
	end
	for _,condition_description_table in ipairs(card.condition_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local widget_name = card_node_id.."_keyword_details_"..described_keyword_index
		local keyword_details_widget = widgets[widget_name]
		local title_style = keyword_details_widget.style.title
		local text_style = keyword_details_widget.style.details
		local content = keyword_details_widget.content

		content.title = enigma:localize("condition")
		content.details = condition_description_table.localized
		
		described_keyword_index = described_keyword_index + 1
	end

	additional_keywords_widget.style.keywords._dynamic_wraped_text = ""
	additional_keywords_widget.style.keywords.font_size = sizes.card_details_font_size
	if any_simple_keywords then
		local keywords = {}
		if card.channel then
			table.insert(keywords, enigma:localize("channel", card.channel))
		end
		if card.double_agent then
			table.insert(keywords, enigma:localize("double_agent"))
		end
		if card.ephemeral then
			table.insert(keywords, enigma:localize("ephemeral"))
		end
		if card.infinite then
			table.insert(keywords, enigma:localize("infinite"))
		end
		if card.unplayable then
			table.insert(keywords, enigma:localize("unplayable"))
		end
		if card.warp_hungry then
			table.insert(keywords, enigma:localize("warp_hungry", card.warp_hungry))
		end
		additional_keywords_widget.content.keywords = table.concat(keywords, ", ")
	else
		additional_keywords_widget.content.keywords = ""
	end
end

ui_common.update_card_display_if_needed = function(scenegraph_nodes, widgets, card_node_id, card, card_width)
	if not card then
		widgets[card_node_id].cached_card = nil
		widgets[card_node_id].cached_card_width = -1
		return ui_common.update_card_display(scenegraph_nodes, widgets, card_node_id, nil, card_width)
	end
	if card.dirty or card ~= widgets[card_node_id].cached_card or card_width ~= widgets[card_node_id].cached_card_width then
		card.dirty = false
		widgets[card_node_id].cached_card = card
		widgets[card_node_id].cached_card_width = card_width
		return ui_common.update_card_display(scenegraph_nodes, widgets, card_node_id, card, card_width)
	end
end

return ui_common