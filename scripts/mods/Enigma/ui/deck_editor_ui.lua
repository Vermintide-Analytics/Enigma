local definitions = local_require("scripts/mods/Enigma/ui/deck_editor_ui_definitions")
local MAX_CARDS_IN_DECK = definitions.max_cards_in_deck
local TOTAL_CARD_TILES = definitions.num_card_tiles
local CARD_TILE_WIDTH = definitions.card_tile_width
local card_ui_common = local_require("scripts/mods/Enigma/ui/card_ui_common")
local ui_common = local_require("scripts/mods/Enigma/ui/ui_common")
local DO_RELOAD = true
EnigmaDeckEditorUI = class(EnigmaDeckEditorUI)

local enigma = get_mod("Enigma")

local alphabet_comparator = function(str1, str2)
	return str1 < str2
end

local alphabet_card_pack_comparator = function(pack_1, pack_2)
	return alphabet_comparator(pack_1.name:lower(), pack_2.name:lower())
end

local card_pack_filter_options = {
	key = "pack",
}
local filter_definitions = {
	{
		key = "rarity",
		{
			enigma.CARD_RARITY.common,
			enigma:localize(enigma.CARD_RARITY.common)
		},
		{
			enigma.CARD_RARITY.rare,
			enigma:localize(enigma.CARD_RARITY.rare)
		},
		{
			enigma.CARD_RARITY.epic,
			enigma:localize(enigma.CARD_RARITY.epic)
		},
		{
			enigma.CARD_RARITY.legendary,
			enigma:localize(enigma.CARD_RARITY.legendary)
		},
	},
	{
		key = "cost",
		{
			0,
			"0"
		},
		{
			1,
			"1"
		},
		{
			2,
			"2"
		},
		{
			3,
			"3"
		},
		{
			4,
			"4"
		},
		{
			5,
			"5+"
		},
	},
	{
		key = "type",
		{
			enigma.CARD_TYPE.passive,
			enigma:localize(enigma.CARD_TYPE.passive)
		},
		{
			enigma.CARD_TYPE.attack,
			enigma:localize(enigma.CARD_TYPE.attack)
		},
		{
			enigma.CARD_TYPE.ability,
			enigma:localize(enigma.CARD_TYPE.ability)
		},
		{
			enigma.CARD_TYPE.chaos,
			enigma:localize(enigma.CARD_TYPE.chaos)
		},
	},
	{
		key = "keyword",
		{
			"auto",
			enigma:localize("keyword_auto")
		},
		{
			"channel",
			enigma:localize("keyword_channel")
		},
		{
			"charges",
			enigma:localize("keyword_charges")
		},
		{
			"condition",
			enigma:localize("keyword_condition")
		},
		-- {
		-- 	"double_agent",
		-- 	enigma:localize("keyword_double_agent")
		-- },
		{
			"ephemeral",
			enigma:localize("keyword_ephemeral")
		},
		{
			"echo",
			enigma:localize("keyword_echo")
		},
		{
			"primordial",
			enigma:localize("keyword_primordial")
		},
		{
			"retain",
			enigma:localize("keyword_retain")
		},
		{
			"unplayable",
			enigma:localize("keyword_unplayable")
		},
		-- {
		-- 	"warp_hungry",
		-- 	enigma:localize("keyword_warp_hungry")
		-- },
	},
	card_pack_filter_options
}

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

	self.name_filter = ""
	self.filtered_cards = {}
	self.num_pages = 1
	self.current_page = 1

	self:create_ui_elements()
end

EnigmaDeckEditorUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self._widgets, self._widgets_by_name = UIUtils.create_widgets(definitions.widgets)

	self.text_input_widgets = {
		self._widgets_by_name["deck_name"],
		self._widgets_by_name["card_name_search"]
	}

	local card_packs = {}
	for _,pack in pairs(enigma.managers.card_pack.card_packs) do
		table.insert(card_packs, {
			id = pack.id,
			name = pack.name
		})
	end
	table.sort(card_packs, alphabet_card_pack_comparator)
	for _,pack in ipairs(card_packs) do
		table.insert(card_pack_filter_options, {
			pack.id,
			pack.name
		})
	end

	local filters_widget = UIWidget.init(ui_common.create_search_filters_widget(self.ui_scenegraph, "filters_panel", self.ui_renderer, filter_definitions))
	self._widgets[#self._widgets + 1] = filters_widget
	self._widgets_by_name.filters = filters_widget
	filters_widget.content.visible = false

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaDeckEditorUI.input_service = function(self)
	return self.input_manager:get_service("deck_editor_view")
end

EnigmaDeckEditorUI.on_enter = function(self, params, offset)
	ShowCursorStack.push()

	self:update_deck_info_ui()
	self:update_deck_cards_ui()

	self:update_filtered_cards()

	self.input_manager:block_device_except_service("deck_editor_view", "keyboard", 1)
	self.input_manager:block_device_except_service("deck_editor_view", "mouse", 1)
	
	self.active = true
end

EnigmaDeckEditorUI.on_exit = function(self, params)
	ShowCursorStack.pop()
	
	self.input_manager:device_unblock_all_services("keyboard", 1)
	self.input_manager:device_unblock_all_services("mouse", 1)

	self.active = false
	enigma.managers.ui:text_input_lost_focus()
end

EnigmaDeckEditorUI.update = function (self, dt, t)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if not enigma.managers.deck_planner.editing_deck then
		return
	end

	self:_handle_input(dt, t)

	self:draw(dt)
end

EnigmaDeckEditorUI._handle_input = function(self, dt, t)
	local deck = enigma.managers.deck_planner.editing_deck
	local cards = deck.cards

	local input_service = self:input_service()
	local input_close_pressed = input_service:get("toggle_menu")

	-- Window buttons
	local deck_list_button = self._widgets_by_name.deck_list_button
	local close_window_button = self._widgets_by_name.close_window_button
	local delete_deck_button = self._widgets_by_name.delete_deck_button

	UIWidgetUtils.animate_default_button(deck_list_button, dt)
	UIWidgetUtils.animate_default_button(close_window_button, dt)
	UIWidgetUtils.animate_default_button(delete_deck_button, dt)

	if deck_list_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if close_window_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if not delete_deck_button.content.disable_button and delete_deck_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end

	if UIUtils.is_button_pressed(deck_list_button) then
		self:play_sound("Play_hud_select")
		Managers.ui:handle_transition("deck_planner_view", { stop_editing = true })
	end
	if input_close_pressed or UIUtils.is_button_pressed(close_window_button) then
		self:play_sound("Play_hud_select")
		Managers.ui:handle_transition("close_active", {})
	end
	if UIUtils.is_button_pressed(delete_deck_button) then
		self:play_sound("Play_hud_select")
		enigma.managers.deck_planner:force_delete_deck(deck.name)
		Managers.ui:handle_transition("deck_planner_view", { stop_editing = true })
		return
	end

	-- Filters
	local card_filter_update_needed = false
	local filters_toggle_button = self._widgets_by_name.filters_button
	local screen_hotspot = self._widgets_by_name.background.content.screen_hotspot
	local panel_hotspot = self._widgets_by_name.filters.content.panel_hotspot
	if filters_toggle_button.content.search_filters_hotspot.on_pressed then
		self.filters_panel_active = not self.filters_panel_active
		self._widgets_by_name.filters.content.visible = self.filters_panel_active
	elseif self.filters_panel_active and screen_hotspot.on_pressed and not panel_hotspot.on_pressed then
		self.filters_panel_active = false
		self._widgets_by_name.filters.content.visible = self.filters_panel_active
		return
	end

	local filters_widget = self._widgets_by_name.filters
	if filters_widget.content.query_dirty then
		card_filter_update_needed = true
	end

	if self.filters_panel_active then
		if card_filter_update_needed then
			self:update_filtered_cards()
		end
		return
	end

	-- Show Hidden Checkbox
	local checkbox_content = self._widgets_by_name.show_hidden_cards.content
	local checkbox_hotspot = checkbox_content.button_hotspot

	if checkbox_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end

	if checkbox_hotspot.on_release then
		checkbox_content.checked = not checkbox_content.checked
		self:play_sound("Play_hud_select")
		card_filter_update_needed = true
	end

	-- Text Inputs
	local text_changes = ui_common.handle_text_inputs(self.text_input_widgets)
	if text_changes then
		local new_deck_name = text_changes[self._widgets_by_name.deck_name]
		if new_deck_name then
			enigma.managers.deck_planner:rename_deck(new_deck_name)
		end
		local new_card_name_search = text_changes[self._widgets_by_name.card_name_search]
		if new_card_name_search then
			self.name_search = new_card_name_search
			card_filter_update_needed = true
		end
	end

	-- Equip button
	local deck_ui_update_needed = false
	local equip_deck_button = self._widgets_by_name.equip_deck_button
	UIWidgetUtils.animate_default_button(equip_deck_button, dt)
	if equip_deck_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if UIUtils.is_button_pressed(equip_deck_button) then
		self:play_sound("Play_hud_select")
		enigma.managers.deck_planner:equip_deck_for_current_career_and_game_mode(deck.name)
		deck_ui_update_needed = true
	end

	-- Deck cards
	for i=1, MAX_CARDS_IN_DECK do
		local item_name = "deck_slot_"..i
		local item = self._widgets_by_name[item_name]
		local card = cards[i]
		if card then
			item.style.background.color = item.content.item_hotspot.is_hover and item.style.background.hover_color or item.style.background.normal_color
			if item.content.item_hotspot.on_hover_enter then
				self:play_sound("Play_hud_hover")
			end
	
			if item.content.item_hotspot.on_pressed then
				if type(card) == "string" then
					enigma:echo("That card is not defined. Either it was removed from the card pack, or you do not have that card pack.")
				else
					self:play_sound("Play_hud_select")
					enigma.managers.ui.big_card_to_display = card
				end
			elseif item.content.item_hotspot.on_right_click then
				self:play_sound("Play_hud_select")
				enigma.managers.deck_planner:remove_card_from_editing_deck_by_index(i)
				deck_ui_update_needed = true
			end
		end
	end


	-- Pagination
	local need_update_pagination = false
	local page_left_button = self._widgets_by_name.page_left_button
	local page_right_button = self._widgets_by_name.page_right_button

	if not page_left_button.content.disable_button and page_left_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	if not page_right_button.content.disable_button and page_right_button.content.button_hotspot.on_hover_enter then
		self:play_sound("Play_hud_hover")
	end
	UIWidgetUtils.animate_default_button(page_left_button, dt)
	UIWidgetUtils.animate_default_button(page_right_button, dt)
	if not page_left_button.content.disable_button and UIUtils.is_button_pressed(page_left_button) then
		self:play_sound("Play_hud_select")
		self.current_page = self.current_page - 1
		need_update_pagination = true
	end
	if not page_right_button.content.disable_button and UIUtils.is_button_pressed(page_right_button) then
		self:play_sound("Play_hud_select")
		self.current_page = self.current_page + 1
		need_update_pagination = true
	end

	if need_update_pagination then
		self:update_card_tiles_ui()
	end


	-- Cards
	for i=1, TOTAL_CARD_TILES do
		local card_interaction_widget = self._widgets_by_name["card_"..i.."_interaction"]
		local card = self.filtered_cards[(self.current_page - 1) * TOTAL_CARD_TILES + i]
		
		card_ui_common.handle_card_input(self._widgets_by_name, "card_"..i, card, self.wwise_world)
		
		if card then
			if card_interaction_widget.content.hotspot.on_pressed then
				self:play_sound("Play_hud_select")
				enigma.managers.ui.big_card_to_display = card
			end
			if card_interaction_widget.content.hotspot.on_right_click then
				-- Add card to deck, if allowed
				self:play_sound("Play_hud_select")
				if card.allow_in_deck then
					enigma.managers.deck_planner:add_card_to_editing_deck(card.id)
					deck_ui_update_needed = true
				else
					enigma:echo(tostring(card.name).." cannot be added to decks")
				end
			end
		end
	end


	
	if deck_ui_update_needed then
		self:update_deck_info_ui()
		self:update_deck_cards_ui()
	end
	if card_filter_update_needed then
		self:update_filtered_cards()
	end
end

EnigmaDeckEditorUI.hotkey_allowed = function(self, input, mapping_data)
	return true
end

EnigmaDeckEditorUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("deck_editor_view")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_all_widgets(ui_renderer, self._widgets)
	UIRenderer.end_pass(ui_renderer)
end

EnigmaDeckEditorUI.play_sound = function (self, event)
	WwiseWorld.trigger_event(self.wwise_world, event)
end

EnigmaDeckEditorUI.update_deck_info_ui = function(self)
	local deck = enigma.managers.deck_planner.editing_deck

	local deck_name_content = self._widgets_by_name.deck_name.content
	deck_name_content.text = deck and deck.name or ""
	deck_name_content.caret_index = deck.name:len() + 1
	
	local deck_card_count_content = self._widgets_by_name.deck_card_count.content
	deck_card_count_content.deck_card_count = enigma:localize("deck_card_count", #deck.cards, enigma.managers.deck_planner:max_cards(deck.game_mode))

	local deck_cp_count_content = self._widgets_by_name.deck_cp_count.content
	deck_cp_count_content.deck_cp_count = enigma:localize("deck_cp_count", deck.cp, enigma.managers.deck_planner:max_cp(deck.game_mode))
	
	local deck_avg_cost_content = self._widgets_by_name.deck_avg_cost.content
	deck_avg_cost_content.deck_avg_cost = enigma:localize("deck_avg_cost", enigma.managers.deck_planner:average_cost(deck))

	local card_count_valid = not enigma.managers.deck_planner:is_num_cards_under_min(deck) and not enigma.managers.deck_planner:is_num_cards_over_max(deck)
	local deck_card_count_style = self._widgets_by_name.deck_card_count.style.deck_card_count
	deck_card_count_style.text_color = card_count_valid and deck_card_count_style.text_color_valid or deck_card_count_style.text_color_invalid
	
	local card_cp_valid = not enigma.managers.deck_planner:is_cp_over_max(deck)
	local deck_card_cp_style = self._widgets_by_name.deck_cp_count.style.deck_cp_count
	deck_card_cp_style.text_color = card_cp_valid and deck_card_cp_style.text_color_valid or deck_card_cp_style.text_color_invalid

	local delete_deck_button = self._widgets_by_name.delete_deck_button
	delete_deck_button.content.disable_button = deck.prebuilt
	delete_deck_button.content.visible = not deck.prebuilt

	local equip_deck_button = self._widgets_by_name.equip_deck_button
	local equipped_deck_text = self._widgets_by_name.equipped_deck_text
	local equipped = enigma.managers.deck_planner:equipped_deck() == deck
	equip_deck_button.content.visible = not equipped
	equipped_deck_text.content.visible = equipped
end

EnigmaDeckEditorUI.update_deck_cards_ui = function(self)
	local deck = enigma.managers.deck_planner.editing_deck
	local cards = deck.cards

	for i=1, MAX_CARDS_IN_DECK do
		local widget_name = "deck_slot_"..i
		local widget = self._widgets_by_name[widget_name]
		local card = cards[i]
		if card then
			local card_defined = type(card) == "table"
			
			widget.content.visible = true
			widget.content.card_name = card_defined and card.name or card
			widget.content.card_cost = card_defined and card.cost or ""
			widget.style.card_rarity.color = card_defined and card_ui_common.rarity_colors[card.rarity] or card_ui_common.rarity_colors[enigma.CARD_RARITY.common]
		else
			widget.content.visible = false
		end
	end
end

EnigmaDeckEditorUI.card_matches_filter = function(self, card, filters_query)
	local show_hidden_checkbox = self._widgets_by_name.show_hidden_cards
	if not show_hidden_checkbox.content.checked and (card.card_type == enigma.CARD_TYPE.chaos or card.hide_in_deck_editor) then
		return false
	end

	if self.name_search then
		local card_name_lower = card.name:lower()
		local search_lower = self.name_search:lower()
		if not card_name_lower:find(search_lower) then
			return false
		end
	end
	if filters_query.rarity and card.rarity ~= filters_query.rarity then
		return false
	end
	if filters_query.cost == 5 and card.cost < 5 then
		return false
	elseif filters_query.cost and card.cost ~= filters_query.cost then
		return false
	end
	if filters_query.type and card.card_type ~= filters_query.type then
		return false
	end
	if filters_query.pack and card.card_pack and card.card_pack.id ~= filters_query.pack then
		return false
	end
	if filters_query.keyword then
		local keyword = filters_query.keyword
		if keyword == "auto" then
			if #card.auto_descriptions == 0 then
				return false
			end
		elseif keyword == "condition" then
			if #card.condition_descriptions == 0 then
				return false
			end
		elseif keyword == "retain" then
			if #card.retain_descriptions == 0 then
				return false
			end
		elseif not card[keyword] then
			return false
		end
	end
	return true
end

local alphabet_card_comparator = function(card_1, card_2)
	return alphabet_comparator(card_1.name:lower(), card_2.name:lower())
end

EnigmaDeckEditorUI.update_filtered_cards = function(self)
	table.clear(self.filtered_cards)

	local filters_query = self._widgets_by_name.filters.content.query
	self._widgets_by_name.filters.content.query_dirty = false

	for _,card_template in pairs(enigma.managers.card_template.card_templates) do
		if self:card_matches_filter(card_template, filters_query) then
			table.insert(self.filtered_cards, card_template)
		end
	end

	table.sort(self.filtered_cards, alphabet_card_comparator)

	self.num_pages = math.ceil(#self.filtered_cards / TOTAL_CARD_TILES)
	self.current_page = math.min(self.current_page, self.num_pages)

	self:update_card_tiles_ui()
end

EnigmaDeckEditorUI.update_card_tiles_ui = function(self)
	local start_offset = (self.current_page - 1) * TOTAL_CARD_TILES
	for i=1, TOTAL_CARD_TILES do
		local card_scenegraph_id = "card_"..i
		local card = self.filtered_cards[start_offset + i]
		card_ui_common.update_card_display_if_needed(self.ui_renderer, self.ui_scenegraph, self._widgets_by_name, card_scenegraph_id, card, CARD_TILE_WIDTH)
	end

	if self.current_page == 0 and self.num_pages > 0 then
		self.current_page = 1
	end

	local pagination_text = enigma:localize("page_count", self.current_page, self.num_pages)
	local pagination_widget = self._widgets_by_name.pagination_panel
	pagination_widget.content.page_text = pagination_text
	
	local page_left_button = self._widgets_by_name.page_left_button
	local page_right_button = self._widgets_by_name.page_right_button

	page_left_button.content.disable_button = self.current_page <= 1
	page_right_button.content.disable_button = self.current_page >= self.num_pages
end