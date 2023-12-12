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
}

local cgm = {
    self_data = {},
    peer_data = {},
}
cgm.self_data = nil -- Initialize as table then set to null to shut up the Lua diagnostics complaining about accessing fields from nil
enigma.managers.game = cgm

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

local handle_local_card_played = function(card, index, location, skip_warpstone_cost, play_type)
    if not skip_warpstone_cost and not enigma.managers.warp:can_pay_cost(card.cost) then
        enigma:echo("Not enough warpstone to play ["..card.name.."]")
        return
    end
    if not skip_warpstone_cost then
        enigma.managers.warp:pay_cost(card.cost)
    end
    
    enigma:info("Playing card ["..card.id.."]")

    local can_expend_charge = card.charges and card.charges > 1
    if not can_expend_charge then
        remove_card_from_pile(cgm.self_data[card.location], card)
    end

    if cgm.is_server and card.on_play_server then
        card:on_play_server(play_type)
    end
    if card.on_play_local then
        card:on_play_local(play_type)
    end

    card.times_played = card.times_played + 1

    if can_expend_charge then
        card.charges = card.charges - 1
    else
        local destination_pile = enigma.CARD_LOCATION.discard_pile
        if card.ephemeral then
            destination_pile = enigma.CARD_LOCATION.out_of_play_pile
        end

        if card.infinite and not card.ephemeral then
            table.insert(cgm.self_data[enigma.CARD_LOCATION.draw_pile], 1, card) -- Put at bottom of draw pile
        else
            table.insert(cgm.self_data[destination_pile], card)
            card.location = destination_pile
            if card.location_changed_local then
                card:location_changed_local(location, destination_pile)
            end
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
    }

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
    enigma.random_seed = table.shuffle(card_ids, enigma.random_seed)
    
    local self_data = {
        deck_name = deck_name,
        draw_pile = {},
        hand = {},
        discard_pile = {},
        out_of_play_pile = {},

        _card_draw_gain_rate = 0,
        available_card_draws = 0,
        card_draw_gain_multiplier = 1,
    }

    self_data.available_card_draws = enigma.mega_resource_start and 99 or self_data.available_card_draws

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
        card.context = self_data
        card.owner = enigma:self_peer_id()
        card.original_owner = card.owner
        table.insert(self_data.draw_pile, card)
        if is_server then
            enigma.managers.event:_add_card_server_event_callbacks(card)
        end
        enigma.managers.event:_add_card_local_event_callbacks(card)
    end

    self.self_data = self_data
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

    for _,card in ipairs(self.self_data.draw_pile) do
        if card.on_game_start_local then
            if self.is_server and card.on_game_start_server then
                card:on_game_start_server(self.self_data)
            end
            card:on_game_start_local(self.self_data)
        end
    end

    for _,peer_data in pairs(self.peer_data) do
        for _,card in ipairs(peer_data.draw_pile) do
            if self.is_server and card.on_game_start_server then
                card:on_game_start_server(peer_data)
            end
            if card.on_game_start_remote then
                card:on_game_start_remote(peer_data)
            end
        end
    end

    if self.is_server then
        self.conflict = Managers.state.conflict
        self.pacing = self.conflict.pacing
        self.pacing_intensity = 0
        self.broadcast_pacing_intensity_interval = 5
        self.time_until_broadcast_pacing_intensity = self.broadcast_pacing_intensity_interval
    end

    enigma.managers.warp:start_game()

    self:_draw_card_for_free()
end

cgm.end_game = function(self)
    self.game_state = nil
    self.self_data = nil
    self.peer_data = {}
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
        local card = cgm.self_data[pile][index]
        if card then
            enigma:warning("Attempted to set card playable: "..card.id)
        end
        return
    end
    local card = cgm.self_data[pile][index]
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
        local card = cgm.self_data.hand[index]
        if card then
            enigma:warning("Attempted to set card auto met: "..card.id)
        end
        return
    end
    local card = cgm.self_data.hand[index]
    if not card then
        enigma:warning("Attempted to set card auto met at invalid index")
        return
    end
    card.auto_condition_server_met = met
