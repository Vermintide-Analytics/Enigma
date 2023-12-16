local enigma = get_mod("Enigma")

enigma.VERSION = "IN DEV"

enigma.managers = {}

enigma.random_seed = 12345 -- The same password I have on my luggage


-- DEBUG SETTINGS
enigma.skip_deck_validity_check = enigma:get("skip_deck_validity_check")
enigma.mega_resource_start = enigma:get("mega_resource_start")
-----------------

local mod_event_callbacks = {
    update = {},
    on_unload = {},
    on_game_state_changed = {},
    on_setting_changed = {},
    on_user_joined = {},
    on_user_left = {}
}
enigma.register_mod_event_callback = function(self, event, executor, callback)
    if mod_event_callbacks[event] then
        table.insert(mod_event_callbacks[event], { executor = executor, callback = callback})
    end
end
enigma.unregister_mod_event_callback = function(self, event, executor, callback)
    if mod_event_callbacks[event] then
        local index = 0
        for k,v in pairs(mod_event_callbacks[event]) do
            if v.executor == executor and v.callback == callback then
                index = k
                break
            end
        end
        table.remove(mod_event_callbacks[event], index)
    end
end

dofile("scripts/mods/Enigma/Constants")
dofile("scripts/mods/Enigma/Util")

dofile("scripts/mods/Enigma/Managers/hook")
dofile("scripts/mods/Enigma/Managers/buff")
dofile("scripts/mods/Enigma/Managers/event")
dofile("scripts/mods/Enigma/Managers/warp")
dofile("scripts/mods/Enigma/Managers/card_pack")
dofile("scripts/mods/Enigma/Managers/card_template")
dofile("scripts/mods/Enigma/Managers/deck_planner")
dofile("scripts/mods/Enigma/Managers/mod_interaction")
dofile("scripts/mods/Enigma/Managers/user_interaction")
dofile("scripts/mods/Enigma/Managers/card_game")
dofile("scripts/mods/Enigma/Managers/ui")
dofile("scripts/mods/Enigma/Managers/debug")

enigma.queued_prebuilt_decks = {}
local process_prebuilt_deck_registrations = function()
    if not enigma.queued_prebuilt_decks then
        return
    end

    for i, v in ipairs(enigma.queued_prebuilt_decks) do
        enigma.managers.deck_planner:create_prebuilt_deck(v.mod_id, v.name, v.game_mode, v.cards)
    end

    enigma.queued_prebuilt_decks = nil -- We don't need this anymore, as any decks can now be registered immediately instead of being deferred via the queue
end

enigma:hook(IngameHud, "_setup_component_definitions", function(func, self, hud_component_list_path)
    if hud_component_list_path == "scripts/ui/hud_ui/component_list_definitions/hud_component_list_adventure" then
        return func(self, "scripts/mods/Enigma/hud_component_list_enigma")
    end
    return func(self, hud_component_list_path)
end)

enigma:command("warpstone_toggle", "test", function()
    enigma.show_warpstone = not enigma.show_warpstone
end)

enigma:command("enigma_dump", "dump some Enigma info to the console", function(manager)
    if not manager then
        enigma.managers.mod:dump()
        enigma.managers.card_pack:dump()
        enigma.managers.card_template:dump()
        enigma.managers.deck_planner:dump()
        enigma.managers.game:dump()
    elseif manager == "mod" then
        enigma.managers.mod:dump()
    elseif manager == "card_pack" then
        enigma.managers.card_pack:dump()
    elseif manager == "card_template" then
        enigma.managers.card_template:dump()
    elseif manager == "deck_planner" then
        enigma.managers.deck_planner:dump()
    elseif manager == "game" or manager == "card_game" then
        enigma.managers.game:dump()
    end
end)

-- Register base card pack
dofile("scripts/mods/Enigma/CardPacks/Base")



local add_test_deck = function()
    enigma.managers.deck_planner:create_prebuilt_deck("Enigma", "The Enigma", "adventure", {
        "base/long_rest",
        "base/warpstone_pie",
        "base/wrath_of_khorne",
        "base/executioner",
        "base/spartan",
        "base/warp_flesh",
        "base/retreat",
        "base/stolen_bell",
        "base/cyclone_strike",
        "base/cyclone_strike",
        "base/cyclone_strike",
        "base/caffeinated",
        "base/expertise",
        "base/gym_rat",
        "base/tough_skin",
        "base/warpfire_strikes",
        "base/warpfire_strikes",
        "base/warpfire_strikes",
        "base/caffeinated",
        "base/expertise",
        "base/gym_rat",
        "base/tough_skin",
        "base/warpfire_strikes",
        "base/warpfire_strikes",
        "base/warpfire_strikes"
    })
end

enigma.on_all_mods_loaded = function()

    process_prebuilt_deck_registrations()
    add_test_deck()

    enigma:echo("Enigma Version: "..enigma.VERSION)
end

-- Commands
enigma:command("big_card", "show a big card!", function(card_id)
    if not card_id then
        enigma.managers.ui.big_card_to_display = nil
        return
    end
    local card = enigma.managers.card_template:get_card_from_id(card_id)
    if not card then
        enigma:echo("Could not find card with id: "..tostring(card_id))
        return
    end
    enigma.managers.ui.big_card_to_display = card
end)

enigma:command("enigma", "", function(cmd)
    if cmd == "toggle_deck_validity_check" then
        if enigma.skip_deck_validity_check then
            enigma:echo("Turning deck validity check ON")
        else
            enigma:echo("Turning deck validity check OFF")
        end
        enigma:set("skip_deck_validity_check", not enigma.skip_deck_validity_check, true)
    elseif cmd == "toggle_mega_resources" then
        if enigma.mega_resource_start then
            enigma:echo("Turning mega resource start OFF")
        else
            enigma:echo("Turning mega resource start ON")
        end
        enigma:set("mega_resource_start", not enigma.mega_resource_start, true)
    end
end)

-- Mod Events
enigma.update = function(dt)
    for _,v in pairs(mod_event_callbacks.update) do
        v.executor[v.callback](v.executor, dt)
    end
end

enigma.on_unload = function(exit_game)
    for _,v in pairs(mod_event_callbacks.on_unload) do
        v.executor[v.callback](v.executor, exit_game)
    end
end

enigma.on_game_state_changed = function(status, state_name)
    for _,v in pairs(mod_event_callbacks.on_game_state_changed) do
        v.executor[v.callback](v.executor, status, state_name)
    end
end

enigma.on_setting_changed = function(setting_id)
    for _,v in pairs(mod_event_callbacks.on_setting_changed) do
        v.executor[v.callback](v.executor, setting_id)
    end

    -- DEV
    if setting_id == "skip_deck_validity_check" then
        enigma.skip_deck_validity_check = enigma:get("skip_deck_validity_check")
        enigma.managers.deck_planner:update_self_equipped_deck_valid()
    elseif setting_id == "mega_resource_start" then
        enigma.mega_resource_start = enigma:get("mega_resource_start")
    end
end

enigma.on_user_joined = function(player)
    for _,v in pairs(mod_event_callbacks.on_user_joined) do
        v.executor[v.callback](v.executor, player)
    end
end

enigma.on_user_left = function(player)
    for _,v in pairs(mod_event_callbacks.on_user_left) do
        v.executor[v.callback](v.executor, player)
    end
end
