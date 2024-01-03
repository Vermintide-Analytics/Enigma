local enigma = get_mod("Enigma")
local sound = enigma.managers.sound

local safe = function(func, ...)
    return enigma:pcall(func, ...)
end

local net = {
    sync_card_game_init_data = "sync_card_game_init_data",
    sync_players_and_units_set = "sync_players_and_units_set",
    event_card_drawn = "event_card_drawn",
    event_card_played = "event_card_played",
    event_card_discarded = "event_card_discarded",
    event_card_shuffled_into_draw_pile = "event_card_shuffled_into_draw_pile",
    event_new_card_shuffled_into_draw_pile = "event_new_card_shuffled_into_draw_pile",
    broadcast_pacing_intensity = "broadcast_pacing_intensity",
    notify_card_condition_met_changed = "notify_card_condition_met_changed",
    notify_card_auto_condition_met_changed = "notify_card_auto_condition_met_changed",
    request_play_card = "request_play_card",
    sync_level_progress = "sync_level_progress",
    sync_card_property = "sync_card_property",
    invoke_card_rpc = "invoke_card_rpc",
    sync_player_accumulated_stagger = "sync_player_accumulated_stagger",
    sync_card_game_property = "sync_card_game_property"
}

local cgm = {
    local_data = {},
    peer_data = {},

    data_by_unit = {},

    level_progress_card_draw = {
        adventure = 15,
        deus = 9
    }
}
cgm.local_data = nil -- Initialize as table then set to null to shut up the Lua diagnostics complaining about accessing fields from nil
enigma.managers.game = cgm

-------------
-- LOGGING --
-------------
local format_card_event_log = function(card, event, remote_peer_id)
    local context = remote_peer_id ~= enigma:local_peer_id() and "Peer: "..tostring(remote_peer_id) or "local"
    return "["..context.."] "..event.." "..card.id
end
local format_drawing_card = function(card, remote_peer_id)
    return format_card_event_log(card, "DRAWING", remote_peer_id)
end
local format_playing_card = function(card, remote_peer_id, warpstone_payed)
    return format_card_event_log(card, "PLAYING", remote_peer_id).." Warpstone payed: "..tostring(warpstone_payed)
end
local format_discarding_card = function(card, remote_peer_id)
    return format_card_event_log(card, "DISCARDING", remote_peer_id)
end
local format_shuffling_card_into_draw_pile = function(card, remote_peer_id)
    return format_card_event_log(card, "SHUFFLING INTO DRAW PILE", remote_peer_id)
end

local format_card_identification = function(peer_id, id)
    return tostring(peer_id).."."..tostring(id)
end

---------------------------
-- DIFFICULTY ADJUSTMENT --
---------------------------
local chaos_card_difficulty_weight = {
    [enigma.CARD_RARITY.common] = 3,
    [enigma.CARD_RARITY.rare] = 5,
    [enigma.CARD_RARITY.epic] = 8,
    [enigma.CARD_RARITY.legendary] = 14
}
local chaos_card_rarity_weight_distribution_center = {
    [enigma.CARD_RARITY.common] = 0,
    [enigma.CARD_RARITY.rare] = 33,
    [enigma.CARD_RARITY.epic] = 67,
    [enigma.CARD_RARITY.legendary] = 100
}
local get_chaos_card_rarity_weight = function(rarity, added_difficulty)
    local x = (added_difficulty - chaos_card_rarity_weight_distribution_center[rarity])/20
    local exp = (x * x) / -2
    return math.pow(1.5, exp)
