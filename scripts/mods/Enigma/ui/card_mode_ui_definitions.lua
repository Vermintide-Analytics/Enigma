local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local CARD_WIDTH = 300

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
	hand_panel = {
		parent = "screen",
		vertical_alignment = "bottom",
		horizontal_alignment = "center",
		size = {
			1536,
			486
		},
		position = {
			0,
			128,
			1
		}
	}
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
	}
}

card_ui_common.add_hand_display(scenegraph_definition, widgets, "hand_panel", CARD_WIDTH, true)

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = CARD_WIDTH
}
