local definitions = local_require("scripts/mods/Enigma/ui/deck_prep_hud_definitions")
local PRETTY_MARGIN = 10
local DO_RELOAD = true
EnigmaDeckPrepHud = class(EnigmaDeckPrepHud)

local enigma = get_mod("Enigma")

EnigmaDeckPrepHud.init = function(self, parent, ingame_ui_context)
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

EnigmaDeckPrepHud.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	self.draw_pile_widget = self._widgets_by_name.draw_pile_column
	self.discard_pile_widget = self._widgets_by_name.discard_pile_column
	self.warpstone_widget = self._widgets_by_name.warpstone_column
	self.card_draw_widget = self._widgets_by_name.card_draw_column
	self.channel_bar_widget = self._widgets_by_name.channel_bar
	self.channel_bar_inner_widget = self._widgets_by_name.channel_bar_inner
	self.hand_panel_widget = self._widgets_by_name.hand_panel
	
	self.warp_dust_bar_node = self.ui_scenegraph.warp_dust_bar
	self.warp_dust_bar_node_inner = self.ui_scenegraph.warp_dust_bar_inner
	self.card_draw_bar_node = self.ui_scenegraph.card_draw_bar
	self.card_draw_bar_node_inner = self.ui_scenegraph.card_draw_bar_inner
	self.channel_bar_node_inner = self.ui_scenegraph.channel_bar_inner

	self.time_since_channel_ended = 0

	self.WARP_DUST_PER_WARPSTONE = enigma.managers.warp:get_warp_dust_per_warpstone()

	self.channeling_message = enigma:localize("channeling")
	self.channeling_cancelled_message = enigma:localize("channeling_cancelled")
	self.channeling_complete_message = enigma:localize("channeling_complete")

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

local valid_color = {
	255,
	0,
	255,
	0
}
local invalid_color = {
	255,
	255,
	0,
	0
}

EnigmaDeckPrepHud.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if enigma.managers.game:is_in_game() or not self.is_in_inn then
		return
	end

	-- Info display
	if enigma.managers.ui.deck_prep_dirty then
		local deck_planner = enigma.managers.deck_planner
		local num_players = 0
		local all_valid = true
		if not Managers.player or not Managers.player._players_by_peer then
			return
		end
		for peer_id,player_data in pairs(deck_planner.player_data) do
			num_players = num_players + 1
			if not player_data.valid then
				all_valid = false
			end
		end
		if num_players > 5 then
			-- TODO: Handle larger players with a simplified view
		else
			for i=1,5 do
				local row_id = "player_row_"..i
				local row_widget = self._widgets_by_name[row_id]
				row_widget.content.visible = false
			end
			local index = 1
			for peer_id,player_data in pairs(deck_planner.player_data) do
				local row_id = "player_row_"..index
				local row_widget = self._widgets_by_name[row_id]
				local player = Managers.player:player_from_peer_id(peer_id)
				if not player then
					enigma:warning("Could not find player from peer id when updating deck prep UI")
				else
					row_widget.content.visible = true
					row_widget.content.player_name = player:name()
					row_widget.content.deck_name = player_data.deck_name
					local tint = player_data.valid and valid_color or invalid_color
					row_widget.style.deck_name.text_color = tint
					row_widget.style.validity_icon.color = tint
					local validity_icon = player_data.valid and "enigma_card_check" or "enigma_card_x"
					row_widget.content.validity_icon = validity_icon

					index = index + 1
				end
			end
		end
		enigma.managers.ui.deck_prep_dirty = false
	end

	self:draw(dt)
end

EnigmaDeckPrepHud.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end