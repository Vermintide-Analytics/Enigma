local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

-- Info Panel Sizing
local INFO_PANEL_WIDTH = 414
local INFO_PANEL_HEIGHT = 158

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
	draw_pile_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			COLUMN_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN,
			0,
			1
		}
	},
	discard_pile_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			COLUMN_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*2 + COLUMN_WIDTH,
			0,
			1
		}
	},
	warp_dust_bar = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			BAR_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*4 + COLUMN_WIDTH*3,
			0,
			1
		}
	},
	warp_dust_bar_inner = {
		parent = "warp_dust_bar",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			BAR_WIDTH - 4,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2 - 4
		},
		position = {
			0,
			2,
			1
		}
	},
	warpstone_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			COLUMN_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*4.5 + COLUMN_WIDTH*3 + BAR_WIDTH,
			0,
			1
		}
	},
	card_draw_bar = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			BAR_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*5.5 + COLUMN_WIDTH*4 + BAR_WIDTH,
			0,
			1
		}
	},
	card_draw_bar_inner = {
		parent = "card_draw_bar",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			BAR_WIDTH - 4,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2 - 4
		},
		position = {
			0,
			2,
			1
		}
	},
	card_draw_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			COLUMN_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*6 + COLUMN_WIDTH*4 + BAR_WIDTH*2,
			0,
			1
		}
	},
	hand_panel = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = {
			700,
			227
		},
		position = {
			0,
			0,
			0
		}
	},
	channel_bar = {
		parent = "hand_panel",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			CHANNEL_BAR_WIDTH,
			CHANNEL_BAR_HEIGHT
		},
		position = {
			0,
			CHANNEL_BAR_HEIGHT*-1 - PRETTY_MARGIN,
			1
		}
	},
	channel_bar_inner = {
		parent = "channel_bar",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			CHANNEL_BAR_WIDTH - 8,
			CHANNEL_BAR_HEIGHT - 8
		},
		position = {
			4,
			0,
			1
		}
	}
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
					COLUMN_WIDTH,
					COLUMN_WIDTH
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = COLUMN_WIDTH,
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
					COLUMN_WIDTH,
					COLUMN_WIDTH
				}
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = COLUMN_WIDTH,
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
					COLUMN_WIDTH,
					COLUMN_WIDTH
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = COLUMN_WIDTH,
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
					COLUMN_WIDTH,
					COLUMN_WIDTH
				},
				color = Colors.get_color_table_with_alpha("white", 255),
			},
			text = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				font_size = COLUMN_WIDTH,
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

card_ui_common.add_hand_display(scenegraph_definition, widgets, "hand_panel", CARD_WIDTH)

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = CARD_WIDTH,
	channel_bar_inner_width = CHANNEL_BAR_WIDTH - 8
}
