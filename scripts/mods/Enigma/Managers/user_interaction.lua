local enigma = get_mod("Enigma")

local uim = {
    card_mode_show_mode = enigma:get("card_mode_show_mode"),
    hide_card_mode_on_card_play = enigma:get("hide_card_mode_on_card_play")
}
enigma.managers.user_interaction = uim

-- Keybind callbacks
local forbid_keybinds = function()
    return enigma.text_input_focused or Managers.chat and Managers.chat:chat_is_focused()
end

enigma.draw_card_hotkey_pressed = function()
    if forbid_keybinds() then return end
    enigma.managers.game:try_draw_card()
end

enigma.card_mode_key_pressed = function(down)
    if forbid_keybinds() then return end
    if enigma.managers.game:is_in_game() then
        if uim.card_mode_show_mode == "toggle" then
            if down then
                enigma.card_mode = not enigma.card_mode
            end
        else
            enigma.card_mode = down
        end
    elseif down then
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
        if not enigma.card_mode then
            return
        end
        enigma.managers.game:try_play_card_from_hand(i, false, "manual")
        if uim.hide_card_mode_on_card_play then
            enigma.card_mode = false
        end
    end
    enigma[quick_hotkey_func_name] = function()
        if forbid_keybinds() then return end
        enigma.managers.game:try_play_card_from_hand(i, false, "manual")
        if uim.hide_card_mode_on_card_play then
            enigma.card_mode = false
        end
    end
end

uim.on_setting_changed = function(self, setting_id)
    if setting_id == "card_mode_show_mode" then
        self.card_mode_show_mode = enigma:get("card_mode_show_mode")
    elseif setting_id == "hide_card_mode_on_card_play" then
        self.hide_card_mode_on_card_play = enigma:get("hide_card_mode_on_card_play")
    end
end
enigma:register_mod_event_callback("on_setting_changed", uim, "on_setting_changed")