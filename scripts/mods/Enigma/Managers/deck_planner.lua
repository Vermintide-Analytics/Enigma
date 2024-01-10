local enigma = get_mod("Enigma")

local common = enigma.CARD_RARITY.common
local rare = enigma.CARD_RARITY.rare
local epic = enigma.CARD_RARITY.epic
local legendary = enigma.CARD_RARITY.legendary

local net = {
    sync_deck_validity = "sync_deck_validity"
}

local dpm = {
    decks = {},
    equipped_decks = {
        adventure = {},
        deus = {}
    },

    editing_deck = {},

    prebuilt_deck_names = {},

    player_data = {},
    all_players_equipped_decks_valid = false,
    
    game_init_data = {},

    initialized = false
}
dpm.editing_deck = nil -- Initialize as table then set to null to shut up the Lua diagnostics complaining about accessing fields from nil
enigma.managers.deck_planner = dpm

dpm.cp = {
    common = 1,
    rare = 2,
    epic = 4,
    legendary = 10
}

dpm.settings = {
    adventure = {
        min_cards = 10,
        max_cards = 25,
        max_cp = dpm.cp[legendary]*1 + dpm.cp[epic]*3 + dpm.cp[rare]*7 + dpm.cp[common]*14, -- 50
    },
    deus = {
        min_Cards = 6,
        max_cards = 15,
        max_cp = dpm.cp[legendary]*1 + dpm.cp[epic]*2 + dpm.cp[rare]*5 + dpm.cp[common]*7, -- 35
    }
}

local deck_template = {}

----------
-- Util --
----------
local local_peer_id
dpm.init = function(self)
    local_peer_id = Network.peer_id()
    self.player_data[local_peer_id] = {
        deck_name = "N/A",
        valid = false
    }

    self:load_save_data()
    dpm:update_self_equipped_deck_valid()
end

dpm.average_cost = function(self, deck)
    if not deck then
        return 0
    end
    local total = 0
    local count = 0
    for _,card in ipairs(deck.cards) do
        if type(card) == "table" and card.cost ~= "X" then
            total = total + card.cost
            count = count + 1
        end
    end
    return count == 0 and 0 or total / count
end

dpm.recalculate_cp = function(self, deck)
    local cp = 0
    for i, card_template in ipairs(deck.cards) do
        if type(card_template) == "table" then
            cp = cp + dpm.cp[card_template.rarity]
        end
    end
    deck.cp = cp
    return cp
end

dpm.is_cp_over_max = function(self, deck)
    return deck.cp > self:max_cp(deck.game_mode)
end

dpm.is_num_cards_under_min = function(self, deck)
    return #deck.cards < self:min_cards(deck.game_mode)
end

dpm.is_num_cards_over_max = function(self, deck)
    return #deck.cards > self:max_cards(deck.game_mode)
end

dpm.deck_is_valid = function(self, deck)
    if enigma.skip_deck_validity_check then
       return true
    end

    for i,v in ipairs(deck.cards) do
        if type(v) == "string" then
            return false, "Deck contains invalid cards" -- Deck contains cards that do not exist within installed card packs
        end
    end
    if self:is_cp_over_max(deck) then
        return false, "Deck exceeds CP limit" -- Deck exceeds cp limit
    end
    if self:is_num_cards_under_min(deck) then
        return false, "Deck does not have enough cards" -- Deck does not meet card minimum
    end
    if self:is_num_cards_over_max(deck) then
        return false, "Deck has too many cards" -- Deck exceeds card maximum
    end
    return true -- All checks passed
end

dpm.update_self_equipped_deck_valid = function(self)
    local cached_deck_name = self.player_data[local_peer_id].deck_name
    local equipped = self:equipped_deck()
    local current_deck_name = equipped and equipped.name or "N/A"
    local cached_valid = self.player_data[local_peer_id].valid
    local now_valid = self:is_equipped_deck_valid()
    if cached_valid ~= now_valid or cached_deck_name ~= current_deck_name then
        self.player_data[local_peer_id].deck_name = current_deck_name
        self.player_data[local_peer_id].valid = now_valid
        enigma.managers.ui.deck_prep_dirty = true
        self:notify_players_of_deck_validity()
    end
