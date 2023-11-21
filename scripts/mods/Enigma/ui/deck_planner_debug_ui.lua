local definitions = local_require("scripts/mods/Enigma/ui/deck_planner_debug_ui_definitions")
local DO_RELOAD = true
EnigmaDeckDebugUI = class(EnigmaDeckDebugUI)

local enigma = get_mod("Enigma")

EnigmaDeckDebugUI.init = function(self, parent, ingame_ui_context)
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

	self:create_ui_elements()
end

EnigmaDeckDebugUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.display_widget = UIWidget.init(definitions.widgets.fullscreen_display)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

local cached_card_names = {}
EnigmaDeckDebugUI.update = function (self, dt)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end
	
	if not self.is_in_inn then
		return
	end

	local deck_planner = enigma.managers.deck_planner
	local equipped_deck = deck_planner:equipped_deck()
	local editing_deck = deck_planner.editing_deck

	self.display_widget.content.equipped_deck_name = equipped_deck and equipped_deck.name or ""
	self.display_widget.content.editing_deck_name = editing_deck and editing_deck.name or ""
	self.display_widget.content.editing_deck_num_cards_text = editing_deck and #editing_deck.cards or ""

	if editing_deck then
		for _,card in ipairs(editing_deck.cards) do
			table.insert(cached_card_names, card.name)
		end
		self.display_widget.content.card_list_text = table.concat(cached_card_names, ", ")
	else
		self.display_widget.content.card_list_text = ""
	end
	self:draw(dt)
	table.clear(cached_card_names)
end

EnigmaDeckDebugUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_menu")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, self.display_widget)
	UIRenderer.end_pass(ui_renderer)
end