end
local add_chaos_cards_based_on_added_difficulty = function(card_ids)
    local added_cards = 0
    local chaos_cards = {
        [enigma.CARD_RARITY.common] = {},
        [enigma.CARD_RARITY.rare] = {},
        [enigma.CARD_RARITY.epic] = {},
        [enigma.CARD_RARITY.legendary] = {}
    }
    for _,card in pairs(enigma.managers.card_template.card_templates) do
        if card.card_type == enigma.CARD_TYPE.chaos then
            table.insert(chaos_cards[card.rarity], card)
        end
    end
    local added_difficulty = enigma:get("added_difficulty")
    while added_difficulty > 0 do
        local selected_rarity = nil

        local common_weight = get_chaos_card_rarity_weight(enigma.CARD_RARITY.common, added_difficulty)
        local rare_weight = get_chaos_card_rarity_weight(enigma.CARD_RARITY.rare, added_difficulty)
        local epic_weight = get_chaos_card_rarity_weight(enigma.CARD_RARITY.epic, added_difficulty)
        local legendary_weight = get_chaos_card_rarity_weight(enigma.CARD_RARITY.legendary, added_difficulty)
        local total_weight = common_weight + rare_weight + epic_weight + legendary_weight

        if enigma:test_chance(common_weight / total_weight) then
            selected_rarity = enigma.CARD_RARITY.common
        else
            total_weight = total_weight - common_weight
        end
        if not selected_rarity and enigma:test_chance(rare_weight / total_weight) then
            selected_rarity = enigma.CARD_RARITY.rare
        else
            total_weight = total_weight - rare_weight
        end
        if not selected_rarity and enigma:test_chance(epic_weight / total_weight) then
            selected_rarity = enigma.CARD_RARITY.epic
        end
        selected_rarity = selected_rarity or enigma.CARD_RARITY.legendary

        enigma:info("Selected rarity: "..tostring(selected_rarity).." : value of "..tostring(chaos_card_difficulty_weight[selected_rarity]))
        enigma:info("Added difficulty: "..tostring(added_difficulty).." -> "..tostring(added_difficulty - chaos_card_difficulty_weight[selected_rarity]))
        added_difficulty = added_difficulty - chaos_card_difficulty_weight[selected_rarity]

        if #chaos_cards[selected_rarity] > 0 then
            local selected_chaos_card = chaos_cards[selected_rarity][enigma:random_range_int(1, #chaos_cards[selected_rarity])]
            table.insert(card_ids, selected_chaos_card.id)
            added_cards = added_cards + 1
            enigma:info("ADDED CHAOS CARD TO DECK: "..tostring(selected_chaos_card.id))
        end
    end
    enigma:info("TOTAL CHAOS CARDS ADDED: "..tostring(added_cards))
end


----------------
-- LOCAL UTIL --
----------------
local get_card_index_in_pile = function(pile, card)
    local ind
    for i,v in ipairs(pile) do
        if v == card then
            ind = i
            break
        end
    end
    return ind
end

local get_card_location = function(card)
    if card.location then
        return card.location, get_card_index_in_pile(card.context[card.location], card)
    end
    if card.just_removed_from_location then
        return card.just_removed_from_location, card.just_removed_from_index
    end
    enigma:warning("Could not find location and index for "..tostring(card.id))
end

local remove_card_from_pile = function(data, location, card)
    local ind = 0
    for i,v in ipairs(data[location]) do
        if v == card then
            ind = i
            break
        end
    end
    table.remove(data[location], ind)
    card.location = nil
    card.just_removed_from_location = location
    card.just_removed_from_index = ind
end

local add_card_to_pile = function(data, location, card, insert_index)
    if insert_index then
        table.insert(data[location], insert_index, card)
    else
        table.insert(data[location], card)
    end
    card.location = location
    card.just_removed_from_location = nil
    card.just_removed_from_index = nil
end

local invoke_card_event_callbacks = function(cards, func_name, ...)
    for _,other_card in ipairs(cards) do
        if other_card[func_name] then
            local func = other_card[func_name]
            func(other_card, ...)
        end
    end
end
local invoke_card_event_callbacks_for_all_piles = function(data, func_name, ...)
    invoke_card_event_callbacks(data.draw_pile, func_name, ...)
    invoke_card_event_callbacks(data.hand, func_name, ...)
    invoke_card_event_callbacks(data.discard_pile, func_name, ...)
end

local set_card_can_pay_warpstone = function(card)
    local final_card_cost, card_cost_modifier = enigma.managers.buff:get_final_warpstone_cost(card)
    local can_pay = enigma.managers.warp:can_pay_cost(final_card_cost, card_cost_modifier)
    if card.can_pay_warpstone ~= can_pay then
        card:set_dirty()
    end
    card.can_pay_warpstone = can_pay
end

cgm.init_game = function(self, game_init_data, debug)
    enigma:info("Initializing Enigma game")
    self.is_server = game_init_data.is_server
    self.debug = debug
    self.game_state = "initializing"

    local card_ids = {}
    for _,template in ipairs(game_init_data.cards) do
        table.insert(card_ids, template.id)
    end
    add_chaos_cards_based_on_added_difficulty(card_ids)
    enigma:shuffle(card_ids)
    
    local local_data = {
        deck_name = game_init_data.deck_name,
        deck_card_ids = card_ids,

        all_cards = {},
        next_card_local_id = 1,

        draw_pile = {},
        hand = {},
        discard_pile = {},
        out_of_play_pile = {},

        active_duration_cards = {},

        _card_draw_gain_rate = 0,
        available_card_draws = 0,
        card_draw_gain_multiplier = 1,

        peer_id = Network.peer_id(),
    }

    local_data.available_card_draws = enigma.mega_resource_start and 99 or local_data.available_card_draws
    local_data.deferred_card_draws = 0

    if self.is_server then
        local_data.accumulated_stagger = {
            trash = 0,
            elite = 0,
            special = 0,
            boss = 0
        }
    end

    self.furthest_level_progress = 0

    local card_manager = enigma.managers.card_template
    for _,card_id in ipairs(card_ids) do
        local card_template = card_manager:get_card_from_id(card_id)
        local card = card_template:instance(local_data)
        
        table.insert(local_data.draw_pile, card)
        if self.is_server then
            enigma.managers.event:_add_card_server_event_callbacks(card)
        end
        enigma.managers.event:_add_card_local_event_callbacks(card)
    end

    self.local_data = local_data

    self.statistics = {
        earned_card_draw = {
            passive = 0,
            level_progress = 0,
            debug = 0,
            other = 0
        },
        cards_drawn = 0,
        cards_played = {
            manual = 0,
            auto = 0
        },
        cards_discarded = {
            manual = 0,
            auto = 0
        }
    }

    enigma:register_mod_event_callback("update", self, "_init_update")
end

enigma:network_register(net.sync_card_game_init_data, function(peer_id, deck_name, card_ids_in_deck)
    local peer_data = {
        deck_name = deck_name,

        all_cards = {},
        next_card_local_id = 1,

        draw_pile = {},
        hand = {},
        discard_pile = {},
        out_of_play_pile = {},

        active_duration_cards = {},

        peer_id = peer_id,
    }

    if cgm.is_server then
        peer_data.accumulated_stagger = {
            trash = 0,
            elite = 0,
            special = 0,
            boss = 0
        }
    end

    local missing_packs = {}
    local card_manager = enigma.managers.card_template
    for _,card_id in ipairs(card_ids_in_deck) do
        local card_template = card_manager:get_card_from_id(card_id)
        if not card_template then
            table.insert(peer_data.draw_pile, card_id)
            local missing_pack = card_manager:get_pack_id_from_card_id(card_id)
            if missing_pack then
                table.insert(missing_packs, missing_pack)
            end
        end
        local card = card_template:instance(peer_data)
        if card.condition_local and not card.condition_server then
            card.condition_server_met = true
        end
        if card.auto_condition_local and not card.auto_condition_server then
            card.auto_condition_server_met = true
        end
        card.owner = peer_id
        card.original_owner = card.owner
        table.insert(peer_data.draw_pile, card)
        if cgm.is_server then
            enigma.managers.event:_add_card_server_event_callbacks(card)
        end
        enigma.managers.event:_add_card_remote_event_callbacks(card)
    end
    if #missing_packs > 0 then
        local pack_list = table.concat(missing_packs, ", ")
        enigma:chat_whisper(peer_id, "A player is missing the following card packs, and some cards may not work properly: (".. pack_list..")")
    end

    cgm.peer_data[peer_id] = peer_data
    enigma:info("peer_data["..tostring(peer_id).."] set")
    enigma:dump(peer_data, "NEW PEER DATA", 0)

    if cgm.game_state == "syncing" then
        if cgm.expecting_sync_from_peers[peer_id] then
            cgm.expecting_sync_from_peers[peer_id] = false
            enigma:info("Received initialization sync from peer: "..tostring(peer_id))
        elseif cgm.expecting_sync_from_peers[peer_id] == false then
            enigma:warning("Received DUPLICATE initialization sync from peer: "..tostring(peer_id))
        end
        local any_left_to_sync = false
        for _,expecting_sync in pairs(cgm.expecting_sync_from_peers) do
            any_left_to_sync = any_left_to_sync or expecting_sync
        end
        if not any_left_to_sync then
            cgm:start_game()
        end
    else
        enigma:info("Received initialization sync from peer: "..tostring(peer_id))
        enigma:info("We have not reached our point of syncing out yet, but that is ok!")
    end
end)
cgm._init_update = function(self, dt)
    if self.game_state ~= "initializing" then
        enigma:unregister_mod_event_callback("update", self, "_init_update")
        return
    end

    local all_players_spawned = Managers.matchmaking and Managers.matchmaking:are_all_players_spawned()
    local others_actually_ingame = false
    if all_players_spawned then
        -- Don't bother evaluating this unless all players have spawned
        local network_manager = Managers.state and Managers.state.network
        others_actually_ingame = network_manager.profile_synchronizer and network_manager.profile_synchronizer:others_actually_ingame()
    end

    if all_players_spawned and others_actually_ingame then
        enigma:info("Syncing Enigma game")
        self.game_state = "syncing"
        self.expecting_sync_from_peers = {}
        -- Peers includes ourselves
        local peers = Managers.matchmaking.lobby:members():get_members()
        
        local num_others_not_yet_synced = 0
        for i = 1, #peers do
            if peers[i] ~= enigma:local_peer_id() and not self.peer_data[peers[i]] then
                enigma:info(" - "..tostring(peers[i]))
                num_others_not_yet_synced = num_others_not_yet_synced + 1
                self.expecting_sync_from_peers[peers[i]] = true
            end
        end
        
        enigma:info("Attempting to send RPC sync_card_game_init_data")
        enigma:network_send(net.sync_card_game_init_data, "others", self.local_data.deck_name, self.local_data.deck_card_ids)

        if num_others_not_yet_synced > 0 then
            enigma:info("Expecting syncs from the above "..tostring(num_others_not_yet_synced).." more peers:")
        else
            enigma:info("ALL PLAYERS HAVE SPAWNED: Since there are no other players that have not already synced with us, starting Enigma now")
            self:start_game()
        end
    end
end

cgm.start_game = function(self)
    if self.game_state ~= "syncing" then
        enigma:echo("Enigma attempted to start a game before initialization and syncing with other players")
        return
    end
    enigma:info("Starting Enigma game")
    self.game_state = "in_progress"
    self.game_mode = enigma:game_mode()
    
    enigma.managers.sound:start_game()
    enigma.managers.warp:start_game(self.game_mode)
    for _,card in ipairs(self.local_data.draw_pile) do
        set_card_can_pay_warpstone(card)
    end

    self.server_peer_id = Managers.mechanism:server_peer_id()
    local player_manager = Managers.player
    local local_player = player_manager:player_from_peer_id(enigma:local_peer_id())
    enigma:info("Setting local player and unit data")
    self.local_data.player = local_player
    self.local_data.unit = local_player.player_unit
    self.data_by_unit[local_player.player_unit] = self.local_data
    enigma.managers.buff:_register_player(local_player)
    enigma:dump(self.local_data, "LOCAL DATA", 0)
    for peer_id,peer_data in pairs(self.peer_data) do
        local player = player_manager:player_from_peer_id(peer_id)
        enigma:info("Setting peer player and unit data for "..tostring(peer_id))
        peer_data.player = player
        peer_data.unit = player.player_unit
        self.data_by_unit[player.player_unit] = peer_data
        enigma:dump(peer_data, "PEER DATA "..tostring(peer_id), 0)
        enigma.managers.buff:_register_player(player)
    end
    enigma:info("Finished setting player and unit data for all players")
    for _,card in ipairs(self.local_data.draw_pile) do
        if card.on_game_start_local then
            if self.is_server and card.on_game_start_server then
                safe(card.on_game_start_server, card)
            end
            safe(card.on_game_start_local, card)
        end
    end

    for _,card in ipairs(self.local_data.draw_pile) do
        if card.on_game_start_local then
            if self.is_server and card.on_game_start_server then
                safe(card.on_game_start_server, card)
            end
            safe(card.on_game_start_local, card)
        end
    end

    for _,peer_data in pairs(self.peer_data) do
        for _,card in ipairs(peer_data.draw_pile) do
            if self.is_server and card.on_game_start_server then
                safe(card.on_game_start_server, card)
            end
            if card.on_game_start_remote then
                safe(card.on_game_start_local, card)
            end
        end
    end

    if self.is_server then
        self.sync_accumulated_stagger_interval = 3
        self.time_until_sync_accumulated_stagger = self.sync_accumulated_stagger_interval

        self.conflict = Managers.state.conflict
        self.pacing = self.conflict.pacing
        self.pacing_intensity = 0
        self.broadcast_pacing_intensity_interval = 5
        self.time_until_broadcast_pacing_intensity = self.broadcast_pacing_intensity_interval

        self.broadcast_level_progress_interval = 5
        self.time_until_broadcast_level_progress = self.broadcast_level_progress_interval
        self.last_broadcast_level_progress = 0
    end

    self:draw_card(true)
    enigma:register_mod_event_callback("update", self, "update")
end

cgm.end_game = function(self)
    enigma:info("Ending Enigma game")
    enigma:dump(self.statistics, "ENIGMA END-OF-GAME STATISTICS", 5)
    self.game_state = nil
    self.local_data = nil
    self.peer_data = {}
    self.data_by_unit = {}
    self.is_server = nil
    self.conflict = nil
    self.pacing = nil
    self.pacing_intensity = nil
    self.broadcast_pacing_intensity_interval = nil
    self.time_until_broadcast_pacing_intensity = nil
    enigma:unregister_mod_event_callback("update", self, "update")
    enigma.managers.warp:end_game()
    enigma.managers.sound:end_game()
    enigma.managers.event:remove_all_card_event_callbacks()

    if self.debug then
        enigma.managers.buff:_reset_players()
    end
end


cgm.unable_to_play = function(self)
    return not self:is_in_game() or self.local_data.dead or self.local_data.waiting_for_rescue
end

----------
-- DRAW --
----------
local handle_card_drawn = function(context, data)
    local card = table.remove(data.draw_pile)
    enigma:info(format_drawing_card(card, data.peer_id))
    if cgm.is_server and card.on_draw_server then
        safe(card.on_draw_server, card)
    end
    local on_draw_func_name = "on_draw_"..context
    if card[on_draw_func_name] then
        safe(card[on_draw_func_name], card)
    end
    add_card_to_pile(data, enigma.CARD_LOCATION.hand, card)
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(data, "on_any_card_drawn_server", card)
    end
    local on_any_card_drawn_func_name = "on_any_card_drawn_"..context
    invoke_card_event_callbacks_for_all_piles(data, on_any_card_drawn_func_name, card)
    if cgm.is_server and card.on_location_changed_server then
        safe(card.on_location_changed_server, card, enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    local on_location_changed_func_name = "on_location_changed_"..context
    if card[on_location_changed_func_name] then
        safe(card[on_location_changed_func_name], card, enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    
    if card.sounds_3D.on_draw then
        sound:trigger_at_unit(card.sounds_3D.on_draw, data.unit)
    end
    return card
end
local handle_local_card_drawn = function(free)
    if not free then
        cgm.local_data.available_card_draws = cgm.local_data.available_card_draws - 1
    end
    local drawn_card = handle_card_drawn("local", cgm.local_data)
    if drawn_card.sounds_2D.on_draw then
        sound:trigger(drawn_card.sounds_2D.on_draw)
    end

    sound:trigger("draw_card")
    enigma:network_send(net.event_card_drawn, "others", drawn_card.local_id)

    cgm.statistics.cards_drawn = cgm.statistics.cards_drawn + 1
    return true
end
enigma:network_register(net.event_card_drawn, function(peer_id, expected_card_local_id)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        enigma:warning(tostring(peer_id).." TOLD US OF A CARD DRAW EVENT, BUT WE DON'T HAVE DATA FOR THAT PEER")
        return
    end
    local drawn_card = handle_card_drawn("remote", peer_data)
    if not drawn_card or not drawn_card.local_id == expected_card_local_id then
        enigma:warning("Unexpected card drawn from draw pile when syncing draw from "..tostring(peer_id))
        return
    end
end)
cgm.draw_card = function(self, free)
    if not self:is_in_game() then
        return false, "not_in_game"
    end
    if self:unable_to_play() then
        enigma:echo("Cannot draw cards at this time")
        return false, "dead"
    end
    if not free and self.local_data.available_card_draws < 1 then
        enigma.managers.ui.time_since_available_draw_action_invalid = 0
        return false, "not_enough_card_draw"
    end
    if #self.local_data.draw_pile < 1 then
        enigma.managers.ui.time_since_draw_pile_action_invalid = 0
        return false, "draw_pile_empty"
    end
    if #self.local_data.hand > 4 then
        enigma.managers.ui.time_since_hand_size_action_invalid = 0
        return false, "hand_full"
    end
    handle_local_card_drawn(free)
    return true
end

cgm.add_card_draw = function(self, gain, source)
    source = source or "other"
    self.local_data.available_card_draws = self.local_data.available_card_draws + gain
    self.statistics.earned_card_draw[source] = self.statistics.earned_card_draw[source] + gain
end


----------
-- PLAY --
----------
local handle_card_played = function(context, data, card, play_type, destination_index, net_x_cost)
    local location = card.location

    enigma:info(format_playing_card(card, data.peer_id, net_x_cost))

    local can_expend_charge = card.charges and card.charges > 1
    if not can_expend_charge then
        remove_card_from_pile(data, card.location, card)
    end

    if cgm.is_server and card.on_play_server then
        safe(card.on_play_server, card, play_type, net_x_cost)
    end
    local on_play_func_name = "on_play_"..context
    if card[on_play_func_name] then
        safe(card[on_play_func_name], card, play_type, net_x_cost)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(data, "on_any_card_played_server", card)
    end
    local any_card_played_func = "on_any_card_played_"..context
    invoke_card_event_callbacks_for_all_piles(data, any_card_played_func, card)

    card.times_played = card.times_played + 1
    if card.duration then
        table.insert(card.active_durations, 1, card.duration)
    end

    if card.sounds_3D.on_play then
        sound:trigger_at_unit(card.sounds_3D.on_play, data.unit)
    end
    if can_expend_charge then
        card.charges = card.charges - 1
        card:set_dirty()
        return enigma.CARD_LOCATION.hand
    else
        local destination_pile = enigma.CARD_LOCATION.discard_pile
        local inserted_index = nil
        if card.ephemeral then
            destination_pile = enigma.CARD_LOCATION.out_of_play_pile
        end

        if card.echo and not card.ephemeral then
            destination_pile = enigma.CARD_LOCATION.draw_pile
            if context == "local" then
                -- Generate random index to insert (also return that value so we can send it to peers)
                local draw_pile_size = #data.draw_pile
                inserted_index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))
                add_card_to_pile(data, enigma.CARD_LOCATION.draw_pile, card, inserted_index) -- Shuffle into draw pile
            else
                add_card_to_pile(data, enigma.CARD_LOCATION.draw_pile, card, destination_index) -- Insert into draw pile where we were told to
            end
        else
            add_card_to_pile(data, destination_pile, card)
        end
        if cgm.is_server and card.on_location_changed_server then
            safe(card.on_location_changed_server, card, location, destination_pile)
        end
        local on_location_changed_func_name = "on_location_changed_"..context
        if card[on_location_changed_func_name] then
            safe(card[on_location_changed_func_name], card, location, destination_pile)
        end
        return destination_pile, inserted_index
    end
end
local handle_local_card_played = function(card, location, index, skip_warpstone_cost, play_type)
    local final_card_cost, card_cost_modifier = enigma.managers.buff:get_final_warpstone_cost(card)
    if not skip_warpstone_cost and not enigma.managers.warp:can_pay_cost(final_card_cost, card_cost_modifier) then
        if play_type == "manual" then
            enigma.managers.ui.time_since_warpstone_cost_action_invalid = 0
        end
        return
    end
    local net_x_cost = nil
    if final_card_cost == "X" then
        final_card_cost = enigma.managers.warp.warpstone
        net_x_cost = final_card_cost - card_cost_modifier
    end
    if not skip_warpstone_cost then
        enigma.managers.warp:pay_cost(final_card_cost, "playing "..tostring(card.id))
    else
        enigma:info("Skipping warpstone cost for playing "..tostring(card.id))
    end
    
    local new_location, inserted_index = handle_card_played("local", cgm.local_data, card, play_type, nil, net_x_cost)
    if location == enigma.CARD_LOCATION.hand and location ~= new_location then
        enigma.managers.ui.hud_data.hand_indexes_just_removed[index] = true
        enigma.managers.ui.card_mode_ui_data.hand_indexes_just_removed[index] = true
    end
    if new_location == enigma.CARD_LOCATION.draw_pile then
        cgm:add_card_cost(card, 1)
    end
    if card.sounds_2D.on_play then
        sound:trigger(card.sounds_2D.on_play)
    end

    sound:trigger("play_card")
    enigma:network_send(net.event_card_played, "others", card.local_id, play_type, inserted_index, net_x_cost)
    cgm.statistics.cards_played[play_type] = cgm.statistics.cards_played[play_type] + 1
    return true
end
enigma:network_register(net.event_card_played, function(peer_id, card_local_id, play_type, destination_index, net_x_cost)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        enigma:warning(tostring(peer_id).." TOLD US OF A CARD PLAYED EVENT, BUT WE DON'T HAVE DATA FOR THAT PEER")
        return
    end
    local card = peer_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Could not find a card to be played with local ID "..format_card_identification(peer_id, card_local_id))
        return
    end
    handle_card_played("remote", peer_data, card, play_type, destination_index, net_x_cost)
end)
cgm._play_card_at_index_from_location = function(self, location, index, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if self:unable_to_play() then
        enigma:echo("Cannot play cards at this time")
        return false, "dead"
    end
    if not enigma.can_play_from_location(location) then
        enigma:warning("Cannot play cards from "..tostring(location))
        return false, "invalid_card_location"
    end
    if self.local_data.active_channel then
        enigma:info("Cannot play card, currently channeling")
        return false, "currently_channeling"
    end
    local card = self.local_data[location][index]
    if not card then
        if play_type == "manual" then 
            enigma.managers.ui.time_since_hand_size_action_invalid = 0
        else
            enigma:warning("Tried to automatically play card at index "..tostring(index).." in "..tostring(location)..", but that does not exist")
        end
        return false, "invalid_card"
    end

    if card.unplayable and play_type == "manual" then
        enigma:info("Cannot play unplayable card manually")
        return false, "card_unplayable"
    end

    if not card.condition_met then
        if play_type == "manual" then
            enigma:info("Could not play "..card.name..", condition not met")
        else
            enigma:debug("Attempted to automatically play "..card.name.." but condition not met")
        end
        return false, "card_condition_not_met"
    end

    local final_card_cost, card_cost_modifier = enigma.managers.buff:get_final_warpstone_cost(card)
    if not skip_warpstone_cost and not enigma.managers.warp:can_pay_cost(final_card_cost, card_cost_modifier) then
        if play_type == "manual" then
            enigma.managers.ui.time_since_warpstone_cost_action_invalid = 0
        end
        return false, "not_enough_warpstone"
    end

    if play_type ~= "auto" and card.channel and card.channel > 0 then
        self.local_data.active_channel = {
            card = card,
            total_duration = card.channel,
            remaining_duration = card.channel,
            play_type = play_type,
            skip_warpstone_cost = skip_warpstone_cost
        }
        sound:trigger("channel_start")
        return true, "channeling"
    end
    return handle_local_card_played(card, location, index, skip_warpstone_cost, play_type)
end

cgm.play_card_from_hand = function(self, card_index, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not self:is_in_game() then
        if play_type == "auto" then
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return false, "not_in_game"
    end
    if not self.local_data.hand[card_index] then
        if play_type == "manual" then 
            enigma.managers.ui.time_since_hand_size_action_invalid = 0
        else
            enigma:warning("Tried to automatically play card at index "..tostring(card_index).." from the hand, but that does not exist")
        end
        return false, "invalid_card"
    end

    return self:_play_card_at_index_from_location(enigma.CARD_LOCATION.hand, card_index, skip_warpstone_cost, play_type)
end

cgm.play_card_from_draw_pile = function(self, card_index, skip_warpstone_cost)
    if not self:is_in_game() then
        enigma:warning("Attempted to auto play a card from the draw pile when not in a game")
        return false, "not_in_game"
    end
    if type(card_index) ~= "number" then
        enigma:echo("Attempted to play card from draw pile using non-number index: " .. tostring(card_index))
        return false, "invalid_card"
    end
    if not self.local_data.draw_pile[card_index] then
        enigma:echo("Attempted to play card "..card_index.." from draw pile, but draw pile does not have a card at that index")
        return false, "invalid_card"
    end

    return self:_play_card_at_index_from_location(enigma.CARD_LOCATION.draw_pile, card_index, skip_warpstone_cost, "auto")
end

cgm.play_card = function(self, card, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not card then
        enigma:warning("Tried to play nil card")
        return false, "invalid_card"
    end
    if not self:is_in_game() then
        if play_type == "auto" then
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return false, "not_in_game"
    end
    if not enigma.can_play_from_location(card.location) then
        enigma:warning("Attempted to play a card from the "..tostring(card.location)..". This is not allowed")
        return false, "invalid_card_location"
    end
    local location, index = get_card_location(card)
    return self:_play_card_at_index_from_location(location, index, skip_warpstone_cost, play_type)
end


-------------
-- DISCARD --
-------------
local handle_card_discarded = function(context, data, card, discard_type)
    local location = card.location

    enigma:info(format_discarding_card(card, data.peer_id))

    remove_card_from_pile(data, location, card)
    if cgm.is_server and card.on_discard_server then
        safe(card.on_discard_server, card, discard_type)
    end
    local on_discard_func_name = "on_discard_"..context
    if card[on_discard_func_name] then
        safe(card[on_discard_func_name], card, discard_type)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(data, "on_any_card_discarded_server", card)
    end
    local on_any_card_discarded_func_name = "on_any_card_discarded_"..context
    invoke_card_event_callbacks_for_all_piles(data, on_any_card_discarded_func_name, card)

    local destination_pile = enigma.CARD_LOCATION.discard_pile
    add_card_to_pile(data, destination_pile, card)
    if cgm.is_server and card.on_location_changed_server then
        safe(card.on_location_changed_server, card, location, destination_pile)
    end
    local on_location_changed_func_name = "on_location_changed_"..context
    if card[on_location_changed_func_name] then
        safe(card[on_location_changed_func_name], card, location, destination_pile)
    end
    if card.sounds_3D.on_discard then
        sound:trigger_at_unit(card.sounds_3D.on_discard, data.unit)
    end
end
local handle_local_card_discarded = function(card, discard_type)
    handle_card_discarded("local", cgm.local_data, card, discard_type)
    if card.sounds_2D.on_discard then
        sound:trigger(card.sounds_2D.on_discard)
    end

    enigma:network_send(net.event_card_discarded, "others", card.local_id, discard_type)
    cgm.statistics.cards_discarded[discard_type] = cgm.statistics.cards_discarded[discard_type] + 1
    return true
end
enigma:network_register(net.event_card_discarded, function(peer_id, card_local_id, discard_type)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        enigma:warning(tostring(peer_id).." TOLD US OF A CARD DISCARDED EVENT, BUT WE DON'T HAVE DATA FOR THAT PEER")
        return
    end
    local card = peer_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Could not find a card to be discarded with local ID "..format_card_identification(peer_id, card_local_id))
        return
    end
    handle_card_discarded("remote", peer_data, card, discard_type)
end)
cgm.discard_card_from_hand = function(self, index, discard_type)
    if not self:is_in_game() then
        if discard_type == "auto" then
            enigma:warning("Attempted to auto discard a card when not in a game")
        end
        return false, "not_in_game"
    end
    discard_type = discard_type or "auto"
    local location = enigma.CARD_LOCATION.hand
    local card = self.local_data[location][index]
    if not card then
        if discard_type == "auto" then
            enigma:info("Attempted to discard card at index "..tostring(index).." from "..location.." which only contains "..#self.local_data[location][index].. " cards")
        end
        return false, "invalid_card"
    end
    handle_local_card_discarded(card, discard_type)
end
cgm.discard_card_from_draw_pile = function(self, index, discard_type)
    if not self:is_in_game() then
        if discard_type == "auto" then
            enigma:warning("Attempted to auto discard a card when not in a game")
        end
        return false, "not_in_game"
    end
    discard_type = discard_type or "auto"
    local location = enigma.CARD_LOCATION.draw_pile
    local card = self.local_data[location][index]
    if not card then
        if discard_type == "auto" then
            enigma:info("Attempted to discard card at index "..tostring(index).." from "..location.." which only contains "..#self.local_data[location][index].. " cards")
        end
        return false, "invalid_card"
    end
    handle_local_card_discarded(card, discard_type)
end
cgm.discard_card = function(self, card, discard_type)
    discard_type = discard_type or "auto"
    if not card then
        enigma:warning("Tried to discard nil card")
        return false, "invalid_card"
    end
    if not self:is_in_game() then
        if discard_type == "auto" then
            enigma:warning("Attempted to auto discard a card when not in a game")
        end
        return false, "not_in_game"
    end
    if not enigma.can_discard_from_location(card.location) then
        enigma:warning("Attempted to discard a card from the "..tostring(card.location)..". This is not allowed")
        return false, "invalid_card_location"
    end
    handle_local_card_discarded(card, discard_type)
    return true
end


----------------------------
-- SHUFFLE INTO DRAW PILE --
----------------------------
local handle_shuffle_new_card_into_draw_pile = function(context, data, card_id, index)
    local template = enigma.managers.card_template:get_card_from_id(card_id)
    if not template then
        enigma:warning("Could not add card to draw pile, card not defined. ("..card_id..")")
        return false, "invalid_card_id"
    end
    local card = template:instance(data)
    enigma:info(format_shuffling_card_into_draw_pile(card, data.peer_id))
    add_card_to_pile(data, enigma.CARD_LOCATION.draw_pile, card, index)
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        safe(card.on_shuffle_into_draw_pile_server, card)
    end
    local on_shuffle_into_draw_pile_func_name = "on_shuffle_into_draw_pile_"..context
    if card[on_shuffle_into_draw_pile_func_name] then
        safe(card[on_shuffle_into_draw_pile_func_name], card)
    end
end
local handle_local_shuffle_new_card_into_draw_pile = function(card_id)
    local draw_pile_size = #cgm.local_data.draw_pile
    local index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))

    -- Need to send the RPC which creates the new card in other players' games, otherwise we risk
    -- sending other RPCs specific to this card before they even know about it.
    enigma:network_send(net.event_new_card_shuffled_into_draw_pile, "others", card_id, index)
    handle_shuffle_new_card_into_draw_pile("local", cgm.local_data, card_id, index)
end
enigma:network_register(net.event_new_card_shuffled_into_draw_pile, function(peer_id, card_id, index)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        enigma:warning(tostring(peer_id).." TOLD US OF A NEW CARD SHUFFLED INTO DRAW PILE EVENT, BUT WE DON'T HAVE DATA FOR THAT PEER")
        return
    end
    handle_shuffle_new_card_into_draw_pile("remote", peer_data, card_id, index)
end)
cgm.shuffle_new_card_into_draw_pile = function(self, card_id)
    if not self:is_in_game() then
        return false, "not_in_game"
    end
    handle_local_shuffle_new_card_into_draw_pile(card_id)
    return true
end

local handle_shuffle_card_into_draw_pile = function(context, data, card, new_index)
    local location = card.location
    enigma:info(format_shuffling_card_into_draw_pile(card, data.peer_id))

    remove_card_from_pile(data, card.location, card)
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        safe(card.on_shuffle_into_draw_pile_server, card)
    end
    local on_shuffle_into_draw_pile_func_name = "on_shuffle_into_draw_pile_"..context
    if card[on_shuffle_into_draw_pile_func_name] then
        safe(card[on_shuffle_into_draw_pile_func_name], card)
    end

    add_card_to_pile(data, enigma.CARD_LOCATION.draw_pile, card)
    if cgm.is_server and card.on_location_changed_server then
        safe(card.on_location_changed_server, card, location, enigma.CARD_LOCATION.draw_pile)
    end
    local on_location_changed_func_name = "on_location_changed_"..context
    if card[on_location_changed_func_name] then
        safe(card[on_location_changed_func_name], card, location, enigma.CARD_LOCATION.draw_pile)
    end
end
local handle_local_shuffle_card_into_draw_pile = function(card)
    local draw_pile_size = #cgm.local_data.draw_pile
    local new_index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))

    handle_shuffle_card_into_draw_pile("local", cgm.local_data, card, new_index)

    enigma:network_send(net.event_card_shuffled_into_draw_pile, "others", card.local_id, new_index)
end
enigma:network_register(net.event_card_shuffled_into_draw_pile, function(peer_id, card_local_id, new_index)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        enigma:warning(tostring(peer_id).." TOLD US OF A CARD SHUFFLED INTO DRAW PILE EVENT, BUT WE DON'T HAVE DATA FOR THAT PEER")
        return
    end
    local card = peer_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Could not find a card to be shuffled into draw pile at "..format_card_identification(peer_id, card_local_id))
        return
    end
    handle_shuffle_card_into_draw_pile("remote", peer_data, card, new_index)
end)
cgm.shuffle_card_into_draw_pile = function(self, card)
    if not card then
        return false, "invalid_card"
    end
    if not self:is_in_game() then
        return false, "not_in_game"
    end
    handle_local_shuffle_card_into_draw_pile(card)
    
    return true
end

------------
-- UPDATE --
------------
enigma:network_register(net.notify_card_condition_met_changed, function(peer_id, card_local_id, satisfied)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card condition met changes")
        local card = cgm.local_data.all_cards[card_local_id]
        if card then
            enigma:warning("Attempted to set card playable: "..card.id)
        end
        return
    end
    local card = cgm.local_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Attempted to set card playable, invalid card local id "..tostring(card_local_id))
        return
    end
    card.cond_satisfied_server = satisfied
    card.cond_satisfied = card.cond_satisfied_server and ((card.cond_satisfied_local == nil) or card.cond_satisfied_local)
end)
enigma:network_register(net.notify_card_auto_condition_met_changed, function(peer_id, card_local_id, met)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card auto-trigger condition met changes")
        local card = cgm.local_data.all_cards[card_local_id]
        if card then
            enigma:warning("Attempted to set card auto met: "..card.id)
        end
        return
    end
    local card = cgm.local_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Attempted to set card auto met, invalid card local id "..tostring(card_local_id))
        return
    end
    card.auto_condition_server_met = met
end)
enigma:network_register(net.broadcast_pacing_intensity, function(peer_id, pacing_intensity)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us the current pacing intensity")
        return
    end
    cgm.pacing_intensity = pacing_intensity
    cgm:_update_card_draw_gain_rate()
end)
enigma:network_register(net.sync_level_progress, function(peer_id, progress)
    if progress <= cgm.furthest_level_progress then
        return
    end
    local new_progress = progress - cgm.furthest_level_progress

    enigma.managers.warp:_handle_level_progress_gained(new_progress)

    local gain = new_progress * cgm.level_progress_card_draw[cgm.game_mode]
    local local_unit = cgm.local_data.unit
    if local_unit then
        local custom_buffs = enigma.managers.buff.unit_custom_buffs[local_unit]
        if custom_buffs and custom_buffs.card_draw_multiplier then
            gain = gain * custom_buffs.card_draw_multiplier
        end
    end
    cgm.local_data.deferred_card_draws = cgm.local_data.deferred_card_draws + gain
    cgm.furthest_level_progress = progress

end)

cgm._handle_requested_card_play_from_ui = function(self, dt)
    local index_from_hand_to_play = enigma.managers.user_interaction.request_play_card_from_hand_next_update
    if index_from_hand_to_play then
        enigma.managers.user_interaction.request_play_card_from_hand_next_update = nil
        local played = enigma.managers.game:play_card_from_hand(index_from_hand_to_play, false, "manual")
        if played and enigma.managers.user_interaction.hide_card_mode_on_card_play then
            enigma.card_mode = false
        end
    end
end

cgm._update_active_channel = function(self, dt)
    if not self.local_data.active_channel then
        return
    end
    if self.local_data.active_channel.cancelled then
        self.local_data.previous_channel = self.local_data.active_channel
        self.local_data.active_channel = nil
        sound:trigger("channel_end")
        return
    end
    self.local_data.active_channel.remaining_duration = self.local_data.active_channel.remaining_duration - dt
    if self.local_data.active_channel.remaining_duration <= 0 then
        local card = self.local_data.active_channel.card
        local location, index = get_card_location(card)
        local skip_warpstone_cost = self.local_data.active_channel.skip_warpstone_cost
        local play_type = self.local_data.active_channel.play_type
        self.local_data.previous_channel = self.local_data.active_channel
        self.local_data.active_channel = nil
        sound:trigger("channel_end")
        handle_local_card_played(card, location, index, skip_warpstone_cost, play_type)
    end
end

cgm._run_local_card_updates = function(self, dt)
    if self:unable_to_play() then
        return
    end
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            if card.update_server then
                safe(card.update_server, card, dt)
            end
        end
        for _,card in ipairs(self.local_data.draw_pile) do
            if card.update_server then
                safe(card.update_server, card, dt)
            end
        end
        for _,card in ipairs(self.local_data.discard_pile) do
            if card.update_server then
                safe(card.update_server, card, dt)
            end
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        if card.update_local then
            safe(card.update_local, card, dt)
        end
    end
    for _,card in ipairs(self.local_data.draw_pile) do
        if card.update_local then
            safe(card.update_local, card, dt)
        end
    end
    for _,card in ipairs(self.local_data.discard_pile) do
        if card.update_local then
            safe(card.update_local, card, dt)
        end
    end
end
cgm._run_remote_card_updates = function(self, dt)
    if self.is_server then
        for _,peer_data in pairs(self.peer_data) do
            if not self:unable_to_play() then
                for _,card in ipairs(peer_data.hand) do
                    if card.update_server then
                        safe(card.update_server, card, dt)
                    end
                end
                for _,card in ipairs(peer_data.draw_pile) do
                    if card.update_server then
                        safe(card.update_server, card, dt)
                    end
                end
                for _,card in ipairs(peer_data.discard_pile) do
                    if card.update_server then
                        safe(card.update_server, card, dt)
                    end
                end
            end
        end
    end
    for _,peer_data in pairs(self.peer_data) do
        if not self:unable_to_play() then
            for _,card in ipairs(peer_data.hand) do
                if card.update_remote then
                    safe(card.update_remote, card, dt)
                end
            end
            for _,card in ipairs(peer_data.draw_pile) do
                if card.update_remote then
                    safe(card.update_remote, card, dt)
                end
            end
            for _,card in ipairs(peer_data.discard_pile) do
                if card.update_remote then
                    safe(card.update_remote, card, dt)
                end
            end
        end
    end
end

local _update_card_active_durations_for_cards = function(cards, dt)
    for _,card in ipairs(cards) do
        if card.active_durations then
            for i=1,#card.active_durations do
                card.active_durations[i] = card.active_durations[i] - dt
            end
            for i=#card.active_durations,1,-1 do
                if card.active_durations[i] <= 0 then
                    table.remove(card.active_durations, i)
                end
            end
        end
    end
end

cgm._update_local_card_active_durations = function(self, dt)
    _update_card_active_durations_for_cards(self.local_data.draw_pile, dt)
    _update_card_active_durations_for_cards(self.local_data.hand, dt)
    _update_card_active_durations_for_cards(self.local_data.discard_pile, dt)
end
cgm._update_remote_card_active_durations = function(self, dt)
    for _,peer_data in pairs(self.peer_data) do
        _update_card_active_durations_for_cards(peer_data.draw_pile, dt)
        _update_card_active_durations_for_cards(peer_data.hand, dt)
        _update_card_active_durations_for_cards(peer_data.discard_pile, dt)
    end
end

local set_card_condition_met = function(card, condition_met)
    if card.condition_met ~= condition_met then
        card:set_dirty()
    end
    card.condition_met = condition_met
end
cgm._evaluate_local_card_conditions = function(self)
    if self:unable_to_play() then
        return
    end
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            if card.condition_server then
                local success, met = safe(card.condition_server, card)
                card.condition_server_met = success and met
            else
                card.condition_server_met = true
            end
        end
        for _,card in ipairs(self.local_data.draw_pile) do
            if card.condition_server then
                local success, met = safe(card.condition_server, card)
                card.condition_server_met = success and met
            else
                card.condition_server_met = true
            end
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        if card.condition_local then
            local success, met = safe(card.condition_local, card)
            card.condition_local_met = success and met
        else
            card.condition_local_met = true
        end
        set_card_condition_met(card, card.condition_local_met and card.condition_server_met)
    end
    for _,card in ipairs(self.local_data.draw_pile) do
        if card.condition_local then
            local success, met = safe(card.condition_local, card)
            card.condition_local_met = success and met
        else
            card.condition_local_met = true
        end
        set_card_condition_met(card, card.condition_local_met and card.condition_server_met)
    end
end
cgm._evaluate_local_card_autos = function(self)
    if self:unable_to_play() then
        return
    end
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            if card.auto_condition_server then
                local success, met = safe(card.auto_condition_server, card)
                card.auto_condition_server_met = success and met
            else
                card.auto_condition_server_met = true
            end
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        if card.auto_condition_local then
            local success, met = safe(card.auto_condition_local, card)
            card.auto_condition_local_met = success and met
        else
            card.auto_condition_local_met = true
        end
        card.auto_condition_met = card.auto_condition_server_met and card.auto_condition_local_met
    end
end
cgm._evaluate_remote_card_conditions = function(self)
    -- Should only be run as server
    for peer_id,peer_data in pairs(self.peer_data) do
        if not self:unable_to_play() then
            for index,card in ipairs(peer_data.hand) do
                local cached_met_value = card.condition_server_met
                if card.condition_server then
                    local success, met = safe(card.condition_server, card)
                    card.condition_server_met = success and met
                else
                    card.condition_server_met = true
                end
                if cached_met_value ~= card.condition_server_met then
                    enigma:network_send(net.notify_card_condition_met_changed, peer_id, enigma.CARD_LOCATION.hand, index, card.condition_server_met)
                end
            end
            for index,card in ipairs(peer_data.draw_pile) do
                local cached_met_value = card.condition_server_met
                if card.condition_server then
                    local success, met = safe(card.condition_server, card)
                    card.condition_server_met = success and met
                else
                    card.condition_server_met = true
                end
                if cached_met_value ~= card.condition_server_met then
                    enigma:network_send(net.notify_card_condition_met_changed, peer_id, enigma.CARD_LOCATION.draw_pile, index, card.condition_server_met)
                end
            end
        end
    end
end
cgm._evaluate_remote_card_autos = function(self)
    -- Should only be run as server
    for peer_id,peer_data in pairs(self.peer_data) do
        if not self:unable_to_play() then
            for index,card in ipairs(peer_data.hand) do
                local cached_met_value = card.auto_condition_server_met
                if card.auto_condition_server then
                    local success, met = safe(card.auto_condition_server, card)
                    card.auto_condition_server_met = success and met
                else
                    card.auto_condition_server_met = true
                end
                if cached_met_value ~= card.auto_condition_server_met then
                    enigma:network_send(net.notify_card_auto_condition_met_changed, peer_id, index, card.auto_condition_server_met)
                end
            end
        end
    end
end
cgm._update_accumulated_staggers = function(self, dt)
    local sync = false
    self.time_until_sync_accumulated_stagger = self.time_until_sync_accumulated_stagger - dt
    if self.time_until_sync_accumulated_stagger <= 0 then
        sync = true
        self.time_until_sync_accumulated_stagger = self.time_until_sync_accumulated_stagger + self.sync_accumulated_stagger_interval
    end
    if sync then
        local trash = self.local_data.accumulated_stagger["trash"]
        local elite = self.local_data.accumulated_stagger["elite"]
        local special = self.local_data.accumulated_stagger["special"]
        local boss = self.local_data.accumulated_stagger["boss"]
        enigma.managers.warp:_process_accumulated_stagger(trash, elite, special, boss)
        self.local_data.accumulated_stagger["trash"] = 0
        self.local_data.accumulated_stagger["elite"] = 0
        self.local_data.accumulated_stagger["special"] = 0
        self.local_data.accumulated_stagger["boss"] = 0

        for peer_id,peer_data in pairs(self.peer_data) do
            trash = peer_data.accumulated_stagger["trash"]
            elite = peer_data.accumulated_stagger["elite"]
            special = peer_data.accumulated_stagger["special"]
            boss = peer_data.accumulated_stagger["boss"]
            if trash > 0 or elite > 0 or special > 0 or boss > 0 then
                enigma:network_send(net.sync_player_accumulated_stagger, peer_id, trash, elite, special, boss)
                peer_data.accumulated_stagger["trash"] = 0
                peer_data.accumulated_stagger["elite"] = 0
                peer_data.accumulated_stagger["special"] = 0
                peer_data.accumulated_stagger["boss"] = 0
            end
        end
    end
end
cgm._update_pacing_intensity = function(self, dt)
    self.time_until_broadcast_pacing_intensity = self.time_until_broadcast_pacing_intensity - dt
    if self.time_until_broadcast_pacing_intensity <= 0 then
        local previous_pacing_intensity = self.pacing_intensity
        self.pacing_intensity = self.pacing.total_intensity
        if self.pacing_intensity ~= previous_pacing_intensity then
            self:_update_card_draw_gain_rate()
            enigma:network_send(net.broadcast_pacing_intensity, "others", self.pacing_intensity)
        end
        self.time_until_broadcast_pacing_intensity = self.broadcast_pacing_intensity_interval
    end
end
cgm._update_level_progress = function(self, dt)
    self.time_until_broadcast_level_progress = self.time_until_broadcast_level_progress - dt
    if self.time_until_broadcast_level_progress <= 0 then
        local progress = enigma:get_level_progress() or 0
        if progress > self.last_broadcast_level_progress then
            self.last_broadcast_level_progress = progress
            enigma:network_send(net.sync_level_progress, "all", progress)
        end
        self.time_until_broadcast_level_progress = self.broadcast_level_progress_interval
    end
end

local card_draw_gain_lut = {
    {
        threshold = 50,
        rate = 0.018
    },
    {
        threshold = 20,
        rate = 0.013
    },
    {
        threshold = 3,
        rate = 0.008
    }
}
cgm._update_card_draw_gain_rate = function(self)
    local rate = 1
    local local_unit = self.local_data.unit
    if local_unit then
        local custom_buffs = enigma.managers.buff.unit_custom_buffs[local_unit]
        if custom_buffs and custom_buffs.card_draw_multiplier then
            rate = rate * custom_buffs.card_draw_multiplier
        end
    end
    
    local pacing_intensity = self.pacing_intensity
    local pacing_multiplier = 0
    for _,t in ipairs(card_draw_gain_lut) do
        if pacing_intensity > t.threshold then
            pacing_multiplier = t.rate
            break
        end
    end
    rate = rate * pacing_multiplier
    self.local_data._card_draw_gain_rate = rate
end
cgm.update = function(self, dt)
    if self.game_state == "in_progress" then

        self:_handle_requested_card_play_from_ui(dt)

        self:_update_active_channel(dt)
        
        self:_run_local_card_updates(dt)
        self:_run_remote_card_updates(dt)
        
        self:_update_local_card_active_durations(dt)
        self:_update_remote_card_active_durations(dt)

        self:_evaluate_local_card_conditions()
        self:_evaluate_local_card_autos()

        if self.is_server then
            self:_evaluate_remote_card_conditions()
            self:_evaluate_remote_card_autos()

            self:_update_accumulated_staggers(dt)
            self:_update_pacing_intensity(dt)
            self:_update_level_progress(dt)
        end

        self:add_card_draw(self.local_data._card_draw_gain_rate * dt, "passive")
        local pull_from_deferred = self.local_data.deferred_card_draws * dt * 0.5
        self.local_data.deferred_card_draws = self.local_data.deferred_card_draws - pull_from_deferred
        self:add_card_draw(pull_from_deferred, "level_progress")

    elseif self.game_state == "initializing" then
    end
end

cgm.card_cost_changed = function(self, card)
    set_card_can_pay_warpstone(card)
    card:_card_cost_changed()
end
cgm.change_card_cost = function(self, card, new_cost)
    if type(card) ~= "table" then
        enigma:warning("Could not change card cost, invalid card")
        return
    end
    if card.owner ~= enigma:local_peer_id() then
        enigma:warning("Attempted to set card cost for someone else's card, this is not allowed.")
        return
    end
    if card.cost == "X" then
        enigma:warning("Cannot directly set card cost of an X-cost card ["..tostring(card.id).."]")
        return
    end
    if type(new_cost) ~= "number" then
        enigma:warning("Could not change card cost to non-number value: "..tostring(new_cost))
        return
    end
    local floor = math.floor(new_cost)
    card.cost = floor
    self:card_cost_changed(card)
end
cgm.add_card_cost = function(self, card, cost_to_add)
    if type(card) ~= "table" then
        enigma:warning("Could not change card cost, invalid card")
        return
    end
    if card.owner ~= enigma:local_peer_id() then
        enigma:warning("Attempted to set card cost for someone else's card, this is not allowed.")
        return
    end
    if type(cost_to_add) ~= "number" then
        enigma:warning("Could not add non-number value to card cost: "..tostring(cost_to_add))
        return
    end
    if card.cost == "X" then
        card.cost_modifier = card.cost_modifier + cost_to_add
        self:card_cost_changed(card)
        return
    end
    self:change_card_cost(card, card.cost + cost_to_add)
end

cgm.on_warpstone_amount_changed = function(self)
    for _,card in ipairs(self.local_data.all_cards) do
        set_card_can_pay_warpstone(card)
    end
end

cgm.is_in_game = function(self)
    return self.game_state == "in_progress"
end

-- Utilities
enigma:network_register(net.request_play_card, function(sender, card_local_id)
    local card = cgm.local_data.all_cards[card_local_id]
    if not card then
        enigma:warning("Received request_play_card with an invalid card local id "..tostring(card_local_id))
        return
    end
    cgm:play_card(card)
end)
cgm.request_play_card = function(self, card)
    if not card.owner then
        enigma:warning("Could not determine owner of card to request them to play it")
        return
    end
    enigma:network_send(net.request_play_card, card.owner, card.local_id)
end
enigma:network_register(net.sync_card_property, function(sender, card_owner_peer_id, card_local_id, property, value)
    local data = nil
    if card_owner_peer_id == cgm.local_data.peer_id then
        data = cgm.local_data
    else
        data = cgm.peer_data[card_owner_peer_id]
    end
    if not data then
        enigma:warning("Received sync_card_property with an invalid peer_id")
        return
    end
    local card = data.all_cards[card_local_id]
    if not card then
        enigma:warning("Received sync_card_property with an invalid card local id "..tostring(card_local_id))
        return
    end
    if not property then
        enigma:warning("Received sync_card_property with an invalid property name")
        return
    end
    enigma:debug("Received card property sync \""..tostring(property).."\"="..tostring(value).." on card "..tostring(card.id))
    card[property] = value
    if card.on_property_synced then
        safe(card.on_property_synced, card, property, value)
    end
end)
cgm.sync_card_property = function(self, card, property)
    if not property then
        enigma:warning("Cannot sync card property: "..tostring(property))
        return
    end
    local card_owner_peer_id = card.context.peer_id
    enigma:info("Sending sync_card_property to others. ["..tostring(card.id).."]."..tostring(property).."="..tostring(card[property]))
    enigma:network_send(net.sync_card_property, "others", card_owner_peer_id, card.local_id, property, card[property])
end
enigma:network_register(net.invoke_card_rpc, function(sender, card_owner_peer_id, card_local_id, func_name, ...)
    local data = nil
    if card_owner_peer_id == cgm.local_data.peer_id then
        data = cgm.local_data
    else
        data = cgm.peer_data[card_owner_peer_id]
    end
    if not data then
        enigma:warning("Received invoke_card_rpc with an invalid peer_id")
        return
    end
    local card = data.all_cards[card_local_id]
    if not card then
        enigma:warning("Received invoke_card_rpc with an invalid card local id "..tostring(card_local_id))
        return
    end
    if not func_name then
        enigma:warning("Received invoke_card_rpc with an invalid func name")
        return
    end
    enigma:debug("Received card RPC \""..tostring(func_name).."\" on card "..tostring(card.id))
    if type(card[func_name]) ~= "function" then
        enigma:warning("Function \""..tostring(func_name).."\" does not exist on card "..tostring(card.id))
        return
    end
    safe(card[func_name], card, ...)
end)
cgm._invoke_card_rpc = function(self, recipient, card, func_name, ...)
    if not recipient then
        enigma:warning("Cannot invoke card rpc with no recipient: "..tostring(func_name))
    end
    if not func_name then
        enigma:warning("Cannot invoke card rpc: "..tostring(func_name))
        return
    end
    local card_owner_peer_id = card.context.peer_id
    enigma:info("Sending invoke_card_rpc to "..tostring(recipient)..". ["..tostring(card.id).."]."..tostring(func_name))
    enigma:network_send(net.invoke_card_rpc, recipient, card_owner_peer_id, card.local_id, func_name, ...)
end
cgm.active_channel = function(self)
    return self.local_data and self.local_data.active_channel
end
cgm.cancel_channel = function(self)
    local active_channel = self:active_channel()
    if active_channel then
        cgm.local_data.active_channel.cancelled = true
    end
end
enigma:network_register(net.sync_card_game_property, function(sender, peer_id, property, value)
    local data = nil
    if peer_id == cgm.local_data.peer_id then
        data = cgm.local_data
    else
        data = cgm.peer_data[peer_id]
    end
    if not data then
        enigma:warning("Received sync_card_game_property with an invalid peer_id")
        return
    end
    if not property then
        enigma:warning("Received sync_card_game_property with an invalid property name")
        return
    end
    enigma:debug("Received card game property sync "..tostring(peer_id)..": \""..tostring(property).."\"="..tostring(value))
    data[property] = value
end)
enigma._sync_card_game_property = function(self, peer_id, property)
    if not property then
        enigma:warning("Cannot sync card game property: "..tostring(property))
        return
    end
    local data = nil
    if peer_id == cgm.local_data.peer_id then
        data = cgm.local_data
    else
        data = cgm.peer_data[peer_id]
    end
    if not data then
        enigma:warning("Cannot sync card game property, we do not have data for peer: "..tostring(peer_id))
        return
    end
    enigma:info("Sending sync_card_game_property to others. ["..tostring(peer_id).."]."..tostring(property).."="..tostring(data[property]))
    enigma:network_send(net.sync_card_game_property, "others", peer_id, property, data[property])
end

-- Hooks
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

reg_hook_safe(PlayerUnitHealthExtension, "set_dead", function(self)
    local data = cgm.data_by_unit[self.unit]
    if data then
        enigma:info("Setting dead for "..tostring(data.peer_id))
        data.dead = true
    end
end, "enigma_card_game_player_dead")
reg_hook_safe(GenericStatusExtension, "set_ready_for_assisted_respawn", function(self, status_bool, flavour_unit)
    local data = cgm.data_by_unit[self.unit]
    if data then
        if status_bool then
            enigma:info("Setting waiting_for_rescue for "..tostring(data.peer_id))
        else
            enigma:info("Setting respawned for "..tostring(data.peer_id))
        end
        data.dead = false
        data.waiting_for_rescue = status_bool
    end
end, "enigma_card_game_player_waiting_for_rescue")

reg_hook_safe(PlayerManager, "assign_unit_ownership", function(self, unit, player, is_player_unit)
    if not is_player_unit then
        return
    end

    local data = nil
    if not player.bot_player and player.peer_id == enigma:local_peer_id() then
        data = cgm.local_data
    elseif not player.bot_player and cgm.peer_data[player.peer_id] then
        data = cgm.peer_data[player.peer_id]
    end
    if data then
        enigma:info("Setting owned unit for "..tostring(data.peer_id))
        local previous_unit = data.unit
        cgm.data_by_unit[unit] = data
        if previous_unit then
            cgm.data_by_unit[previous_unit] = nil
        end
        data.dead = false
        data.unit = unit
        enigma.managers.buff:_register_player(player)
    end
end, "enigma_card_game_player_unit_ownership")

reg_hook_safe(PlayerUnitHealthExtension, "init", function(self, extension_init_context, unit, extension_init_data)
    enigma:info("PlayerUnitHealthExtension INIT")
end, "enigma_card_game_player_health_init")

-- Hooks for disabling active channel
reg_hook_safe(PlayerUnitHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    if not cgm:is_in_game() then
        return
    end
    if self.unit == cgm.local_data.unit and damage_amount > 0 and damage_type ~= "temporary_health_degen" then
        cgm:cancel_channel()
    end
end, "card_game_player_damaged")

enigma:hook(CharacterStateHelper, "get_movement_input", function(func, input_extension)
    if not cgm:is_in_game() then
        return func(input_extension)
    end
    local movement = func(input_extension)
    if input_extension.unit == cgm.local_data.unit and Vector3.length(movement) > 0 then
        cgm:cancel_channel()
    end
    return movement
end)

local cancel_channel_triggers = {
    on_player_disabled = true,
    on_block_broken = true,
    on_knocked_down = true,
    on_reload = true,
    on_ability_activated = true,
    on_death = true,
    on_body_pushed = true,
    on_push_used = true
}
reg_hook_safe(BuffExtension, "trigger_procs", function(self, event, ...)
    if not cgm:is_in_game() then
        return
    end
    if self._unit == cgm.local_data.unit then
        local filtered_action_start = event == "on_start_action"
        if filtered_action_start then
            local action = select(1, ...)
            filtered_action_start = action and action.kind ~= "block" and action.kind ~= "wield" and action.kind ~= "dummy"
            if filtered_action_start then
                cgm:cancel_channel()
            end
        elseif cancel_channel_triggers[event] then
            cgm:cancel_channel()
        end
    end
end, "enigma_card_game_trigger_procs")

reg_hook_safe(PlayerCharacterStateJumping, "on_enter", function(self, unit, ...)
    if not cgm:is_in_game() then
        return
    end
    if unit == cgm.local_data.unit then
        cgm:cancel_channel()
    end
end, "enigma_card_game_player_jump")

local handle_channel_cancelling_status_change = function(unit, bad_status)
    if not cgm:is_in_game() then
        return
    end
    if unit == cgm.local_data.unit and bad_status then
        cgm:cancel_channel()
    end
end

reg_hook_safe(GenericStatusExtension, "set_pushed", function(self, pushed, t)
    handle_channel_cancelling_status_change(self.unit, pushed)
end, "enigma_card_game_set_pushed")

reg_hook_safe(GenericStatusExtension, "set_catapulted", function(self, catapulted, velocity)
    handle_channel_cancelling_status_change(self.unit, catapulted)
end, "enigma_card_game_set_catapulted")

reg_hook_safe(GenericStatusExtension, "set_in_vortex", function(self, in_vortex, vortex_unit)
    handle_channel_cancelling_status_change(self.unit, in_vortex)
end, "enigma_card_game_set_in_vortex")




enigma:network_register(net.sync_player_accumulated_stagger, function(peer_id, trash, elite, special, boss)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us how much stagger we have accumulated recently")
        return
    end
    enigma.managers.warp:_process_accumulated_stagger(trash, elite, special, boss)
end)

-- It would be nice if we could instead hook the "enter" and "leave" functions and track the number of staggered enemies ourselves,
-- but I discovered that it was not reliable.
enigma:hook_safe(BTStaggerAction, "run", function(self, unit, blackboard, t, dt)
    if blackboard.pushing_unit then
        local data = cgm.data_by_unit[blackboard.pushing_unit]
        if data then
            local enemy_type = blackboard.enemy_type
            if not enemy_type then
                local staggered_breed = Unit.get_data(unit, "breed")
                enemy_type = staggered_breed.boss and "boss" or staggered_breed.special and "special" or staggered_breed.elite and "elite" or "trash"
            end
            data.accumulated_stagger[enemy_type] = data.accumulated_stagger[enemy_type] + dt
        end
    end
end)


-- Events
cgm.on_game_state_changed = function(self, status, state_name)
    if state_name == "StateLoading" and status == "enter" and Managers.level_transition_handler then
        if self:is_in_game() and (enigma:traveling_to_inn() or enigma:traveling_to_morris_hub() or enigma:traveling_to_morris_map()) then
            self:end_game()
        end
    elseif state_name == "StateIngame" and status == "enter" and Managers.level_transition_handler then
        local in_dev_game = enigma.managers.game:is_in_game() and enigma.managers.game.debug
        if in_dev_game or (not enigma:in_keep() and not enigma:in_morris_map()) then
            local game_init_data = enigma.managers.deck_planner.game_init_data
            self:init_game(game_init_data)
        end
    end
end
enigma:register_mod_event_callback("on_game_state_changed", cgm, "on_game_state_changed")


-- Debug
cgm.dump = function(self)
    enigma:dump(self.local_data, "SELF GAME DATA", 2)
    enigma:dump(self.peer_data, "PEER GAME DATA", 3)
    enigma:dump(self, "CARD GAME MANAGER", 0)
end

enigma:command("gain_draw", "", function(num)
    num = num or 1
    cgm:add_card_draw(num, "debug")
end)