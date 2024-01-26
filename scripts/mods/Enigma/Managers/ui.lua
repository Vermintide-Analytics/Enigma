local enigma = get_mod("Enigma")

dofile("scripts/mods/Enigma/ui/deck_editor_ui")
dofile("scripts/mods/Enigma/ui/deck_list_ui")

local uim = {
    big_card_to_display = nil,
	big_card_related_card_1 = nil,
	big_card_related_card_2 = nil,

	hud_data = {
		hand_indexes_just_removed = {
			false,
			false,
			false,
			false,
			false
		},
	},
	card_mode_ui_data = {
		hand_indexes_just_removed = {
			false,
			false,
			false,
			false,
			false
		}
	},
	
	time_since_draw_pile_action_invalid = 100,
	time_since_available_draw_action_invalid = 100,
	time_since_warpstone_cost_action_invalid = 100,
	time_since_hand_size_action_invalid = 100,

	time_since_card_played = 0,
	played_cards_queue = {},

	gamepad_button_texture_data = {
		confirm_press = {
			size = { 34, 34 },
			texture_xbone = "xbone_button_icon_a",
			texture_ps4 = "ps4_button_icon_cross"
		},
		back = {
			size = { 34, 34 },
			texture_xbone = "xbone_button_icon_b",
			texture_ps4 = "ps4_button_icon_circle"
		},
		special_1_press = {
			size = { 34, 34 },
			texture_xbone = "xbone_button_icon_x",
			texture_ps4 = "ps4_button_icon_square"
		},
		refresh_press = {
			size = { 34, 34 },
			texture_xbone = "xbone_button_icon_y",
			texture_ps4 = "ps4_button_icon_triangle"
		},

		move_down_raw = {
			size = { 33, 33 },
			texture_xbone = "xbone_button_icon_d_pad_down",
			texture_ps4 = "ps4_button_icon_d_pad_down"
		},
		move_right_raw = {
			size = { 33, 33 },
			texture_xbone = "xbone_button_icon_d_pad_right",
			texture_ps4 = "ps4_button_icon_d_pad_right"
		},
		move_left_raw = {
			size = { 33, 33 },
			texture_xbone = "xbone_button_icon_d_pad_left",
			texture_ps4 = "ps4_button_icon_d_pad_left"
		},
		move_up_raw = {
			size = { 33, 33 },
			texture_xbone = "xbone_button_icon_d_pad_up",
			texture_ps4 = "ps4_button_icon_d_pad_up"
		},
		
		left_stick_press = {
			size = { 32, 33 },
			texture_xbone = "xbone_button_icon_left_stick",
			texture_ps4 = "ps4_button_icon_left_stick"
		},
		right_stick_press = {
			size = { 32, 33 },
			texture_xbone = "xbone_button_icon_right_stick",
			texture_ps4 = "ps4_button_icon_right_stick"
		},
		
		cycle_previous = {
			size = { 36, 26 },
			texture_xbone = "xbone_button_icon_lb",
			texture_ps4 = "ps4_button_icon_l1"
		},
		cycle_next = {
			size = { 36, 26 },
			texture_xbone = "xbone_button_icon_rb",
			texture_ps4 = "ps4_button_icon_r1"
		},
		
		trigger_cycle_previous = {
			size = { 38, 33 },
			texture_xbone = "xbone_button_icon_lt",
			texture_ps4 = "ps4_button_icon_l2"
		},
		trigger_cycle_next = {
			size = { 38, 33 },
			texture_xbone = "xbone_button_icon_rt",
			texture_ps4 = "ps4_button_icon_r2"
		},
	},
}
enigma.managers.ui = uim

uim.show_big_card = function(self, card, showcase)
    self.big_card_to_display = card
	self.big_card_showcase_mode = showcase
	if card.related_cards then
		local id_1 = card.related_cards[1]
		local id_2 = card.related_cards[2]
		self.big_card_related_card_1 = enigma.managers.card_template:get_card_from_id(id_1)
		self.big_card_related_card_2 = enigma.managers.card_template:get_card_from_id(id_2)
	else
		self.big_card_related_card_1 = nil
		self.big_card_related_card_2 = nil
	end
end

uim.hide_big_card = function(self)
    self.big_card_to_display = nil
	self.big_card_related_card_1 = nil
	self.big_card_related_card_2 = nil
end

uim.show_deck_editor = function(self)
    self.show_deck_editor = true
end

uim.hide_deck_editor = function(self)
    self.show_deck_editor = false
end

uim.enable_chat_ui = function(self)
	GameSettingsDevelopment.allow_chat_input = true
end
uim.disable_chat_ui = function(self)
	GameSettingsDevelopment.allow_chat_input = false
end

uim.text_input_focused = function(self)
	enigma.text_input_focused = true
	uim.disable_chat_ui()
