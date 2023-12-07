local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")

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
			screen_hotspot = {}
		},
		style = {
			background = {
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

for i=1,5 do
	ui_common.add_card_display(scenegraph_definition, widgets, "hand_panel", "card_"..i, CARD_WIDTH)
end

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
	card_width = CARD_WIDTH
}