end
dpm.update_all_players_equipped_decks_valid = function(self)
    local all_valid = true
    for k,v in pairs(self.player_data) do
        if not v.valid then
            all_valid = false
            break
        end
    end
    self.all_players_equipped_decks_valid = all_valid
    return all_valid
end
dpm.notify_players_of_deck_validity = function(self, recipient)
    if not enigma:in_keep() then
        return
    end
    recipient = recipient or "all"
    local equipped_deck = self:equipped_deck()
    local deck_name = equipped_deck and equipped_deck.name or "N/A"
    enigma:network_send(net.sync_deck_validity, recipient, deck_name, self:is_equipped_deck_valid())
end

------------------------
-- Game mode settings --
------------------------
dpm.min_cards = function(self, game_mode)
    return self.settings[game_mode].min_cards
end
dpm.max_cards = function(self, game_mode)
    return self.settings[game_mode].max_cards
end
dpm.max_cp = function(self, game_mode)
    return self.settings[game_mode].max_cp
end

-----------------------------------
-- Deck creation/edit operations --
-----------------------------------
local on_deck_edited = function(deck)
    if dpm:equipped_deck() == deck then
        dpm:update_self_equipped_deck_valid()
    end
end

dpm.create_empty_deck = function(self, name, game_mode, skip_save)
    if self.prebuilt_deck_names[name] then
        enigma:echo("Cannot make a new deck by the name \""..name.."\" as a pre-built deck of that name already exists")
        return
    end
    local new_deck = table.shallow_copy(deck_template)
    new_deck.name = name
    new_deck.game_mode = game_mode
    new_deck.cards = {}
    new_deck.cp = 0
    self.decks[name] = new_deck
    if not skip_save then
        self:save_decks()
    end
    return new_deck
end

dpm.create_prebuilt_deck = function(self, mod_id, name, game_mode, card_ids)
    local new_deck = self:create_empty_deck(name, game_mode, true)
    if not new_deck then
        enigma:warning("Prebuilt deck \""..name.."\" from "..mod_id.." could not be added as a deck of the same name already exists")
        return
    end
    new_deck.prebuilt = true
    new_deck.prebuilt_by = mod_id

    for i, v in ipairs(card_ids) do
        self:add_card_to_deck(v, new_deck, true, true)
    end

    self.prebuilt_deck_names[name] = true
end

local alphabet_comparator = function(str1, str2)
	return str1 < str2
end
local rarity_ranks = {
    [enigma.CARD_RARITY.legendary] = 4,
    [enigma.CARD_RARITY.epic] = 3,
    [enigma.CARD_RARITY.rare] = 2,
    [enigma.CARD_RARITY.common] = 1,
}
local rarity_name_comparator = function(card_1, card_2)
    if type(card_2) == "string" then
        if type(card_1) == "string" then
            return alphabet_comparator(card_1, card_2)
        end
        return true
    end
    if type(card_1) == "string" then
        return false
    end
    if rarity_ranks[card_1.rarity] > rarity_ranks[card_2.rarity] then
        return true
    elseif rarity_ranks[card_1.rarity] < rarity_ranks[card_2.rarity] then
        return false
    end
    return alphabet_comparator(card_1.name:lower(), card_2.name:lower())
end
local add_card_to_deck_cards_sorted = function(cards, new_card_template)
    local index = 1
    local inserted = false
    while not inserted and index <= #cards do
        if rarity_name_comparator(new_card_template, cards[index]) then
            table.insert(cards, index, new_card_template)
            inserted = true
            break
        end
        index = index + 1
    end
    if not inserted then
        table.insert(cards, new_card_template)
    end
