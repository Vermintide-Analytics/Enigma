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

local set_common_card_properties = function(template, type, pack, id)
    local mod = get_mod(template.mod_id)
    template.name = mod:localize(template.name)
    refresh_card_detail_localization(template)

    template.card_type = type
    template.card_pack = pack
    template.id = tostring(template.card_pack.id) .. "/" .. id
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
    infinite = false,
    unplayable = false,
    warp_hungry = nil,

    description_lines = {},
    retain_descriptions = {},
    auto_descriptions = {},
    condition_descriptions = {},


    instance = function(self)
        local inst = table.deep_copy(self, 100)
        trim_template_properties(inst)
        inst.mod = get_mod(inst.mod_id)
        inst.times_played = 0
        if self.duration then
            inst.active_durations = {}
        end
        inst.sync_property = function(card, property)
            if not property then
                enigma:warning("Cannot sync card property: "..tostring(property))
                return
            end
            enigma.managers.game:sync_card_property(card, property, card[property])
        end
        return inst
    end,

    is_in_draw_pile = function(self)
        return self.location == enigma.CARD_LOCATION.draw_pile
    end,
    is_in_hand = function(self)
        return self.location == enigma.CARD_LOCATION.hand
    end,
    is_in_discard_pile = function(self)
        return self.location == enigma.CARD_LOCATION.discard_pile
    end,
    is_out_of_play = function(self)
        return self.location == enigma.CARD_LOCATION.out_of_play_pile
    end,
    set_dirty = function(self)
        refresh_card_detail_localization(self)
        self.dirty_hud_ui = true
        self.dirty_card_mode_ui = true
    end,
}

local create_card_template_handle = function(card_id)
    return {
        set_update = function(func, context)
            ctm:add_update(card_id, func, context)
        end,
        set_on_draw = function(func, context)
            ctm:add_on_draw(card_id, func, context)
        end,
        set_on_play = function(func, context)
            ctm:add_on_play(card_id, func, context)
        end,
        add_description_line = function(format, default_params)
            ctm:add_description_line(card_id, format, default_params)
        end,
        set_auto = function(condition_func, context)
            ctm:add_auto(card_id, condition_func, context)
        end,
        add_auto_description = function(description)

        end,
        set_channel = function(duration)
            ctm:add_channel(card_id, duration)
        end,
        set_condition = function(condition_func, description)
            ctm:add_condition(card_id, condition_func, description)
        end,
        set_double_agent = function()
            ctm:add_double_agent(card_id)
        end,
        set_ephemeral = function()
            ctm:add_ephemeral(card_id)
        end,
        set_infinite = function()
            ctm:add_infinite(card_id)
        end,
        set_unplayable = function()
            ctm:add_unplayable(card_id)
        end,
        set_warp_hungry = function(duration)
            ctm:add_warp_hungry(card_id, duration)
        end
    }
end

ctm.register_card = function(self, pack_id, card_id, card_type, card_def, additional_params)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("register_card", "id", {pack_id = pack_id, id = card_def.id, name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return
    end
    if type(card_def.name) ~= "string" then
        enigma:echo_bad_function_call("register_card", "name", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return
    end
    if not enigma.validate_rarity(card_def.rarity) then
        enigma:echo_bad_function_call("register_card", "rarity", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return
    end
    if type(card_def.cost) ~= "number" then
        enigma:echo_bad_function_call("register_card", "cost", {pack_id = pack_id, id = card_def.id,  name = card_def.name, rarity = card_def.rarity, cost = card_def.cost})
        return
    end

    local pack = enigma.managers.card_pack:get_pack_by_id(pack_id)
    if not pack then
        enigma:warning("Could not register card \""..tostring(pack_id).."/"..tostring(card_id).."\", could not determine associated card pack")
        return
    end
    if not card_def.mod_id then
        enigma:warning("Could not register card \""..tostring(pack_id).."/"..tostring(card_id).."\", could not determine associated mod")
        return
    end

    local new_template = table.shallow_copy(template_template)
    table.merge(new_template, card_def)
    set_common_card_properties(new_template, card_type, pack, card_id)
    if additional_params then
        table.merge(new_template, additional_params)
    end

    self.card_templates[new_template.id] = new_template
    return create_card_template_handle(new_template.id)
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

ctm.add_update = function(self, card_id, func, context)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_on_play", "card_id", {card_id = card_id, func = func})
        return
    end
    if type(func) ~= "function" then
        enigma:echo_bad_function_call("add_on_play", "func", {card_id = card_id, func = func})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add update to card \""..card_id.."\". Must register it first")
        return
    end
    context = context or "local"
    if context:find("local") then
        template.update_local = func
    end
    if context:find("server") then
        template.update_server = func
    end
    if context:find("remote") then
        template.update_remote = func
    end
end
ctm.add_on_draw = function(self, card_id, func, context)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_on_draw", "card_id", {card_id = card_id, func = func})
        return
    end
    if type(func) ~= "function" then
        enigma:echo_bad_function_call("add_on_draw", "func", {card_id = card_id, func = func})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add on_draw to card \""..card_id.."\". Must register it first")
        return
    end
    context = context or "local"
    if context:find("local") then
        template.on_draw_local = func
    end
    if context:find("server") then
        template.on_draw_server = func
    end
    if context:find("remote") then
        template.on_draw_remote = func
    end
end
ctm.add_on_play = function(self, card_id, func, context)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_on_play", "card_id", {card_id = card_id, func = func})
        return
    end
    if type(func) ~= "function" then
        enigma:echo_bad_function_call("add_on_play", "func", {card_id = card_id, func = func})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add on_play to card \""..card_id.."\". Must register it first")
        return
    end
    context = context or "local"
    if context:find("local") then
        template.on_play_local = func
    end
    if context:find("server") then
        template.on_play_server = func
    end
    if context:find("remote") then
        template.on_play_remote = func
    end
end
ctm.add_description_line = function(self, card_id, format, default_params)
    if type(format) ~= "string" then
        enigma:echo_bad_function_call("add_description_line", "format", {format = format, default_params = default_params})
        return
    end
    if type(default_params) ~= "table" then
        enigma:echo_bad_function_call("add_description_line", "default_params", {format = format, default_params = default_params})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add description line to card \""..card_id.."\". Must register it first")
        return
    end
    table.insert(template.description_lines, {
        format = format,
        parameters = default_params
    })
