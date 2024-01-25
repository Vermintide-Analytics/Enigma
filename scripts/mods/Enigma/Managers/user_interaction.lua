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
    enigma.managers.game:draw_card(true)
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
    elseif down and not enigma:in_morris_map() then
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
        local played = enigma.managers.game:play_card_from_hand(i, false, "manual")
        if played and uim.hide_card_mode_on_card_play then
            enigma.card_mode = false
        end
    end
    enigma[quick_hotkey_func_name] = function()
        if forbid_keybinds() then return end
        local played = enigma.managers.game:play_card_from_hand(i, false, "manual")
        if played and uim.hide_card_mode_on_card_play then
            enigma.card_mode = false
        end
    end
end

local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

reg_hook_safe(StateInGameRunning, "on_enter", function(self, params)
    local controller_input_service = Managers.input:get_service("enigma_controller_support")
    if not controller_input_service then
        Managers.input:create_input_service("enigma_controller_support", "IngameMenuKeymaps", "IngameMenuFilters")
        Managers.input:map_device_to_service("enigma_controller_support", "gamepad")
    end
end, "enigma_controller_support_ingame_enter")

uim.gamepad_play_card_bindings = {
    enigma:get("gamepad_play_1_button"),
    enigma:get("gamepad_play_2_button"),
    enigma:get("gamepad_play_3_button"),
    enigma:get("gamepad_play_4_button"),
    enigma:get("gamepad_play_5_button"),
}
uim.gamepad_card_mode_button = enigma:get("gamepad_card_mode_button")
uim.gamepad_draw_card_button = enigma:get("gamepad_draw_card_button")

uim.update = function(self, dt)
    if enigma.managers.game:is_in_game() then
        local gamepad_active = Managers.input and Managers.input:is_device_active("gamepad")
        if gamepad_active then
            local input_service = Managers.input:get_service("enigma_controller_support")

            if enigma.card_mode then
                for i=1,5 do
                    if input_service:get(self.gamepad_play_card_bindings[i]) then
                        enigma["play_"..i.."_hotkey_pressed"]()
                    end
                end
            end

            if input_service:get(self.gamepad_card_mode_button) then
                enigma.card_mode = not enigma.card_mode
            end

            if input_service:get(self.gamepad_draw_card_button) then
                enigma.managers.game:draw_card(true)
            end
        end
    end
end
enigma:register_mod_event_callback("update", uim, "update")

uim.on_setting_changed = function(self, setting_id)
    if setting_id == "card_mode_show_mode" then
        self.card_mode_show_mode = enigma:get("card_mode_show_mode")
    elseif setting_id == "hide_card_mode_on_card_play" then
        self.hide_card_mode_on_card_play = enigma:get("hide_card_mode_on_card_play")
    elseif setting_id == "gamepad_card_mode_button" then
        self.gamepad_card_mode_button = enigma:get(setting_id)
    elseif setting_id == "gamepad_draw_card_button" then
        self.gamepad_draw_card_button = enigma:get(setting_id)
    else
        for i=1,5 do
            if setting_id == "gamepad_play_"..i.."_button" then
                self.gamepad_play_card_bindings[i] = enigma:get(setting_id)
            end
        end
    end
end
enigma:register_mod_event_callback("on_setting_changed", uim, "on_setting_changed")