end

dpm.add_card_to_deck = function(self, card_id, deck, skip_save, force_for_prebuilt)
    if not card_id then
        enigma:echo("Must provide a card_id to add to deck")
        return false
    end
    if deck.prebuilt and not force_for_prebuilt then
        enigma:echo("Cannot add cards to pre-built decks")
        return false
    end
    local card_template = enigma.managers.card_template:get_card_from_id(card_id)
    if not card_template then
        enigma:echo("Could not find card by id ["..tostring(card_id).."]")
        return false
    end
    add_card_to_deck_cards_sorted(deck.cards, card_template)
    self:recalculate_cp(deck)
    if not skip_save then
        self:save_decks()
        on_deck_edited(deck)
    end
    return true
end

dpm.remove_card_from_deck = function(self, card_id, deck, skip_save)
    if not card_id then
        enigma:echo("Must provide a card_id to remove from a deck")
        return false
    end
    if deck.prebuilt then
        enigma:echo("Cannot remove cards from pre-built decks")
        return false
    end
    local index
    for i,v in ipairs(deck.cards) do
        if v == card_id or (type(v) == "table") and v.id == card_id then
            index = i
            break
        end
    end
    if not index then
        enigma:echo("Deck did not contain the specified card")
        return false
    end
    table.remove(deck.cards, index)
    self:recalculate_cp(deck)
    if not skip_save then
        self:save_decks()
        on_deck_edited(deck)
    end
    return true
end

dpm.remove_card_from_deck_by_index = function(self, index, deck, skip_save)
    if deck.prebuilt then
        enigma:echo("Cannot remove cards from pre-built decks")
        return false
    end
    if not index then
        enigma:echo("Deck did not contain the specified card")
        return false
    end
    table.remove(deck.cards, index)
    self:recalculate_cp(deck)
    if not skip_save then
        self:save_decks()
        on_deck_edited(deck)
    end
    return true
end

dpm.rename_deck = function(self, name, skip_save)
    if not self.editing_deck then
        enigma:echo("Not currently editing a deck, cannot rename")
        return
    end
    if self.editing_deck.prebuilt then
        enigma:echo("Cannot rename pre-built decks")
        return
    end
    if self.decks[name] then
        enigma:warning("A deck by that name already exists")
        return
    end

    local save_equipped_decks = false
    for career,deck_name in pairs(self.equipped_decks[self.editing_deck.game_mode]) do
        if deck_name == self.editing_deck.name then
            save_equipped_decks = true
            self.equipped_decks[self.editing_deck.game_mode][career] = name
        end
    end
    if save_equipped_decks then
        self:save_equipped_decks()
    end

    self.decks[name] = self.editing_deck
    self.decks[self.editing_deck.name] = nil
    self.editing_deck.name = name
    if not skip_save then
        self:save_decks()
        on_deck_edited(self.editing_deck)
    end
    return true
end

dpm.set_editing_deck_by_name = function(self, deck_name)
    if not deck_name then
        self.editing_deck = nil
        return
    end
    local deck = self.decks[deck_name]
    if not deck then
        enigma:echo("Could not find deck with name: "..tostring(deck_name))
        return
    end
    self.editing_deck = deck
    return self.editing_deck
end

dpm.set_editing_deck = function(self, deck)
    if not deck.name or not self.decks[deck.name] then
        enigma:echo("Could not set editing deck, invalid deck table")
        enigma:dump(deck, "Invalid deck", 2)
        return
    end
    self.editing_deck = deck
    return self.editing_deck
end

dpm.add_card_to_editing_deck = function(self, card_id)
    if not self.editing_deck then
        enigma:echo("Not currently editing a deck, cannot add a card")
        return false
    end
    return self:add_card_to_deck(card_id, self.editing_deck)
end

dpm.remove_card_from_editing_deck = function(self, card_id)
    if not self.editing_deck then
        enigma:echo("Not currently editing a deck, cannot remove a card")
        return false
    end
    return self:remove_card_from_deck(card_id, self.editing_deck)
