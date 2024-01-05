local definitions = local_require("scripts/mods/Enigma/ui/card_game_hud_definitions")
local CARD_WIDTH = definitions.card_width
local MAX_PLAYED_CARD_WIDTH = definitions.played_card_width
local PRETTY_MARGIN = 10
local CHANNEL_BAR_INNER_WIDTH = definitions.channel_bar_inner_width
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaCardGameHud = class(EnigmaCardGameHud)

local FLASH_DURATION = 0.75
local CHANNEL_BAR_FADE_DURATION = 2

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

local set_color_table = function(color_table, color)
	for i=1,4 do
		color_table[i] = color[i]
	end
end
local lerp_color_table = function(color_table, color_1, color_2, t)
	for i=1,4 do
		color_table[i] = math.lerp(color_1[i], color_2[i], t)
	end
end

EnigmaCardGameHud.update_draw_pile_color = function(self)
	local ui_manager = enigma.managers.ui
	local style = self.draw_pile_widget.style
	if ui_manager.time_since_draw_pile_action_invalid < FLASH_DURATION then
		local fade_time = ui_manager.time_since_draw_pile_action_invalid / FLASH_DURATION
		lerp_color_table(style.text.text_color, style.error_color, style.default_color, fade_time)
		lerp_color_table(style.icon.color, style.error_color, style.default_color, fade_time)
	else
		set_color_table(style.text.text_color, style.default_color)
		set_color_table(style.icon.color, style.default_color)
	end
end
EnigmaCardGameHud.update_warpstone_color = function(self)
	local ui_manager = enigma.managers.ui
	local style = self.warpstone_widget.style
	if ui_manager.time_since_warpstone_cost_action_invalid < FLASH_DURATION then
		local fade_time = ui_manager.time_since_warpstone_cost_action_invalid / FLASH_DURATION
		lerp_color_table(style.text.text_color, style.error_color, style.default_text_color, fade_time)
		lerp_color_table(style.icon.color, style.error_color, style.default_icon_color, fade_time)
	else
		set_color_table(style.text.text_color, style.default_text_color)
		set_color_table(style.icon.color, style.default_icon_color)
	end
end
EnigmaCardGameHud.update_card_draw_color = function(self)
	local ui_manager = enigma.managers.ui
	local style = self.card_draw_widget.style
	if ui_manager.time_since_available_draw_action_invalid < FLASH_DURATION then
		local fade_time = ui_manager.time_since_available_draw_action_invalid / FLASH_DURATION
		lerp_color_table(style.text.text_color, style.error_color, style.default_color, fade_time)
		lerp_color_table(style.icon.color, style.error_color, style.default_color, fade_time)
	else
		set_color_table(style.text.text_color, style.default_color)
		set_color_table(style.icon.color, style.default_color)
	end
end
EnigmaCardGameHud.update_hand_panel_color = function(self)
	local ui_manager = enigma.managers.ui
	local style = self.hand_panel_widget.style
	if ui_manager.time_since_hand_size_action_invalid < FLASH_DURATION then
		local fade_time = ui_manager.time_since_hand_size_action_invalid / FLASH_DURATION
		lerp_color_table(style.background.color, style.error_color, style.default_color, fade_time)
	else
		set_color_table(style.background.color, style.default_color)
	end
end

local show_played_card_duration = 1.25
local played_card_grow_duration = 0.2
EnigmaCardGameHud.update_played_card_display = function(self, dt, t)
	local ui_manager = enigma.managers.ui

	if not ui_manager.last_played_card and #ui_manager.played_cards_queue > 0 then
		ui_manager.time_since_card_played = 0
		ui_manager.last_played_card = table.remove(ui_manager.played_cards_queue, 1)
	elseif ui_manager.last_played_card then
		ui_manager.time_since_card_played = ui_manager.time_since_card_played + dt
		if ui_manager.time_since_card_played > show_played_card_duration then
			ui_manager.last_played_card = nil
		end
	end

	local card_to_display = ui_manager.time_since_card_played < show_played_card_duration and ui_manager.last_played_card
	local width = MAX_PLAYED_CARD_WIDTH
	if card_to_display and ui_manager.time_since_card_played < played_card_grow_duration then
		width = math.lerp(0, MAX_PLAYED_CARD_WIDTH, ui_manager.time_since_card_played / played_card_grow_duration)
	end

	card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, "played_card", card_to_display, width, "dirty_hud_ui_played_card", false)

end

