local enigma = get_mod("Enigma")

local COMMON = enigma.CARD_RARITY.common
local RARE = enigma.CARD_RARITY.rare
local EPIC = enigma.CARD_RARITY.epic
local LEGENDARY = enigma.CARD_RARITY.legendary

local pack_handle = enigma.managers.card_pack:register_card_pack("Enigma", "base", "base")

local game = enigma.managers.game
local buff = enigma.managers.buff

pack_handle.register_passive_cards({
    ex_passive = {
        name = "base_ex_passive",
        rarity = LEGENDARY,
        cost = 4,
        description_lines = {
            {
                format = "description_test"
            }
        },
        auto_descriptions = {
            {
                format = "auto_description_test"
            }
        },
        channel = 10,
        ephemeral = true,
        infinite = true
    },
    caffeinated = {
        name = "base_caffeinated",
        rarity = COMMON,
        cost = 2,
        texture = "enigma_base_caffeinated",
        description_lines = {
            {
                format = "description_attack_speed",
                parameters = { 3 }
            },
            {
                format = "description_movement_speed",
                parameters = { 5 }
            }
        },
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_speed", 0.03)
            buff:update_stat(card.context.unit, "movement_speed", 0.05)
        end
    },
    collar_cage = {
        name = "base_collar_cage",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_collar_cage",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_packmaster", 1.0)
        end,
        description_lines = {
            {
                format = "base_collar_cage_description"
            }
        },
    },
    eshin_counter_intelligence = {
        name = "base_eshin_counter_intelligence",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_eshin_counter_intelligence",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_assassin", 1.0)
        end,
        description_lines = {
            {
                format = "base_eshin_counter_intelligence_description"
            }
        }
    },
    executioner = {
        name = "base_executioner",
        rarity = EPIC,
        cost = 2,
        texture = "enigma_base_executioner",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_instantly_slay_man_sized_enemy", 0.05)
        end,
        description_lines = {
            {
                format = "description_execute_man_sized_enemy",
                parameters = { 5 }
            }
        }
    },
    expertise = {
        name = "base_expertise",
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_expertise",
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "cooldown_regen", 0.05)
        end,
        description_lines = {
            {
                format = "description_cooldown_regen",
                parameters = { 5 }
            }
        }
    },
    gym_rat = {
        name = "base_gym_rat",
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_gym_rat",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level", 0.02)
        end,
        description_lines = {
            {
                format = "description_power_level",
                parameters = { 2 }
            }
        }
    },
    soul_safe = {
        name = "base_soul_safe",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_soul_safe",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_leech", 1.0)
        end,
        description_lines = {
            {
                format = "base_soul_safe_description"
            }
        },
    },
    spartan = {
        name = "base_spartan",
        rarity = RARE,
        cost = 1,
        texture = "enigma_base_spartan",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level_impact", 0.05)
        end,
        description_lines = {
            {
                format = "description_power_level_impact",
                parameters = { 5 }
            }
        }
    },
    tough_skin = {
        name = "base_tough_skin",
        rarity = COMMON,
        cost = 0,
        texture = "enigma_base_tough_skin",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "damage_taken", -0.02)
        end,
        description_lines = {
            {
                format = "description_damage_taken",
                parameters = { -2 }
            }
        }
    },
    veteran = {
        name = "base_veteran",
        rarity = EPIC,
        cost = 4,
        texture = "enigma_base_veteran",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level", 0.1)
        end,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_speed", 0.05)
            buff:update_stat(card.context.unit, "max_health", 0.15)
            buff:update_stat(card.context.unit, "movement_speed", 0.05)
            buff:update_stat(card.context.unit, "cooldown_regen", 0.1)
            buff:update_stat(card.context.unit, "critical_strike_chance", 0.05)
        end,
        description_lines = {
            {
                format = "description_attack_speed",
                parameters = { 5 }
            },
            {
                format = "description_max_health",
                parameters = { 15 }
            },
            {
                format = "description_movement_speed",
                parameters = { 5 }
            },
            {
                format = "description_cooldown_regen",
                parameters = { 10 }
            },
            {
                format = "description_critical_strike_chance",
                parameters = { 5 }
            },
        }
    },
    warp_flesh = {
        name = "base_warp_flesh",
        rarity = RARE,
        cost = 2,
        texture = "enigma_base_warp_flesh",
        update_server = function(card, dt)
            if card.times_played > 0 then
                card.next_heal_time = card.next_heal_time - dt
                if card.next_heal_time <= 0 then
                    DamageUtils.heal_network(card.context.unit, card.context.unit, 5*card.times_played, "health_regen")
                    card.next_heal_time = card.next_heal_time + card.heal_interval
                end
            end
        end,
        on_play_server = function(card)
            card.heal_interval = 20
            card.next_heal_time = card.heal_interval
            buff:update_stat(card.context.unit, "temporary_healing_received", -0.25)
        end,
        description_lines = {
            {
                format = "description_temporary_healing_received",
                parameters = { -25 }
            },
            {
                format = "base_warp_flesh_description",
                parameters = { 5, 20 }
            }
        }
    },
})

