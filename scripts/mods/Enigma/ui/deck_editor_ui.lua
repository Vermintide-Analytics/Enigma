local definitions = local_require("scripts/mods/Enigma/ui/deck_editor_ui_definitions")
local MAX_CARDS_IN_DECK = definitions.max_cards_in_deck
local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaDeckEditorUI = class(EnigmaDeckEditorUI)

local enigma = get_mod("Enigma")

EnigmaDeckEditorUI.init = function(self, ingame_ui_context)
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

	self.input_manager:create_input_service("deck_editor_view", "IngameMenuKeymaps", "IngameMenuFilters")
	self.input_manager:map_device_to_service("deck_editor_view", "keyboard")
	self.input_manager:map_device_to_service("deck_editor_view", "mouse")

	self:create_ui_elements()
end

EnigmaDeckEditorUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaDeckEditorUI.input_service = function(self)
	return self.input_manager:get_service("deck_editor_view")
end

EnigmaDeckEditorUI.on_enter = function(self, params, offset)
	ShowCursorStack.push()

	self:update_deck_info_ui()
	self:update_deck_cards_ui()

	self.input_manager:block_device_except_service("deck_editor_view", "keyboard", 1)
	self.input_manager:block_device_except_service("deck_editor_view", "mouse", 1)
	
	self.active = true
end

EnigmaDeckEditorUI.on_exit = function(self, params)
	ShowCursorStack.pop()
	
	self.input_manager:device_unblock_all_services("keyboard", 1)
	self.input_manager:device_unblock_all_services("mouse", 1)

	self.active = false
	enigma.text_input_focused = false
end

EnigmaDeckEditorUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	self:_handle_input(dt, t)

	if not enigma.managers.deck_planner.editing_deck then
		return
	end

	self:draw(dt)
end

EnigmaDeckEditorUI._handle_input = function(self, dt, t)
	local deck = enigma.managers.deck_planner.editing_deck
	local cards = deck.cards

	local input_service = self:input_service()
	local input_close_pressed = input_service:get("toggle_menu")

	-- Window buttons
	local deck_list_button = self._widgets_by_name.deck_list_button
	local close_window_button = self._widgets_by_name.close_window_button

	UIWidgetUtils.animate_default_button(deck_list_button, dt)
	UIWidgetUtils.animate_default_button(close_window_button, dt)

	if deck_list_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if close_window_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end

	if UIUtils.is_button_pressed(deck_list_button) then
		self:play_sound("Play_hud_select")
		Managers.ui:handle_transition("deck_planner_view", { stop_editing = true })
	end

	if input_close_pressed or UIUtils.is_button_pressed(close_window_button) then
		self:play_sound("Play_hud_select")
		Managers.ui:handle_transition("close_active", {})
	end


	-- Deck Name Text Box
	local deck_name_content = self._widgets_by_name.deck_name.content
	if deck_name_content.deck_name_input_hotspot.on_pressed then
		deck_name_content.deck_name_input_active = true
		enigma.text_input_focused = true
	elseif deck_name_content.screen_hotspot.on_pressed then
		deck_name_content.deck_name_input_active = false
		enigma.text_input_focused = false
	end

	local keystrokes = Keyboard.keystrokes()
	for _, stroke in ipairs(keystrokes) do
		if stroke == Keyboard.ENTER or stroke == Keyboard.ESCAPE then
			deck_name_content.deck_name_input_active = false
			enigma.text_input_focused = false
		end
	end

	if deck_name_content.deck_name_input_active then
		local previous_deck_name = deck_name_content.deck_name
		deck_name_content.deck_name, deck_name_content.caret_index = KeystrokeHelper.parse_strokes(deck_name_content.deck_name, deck_name_content.caret_index, "insert", keystrokes)
		if deck_name_content.deck_name ~= previous_deck_name then
			enigma.managers.deck_planner:rename_deck(deck_name_content.deck_name)
		end
	end



	-- Deck cards
	local ui_update_needed = false
	for i=1, MAX_CARDS_IN_DECK do
		local item_name = "deck_slot_"..i
		local item = self._widgets_by_name[item_name]
		local card = cards[i]
		if card then
			item.style.background.color = item.content.item_hotspot.is_hover and item.style.background.hover_color or item.style.background.normal_color
			if item.content.item_hotspot.on_hover_enter then
				self:play_sound("Play_hud_hover")
			end
	
			if item.content.item_hotspot.on_pressed then
				enigma.managers.ui.big_card_to_display = card
	
			elseif item.content.item_hotspot.on_right_click then
				enigma.managers.deck_planner:remove_card_from_editing_deck_by_index(i)
				ui_update_needed = true
			end
		end
	end
	if ui_update_needed then
		self:update_deck_info_ui()
		self:update_deck_cards_ui()
	end
end

EnigmaDeckEditorUI.hotkey_allowed = function(self, input, mapping_data)
	return true
end

EnigmaDeckEditorUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("deck_editor_view")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaDeckEditorUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end

EnigmaDeckEditorUI.update_deck_info_ui = function(self)
	local deck = enigma.managers.deck_planner.editing_deck

	local deck_name_content = self._widgets_by_name.deck_name.content
	deck_name_content.deck_name = deck and deck.name or ""
	deck_name_content.caret_index = deck.name:len() + 1
	
	local deck_card_count_content = self._widgets_by_name.deck_card_count.content
	deck_card_count_content.deck_card_count = "Cards: "..#deck.cards.." / "..enigma.managers.deck_planner:max_cards(deck.game_mode)
	
	local deck_cp_count_content = self._widgets_by_name.deck_cp_count.content
	deck_cp_count_content.deck_cp_count = "CP: "..deck.cp.." / "..enigma.managers.deck_planner:max_cp(deck.game_mode)
end

local color_by_rarity = {
	[enigma.CARD_RARITY.common] = {
		255,
		255,
		255,
		255
	},
	[enigma.CARD_RARITY.rare] = {
		255,
		0,
		0,
		255
	},
	[enigma.CARD_RARITY.epic] = {
		255,
		147,
		112,
		219
	},
	[enigma.CARD_RARITY.legendary] = {
		255,
		255,
		165,
		0
	},
}

EnigmaDeckEditorUI.update_deck_cards_ui = function(self)
	local deck = enigma.managers.deck_planner.editing_deck
	local cards = deck.cards

	for i=1, MAX_CARDS_IN_DECK do
		local widget_name = "deck_slot_"..i
		local widget = self._widgets_by_name[widget_name]
		local card = cards[i]
		if card then
			widget.content.visible = true
			widget.content.card_name = card.name
			widget.content.card_cost = card.cost
			widget.style.card_rarity.color = color_by_rarity[card.rarity]
		else
			widget.content.visible = false
		end
	end
end
