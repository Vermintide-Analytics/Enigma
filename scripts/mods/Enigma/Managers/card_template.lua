local enigma = get_mod("Enigma")

local ctm = {}
enigma.managers.card_template = ctm

ctm.card_templates = {}

local trim_template_properties = function(card_instance)
    card_instance.instance = nil
end

local card_loc_helper = function(mod, format, parameters)
    if parameters then
        return mod:localize(format, unpack(parameters))
    end
    return mod:localize(format)
end

local refresh_card_detail_localization = function(card)
    local mod = get_mod(card.mod_id)
    for _,description_table in ipairs(card.description_lines) do
        description_table.localized = card_loc_helper(mod, description_table.format, description_table.parameters)
    end
    for _,retain_description_table in ipairs(card.retain_descriptions) do
        retain_description_table.localized = card_loc_helper(mod, retain_description_table.format, retain_description_table.parameters)
    end
    for _,auto_description_table in ipairs(card.auto_descriptions) do
        auto_description_table.localized = card_loc_helper(mod, auto_description_table.format, auto_description_table.parameters)
    end
    for _,condition_description_table in ipairs(card.condition_descriptions) do
        condition_description_table.localized = card_loc_helper(mod, condition_description_table.format, condition_description_table.parameters)
    end
end

local add_card_instance_functions = function(inst)
    inst.play = function(card)
        if card.owner ~= enigma:local_peer_id() then
            enigma:warning("("..card.id..") cannot call card:play from remote context. Must be called by the owner, or use card:request_play instead")
        else
            return enigma.managers.game:play_card(card)
        end
    end
    inst.request_play = function(card)
        if card.owner == enigma:local_peer_id() then
            return enigma.managers.game:play_card(card)
        else
            enigma.managers.game:request_play_card(card)
        end
    end
    inst.sync_property = function(card, property)
        if not property then
            enigma:warning("Cannot sync card property: "..tostring(property))
            return
        end
        enigma.managers.game:sync_card_property(card, property)
    end
    inst.rpc_others = function(card, func_name, ...)
        if not func_name then
            enigma:warning("Cannot invoke card rpc: "..tostring(func_name))
            return
        end
        enigma.managers.game:_invoke_card_rpc("others", card, func_name, ...)
    end
    inst.rpc_peer = function(card, peer_id, func_name, ...)
        if not peer_id then
            enigma:warning("Cannot invoke card rpc with no recipient: "..tostring(func_name))
        end
        if not func_name then
            enigma:warning("Cannot invoke card rpc: "..tostring(func_name))
            return
        end
        enigma.managers.game:_invoke_card_rpc(peer_id, card, func_name, ...)
    end
    inst.rpc_server = function(card, func_name, ...)
        if enigma.managers.game.is_server and card.func_name then
            enigma:pcall(card.func_name, ...)
        else
            card:rpc_peer(enigma.managers.game.server_peer_id, func_name, ...)
        end
    end
    inst.is_in_draw_pile = function(self)
        return self.location == enigma.CARD_LOCATION.draw_pile
    end
    inst.is_in_hand = function(self)
        return self.location == enigma.CARD_LOCATION.hand
    end
    inst.is_in_discard_pile = function(self)
        return self.location == enigma.CARD_LOCATION.discard_pile
    end
    inst.is_out_of_play = function(self)
        return self.location == enigma.CARD_LOCATION.out_of_play_pile
    end
    inst.set_dirty = function(self)
        refresh_card_detail_localization(self)
        self.dirty_hud_ui = true
        self.dirty_card_mode_ui = true
    end
    inst._card_cost_changed = function(self)
        if self.cost == "X" then
            local any_description_changed = false
            local description_tables = {
                self.description_lines,
                self.auto_descriptions,
                self.condition_descriptions,
                self.retain_descriptions
            }
            for _,description_table in ipairs(description_tables) do
                for _,line in ipairs(description_table) do
                    if line.x_cost_parameters then
                        for i,_ in ipairs(line.parameters) do
                            if line.x_cost_parameters[i] then
                                local x_cost_string = "X"
                                local total_modifier = self.cost_modifier + line.x_cost_parameters[i] + enigma.managers.buff:get_warpstone_cost_modifier_from_buffs(self)
                                if total_modifier > 0 then
                                    x_cost_string = "(X-"..tostring(total_modifier)..")"
                                elseif total_modifier < 0 then
                                    x_cost_string = "(X+"..tostring(total_modifier*-1)..")"
                                end
                                line.parameters[i] = x_cost_string
                                any_description_changed = true
                                enigma:info("Changed description parameter to "..tostring(x_cost_string))
                            end
                        end
                    end
                end
            end
            if any_description_changed then
                self:set_dirty()
            end
        end
    end
    inst.x_cost_modifier = function(self)

    end
