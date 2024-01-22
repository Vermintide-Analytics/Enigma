local enigma = get_mod("Enigma")
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local NUM_CARDS_TO_CHOOSE_BETWEEN = enigma.managers.deus.num_cards_to_choose_between

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
			UILayer.hud+110
		}
	},
	additional_resources_note = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "right",
		size = {
			300,
			100
		},
		position = {
			-320,
			0,
			1
		}
	},
	toggle_view_button = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			470,
			100
		},
		position = {
			0,
			-50,
			1
		}
	},
	additional_resources_label_panel = {
		parent = "screen",
		vertical_alignment = "top",
		horizontal_alignment = "center",
		size = {
			1920,
			50
		},
		position = {
			0,
			-175,
			1
		}
	},
	cards_panel = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			1920,
			630
		},
		position = {
			0,
			-25,
			1
		}
	},
	skip_button = {
		parent = "screen",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			260,
			100
		},
		position = {
			0,
			50,
			1
		}
	},
}

local widgets = {
	background = {
		scenegraph_id = "screen",
		element = {
			passes = {
				{
					pass_type = "hotspot",
					scenegraph_id = "screen",
					content_id = "screen_hotspot"
				},
				{
					pass_type = "rect",
					style_id = "fullscreen_shade"
				},
			}
		},
		content = {
			screen_hotspot = {}
		},
		style = {
			fullscreen_shade = {
				color = {
					150,
					0,
					0,
					0
				}
			},
		}
	},
	additional_resources_note = {
		scenegraph_id = "additional_resources_note",
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				},
			}
		},
		content = {
			text = enigma:localize("added_card_draw_warpstone_note"),
		},
		style = {
			background = {
				color = {
					120,
					120,
					120,
					120
				}
			},
			text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 18,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					0
				},
				offset = {
					0,
					0,
					1
				}
			},
		}
	},
	waiting_for_other_players_notice = {
		scenegraph_id = "toggle_view_button",
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "text",
					style_id = "text"
				},
			}
		},
		content = {
			text = enigma:localize("waiting_for_other_players_to_choose_cards"),
		},
		style = {
			text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 24,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					0,
					0,
					1
				}
			},
		}
	},
	toggle_view_button = UIWidgets.create_default_button("toggle_view_button", scenegraph_definition.toggle_view_button.size, nil, nil, enigma:localize("hide_card_selection"), 34, nil, nil, nil, true, true),
	skip_button = UIWidgets.create_default_button("skip_button", scenegraph_definition.skip_button.size, nil, nil, enigma:localize("skip"), 34, nil, nil, nil, true, true),
}

local MAX_CARD_WIDTH = scenegraph_definition.cards_panel.size[2] / 1.618
local SCREEN_HORIZONTAL_SPACE = 1920
local DESIRED_CARD_SPACE = SCREEN_HORIZONTAL_SPACE * 0.8
local DESIRED_CARD_WIDTH = DESIRED_CARD_SPACE / NUM_CARDS_TO_CHOOSE_BETWEEN
local ACTUAL_CARD_WIDTH = math.min(DESIRED_CARD_WIDTH, MAX_CARD_WIDTH)
local ACTUAL_CARD_SPACE = ACTUAL_CARD_WIDTH * NUM_CARDS_TO_CHOOSE_BETWEEN

local CARD_INBETWEEN_SPACE = SCREEN_HORIZONTAL_SPACE - ACTUAL_CARD_SPACE
local CARD_INBETWEENS = NUM_CARDS_TO_CHOOSE_BETWEEN + 1
local CARD_INBETWEEN_WIDTH = CARD_INBETWEEN_SPACE / CARD_INBETWEENS

local horizontal_offset = 0
for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
	horizontal_offset = horizontal_offset + CARD_INBETWEEN_WIDTH

	local card_container_node_id = "card_"..i.."_container"
	scenegraph_definition[card_container_node_id] = {
		parent = "cards_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			ACTUAL_CARD_WIDTH,
			scenegraph_definition.cards_panel.size[2]
		},
		position = {
			horizontal_offset,
			0,
			1
		}
	}
	card_ui_common.add_card_display(scenegraph_definition, widgets, card_container_node_id, "card_"..i, ACTUAL_CARD_WIDTH, true)

	local additional_resources_label_node_id = "additional_resources_label_"..i
	scenegraph_definition[additional_resources_label_node_id] = {
		parent = "additional_resources_label_panel",
		vertical_alignment = "center",
		horizontal_alignment = "left",
		size = {
			ACTUAL_CARD_WIDTH,
			scenegraph_definition.cards_panel.size[2]
		},
		position = {
			horizontal_offset,
			0,
			1
		}
	}
	widgets[additional_resources_label_node_id] = {
		scenegraph_id = additional_resources_label_node_id,
		element = {
			passes = {
				{
					pass_type = "text",
					text_id = "plus_card_draw_text",
					style_id = "plus_card_draw_text"
				},
				{
					pass_type = "texture",
					texture_id = "plus_card_draw_texture",
					style_id = "plus_card_draw_texture"
				},
				{
					pass_type = "text",
					text_id = "plus_warpstone_text",
					style_id = "plus_warpstone_text"
				},
				{
					pass_type = "texture",
					texture_id = "plus_warpstone_texture",
					style_id = "plus_warpstone_texture"
				},
			}
		},
		content = {
			plus_card_draw_text = "+1",
			plus_warpstone_text = "+1",

			plus_card_draw_texture = "enigma_card_card_draw",
			plus_warpstone_texture = "enigma_card_warpstone",

		},
		style = {
			plus_card_draw_text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 28,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					-75,
					0,
					1
				}
			},
			plus_card_draw_texture = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				texture_size = {
					50,
					50
				},
				offset = {
					-25,
					0,
					1
				}
			},
			plus_warpstone_text = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				font_size = 28,
				word_wrap = true,
				font_type = "hell_shark",
				text_color = {
					255,
					255,
					255,
					255
				},
				offset = {
					25,
					0,
					1
				}
			},
			plus_warpstone_texture = {
				vertical_alignment = "center",
				horizontal_alignment = "center",
				texture_size = {
					50,
					50
				},
				offset = {
					75,
					0,
					1
				}
			},
		}
	}

	horizontal_offset = horizontal_offset + ACTUAL_CARD_WIDTH
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = ACTUAL_CARD_WIDTH,
	num_cards_to_choose_between = NUM_CARDS_TO_CHOOSE_BETWEEN,
}
