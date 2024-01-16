local enigma = get_mod("Enigma")

local ui_common = {}

ui_common.create_text_input = function(scenegraph_id, text_scenegraph_id, unfocus_scenegraph_id, default_text, hint_text)
	local widget = {
		scenegraph_id = scenegraph_id,
		element = {
			passes = {
				{
					pass_type = "rect",
					style_id = "background"
				},
				{
					pass_type = "rect",
					style_id = "inner_background"
				},
				{
					pass_type = "hotspot",
					content_id = "hotspot"
				},
				{
					pass_type = "hotspot",
					scenegraph_id = unfocus_scenegraph_id,
					content_id = "unfocus_hotspot"
				},
				{
					pass_type = "text",
					style_id = "text",
					text_id = "text",
					content_check_function = function(content, style)
						if not content.input_active then
							style.caret_color[1] = 0
						else
							style.caret_color[1] = 128 + math.sin(Managers.time:time("ui") * 5) * 128
						end
						return true
					end
				}
			}
		},
		content = {
			hotspot = {},
			unfocus_hotspot = {},
			text_start_offset = 0,
			text_index = 1,
			input_active = false,
			text = default_text or "",
			caret_index = 1
		},
		style = {
			background = {
				color = {
					255,
					128,
					128,
					128
				},
			},
			inner_background = {
				color = {
					255,
					0,
					0,
					0
				},
			},
			text = {
				scenegraph_id = text_scenegraph_id,
				horizontal_scroll = true,
				word_wrap = false,
				pixel_perfect = true,
				horizontal_alignment = "left",
				vertical_alignment = "center",
				font_size = 32,
				dynamic_font = true,
				font_type = "hell_shark_arial",
				text_color = Colors.get_table("white"),
				offset = {
					2,
					2,
					1
				},
				caret_size = {
					2,
					30
				},
				caret_offset = {
					0,
					-4,
					4
				},
				caret_color = Colors.get_table("white")
			}
		}
	}

	if hint_text then
		table.insert(widget.element.passes, {
			pass_type = "text",
			style_id = "hint",
			text_id = "hint",
			content_check_function = function (content, style)
				if content.hotspot.is_hover then
					style.text_color = {
						128,
						255,
						255,
						255
					}
				else
					style.text_color = {
						60,
						255,
						255,
						255
					}
				end

				return content.text == ""
			end
		})
		widget.content.hint = hint_text
		widget.style.hint = {
			scenegraph_id = text_scenegraph_id,
			horizontal_scroll = true,
			word_wrap = false,
			pixel_perfect = true,
			horizontal_alignment = "left",
			vertical_alignment = "center",
			font_size = 32,
			dynamic_font = true,
			font_type = "hell_shark_arial",
			text_color = {
				60,
				255,
				255,
				255
			},
			offset = {
				2,
				2,
				1
			},
		}
	end

	return widget
end

ui_common.handle_text_input = function(widget)
	local content = widget.content
	if UIUtils.is_button_pressed(widget) then
		content.input_active = true
		enigma.managers.ui:text_input_focused()
	elseif UIUtils.is_button_pressed(widget, "unfocus_hotspot") then
		content.input_active = false
		enigma.managers.ui:text_input_lost_focus()
	end

	local keystrokes = Keyboard.keystrokes()
	for _, stroke in ipairs(keystrokes) do
		if stroke == Keyboard.ENTER or stroke == Keyboard.ESCAPE then
			content.input_active = false
			enigma.managers.ui:text_input_lost_focus()
		end
	end

	if content.input_active then
		local previous_text = content.text
		content.text, content.caret_index = KeystrokeHelper.parse_strokes(content.text, content.caret_index, "insert", keystrokes)
		if content.text ~= previous_text then
			return content.text
		end
	end
	return false
end

