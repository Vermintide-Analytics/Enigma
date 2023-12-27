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
	if content.hotspot.on_pressed then
		content.input_active = true
		enigma.managers.ui:text_input_focused()
	elseif content.unfocus_hotspot.on_pressed then
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
		local pressed = widget.content.hotspot.on_pressed
		if pressed then
			any_pressed = widget
		elseif widget.content.unfocus_hotspot.on_pressed then
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

ui_common.create_dropdown_menu_widget = function(dropdown_definition, scenegraph_2nd_layer_id)
	local offset_x = dropdown_definition.style.border_bottom.offset[1]
	local offset_y = dropdown_definition.style.border_bottom.offset[2]
	--local offset_y = dropdown_definition.style.offset[2]
	local size_x = dropdown_definition.style.border_bottom.size[1]
	local options_texts = dropdown_definition.content.options_texts
	local string_height = 35
	local size_y = #options_texts * string_height

	local definition = {
		element = {
		passes = {
			{
			pass_type = "texture",

			style_id   = "background",
			texture_id = "rect_masked_texture"
			}
		}
		},
		content = {
		rect_masked_texture = "rect_masked",
		},
		style = {
		background = {
			size = {size_x, size_y},
			offset = {offset_x, offset_y - size_y, 20},
			color = {255, 10, 10, 10}
		}
		},
		scenegraph_id = scenegraph_2nd_layer_id,
		offset = {0, 0, 0}
	}

	for i, options_text in ipairs(options_texts) do

		-- HOTSPOT

		local lua_hotspot_name = "hotspot" .. tostring(i)

		-- pass
		local pass = {
			pass_type = "hotspot",

			style_id = lua_hotspot_name,
			content_id = lua_hotspot_name
		}
		table.insert(definition.element.passes, pass)

		-- content
		definition.content[lua_hotspot_name] = {}
		definition.content[lua_hotspot_name].num = i

		-- style
		definition.style[lua_hotspot_name] = {
		offset = {offset_x, offset_y - string_height * i, 21},
		size = {size_x, string_height}
		}

		-- OPTION TEXT

		local lua_text_name = "text" .. tostring(i)

		-- pass
		pass = {
			pass_type = "text",

			style_id = lua_text_name,
			text_id = lua_text_name,

			content_check_function = function (content, style)

				style.text_color = content[lua_hotspot_name].is_hover and Colors.get_color_table_with_alpha("white", 255) or Colors.get_color_table_with_alpha("cheeseburger", 255)
				return true
			end
		}
		table.insert(definition.element.passes, pass)

		-- content
		definition.content[lua_text_name] = options_text

		-- style
		definition.style[lua_text_name] = {
			offset = {offset_x + size_x / 2, offset_y - string_height * i, 21},
			horizontal_alignment = "center",
			font_size = 24,
			font_type = "hell_shark_masked",
			dynamic_font = true,
			text_color = Colors.get_color_table_with_alpha("cheeseburger", 255)
		}
	end

	return UIWidget.init(definition)
end

