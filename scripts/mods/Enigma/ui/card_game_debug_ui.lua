local definitions = local_require("scripts/mods/Enigma/ui/card_game_debug_ui_definitions")
local DO_RELOAD = true
EnigmaGameDebugUI = class(EnigmaGameDebugUI)

local enigma = get_mod("Enigma")

EnigmaGameDebugUI.init = function(self, parent, ingame_ui_context)
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

EnigmaGameDebugUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.display_widget = UIWidget.init(definitions.widgets.fullscreen_display)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaGameDebugUI.update = function (self, dt)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	local self_data = enigma.managers.game.self_data
	local hand = self_data and self_data.hand
	if not self_data or not hand then
		return
	end

	self.display_widget.content.draws_text = self_data.available_card_draws or 0

	local warp = enigma.managers.warp
	self.display_widget.content.warpstone_text = warp.warpstone or 0
	self.display_widget.content.warp_dust_text = warp.warp_dust or 0

	for i=1,5 do
		local text_property = "card_"..i.."_text"
		if hand[i] then
			self.display_widget.content[text_property] = hand[i].name
		else
			self.display_widget.content[text_property] = ""
		end
	end
	self:draw(dt)
end

EnigmaGameDebugUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_menu")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, self.display_widget)
	UIRenderer.end_pass(ui_renderer)
end