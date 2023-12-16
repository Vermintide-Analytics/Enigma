local enigma = get_mod("Enigma")

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
    sync_level_progress = "sync_level_progress",
    sync_card_property = "sync_card_property",
    sync_player_accumulated_stagger = "sync_player_accumulated_stagger",
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

local remove_card_from_pile = function(pile, card)
    local ind = 0
    for i,v in ipairs(pile) do
        if v == card then
            ind = i
            break
        end
    end
    table.remove(pile, ind)
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

local handle_local_card_played = function(card, index, location, skip_warpstone_cost, play_type)
    if not skip_warpstone_cost and not enigma.managers.warp:can_pay_cost(card.cost) then
        if play_type == "manual" then
            enigma.managers.ui.time_since_warpstone_cost_action_invalid = 0
        end
        return
    end
    if not skip_warpstone_cost then
        enigma.managers.warp:pay_cost(card.cost)
    end
    
    enigma:info("Playing card ["..card.id.."]")

    local can_expend_charge = card.charges and card.charges > 1
    if not can_expend_charge then
        remove_card_from_pile(cgm.local_data[card.location], card)
    end

    if cgm.is_server and card.on_play_server then
        card:on_play_server(play_type)
    end
    if card.on_play_local then
        card:on_play_local(play_type)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_played_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_played_local", card)

    card.times_played = card.times_played + 1
    if card.duration then
        table.insert(card.active_durations, 1, card.duration)
    end

    if can_expend_charge then
        card.charges = card.charges - 1
        card:set_dirty()
    else
        local destination_pile = enigma.CARD_LOCATION.discard_pile
        if card.ephemeral then
            destination_pile = enigma.CARD_LOCATION.out_of_play_pile
        end

        if card.infinite and not card.ephemeral then
            table.insert(cgm.local_data[enigma.CARD_LOCATION.draw_pile], 1, card) -- Put at bottom of draw pile
        else
            table.insert(cgm.local_data[destination_pile], card)
            card.location = destination_pile
            if cgm.is_server and card.on_location_changed_server then
                card:on_location_changed_server(location, destination_pile)
            end
            if card.on_location_changed_local then
                card:on_location_changed_local(location, destination_pile)
            end
        end

        if location == enigma.CARD_LOCATION.hand then
            enigma.managers.ui.hud_data.hand_indexes_just_removed[index] = true
            enigma.managers.ui.card_mode_ui_data.hand_indexes_just_removed[index] = true
        end
    end

    enigma:network_send(net.event_card_played, "others", index, location, play_type)
    return true
end

cgm.game_state = nil