EnigmaCardGameHud.create_ui_elements = function (self)
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
	self.played_card_widget = self._widgets_by_name.played_card
	
	self.warp_dust_bar_node = self.ui_scenegraph.warp_dust_bar
	self.warp_dust_bar_node_inner = self.ui_scenegraph.warp_dust_bar_inner
	self.card_draw_bar_node = self.ui_scenegraph.card_draw_bar
	self.card_draw_bar_node_inner = self.ui_scenegraph.card_draw_bar_inner
	self.channel_bar_node_inner = self.ui_scenegraph.channel_bar_inner

	self._widgets_except_hand = {}
	for id,widget in pairs(self._widgets_by_name) do
		if not id:find("hand_") then
			table.insert(self._widgets_except_hand, widget)
		else
			widget.cached_card = 1
		end
	end
	self.played_card_widget.cached_card = 1

	self.time_since_channel_ended = 0

	self.WARP_DUST_PER_WARPSTONE = enigma.managers.warp:get_warp_dust_per_warpstone()

	self.channeling_message = enigma:localize("channeling")
	self.channeling_cancelled_message = enigma:localize("channeling_cancelled")
	self.channeling_complete_message = enigma:localize("channeling_complete")

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

	-- Handle UI responsiveness flashing
	self:update_draw_pile_color()
	self:update_warpstone_color()
	self:update_card_draw_color()
	self:update_hand_panel_color()

	-- Hand display
	card_ui_common.update_hand_display(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, CARD_WIDTH, PRETTY_MARGIN, enigma.managers.ui.hud_data, "dirty_hud_ui")

	-- Played card display
	self:update_played_card_display(dt, t)

	-- Channel Bar
	local active_channel = game_data.active_channel
	if not active_channel then
		local previous_channel = game_data.previous_channel
		if not previous_channel or self.time_since_channel_ended > CHANNEL_BAR_FADE_DURATION then
			-- Show nothing
			self.channel_bar_widget.content.visible = false
			self.channel_bar_inner_widget.content.visible = false
		elseif previous_channel.cancelled then
			-- Show failure and fade it out
			self.time_since_channel_ended = self.time_since_channel_ended + dt
			self.channel_bar_widget.content.visible = true
			self.channel_bar_inner_widget.content.visible = true
			self.channel_bar_inner_widget.style.background.color = self.channel_bar_inner_widget.style.background.color_failure
			local alpha = math.lerp(255, 0, self.time_since_channel_ended/CHANNEL_BAR_FADE_DURATION)
			self.channel_bar_widget.style.background.color[1] = alpha
			self.channel_bar_inner_widget.style.background.color[1] = alpha
			self.channel_bar_widget.style.text.text_color[1] = alpha
			self.channel_bar_widget.content.text = self.channeling_cancelled_message
		elseif previous_channel.remaining_duration <= 0 then
			-- Show success and fade it out
			self.time_since_channel_ended = self.time_since_channel_ended + dt
			self.channel_bar_widget.content.visible = true
			self.channel_bar_inner_widget.content.visible = true
			self.channel_bar_inner_widget.style.background.color = self.channel_bar_inner_widget.style.background.color_success
			local alpha = math.lerp(255, 0, self.time_since_channel_ended/CHANNEL_BAR_FADE_DURATION)
			self.channel_bar_widget.style.background.color[1] = alpha
			self.channel_bar_inner_widget.style.background.color[1] = alpha
			self.channel_bar_widget.style.text.text_color[1] = alpha
			self.channel_bar_widget.content.text = self.channeling_complete_message
		end
	else
		-- Show progress
		self.time_since_channel_ended = 0
		self.channel_bar_widget.content.visible = true
		self.channel_bar_inner_widget.content.visible = true
		self.channel_bar_inner_widget.style.background.color = self.channel_bar_inner_widget.style.background.color_progress
		self.channel_bar_node_inner.size[1] = CHANNEL_BAR_INNER_WIDTH * math.clamp(1 - active_channel.remaining_duration/active_channel.total_duration, 0, 1)
		self.channel_bar_widget.style.background.color[1] = 255
		self.channel_bar_widget.style.text.text_color[1] = 255
		self.channel_bar_widget.content.text = self.channeling_message
	end

	self:draw(dt)
end

EnigmaCardGameHud.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_ui")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	local widgets_to_draw = enigma.managers.game.local_data and not enigma.managers.game:unable_to_play() and self._widgets or self._widgets_except_hand
	UIRenderer.draw_all_widgets(ui_renderer, widgets_to_draw)
	UIRenderer.end_pass(ui_renderer)
end