local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

local CARD_WIDTH = 512
local RELATED_CARD_WIDTH = 280

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
			UILayer.chat+10
		}
	},
	big_card = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			CARD_WIDTH,
			1080
		},
		position = {
			0,
			0,
			1
		}
	},
	related_card_1_container = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			RELATED_CARD_WIDTH,
			1080
		},
		position = {
			475,
			-277,
			1
		}
	},
	related_card_2_container = {
		parent = "screen",
		vertical_alignment = "center",
		horizontal_alignment = "center",
		size = {
			RELATED_CARD_WIDTH,
			1080
		},
		position = {
			475,
			277,
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
					180,
					0,
					0,
					0
				}
			},
		}
	}
}

card_ui_common.add_card_display(scenegraph_definition, widgets, "big_card", "card", CARD_WIDTH)
card_ui_common.add_card_display(scenegraph_definition, widgets, "related_card_1_container", "related_card_1", RELATED_CARD_WIDTH, true)
card_ui_common.add_card_display(scenegraph_definition, widgets, "related_card_2_container", "related_card_2", RELATED_CARD_WIDTH, true)

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	big_card_width = CARD_WIDTH,
	related_card_width = RELATED_CARD_WIDTH
}
