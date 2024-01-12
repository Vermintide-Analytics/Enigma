local enigma = get_mod("Enigma")

local mim = {}
enigma.managers.mod = mim

mim.mods = {}
mim.network_lookups = {}

local create_mod_interaction_handle = function(mod_id)
    return {
        hook_safe = function(object, func_name, func, hook_id)
            enigma.managers.hook:hook_safe(mod_id, object, func_name, func, hook_id)
        end,
        unhook_safe = function(object, func_name, hook_id)
            enigma.managers.hook:unhook_safe(mod_id, object, func_name, hook_id)
        end,
        register_card_pack = function(id, name, disabled)
            return enigma.managers.card_pack:register_card_pack(mod_id, id, name, disabled)
        end,
        register_prebuilt_deck = function(name, game_mode, cards)
            if enigma.queued_prebuilt_decks then
                table.insert(enigma.queued_prebuilt_decks, {
                    mod_id = mod_id,
                    name = name,
                    game_mode = game_mode,
                    cards = cards
                })
            else
                return enigma.managers.deck_planner:create_prebuilt_deck(mod_id, name, game_mode, cards)
            end
        end,
        add_network_lookup = function(network_lookup_table, value)
            local this_mods_lookups = mim.network_lookups[mod_id] or {}
            table.insert(this_mods_lookups, {
                lookup_table = network_lookup_table,
                value = value
            })
            mim.network_lookups[mod_id] = this_mods_lookups
        end
    }
end

mim.register_mod = function(self, mod_id)
    local mod_table = get_mod(mod_id)
    if not mod_table then
        enigma:echo("Enigma could not register mod \""..tostring(mod_id).."\"")
        return
    end
    if type(mod_id) ~= "string" then
        enigma:echo_bad_function_call("register_mod", "mod_id", "mod_id", mod_id, "mod_table", mod_table)
    end
    self.mods[mod_id] = mod_table
    return create_mod_interaction_handle(mod_id)
end

mim.dump = function(self)
    enigma:dump(self.mods, "MODS", 2)
end
