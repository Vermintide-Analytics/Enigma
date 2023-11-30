local definitions = local_require("scripts/mods/Enigma/ui/big_card_ui_definitions")
local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaBigCardUI = class(EnigmaBigCardUI)

local enigma = get_mod("Enigma")

EnigmaBigCardUI.init = function(self, parent, ingame_ui_context)
	self._parent = parent
	self.network_event_delegate = ingame_ui_context.network_event_delegate
	self.camera_manager = ingame_ui_context.camera_manager
	self.ui_renderer = ingame_ui_context.ui_top_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.is_in_inn = ingame_ui_context.is_in_inn
	self.is_server = ingame_ui_context.is_server
	self.world_manager = ingame_ui_context.world_manager
	self.input_manager = ingame_ui_context.input_manager
	self.matchmaking_manager = Managers.matchmaking
	local world = self.world_manager:world("level_world")
	self.wwise_world = Managers.world:wwise_world(world)
	
	self.input_manager:create_input_service("big_card_ui", "IngameMenuKeymaps", "IngameMenuFilters")
	self.input_manager:map_device_to_service("big_card_ui", "keyboard")
	self.input_manager:map_device_to_service("big_card_ui", "mouse")

	self:create_ui_elements()
end

EnigmaBigCardUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)
	self.card_widget = self._widgets_by_name.card
	self.card_name_widget = self._widgets_by_name.card_name
	self.card_image_widget = self._widgets_by_name.card_image
	self.card_details_widget = self._widgets_by_name.card_details

	self.card_scenegraph_nodes = {
		card = self.ui_scenegraph.card,
		card_name = self.ui_scenegraph.card_name,
		card_image = self.ui_scenegraph.card_image,
		card_details = self.ui_scenegraph.card_details
	}

	self.card_widgets = {
		card = self.card_widget,
		card_name = self.card_name_widget,
		card_image = self.card_image_widget,
		card_details = self.card_details_widget
	}

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