enigma:network_register(net.sync_card_game_init_data, function(peer_id, deck_name, card_ids_in_deck)
    local peer_data = {
        deck_name = deck_name,
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
        local card = card_template:instance()
        if card.condition_local and not card.condition_server then
            card.condition_server_met = true
        end
        if card.auto_condition_local and not card.auto_condition_server then
            card.auto_condition_server_met = true
        end
        card.context = peer_data
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
end)
cgm.init_game = function(self, deck_name, card_templates, is_server)
    enigma:echo("Initializing Enigma game")
    self.is_server = is_server
    self.game_state = "loading"

    local card_ids = {}
    for _,template in ipairs(card_templates) do
        table.insert(card_ids, template.id)
    end
    add_chaos_cards_based_on_added_difficulty(card_ids)
    enigma:shuffle(card_ids)
    
    local local_data = {
        deck_name = deck_name,
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
        local card = card_template:instance()
        if not card.condition_server then
            card.condition_server_met = true
        end
        if not card.condition_local then
            card.condition_local_met = true
        end
        card.condition_met = card.condition_server_met and card.condition_local_met or false
        if card.auto_condition_local and not card.auto_condition_server then
            card.auto_condition_server_met = true
        end
        if card.auto_condition_server and not card.auto_condition_local then
            card.auto_condition_local_met = true
        end
        card.context = local_data
        card.owner = enigma:local_peer_id()
        card.original_owner = card.owner
        table.insert(local_data.draw_pile, card)
        if is_server then
            enigma.managers.event:_add_card_server_event_callbacks(card)
        end
        enigma.managers.event:_add_card_local_event_callbacks(card)
    end

    self.local_data = local_data
    enigma:network_send(net.sync_card_game_init_data, "others", deck_name, card_ids)

    enigma:register_mod_event_callback("update", self, "update")
end

cgm.start_game = function(self)
    if self.game_state ~= "loading" then
        enigma:echo("Enigma attempted to start a game before initializing it")
        return
    end
    enigma:echo("Starting Enigma game")
    self.game_state = "in_progress"
    self.game_mode = enigma:game_mode()

    for _,card in ipairs(self.local_data.draw_pile) do
        if card.on_game_start_local then
            if self.is_server and card.on_game_start_server then
                card:on_game_start_server()
            end
            card:on_game_start_local()
        end
    end

    for _,peer_data in pairs(self.peer_data) do
        for _,card in ipairs(peer_data.draw_pile) do
            if self.is_server and card.on_game_start_server then
                card:on_game_start_server()
            end
            if card.on_game_start_remote then
                card:on_game_start_remote()
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
    end

    enigma.managers.warp:start_game()

    self:_draw_card_for_free()
end

cgm.end_game = function(self)
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
    enigma.managers.event:remove_all_card_event_callbacks()
end

enigma:network_register(net.notify_card_condition_met_changed, function(peer_id, pile, index, satisfied)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card condition met changes")
        local card = cgm.local_data[pile][index]
        if card then
            enigma:warning("Attempted to set card playable: "..card.id)
        end
        return
    end
    local card = cgm.local_data[pile][index]
    if not card then
        enigma:warning("Attempted to set card playable at invalid index")
        return
    end
    card.cond_satisfied_server = satisfied
    card.cond_satisfied = card.cond_satisfied_server and ((card.cond_satisfied_local == nil) or card.cond_satisfied_local)
end)
enigma:network_register(net.notify_card_auto_condition_met_changed, function(peer_id, index, met)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card auto-trigger condition met changes")
        local card = cgm.local_data.hand[index]
        if card then
            enigma:warning("Attempted to set card auto met: "..card.id)
        end
        return
    end
    local card = cgm.local_data.hand[index]
    if not card then
        enigma:warning("Attempted to set card auto met at invalid index")
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

cgm._update_active_channel = function(self, dt)
    if not self.local_data.active_channel then
        return
    end
    if self.local_data.active_channel.cancelled then
        self.local_data.previous_channel = self.local_data.active_channel
        self.local_data.active_channel = nil
        return
    end
    self.local_data.active_channel.remaining_duration = self.local_data.active_channel.remaining_duration - dt
    if self.local_data.active_channel.remaining_duration <= 0 then
        local card = self.local_data.active_channel.card
        local pile = self.local_data[card.location]
        local index = get_card_index_in_pile(pile, card)
        local skip_warpstone_cost = self.local_data.active_channel.skip_warpstone_cost
        local play_type = self.local_data.active_channel.play_type
        self.local_data.previous_channel = self.local_data.active_channel
        self.local_data.active_channel = nil
        handle_local_card_played(card, index, card.location, skip_warpstone_cost, play_type)
    end
end

cgm._run_local_card_updates = function(self, dt)
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            if card.update_server then
                card:update_server(dt)
            end
        end
        for _,card in ipairs(self.local_data.draw_pile) do
            if card.update_server then
                card:update_server(dt)
            end
        end
        for _,card in ipairs(self.local_data.discard_pile) do
            if card.update_server then
                card:update_server(dt)
            end
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        if card.update_local then
            card:update_local(dt)
        end
    end
    for _,card in ipairs(self.local_data.draw_pile) do
        if card.update_local then
            card:update_local(dt)
        end
    end
    for _,card in ipairs(self.local_data.discard_pile) do
        if card.update_local then
            card:update_local(dt)
        end
    end
end
cgm._run_remote_card_updates = function(self, dt)
    if self.is_server then
        for _,peer_data in pairs(self.peer_data) do
            for _,card in ipairs(peer_data.hand) do
                if card.update_server then
                    card:update_server(dt)
                end
            end
            for _,card in ipairs(peer_data.draw_pile) do
                if card.update_server then
                    card:update_server(dt)
                end
            end
            for _,card in ipairs(peer_data.discard_pile) do
                if card.update_server then
                    card:update_server(dt)
                end
            end
        end
    end
    for _,peer_data in pairs(self.peer_data) do
        for _,card in ipairs(peer_data.hand) do
            if card.update_remote then
                card:update_remote(dt)
            end
        end
        for _,card in ipairs(peer_data.draw_pile) do
            if card.update_remote then
                card:update_remote(dt)
            end
        end
        for _,card in ipairs(peer_data.discard_pile) do
            if card.update_remote then
                card:update_remote(dt)
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

cgm._evaluate_local_card_conditions = function(self)
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
        end
        for _,card in ipairs(self.local_data.draw_pile) do
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        card.condition_local_met = (not card.condition_local) or card:condition_local()
        card.condition_met = card.condition_server_met and card.condition_local_met
    end
    for _,card in ipairs(self.local_data.draw_pile) do
        card.condition_local_met = (not card.condition_local) or card:condition_local() or false
        card.condition_met = card.condition_server_met and card.condition_local_met
    end
end
cgm._evaluate_local_card_autos = function(self)
    if self.is_server then
        for _,card in ipairs(self.local_data.hand) do
            card.auto_condition_server_met = (not card.auto_condition_server) or card:auto_condition_server() or false
        end
    end
    for _,card in ipairs(self.local_data.hand) do
        card.auto_condition_local_met = (not card.auto_condition_local) or card:auto_condition_local() or false
        card.auto_condition_met = card.auto_condition_server_met and card.auto_condition_local_met
    end
end
cgm._evaluate_remote_card_conditions = function(self)
    -- Should only be run as server
    for peer_id,peer_data in pairs(self.peer_data) do
        for index,card in ipairs(peer_data.hand) do
            local cached_met_value = card.condition_server_met
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
            if cached_met_value ~= card.condition_server_met then
                enigma:network_send(net.notify_card_condition_met_changed, peer_id, enigma.CARD_LOCATION.hand, index, card.condition_server_met)
            end
        end
        for index,card in ipairs(peer_data.draw_pile) do
            local cached_met_value = card.condition_server_met
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
            if cached_met_value ~= card.condition_server_met then
                enigma:network_send(net.notify_card_condition_met_changed, peer_id, enigma.CARD_LOCATION.draw_pile, index, card.condition_server_met)
            end
        end
    end
end
cgm._evaluate_remote_card_autos = function(self)
    -- Should only be run as server
    for peer_id,peer_data in pairs(self.peer_data) do
        for index,card in ipairs(peer_data.hand) do
            local cached_met_value = card.auto_condition_server_met
            card.auto_condition_server_met = (not card.auto_condition_server) or card:auto_condition_server() or false
            if cached_met_value ~= card.auto_condition_server_met then
                enigma:network_send(net.notify_card_auto_condition_met_changed, peer_id, index, card.auto_condition_server_met)
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
    end
    for peer_id,peer_data in pairs(self.peer_data) do
        if sync then
            local trash = peer_data.accumulated_stagger["trash"]
            local elite = peer_data.accumulated_stagger["elite"]
            local special = peer_data.accumulated_stagger["special"]
            local boss = peer_data.accumulated_stagger["boss"]
            enigma:network_send(net.sync_player_accumulated_stagger, peer_id, trash, elite, special, boss)
            peer_data.accumulated_stagger["trash"] = 0
            peer_data.accumulated_stagger["elite"] = 0
            peer_data.accumulated_stagger["special"] = 0
            peer_data.accumulated_stagger["boss"] = 0
        end
    end
end
local card_draw_gain_lut = {
    {
        threshold = 50,
        rate = 0.020
    },
    {
        threshold = 20,
        rate = 0.014
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

            self.time_until_broadcast_pacing_intensity = self.time_until_broadcast_pacing_intensity - dt
            if self.time_until_broadcast_pacing_intensity <= 0 then
                self.pacing_intensity = self.pacing.total_intensity
                self:_update_card_draw_gain_rate()
                enigma:network_send(net.broadcast_pacing_intensity, "others", self.pacing_intensity)
                self.time_until_broadcast_pacing_intensity = self.broadcast_pacing_intensity_interval
            end

            self.time_until_broadcast_level_progress = self.time_until_broadcast_level_progress - dt
            if self.time_until_broadcast_level_progress <= 0 then
                local progress = enigma:get_level_progress() or 0
                enigma:network_send(net.sync_level_progress, "all", progress)
                self.time_until_broadcast_level_progress = self.broadcast_level_progress_interval
            end
        end

        self.local_data.available_card_draws = self.local_data.available_card_draws + (self.local_data._card_draw_gain_rate * dt)
        local pull_from_deferred = self.local_data.deferred_card_draws * dt * 0.5
        self.local_data.deferred_card_draws = self.local_data.deferred_card_draws - pull_from_deferred
        self.local_data.available_card_draws = self.local_data.available_card_draws + pull_from_deferred

    elseif self.game_state == "loading" then
    end
end

enigma:network_register(net.event_card_drawn, function(peer_id)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end
    
    local card = table.remove(peer_data.draw_pile)
    if cgm.is_server and card.on_draw_server then
        card:on_draw_server()
    end
    if card.on_draw_remote then
        card:on_draw_remote()
    end
    table.insert(peer_data.hand, card)
    card.location = enigma.CARD_LOCATION.hand
    if cgm.is_server and card.on_location_changed_server then
        card:on_location_changed_server(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if card.on_location_changed_remote then
        card:on_location_changed_remote(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_drawn_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_drawn_remote", card)
end)
cgm._draw_card_for_free = function(self)
    if #self.local_data.draw_pile < 1 then
        enigma.managers.ui.time_since_draw_pile_action_invalid = 0
        return false, "Draw pile is empty"
    end
    if #self.local_data.hand > 4 then
        enigma.managers.ui.time_since_hand_size_action_invalid = 0
        return false, "Hand is full"
    end
    local card = table.remove(self.local_data.draw_pile)
    if cgm.is_server and card.on_draw_server then
        card:on_draw_server()
    end
    if card.on_draw_local then
        card:on_draw_local()
    end
    table.insert(self.local_data.hand, card)
    card.location = enigma.CARD_LOCATION.hand
    if self.is_server and card.on_location_changed_server then
        card:on_location_changed_server(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if card.on_location_changed_local then
        card:on_location_changed_local(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_drawn_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_drawn_local", card)

    enigma:network_send(net.event_card_drawn, "others")
    enigma:info("Drew card ["..card.id.."]")
    return true
end
cgm.try_draw_card = function(self)
    if not self:is_in_game() then
        return false, "Not in a game"
    end
    if self.local_data.available_card_draws < 1 then
        enigma.managers.ui.time_since_available_draw_action_invalid = 0
        return false, "Not enough available card draws"
    end
    local success, fail_reason = self:_draw_card_for_free()
    if success then
        self.local_data.available_card_draws = self.local_data.available_card_draws - 1
    end
    return success, fail_reason
end


enigma:network_register(net.event_card_played, function(peer_id, index, location, play_type)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end

    local card = peer_data[location][index]
    if not card then
        enigma:warning("Received card played event from another player but we can't find the card to play")
        return
    end

    if cgm.is_server and card.on_play_server then
        card:on_play_server(play_type)
    end
    if card.on_play_remote then
        card:on_play_remote(play_type)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_played_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_played_remote", card)

    card.times_played = card.times_played + 1
    if card.duration then
        table.insert(card.active_durations, 1, card.duration)
    end
    
    local can_expend_charge = card.charges and card.charges > 1

    if can_expend_charge then
        card.charges = card.charges - 1
    else
        table.remove(peer_data[location], index)
        local destination_pile = enigma.CARD_LOCATION.discard_pile
        if card.ephemeral then
            destination_pile = enigma.CARD_LOCATION.out_of_play_pile
        elseif card.infinite then
            destination_pile = enigma.CARD_LOCATION.draw_pile
        end
        table.insert(peer_data[destination_pile], card)
        card.location = destination_pile
        if cgm.is_server and card.on_location_changed_server then
            card:on_location_changed_server(location, destination_pile)
        end
        if card.on_location_changed_remote then
            card:on_location_changed_remote(location, destination_pile)
        end
    end
end)
cgm._try_play_card_at_index_from_location = function(self, index, location, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not enigma.can_play_from_location(location) then
        enigma:warning("Cannot play cards from "..tostring(location))
        return
    end
    if self.local_data.active_channel then
        enigma:info("Cannot play card, currently channeling")
        return
    end
    local card = self.local_data[location][index]
    if not card then
        if play_type == "manual" then 
            enigma.managers.ui.time_since_hand_size_action_invalid = 0
        else
            enigma:warning("Tried to automatically play card at index "..tostring(index).." in "..tostring(location)..", but that does not exist")
        end
        return
    end

    if card.unplayable and play_type == "manual" then
        enigma:info("Cannot play unplayable card manually")
        return
    end

    if not card.condition_met then
        if play_type == "manual" then
            enigma:info("Could not play "..card.name..", condition not met")
        else
            enigma:debug("Attempted to automatically play "..card.name.." but condition not met")
        end
        return
    end

    if not skip_warpstone_cost and not enigma.managers.warp:can_pay_cost(card.cost) then
        if play_type == "manual" then
            enigma.managers.ui.time_since_warpstone_cost_action_invalid = 0
        end
        return
    end

    if play_type ~= "auto" and card.channel and card.channel > 0 then
        self.local_data.active_channel = {
            card = card,
            total_duration = card.channel,
            remaining_duration = card.channel,
            play_type = play_type,
            skip_warpstone_cost = skip_warpstone_cost
        }
        return
    end
    return handle_local_card_played(card, index, location, skip_warpstone_cost)
end

cgm.try_play_card_from_hand = function(self, card_index, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not self:is_in_game() then
        if play_type == "auto" then
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return
    end
    if not self.local_data.hand[card_index] then
        if play_type == "manual" then 
            enigma.managers.ui.time_since_hand_size_action_invalid = 0
        else
            enigma:warning("Tried to automatically play card at index "..tostring(card_index).." from the hand, but that does not exist")
        end
        return
    end

    return self:_try_play_card_at_index_from_location(card_index, enigma.CARD_LOCATION.hand, skip_warpstone_cost, play_type)
end

cgm.try_play_card_from_draw_pile = function(self, card_index, skip_warpstone_cost)
    if not self:is_in_game() then
        enigma:warning("Attempted to auto play a card from the draw pile when not in a game")
        return
    end
    if type(card_index) ~= "number" then
        enigma:echo("Attempted to play card from draw pile using non-number index: " .. tostring(card_index))
        return
    end
    if not self.local_data.draw_pile[card_index] then
        enigma:echo("Attempted to play card "..card_index.." from draw pile, but draw pile does not have a card at that index")
    end

    return self:_try_play_card_at_index_from_location(card_index, enigma.CARD_LOCATION.draw_pile, skip_warpstone_cost, "auto")
end

cgm.try_play_card = function(self, card, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not card then
        enigma:warning("Tried to play nil card")
        return
    end
    if not self:is_in_game() then
        if play_type == "auto" then
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return
    end
    if not enigma.can_play_from_location(card.location) then
        enigma:warning("Attempted to play a card from the "..tostring(card.location)..". This is not allowed")
    end
    local pile = self.local_data[card.location]
    local index = pile and get_card_index_in_pile(pile, card)
    return self:_try_play_card_at_index_from_location(index, card.location, skip_warpstone_cost, play_type)
end

enigma:network_register(net.event_card_discarded, function(peer_id, index, from_draw_pile, discard_type)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end

    local pile = enigma.CARD_LOCATION.hand
    if from_draw_pile then
        pile = enigma.CARD_LOCATION.draw_pile
    end
    local card = table.remove(peer_data[pile], index)
    if cgm.is_server and card.on_discard_server then
        card:on_discard_server(discard_type)
    end
    if card.on_discard_remote then
        card:on_discard_remote(discard_type)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_discarded_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(peer_data, "on_any_card_discarded_remote", card)
    local destination_pile = enigma.CARD_LOCATION.discard_pile
    table.insert(peer_data[destination_pile], card)
    card.location = destination_pile
    if cgm.is_server and card.on_location_changed_server then
        card:on_location_changed_server(pile, enigma.CARD_LOCATION.discard_pile)
    end
    if card.on_location_changed_remote then
        card:on_location_changed_remote(pile, enigma.CARD_LOCATION.discard_pile)
    end
end)
cgm.discard_card = function(self, index, from_draw_pile, discard_type)
    discard_type = discard_type or "auto"
    local pile = enigma.CARD_LOCATION.hand
    if from_draw_pile then
        pile = enigma.CARD_LOCATION.draw_pile
    end
    local card = self.local_data[pile][index]
    if not card then
        enigma:echo("Attempted to discared card at index "..tostring(index).." from "..pile.." which only contains "..#self.local_data[pile][index].. " cards")
        return
    end

    remove_card_from_pile(self.local_data[card.location], card)
    if cgm.is_server and card.on_discard_server then
        card:on_discard_server(self.local_data, discard_type)
    end
    if card.on_discard_local then
        card:on_discard_local(self.local_data, discard_type)
    end
    if cgm.is_server then
        invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_discarded_server", card)
    end
    invoke_card_event_callbacks_for_all_piles(cgm.local_data, "on_any_card_discarded_local", card)

    local destination_pile = enigma.CARD_LOCATION.discard_pile
    table.insert(self.local_data[destination_pile], card)
    card.location = destination_pile
    if self.is_server and card.on_location_changed_server then
        card:on_location_changed_server(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if card.on_location_changed_local then
        card:on_location_changed_local(pile, enigma.CARD_LOCATION.discard_pile)
    end
    enigma:network_send(net.event_card_discarded, "others", index, from_draw_pile, discard_type)
    enigma:info("Discarded card ["..card.id.."]")
    return true
end

enigma:network_register(net.event_new_card_shuffled_into_draw_pile, function(peer_id, card_id, index)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end
    local template = enigma.managers.card_template:get_card_from_id(card_id)
    if not template then
        local card_pack = enigma.managers.card_template:get_pack_id_from_card_id(card_id)
        enigma:chat_whisper(peer_id, "A player is missing the "..card_pack.." card pack, and cards from this pack may not work properly.")
        table.insert(peer_data.draw_pile, index, card_id)
        return
    end

    local card = template:instance()
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server(peer_data)
    end
    if card.on_shuffle_into_draw_pile_remote then
        card:on_shuffle_into_draw_pile_remote(peer_data)
    end
    table.insert(peer_data.draw_pile, index, card)
end)
cgm.shuffle_new_card_into_draw_pile = function(self, card_id)
    local template = enigma.managers.card_template:get_card_from_id(card_id)
    if not template then
        enigma:echo("Could not add card to draw pile, card not defined. ("..card_id..")")
        return
    end
    local draw_pile_size = #self.local_data.draw_pile
    local index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))
    local card = template:instance()
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server()
    end
    if card.on_shuffle_into_draw_pile_local then
        card:on_shuffle_into_draw_pile_local()
    end
    table.insert(self.local_data.draw_pile, index, card)
    enigma:network_send(net.event_new_card_shuffled_into_draw_pile, "others", card_id, index) 
end

enigma:network_register(net.event_card_shuffled_into_draw_pile, function(peer_id, source_pile, source_index, destination_index)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end
    local card = peer_data[source_pile][source_index]
    if not card then
        enigma:warning("Could not pull card from index "..source_index.." in "..source_pile)
        return
    end
    remove_card_from_pile(peer_data[source_pile], card)
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server(peer_data)
    end
    if card.on_shuffle_into_draw_pile_remote then
        card:on_shuffle_into_draw_pile_remote(peer_data)
    end
    card.location = enigma.CARD_LOCATION.draw_pile
    if cgm.is_server and card.on_location_changed_server then
        card:on_location_changed_server(source_pile, enigma.CARD_LOCATION.draw_pile)
    end
    if card.on_location_changed_remote then
        card:on_location_changed_remote(source_pile, enigma.CARD_LOCATION.draw_pile)
    end
    table.insert(peer_data.draw_pile, destination_index, card)
end)
cgm.shuffle_card_into_draw_pile = function(self, card)
    remove_card_from_pile(self.local_data[card.location], card)
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server(self.local_data)
    end
    if card.on_shuffle_into_draw_pile_local then
        card:on_shuffle_into_draw_pile_local(self.local_data)
    end

    local draw_pile_size = #self.local_data.draw_pile
    local index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))

    table.insert(self.local_data.draw_pile, index, card)
    local original_pile = card.location
    local original_pile_index = get_card_index_in_pile(self.local_data[original_pile], card)
    card.location = enigma.CARD_LOCATION.draw_pile
    if self.is_server and card.on_location_changed_server then
        card:on_location_changed_server(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if card.on_location_changed_local then
        card:on_location_changed_local(original_pile, enigma.CARD_LOCATION.draw_pile)
    end
    enigma:network_send(net.event_card_shuffled_into_draw_pile, "others", original_pile, original_pile_index, index)
    enigma:info("Shuffled card ["..card.id.."] into draw pile")
    return true
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
    if type(new_cost) ~= "number" then
        enigma:warning("Could not change card cost to non-number value: "..tostring(new_cost))
    end
    local floor = math.floor(new_cost)
    if floor < 0 then
        enigma:warning("Cannot set card cost to less than 0 (attempted to set to"..tostring(new_cost)..")")
        return
    end
    card.cost = new_cost
    card.can_pay_warpstone = enigma.managers.warp:can_pay_cost(card.cost)
end

cgm.on_warpstone_amount_changed = function(self)
    for _,card in ipairs(self.local_data.hand) do
        card.can_pay_warpstone = enigma.managers.warp:can_pay_cost(card.cost)
    end
    for _,card in ipairs(self.local_data.draw_pile) do
        card.can_pay_warpstone = enigma.managers.warp:can_pay_cost(card.cost)
    end
end

cgm.is_in_game = function(self)
    return self.game_state == "in_progress"
end

cgm.start_game_if_all_ready = function(self)
    if self.game_state ~= "loading" then
        return
    end
    if not (self.local_data and self.local_data.ready) then
        return
    end
    for _,peer_data in pairs(self.peer_data) do
        if not peer_data.ready then
            return
        end
    end
    self:start_game()
end

enigma:network_register(net.sync_players_and_units_set, function(peer_id, ready)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end
    peer_data.ready = ready
    cgm:start_game_if_all_ready()
end)
cgm.check_players_and_units_all_set = function(self)
    if self.game_state ~= "loading" then
        return
    end
    enigma:echo("Checking if players and units are all set at game start")
    if not cgm.local_data.player then
        return
    end
    for peer_id,peer_data in pairs(self.peer_data) do
        if not peer_data.player then
            enigma:echo("Peer data for "..peer_id.." not yet set, not starting game")
            return
        end
    end
    self.local_data.ready = true
    enigma:network_send(net.sync_players_and_units_set, "others", true)
    cgm:start_game_if_all_ready()
    return true
end

-- Utilities
cgm.player_and_bot_units = function(self)
    if not self:is_in_game() then
        return
    end
    local side = Managers.state and Managers.state.side and Managers.state.side:get_side_from_name("heroes")
	return side and side.PLAYER_AND_BOT_UNITS
end
cgm.force_damage = function(self, unit, damage, damager)
    damager = damager or unit
    local health_ext = ScriptUnit.extension(unit, "health_system")
    health_ext:add_damage(damager, damage, "full", "forced", nil, Vector3.up())
end

enigma:network_register(net.sync_card_property, function(sender, card_owner_peer_id, pile_name, index, property, value)
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
    local cards = pile_name and data[pile_name]
    if not cards then
        enigma:warning("Received sync_card_property with an invalid pile name")
        return
    end
    local card = index and cards[index]
    if not card then
        enigma:warning("Received sync_card_property with an invalid card index")
        return
    end
    if not property then
        enigma:warning("Received sync_card_property with an invalid property name")
        return
    end
    card[property] = value
    if card.on_property_synced then
        card:on_property_synced(property, value)
    end
end)
cgm.sync_card_property = function(self, card, property, value)
    if not property then
        enigma:warning("Cannot sync card property: "..tostring(property))
        return
    end
    local pile_name = card.location
    local pile = card.context[pile_name]
    local card_owner_peer_id = card.context.peer_id
    enigma:network_send(net.sync_card_property, "others", card_owner_peer_id, pile_name, get_card_index_in_pile(pile, card), property, value)
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

-- Hooks
local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

local bulldozer_player_set_player_unit = function(self, unit)
    if cgm.local_data then
        cgm.server_peer_id = Managers.mechanism:server_peer_id()
        cgm.local_data.player = self
        cgm.local_data.unit = self.player_unit
        cgm.data_by_unit[self.player_unit] = cgm.local_data
        if cgm.game_state == "loading" then
            cgm:check_players_and_units_all_set()
        end
    end
end
local remote_player_set_player_unit = function(self, unit)
    local peer_id = self.peer_id
    local peer_data = cgm.peer_data[peer_id]
    if peer_data then
        peer_data.player = self
        peer_data.unit = self.player_unit
        cgm.data_by_unit[self.player_unit] = peer_data
        if cgm.game_state == "loading" then
            cgm:check_players_and_units_all_set()
        end
    end
end
enigma.managers.hook:hook_safe("Enigma", BulldozerPlayer, "set_player_unit", bulldozer_player_set_player_unit, "card_game_start")
enigma.managers.hook:hook_safe("Enigma", RemotePlayer, "set_player_unit", remote_player_set_player_unit, "card_game_start")

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

local hand_channel_cancelling_status_change = function(unit, bad_status)
    if not cgm:is_in_game() then
        return
    end
    if unit == cgm.local_data.unit and bad_status then
        cgm:cancel_channel()
    end
end

reg_hook_safe(GenericStatusExtension, "set_pushed", function(self, pushed, t)
    hand_channel_cancelling_status_change(self.unit, pushed)
end, "enigma_card_game_set_pushed")

reg_hook_safe(GenericStatusExtension, "set_catapulted", function(self, catapulted, velocity)
    hand_channel_cancelling_status_change(self.unit, catapulted)
end, "enigma_card_game_set_catapulted")

reg_hook_safe(GenericStatusExtension, "set_in_vortex", function(self, in_vortex, vortex_unit)
    hand_channel_cancelling_status_change(self.unit, in_vortex)
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
        if enigma:traveling_to_inn() or enigma:traveling_to_morris_hub() or enigma:traveling_to_morris_map() then
            self:end_game()
        else
            local game_init_data = enigma.managers.deck_planner.game_init_data
            self:init_game(game_init_data.deck_name, game_init_data.cards, game_init_data.is_server)
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
    cgm.local_data.available_card_draws = cgm.local_data.available_card_draws + num
end)