local enigma = get_mod("Enigma")

local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local info_panel_anchor_horizontal = enigma:get("info_anchor_horizontal")
local info_panel_anchor_vertical = enigma:get("info_anchor_vertical")
local info_panel_offset_horizontal = enigma:get("info_offset_horizontal") * 19.2 -- (divide by 100 because it's a percentage, then scale to 1920)
local info_panel_offset_vertical = enigma:get("info_offset_vertical") * 10.8 -- (divide by 100 because it's a percentage, then scale to 1080)

local info_panel_scale = enigma:get("info_scale")


local hand_panel_anchor_horizontal = enigma:get("hand_anchor_horizontal")
local hand_panel_anchor_vertical = enigma:get("hand_anchor_vertical")
local hand_panel_offset_horizontal = enigma:get("hand_offset_horizontal") * 19.2 -- (divide by 100 because it's a percentage, then scale to 1920)
local hand_panel_offset_vertical = enigma:get("hand_offset_vertical") * 10.8 -- (divide by 100 because it's a percentage, then scale to 1080)

local hand_panel_scale = enigma:get("hand_scale")


local channel_bar_anchor_horizontal = enigma:get("channel_bar_anchor_horizontal")
local channel_bar_anchor_vertical = enigma:get("channel_bar_anchor_vertical")
local channel_bar_offset_horizontal = enigma:get("channel_bar_offset_horizontal") * 19.2 -- (divide by 100 because it's a percentage, then scale to 1920)
local channel_bar_offset_vertical = enigma:get("channel_bar_offset_vertical") * 10.8 -- (divide by 100 because it's a percentage, then scale to 1080)

local channel_bar_scale = enigma:get("channel_bar_scale")


-- Info Panel Sizing
local DEFAULT_INFO_PANEL_WIDTH = 414
local DEFAULT_INFO_PANEL_HEIGHT = 158
local info_panel_width = DEFAULT_INFO_PANEL_WIDTH * info_panel_scale
local info_panel_height = DEFAULT_INFO_PANEL_HEIGHT * info_panel_scale

local PRETTY_MARGIN = 10

local DEFAULT_INFO_COLUMN_WIDTH = 64
local DEFAULT_INFO_COLUMN_HEIGHT = DEFAULT_INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
local DEFAULT_BAR_WIDTH = 12
local DEFAULT_BAR_INNER_PADDING = 2
local DEFAULT_BAR_INNER_WIDTH = DEFAULT_BAR_WIDTH - DEFAULT_BAR_INNER_PADDING*2
local DEFAULT_BAR_INNER_HEIGHT = DEFAULT_INFO_COLUMN_HEIGHT - DEFAULT_BAR_INNER_PADDING*2

-- Hand Panel Sizing
local DEFAULT_HAND_PANEL_WIDTH = 700
local DEFAULT_HAND_PANEL_HEIGHT = 227
local hand_panel_width = DEFAULT_HAND_PANEL_WIDTH * hand_panel_scale
local hand_panel_height = DEFAULT_HAND_PANEL_HEIGHT * hand_panel_scale
local hand_panel_card_margin = PRETTY_MARGIN * hand_panel_scale

local DEFAULT_CARD_WIDTH = 128
local card_width = DEFAULT_CARD_WIDTH * hand_panel_scale

-- Other Element Sizing
local DEFAULT_CHANNEL_BAR_WIDTH = 600
local DEFAULT_CHANNEL_BAR_HEIGHT = 28
local DEFAULT_CHANNEL_BAR_INNER_PADDING = 2
local DEFAULT_CHANNEL_BAR_INNER_WIDTH = DEFAULT_CHANNEL_BAR_WIDTH - DEFAULT_CHANNEL_BAR_INNER_PADDING*2
local DEFAULT_CHANNEL_BAR_INNER_HEIGHT = DEFAULT_CHANNEL_BAR_HEIGHT - DEFAULT_CHANNEL_BAR_INNER_PADDING*2
local DEFAULT_CHANNEL_BAR_FONT_SIZE = 20

local PLAYED_CARD_WIDTH = 240
local PLAYED_CARD_HEIGHT = 388

local set_info_panel_sizes = function(scenegraph, widgets, scale)
	local scaled_column_width = DEFAULT_INFO_COLUMN_WIDTH * scale

	local sg = scenegraph
	sg.info_panel.size[1] = DEFAULT_INFO_PANEL_WIDTH * scale
	sg.info_panel.size[2] = DEFAULT_INFO_PANEL_HEIGHT * scale

	sg.draw_pile_column.size[1] = scaled_column_width
	sg.draw_pile_column.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.draw_pile_column.position[1] = PRETTY_MARGIN * scale

	sg.discard_pile_column.size[1] = scaled_column_width
	sg.discard_pile_column.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.discard_pile_column.position[1] = (PRETTY_MARGIN*2 + DEFAULT_INFO_COLUMN_WIDTH) * scale
	
	sg.warp_dust_bar.size[1] = DEFAULT_BAR_WIDTH * scale
	sg.warp_dust_bar.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.warp_dust_bar.position[1] = (PRETTY_MARGIN*4 + DEFAULT_INFO_COLUMN_WIDTH*3) * scale
	sg.warp_dust_bar_inner.size[1] = DEFAULT_BAR_INNER_WIDTH * scale
	sg.warp_dust_bar_inner.size[2] = DEFAULT_BAR_INNER_HEIGHT * scale
	sg.warp_dust_bar_inner.position[2] = DEFAULT_BAR_INNER_PADDING * scale
	
	sg.warpstone_column.size[1] = scaled_column_width
	sg.warpstone_column.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.warpstone_column.position[1] = (PRETTY_MARGIN*4.5 + DEFAULT_INFO_COLUMN_WIDTH*3 + DEFAULT_BAR_WIDTH) * scale
	
	sg.card_draw_bar.size[1] = DEFAULT_BAR_WIDTH * scale
	sg.card_draw_bar.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.card_draw_bar.position[1] = (PRETTY_MARGIN*5.5 + DEFAULT_INFO_COLUMN_WIDTH*4 + DEFAULT_BAR_WIDTH) * scale
	sg.card_draw_bar_inner.size[1] = DEFAULT_BAR_INNER_WIDTH * scale
	sg.card_draw_bar_inner.size[2] = DEFAULT_BAR_INNER_HEIGHT * scale
	sg.card_draw_bar_inner.position[2] = DEFAULT_BAR_INNER_PADDING * scale
	
	sg.card_draw_column.size[1] = scaled_column_width
	sg.card_draw_column.size[2] = DEFAULT_INFO_COLUMN_HEIGHT * scale
	sg.card_draw_column.position[1] = (PRETTY_MARGIN*6 + DEFAULT_INFO_COLUMN_WIDTH*4 + DEFAULT_BAR_WIDTH*2) * scale

	local w = widgets
	w.draw_pile_column.style.icon.texture_size[1] = scaled_column_width
	w.draw_pile_column.style.icon.texture_size[2] = scaled_column_width
	w.draw_pile_column.style.text.font_size = scaled_column_width
	
	w.discard_pile_column.style.icon.texture_size[1] = scaled_column_width
	w.discard_pile_column.style.icon.texture_size[2] = scaled_column_width
	w.discard_pile_column.style.text.font_size = scaled_column_width
	
	w.warpstone_column.style.icon.texture_size[1] = scaled_column_width
	w.warpstone_column.style.icon.texture_size[2] = scaled_column_width
	w.warpstone_column.style.text.font_size = scaled_column_width
	
	w.card_draw_column.style.icon.texture_size[1] = scaled_column_width
	w.card_draw_column.style.icon.texture_size[2] = scaled_column_width
	w.card_draw_column.style.text.font_size = scaled_column_width
end
local set_channel_bar_sizes = function(scenegraph, widgets, scale)
	local sg = scenegraph
	sg.channel_bar.size[1] = DEFAULT_CHANNEL_BAR_WIDTH * scale
	sg.channel_bar.size[2] = DEFAULT_CHANNEL_BAR_HEIGHT * scale
	sg.channel_bar_inner.size[1] = DEFAULT_CHANNEL_BAR_INNER_WIDTH * scale
	sg.channel_bar_inner.size[2] = DEFAULT_CHANNEL_BAR_INNER_HEIGHT * scale
	sg.channel_bar_inner.position[1] = DEFAULT_CHANNEL_BAR_INNER_PADDING * scale

	local w = widgets
	w.channel_bar.style.text.font_size = DEFAULT_CHANNEL_BAR_FONT_SIZE * scale
end


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
		vertical_alignment = info_panel_anchor_vertical,
		horizontal_alignment = info_panel_anchor_horizontal,
		size = {
			info_panel_width,
			info_panel_height
		},
		position = {
			info_panel_offset_horizontal,
			info_panel_offset_vertical,
			0
		}
	},
	draw_pile_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	discard_pile_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	warp_dust_bar = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	warp_dust_bar_inner = {
		parent = "warp_dust_bar",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	warpstone_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	card_draw_bar = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	card_draw_bar_inner = {
		parent = "card_draw_bar",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	card_draw_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	hand_panel = {
		parent = "screen",
		vertical_alignment = hand_panel_anchor_vertical,
		horizontal_alignment = hand_panel_anchor_horizontal,
		size = {
			hand_panel_width,
			hand_panel_height
		},
		position = {
			hand_panel_offset_horizontal,
			hand_panel_offset_vertical,
			0
		}
	},
	channel_bar = {
		parent = "screen",
		vertical_alignment = channel_bar_anchor_vertical,
		horizontal_alignment = channel_bar_anchor_horizontal,
		size = {
			0,
			0
		},
		position = {
			channel_bar_offset_horizontal,
			channel_bar_offset_vertical,
			1
		}
	},
	channel_bar_inner = {
		parent = "channel_bar",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			0,
			0
		},
		position = {
			0,
			0,
			1
		}
	},
	played_card_container = {
		parent = "channel_bar",
		vertical_alignment = "bottom",
		horizontal_alignment = "right",
		size = {
			PLAYED_CARD_WIDTH,
			PLAYED_CARD_HEIGHT
		},
		position = {
			0,
			PLAYED_CARD_HEIGHT*-1 - PRETTY_MARGIN*2,
			1
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
	draw_pile_column = {
		scenegraph_id = "draw_pile_column",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "icon",
					style_id = "icon"
				},
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				}
			}
		},
		content = {
			icon = "enigma_card_draw_pile",
			text = "0"
		},
		style = {
			icon = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				texture_size = {
					0,
					0
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = 0,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
			},
			default_color = Colors.get_color_table_with_alpha("white", 255),
			error_color = {
				255,
				255,
				0,
				0
			}
		}
	},
	discard_pile_column = {
		scenegraph_id = "discard_pile_column",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "icon",
					style_id = "icon"
				},
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				}
			}
		},
		content = {
			icon = "enigma_card_discard_pile",
			text = "0"
		},
		style = {
			icon = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				texture_size = {
					0,
					0
				}
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = 0,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
			},
		}
	},
	warp_dust_bar = {
		scenegraph_id = "warp_dust_bar",
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
				color = {
					255,
					80,
					80,
					80
				}
			},
		}
	},
	warp_dust_bar_inner = {
		scenegraph_id = "warp_dust_bar_inner",
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
				color = {
					255,
					0,
					255,
					0
				}
			},
		}
	},
	warpstone_column = {
		scenegraph_id = "warpstone_column",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "icon",
					style_id = "icon"
				},
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				}
			}
		},
		content = {
			icon = "enigma_card_warpstone",
			text = "0"
		},
		style = {
			icon = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				texture_size = {
					0,
					0
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = 0,
				font_type = "hell_shark",
				text_color = {
					255,
					0,
					255,
					0
				}
			},
			default_icon_color = Colors.get_color_table_with_alpha("white", 255),
			default_text_color = {
				255,
				0,
				255,
				0
			},
			error_color = {
				255,
				255,
				0,
				0
			}
		}
	},
	card_draw_bar = {
		scenegraph_id = "card_draw_bar",
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
				color = {
					255,
					80,
					80,
					80
				}
			},
		}
	},
	card_draw_bar_inner = {
		scenegraph_id = "card_draw_bar_inner",
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
				color = {
					255,
					255,
					255,
					255
				}
			},
		}
	},
	card_draw_column = {
		scenegraph_id = "card_draw_column",
		element = {
			passes = {
				{
					pass_type = "texture",
					texture_id = "icon",
					style_id = "icon"
				},
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				}
			}
		},
		content = {
			icon = "enigma_card_card_draw",
			text = "0"
		},
		style = {
			icon = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				texture_size = {
					0,
					0
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = 0,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
			},
			default_color = Colors.get_color_table_with_alpha("white", 255),
			error_color = {
				255,
				255,
				0,
				0
			}
		}
	},
	hand_panel = {
		scenegraph_id = "hand_panel",
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
					80,
					0,
					0,
					0
				}
			},
			default_color = {
				80,
				0,
				0,
				0
			},
			error_color = {
				160,
				255,
				0,
				0
			}
		}
	},
	channel_bar = {
		scenegraph_id = "channel_bar",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "text",
					style_id = "text",
					text_id = "text"
				}
			}
		},
		content = {
			text = "channeling",
			visible = false
		},
		style = {
			background = {
				color = {
					255,
					0,
					0,
					0
				}
			},
			text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 20,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
				offset = {
					0,
					0,
					5
				}
			}
		}
	},
	channel_bar_inner = {
		scenegraph_id = "channel_bar_inner",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				}
			}
		},
		content = {
			visible = false
		},
		style = {
			background = {
				color = {
					255,
					0,
					0,
					220
				},
				color_progress = {
					255,
					0,
					0,
					220
				},
				color_success = {
					255,
					0,
					220,
					0
				},
				color_failure = {
					255,
					220,
					0,
					0
				}
			}
		}
	},
}

set_info_panel_sizes(scenegraph_definition, widgets, info_panel_scale)
set_channel_bar_sizes(scenegraph_definition, widgets, channel_bar_scale)

card_ui_common.add_hand_display(scenegraph_definition, widgets, "hand_panel", card_width)
card_ui_common.add_card_display(scenegraph_definition, widgets, "played_card_container", "played_card", PLAYED_CARD_WIDTH)

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,

	set_info_panel_sizes = set_info_panel_sizes,
	set_channel_bar_sizes = set_channel_bar_sizes,

	default_hand_panel_width = DEFAULT_HAND_PANEL_WIDTH,
	default_hand_panel_height = DEFAULT_HAND_PANEL_HEIGHT,
	default_card_width = DEFAULT_CARD_WIDTH,
	card_width = card_width,
	played_card_width = PLAYED_CARD_WIDTH,
	default_channel_bar_inner_width = DEFAULT_CHANNEL_BAR_INNER_WIDTH,
	channel_bar_inner_width = DEFAULT_CHANNEL_BAR_INNER_WIDTH * channel_bar_scale,
	default_hand_card_margin = PRETTY_MARGIN,
	hand_card_margin = hand_panel_card_margin
}