end

dpm.remove_card_from_editing_deck_by_index = function(self, index)
    if not self.editing_deck then
        enigma:echo("Not currently editing a deck, cannot remove a card")
        return false
    end
    return self:remove_card_from_deck_by_index(index, self.editing_deck)
end

local delete_deck_helper = function(manager, deck_name, force, skip_save)
    if not deck_name then
        enigma:echo("Cannot delete deck, must provide a deck name")
        return false
    end
    local deck = manager.decks[deck_name]
    if not deck then
        enigma:echo("Cannot delete deck, does not exist")
        return false
    end
    if deck.prebuilt then
        enigma:echo("Cannot delete pre-built decks")
        return false
    end
    local equipped = {}
    for career_name,equipped_deck_name in pairs(manager.equipped_decks[deck.game_mode]) do
        if equipped_deck_name == deck_name then
            table.insert(equipped, {game_mode = deck.game_mode, career_name = career_name })
        end
    end
    if force then
        if #equipped > 0 then
            enigma:echo("Unequipping "..deck_name.." from "..#equipped.." careers")
        end
        for _,v in ipairs(equipped) do
            manager.equipped_decks[v.game_mode][v.career_name] = nil
        end
        if not skip_save then
            manager:save_equipped_decks()
        end
    elseif #equipped > 0 then
        enigma:echo("Cannot delete deck, currently equipped for:")
        for _,v in ipairs(equipped) do
            enigma:echo("- "..v)
        end
        return false
    end

    manager.decks[deck_name] = nil
    if manager.editing_deck and manager.editing_deck.name == deck_name then
        manager.editing_deck = nil
    end
    
    if not skip_save then
        manager:save_decks()
    end
    return true
end

dpm.delete_deck = function(self, deck_name, skip_save)
    return delete_deck_helper(self, deck_name, false, skip_save)
end

dpm.force_delete_deck = function(self, deck_name, skip_save)
    local success = delete_deck_helper(self, deck_name, true, skip_save)
    if success then
        self:update_self_equipped_deck_valid()
    end
    return success
end

-------------------
-- Equipped deck --
-------------------
dpm.equip_deck = function(self, deck_name, game_mode, career_name, skip_save)
    if enigma.managers.game:is_in_game() then
        enigma:echo("Cannot manage decks while in a game. Please return to the Keep and try again.")
        return false
    end
    if not enigma:is_game_mode_supported(game_mode) then
        enigma:echo("Cannot equip deck for unsupported game mode: "..tostring(game_mode))
        return false
    end
    if type(career_name) ~= "string" then
        enigma:echo("Cannot equip deck for invalid career: "..tostring(career_name))
        return false
    end
    self.equipped_decks[game_mode][career_name] = deck_name
    if not skip_save then
        self:save_equipped_decks()
    end
    self:update_self_equipped_deck_valid()
    return true
end

dpm.equip_deck_for_current_career_and_game_mode = function(self, deck_name, skip_save)
    local level_key = enigma:level_key()
    local game_mode
    if level_key == "inn_level" then
        game_mode = "adventure"
    elseif level_key == "morris_hub" then
        game_mode = "deus"
    end
    if not game_mode then
        enigma:echo("Could not equip deck, game mode not supported")
        return false
    end
    local career_name = enigma:local_player_career_name()
    return self:equip_deck(deck_name, game_mode, career_name, skip_save)
end

dpm.unequip_deck = function(self, game_mode, career_name, skip_save)
    if enigma.managers.game:is_in_game() then
        enigma:echo("Cannot manage decks while in a game. Please return to the Keep and try again.")
        return false
    end
    if not enigma:is_game_mode_supported(game_mode) then
        enigma:echo("Cannot unequip deck for unsupported game mode: "..tostring(game_mode))
        return false
    end
    if type(career_name) ~= "string" then
        enigma:echo("Cannot unequip deck for invalid career: "..tostring(career_name))
        return false
    end
    self.equipped_decks[game_mode][career_name] = nil
    if not skip_save then
        self:save_equipped_decks()
    end
    self:update_self_equipped_deck_valid()
    return true
end

dpm.unequip_deck_for_current_career_and_game_mode = function(self, skip_save)
    local level_key = enigma:level_key()
    local game_mode
    if level_key == "inn_level" then
        game_mode = "adventure"
    elseif level_key == "morris_hub" then
        game_mode = "deus"
    end
    if not game_mode then
        enigma:echo("Could not unequip deck, game mode not supported")
        return false
    end
    local career_name = enigma:local_player_career_name()
    return self:unequip_deck(game_mode, career_name)
end

dpm.equipped_deck = function(self)
    local game_mode = enigma:game_mode()
    if not game_mode then
        enigma:echo("Enigma could not determine equipped deck. Unable to determine current game mode.")
        return nil
    end

    local career = enigma:local_player_career_name()
    if not career then
        enigma:echo("Enigma could not determine equipped deck. Unabled to determine current career.")
        return nil
    end
    if not self.equipped_decks[game_mode][career] then
        return nil
    end
    return self.decks[self.equipped_decks[game_mode][career]]
end

dpm.is_equipped_deck_valid = function(self)
    local equipped_deck = self:equipped_deck()
    local valid, invalid_reason
    if not equipped_deck then
        valid, invalid_reason = false, "No deck equipped"
    else
        valid, invalid_reason = self:deck_is_valid(equipped_deck)
    end
    if not valid and invalid_reason then
        enigma:info("Equipped deck is not valid because: "..tostring(invalid_reason))
    end
    self.game_init_data.valid = valid
    self.game_init_data.cards = equipped_deck and equipped_deck.cards
    self.game_init_data.deck_name = equipped_deck and equipped_deck.name
    self.game_init_data.is_server = enigma:is_server()
    return valid
end

--------------------
-- Saving/Loading --
--------------------
dpm.create_deck_from_save_data = function(self, save_data)
    local new_deck = table.shallow_copy(deck_template)
    new_deck.name = save_data.name
    new_deck.game_mode =save_data.game_mode
    new_deck.cards = {}
    for i, id in ipairs(save_data.cards) do
        -- If card template does not exist (like if the card pack it came from is not enabled), the card will be stored as the id
        add_card_to_deck_cards_sorted(new_deck.cards, enigma.managers.card_template:get_card_from_id(id) or id)
    end
    self:recalculate_cp(new_deck)

    if self.prebuilt_deck_names[new_deck.name] then
        new_deck.name = new_deck.name.."_copy"
    end
    self.decks[new_deck.name] = new_deck
    return new_deck
end

dpm.create_save_data_from_deck = function(self, deck)
    if deck.prebuilt then
        return nil
    end
    local save_data = {
        name = deck.name,
        game_mode = deck.game_mode,
        cards = {}
    }
    for _, card_template in ipairs(deck.cards) do
        local card_save_data = card_template
        if type(card_template) == "table" then
            card_save_data = card_template.id
        end
        table.insert(save_data.cards, card_save_data)
    end
    return save_data
end

local DECKS_SAVE_NAME = "enigma_decks"
dpm.save_decks = function(self)
    local decks_save_data = {}
    for _,v in pairs(self.decks) do
        local deck_save_data = self:create_save_data_from_deck(v)
        if deck_save_data then
            table.insert(decks_save_data, deck_save_data)
        end
    end
    enigma:info("Saving deck data")
    enigma:save(DECKS_SAVE_NAME, decks_save_data)
end

local EQUIPPED_DECKS_SAVE_NAME = "enigma_equipped_decks"
dpm.save_equipped_decks = function(self)
    enigma:info("Saving equipped deck data")
    enigma:save(EQUIPPED_DECKS_SAVE_NAME, self.equipped_decks, nil)
end

dpm.load_decks = function(self)
    enigma:load(DECKS_SAVE_NAME, callback(self, "on_decks_loaded"))
end
dpm.on_decks_loaded = function(self, info)
    if info.error then
        enigma:info("Could not load Enigma_decks: "..tostring(info.error))
        return
    end
    for _,v in ipairs(info.data) do
        local loaded_deck = self:create_deck_from_save_data(v)
        self.decks[loaded_deck.name] = loaded_deck
    end
end

dpm.load_equipped_decks = function(self)
    enigma:load(EQUIPPED_DECKS_SAVE_NAME, callback(self, "on_equipped_decks_loaded"))
end
dpm.on_equipped_decks_loaded = function(self, info)
    if info.error then
        enigma:info("Could not load Enigma_equipped_decks: "..tostring(info.error))
        return
    end
    for game_mode,gm_table in pairs(info.data) do
        for career,deck_name in pairs(gm_table) do
            self.equipped_decks[game_mode][career] = deck_name
        end
    end
    self:update_self_equipped_deck_valid()
end

dpm.load_save_data = function(self)
    self:load_decks()
    self:load_equipped_decks()
end

-- Hooks
enigma:hook(GameModeManager, "evaluate_end_zone_activation_conditions", function(func, self)
    if enigma:in_keep() and not dpm.all_players_equipped_decks_valid then
        return false
    end
    return func(self)
end)

enigma.managers.hook:hook_safe("Enigma", BulldozerPlayer, "spawn", function(self, optional_position, optional_rotation, is_initial_spawn, ammo_melee, ammo_ranged, healthkit, potion, grenade, ability_cooldown_percent_int, additional_items, initial_buff_names)
    if not dpm.initialized then
        
        dpm:init()
        dpm.initialized = true
    else
        dpm:notify_players_of_deck_validity()
        dpm:update_all_players_equipped_decks_valid()
    end
end, "deck_planner_init")

------------
-- Events --
------------
dpm.on_user_joined = function(self, player)
    self.player_data[player.peer_id] = {
        deck_name = "N/A",
        valid = false
    }
    enigma.managers.ui.deck_prep_dirty = true
    self:notify_players_of_deck_validity(player.peer_id)
    self:update_all_players_equipped_decks_valid()
end
enigma:register_mod_event_callback("on_user_joined", dpm, "on_user_joined")

dpm.on_user_left = function(self, player)
    dpm.player_data[player.peer_id] = nil
    dpm:update_all_players_equipped_decks_valid()
end
enigma:register_mod_event_callback("on_user_left", dpm, "on_user_left")

----------
-- RPCs --
----------
enigma:network_register(net.sync_deck_validity, function(sender, deck_name, valid)
    if not enigma:in_keep() then
        return
    end
    if not dpm.player_data[sender] then
        dpm.player_data[sender] = {}
    end
    dpm.player_data[sender].deck_name = deck_name
    dpm.player_data[sender].valid = valid
    enigma.managers.ui.deck_prep_dirty = true
    dpm:update_all_players_equipped_decks_valid()
end)


---------
-- dev --
---------
dpm.deck_tostring = function(self, deck)
    local str = "["..deck.name.."]\n"
    str = str.."Game Mode: "..deck.game_mode.."\n"
    for i, card_template in ipairs(deck.cards) do
        str = str..card_template.id.."\n"
    end
    str = str.." --- "..#deck.cards.."/"..self:max_cards(deck.game_mode).." cards"
    str = str.." --- "..deck.cp.."/"..self:max_cp(deck.game_mode).." cp"
    return str
end

dpm.dump = function(self)
    enigma:dump(self.decks, "DECKS", 2)
    enigma:dump(self.equipped_decks, "EQUIPPED DECKS", 3)
    enigma:dump(self.player_data, "DECK PLAYER DATA", 3)
end