local cached_card
local x_scale = 512
EnigmaBigCardUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

    local card = enigma.managers.ui.big_card_to_display
	if not cached_card and card then
		-- on enter
		ShowCursorStack.push()

		self.input_manager:capture_input(ALL_INPUT_METHODS, 1, "big_card_ui", "big_card_ui")

	elseif cached_card and not card then
		-- on exit
		ShowCursorStack.pop()
		
		self.input_manager:release_input(ALL_INPUT_METHODS, 1, "big_card_ui", "big_card_ui")
	end
	cached_card = card
	if not card then
		return
	end

	self:_handle_input(dt, t)

	x_scale = x_scale - dt*50
	if x_scale < 10 then
		x_scale = 800
	end

	ui_common.update_card_display(self.card_scenegraph_nodes, self.card_widgets, card, x_scale)
	self:draw(dt)

	--[[
	if card == cached_card and not card.dirty then
		self:draw(dt)
		return
	end
	
	if card.texture then
		self.card_image_widget.content.card_image = card.texture
	else
		self.card_image_widget.content.card_image = "enigma_card_image_placeholder"
	end

	if card.card_type == enigma.CARD_TYPE.passive then
		self.card_widget.style.card_background.color[2] = 205
		self.card_widget.style.card_background.color[3] = 198
		self.card_widget.style.card_background.color[4] = 111
	elseif card.card_type == enigma.CARD_TYPE.surge then
		self.card_widget.style.card_background.color[2] = 187
		self.card_widget.style.card_background.color[3] = 124
		self.card_widget.style.card_background.color[4] = 118
	elseif card.card_type == enigma.CARD_TYPE.ability then
		self.card_widget.style.card_background.color[2] = 118
		self.card_widget.style.card_background.color[3] = 130
		self.card_widget.style.card_background.color[4] = 187
	else
		self.card_widget.style.card_background.color[2] = 255
		self.card_widget.style.card_background.color[3] = 255
		self.card_widget.style.card_background.color[4] = 255
	end
	self.card_name_widget.content.card_name = card.name

	local num_description_lines = #card.description_lines
	local num_auto_descriptions = #card.auto_descriptions
	local num_condition_descriptions = #card.condition_descriptions
	local any_simple_keywords = card.channel or card.double_agent or card.ephemeral or card.infinite or card.unplayable or card.warp_hungry

	local num_rows = num_description_lines + num_auto_descriptions*2 + num_condition_descriptions*2 + (any_simple_keywords and 1 or 0)
	local details_vertical_space = self.ui_scenegraph.card_details.size[2]
	local row_height = details_vertical_space / num_rows
	local current_vertical_offset = details_vertical_space/-2 + row_height/2

	if any_simple_keywords then
		local keywords = {}
		if card.channel then
			table.insert(keywords, enigma:localize("channel", card.channel))
		end
		if card.double_agent then
			table.insert(keywords, enigma:localize("double_agent"))
		end
		if card.ephemeral then
			table.insert(keywords, enigma:localize("ephemeral"))
		end
		if card.infinite then
			table.insert(keywords, enigma:localize("infinite"))
		end
		if card.unplayable then
			table.insert(keywords, enigma:localize("unplayable"))
		end
		if card.warp_hungry then
			table.insert(keywords, enigma:localize("warp_hungry", card.warp_hungry))
		end
		self.card_details_widget.content.simple_keywords_text = table.concat(keywords, ", ")
		self.card_details_widget.style.simple_keywords_text.offset[2] = current_vertical_offset
		self.card_details_widget.style.simple_keywords_text.area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + row_height
	else
		self.card_details_widget.content.simple_keywords_text = ""
	end

	for i=1,5 do
		local described_keyword_title = "described_keyword_title_"..i
		local described_keyword_text = "described_keyword_text_"..i
		self.card_details_widget.content[described_keyword_title] = ""
		self.card_details_widget.content[described_keyword_text] = ""
	end

	local described_keyword_index = 1
	local text_size = self.card_details_widget.style.described_keyword_text_1.font_size
	for _,auto_description_table in ipairs(card.auto_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local described_keyword_title = "described_keyword_title_"..described_keyword_index
		local described_keyword_text = "described_keyword_text_"..described_keyword_index

		current_vertical_offset = current_vertical_offset + row_height/2 - text_size/2 - 3

		self.card_details_widget.content[described_keyword_text] = auto_description_table.localized
		self.card_details_widget.style[described_keyword_text].offset[2] = current_vertical_offset
		self.card_details_widget.style[described_keyword_text].area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + text_size + 6

		self.card_details_widget.content[described_keyword_title] = enigma:localize("auto")
		self.card_details_widget.style[described_keyword_title].offset[2] = current_vertical_offset
		current_vertical_offset = current_vertical_offset + row_height*1.5 - 3 - text_size/2
		
		described_keyword_index = described_keyword_index + 1
	end
	for _,condition_description_table in ipairs(card.condition_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local described_keyword_title = "described_keyword_title_"..described_keyword_index
		local described_keyword_text = "described_keyword_text_"..described_keyword_index

		current_vertical_offset = current_vertical_offset + row_height/2 - text_size/2 - 3

		self.card_details_widget.content[described_keyword_text] = condition_description_table.localized
		self.card_details_widget.style[described_keyword_text].offset[2] = current_vertical_offset
		self.card_details_widget.style[described_keyword_text].area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + text_size + 6

		self.card_details_widget.content[described_keyword_title] = enigma:localize("condition")
		self.card_details_widget.style[described_keyword_title].offset[2] = current_vertical_offset
		current_vertical_offset = current_vertical_offset + row_height*1.5 - 3 - text_size/2
		
		described_keyword_index = described_keyword_index + 1
	end

	if num_description_lines > 0 then
		local lines = {}
		for _,description_line_table in ipairs(card.description_lines) do
			table.insert(lines, description_line_table.localized)
		end
		self.card_details_widget.content.card_text = table.concat(lines, "\n")
		self.card_details_widget.style.card_text.offset[2] = current_vertical_offset
		self.card_details_widget.style.card_text.area_size[2] = row_height
	else
		self.card_details_widget.content.card_text = ""
	end

	self:draw(dt)
	]]
end

EnigmaBigCardUI._handle_input = function(self, dt, t)
	local keystrokes = Keyboard.keystrokes()
	if #keystrokes > 0 or self._widgets_by_name.background.content.screen_hotspot.on_pressed then
		enigma.managers.ui.big_card_to_display = nil
	end
end

EnigmaBigCardUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("big_card_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end