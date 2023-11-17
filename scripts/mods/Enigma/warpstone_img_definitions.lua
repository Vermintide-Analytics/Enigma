local scenegraph_definition = {
	fullscreen_warpstone_display = {
		scale = "fit",
		size = {
			1920,
			1080
		},
		position = {
			0,
			0,
			UILayer.hud
		}
	}
}
local widgets = {
	fullscreen_warpstone_display = {
		scenegraph_id = "fullscreen_warpstone_display",
		element = {
			passes = {
				{
					texture_id = "warpstone_texture",
					style_id = "warpstone_texture",
					pass_type = "rotated_texture"
				},
				{
					pass_type = "text",
					style_id = "test_text",
					text_id = "test_text"
				}
			}
		},
		content = {
			warpstone_texture = "enigma_test_material",
			test_text = "test text"
		},
		style = {
			warpstone_texture = {
				angle = math.degrees_to_radians(0),
				pivot = {
					0,
					0
				},
				pixel_perfect = true,
				horizontal_alignment = "center",
				vertical_alignment = "center",
				offset = {
					0,
					0,
					0
				},
				size = {
					500,
					500
				}
			},
			test_text = {
				parent = "warpstone_texture",
				horizontal_alignment = "center",
				vertical_alignment = "center",
				font_size = 50,
				localize = false,
				word_wrap = false,
				font_type = "hell_shark",
				text_color = {
					255,
					0, -- R
					255,
					255
				},
				offset = {
					0,
					0,
					0
				}
			}
		}
	}
}

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets
}