ui_common.handle_text_inputs = function(text_input_widgets)
	local any_pressed = false
	local unfocus_pressed = false
	for _,widget in ipairs(text_input_widgets) do
		local pressed = UIUtils.is_button_pressed(widget)
		if pressed then
			any_pressed = widget
		elseif UIUtils.is_button_pressed(widget, "unfocus_hotspot") then
			unfocus_pressed = true
		end
	end
	if any_pressed then
		for _,widget in ipairs(text_input_widgets) do
			local active = widget == any_pressed
			widget.content.input_active = active
		end
		enigma.managers.ui:text_input_focused()
	elseif unfocus_pressed then
		for _,widget in ipairs(text_input_widgets) do
			widget.content.input_active = false
		end
		enigma.managers.ui:text_input_lost_focus()
	end

	local keystrokes = Keyboard.keystrokes()
	for _,widget in ipairs(text_input_widgets) do
		if widget.content.input_active then
			for _, stroke in ipairs(keystrokes) do
				if stroke == Keyboard.ENTER or stroke == Keyboard.ESCAPE then
					widget.content.input_active = false
					enigma.managers.ui:text_input_lost_focus()
				end
			end
		end
	end
	
	local changes = nil
	for _,widget in ipairs(text_input_widgets) do
		local content = widget.content
		if content.input_active then
			local previous_text = content.text
			content.text, content.caret_index = KeystrokeHelper.parse_strokes(content.text, content.caret_index, "insert", keystrokes)
			if content.text ~= previous_text then
				changes = changes or {}
				changes[widget] = content.text
			end
		end
	end
	return changes
end

ui_common.create_checkbox_widget = function (text, tooltip_text, scenegraph_id, checkbox_offset, optional_text_offset, optional_tooltip_text_disabled)
	local frame_settings = UIFrameSettings.menu_frame_06

	return {
		element = {
			passes = {
				{
					pass_type = "hotspot",
					content_id = "button_hotspot"
				},
				{
					style_id = "tooltip_text",
					pass_type = "tooltip_text",
					text_id = "tooltip_text",
					content_check_function = function (ui_content)
						return ui_content.button_hotspot.is_hover and ui_content.tooltip_text ~= "" and not ui_content.is_disabled
					end
				},
				{
					style_id = "tooltip_text",
					pass_type = "tooltip_text",
					text_id = "tooltip_text_disabled",
					content_check_function = function (ui_content)
						return ui_content.button_hotspot.is_hover and ui_content.tooltip_text_disabled ~= "" and ui_content.is_disabled
					end
				},
				{
					style_id = "setting_text",
					pass_type = "text",
					text_id = "setting_text",
					content_check_function = function (content)
						return not content.button_hotspot.is_hover and not content.is_disabled
					end
				},
				{
					style_id = "setting_text_disabled",
					pass_type = "text",
					text_id = "setting_text",
					content_check_function = function (content)
						return content.is_disabled
					end
				},
				{
					style_id = "setting_text_hover",
					pass_type = "text",
					text_id = "setting_text",
					content_check_function = function (content)
						return content.button_hotspot.is_hover and not content.is_disabled
					end
				},
				{
					pass_type = "texture",
					style_id = "checkbox_marker",
					texture_id = "checkbox_marker",
					content_check_function = function (content)
						return content.checked and not content.is_disabled
					end
				},
				{
					pass_type = "texture",
					style_id = "checkbox_marker_disabled",
					texture_id = "checkbox_marker",
					content_check_function = function (content)
						return content.checked and content.is_disabled
					end
				},
				{
					pass_type = "rect",
					style_id = "checkbox_background"
				},
				{
					pass_type = "texture_frame",
					style_id = "checkbox_frame",
					texture_id = "checkbox_frame",
					content_check_function = function (content)
						return not content.is_disabled
					end
				},
				{
					pass_type = "texture_frame",
					style_id = "checkbox_frame_disabled",
					texture_id = "checkbox_frame",
					content_check_function = function (content)
						return content.is_disabled
					end
				}
			}
		},
		content = {
			checked = false,
			checkbox_marker = "matchmaking_checkbox",
			button_hotspot = {},
			tooltip_text = tooltip_text,
			setting_text = text,
			tooltip_text_disabled = optional_tooltip_text_disabled or "",
			checkbox_frame = frame_settings.texture
		},
		style = {
			checkbox_style = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				texture_size = {
					40,
					40
				},
				offset = {
					checkbox_offset,
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
			checkbox_style_disabled = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				texture_size = {
					40,
					40
				},
				offset = {
					checkbox_offset,
					0,
					1
				},
				color = {
					96,
					255,
					255,
					255
				}
			},
			checkbox_background = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				texture_size = {
					40,
					40
				},
				offset = {
					checkbox_offset,
					0,
					0
				},
				color = {
					255,
					0,
					0,
					0
				}
			},
			checkbox_frame = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				area_size = {
					40,
					40
				},
				texture_size = frame_settings.texture_size,
				texture_sizes = frame_settings.texture_sizes,
				offset = {
					checkbox_offset,
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
			checkbox_frame_disabled = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				area_size = {
					40,
					40
				},
				texture_size = frame_settings.texture_size,
				texture_sizes = frame_settings.texture_sizes,
				offset = {
					checkbox_offset,
					0,
					1
				},
				color = {
					96,
					255,
					255,
					255
				}
			},
			checkbox_marker = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				texture_size = {
					37,
					31
				},
				offset = {
					checkbox_offset + 4,
					6,
					1
				},
				color = Colors.get_color_table_with_alpha("font_title", 255)
			},
			checkbox_marker_disabled = {
				vertical_alignment = "bottom",
				horizontal_alignment = "right",
				texture_size = {
					37,
					31
				},
				offset = {
					checkbox_offset + 4,
					6,
					1
				},
				color = Colors.get_color_table_with_alpha("white", 96)
			},
			setting_text = {
				vertical_alignment = "center",
				upper_case = true,
				horizontal_alignment = "right",
				font_size = 24,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("font_title", 255),
				offset = optional_text_offset or {
					-50,
					0,
					4
				}
			},
			setting_text_disabled = {
				vertical_alignment = "center",
				upper_case = true,
				horizontal_alignment = "right",
				font_size = 24,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 96),
				offset = optional_text_offset or {
					-50,
					0,
					4
				}
			},
			setting_text_hover = {
				vertical_alignment = "center",
				upper_case = true,
				horizontal_alignment = "right",
				font_size = 24,
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("font_default", 255),
				offset = optional_text_offset or {
					-50,
					0,
					4
				}
			},
			tooltip_text = {
				font_size = 24,
				max_width = 500,
				cursor_side = "left",
				horizontal_alignment = "left",
				vertical_alignment = "top",
				font_type = "hell_shark",
				text_color = Colors.get_color_table_with_alpha("white", 255),
				line_colors = {},
				offset = {
					0,
					0,
					50
				},
				cursor_offset = {
					-10,
					-27
				}
			}
		},
		scenegraph_id = scenegraph_id
	}
