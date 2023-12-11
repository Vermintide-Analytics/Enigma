local enigma = get_mod("Enigma")

local cpm = {}
enigma.managers.card_pack = cpm

cpm.card_packs = {
    base = {
        mod_id = "Enigma",
        name = "Base",
        enabled = true
    }
}

local get_pack_handle = function(pack_id)
    local pack = cpm:get_pack_by_id(pack_id)
    if not pack then
        enigma:warning("Could not find card pack \""..tostring(pack_id).."\"")
        return
    end
    local mod = get_mod(pack.mod_id)
    if not mod then
        enigma:warning("Could not find mod for card pack \""..tostring(pack_id).."\"")
        return
    end
    return {
        register_passive_cards = function(card_defs)
            for card_id,card_def in pairs(card_defs) do
                card_def.mod_id = pack.mod_id
                enigma.managers.card_template:register_passive_card(pack_id, card_id, card_def)
            end
        end,
        register_attack_cards = function(card_defs)
            for card_id,card_def in pairs(card_defs) do
                card_def.mod_id = pack.mod_id
                enigma.managers.card_template:register_attack_card(pack_id, card_id, card_def)
            end
        end,
        register_ability_cards = function(card_defs)
            for card_id,card_def in pairs(card_defs) do
                card_def.mod_id = pack.mod_id
                enigma.managers.card_template:register_ability_card(pack_id, card_id, card_def)
            end
        end,
        register_chaos_cards = function(card_defs)
            for card_id,card_def in pairs(card_defs) do
                card_def.mod_id = pack.mod_id
                enigma.managers.card_template:register_chaos_card(pack_id, card_id, card_def)
            end
        end
    }
end

cpm.register_card_pack = function(self, mod_id, pack_id, name, disabled)
    if type(mod_id) ~= "string" then
        enigma:echo_bad_function_call("register_card_pack", "mod_id", {mod_id = mod_id, pack_id = pack_id, name = name, disabled = disabled})
        return nil
    end
    if (type(pack_id) ~= "string") or pack_id:find("/") then
        enigma:echo_bad_function_call("register_card_pack", "pack_id", {mod_id = mod_id, pack_id = pack_id, name = name, disabled = disabled})
        return nil
    end
    if type(name) ~= "string" then
        enigma:echo_bad_function_call("register_card_pack", "name", {mod_id = mod_id, pack_id = pack_id, name = name, disabled = disabled})
        return nil
    end
    local enabled = not disabled
    local mod = get_mod(mod_id)
    self.card_packs[pack_id] = {
        id = pack_id,
        mod_id = mod_id,
        name = mod:localize(name),
        enabled = enabled
    }
    return get_pack_handle(pack_id)
end

cpm.get_pack_by_id = function(self, pack_id)
    if type(pack_id) ~= "string" then
        enigma:echo_bad_function_call("get_pack_by_id", "pack_id", {pack_id = pack_id})
        return nil
    end
    return self.card_packs[pack_id]
end

cpm.dump = function(self)
    enigma:dump(self.card_packs, "CARD PACKS", 2)
end
