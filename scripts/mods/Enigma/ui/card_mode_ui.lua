local definitions = local_require("scripts/mods/Enigma/ui/card_mode_ui_definitions")
local CARD_WIDTH = definitions.card_width
local PRETTY_MARGIN = 16
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaCardModeUI = class(EnigmaCardModeUI)

local enigma = get_mod("Enigma")

EnigmaCardModeUI.init = function(self, parent, ingame_ui_context)
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
	
	self.input_manager:create_input_service("card_mode_ui", "IngameMenuKeymaps", "IngameMenuFilters")
	self.input_manager:map_device_to_service("card_mode_ui", "keyboard")
	self.input_manager:map_device_to_service("card_mode_ui", "mouse")

	self:create_ui_elements()
end

EnigmaCardModeUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	for id,widget in pairs(self._widgets_by_name) do
		if id:find("hand_") then
			widget.cached_card = 1
		end
	end

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

local cached_card_mode
EnigmaCardModeUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if not cached_card_mode and enigma.card_mode then
		-- on enter
		self.input_manager:block_device_except_service("card_mode_ui", "keyboard", 1)
		self.input_manager:block_device_except_service("card_mode_ui", "mouse", 1)
		ShowCursorStack.push()

		self.input_manager:capture_input(ALL_INPUT_METHODS, 1, "card_mode_ui", "card_mode_ui")

		self._widgets_by_name.end_test_game_button.content.visible = enigma.managers.game.debug or false

	elseif cached_card_mode and not enigma.card_mode then
		-- on exit
		self.input_manager:device_unblock_all_services("keyboard", 1)
		self.input_manager:device_unblock_all_services("mouse", 1)
		ShowCursorStack.pop()

		self.input_manager:release_input(ALL_INPUT_METHODS, 1, "card_mode_ui", "card_mode_ui")
	end
	cached_card_mode = enigma.card_mode

	if not enigma.managers.game:is_in_game() then
		return
	end
	
	card_ui_common.update_hand_display(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, CARD_WIDTH, PRETTY_MARGIN, enigma.managers.ui.card_mode_ui_data, "dirty_card_mode_ui")

	if not enigma.card_mode then
		return
	end

	self:_handle_input(dt, t)

	self:draw(dt)
end

EnigmaCardModeUI._handle_input = function(self, dt, t)
	local keystrokes = Keyboard.keystrokes()
	for _, stroke in ipairs(keystrokes) do
		if stroke == Keyboard.ENTER or stroke == Keyboard.ESCAPE then
			enigma.card_mode = false
		end
	end
	card_ui_common.handle_hand_input(self._widgets_by_name, self.wwise_world)

	local hand = enigma.managers.game.local_data.hand
	local hand_size = #hand
	for i=1,hand_size do
		local interaction_widget = self._widgets_by_name["hand_card_"..i.."_interaction"]
		if UIUtils.is_button_pressed(interaction_widget) then
			enigma.managers.user_interaction.request_play_card_from_hand_next_update = i
		end
	end

	if enigma.managers.game.debug then
		-- End Test Game Button
		local end_test_game_button = self._widgets_by_name.end_test_game_button
		UIWidgetUtils.animate_default_button(end_test_game_button, dt)
		if end_test_game_button.content.button_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end
		if UIUtils.is_button_pressed(end_test_game_button) then
			self:play_sound("Play_hud_select")
			enigma:network_send("enigma_dev_game", "all", "end")
		end

		-- Warpstone Zero Button
		local warpstone_zero_button = self._widgets_by_name.test_game_warpstone_zero_button
		UIWidgetUtils.animate_default_button(warpstone_zero_button, dt)
		if warpstone_zero_button.content.button_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end
		if UIUtils.is_button_pressed(warpstone_zero_button) then
			self:play_sound("Play_hud_select")
			enigma.managers.warp:pay_cost(enigma.managers.warp.warpstone, "debug")
		end
		-- Warpstone +1 Button
		local warpstone_plus_one_button = self._widgets_by_name.test_game_warpstone_plus_one_button
		UIWidgetUtils.animate_default_button(warpstone_plus_one_button, dt)
		if warpstone_plus_one_button.content.button_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end
		if UIUtils.is_button_pressed(warpstone_plus_one_button) then
			self:play_sound("Play_hud_select")
			enigma.managers.warp:add_warpstone(1, "debug")
		end
		-- Warpstone +99 Button
		local warpstone_plus_hundred_button = self._widgets_by_name.test_game_warpstone_plus_hundred_button
		UIWidgetUtils.animate_default_button(warpstone_plus_hundred_button, dt)
		if warpstone_plus_hundred_button.content.button_hotspot.on_hover_enter then
			self:play_sound("Play_hud_hover")
		end
		if UIUtils.is_button_pressed(warpstone_plus_hundred_button) then
			self:play_sound("Play_hud_select")
			enigma.managers.warp:add_warpstone(99, "debug")
		end
	end
end

EnigmaCardModeUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("card_mode_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaCardModeUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end