end

local FILTER_COLOR_DEFAULT = {
	255,
	32,
	32,
	32
}
local FILTER_COLOR_SELECTED = {
	255,
	139,
	69,
	19
}

ui_common.create_search_filters_widget = function(scenegraph_definition, scenegraph_id, ui_renderer, search_definitions)
	local sg_size = scenegraph_definition[scenegraph_id].size
	local size = {
		sg_size[1],
		100
	}
	local frame_settings = UIFrameSettings.button_frame_01
	local widget = {
		scenegraph_id = scenegraph_id,
		offset = {
			0,
			0,
			0
		},
		element = {
			passes = {
				{
					texture_id = "bg",
					style_id = "bg",
					pass_type = "texture"
				},
				{
					scenegraph_id = "gamepad_background",
					style_id = "gamepad_background",
					pass_type = "rect",
					content_check_function = function (content, style)
						local gamepad_active = Managers.input:is_device_active("gamepad")

						return gamepad_active
					end
				},
				{
					pass_type = "hotspot",
					content_id = "panel_hotspot",
				},
				{
					texture_id = "frame",
					style_id = "frame",
					pass_type = "texture_frame"
				},
				{
					style_id = "title_text",
					pass_type = "text",
					text_id = "title_text"
				},
				{
					texture_id = "divider_top",
					style_id = "divider_top",
					pass_type = "texture"
				},
				{
					texture_id = "divider_left",
					style_id = "divider_left",
					pass_type = "rotated_texture"
				},
				{
					style_id = "reset_filter_hotspot",
					pass_type = "hotspot",
					content_id = "reset_filter_hotspot",
					content_change_function = function (hotspot, style)
						if hotspot.on_pressed then
							local content = hotspot.parent
							local query = content.query

							if not table.is_empty(query) then
								table.clear(query)

								content.query_dirty = true
							end
						end

						style.parent.reset_filter_fg.color[1] = hotspot.is_hover and 255 or 0
					end
				},
				{
					texture_id = "reset_filter_bg",
					style_id = "reset_filter_bg",
					pass_type = "texture",
					content_check_function = function (content, style)
						return not Managers.input:is_device_active("gamepad")
					end
				},
				{
					texture_id = "reset_filter_fg",
					style_id = "reset_filter_fg",
					pass_type = "texture",
					content_check_function = function (content, style)
						return not Managers.input:is_device_active("gamepad")
					end
				},
				{
					pass_type = "hover",
					style_id = "hover"
				}
			}
		},
		content = {
			divider_left = "divider_01_bottom",
			title_text = "filters",
			bg = "button_bg_01",
			panel_hotspot = {},
			reset_filter_bg = "achievement_refresh_off",
			reset_filter_fg = "achievement_refresh_on",
			divider_top = "divider_01_top",
			visible = true,
			query_dirty = false,
			frame = frame_settings.texture,
			reset_filter_hotspot = {},
			query = {},
			gamepad_button_index = {
				1,
				1
			}
		},
		style = {
			hover = {
				vertical_alignment = "top",
				offset = {
					0,
					0,
					0
				},
				area_size = size
			},
			bg = {
				vertical_alignment = "top",
				offset = {
					0,
					0,
					1
				},
				color = {
					255,
					64,
					64,
					64
				},
				texture_size = size
			},
			gamepad_background = {
				offset = {
					0,
					0,
					-1
				},
				color = {
					128,
					0,
					0,
					0
				}
			},
			frame = {
				vertical_alignment = "top",
				texture_size = frame_settings.texture_size,
				texture_sizes = frame_settings.texture_sizes,
				area_size = size,
				offset = {
					0,
					0,
					2
				},
				color = {
					255,
					255,
					255,
					255
				}
			},
			title_text = {
				vertical_alignment = "top",
				upper_case = true,
				localize = true,
				horizontal_alignment = "center",
				font_size = 40,
				font_type = "hell_shark_header",
				text_color = Colors.get_table("font_title"),
				offset = {
					0,
					-10,
					3
				}
			},
			divider_top = {
				vertical_alignment = "top",
				horizontal_alignment = "center",
				texture_size = {
					264,
					32
				},
				offset = {
					0,
					-50,
					3
				}
			},
			divider_left = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = {
					0,
					21
				},
				offset = {
					170,
					-60,
					3
				},
				angle = math.pi * 0.5,
				pivot = {
					0,
					0
				}
			},
			reset_filter_hotspot = {
				vertical_alignment = "top",
				horizontal_alignment = "right",
				area_size = {
					37.5,
					37.5
				},
				offset = {
					-15,
					-15,
					3
				}
			},
			reset_filter_bg = {
				vertical_alignment = "top",
				horizontal_alignment = "right",
				texture_size = {
					37.5,
					37.5
				},
				offset = {
					-15,
					-15,
					4
				},
				color = {
					255,
					255,
					255,
					255
				}
			},
			reset_filter_fg = {
				vertical_alignment = "top",
				horizontal_alignment = "right",
				texture_size = {
					37.5,
					37.5
				},
				offset = {
					-15,
					-15,
					5
				},
				color = {
					0,
					255,
					255,
					255
				}
			}
		}
	}
	local FONT_SIZE = 20
	local CONTAINER_PADDING = 25
	local LINE_HEIGHT = FONT_SIZE + 15
	local LINE_MARGIN = 10
	local font = Fonts.hell_shark
	local size_of_font = math.max(FONT_SIZE * RESOLUTION_LOOKUP.scale, 1)
	local font_material = font[1]
	local font_size = font[2]
	local font_name = font[3]
	local divider_left_size = widget.style.divider_left.texture_size
	local y_position = -80

	for i = 1, #search_definitions do
		local search_definition = search_definitions[i]
		local search_key = search_definition.key
		local header_pass_name = search_key .. "_header"

		table.insert(widget.element.passes, {
			pass_type = "text",
			text_id = header_pass_name,
			style_id = header_pass_name
		})

		widget.content[header_pass_name] = search_key
		widget.style[header_pass_name] = {
			vertical_alignment = "top",
			upper_case = true,
			horizontal_alignment = "left",
			font_type = "hell_shark",
			font_size = FONT_SIZE,
			text_color = Colors.get_table("font_button_normal"),
			offset = {
				CONTAINER_PADDING,
				-10 + y_position,
				3
			}
		}
		local BASE_X_POSITION = 200
		local x_position = BASE_X_POSITION

		for j = 1, #search_definition do
			local tuple = search_definition[j]
			local search_value = tuple[1]
			local search_kword = tuple[2]
			local text = string.match(search_kword, "^[^,]+")
			local text_width = 10 + UIRenderer.text_size(ui_renderer, text, font_material, size_of_font, font_name)

			if x_position + text_width >= size[1] - CONTAINER_PADDING then
				x_position = BASE_X_POSITION
				y_position = y_position - LINE_HEIGHT
				divider_left_size[1] = divider_left_size[1] + LINE_HEIGHT
				size[2] = size[2] + LINE_HEIGHT
			end

			local pass_hotspot = header_pass_name .. "_hotspot_" .. search_kword

			table.insert(widget.element.passes, {
				pass_type = "hotspot",
				content_id = pass_hotspot,
				style_id = pass_hotspot
			})

			widget.content[pass_hotspot] = {}
			widget.style[pass_hotspot] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				area_size = {
					text_width,
					30
				},
				offset = {
					x_position,
					-5 + y_position,
					3
				}
			}
			local pass_rect = header_pass_name .. "_rect_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "rect",
				style_id = pass_rect,
				content_change_function = function (content, style)
					local hotspot = content[pass_hotspot]
					local is_selected = search_value == content.query[search_key]
					local wanted_color = is_selected and FILTER_COLOR_SELECTED or FILTER_COLOR_DEFAULT

					Colors.copy_to(style.color, wanted_color)

					style.color[1] = hotspot.is_hover and 255 or 175

					if hotspot.on_pressed then
						if is_selected then
							content.query[search_key] = nil
						else
							content.query[search_key] = search_value
						end

						content.query_dirty = true
					end
				end
			})

			widget.style[pass_rect] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = {
					text_width,
					30
				},
				color = {
					255,
					64,
					64,
					64
				},
				offset = {
					x_position,
					-7 + y_position,
					4
				}
			}
			local frame_settings = UIFrameSettings.frame_outer_glow_01_white
			local frame_width = frame_settings.texture_sizes.corner[1]
			local pass_texture_frame = header_pass_name .. "_texture_frame_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "texture_frame",
				texture_id = pass_texture_frame .. "_id",
				style_id = pass_texture_frame,
				content_check_function = function (content, style)
					local gamepad_active = Managers.input:is_device_active("gamepad")

					return gamepad_active and content.gamepad_button_index[1] == j and content.gamepad_button_index[2] == i
				end
			})

			widget.content[pass_texture_frame .. "_id"] = frame_settings.texture
			widget.style[pass_texture_frame] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = frame_settings.texture_size,
				texture_sizes = frame_settings.texture_sizes,
				color = Colors.get_table("font_title"),
				offset = {
					x_position - frame_width,
					y_position + frame_width - 7,
					5
				},
				area_size = {
					text_width + frame_width * 2,
					30 + frame_width * 2
				}
			}
			local pass_fade = header_pass_name .. "_fade1_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "texture",
				texture_id = pass_fade,
				style_id = pass_fade
			})

			widget.content[pass_fade] = "button_state_default"
			widget.style[pass_fade] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = {
					text_width,
					30
				},
				color = {
					100,
					255,
					255,
					255
				},
				offset = {
					x_position,
					-7 + y_position,
					5
				}
			}
			local pass_fade = header_pass_name .. "_fade2_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "texture",
				texture_id = pass_fade,
				style_id = pass_fade
			})

			widget.content[pass_fade] = "button_bg_fade"
			widget.style[pass_fade] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = {
					text_width,
					30
				},
				color = {
					100,
					255,
					255,
					255
				},
				offset = {
					x_position,
					-7 + y_position,
					6
				}
			}
			local pass_fade = header_pass_name .. "_fade3_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "texture",
				texture_id = pass_fade,
				style_id = pass_fade
			})

			widget.content[pass_fade] = "menu_frame_glass_01"
			widget.style[pass_fade] = {
				vertical_alignment = "top",
				horizontal_alignment = "left",
				texture_size = {
					text_width,
					30
				},
				color = {
					100,
					255,
					255,
					255
				},
				offset = {
					x_position,
					-7 + y_position,
					7
				}
			}
			local pass_text = header_pass_name .. "_text_" .. tuple[2]

			table.insert(widget.element.passes, {
				pass_type = "text",
				text_id = pass_text,
				style_id = pass_text
			})

			widget.content[pass_text] = text
			widget.style[pass_text] = {
				vertical_alignment = "top",
				font_type = "hell_shark",
				font_size = 20,
				horizontal_alignment = "left",
				text_color = Colors.get_table("font_default"),
				offset = {
					5 + x_position,
					-10 + y_position,
					10
				}
			}
			x_position = x_position + 10 + text_width
		end

		local height_with_margin = LINE_HEIGHT + LINE_MARGIN
		y_position = y_position - height_with_margin
		divider_left_size[1] = divider_left_size[1] + height_with_margin
		size[2] = size[2] + height_with_margin
	end

	return widget
end

return ui_common