end
uim.text_input_lost_focus = function(self)
	enigma.text_input_focused = false
	uim.enable_chat_ui()
end

local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

uim.transitions = {
    deck_planner_view = function(self, params)
        if params.stop_editing then
            enigma.managers.deck_planner:set_editing_deck_by_name(nil)
        else
            local forced_deck = params.deck_name and enigma.managers.deck_planner.decks[params.deck_name]
            if forced_deck then
                enigma.managers.deck_planner:set_editing_deck_by_name(forced_deck.name)
            end
        end
        if enigma.managers.deck_planner.editing_deck then
            self.current_view = "enigma_deck_editor"
        else
            self.current_view = "enigma_deck_list"
        end
    end
}

local handle_custom_transition = function(ingame_ui_context, new_transition, params)
    fassert(uim.transitions[new_transition], "Missing Enigma transition to %s", new_transition)

	local blocked_transitions = ingame_ui_context.blocked_transitions

	if blocked_transitions and blocked_transitions[new_transition] then
		return
	end

	if not ingame_ui_context:is_transition_allowed(new_transition) then
		return
	end

	if ingame_ui_context.new_transition_old_view then
		return
	end

	params = params or {}
	local old_view = ingame_ui_context.current_view

	uim.transitions[new_transition](ingame_ui_context, params)

	local new_view = ingame_ui_context.current_view
	local force_open = params.force_open

	if old_view ~= new_view or force_open then
		if ingame_ui_context.views[old_view] then
			if ingame_ui_context.views[old_view].on_exit then
				printf("[IngameUI] menu view on_exit %s", old_view)
				ingame_ui_context.views[old_view]:on_exit(params)

				ingame_ui_context.views[old_view].exit_to_game = nil
			end

			local old_params = ingame_ui_context.transition_params
			local on_exit_callback = old_params and old_params.on_exit_callback

			if on_exit_callback then
				on_exit_callback()
			end
		end

		if new_view and ingame_ui_context.views[new_view] and ingame_ui_context.views[new_view].on_enter then
			printf("[IngameUI] menu view on_enter %s", new_view)
			ingame_ui_context.views[new_view]:on_enter(params)
		end

		ingame_ui_context.new_transition = new_transition
		ingame_ui_context.new_transition_old_view = old_view
		ingame_ui_context.transition_params = params
		ingame_ui_context._previous_transition = new_transition
	end
end

enigma:hook(IngameUI, "handle_transition", function(func, self, new_transition, params)
    if uim.transitions[new_transition] then
        return handle_custom_transition(self, new_transition, params)
    end
    return func(self, new_transition, params)
end)

enigma:hook(IngameUI, "setup_views", function(func, self, ingame_ui_context)
    local result = func(self, ingame_ui_context)
    self.views.enigma_deck_editor = EnigmaDeckEditorUI:new(ingame_ui_context)
    self.views.enigma_deck_list = EnigmaDeckListUI:new(ingame_ui_context)
    return result
end)


local DEFAULT_KILL_FEED_HORIZONTAL_OFFSET = 0
local DEFAULT_KILL_FEED_VERTICAL_OFFSET = 0
local kill_feed_scenegraph_node = nil
local kill_feed_offset_horizontal = enigma:get("kill_feed_offset_horizontal") * 19.2
local kill_feed_offset_vertical = enigma:get("kill_feed_offset_vertical") * 10.8
local update_kill_feed_ui_offset = function()
	if not kill_feed_scenegraph_node then
		return
	end
	kill_feed_scenegraph_node.position[1] = DEFAULT_KILL_FEED_HORIZONTAL_OFFSET + kill_feed_offset_horizontal
	kill_feed_scenegraph_node.position[2] = DEFAULT_KILL_FEED_VERTICAL_OFFSET + kill_feed_offset_vertical
end

local DEFAULT_COIN_UI_HORIZONTAL_OFFSET = 0
local DEFAULT_COIN_UI_VERTICAL_OFFSET = 0
local deus_coin_ui_scenegraph_node = nil
local deus_coin_ui_offset_horizontal = enigma:get("deus_coins_offset_horizontal") * 19.2
local deus_coin_ui_offset_vertical = enigma:get("deus_coins_offset_vertical") * 10.8
local update_deus_coin_ui_offset = function()
	if not deus_coin_ui_scenegraph_node then
		return
	end
	deus_coin_ui_scenegraph_node.position[1] = DEFAULT_COIN_UI_HORIZONTAL_OFFSET + deus_coin_ui_offset_horizontal
	deus_coin_ui_scenegraph_node.position[2] = DEFAULT_COIN_UI_VERTICAL_OFFSET + deus_coin_ui_offset_vertical
