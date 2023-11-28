local enigma = get_mod("Enigma")

local uim = {}
enigma.managers.user_interaction = uim

uim.card_mode = false

uim.toggle_card_mode = function()

end

uim.try_draw_card = function(self)
    enigma.managers.game:draw_card()
end

uim.try_play_card_from_hand = function(self, card_index)
    enigma.managers.game:try_play_card_from_hand(card_index)
end

-- Keybind callbacks
enigma.card_mode_key_pressed = function()
    if enigma.managers.game:is_in_game() then
        
    else
        local deck_editor_ui = Managers.ui._ingame_ui.views.enigma_deck_editor
        if deck_editor_ui and deck_editor_ui.active then
            Managers.ui:handle_transition("close_active", {})
        else
            Managers.ui:handle_transition("deck_editor_view", {})
        end
    end
end

enigma.play_card_1_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_play_card_from_hand(1)
end
enigma.play_card_2_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_play_card_from_hand(2)
end
enigma.play_card_3_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_play_card_from_hand(3)
end
enigma.play_card_4_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_play_card_from_hand(4)
end
enigma.play_card_5_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_play_card_from_hand(5)
end

enigma.draw_card_key_pressed = function()
    local interaction = enigma.managers.user_interaction
    if not interaction.card_mode then
        return
    end
    interaction:try_draw_card()
end