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
			widget.content.input_active = true
		elseif widget.content.unfocus_hotspot.on_pressed then
			unfocus_pressed = true
		end
	end
	if any_pressed then
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

return ui_common