pack_handle.register_attack_cards({
    ex_attack = {
        name = "base_ex_attack",
        rarity = LEGENDARY,
        cost = 4,
        description_lines = {
            {
                format = "description_test"
            }
        },
        auto_descriptions = {
            {
                format = "auto_description_test"
            }
        },
    },
    cyclone_strike = {
        name = "base_cyclone_strike",
        rarity = RARE,
        cost = 0,
        texture = "enigma_base_cyclone_strike",
        -- TODO implement card
        description_lines = {
            {
                format = "base_cyclone_strike_description"
            }
        }
    },
})

pack_handle.register_ability_cards({
    ex_ability = {
        name = "base_ex_ability",
        rarity = EPIC,
        cost = 4,
        description_lines = {
            {
                format = "description_test"
            }
        },
        retain_descriptions = {
            {
                format = "retain_description_test"
            }
        },
        auto_descriptions = {
            {
                format = "auto_description_test"
            }
        },
        condition_descriptions = {
            {
                format = "condition_description_test"
            }
        },
        channel = 10,
        ephemeral = true,
        infinite = true
    },
    blood_transfusion = {
        name = "base_blood_transfusion",
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_blood_transfusion",
        on_play_server = function(card)
            local us = card.context.unit
            DamageUtils.add_damage_network(us, us, 15, "full", "health_degen", nil, Vector3.up(), "health_degen")
            local health_ext = ScriptUnit.extension(us, "health_system")
            health_ext:add_damage(us, 15, "full", "forced", nil, Vector3.up())

            local players_and_bots = game:player_and_bot_units()
            for _,unit in ipairs(players_and_bots) do
                if unit ~= card.context.unit then
                    DamageUtils.heal_network(unit, us, 15, "health_regen")
                end
            end
        end,
        infinite = true,
        description_lines = {
            {
                format = "description_take_damage",
                parameters = { 15 }
            },
            {
                format = "base_blood_transfusion_description",
                parameters = { 15 }
            }
        }
    },
    divine_insurance = {
        name = "base_divine_insurance",
        rarity = EPIC,
        cost = 2,
        texture = "enigma_base_divine_insurance",
        duration = 60,
        on_play_server = function(card)
            if card.disabler_unit then
                enigma:execute_unit(card.disabler_unit, card.context.unit)
            end
            buff:surge_stat(card.context.unit, "chance_ignore_assassin", 1, card.duration)
            buff:surge_stat(card.context.unit, "chance_ignore_leech", 1, card.duration)
            buff:surge_stat(card.context.unit, "chance_ignore_packmaster", 1, card.duration)
        end,
        events_server = {
            player_disabled = function(card, disabled_unit, disable_type, disabler)
                if not card:is_in_hand() then
                    return
                end
                enigma:info("DIVINE INSURANCE PLAYER DISABLED")
                if disabled_unit == card.context.unit then
                    card.disabler_unit = disabler
                    game:try_play_card(card)
                else
                    enigma:info("Disabled unit aint us!")
                end
            end
        },
        unplayable = true,
        description_lines = {
            {
                format = "base_divine_insurance_description"
            }
        },
        auto_descriptions = {
            {
                format = "base_divine_insurance_auto"
            }
        }
    },
    dubious_insurance = {
        name = "base_dubious_insurance",
        rarity = EPIC,
        cost = 0,
        texture = "enigma_base_dubious_insurance",
        on_play_server = function(card)
            if card.disabler_unit then
                enigma:execute_unit(card.disabler_unit, card.context.unit)
            end
        end,
        events_server = {
            player_disabled = function(card, disabled_unit, disable_type, disabler)
                if not card:is_in_hand() then
                    return
                end
                enigma:info("DUBIOUS INSURANCE PLAYER DISABLED")
                if disabled_unit == card.context.unit then
                    card.disabler_unit = disabler
                    game:try_play_card(card)
                else
                    enigma:info("Disabled unit aint us!")
                end
            end
        },
        unplayable = true,
        description_lines = {
            {
                format = "base_dubious_insurance_description"
            }
        },
        auto_descriptions = {
            {
                format = "base_dubious_insurance_auto"
            }
        }
    },
    long_rest = {
        name = "base_long_rest",
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_long_rest",
        on_play_local = function(card)
            local discard_pile = game.self_data.discard_pile
            local to_return_to_draw_pile = math.min(5, #discard_pile)
            local indexes = enigma:n_random_indexes(#discard_pile, to_return_to_draw_pile)
            for i=to_return_to_draw_pile,1,-1 do
                game:shuffle_card_into_draw_pile(discard_pile[indexes[i]])
            end
        end,
        channel = 10,
        ephemeral = true,
        description_lines = {
            {
                format = "base_long_rest_description",
                parameters = { 5 }
            }
        }
    },
    ranalds_play = {
        name = "base_ranalds_play",
        rarity = LEGENDARY,
        cost = 1,
        texture = "enigma_base_ranalds_play",
        on_play_local = function(card)
            local hand_size = #game.self_data.hand
            if hand_size < 1 then
                return -- If no other cards in hand... nothing happens! Too bad!
            end
            local card_index = enigma:random_range_int(1, hand_size)
            game:try_play_card_from_hand(card_index, true)
        end,
        description_lines = {
            {
                format = "base_ranalds_play_description"
            }
        },
        auto_descriptions = {
            {
                format = "base_ranalds_play_auto"
            }
        }
    },
    retreat = {
        name = "base_retreat",
        rarity = RARE,
        cost = 1,
        duration = 15,
        texture = "enigma_base_retreat",
        on_surge_begin_local = function(card)
            buff:surge_stat(card.context.unit, "movement_speed", 0.5, card.duration)
            buff:surge_stat(card.context.unit, "dodge_range", 0.3, card.duration)
            buff:surge_stat(card.context.unit, "dodge_speed", 0.3, card.duration)
        end,
        events_local = {
            player_damaged = function(card, health_ext, _, damage_amount)
                local damaged_unit = health_ext.unit
                if damaged_unit ~= card.context.unit or damage_amount < 25 then
                    return
                end
                game.try_play_card(card)
            end
        },
        description_lines = {
            {
                format = "description_movement_speed",
                parameters = { 50 }
            },
            {
                format = "description_dodge_range",
                parameters = { 30 }
            },
            {
                format = "description_dodge_speed",
                parameters = { 30 }
            },
        },
        auto_descriptions = {
            {
                format = "base_retreat_auto_description",
                parameters = { 25 }
            }
        }
    },
    spare_engine = {
        name = "base_spare_engine",
        rarity = RARE,
        cost = 1,
        texture = "enigma_base_spare_engine",
        warp_dust_increase = 0.1,
        card_draw_increase = 0.25,
        location_changed_local = function(card, old, new)
            if new == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_increase)
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_increase)
            elseif old == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_increase * -1)
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_increase * -1)
            end
        end,
        retain_descriptions = {
            {
                format = "base_spare_engine_retain",
                parameters = { 10, 25 }
            },
        }
    },
    stolen_bell = {
        name = "base_stolen_bell",
        rarity = RARE,
        cost = 1,
        duration = 100,
        texture = "enigma_base_stolen_bell",
        -- TODO implement card
        description_lines = {
            {
                format = "base_stolen_bell_description"
            },
            {
                format = "description_power_level_skaven",
                parameters = { 35 }
            }
        }
    },
    ubersreik_hero = {
        name = "base_ubersreik_hero",
        rarity = RARE,
        cost = 1,
        texture = "enigma_base_ubersreik_hero",
        on_play_server = function(card)
            -- Find closest disabled ally and kill their disabler
            local us = card.context.unit
            local closest_unit_status = nil
            local closest_distance = nil
            
            local players_and_bots = game:player_and_bot_units()
            for _,unit in pairs(players_and_bots) do
                if unit ~= us then
                    local status = ScriptUnit.extension(unit, "status_system")
                    if status:is_disabled() then
                        local distance = enigma:distance_between_units(unit, us)
                        if closest_distance == nil or distance < closest_distance then
                            closest_distance = distance
                            closest_unit_status = status
                        end
                    end
                end
            end
            if not closest_unit_status then
                enigma:warning("Ubersreik Hero could not find a disabled ally when it was played!")
                return
            end
            local disabler = closest_unit_status:get_disabler_unit()
            if not disabler then
                enigma:warning("Ubersreik Hero could not find the disabler unit when it was played!")
                return
            end
            enigma:execute_unit(disabler, us)
        end,
        condition_local = function(card)
            -- At least one ally is disabled
            local players_and_bots = game:player_and_bot_units()
            for _,unit in ipairs(players_and_bots) do
                if unit ~= card.context.unit then -- Skip ourselves
                    local status = ScriptUnit.extension(unit, "status_system")
                    if status:is_disabled() then
                        return true
                    end
                end
            end
            return false
        end,
        description_lines = {
            {
                format = "base_ubersreik_hero_description"
            }
        },
        condition_descriptions = {
            {
                format = "base_ubersreik_hero_condition"
            }
        }
    },
    warpfire_strikes = {
        name = "base_warpfire_strikes",
        rarity = COMMON,
        cost = 2,
        duration = 60,
        texture = "enigma_base_warpfire_strikes",
        events_server = {
            enemy_damaged = function(card, health_ext, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if not card.surging then
                    return
                end
                if attacker_unit == card.context.unit then
                    -- TODO implement card
                end
            end
        },
        description_lines = {
            {
                format = "base_warpfire_strikes_description"
            }
        }
    },
    warpstone_pie = {
        name = "base_warpstone_pie",
        rarity = EPIC,
        cost = 1,
        duration = 31.4,
        texture = "enigma_base_warpstone_pie",
        on_surge_begin_server = function(card)
            buff:surge_stat(card.context.unit, "power_level", .314, card.duration)
            buff:surge_stat(card.context.unit, "damage_taken", -.314, card.duration)
        end,
        on_surge_begin_local = function(card)
            buff:surge_stat(card.context.unit, "movement_speed", -.314, card.duration)
        end,
        description_lines = {
            {
                format = "description_power_level",
                parameters = { 31.4 }
            },
            {
                format = "description_damage_taken",
                parameters = { -31.4 }
            },
            {
                format = "description_movement_speed",
                parameters = { -31.4 }
            },
        }
    },
    wrath_of_khorne = {
        name = "base_wrath_of_khorne",
        rarity = EPIC,
        cost = 1,
        duration = 10,
        texture = "enigma_base_wrath_of_khorne",
        on_surge_begin_server = function(card)
            buff:surge_stat(card.context.unit, "chance_instantly_slay_man_sized_enemy", 1.0, card.duration)
        end,
        description_lines = {
            {
                format = "description_execute_man_sized_enemy",
                parameters = { 100 }
            }
        }
    },
})

pack_handle.register_chaos_cards({
    
    ex_chaos = {
        name = "base_ex_chaos",
        rarity = EPIC,
        cost = 4,
        description_lines = {
            {
                format = "description_test"
            }
        },
        retain_descriptions = {
            {
                format = "retain_description_test"
            }
        },
        auto_descriptions = {
            {
                format = "auto_description_test"
            }
        },
        condition_descriptions = {
            {
                format = "condition_description_test"
            }
        },
        channel = 10,
        ephemeral = true,
        infinite = true
    },
})