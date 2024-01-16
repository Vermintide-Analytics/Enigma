local definitions = local_require("scripts/mods/Enigma/ui/big_card_ui_definitions")
local BIG_CARD_WIDTH = definitions.big_card_width
local RELATED_CARD_WIDTH = definitions.related_card_width
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
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

	self.background_widget = self._widgets_by_name.background

	local related_card_1_widget = self._widgets_by_name.related_card_1
	local related_card_2_widget = self._widgets_by_name.related_card_2
	related_card_1_widget.cached_card = 1
	related_card_2_widget.cached_card = 1

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

local cached_card
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
		local background_color = self.background_widget.style.fullscreen_shade.color
		background_color[1] = enigma.managers.ui.big_card_showcase_mode and 255 or 180

	elseif cached_card and not card then
		-- on exit
		ShowCursorStack.pop()
		
		self.input_manager:release_input(ALL_INPUT_METHODS, 1, "big_card_ui", "big_card_ui")

		enigma.managers.ui.big_card_showcase_mode = false
	end
	cached_card = card
	if not card then
		return
	end

	self:_handle_input(dt, t)

	local related_card_1 = enigma.managers.ui.big_card_related_card_1
	local related_card_2 = enigma.managers.ui.big_card_related_card_2

	card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, "card", card, BIG_CARD_WIDTH)
	card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, "related_card_1", related_card_1, RELATED_CARD_WIDTH)
	card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, "related_card_2", related_card_2, RELATED_CARD_WIDTH)
	self:draw(dt)
end

EnigmaBigCardUI._handle_input = function(self, dt, t)
	local keystrokes = Keyboard.keystrokes()
	
	local related_card_1 = enigma.managers.ui.big_card_related_card_1
	local related_card_2 = enigma.managers.ui.big_card_related_card_2
	card_ui_common.handle_card_input(self._widgets_by_name, "related_card_1", related_card_1, self.wwise_world)
	card_ui_common.handle_card_input(self._widgets_by_name, "related_card_2", related_card_2, self.wwise_world)

	local related_card_1_interaction_widget = self._widgets_by_name["related_card_1_interaction"]
	local related_card_2_interaction_widget = self._widgets_by_name["related_card_2_interaction"]

	if related_card_1 and UIUtils.is_button_pressed(related_card_1_interaction_widget) then
		self:play_sound("Play_hud_select")
		enigma.managers.ui:show_big_card(related_card_1, enigma.managers.ui.big_card_showcase_mode)
	elseif related_card_2 and UIUtils.is_button_pressed(related_card_2_interaction_widget) then
		self:play_sound("Play_hud_select")
		enigma.managers.ui:show_big_card(related_card_2, enigma.managers.ui.big_card_showcase_mode)
	elseif #keystrokes > 0 or UIUtils.is_button_pressed(self._widgets_by_name.background, "screen_hotspot") then
		enigma.managers.ui:hide_big_card()
	end
end

EnigmaBigCardUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("big_card_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaBigCardUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end