end

local add_card_type_specific_properties = function(inst)
    if inst.card_type == enigma.CARD_TYPE.attack then
        inst.power_multiplier = 1
        inst.hit_enemy = function(card, hit_unit, attacking_player_unit, hit_zone_name, damage_profile, power_multiplier, is_critical_strike, break_shields)
            power_multiplier = power_multiplier * card.power_multiplier
            local custom_buffs = enigma.managers.buff.unit_custom_buffs[inst.context.unit]
            if custom_buffs then
                power_multiplier = power_multiplier * custom_buffs.attack_card_power_multiplier
            end
            enigma:hit_enemy(hit_unit, attacking_player_unit, hit_zone_name, damage_profile, power_multiplier, is_critical_strike, break_shields)
        end
        inst.damage = function(card, unit, damage, damager, damage_source)
            damage = damage * card.power_multiplier
            local custom_buffs = enigma.managers.buff.unit_custom_buffs[inst.context.unit]
            if custom_buffs then
                damage = damage * custom_buffs.attack_card_power_multiplier
            end
            enigma:force_damage(unit, damage, damager, damage_source)
        end
    end
end

local set_common_card_properties = function(template, type, pack, id)
    local mod = get_mod(template.mod_id)
    template.name = mod:localize(template.name)
    refresh_card_detail_localization(template)

    template.card_type = type
    template.card_pack = pack
    template.id = tostring(template.card_pack.id) .. "/" .. id
    
    if template.cost == "x" or template.cost == "X" then
        template.cost = "X" -- Standardize to capital X
        template.cost_modifier = 0
    elseif template.cost < 0 then
        enigma:warning("Card ["..tostring(template.id).."] is defined with a cost less than 0. Cards cannot cost less than 0")
        template.cost = 0
    end
end

local template_template = {
    location = enigma.CARD_LOCATION.draw_pile,
    on_location_changed_local = nil,
    on_location_changed_server = nil,
    on_location_changed_remote = nil,

    on_any_card_drawn_local = nil,
    on_any_card_drawn_server = nil,
    on_any_card_drawn_remote = nil,

    on_any_card_played_local = nil,
    on_any_card_played_server = nil,
    on_any_card_played_remote = nil,
    
    on_any_card_discarded_local = nil,
    on_any_card_discarded_server = nil,
    on_any_card_discarded_remote = nil,

    on_game_start_local = nil,
    on_game_start_server = nil,
    on_game_start_remote = nil,

    update_local = nil,
    update_server = nil,
    update_remote = nil,

    on_draw_local = nil,
    on_draw_server = nil,
    on_draw_remote = nil,

    on_play_local = nil,
    on_play_server = nil,
    on_play_remote = nil,

    on_discard_local = nil,
    on_discard_server = nil,
    on_discard_remote = nil,

    events_local = nil,
    events_server = nil,
    events_remote = nil,

    on_property_synced = nil,

    auto_condition_local = nil,
    auto_condition_server = nil,
    channel = nil,
    charges = nil,
    condition_local = nil,
    condition_server = nil,
    double_agent = false,
    ephemeral = false,
    echo = false,
    unplayable = false,
    warp_hungry = nil,

    hide_in_deck_editor = false,
    allow_in_deck = true,

    description_lines = {},
    retain_descriptions = {},
    auto_descriptions = {},
    condition_descriptions = {},

    sounds_2D = {
        on_draw = nil,
        on_play = nil,
        on_discard = nil,
    },
    sounds_3D = {
        on_draw = nil,
        on_play = nil,
        on_discard = nil,
    },

    instance = function(self, context)
        local inst = table.deep_copy(self, 100)
        trim_template_properties(inst)
        inst.mod = get_mod(inst.mod_id)
        if not context then
            enigma:warning("Card instanced without a context, this is not allowed")
            return nil
        end

        inst.local_id = context.next_card_local_id
        enigma:debug("New card local id: "..tostring(inst.local_id))
        table.insert(context.all_cards, inst)
        context.next_card_local_id = context.next_card_local_id + 1

        inst.owner = context.peer_id
        inst.original_owner = inst.owner

        if not inst.condition_server then
            inst.condition_server_met = true
        end
        if not inst.condition_local then
            inst.condition_local_met = true
        end
        inst.condition_met = inst.condition_server_met and inst.condition_local_met or false
        if inst.auto_condition_local and not inst.auto_condition_server then
            inst.auto_condition_server_met = true
        end
        if inst.auto_condition_server and not inst.auto_condition_local then
            inst.auto_condition_local_met = true
        end

        inst.context = context
        inst.times_played = 0
        if self.duration then
            inst.active_durations = {}
        end
        add_card_instance_functions(inst)
        add_card_type_specific_properties(inst)
        return inst
    end,
}

