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

	self.draw_pile_widget = self._widgets_by_name.draw_pile_column
	self.discard_pile_widget = self._widgets_by_name.discard_pile_column
	self.warpstone_widget = self._widgets_by_name.warpstone_column
	self.card_draw_widget = self._widgets_by_name.card_draw_column

	self.warp_dust_bar_node = self.ui_scenegraph.warp_dust_bar
	self.warp_dust_bar_node_inner = self.ui_scenegraph.warp_dust_bar_inner
	self.card_draw_bar_node = self.ui_scenegraph.card_draw_bar
	self.card_draw_bar_node_inner = self.ui_scenegraph.card_draw_bar_inner

	self.WARP_DUST_PER_WARPSTONE = enigma.managers.warp:get_warp_dust_per_warpstone()

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

	-- Info display
	local game_data = enigma.managers.game.local_data
	local num_draw_pile = #game_data.draw_pile
	local num_discard_pile = #game_data.discard_pile
	local card_draws = game_data.available_card_draws
	local card_draws_ipart = math.floor(card_draws)
	local card_draws_fpart = card_draws - card_draws_ipart

	local warpstone = enigma.managers.warp.warpstone
	local warp_dust = enigma.managers.warp.warp_dust

	self.draw_pile_widget.content.text = num_draw_pile
	self.discard_pile_widget.content.text = num_discard_pile
	
	self.warpstone_widget.content.text = warpstone
	self.warp_dust_bar_node_inner.size[2] = self.warp_dust_bar_node.size[2] * (warp_dust / self.WARP_DUST_PER_WARPSTONE)

	self.card_draw_widget.content.text = card_draws_ipart
	self.card_draw_bar_node_inner.size[2] = self.card_draw_bar_node.size[2] * card_draws_fpart

	-- Hand display
	ui_common.update_hand_display(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, CARD_WIDTH, PRETTY_MARGIN, enigma.managers.ui.hud_data)

	self:draw(dt)
end

EnigmaCardGameHud.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end