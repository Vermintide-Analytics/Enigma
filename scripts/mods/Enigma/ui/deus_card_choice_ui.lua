local definitions = local_require("scripts/mods/Enigma/ui/deus_card_choice_ui_definitions")
local CARD_WIDTH = definitions.card_width
local NUM_CARDS_TO_CHOOSE_BETWEEN = definitions.num_cards_to_choose_between
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local DO_RELOAD = true
EnigmaDeusCardChoiceUI = class(EnigmaDeusCardChoiceUI)

local enigma = get_mod("Enigma")

EnigmaDeusCardChoiceUI.init = function(self, parent, ingame_ui_context)
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
	
	self.hide_view = false

	self:create_ui_elements()
end

EnigmaDeusCardChoiceUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	self.background_widget = self._widgets_by_name.background
	self.additional_resources_note_widget = self._widgets_by_name.additional_resources_note
	self.waiting_for_other_players_widget = self._widgets_by_name.waiting_for_other_players_notice
	self.toggle_view_button = self._widgets_by_name.toggle_view_button
	self.skip_button = self._widgets_by_name.skip_button

	for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
		self._widgets_by_name["card_"..i].cached_card = 1
	end

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaDeusCardChoiceUI.set_hide_view = function(self, hide)
	self.hide_view = hide
	self.toggle_view_button.content.title_text = hide and enigma:localize("show_card_selection") or enigma:localize("hide_card_selection")
end

local cached_show = false
EnigmaDeusCardChoiceUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end
	
	local deus_manager = enigma.managers.deus
	if not deus_manager.choosing_deus_card and not deus_manager.waiting_for_other_player_card_choices then
		if cached_show then
			-- on exit
			cached_show = false
		end
		return
	end
	if not cached_show then
		-- on enter
		cached_show = true
		self:set_hide_view(false)
	end

	self.toggle_view_button.content.visible = deus_manager.choosing_deus_card
	self.waiting_for_other_players_widget.content.visible = not deus_manager.choosing_deus_card

	local show_card_choice_ui = deus_manager.choosing_deus_card and not self.hide_view

	for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
		local card_to_show = show_card_choice_ui and deus_manager.offered_cards[i]
		card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, "card_"..i, card_to_show, CARD_WIDTH)

		local additional_resources_label_widget = self._widgets_by_name["additional_resources_label_"..i]
		additional_resources_label_widget.content.visible = show_card_choice_ui
	end

	self.skip_button.content.visible = show_card_choice_ui
	self.background_widget.content.visible = show_card_choice_ui
	self.additional_resources_note_widget.content.visible = show_card_choice_ui

	self:_handle_input(dt, t)

	self:draw(dt)
end

EnigmaDeusCardChoiceUI._handle_input = function(self, dt, t)
	-- Toggle View Button
	local toggle_view_button = self._widgets_by_name.toggle_view_button
	UIWidgetUtils.animate_default_button(toggle_view_button, dt)
	if toggle_view_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if UIUtils.is_button_pressed(toggle_view_button) then
		self:play_sound("Play_hud_select")
		self:set_hide_view(not self.hide_view)
	end

	if self.hide_view then
		return
	end

	for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
		local card = enigma.managers.deus.offered_cards[i]
		if card then
			local card_node_id = "card_"..i
			card_ui_common.handle_card_input(self._widgets_by_name, card_node_id, card, self.wwise_world)
			local interaction_widget = self._widgets_by_name["card_"..i.."_interaction"]
			if UIUtils.is_button_pressed(interaction_widget) then
				self:play_sound("Play_hud_select")
				enigma.managers.deus:card_to_add_chosen(card)
			end
		end
	end

	-- Skip Button
	local skip_button = self._widgets_by_name.skip_button
	UIWidgetUtils.animate_default_button(skip_button, dt)
	if skip_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if UIUtils.is_button_pressed(skip_button) then
		self:play_sound("Play_hud_select")
		enigma.managers.deus:card_to_add_chosen(nil)
	end
end

EnigmaDeusCardChoiceUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("deus_map_input_service_name")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaDeusCardChoiceUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end