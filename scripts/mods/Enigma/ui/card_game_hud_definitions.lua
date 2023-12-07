local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

-- Info Panel Sizing
local INFO_PANEL_WIDTH = 414
local INFO_PANEL_HEIGHT = 158

local COLUMN_WIDTH = 64
local BAR_WIDTH = 12
local FONT_SIZE = 64
local PRETTY_MARGIN = 10

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
	out_of_play_column = {
		parent = "info_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			COLUMN_WIDTH,
			INFO_PANEL_HEIGHT - PRETTY_MARGIN*2
		},
		position = {
			PRETTY_MARGIN*3 + COLUMN_WIDTH*2,
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
	out_of_play_column = {
		scenegraph_id = "out_of_play_column",
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
			icon = "enigma_card_x",
			text = "0"
		},
		style = {
			icon = {
				vertical_alignment = "bottom",
				horizontal_alignment = "center",
				texture_size = {
					COLUMN_WIDTH-8,
					COLUMN_WIDTH-8
				},
				offset = {
					0,
					4,
					0
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
			icon = {
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
			icon = {
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
				}
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
			icon = {
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
			icon = {
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
		}
	}
}

for i=1,5 do
	ui_common.add_card_display(scenegraph_definition, widgets, "hand_panel", "card_"..i, CARD_WIDTH)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = CARD_WIDTH
}
