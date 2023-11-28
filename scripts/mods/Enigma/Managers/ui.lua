local enigma = get_mod("Enigma")

dofile("scripts/mods/Enigma/ui/deck_editor_ui")

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
    deck_editor_view = function(self, params)
        if not enigma.managers.deck_planner.editing_deck then
            enigma:echo("Could not open the Deck Editor UI, you are not currently editing a deck.")
            return
        end
        self.menu_active = true
        self.current_view = "enigma_deck_editor"
    end
}

local handle_custom_transition = function(ingame_ui_context, new_transition, params)
    fassert(uim.transitions[new_transition], "Missing Enigma transition to %s", new_transition)

	local blocked_transitions = ingame_ui_context.blocked_transitions

	if blocked_transitions and blocked_transitions[new_transition] then
		return
	end

	local previous_transition = ingame_ui_context._previous_transition

	if not ingame_ui_context:is_transition_allowed(new_transition) or previous_transition and previous_transition == new_transition then
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
    return result
end)

enigma:hook(DLCUtils, "merge", function(func, dlc_fields, table)
    if dlc_fields == "ui_transitions" then
        enigma:echo("We can successfully hoiok DLCUtils.merge!")
    end
end)