end)
enigma:network_register(net.broadcast_pacing_intensity, function(peer_id, pacing_intensity)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card auto-trigger condition met changes")
        return
    end
    cgm.pacing_intensity = pacing_intensity
    cgm:_update_card_draw_gain_rate()
end)

cgm._update_active_channel = function(self, dt)
    if not self.self_data.active_channel then
        return
    end
    if self.self_data.active_channel.cancelled then
        self.self_data.active_channel = nil
        return
    end
    self.self_data.active_channel.remaining_duration = self.self_data.active_channel.remaining_duration - dt
    if self.self_data.active_channel.remaining_duration <= 0 then
        local card = self.self_data.active_channel.card
        local pile = self.self_data[card.location]
        local index = get_card_index_in_pile(pile, card)
        local skip_warpstone_cost = self.self_data.active_channel.skip_warpstone_cost
        local play_type = self.self_data.active_channel.play_type
        self.self_data.active_channel = nil
        handle_local_card_played(card, index, card.location, skip_warpstone_cost, play_type)
    end
end

cgm._run_local_card_updates = function(self, dt)
    if self.is_server then
        for _,card in ipairs(self.self_data.hand) do
            if card.update_server then
                card:update_server(dt)
            end
        end
        for _,card in ipairs(self.self_data.draw_pile) do
            if card.update_server then
                card:update_server(dt)
            end
        end
        for _,card in ipairs(self.self_data.discard_pile) do
            if card.update_server then
                card:update_server(dt)
            end
        end
    end
    for _,card in ipairs(self.self_data.hand) do
        if card.update_local then
            card:update_local(dt)
        end
    end
    for _,card in ipairs(self.self_data.draw_pile) do
        if card.update_local then
            card:update_local(dt)
        end
    end
    for _,card in ipairs(self.self_data.discard_pile) do
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

cgm._evaluate_local_card_conditions = function(self)
    if self.is_server then
        for _,card in ipairs(self.self_data.hand) do
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
        end
        for _,card in ipairs(self.self_data.draw_pile) do
            card.condition_server_met = (not card.condition_server) or card:condition_server() or false
        end
    end
    for _,card in ipairs(self.self_data.hand) do
        card.condition_local_met = (not card.condition_local) or card:condition_local()
        card.condition_met = card.condition_server_met and card.condition_local_met
    end
    for _,card in ipairs(self.self_data.draw_pile) do
        card.condition_local_met = (not card.condition_local) or card:condition_local() or false
        card.condition_met = card.condition_server_met and card.condition_local_met
    end
end
cgm._evaluate_local_card_autos = function(self)
    if self.is_server then
        for _,card in ipairs(self.self_data.hand) do
            card.auto_condition_server_met = (not card.auto_condition_server) or card:auto_condition_server() or false
        end
    end
    for _,card in ipairs(self.self_data.hand) do
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
local card_draw_gain_lut = {
    {
        threshold = 60,
        rate = 0.016
    },
    {
        threshold = 10,
        rate = 0.008
    }
}
cgm._update_card_draw_gain_rate = function(self)
    local rate = 1
    local local_unit = self.self_data.unit
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
    self.self_data._card_draw_gain_rate = rate
    return rate
