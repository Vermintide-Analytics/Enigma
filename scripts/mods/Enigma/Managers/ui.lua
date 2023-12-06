local enigma = get_mod("Enigma")

dofile("scripts/mods/Enigma/ui/deck_editor_ui")
dofile("scripts/mods/Enigma/ui/deck_list_ui")

local uim = {
    big_card_to_display = nil,
}
enigma.managers.ui = uim

uim.show_big_card = function(self, card)
    self.big_card_to_display = card
end

uim.hide_big_card = function(self)
    self.big_card_to_display = nil
end

uim.show_deck_editor = function(self)
    self.show_deck_editor = true
end

uim.hide_deck_editor = function(self)
    self.show_deck_editor = false
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
