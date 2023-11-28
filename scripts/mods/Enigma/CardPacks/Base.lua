local enigma = get_mod("Enigma")

local COMMON = enigma.CARD_RARITY.common
local RARE = enigma.CARD_RARITY.rare
local EPIC = enigma.CARD_RARITY.epic
local LEGENDARY = enigma.CARD_RARITY.legendary

local pack_handle = enigma.managers.card_pack:register_card_pack("Enigma", "base", "Base")

local game = enigma.managers.game
local buff = enigma.managers.buff

pack_handle.register_passive_cards({
    exfull = {
        name = "base_ex_full",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_collar_cage",
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
        condition_descriptions = {
            {
                format = "condition_description_test"
            }
        },
        channel = 10,
        ephemeral = true,
        infinite = true
    },
    ex1 = {
        name = "base_ex_1",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_collar_cage",
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
    ex2 = {
        name = "base_ex_1",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_collar_cage",
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
    caffeinated = {
        name = "base_caffeinated",
        rarity = COMMON,
        cost = 2,
        texture = "enigma_base_caffeinated",
        description_lines = {
            {
                format = "description_attack_speed",
                parameters = { 5 }
            },
            {
                format = "description_movement_speed",
                parameters = { 5 }
            }
        },
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_speed", 0.05)
            buff.update_stat(card.context.unit, "movement_speed", 0.05)
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
                format = "description_test"
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
        ephemeral = true
    },
    eshin_counter_intelligence = {
        name = "base_eshin_counter_intelligence",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_eshin_counter_intelligence",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_assassin", 1.0)
        end
    },
    executioner = {
        name = "base_executioner",
        rarity = EPIC,
        cost = 2,
        texture = "enigma_base_executioner",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_instantly_slay_man_sized_enemy", 0.05)
        end
    },
    expertise = {
        name = "base_expertise",
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_expertise",
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "cooldown_regen", 1.0)
        end
    },
    gym_rat = {
        name = "base_gym_rat",
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_gym_rat",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level", 1.0)
        end
    },
    soul_safe = {
        name = "base_soul_safe",
        rarity = LEGENDARY,
        cost = 4,
        texture = "enigma_base_soul_safe",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_leech", 1.0)
        end
    },
    spartan = {
        name = "base_spartan",
        rarity = RARE,
        cost = 1,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level_impact", 2.0)
        end
    },
    tough_skin = {
        name = "base_tough_skin",
        rarity = COMMON,
        cost = 0,
        texture = "enigma_base_tough_skin",
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "damage_taken", -0.9)
        end
    },
    veteran = {
        name = "base_veteran",
        rarity = EPIC,
        cost = 4,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level", 0.1)
        end,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_speed", 0.05)
            buff:update_stat(card.context.unit, "max_health", 0.15)
            buff:update_stat(card.context.unit, "movement_speed", 0.1)
            buff:update_stat(card.context.unit, "cooldown_regen", 0.1)
            buff:update_stat(card.context.unit, "critical_strike_chance", 0.05)
        end
    },
    warp_flesh = {
        name = "base_warp_flesh",
        rarity = RARE,
        cost = 2,
        update_server = function(card, dt)
            if card.played then
                card.next_heal_time = card.next_heal_time - dt
                if card.next_heal_time <= 0 then
                    enigma:echo("Triggering Warp-Flesh heal")
                    DamageUtils.heal_network(card.context.unit, card.context.unit, 5, "health_regen")
                    card.next_heal_time = card.next_heal_time + card.heal_interval
                end
            end
        end,
        on_play_server = function(card)
            card.played = true
            card.heal_interval = 20
            card.next_heal_time = card.heal_interval
            buff:update_stat(card.context.unit, "temporary_healing_received", -0.25)
        end
    },
})

pack_handle.register_surge_cards({
    retreat = {
        name = "base_retreat",
        rarity = RARE,
        cost = 1,
        duration = 15,
        on_surge_begin_local = function(card)
            buff:surge_stat(card.context.unit, "movement_speed", 0.5, card.duration)
            buff:surge_stat(card.context.unit, "dodge_range", 0.2, card.duration)
            buff:surge_stat(card.context.unit, "dodge_speed", 0.2, card.duration)
        end,
        events = {
            player_damaged = function(card, health_ext, _, damage_amount)
                local damaged_unit = health_ext.unit
                if damaged_unit ~= card.context.unit or damage_amount < 25 then
                    return
                end
                game.try_play_card(card)
            end
        }
    },
    stolen_bell = {
        name = "base_stolen_bell",
        rarity = RARE,
        cost = 1,
        duration = 100
    },
    warpfire_strikes = {
        name = "base_warpfire_strikes",
        rarity = COMMON,
        cost = 2,
        duration = 60,
        events = {
            enemy_damaged = function(card, health_ext, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if attacker_unit == card.context.unit then
                    -- TODO
                end
            end
        }
    },
    warpstone_pie = {
        name = "base_warpstone_pie",
        rarity = EPIC,
        cost = 1,
        duration = 31.4,
        on_surge_begin_server = function(card)
            buff:surge_stat(card.context.unit, "power_level", .314, card.duration)
            buff:surge_stat(card.context.unit, "damage_taken", -.314, card.duration)
        end,
        on_surge_begin_local = function(card)
            buff:surge_stat(card.context.unit, "movement_speed", .314, card.duration)
        end
    },
    wrath_of_khorne = {
        name = "base_wrath_of_khorne",
        rarity = EPIC,
        cost = 1,
        duration = 10,
        on_surge_begin_server = function(card)
            buff:surge_stat(card.context.unit, "chance_instantly_slay_man_sized_enemy", 1.0, card.duration)
        end
    },
})

pack_handle.register_ability_cards({
    cyclone_strike = {
        name = "base_cyclone_strike",
        rarity = RARE,
        cost = 0
    },
    ranalds_play = {
        name = "base_ranalds_play",
        rarity = LEGENDARY,
        cost = 1
    },
    long_rest = {
        name = "base_long_rest",
        rarity = LEGENDARY,
        cost = 3
    },
})