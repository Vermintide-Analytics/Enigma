local enigma = get_mod("Enigma")

local NUM_CARDS_TO_CHOOSE_BETWEEN = 3

local net = {
    sync_beginning_deus_card_choice = "sync_beginning_deus_card_choice",
    sync_deus_card_chosen = "sync_deus_card_chosen"
}

local dm = {
    num_cards_to_choose_between = NUM_CARDS_TO_CHOOSE_BETWEEN,
    extra_cards_taken = 0,

    choosing_deus_card = false,
    waiting_for_other_player_card_choices = false,

    offered_cards = {},
}
enigma.managers.deus = dm

dm.add_extra_card_for_playthrough = function(self, card_template)
    if not card_template then
        return
    end
    local game_init_data = enigma.managers.deck_planner.game_init_data
    if not game_init_data.extra_cards then
        game_init_data.extra_cards = {}
    end
    table.insert(game_init_data.extra_cards, card_template)
    self.extra_cards_taken = self.extra_cards_taken + 1
end

dm.reset_run_data = function(self)
    self.extra_cards_taken = 0
    enigma.managers.deck_planner.game_init_data.extra_cards = nil
end

local next_non_shop_node_is_arena
next_non_shop_node_is_arena = function(deus_controller, node)
    for _,node_key in ipairs(node.next) do
        local next_node = deus_controller:get_node(node_key)
        if next_node.level_type == "ARENA" then
            return true
        end
        if next_node.level_type == "SHOP" then
            local arena_found = next_non_shop_node_is_arena(deus_controller, next_node)
            if arena_found then
                return true
            end
        end
    end
    return false
end
local card_rarity_to_offer_logic = {
    {   -- Offer legendary just before arena levels
        match = function(controller, graph, current_node)
            return next_non_shop_node_is_arena(controller, current_node)
        end,
        rarity = function() return enigma.CARD_RARITY.legendary end
    },
    {   -- Do not offer cards before the first level
        match = function(_, _, current_node)
            return current_node.level_type == "START"
        end,
        rarity = nil
    },
    {   -- DEFAULT to random rarity selection, with most being rare 
        match = function(_, _, _)
            return true
        end,
        rarity = function()
            local rand = enigma:random()
            local threshold = 1
            threshold = threshold - 0.01
            if rand > threshold then
                return enigma.CARD_RARITY.legendary
            end
            threshold = threshold - 0.25
            if rand > threshold then
                return enigma.CARD_RARITY.epic
            end
            threshold = threshold - 0.6
            if rand > threshold then
                return enigma.CARD_RARITY.rare
            end
            return enigma.CARD_RARITY.common
        end
    }
}
dm.get_card_rarity_function = function(self)
    local mechanism = Managers.mechanism:game_mechanism()
    if not mechanism or not mechanism.get_deus_run_controller then
        enigma:warning("Could not determine card rarity to offer to player, no deus mechanism: "..tostring(mechanism))
        return
    end
    local run_controller = mechanism:get_deus_run_controller()
    if not run_controller then
        enigma:warning("Could not determine card rarity to offer to player, no deus run controller")
        return
    end

    local graph = run_controller:get_graph_data()
    local node = run_controller:get_current_node()
    for _,logic in ipairs(card_rarity_to_offer_logic) do
        if logic.match(run_controller, graph, node) then
            return logic.rarity
        end
    end
end

enigma:network_register(net.sync_beginning_deus_card_choice, function(sender)
    if not dm.waiting_for_other_player_card_choices then
        dm.waiting_for_other_player_card_choices = {}
    end
    if dm.waiting_for_other_player_card_choices[sender] then
        enigma:warning("Received duplicate sync_beginning_deus_card_choice from ["..tostring(sender).."]")
    end
    dm.waiting_for_other_player_card_choices[sender] = true
end)
dm.begin_card_choice = function(self, card_rarities)
    local chosen_card_templates = {}
    local index = 1
    local random_card_predicate = function(template)
        return not template.hide_in_deck_editor and
            not template.exclude_from_random_card_effects and
            (template.card_type ~= enigma.CARD_TYPE.chaos) and
            (template.rarity == card_rarities[index]) and
            not chosen_card_templates[template]
    end
    for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
        local random_card_template = enigma:get_random_card_definition(random_card_predicate)
        index = index + 1
        enigma:info("Offering card choice: ["..tostring(random_card_template and random_card_template.id).."]")
        chosen_card_templates[random_card_template] = true
        table.insert(self.offered_cards, random_card_template)
    end

    self.choosing_deus_card = true
    enigma:network_send(net.sync_beginning_deus_card_choice, "others")
end

enigma:network_register(net.sync_deus_card_chosen, function(sender, card_id)
    if not dm.waiting_for_other_player_card_choices or not dm.waiting_for_other_player_card_choices[sender] then
        enigma:warning("Received sync_deus_card_chosen from ["..tostring(sender).."] when they have not told us they are beginning a card choice!")
        return
    end
    dm.waiting_for_other_player_card_choices[sender] = nil
    local still_waiting_for_more = false
    for _,waiting in pairs(dm.waiting_for_other_player_card_choices) do
        if waiting then
            still_waiting_for_more = true
        end
    end
    if not still_waiting_for_more then
        dm.waiting_for_other_player_card_choices = false
    end
end)
dm.card_to_add_chosen = function(self, card_template)
    self.choosing_deus_card = false
    if card_template then
        self:add_extra_card_for_playthrough(card_template)
    end
    enigma:network_send(net.sync_deus_card_chosen, "others", card_template and card_template.id)
end

dm.on_game_state_changed = function(self, status, state_name)
    if state_name == "StateIngame" and status == "enter" and Managers.level_transition_handler then
        if enigma:in_morris_map() then
            local rarity_function = self:get_card_rarity_function()
            if rarity_function then
                local rarities = {}
                for i=1,NUM_CARDS_TO_CHOOSE_BETWEEN do
                    table.insert(rarities, rarity_function())
                end
                self:begin_card_choice(rarities)
            end
        end
    elseif state_name == "StateLoading" and status == "enter" then
        self.waiting_for_other_player_card_choices = nil
        self.choosing_deus_card = false
        table.clear(self.offered_cards)
    end
end
enigma:register_mod_event_callback("on_game_state_changed", dm, "on_game_state_changed")

enigma:hook_safe(DeusRunController, "handle_run_ended", function(self)
    dm:reset_run_data()
end)

enigma:hook(DeusMapDecisionView, "_node_pressed", function(func, self, node_key)
    if dm.choosing_deus_card or dm.waiting_for_other_player_card_choices then
        return
    end
    return func(self, node_key)
end)