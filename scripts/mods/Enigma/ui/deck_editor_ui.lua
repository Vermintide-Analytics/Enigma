local definitions = local_require("scripts/mods/Enigma/ui/deck_editor_ui_definitions")
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

local cached_editing_deck

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
	self._is_focused = true
	
	--self.input_manager:block_device_except_service("deck_editor_view", "keyboard", 1)
	self.input_manager:block_device_except_service("deck_editor_view", "mouse", 1)
	
	self.active = true
end

EnigmaDeckEditorUI.on_exit = function(self, params)
	self._is_focused = false
	ShowCursorStack.pop()
	
	--self.input_manager:device_unblock_all_services("keyboard", 1)
	self.input_manager:device_unblock_all_services("mouse", 1)

	self.active = false
end

EnigmaDeckEditorUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if self._is_focused then
		self:_handle_input(dt, t)
	end

	local editing_deck = enigma.managers.deck_planner.editing_deck
	if not editing_deck then
		return
	end
	if editing_deck ~= cached_editing_deck then
		-- Update info here
		cached_editing_deck = editing_deck
	end

	self:draw(dt)
end

EnigmaDeckEditorUI._handle_input = function(self, dt, t)
	local close_window_button = self._widgets_by_name.close_window_button
	if UIUtils.is_button_pressed(close_window_button) then
		Managers.ui:handle_transition("close_active", {})
	end
end

EnigmaDeckEditorUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("deck_editor_view")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end