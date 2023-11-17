local enigma = get_mod("Enigma")

local net = {
    sync_card_game_init_data = "sync_card_game_init_data",
    notify_draw_card = "notify_draw_card",
    notify_play_card = "notify_play_card",
    sync_players_and_units_set = "sync_players_and_units_set",
    notify_shuffle_card_into_draw_pile = "notify_shuffle_card_into_draw_pile",
    notify_card_condition_satisfaction_changed = "notify_card_condition_satisfaction_changed",
    notify_card_auto_satisfaction_changed = "notify_card_auto_satisfaction_changed",
    request_server_update_cards_condition_satisfaction = "request_server_update_cards_condition_satisfaction"
}

local cgm = {
    self_data = {},
    peer_data = {},
}
cgm.self_data = nil
enigma.managers.game = cgm

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

cgm.game_state = nil

enigma:network_register(net.sync_card_game_init_data, function(peer_id, deck_name, card_ids_in_deck)
    local peer_data = {
        deck_name = deck_name,
        draw_pile = {},
        hand = {},
        discard_pile = {},
        out_of_play_pile = {}
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
        table.insert(peer_data.draw_pile, card)
    end
    if #missing_packs > 0 then
        local pack_list = table.concat(missing_packs, ", ")
        enigma:chat_whisper(peer_id, "A player is missing the following card packs, and some cards may not work properly: (".. pack_list..")")
    end

    cgm.peer_data[peer_id] = peer_data
end)
cgm.init_game = function(self, deck_name, card_templates)
    enigma:echo("Initializing Enigma game")
    self.is_server = enigma:is_server()
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

        autos_waiting_for_warpstone = {},
    }

    local card_manager = enigma.managers.card_template
    for _,card_id in ipairs(card_ids) do
        local card_template = card_manager:get_card_from_id(card_id)
        local card = card_template:instance()
        table.insert(self_data.draw_pile, card)
    end

    self_data.available_card_draws = 1

    self.self_data = self_data
    enigma:network_send(net.sync_card_game_init_data, "others", deck_name, card_ids)
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

    self:draw_card()
end

cgm.end_game = function(self)
    self.game_state = nil
end

