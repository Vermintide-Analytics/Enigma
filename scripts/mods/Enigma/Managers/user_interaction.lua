local enigma = get_mod("Enigma")

local uim = {}
enigma.managers.user_interaction = uim

uim.card_mode = false

uim.try_draw_card = function(self)
    enigma.managers.game:draw_card()
end

-- Keybind callbacks
local forbid_keybinds = function()
    return enigma.text_input_focused or Managers.chat and Managers.chat:chat_is_focused()
end

enigma.draw_card_hotkey_pressed = function()
    if forbid_keybinds() then return end
    local success, fail_reason = enigma.managers.game:try_draw_card()
    if not success then
        enigma:echo("Could not draw card because: "..tostring(fail_reason))
    else
        enigma:echo("Successfully drew a card")
    end
end

enigma.card_mode_key_pressed = function()
    if forbid_keybinds() then return end
    if enigma.managers.game:is_in_game() then
        
    else
        local deck_list_ui = Managers.ui._ingame_ui.views.enigma_deck_list
        local deck_editor_ui = Managers.ui._ingame_ui.views.enigma_deck_editor
        if deck_editor_ui and deck_editor_ui.active or deck_list_ui and deck_list_ui.active then
            Managers.ui:handle_transition("close_active", {})
        else
            Managers.ui:handle_transition("deck_planner_view", {})
        end
    end
end

for i=1,5 do
    local hotkey_func_name = "play_"..i.."_hotkey_pressed"
    local quick_hotkey_func_name = "quick_"..hotkey_func_name
    enigma[hotkey_func_name] = function()
        if forbid_keybinds() then return end
        if not uim.card_mode then
            return
        end
        enigma.managers.game:try_play_card_from_hand(i, false, "manual")
    end
    enigma[quick_hotkey_func_name] = function()
        if forbid_keybinds() then return end
        enigma.managers.game:try_play_card_from_hand(i, false, "manual")
    end
end