ui_common.create_dropdown_widget = function(widget_definition, scenegraph_id, scenegraph_2nd_layer_id, width)
	local widget_size = { width, 80 }
	local offset_y = -widget_size[2]

	local options_texts         = {}
	local options_values        = {}
	local options_shown_widgets = {}

	for i, option in ipairs(widget_definition.options) do
		options_texts[i] = option.text
		options_values[i] = option.value
		options_shown_widgets[i] = option.show_widgets or {}
	end

	local definition = {
		element = {
			passes = {
				-- VISUALS
				{
				pass_type = "texture",

				style_id   = "background",
				texture_id = "rect_masked_texture",
				},
				{
				pass_type = "texture",

				style_id   = "highlight_texture",
				texture_id = "highlight_texture",
				content_check_function = function (content)
					return content.highlight_hotspot.is_hover and content.callback_is_cursor_inside_settings_list()
				end
				},
				{
				pass_type = "text",

				style_id = "text",
				text_id  = "text"
				},
				{
				pass_type = "text",

				style_id = "current_option_text",
				text_id  = "current_option_text"
				},
				{
				pass_type = "texture",

				style_id   = "border_top",
				texture_id = "rect_masked_texture"
				},
				{
				pass_type = "texture",

				style_id   = "border_left",
				texture_id = "rect_masked_texture"
				},
				{
				pass_type = "texture",

				style_id   = "border_right",
				texture_id = "rect_masked_texture"
				},
				{
				pass_type = "texture",

				style_id   = "border_bottom",
				texture_id = "rect_masked_texture"
				},

				-- HOTSPOTS
				{
				pass_type = "hotspot",

				content_id = "highlight_hotspot"
				},
				{
				pass_type = "hotspot",

				style_id   = "dropdown_hotspot",
				content_id = "dropdown_hotspot"
				},
				-- PROCESSING
				{
				pass_type = "local_offset",

				offset_function = function (ui_scenegraph_, style, content, ui_renderer)

					local is_interactable = content.highlight_hotspot.is_hover and content.callback_is_cursor_inside_settings_list()

					if is_interactable then

					if content.tooltip_text then
						style.tooltip_text.cursor_offset = content.callback_fit_tooltip_to_the_screen(content, style.tooltip_text, ui_renderer)
					end

					if content.dropdown_hotspot.on_release then
						content.callback_change_dropdown_menu_visibility(content)
					end

					if content.highlight_hotspot.on_release and not content.dropdown_hotspot.on_release then
						content.callback_hide_sub_widgets(content)
					end
					end

					if content.is_dropdown_menu_opened then

					local old_value = content.options_values[content.current_option_number]

					if content.callback_draw_dropdown_menu(content) then

						if content.is_widget_collapsed then
						content.callback_hide_sub_widgets(content)
						end

						local mod_name = content.mod_name
						local setting_id = content.setting_id
						local new_value = content.options_values[content.current_option_number]

						content.callback_setting_changed(mod_name, setting_id, old_value, new_value)
					end
					end

					style.current_option_text.text_color = (is_interactable and content.dropdown_hotspot.is_hover or content.is_dropdown_menu_opened) and Colors.get_color_table_with_alpha("white", 255) or Colors.get_color_table_with_alpha("cheeseburger", 255)

					local new_border_color = is_interactable and content.dropdown_hotspot.is_hover and {255, 45, 45, 45} or {255, 30, 30, 30}
					style.border_top.color = new_border_color
					style.border_left.color  = new_border_color
					style.border_right.color = new_border_color
					style.border_bottom.color = new_border_color
				end
				},
				-- TOOLTIP
				{
				pass_type = "tooltip_text",

				text_id  = "tooltip_text",
				style_id = "tooltip_text",
				content_check_function = function (content)
					return content.tooltip_text and content.highlight_hotspot.is_hover and content.callback_is_cursor_inside_settings_list()
				end
				},
				-- DEBUG
				{
				pass_type = "rect",

				content_check_function = function ()
					return false
				end
				},
				{
				pass_type = "border",

				content_check_function = function (content_, style)
					if false then
						style.thickness = 1
					end

					return false
				end
				},
				{
				pass_type = "rect",

				style_id = "debug_middle_line",
				content_check_function = function ()
					return false
				end
				}
			}
		},
		content = {
			is_widget_visible = true,

			highlight_texture = "playerlist_hover",
			rect_masked_texture = "rect_masked",
			--background_texture = "common_widgets_background_lit",

			highlight_hotspot = {},
			dropdown_hotspot = {},

			options_texts  = options_texts,
			options_values = options_values,
			options_shown_widgets = options_shown_widgets,
			total_options_number = #options_texts,
			current_option_number = 1,
			current_option_text = options_texts[1],
			current_shown_widgets = nil, -- if nil, all subwidgets are shown
			default_value = widget_definition.default_value,
		},
		style = {

		-- VISUALS

		background = {
			size = {widget_size[1], widget_size[2] - 3},
			offset = {0, offset_y + 1, 0},
			color = {255, 30, 23, 15}
		},

		highlight_texture = {
			size = {widget_size[1], widget_size[2] - 3},
			offset = {0, offset_y + 1, 2},
			masked = true
		},

		text = {
			offset = {60 + widget_definition.depth * 40, offset_y + 5, 3},
			font_size = 28,
			font_type = "hell_shark_masked",
			dynamic_font = true,
			text_color = Colors.get_color_table_with_alpha("white", 255)
		},

		border_top = {
			size = {270, 2},
			offset = {widget_size[1] - 300, offset_y + (widget_size[2] - 10), 1},
			color = {255, 30, 30, 30}
		},

		border_left = {
			size = {2, widget_size[2] - 16},
			offset = {widget_size[1] - 300, offset_y + 8, 1},
			color = {255, 30, 30, 30}
		},

		border_right = {
			size = {2, widget_size[2] - 16},
			offset = {widget_size[1] - 32, offset_y + 8, 1},
			color = {255, 30, 30, 30}
		},

		border_bottom = {
			size = {270, 2},
			offset = {widget_size[1] - 300, offset_y + 8, 1},
			color = {255, 30, 30, 30}
		},

		current_option_text = {
			offset = {widget_size[1] - 165, offset_y + 4, 3},
			horizontal_alignment = "center",
			font_size = 28,
			font_type = "hell_shark_masked",
			dynamic_font = true,
			text_color = Colors.get_color_table_with_alpha("cheeseburger", 255)
		},

		-- HOTSPOTS

		dropdown_hotspot = {
			size = {270, widget_size[2]},
			offset = {widget_size[1] - 300, offset_y, 0}
		},

		-- TOOLTIP

		tooltip_text = {
			font_type = "hell_shark",
			font_size = 18,
			horizontal_alignment = "left",
			vertical_alignment = "top",
			cursor_side = "right",
			max_width = 600,
			cursor_offset = {27, 27},
			cursor_offset_bottom = {27, 27},
			cursor_offset_top = {27, -27},
			line_colors = {
			Colors.get_color_table_with_alpha("cheeseburger", 255),
			Colors.get_color_table_with_alpha("white", 255)
			}
		},

		-- DEBUG

		debug_middle_line = {
			size = {widget_size[1], 2},
			offset = {0, (offset_y + widget_size[2]/2) - 1, 10},
			color = {200, 0, 255, 0}
		},

		offset = {0, offset_y, 0},
		size = {widget_size[1], widget_size[2]},
		color = {50, 255, 255, 255}
		},
		scenegraph_id = scenegraph_id,
		offset = {0, 0, 0}
	}

	definition.content.popup_menu_widget = ui_common.create_dropdown_menu_widget(definition, scenegraph_2nd_layer_id)

	return UIWidget.init(definition)
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