end
reg_hook_safe(IngameHud, "_compile_component_list", function(self, ingame_ui_context, component_definitions)
	local components = self._components
	if components then
		if components.PositiveReinforcementUI then
			kill_feed_scenegraph_node = components.PositiveReinforcementUI.ui_scenegraph.pivot
			DEFAULT_KILL_FEED_HORIZONTAL_OFFSET = kill_feed_scenegraph_node.position[1]
			DEFAULT_KILL_FEED_VERTICAL_OFFSET = kill_feed_scenegraph_node.position[2]
			update_kill_feed_ui_offset()
		end
		if components.DeusSoftCurrencyIndicatorUI then
			deus_coin_ui_scenegraph_node = components.DeusSoftCurrencyIndicatorUI._ui_scenegraph.coin_ui
			DEFAULT_COIN_UI_HORIZONTAL_OFFSET = deus_coin_ui_scenegraph_node.position[1]
			DEFAULT_COIN_UI_VERTICAL_OFFSET = deus_coin_ui_scenegraph_node.position[2]
			update_deus_coin_ui_offset()
		end
	end
end, "enigma_ui_compile_component_list")

-- Events
uim.update = function(self, dt)
	self.time_since_draw_pile_action_invalid = self.time_since_draw_pile_action_invalid + dt
	self.time_since_available_draw_action_invalid = self.time_since_available_draw_action_invalid + dt
	self.time_since_warpstone_cost_action_invalid = self.time_since_warpstone_cost_action_invalid + dt
	self.time_since_hand_size_action_invalid = self.time_since_hand_size_action_invalid + dt
end
enigma:register_mod_event_callback("update", uim, "update")

uim.on_setting_changed = function(self, setting_id)
	if setting_id == "kill_feed_offset_horizontal" then
		kill_feed_offset_horizontal = enigma:get(setting_id) * 19.2
		update_kill_feed_ui_offset()
	elseif setting_id == "kill_feed_offset_vertical" then
		kill_feed_offset_vertical = enigma:get(setting_id) * 10.8
		update_kill_feed_ui_offset()
	elseif setting_id == "deus_coins_offset_horizontal" then
		deus_coin_ui_offset_horizontal = enigma:get(setting_id) * 19.2
		update_deus_coin_ui_offset()
	elseif setting_id == "deus_coins_offset_vertical" then
		deus_coin_ui_offset_vertical = enigma:get(setting_id) * 10.8
		update_deus_coin_ui_offset()
	end
end
enigma:register_mod_event_callback("on_setting_changed", uim, "on_setting_changed")

-- DEBUG
local function draw_border(gui, pos, size, color, border)
	border = border or 5
	pos = pos + Vector3(0, 0, 1)
	local w = size[1]
	local h = size[2] - 2 * border

	Gui.rect(gui, Vector3(pos[1], pos[2], pos[3]), Vector2(w, border), color)
	Gui.rect(gui, Vector3(pos[1], pos[2] + size[2] - border, pos[3]), Vector2(w, border), color)
	Gui.rect(gui, Vector3(pos[1], pos[2] + border, pos[3]), Vector2(border, h), color)
	Gui.rect(gui, Vector3(pos[1] + size[1] - border, pos[2] + border, pos[3]), Vector2(border, h), color)
end
local function debug_render_scenegraph(ui_renderer, scenegraph, n_scenegraph, force_draw_depth)
	local cursor = Mouse.axis(Mouse.axis_id("cursor"))
	local inside_box = math.point_is_inside_2d_box
	local gui = Debug.gui
	force_draw_depth = force_draw_depth - 1
	local border = 4

	for i = 1, n_scenegraph do
		local node = scenegraph[i]
		local pos = node.world_position
		local size = node.size

		if size[2] > 0 and (force_draw_depth >= 0 or inside_box(cursor, pos, size)) then
			local name = node.name
			local label = string.format("%s (%d,%d,%d)[%d,%d]", name, pos[1], pos[2], pos[3], size[1], size[2])
			local posV3 = Vector3(pos[1], pos[2], pos[3])
			local hue = tonumber(string.sub(Application.make_hash(name), 8), 16) / 4294967296.0
			local r, g, b = Colors.hsl2rgb(hue, 0.75, 0.5)

			Gui.rect(gui, posV3, Vector2(size[1], size[2]), Color(20, r, g, b))

			Gui.text(gui, label, "materials/fonts/arial", 16, nil, posV3 + Vector2(border, border), Color(200, r, g, b), "shadow", Color(200, 0, 0, 0))
			draw_border(gui, posV3, size, Color(50, r, g, b), border)

			local children = node.children

			if children then
				debug_render_scenegraph(ui_renderer, children, #children, force_draw_depth)
			end
		end
	end
end
enigma:hook_origin(UISceneGraph, "debug_render_scenegraph", function(ui_renderer, scenegraph, force_draw_depth)
	return debug_render_scenegraph(ui_renderer, scenegraph, #scenegraph, force_draw_depth or 1)
end)