end
ctm.add_auto = function(self, card_id, condition_func, context)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_auto", "card_id", {card_id = card_id, condition_func = condition_func})
        return
    end
    if type(condition_func) ~= "function" then
        enigma:echo_bad_function_call("add_auto", "func", {card_id = card_id, condition_func = condition_func})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add auto to card \""..card_id.."\". Must register it first")
        return
    end
    context = context or "local"
    if context:find("local") then
        template.auto_condition_local = condition_func
    end
    if context:find("server") then
        template.auto_condition_server = condition_func
    end
end
ctm.add_auto_description = function(self, card_id, description)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_auto_description", "card_id", {card_id = card_id, description = description})
        return
    end
    if type(description) ~= "string" then
        enigma:echo_bad_function_call("add_auto_description", "description", {card_id = card_id, description = description})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add auto description to card \""..card_id.."\". Must register it first")
        return
    end
    table.insert(template.auto_descriptions, description)
end
ctm.add_channel = function(self, card_id, duration)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_channel", "card_id", "card_id", card_id, "duration", duration)
        return
    end
    if type(duration) ~= "number" then
        enigma:echo_bad_function_call("add_channel", "duration", "card_id", card_id, "duration", duration)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add channel to card \""..card_id.."\". Must register it first")
        return
    end
    template.channel = duration
end
ctm.add_condition = function(self, card_id, condition_func, context)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_condition", "card_id", {card_id = card_id, condition_func = condition_func})
        return
    end
    if type(condition_func) ~= "function" then
        enigma:echo_bad_function_call("add_condition", "func", {card_id = card_id, condition_func = condition_func})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add condition to card \""..card_id.."\". Must register it first")
        return
    end
    
    context = context or "local"
    if context:find("local") then
        template.condition_local = condition_func
    end
    if context:find("server") then
        template.condition_server = condition_func
    end
end
ctm.add_condition_description = function(self, card_id, description)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_condition", "card_id", {card_id = card_id, description = description})
        return
    end
    if type(description) ~= "string" then
        enigma:echo_bad_function_call("add_condition", "description", {card_id = card_id, description = description})
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add condition to card \""..card_id.."\". Must register it first")
        return
    end
    table.insert(template.condition_descriptions, description)
end
ctm.add_double_agent = function(self, card_id)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_double_agent", "card_id", "card_id", card_id)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add double_agent to card \""..card_id.."\". Must register it first")
        return
    end
    template.double_agent = true
end
ctm.add_ephemeral = function(self, card_id)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_ephemeral", "card_id", "card_id", card_id)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add ephemeral to card \""..card_id.."\". Must register it first")
        return
    end
    template.ephemeral = true
end
ctm.add_infinite = function(self, card_id)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_infinite", "card_id", "card_id", card_id)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add infinite to card \""..card_id.."\". Must register it first")
        return
    end
    template.infinite = true
end
ctm.add_unplayable = function(self, card_id)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_unplayable", "card_id", "card_id", card_id)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add unplayable to card \""..card_id.."\". Must register it first")
        return
    end
    template.unplayable = true
end
ctm.add_warp_hungry = function(self, card_id, duration)
    if type(card_id) ~= "string" then
        enigma:echo_bad_function_call("add_warp_hungry", "card_id", "card_id", card_id, "duration", duration)
        return
    end
    if type(duration) ~= "number" then
        enigma:echo_bad_function_call("add_warp_hungry", "duration", "card_id", card_id, "duration", duration)
        return
    end
    local template = self.card_templates[card_id]
    if not template then
        enigma:echo("Enigma could not add warp_hungry to card \""..card_id.."\". Must register it first")
        return
    end
    template.warp_hungry = duration
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
