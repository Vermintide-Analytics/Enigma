local definitions = local_require("scripts/mods/Enigma/ui/card_game_hud_definitions")
local CARD_WIDTH = definitions.card_width
local PRETTY_MARGIN = 10
local ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaCardGameHud = class(EnigmaCardGameHud)

local enigma = get_mod("Enigma")

EnigmaCardGameHud.init = function(self, parent, ingame_ui_context)
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

EnigmaCardGameHud.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaCardGameHud.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if not enigma.managers.game:is_in_game() then
		return
	end

	local hand = enigma.managers.game.self_data.hand
	local hand_size = #hand
	local horizontal_offset = (PRETTY_MARGIN + CARD_WIDTH)/2 * (hand_size-1) * -1
	for i=1,5 do
		local card = hand[i]
		ui_common.update_card_display_if_needed(self.ui_scenegraph, self._widgets_by_name, "card_"..i, card, CARD_WIDTH)
		local card_scenegraph_node = self.ui_scenegraph["card_"..i]
		card_scenegraph_node.position[1] = horizontal_offset
		horizontal_offset = horizontal_offset + PRETTY_MARGIN + CARD_WIDTH
	end

	self:draw(dt)
end

EnigmaCardGameHud.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end