ctm.register_card = function(self, pack_id, card_id, card_type, card_def, additional_params)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("register_card", "id", {pack_id = pack_id, id = card_def.id, name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return false
    end
    if type(card_def.name) ~= "string" then
        enigma:echo_bad_function_call("register_card", "name", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return false
    end
    if not enigma.validate_rarity(card_def.rarity) then
        enigma:echo_bad_function_call("register_card", "rarity", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return false
    end
    if type(card_def.cost) ~= "number" and card_def.cost ~= "x" and card_def.cost ~= "X" then
        enigma:echo_bad_function_call("register_card", "cost", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return false
    end

    local pack = enigma.managers.card_pack:get_pack_by_id(pack_id)
    if not pack then
        enigma:warning("Could not register card \""..tostring(pack_id).."/"..tostring(card_id).."\", could not determine associated card pack")
        return false
    end
    if not card_def.mod_id then
        enigma:warning("Could not register card \""..tostring(pack_id).."/"..tostring(card_id).."\", could not determine associated mod")
        return false
    end

    local new_template = table.shallow_copy(template_template)
    table.merge(new_template, card_def)
    set_common_card_properties(new_template, card_type, pack, card_id)
    if additional_params then
        table.merge(new_template, additional_params)
    end

    self.card_templates[new_template.id] = new_template
    return true
end

ctm.register_passive_card = function(self, pack_id, card_id, card_def)
    return self:register_card(pack_id, card_id, enigma.CARD_TYPE.passive, card_def)
end

ctm.register_attack_card = function(self, pack_id, card_id, card_def)
    return self:register_card(pack_id, card_id, enigma.CARD_TYPE.attack, card_def)
end

ctm.register_ability_card = function(self, pack_id, card_id, card_def)
    return self:register_card(pack_id, card_id, enigma.CARD_TYPE.ability, card_def)
end

ctm.register_chaos_card = function(self, pack_id, card_id, card_def)
    return self:register_card(pack_id, card_id, enigma.CARD_TYPE.chaos, card_def)
end

ctm.get_card_from_id = function(self, scoped_card_id)
    return self.card_templates[scoped_card_id]
end

ctm.get_card_from_pack_and_id = function(self, pack_id, card_id)
    return self:get_card_from_id(pack_id.."/"..card_id)
end

ctm.get_pack_id_from_card_id = function(self, scoped_card_id)
    local delimiter_index = scoped_card_id:find("/")
    if not delimiter_index then
        return
    end
    return scoped_card_id:sub(1, delimiter_index - 1)
end

ctm.dump = function(self)
    enigma:dump(self.card_templates, "CARD TEMPLATES", 2)
end