end
cgm.update = function(self, dt)
    if self.game_state == "in_progress" then

        self:_update_active_channel(dt)
        
        self:_run_local_card_updates(dt)
        self:_run_remote_card_updates(dt)

        self:_evaluate_local_card_conditions()
        self:_evaluate_local_card_autos()

        if self.is_server then
            self:_evaluate_remote_card_conditions()
            self:_evaluate_remote_card_autos()

            self.time_until_broadcast_pacing_intensity = self.time_until_broadcast_pacing_intensity - dt
            
            if self.time_until_broadcast_pacing_intensity <= 0 then
                self.pacing_intensity = self.pacing.total_intensity
                self:_update_card_draw_gain_rate()
                enigma:network_send(net.broadcast_pacing_intensity, "others", self.pacing_intensity)
                self.time_until_broadcast_pacing_intensity = self.broadcast_pacing_intensity_interval
            end
        end

        self.self_data.available_card_draws = self.self_data.available_card_draws + (self.self_data._card_draw_gain_rate * dt)

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
    if cgm.is_server and card.location_changed_server then
        card:location_changed_server(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    if card.location_changed_remote then
        card:location_changed_remote(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
end)
cgm._draw_card_for_free = function(self)
    if #self.self_data.draw_pile < 1 then
        enigma:echo("Cannot draw a card, draw pile is empty")
        return false, "Draw pile is empty"
    end
    if #self.self_data.hand > 4 then
        enigma:echo("Cannot draw a card, hand is full")
        return false, "Hand is full"
    end
    local card = table.remove(self.self_data.draw_pile)
    if cgm.is_server and card.on_draw_server then
        card:on_draw_server()
    end
    if card.on_draw_local then
        card:on_draw_local()
    end
    table.insert(self.self_data.hand, card)
    card.location = enigma.CARD_LOCATION.hand
    if card.location_changed_local then
        card:location_changed_local(enigma.CARD_LOCATION.draw_pile, enigma.CARD_LOCATION.hand)
    end
    enigma:network_send(net.event_card_drawn, "others")
    enigma:info("Drew card ["..card.id.."]")
    return true
end
cgm.try_draw_card = function(self)
    if not self:is_in_game() then
        return false, "Not in a game"
    end
    if self.self_data.available_card_draws < 1 then
        return false, "Not enough available card draws"
    end
    local success, fail_reason = self:_draw_card_for_free()
    if success then
        self.self_data.available_card_draws = self.self_data.available_card_draws - 1
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

    card.times_played = card.times_played + 1
    
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
        if cgm.is_server and card.location_changed_server then
            card:location_changed_server(location, destination_pile)
        end
        if card.location_changed_remote then
            card:location_changed_remote(location, destination_pile)
        end
    end
end)
cgm._try_play_card_at_index_from_location = function(self, index, location, skip_warpstone_cost, play_type)
    play_type = play_type or "auto"
    if not enigma.can_play_from_location(location) then
        enigma:warning("Cannot play cards from "..tostring(location))
        return
    end
    if self.self_data.active_channel then
        enigma:info("Cannot play card, currently channeling")
        return
    end
    local card = self.self_data[location][index]
    if not card then
        enigma:echo("Attempted to play card at index "..tostring(index).." from "..location.." which only contains "..#self.self_data[location][index].. " cards")
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
        enigma:echo("Not enough warpstone to play ["..card.name.."]")
        return
    end

    if play_type ~= "auto" and card.channel and card.channel > 0 then
        self.self_data.active_channel = {
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
        if play_type == "manual" then
            enigma:echo("Cannot play a card, not in a game right now.")
        else
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return
    end
    if type(card_index) ~= "number" then
        enigma:echo("Attempted to play card from hand using non-number index: " .. tostring(card_index))
        return
    end
    if not self.self_data.hand[card_index] then
        enigma:echo("Attempted to play card "..card_index.." from hand, but hand does not have a card at that index")
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
    if not self.self_data.draw_pile[card_index] then
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
        if play_type == "manual" then
            enigma:echo("Cannot play a card, not in a game right now.")
        else
            enigma:warning("Attempted to auto play a card when not in a game")
        end
        return
    end
    if not enigma.can_play_from_location(card.location) then
        enigma:warning("Attempted to play a card from the "..tostring(card.location)..". This is not allowed")
    end
    local pile = self.self_data[card.location]
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
    local destination_pile = enigma.CARD_LOCATION.discard_pile
    table.insert(peer_data[destination_pile], card)
    card.location = destination_pile
    if cgm.is_server and card.location_changed_server then
        card:location_changed_server(pile, enigma.CARD_LOCATION.discard_pile)
    end
    if card.location_changed_remote then
        card:location_changed_remote(pile, enigma.CARD_LOCATION.discard_pile)
    end
end)
cgm.discard_card = function(self, index, from_draw_pile, discard_type)
    discard_type = discard_type or "auto"
    local pile = enigma.CARD_LOCATION.hand
    if from_draw_pile then
        pile = enigma.CARD_LOCATION.draw_pile
    end
    local card = self.self_data[pile][index]
    if not card then
        enigma:echo("Attempted to discared card at index "..tostring(index).." from "..pile.." which only contains "..#self.self_data[pile][index].. " cards")
        return
    end

    remove_card_from_pile(self.self_data[card.location], card)
    if cgm.is_server and card.on_discard_server then
        card:on_discard_server(self.self_data, discard_type)
    end
    if card.on_discard_local then
        card:on_discard_local(self.self_data, discard_type)
    end
    local destination_pile = enigma.CARD_LOCATION.discard_pile
    table.insert(self.self_data[destination_pile], card)
    card.location = destination_pile
    if card.location_changed_local then
        card:location_changed_local(pile, enigma.CARD_LOCATION.discard_pile)
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
    local draw_pile_size = #self.self_data.draw_pile
    local index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))
    local card = template:instance()
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server()
    end
    if card.on_shuffle_into_draw_pile_local then
        card:on_shuffle_into_draw_pile_local()
    end
    table.insert(self.self_data.draw_pile, index, card)
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
    if cgm.is_server and card.location_changed_server then
        card:location_changed_server(source_pile, enigma.CARD_LOCATION.draw_pile)
    end
    if card.location_changed_remote then
        card:location_changed_remote(source_pile, enigma.CARD_LOCATION.draw_pile)
    end
    table.insert(peer_data.draw_pile, destination_index, card)