enigma:network_register(net.notify_card_condition_satisfaction_changed, function(peer_id, pile, index, satisfied)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card condition satisfaction changes")
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
enigma:network_register(net.notify_card_auto_satisfaction_changed, function(peer_id, index, satisfied)
    if peer_id ~= cgm.server_peer_id then
        enigma:warning("Only the server is allowed to tell us when a card auto-trigger condition satisfaction changes")
        local card = cgm.self_data.hand[index]
        if card then
            enigma:warning("Attempted to set card auto satisfaction: "..card.id)
        end
        return
    end
    local card = cgm.self_data.hand[index]
    if not card then
        enigma:warning("Attempted to set card auto satisfaction at invalid index")
        return
    end
    if satisfied then -- TODO take into account local auto satisfaction?
        local played = cgm:try_play_card_from_hand(index)
        if not played then
            table.insert(cgm.self_data.autos_waiting_for_warpstone, card)
        end
    else
        local index
        for i,queued_auto_card in ipairs(cgm.self_data.autos_waiting_for_warpstone) do
            if queued_auto_card == card then
                index = i
            end
        end
        if index then
            table.remove(cgm.self_data.autos_waiting_for_warpstone, index)
        end
    end
end)
cgm.update = function(self, dt)
    if self.game_state == "in_progress" then
        -- Run local card update functions
        if self.is_server then
            for _,card in ipairs(self.self_data.hand) do
                if card.update_server then
                    card:update_server(self.self_data)
                end
            end
            for _,card in ipairs(self.self_data.draw_pile) do
                if card.update_server then
                    card:update_server(self.self_data)
                end
            end
            for _,card in ipairs(self.self_data.discard_pile) do
                if card.update_server then
                    card:update_server(self.self_data)
                end
            end
        end
        for _,card in ipairs(self.self_data.hand) do
            if card.update_local then
                card:update_local(self.self_data)
            end
        end
        for _,card in ipairs(self.self_data.draw_pile) do
            if card.update_local then
                card:update_local(self.self_data)
            end
        end
        for _,card in ipairs(self.self_data.discard_pile) do
            if card.update_local then
                card:update_local(self.self_data)
            end
        end

        -- Run local card condition functions
        for _,card in ipairs(self.self_data.hand) do
            card.server_cond_satisfied = (not self.is_server) or (not card.condition_server) or card:condition_server(self.self_data) or false
            card.local_cond_satisfied = (not card.condition_local) or card:condition_local(self.self_data) or false
            card.cond_satisfied = card.server_cond_satisfied and card.local_cond_satisfied
        end
        for _,card in ipairs(self.self_data.draw_pile) do
            card.server_cond_satisfied = (not self.is_server) or (not card.condition_server) or card:condition_server(self.self_data) or false
            card.local_cond_satisfied = (not card.condition_local) or card:condition_local(self.self_data) or false
            card.cond_satisfied = card.server_cond_satisfied and card.local_cond_satisfied
        end
        
        -- Run local card auto functions
        if self.is_server then -- TODO implement
            for _,card in ipairs(self.self_data.hand) do
                if card.auto_server and card:auto_server(self.self_data) then
                    
                end
            end
            for _,card in ipairs(self.self_data.draw_pile) do
                if card.update_server then
                    card:update_server(self.self_data)
                end
            end
            for _,card in ipairs(self.self_data.discard_pile) do
                if card.update_server then
                    card:update_server(self.self_data)
                end
            end
        end

        -- Run remote update functions
        for peer_id,peer_data in pairs(self.peer_data) do
            if self.is_server then
                for _,card in ipairs(peer_data.hand) do
                    if card.update_server then
                        card:update_server(peer_data)
                    end
                end
                for _,card in ipairs(peer_data.draw_pile) do
                    if card.update_server then
                        card:update_server(peer_data)
                    end
                end
                for _,card in ipairs(peer_data.discard_pile) do
                    if card.update_server then
                        card:update_server(peer_data)
                    end
                end
            end
            for _,card in ipairs(peer_data.hand) do
                if card.update_remote then
                    card:update_remote(peer_data)
                end
            end
            for _,card in ipairs(peer_data.draw_pile) do
                if card.update_remote then
                    card:update_remote(peer_data)
                end
            end
            for _,card in ipairs(peer_data.discard_pile) do
                if card.update_remote then
                    card:update_remote(peer_data)
                end
            end
        end
    elseif self.game_state == "loading" then
    end
end

enigma:network_register(net.notify_draw_card, function(peer_id)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end
    
    local card = table.remove(peer_data.draw_pile)
    if cgm.is_server and card.on_draw_server then
        card:on_draw_server(peer_data)
    end
    if card.on_draw_remote then
        card:on_draw_remote(peer_data)
    end
    table.insert(peer_data.hand, card)
    card.location = enigma.CARD_LOCATION.hand
end)
cgm.draw_card = function(self)
    if #self.self_data.draw_pile < 1 then
        enigma:echo("Cannot draw a card, draw pile is empty")
        return false
    end
    if #self.self_data.hand > 4 then
        enigma:echo("Cannot draw a card, hand is full")
        return false
    end
    local card = table.remove(self.self_data.draw_pile)
    if cgm.is_server and card.on_draw_server then
        card:on_draw_server(self.self_data)
    end
    if card.on_draw_local then
        card:on_draw_local(self.self_data)
    end
    table.insert(self.self_data.hand, card)
    card.location = enigma.CARD_LOCATION.hand
    enigma:network_send(net.notify_draw_card, "others")
end

enigma:network_register(net.notify_play_card, function(peer_id, index, from_draw_pile, play_type)
    local peer_data = cgm.peer_data[peer_id]
    if not peer_data then
        return
    end

    local pile = enigma.CARD_LOCATION.hand
    if from_draw_pile then
        pile = enigma.CARD_LOCATION.draw_pile
    end
    local card = table.remove(peer_data[pile], index)
    if cgm.is_server and card.on_play_server then
        card:on_play_server(peer_data, play_type)
    end
    if card.on_play_remote then
        card:on_play_remote(peer_data, play_type)
    end
    local destination_pile = enigma.CARD_LOCATION.discard_pile
    if card.ephemeral then
        destination_pile = enigma.CARD_LOCATION.out_of_play_pile
    end
    table.insert(peer_data[destination_pile], card)
    card.location = destination_pile
end)
cgm.play_card = function(self, index, from_draw_pile, play_type)
    play_type = play_type or "manual"
    local pile = enigma.CARD_LOCATION.hand
    if from_draw_pile then
        pile = enigma.CARD_LOCATION.draw_pile
    end
    local card = self.self_data[pile][index]
    if not card then
        enigma:echo("Attempted to play card at index "..tostring(index).." from "..pile.." which only contains "..#self.self_data[pile][index].. " cards")
        return
    end

    if not enigma.managers.warp:can_pay_cost(card.cost) then
        enigma:echo("Not enough warpstone to play ["..card.id.."]")
        return
    end
    enigma.managers.warp:pay_cost(card.cost)

    remove_card_from_pile(self.self_data[card.location], card)
    if cgm.is_server and card.on_play_server then
        card:on_play_server(self.self_data, play_type)
    end
    if card.on_play_local then
        card:on_play_local(self.self_data, play_type)
    end
    local destination_pile = enigma.CARD_LOCATION.discard_pile
    if card.ephemeral then
        destination_pile = enigma.CARD_LOCATION.out_of_play_pile
    end
    table.insert(self.self_data[destination_pile], card)
    card.location = destination_pile
    enigma:network_send(net.notify_play_card, "others", index, from_draw_pile, play_type)
    return true
end

cgm.try_play_card_from_hand = function(self, card_index, play_type)
    play_type = play_type or "manual"
    if type(card_index) ~= "number" then
        enigma:echo("Attempted to play card from hand using non-number index: " .. tostring(card_index))
        return
    end
    if not self.self_data.hand[card_index] then
        enigma:echo("Attempted to play card "..card_index.." from hand, but hand does not have a card at that index")
    end

    return self:play_card(card_index, false, play_type)
end

cgm.try_play_card_from_draw_pile = function(self, card_index)
    if type(card_index) ~= "number" then
        enigma:echo("Attempted to play card from draw pile using non-number index: " .. tostring(card_index))
        return
    end
    if not self.self_data.draw_pile[card_index] then
        enigma:echo("Attempted to play card "..card_index.." from draw pile, but draw pile does not have a card at that index")
    end

    return self:play_card(card_index, true, "auto")
end

enigma:network_register(net.notify_shuffle_card_into_draw_pile, function(peer_id, card_id, index)
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
cgm.shuffle_card_into_draw_pile = function(self, card_id)
    local template = enigma.managers.card_template:get_card_from_id(card_id)
    if not template then
        enigma:echo("Could not add card to draw pile, card not defined. ("..card_id..")")
        return
    end
    local draw_pile_size = #self.self_data.draw_pile
    local index = math.floor(enigma:random_range(1, draw_pile_size + 2))
    local card = template:instance()
    if cgm.is_server and card.on_shuffle_into_draw_pile_server then
        card:on_shuffle_into_draw_pile_server(self.self_data)
    end
    if card.on_shuffle_into_draw_pile_local then
        card:on_shuffle_into_draw_pile_local(self.self_data)
    end
    table.insert(self.self_data.draw_pile, index, card)
    enigma:network_send(net.notify_shuffle_card_into_draw_pile, card_id, index) 
end

cgm.on_warpstone_amount_changed = function(self)
    local card_indexes_to_remove = {}
    for _,card in ipairs(self.self_data.autos_waiting_for_warpstone) do
        if enigma.managers.warp:can_pay_cost(card.cost) then
            local index
            for i,hand_card in ipairs(self.self_data.hand) do
                if hand_card == card then
                    index = i
                end
            end
            if index then
                table.insert(card_indexes_to_remove, index)
                self:try_play_card_from_hand(index, "auto")
            end
        end
    end
    for _,index in ipairs(card_indexes_to_remove) do
        table.remove(self.self_data.autos_waiting_for_warpstone, index)
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
            self:init_game(game_init_data.deck_name, game_init_data.cards)
        end
    end
end
enigma:register_event_callback("on_game_state_changed", cgm, "on_game_state_changed")

-- Debug
cgm.dump = function(self)
    enigma:dump(self.self_data, "SELF GAME DATA", 2)
    enigma:dump(self.peer_data, "PEER GAME DATA", 3)
    enigma:dump(self, "CARD GAME MANAGER", 0)
end