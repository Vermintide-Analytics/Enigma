local enigma = get_mod("Enigma")

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

enigma:command("enigmadump", "dump some Enigma info to the console", function(manager)
    if not manager then
        enigma.managers.mod_interaction:dump()
        enigma.managers.card_pack:dump()
        enigma.managers.card_template:dump()
        enigma.managers.deck_planner:dump()
        enigma.managers.game:dump()
    elseif manager == "mod_interaction" then
        enigma.managers.mod_interaction:dump()
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
    enigma.managers.deck_planner:create_prebuilt_deck("Enigma", "Enigma Test Deck", "adventure", {
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
end

-- Commands
enigma:command("new_empty_deck", "make a new empty deck", function(name, game_mode)
    if not name then
        enigma:echo("Must provide a deck name")
        return
    end
    if not game_mode then
        local level_key = enigma:level_key()
        if level_key == "inn_level" then
            game_mode = "adventure"
        elseif level_key == "morris_hub" then
            game_mode = "deus"
        end
    end
    if not game_mode then
        enigma:echo("Must provide a game mode (adventure/deus)")
        return
    end
    if not enigma:is_game_mode_supported(game_mode) then
        enigma:echo("Game mode not supported")
        return
    end
    local new_deck = enigma.managers.deck_planner:create_empty_deck(name, game_mode)
    if new_deck then
        enigma.managers.deck_planner:set_editing_deck(new_deck.name)
        enigma:echo("New deck created, now editing it")
    end
end)

enigma:command("edit_deck", "select a deck to edit", function(deck_name)
    local deck = enigma.managers.deck_planner:set_editing_deck(deck_name)
    if not deck then
        enigma:echo("No longer editing a deck")
    else
        enigma:echo("Now editing "..deck_name)
    end
end)

enigma:command("edit_equipped_deck", "", function()
    local deck = enigma.managers.deck_planner:equipped_deck()
    if not deck then
        enigma:echo("No deck equipped")
        return
    end
    deck = enigma.managers.deck_planner:set_editing_deck(deck.name)
    if not deck then
        enigma:echo("Could not edit equipped deck")
        return
    end
    enigma:echo("Editing deck: "..deck.name)
end)

enigma:command("add_card", "add a card to currently editing deck", function(card_id)
    local success = enigma.managers.deck_planner:add_card_to_editing_deck(card_id)
    if success then
        enigma:echo(card_id.." added")
    end
end)

enigma:command("remove_card", "remove a card from currently editing deck", function(card_id)
    local success = enigma.managers.deck_planner:remove_card_from_editing_deck(card_id)
    if success then
        enigma:echo(card_id.." removed")
    end
end)

enigma:command("equip_deck", "equip the currently editing deck", function()
    local success = enigma.managers.deck_planner:equip_deck_for_current_career_and_game_mode(enigma.managers.deck_planner.editing_deck.name)
    if success then
        enigma:echo("Deck equipped")
    end
end)

enigma:command("unequip_deck", "unequip the currently equipped deck for current game-mode and career", function()
    local success = enigma.managers.deck_planner:unequip_deck_for_current_career_and_game_mode()
    if success then
        enigma:echo("Deck unequipped")
    end
end)

enigma:command("delete_deck", "delete a deck by name", function(deck_name, force)
    local success
    if force then
        success = enigma.managers.deck_planner:delete_deck(deck_name)
    else
        success = enigma.managers.deck_planner:force_delete_deck(deck_name)
    end
    if success then
        enigma:echo("Deck deleted")
    end
end)

enigma:command("rename_deck", "rename deck", function(deck_name)
    local success = enigma.managers.deck_planner:rename_deck(deck_name)
    if success then
        enigma:echo("Deck renamed")
    end
end)

enigma:command("list_decks", "", function()
    local deck_count = 0
    enigma:echo("Decks ("..deck_count.."):")
    for name,deck in pairs(enigma.managers.deck_planner.decks) do
        enigma:echo(" "..name)
        deck_count = deck_count + 1
    end
    enigma:echo("Total decks: "..deck_count)
end)

enigma:command("equipped_deck", "", function()
    local deck = enigma.managers.deck_planner:equipped_deck()
    if not deck then
        enigma:echo("No deck equipped")
        return
    end
    
    enigma:echo("Equipped deck: "..deck.name)
end)

enigma:command("print_deck", "print deck to chat", function(deck_name)
    local deck = enigma.managers.deck_planner.editing_deck
    if deck_name then
        deck = enigma.managers.deck_planner.decks[deck_name]
    end
    if not deck then
        enigma:echo("No deck to print")
    end
    enigma:echo(enigma.managers.deck_planner:deck_tostring(enigma.managers.deck_planner.editing_deck))
end)

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