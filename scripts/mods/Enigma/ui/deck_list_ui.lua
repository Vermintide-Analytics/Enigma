local definitions = local_require("scripts/mods/Enigma/ui/deck_list_ui_definitions")
local DECKS_PER_PAGE = definitions.decks_per_page
local DO_RELOAD = true
EnigmaDeckListUI = class(EnigmaDeckListUI)

local enigma = get_mod("Enigma")

EnigmaDeckListUI.init = function(self, ingame_ui_context)
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

	self.input_manager:create_input_service("deck_list_view", "IngameMenuKeymaps", "IngameMenuFilters")
	self.input_manager:map_device_to_service("deck_list_view", "keyboard")
	self.input_manager:map_device_to_service("deck_list_view", "mouse")

	self.name_filter = ""
	self.filtered_decks = {}
	self.num_pages = 1
	self.current_page = 1

	self:create_ui_elements()
end

EnigmaDeckListUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaDeckListUI.input_service = function(self)
	return self.input_manager:get_service("deck_list_view")
end

EnigmaDeckListUI.on_enter = function(self, params, offset)
	ShowCursorStack.push()

	self:update_filtered_decks()
	
	self.input_manager:block_device_except_service("deck_list_view", "keyboard", 1)
	self.input_manager:block_device_except_service("deck_list_view", "mouse", 1)
	
	self.active = true
end

EnigmaDeckListUI.on_exit = function(self, params)
	ShowCursorStack.pop()

	self:play_sound("Play_hud_select")
	
	self.input_manager:device_unblock_all_services("keyboard", 1)
	self.input_manager:device_unblock_all_services("mouse", 1)

	self.active = false
end

EnigmaDeckListUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	self:_handle_input(dt, t)

	local editing_deck = enigma.managers.deck_planner.editing_deck
	if editing_deck then
		return
	end

	self:draw(dt)
end

EnigmaDeckListUI._handle_input = function(self, dt, t)
	local input_service = self:input_service()
	local input_close_pressed = input_service:get("toggle_menu")

	local close_window_button = self._widgets_by_name.close_window_button


	local equip_button_pressed = false
	for i=1,DECKS_PER_PAGE do
		local item_name = "deck_slot_"..i
		local item = self._widgets_by_name[item_name]

		local item_equip_button_name = item_name.."_equip_button"
		local equip_button = self._widgets_by_name[item_equip_button_name]

		-- Lighten item background if hotspot.is_hover
		if item.content.item_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end

		UIWidgetUtils.animate_default_button(equip_button, dt)
		if equip_button.content.button_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end
		if UIUtils.is_button_pressed(equip_button) then
			equip_button_pressed = true
			local deck_index = (self.current_page - 1) * DECKS_PER_PAGE + i
			local deck = self.filtered_decks[deck_index]
			if deck then
				self:play_sound("Play_hud_select")
				enigma.managers.deck_planner:equip_deck_for_current_career_and_game_mode(deck.name)
				self:update_deck_list_ui()
			end
		end
	end
	if not equip_button_pressed then
		for i=1,DECKS_PER_PAGE do
			local item_name = "deck_slot_"..i
			local item = self._widgets_by_name[item_name]
	
			if UIUtils.is_button_pressed(item, "item_hotspot") then
				local deck_index = (self.current_page - 1) * DECKS_PER_PAGE + i
				local deck = self.filtered_decks[deck_index]
				if deck then
					Managers.ui:handle_transition("deck_planner_view", { deck_name = deck.name })
				end
			end
		end
	end

	UIWidgetUtils.animate_default_button(close_window_button, dt)
	if close_window_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if input_close_pressed or UIUtils.is_button_pressed(close_window_button) then
		Managers.ui:handle_transition("close_active", {})
	end
end

EnigmaDeckListUI.hotkey_allowed = function(self, input, mapping_data)
	return true
end

EnigmaDeckListUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("deck_list_view")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaDeckListUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end

EnigmaDeckListUI.update_filtered_decks = function(self)
	if not (enigma.managers.deck_planner and enigma.managers.deck_planner.decks) then
		return
	end

	local game_mode = enigma:detect_game_mode()

	table.clear(self.filtered_decks)

	for name,deck in pairs(enigma.managers.deck_planner.decks) do
		if deck.game_mode == game_mode and name:lower():find(self.name_filter) then
			table.insert(self.filtered_decks, deck)
		end
	end

	self.num_pages = math.ceil(#self.filtered_decks / DECKS_PER_PAGE)
	self.current_page = math.min(self.current_page, self.num_pages)

	self:update_deck_list_ui()
end

EnigmaDeckListUI.update_deck_list_ui = function(self)
	local equipped_deck = enigma.managers.deck_planner:equipped_deck()

	local start_offset = (self.current_page - 1) * DECKS_PER_PAGE
	for i=1,DECKS_PER_PAGE do
		local deck_index = i + start_offset
		local deck = self.filtered_decks[deck_index]
		local has_deck = not not deck

		local item_widget_name = "deck_slot_"..i
		local item_widget = self._widgets_by_name[item_widget_name]
		local equip_button_name = item_widget_name.."_equip_button"
		local equip_button = self._widgets_by_name[equip_button_name]
		item_widget.content.visible = has_deck
		equip_button.content.visible = has_deck and deck ~= equipped_deck
		
		if deck then
			item_widget.content.deck_name = deck.name
		end
	end
end