end)
cgm.shuffle_card_into_draw_pile = function(self, card)
    remove_card_from_pile(self.self_data[card.location], card)
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server(self.self_data)
    end
    if card.on_shuffle_into_draw_pile_local then
        card:on_shuffle_into_draw_pile_local(self.self_data)
    end

    local draw_pile_size = #self.self_data.draw_pile
    local index = math.floor(enigma:random_range_int(1, draw_pile_size + 1))

    table.insert(self.self_data.draw_pile, index, card)
    local original_pile = card.location
    local original_pile_index = get_card_index_in_pile(self.self_data[original_pile], card)
    card.location = enigma.CARD_LOCATION.draw_pile
    if card.location_changed_local then
        card:location_changed_local(original_pile, enigma.CARD_LOCATION.draw_pile)
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
    if card.owner ~= enigma:self_peer_id() then
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
    for _,card in ipairs(self.self_data.hand) do
        card.can_pay_warpstone = enigma.managers.warp:can_pay_cost(card.cost)
    end
    for _,card in ipairs(self.self_data.draw_pile) do
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
    if not (self.self_data and self.self_data.ready) then
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
    if not cgm.self_data.player then
        return
    end
    for peer_id,peer_data in pairs(self.peer_data) do
        if not peer_data.player then
            enigma:echo("Peer data for "..peer_id.." not yet set, not starting game")
            return
        end
    end
    self.self_data.ready = true
    enigma:network_send(net.sync_players_and_units_set, "others", true)
    cgm:start_game_if_all_ready()
    return true
end

-- Utilities
cgm.player_and_bot_units = function(self)
    if not self.is_in_game then
        return
    end
    local side = Managers.state and Managers.state.side and Managers.state.side:get_side_from_name("heroes")
	return side and side.PLAYER_AND_BOT_UNITS
end


-- Hooks
local bulldozer_player_set_player_unit = function(self, unit)
    if cgm.self_data then
        cgm.server_peer_id = Managers.mechanism:server_peer_id()
        cgm.self_data.player = self
        cgm.self_data.unit = self.player_unit
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
        if cgm.game_state == "loading" then
            cgm:check_players_and_units_all_set()
        end
    end
end
enigma.managers.hook:hook_safe("Enigma", BulldozerPlayer, "set_player_unit", bulldozer_player_set_player_unit, "card_game_start")
enigma.managers.hook:hook_safe("Enigma", RemotePlayer, "set_player_unit", remote_player_set_player_unit, "card_game_start")

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
    enigma:dump(self.self_data, "SELF GAME DATA", 2)
    enigma:dump(self.peer_data, "PEER GAME DATA", 3)
    enigma:dump(self, "CARD GAME MANAGER", 0)
end

enigma:command("hand", "", function()
    enigma:echo("Cards in hand:")
    for i,card in ipairs(cgm.self_data.hand) do
        enigma:echo(" "..i..". "..card.name)
    end
end)

enigma:command("gain_draw", "", function(num)
    num = num or 1
    cgm.self_data.available_card_draws = cgm.self_data.available_card_draws + num
end)