local enigma = get_mod("Enigma")

enigma.VERSION = "1.2"

Wwise.load_bank("wwise/mods/Enigma/Enigma")

enigma.managers = {}

enigma.random_seed = os.clock() * 10000 % 1000


-- DEBUG SETTINGS
enigma.skip_deck_validity_check = enigma:get("skip_deck_validity_check")
-----------------

local mod_event_callbacks = {
    on_all_mods_loaded = {},
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
    else
        enigma:warning("Tried registering mod event callback for "..tostring(event)..", but the given table does not contain a function by the name \""..tostring(callback).."\"")
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
dofile("scripts/mods/Enigma/Managers/sound")
dofile("scripts/mods/Enigma/Managers/buff")
dofile("scripts/mods/Enigma/Managers/event")
dofile("scripts/mods/Enigma/Managers/warp")
dofile("scripts/mods/Enigma/Managers/card_pack")
dofile("scripts/mods/Enigma/Managers/card_template")
dofile("scripts/mods/Enigma/Managers/deck_planner")
dofile("scripts/mods/Enigma/Managers/mod_interaction")
dofile("scripts/mods/Enigma/Managers/user_interaction")
dofile("scripts/mods/Enigma/Managers/card_game")
dofile("scripts/mods/Enigma/Managers/deus")
dofile("scripts/mods/Enigma/Managers/ui")
dofile("scripts/mods/Enigma/Managers/debug")

dofile("scripts/mods/Enigma/GameLogic/target_selection_utils")
dofile("scripts/mods/Enigma/GameLogic/player_movement")
dofile("scripts/mods/Enigma/GameLogic/controlled_unit_templates")
dofile("scripts/mods/Enigma/GameLogic/ai_commander_extension")
dofile("scripts/mods/Enigma/GameLogic/bt_teleport_to_commander_action")


-- Process all requested network lookup values that card pack mods told us about
-- This allows these mods to add network lookups without requiring players to
-- make sure their mod load order is correct between Card Packs
local add_registered_network_lookups = function()
    local modified_tables = {}
    local mod_names = {}
    for name,_ in pairs(enigma.managers.mod.network_lookups) do
        table.insert(mod_names, name)
    end
    table.sort(mod_names)
    for _,name in ipairs(mod_names) do
        for _,data in ipairs(enigma.managers.mod.network_lookups[name]) do
            local lookup_table = data.lookup_table
            local index = #lookup_table + 1
            lookup_table[index] = data.value
            lookup_table[data.value] = index
            modified_tables[lookup_table] = true
        end
    end
    enigma.managers.mod.network_lookups = nil -- Don't need this anymore

    enigma:info("CARD PACK MODS MODIFIED NETWORK LOOKUP TABLES:")
    for tbl,_ in pairs(modified_tables) do
        enigma:dump(tbl, "MODIFIED NETWORK LOOKUP TABLE", 1)
    end
end

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

local hud_component_list_definitions_to_append_to = {
    ["scripts/ui/hud_ui/component_list_definitions/hud_component_list_adventure"] = "scripts/mods/Enigma/ui/hud_component/hud_component_list_adventure",
    ["scripts/ui/hud_ui/component_list_definitions/hud_component_list_deus"] = "scripts/mods/Enigma/ui/hud_component/hud_component_list_deus",
    ["scripts/ui/hud_ui/component_list_definitions/hud_component_list_inn_deus"] = "scripts/mods/Enigma/ui/hud_component/hud_component_list_inn_deus",
    ["scripts/mods/Peregrinaje/ui/hud_component_list_deus"] = "scripts/mods/Enigma/ui/hud_component/Peregrinaje/hud_component_list_deus",
    ["scripts/mods/Peregrinaje/ui/hud_component_list_inn_deus"] = "scripts/mods/Enigma/ui/hud_component/Peregrinaje/hud_component_list_inn_deus",
    
    ["scripts/ui/hud_ui/component_list_definitions/hud_component_list_map_deus"] = "scripts/mods/Enigma/ui/hud_component/hud_component_list_map_deus",
    ["scripts/mods/Peregrinaje/ui/hud_component_list_map_deus"] = "scripts/mods/Enigma/ui/hud_component/Peregrinaje/hud_component_list_map_deus"
}
enigma:hook(IngameHud, "_setup_component_definitions", function(func, self, hud_component_list_path)
    return func(self, hud_component_list_definitions_to_append_to[hud_component_list_path] or hud_component_list_path)
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
    elseif manager == "warp" then
        enigma.managers.warp:dump()
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
    add_registered_network_lookups()
    process_prebuilt_deck_registrations()
    add_test_deck()
    
    for _,v in pairs(mod_event_callbacks.on_all_mods_loaded) do
        v.executor[v.callback](v.executor)
    end

    enigma:echo("Enigma Version: "..enigma.VERSION)
end

-- Commands
enigma:command("card_showcase", "Showcase an Enigma card", function(card_id)
    if not card_id then
        enigma.managers.ui:hide_big_card()
        return
    end
    local card = enigma.managers.card_template:get_card_from_id(card_id)
    if not card then
        enigma:echo("Could not find card with id: "..tostring(card_id))
        return
    end
    enigma.managers.ui:show_big_card(card, true)
end)

enigma._command_toggle = function(self, args)
    local toggle_cmd = args[2]
    if not toggle_cmd then
        enigma:echo("Must provide another argument for enigma toggle")
        return
    end
    if toggle_cmd == "deck_validity_check" then
        if enigma.skip_deck_validity_check then
            enigma:echo("Turning deck validity check ON")
        else
            enigma:echo("Turning deck validity check OFF")
        end
        enigma:set("skip_deck_validity_check", not enigma.skip_deck_validity_check, true)
    elseif toggle_cmd == "noclip" then
        local local_player_unit = enigma:local_player_unit()
        if not local_player_unit then
            return
        end
        enigma.debug_noclip = not enigma.debug_noclip
        if enigma.debug_noclip then
            enigma:apply_no_clip_filter(local_player_unit, "enigma_testing_noclip", true, true, true, true, true, true)
        else
            enigma:remove_no_clip_filter(local_player_unit, "enigma_testing_noclip")
        end
    end
end

enigma:network_register("enigma_dev_game", function(sender, state)
    if state == "start" then
        if enigma.managers.game:is_in_game() then
            enigma:echo("Enigma dev game requested start, but already in a game!")
            return
        end
        local game_init_data = enigma.managers.deck_planner.game_init_data
        enigma:echo("Initializing Enigma TEST game with\nDeck: "..tostring(game_init_data.deck_name).."\nHost: "..tostring(game_init_data.is_server))
        enigma.managers.game:init_game(game_init_data, true)
    elseif state == "end" then
        enigma.managers.game:end_game()
    end
end)
enigma._command_force = function(self, args)
    local force_cmd = args[2]
    if not force_cmd then
        enigma:echo("Must provide another argument for enigma force")
        return
    end
    if force_cmd == "start" then
        enigma:network_send("enigma_dev_game", "all", "start")
    elseif force_cmd == "end" then
        enigma:network_send("enigma_dev_game", "all", "end")
    end
end

enigma._command_paste = function(self, args)
    local configure_target = args[2]
    if configure_target == "warp" then
        local json = tostring(Clipboard.get())
        local data = cjson.decode(json)
        if not data then
            enigma:echo("Invalid json data to configure warp settings")
            return
        end
        for key,val in pairs(data) do
            enigma.managers.warp[key] = val
        end
        enigma:dump(enigma.managers.warp, "WARP MANAGER", 3)
    end
end
enigma._command_set = function(self, args)
    local set_target = args[2]
    if set_target == "seed" then
        local seed = args[3] and tonumber(args[3])
        if not seed then
            enigma:echo("Must provide a seed value")
            return
        end
        enigma.random_seed = seed
        enigma:echo("Enigma random seed set to "..tostring(seed))
    end
end

enigma:command("enigma", "", function(...)
    local args = table.pack(...)
    local cmd = args[1]
    local command_function = enigma["_command_"..tostring(cmd)]
    if command_function then
        command_function(enigma, args)
    else
        enigma:echo("No such command \""..tostring(cmd).."\"")
    end
end)


-- Mod Events
enigma.update = function(dt)
    for _,v in pairs(mod_event_callbacks.update) do
        v.executor[v.callback](v.executor, dt, Managers.time:time("game"))
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
