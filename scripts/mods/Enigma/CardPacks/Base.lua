local enigma = get_mod("Enigma")

dofile("scripts/mods/Enigma/CardPacks/Base_explosion_templates")

local COMMON = enigma.CARD_RARITY.common
local RARE = enigma.CARD_RARITY.rare
local EPIC = enigma.CARD_RARITY.epic
local LEGENDARY = enigma.CARD_RARITY.legendary

local X = "X"

local pack_handle = enigma.managers.card_pack:register_card_pack("Enigma", "base", "base")

local game = enigma.managers.game
local buff = enigma.managers.buff
local warp = enigma.managers.warp

--[[ CARD DEFINITION TEMPLATE

    CARD_NAME = {
        rarity = RARITY,
        cost = COST,
        texture = false,
        on_play_local = function(card)

        end,
        description_lines = {
            {
                format = DESCRIPTION_LINE_1,
                parameters = { PARAMETER_1 }
            }
        }
    },

]]

local passive_cards = {
    bigger_bombs = {
        rarity = RARE,
        cost = 1,
        texture = true,
        grenade_radius_modifier = 0.2,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "grenade_radius", card.grenade_radius_modifier)
        end,
        description_lines = {
            {
                format = "description_grenade_radius",
                parameters = { 20 }
            }
        }
    },
    burly = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        max_health_modifier = 0.1,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "max_health", card.max_health_modifier)
        end,
        description_lines = {
            {
                format = "description_max_health",
                parameters = { 10 }
            }
        }
    },
    caffeinated = {
        rarity = COMMON,
        cost = 2,
        texture = true,
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
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_packmaster", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_collar_cage_description"
            }
        },
    },
    controlled_breathing = {
        rarity = EPIC,
        cost = 2,
        texture = true,
        stamina_regen_modifier = 0.3,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "fatigue_regen", card.stamina_regen_modifier)
        end,
        description_lines = {
            {
                format = "description_stamina_regen",
                parameters = { 30 }
            }
        }
    },
    cooperation = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        revive_speed_modifier = -0.15,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "faster_revive", card.revive_speed_modifier)
        end,
        description_lines = {
            {
                format = "description_revive_speed",
                parameters = { -15 }
            }
        }
    },
    doctors_orders = {
        rarity = EPIC,
        cost = 1,
        texture = true,
        healing_received_modifier = 0.25,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "healing_received", card.healing_received_modifier)
        end,
        description_lines = {
            {
                format = "description_healing_received",
                parameters = { 25 }
            }
        }
    },
    dogged_warrior = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        respawn_speed_modifier = -0.2,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "faster_respawn", card.respawn_speed_modifier)
        end,
        description_lines = {
            {
                format = "description_respawn_speed",
                parameters = { -20 }
            }
        }
    },
    dormant_crystal = {
        rarity = EPIC,
        cost = 0,
        texture = true,
        texture_tint = nil,
        variant = nil,
        variants = {
            {
                -- Red
                color = {
                    255,
                    255,
                    0,
                    0
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "power_level", 0.2)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "power_level", -0.2)
                end,
                retain_descriptions = {
                    {
                        format = "description_power_level",
                        parameters = { 20 }
                    }
                }
            },
            {
                -- Yellow
                color = {
                    255,
                    255,
                    255,
                    0
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "movement_speed", 0.3)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "movement_speed", -0.3)
                end,
                retain_descriptions = {
                    {
                        format = "description_movement_speed",
                        parameters = { 30 }
                    }
                }
            },
            {
                -- Blue
                color = {
                    255,
                    0,
                    0,
                    255
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "fatigue_regen", 0.5)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "fatigue_regen", -0.5)
                end,
                retain_descriptions = {
                    {
                        format = "description_stamina_regen",
                        parameters = { 50 }
                    }
                }
            },
            {
                -- Green
                color = {
                    255,
                    0,
                    255,
                    0
                },
                activate_func = function(card)
                    card:rpc_server("start_health_regen", 1, 3)
                end,
                deactivate_func = function(card)
                    card:rpc_server("end_health_regen")
                end,
                retain_descriptions = {
                    {
                        format = "description_health_regen_per_second",
                        parameters = { 3 }
                    }
                }
            },
            {
                -- Purple
                color = {
                    255,
                    255,
                    0,
                    255
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "attack_speed", 0.2)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "attack_speed", -0.2)
                end,
                retain_descriptions = {
                    {
                        format = "description_attack_speed",
                        parameters = { 20 }
                    }
                }
            },
            {
                -- Cyan
                color = {
                    255,
                    0,
                    255,
                    255
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "cooldown_regen", 1.5)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "cooldown_regen", -1.5)
                end,
                retain_descriptions = {
                    {
                        format = "description_cooldown_regen",
                        parameters = { 150 }
                    }
                }
            },
            {
                -- White
                color = {
                    255,
                    255,
                    255,
                    255
                },
                activate_func = function(card)
                    buff:update_stat(card.context.unit, "critical_strike_chance", 0.2)
                end,
                deactivate_func = function(card)
                    buff:update_stat(card.context.unit, "critical_strike_chance", -0.2)
                end,
                retain_descriptions = {
                    {
                        format = "description_critical_strike_chance",
                        parameters = { 20 }
                    }
                }
            },
        },
        start_health_regen = function(card, interval, amount)
            card.heal_interval = interval
            card.heal_amount = amount
            card.time_until_next_heal = card.heal_interval

            card.update_server = function(card, dt)
                -- This card transcends time so reverse the effect of any time scale
                dt = dt / Managers.time._global_time_scale
                card.time_until_next_heal = card.time_until_next_heal - dt
                if card.time_until_next_heal <= 0 then
                    card.time_until_next_heal = card.time_until_next_heal + card.heal_interval
                    enigma:heal(card.context.unit, card.heal_amount)
                end
            end
        end,
        end_health_regen = function(card)
            card.heal_interval = nil
            card.heal_amount = nil
            card.time_until_next_heal = nil

            card.update_server = nil
        end,
        init_local = function(card)
            -- Choose a random color/effect, this card will turn into that version when activated later
            local index = enigma:random_range_int(1, #card.variants)
            local variant = card.variants[index]
            card.texture_tint = variant.color
            card.variant_activate = variant.activate_func
            card.variant_deactivate = variant.deactivate_func
            card.activated_retain_descriptions = variant.retain_descriptions

            for _,description in ipairs(card.activated_retain_descriptions) do
                description.activated = true
            end
            card.variants = nil

            card:set_dirty()
        end,
        activate = function(card)
            enigma:info("Activating Dormant Crystal")
            card.texture = "enigma_base_dormant_crystal_activated"
            card:variant_activate()

            for _,description in ipairs(card.activated_retain_descriptions) do
                table.insert(card.retain_descriptions, description)
            end
            card.unplayable = true
            card:set_dirty()
        end,
        deactivate = function(card)
            enigma:info("Deactivating Dormant Crystal")
            card.texture = "enigma_base_dormant_crystal"
            card:variant_deactivate()

            local retain_description_indexes_to_remove = {}
            for i,description in ipairs(card.retain_descriptions) do
                if description.activated then
                    table.insert(retain_description_indexes_to_remove, i)
                end
            end
            for i=#retain_description_indexes_to_remove,1,-1 do
                table.remove(card.retain_descriptions, retain_description_indexes_to_remove[i])
            end
            card.unplayable = false
            card:set_dirty()
        end,
        description_lines = {
            {
                format = "base_dormant_crystal_description",
            }
        },

        hide_in_deck_editor = true,
        allow_in_deck = false
    },
    efficient_strikes = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "added_card_cost_attack", -1)
        end,
        description_lines = {
            {
                format = "base_efficient_strikes_description",
                parameters = { 1 }
            }
        }
    },
    eshin_counter_intelligence = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_assassin", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_eshin_counter_intelligence_description"
            }
        }
    },
    enchanted_shield = {
        rarity = EPIC,
        cost = 1,
        texture = true,
        block_cost_modifier = -0.1,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "block_cost", card.block_cost_modifier)
        end,
        description_lines = {
            {
                format = "description_block_cost",
                parameters = { -10 }
            }
        }
    },
    executioner = {
        rarity = EPIC,
        cost = 2,
        texture = true,
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
    exertion = {
        rarity = RARE,
        cost = 1,
        texture = true,
        push_power_modifier = 0.15,
        push_range_modifier = 0.1,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "push_power", card.push_power_modifier)
            buff:update_stat(card.context.unit, "push_range", card.push_range_modifier)
        end,
        description_lines = {
            {
                format = "description_push_power",
                parameters = { 15 }
            },
            {
                format = "description_push_range",
                parameters = { 10 }
            },
        }
    },
    extra_munitions = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        max_ammo_modifier = 0.1,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "total_ammo", card.max_ammo_modifier)
        end,
        description_lines = {
            {
                format = "description_max_ammo",
                parameters = { 10 }
            }
        }
    },
    expertise = {
        rarity = COMMON,
        cost = 1,
        texture = true,
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
    fancy_footwork = {
        rarity = COMMON,
        cost = 3,
        texture = true,
        dodge_range_modifier = 0.2,
        dodge_speed_modifier = 0.25,
        on_play_local = function(card)
            local us = card.context.unit
            buff:update_stat(us, "dodge_range", card.dodge_range_modifier)
            buff:update_stat(us, "dodge_speed", card.dodge_speed_modifier)
        end,
        description_lines = {
            {
                format = "description_dodge_range",
                parameters = { 20 }
            },
            {
                format = "description_dodge_speed",
                parameters = { 25 }
            },
        }
    },
    gym_rat = {
        rarity = COMMON,
        cost = 1,
        texture = true,
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
    khornes_pact = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        power_boost_per_damage_dealt = 0.0006,
        shared_damage_multiplier = 0.2,
        calculated_power_boost = 0,
        last_applied_power_boost = 0,
        power_boost_update_interval = 5,
        time_until_power_boost_update = 0,
        on_play_server = function(card)
            card.time_until_power_boost_update = card.power_boost_update_interval
        end,
        update_server = function(card, dt)
            if card.times_played > 0 then
                card.time_until_power_boost_update = card.time_until_power_boost_update - dt
                if card.time_until_power_boost_update <= 0 then
                    card.time_until_power_boost_update = card.time_until_power_boost_update + card.power_boost_update_interval
                    local buff_difference = card.calculated_power_boost - card.last_applied_power_boost
                    card.last_applied_power_boost = card.calculated_power_boost
                    if buff_difference ~= 0 then
                        buff:update_stat(card.context.unit, "power_level", buff_difference)
                    end
                end
                local power_boost_lerp_amount = dt * 0.1
                card.calculated_power_boost = math.lerp(card.calculated_power_boost, 0, power_boost_lerp_amount)
            end
        end,
        events_server = {
            enemy_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if card.times_played > 0 then
                    local attacker = attacker_unit or source_attacker_unit
                    local breed = attacker and Unit.get_data(attacker, "breed")
                    if not breed or not breed.is_player or attacker == card.context.unit then
                        return
                    end
                    card.calculated_power_boost = card.calculated_power_boost + card.power_boost_per_damage_dealt * damage_amount
                end
            end,
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if card.times_played > 0 then
                    local damaged_unit = self.unit
                    local us = card.context.unit
                    if damaged_unit == us or damage_type == "temporary_health_degen" then
                        return
                    end
                    enigma:force_damage(us, damage_amount * card.shared_damage_multiplier, us)
                end
            end,
        },
        ephemeral = true,
        description_lines = {
            {
                format = "base_khornes_pact_description",
            }
        }
    },
    plated_armor = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_gunner", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_plated_armor_description"
            }
        },
    },
    precise_thrusts = {
        rarity = RARE,
        cost = 2,
        texture = true,
        crit_chance_modifier = 0.04,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "critical_strike_chance_melee", card.crit_chance_modifier)
        end,
        description_lines = {
            {
                format = "description_critical_strike_chance_melee",
                parameters = { 4 }
            }
        }
    },
    refined_parts = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        reload_speed_modifier = -0.05,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "reload_speed", card.reload_speed_modifier)
        end,
        description_lines = {
            {
                format = "description_reload_speed",
                parameters = { -5 }
            }
        }
    },
    sharpshooter = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        crit_chance_modifier = 0.02,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "critical_strike_chance_ranged", card.crit_chance_modifier)
        end,
        description_lines = {
            {
                format = "description_critical_strike_chance_ranged",
                parameters = { 2 }
            }
        }
    },
    soul_safe = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_leech", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_soul_safe_description"
            }
        },
    },
    spartan = {
        rarity = RARE,
        cost = 1,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level_impact", 0.08)
        end,
        description_lines = {
            {
                format = "description_power_level_impact",
                parameters = { 8 }
            }
        }
    },
    the_gas_mask = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_globadier", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_the_gas_mask_description"
            }
        },
    },
    the_mill = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        effect_interval = 60,
        time_until_next_effect = 0,
        update_local = function(card, dt)
            if card.times_played > 0 then
                card.time_until_next_effect = card.time_until_next_effect - dt
                if card.time_until_next_effect <= 0 then
                    card.time_until_next_effect = card.time_until_next_effect + card.effect_interval
                    for i=1,card.times_played do
                        if #game.local_data.hand > 4 then
                            local random_hand_index = enigma:random_range_int(1, 5)
                            local random_card_to_discard = game.local_data.hand[random_hand_index]
                            game:discard_card(random_card_to_discard)
                        end
                        game:draw_card()
                    end
                end
            end
        end,
        on_play_local = function(card)
            if card.times_played < 1 then
                card.time_until_next_effect = card.effect_interval
            end
        end,
        ephemeral = true,
        description_lines = {
            {
                format = "base_the_mill_description",
                parameters = { 60 }
            }
        }
    },
    thermal_suit = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_fire_rat", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_thermal_suit_description"
            }
        },
    },
    tough_skin = {
        rarity = COMMON,
        cost = 0,
        texture = true,
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
    training_weights = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_blightstorm_damage", 1.0)

            local status = ScriptUnit.extension(card.context.unit, "status_system")
            if status:is_in_vortex() and status.in_vortex_unit then
                local vortex_ext = ScriptUnit.has_extension(status.in_vortex_unit, "ai_supplementary_system") and ScriptUnit.extension(status.in_vortex_unit, "ai_supplementary_system")
                if vortex_ext and vortex_ext._owner_unit then
                    enigma:execute_unit(vortex_ext._owner_unit, card.context.unit)
                end
                card.update_server = function(card, dt)
                    if not status:is_in_vortex() then
                        if not card.out_of_vortex_seconds then
                            card.out_of_vortex_seconds = 0
                        else
                            card.out_of_vortex_seconds = card.out_of_vortex_seconds + dt
                            if card.out_of_vortex_seconds > 2 then
                                card.update_server = nil
                                buff:update_stat(card.context.unit, "chance_ignore_blightstormer", 1.0)
                            end
                        end
                    else
                        card.out_of_vortex_seconds = 0
                    end
                end
            else
                buff:update_stat(card.context.unit, "chance_ignore_blightstormer", 1.0)
            end
        end,
        sounds_2D = {
            on_play = "legendary_buff"
        },
        description_lines = {
            {
                format = "base_training_weights_description"
            }
        },
    },
    veteran = {
        rarity = EPIC,
        cost = 4,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "power_level", 0.1)
        end,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_speed", 0.03)
            buff:update_stat(card.context.unit, "max_health", 0.15)
            buff:update_stat(card.context.unit, "movement_speed", 0.05)
            buff:update_stat(card.context.unit, "cooldown_regen", 0.1)
            buff:update_stat(card.context.unit, "critical_strike_chance", 0.03)
        end,
        description_lines = {
            {
                format = "description_attack_speed",
                parameters = { 3 }
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
                parameters = { 3 }
            },
        }
    },
    warding_charm = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        curse_resistance_modifier = -0.2,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "curse_protection", card.curse_resistance_modifier)
        end,
        description_lines = {
            {
                format = "description_curse_resistance",
                parameters = { 20 }
            }
        }
    },
    warp_flesh = {
        rarity = RARE,
        cost = 2,
        texture = true,
        update_server = function(card, dt)
            if card.times_played > 0 then
                card.next_heal_time = card.next_heal_time - dt
                if card.next_heal_time <= 0 then
                    card.next_heal_time = card.next_heal_time + card.heal_interval
                    enigma:heal(card.context.unit, 5*card.times_played)
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
    weakpoint_exploiter = {
        rarity = RARE,
        cost = 2,
        texture = true,
        crit_power_modifier = 0.05,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "critical_strike_effectiveness", card.crit_power_modifier)
        end,
        description_lines = {
            {
                format = "description_critical_strike_power",
                parameters = { 5 }
            }
        }
    },
}

local attack_cards = {
    counterattack = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        block_time_threshold = 2,
        time_since_last_block = 2,
        last_blocked_unit = nil,
        on_play_server = function(card)
            local us = card.context.unit
            local enemy = card.last_blocked_unit
            if Unit.alive(us) and Unit.alive(enemy) then
                card:hit_enemy(enemy, us, nil, DamageProfileTemplates.medium_pointy_smiter_flat_1h, 3)
            end
        end,
        update_local = function(card, dt)
            card.time_since_last_block = card.time_since_last_block + dt
        end,
        condition_local = function(card)
            local enemy_alive = Unit.alive(card.last_blocked_unit) and card.last_blocked_unit_health_extension and card.last_blocked_unit_health_extension:is_alive()
            return enemy_alive and card.time_since_last_block < card.block_time_threshold
        end,
        events_local = {
            player_block = function(card, blocker_unit, blocked_unit, fatigue_type)
                if blocker_unit == card.context.unit then
                    card.last_blocked_unit = blocked_unit
                    card.last_blocked_unit_health_extension = ScriptUnit.extension(blocked_unit, "health_system")
                    card.time_since_last_block = 0
                end
            end
        },
        events_server = {
            player_block = function(card, blocker_unit, blocked_unit, fatigue_type)
                if blocker_unit == card.context.unit then
                    card.last_blocked_unit = blocked_unit
                end
            end
        },
        echo = true,
        description_lines = {
            {
                format = "base_counterattack_description"
            }
        },
        condition_descriptions = {
            {
                format = "base_counterattack_condition",
                parameters = { 2 }
            }
        }
    },
    cyclone_strike = {
        rarity = RARE,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 6)
            for _,unit in ipairs(nearby_ai_units) do
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_slashing_linesman, 5)
            end
        end,
        sounds_3D = {
            on_play = "slice"
        },
        description_lines = {
            {
                format = "base_cyclone_strike_description"
            }
        }
    },
    omnistrike = {
        rarity = EPIC,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local enemies = enigma:get_all_enemies()
            for _,unit in ipairs(enemies) do
                if Unit.alive(unit) then
                    card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_slashing_linesman, 3)
                end
            end
        end,
        description_lines = {
            {
                format = "base_omnistrike_description"
            }
        }
    },
    quick_stab = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local ai_units_to_stab = enigma:get_ai_units_in_front_of_unit(us, 3, 90)
            for _,unit in ipairs(ai_units_to_stab) do
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.medium_pointy_smiter_flat_1h, 1.5)
            end
        end,
        on_play_local = function(card)
            game:draw_card()
        end,
        description_lines = {
            {
                format = "base_quick_stab_description"
            },
            {
                format = "description_draw_a_card"
            }
        }
    },
    slam = {
        rarity = EPIC,
        cost = 1,
        texture = true,
        damage_enemies = function(card)
            local us = card.context.unit
            enigma:create_explosion(us, enigma:unit_position(us), Quaternion.identity(), "grenade_no_ff", 1, "undefined", nil, false)
        end,
        on_play_local = function(card)
            local us = card.context.unit
            enigma:apply_no_clip(us, "enigma_base_slam")
            enigma:apply_perk(us, "immovable")
            enigma:leap_forward(us, 0.5, 0.1, 10, {
                finished = function(this, aborted, final_position)
                    card:rpc_server("damage_enemies")
                    enigma:remove_no_clip(us, "enigma_base_slam")
                    enigma:remove_perk(us, "immovable")
                end
            })
        end,
        condition_local = function(card)
            return enigma:on_ground(card.context.unit)
        end,
        description_lines = {
            {
                format = "base_slam_description"
            }
        }
    },
    thrash = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 2.5)
            for _,unit in ipairs(nearby_ai_units) do
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_blunt_tank, 8)
            end
        end,
        on_draw_local = function(card)
            local cost = enigma:random_range_int(0, 2)
            game:set_card_cost(card, cost)
        end,
        description_lines = {
            {
                format = "base_thrash_description",
                parameters = { }
            },
            {
                format = "base_thrash_description_drawn",
                parameters = { 0, 2 }
            }
        }
    },
}

local ability_cards = {
    -- example_x_cost_card = {
    --     rarity = COMMON,
    --     cost = X,
    --     texture = false,
    --     on_play_local = function(card, play_type, net_x_cost)
    --         buff:surge_stat(card.context.unit, "attack_speed", 0.33*(net_x_cost+2), 10)
    --     end,
    --     description_lines = {
    --         {
    --             format = "example_x_cost_card_description",
    --             parameters = { 33, "X" },
    --             x_cost_parameters = { false, 2 }
    --         }
    --     }
    -- },

    blood_transfusion = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            enigma:force_damage(card.context.unit, 40)

            local players_and_bots = enigma:player_and_bot_units()
            if #players_and_bots > 1 then
                local total_health_to_distribute = 60
                local divided = total_health_to_distribute / (#players_and_bots - 1)
                for _,unit in ipairs(players_and_bots) do
                    if unit ~= card.context.unit then
                        enigma:heal(unit, divided, us)
                    end
                end
            end
        end,
        echo = true,
        description_lines = {
            {
                format = "description_take_damage",
                parameters = { 40 }
            },
            {
                format = "base_blood_transfusion_description",
                parameters = { 60 }
            }
        }
    },
    delayed_bomb = {
        rarity = RARE,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            enigma:invoke_delayed(function()
                enigma:create_explosion(card.context.unit, enigma:unit_position(card.context.unit), Quaternion.identity(), "grenade_no_ff_scaled_x3", 1, "undefined", nil, false)
            end, 60)
        end,
        description_lines = {
            {
                format = "base_delayed_bomb_description",
                parameters = { 60 }
            }
        }
    },
    divine_insurance = {
        rarity = EPIC,
        cost = 2,
        texture = true,
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
                if disabled_unit == card.context.unit then
                    local disabler_health = ScriptUnit.extension(disabler, "health_system")
                    if not disabler_health:is_dead() then
                        card.disabler_unit = disabler
                        card:request_play()
                    end
                end
            end
        },
        unplayable = true,
        sounds_3D = {
            on_play = "harmonious_bell"
        },
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
    douse = {
        rarity = RARE,
        cost = 0,
        texture = true,
        on_play_local = function(card)
            enigma:remove_overcharge_fraction(card.context.unit, 1)
        end,
        charges = 4,
        description_lines = {
            {
                format = "base_douse_description"
            },
        }
    },
    dubious_insurance = {
        rarity = EPIC,
        cost = 0,
        texture = true,
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
                if disabled_unit == card.context.unit then
                    local disabler_health = ScriptUnit.extension(disabler, "health_system")
                    if not disabler_health:is_dead() then
                        card.disabler_unit = disabler
                        card:request_play()
                    end
                end
            end
        },
        unplayable = true,
        sounds_3D = {
            on_play = "dissonant_bell"
        },
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
    field_medicine = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            enigma:heal(us, 20)
        end,
        charges = 5,
        channel = 1,
        description_lines = {
            {
                format = "description_restore_health",
                parameters = { 20 }
            },
        }
    },
    gluttonous_jug = {
        rarity = RARE,
        cost = 1,
        texture = true,
        on_play_local = function(card)
            game:draw_card()
            game:draw_card()
        end,
        description_lines = {
            {
                format = "description_draw_cards",
                parameters = { 2 }
            }
        }
    },
    honorable_duel = {
        rarity = EPIC,
        cost = 3,
        texture = true,
        power_level_boost = 0.2,
        attack_speed_boost = 0.2,
        in_duel = false,
        start_duel = function(card, monster_unit)
            local player_unit = card.context.unit
            if card.dueling_monster then
                enigma:warning("Could not start Honorable Duel, we were already dueling a monster...")
                return
            end
            enigma:info("Starting Honorable Duel between "..tostring(player_unit).." and "..tostring(monster_unit))
            card.in_duel = true
            buff:update_stat(player_unit, "power_level", card.power_level_boost)
            buff:update_stat(player_unit, "attack_speed", card.attack_speed_boost)

            enigma:push_unit_untargetable(player_unit)
            Unit.set_data(player_unit, "can_only_damage_unit", monster_unit)
            Unit.set_data(player_unit, "can_only_be_damaged_by_unit", monster_unit)
            Unit.set_data(player_unit, "enigma_base_honorable_dueling", monster_unit)
            
            enigma:set_taunt_unit(monster_unit, player_unit, true)
            Unit.set_data(monster_unit, "can_only_damage_unit", player_unit)
            Unit.set_data(monster_unit, "can_only_be_damaged_by_unit", player_unit)
            Unit.set_data(monster_unit, "enigma_base_honorable_dueling", player_unit)

            card.living_monsters[monster_unit] = "dueling"
            card.dueling_monster = monster_unit
        end,
        end_duel = function(card)
            local player_unit = card.context.unit
            local monster_unit = card.dueling_monster

            local player_alive = Unit.alive(player_unit)
            local monster_alive = Unit.alive(monster_unit)

            if not monster_unit then
                enigma:warning("Could not end Honorable Duel, we were not dueling a monster...")
                return
            end
            enigma:info("Ending Honorable Duel between "..tostring(player_unit).." and "..tostring(monster_unit))
            card.in_duel = false
            buff:update_stat(player_unit, "power_level", card.power_level_boost * -1)
            buff:update_stat(player_unit, "attack_speed", card.attack_speed_boost * -1)

            if player_alive then
                enigma:pop_unit_untargetable(player_unit)
                Unit.set_data(player_unit, "can_only_damage_unit", nil)
                Unit.set_data(player_unit, "can_only_be_damaged_by_unit", nil)
                Unit.set_data(player_unit, "enigma_base_honorable_dueling", nil)
            end
            if monster_alive then
                enigma:unset_taunt_unit(monster_unit)
                Unit.set_data(monster_unit, "can_only_damage_unit", nil)
                Unit.set_data(monster_unit, "can_only_be_damaged_by_unit", nil)
                Unit.set_data(monster_unit, "enigma_base_honorable_dueling", nil)
            end
            
            card.living_monsters[monster_unit] = monster_alive and "alive" or nil
            card.dueling_monster = nil
        end,
        init_server = function(card)
            card.living_monsters = {}
        end,
        on_play_server = function(card)
            local us = card.context.unit
            local closest_monster = nil
            local closest_distance = math.huge
            if card.living_monsters then
                for unit,state in pairs(card.living_monsters) do
                    if state == "alive" then
                        local distance = enigma:distance_between_units(us, unit)
                        if distance < closest_distance then
                            closest_distance = distance
                            closest_monster = unit
                        end
                    end
                end
            end
            if closest_monster then
                card:start_duel(closest_monster)
            end
        end,
        on_any_card_played_server = function(card, played_card)
            if played_card.id == "base/honorable_duel" then
                for unit,_ in pairs(card.living_monsters) do
                    local alive = Unit.alive(unit)
                    local dueling = alive and Unit.has_data(unit, "enigma_base_honorable_dueling") and Unit.get_data(unit, "enigma_base_honorable_dueling")
                    card.living_monsters[unit] = dueling and "dueling" or alive and "alive" or nil
                end
            end
        end,
        update_server = function(card, dt)
            if card.dueling_monster and not Unit.alive(card.dueling_monster) then
                card:end_duel()
            end
        end,
        condition_server = function(card)
            if not card.living_monsters then
                return false
            end
            for unit,state in pairs(card.living_monsters) do
                if state == "alive" then
                    if not Unit.alive(unit) then
                        card.living_monsters[unit] = nil
                    end
                    return true
                end
            end
            return false
        end,
        events_server = {
            enemy_spawned = function(card, spawned_unit, breed, ...)
                if enigma:breed_is_monster(breed) then
                    card.living_monsters[spawned_unit] = "alive"
                end
            end,
            enemy_killed = function(card, killed_unit, killing_blow)
                local breed = Unit.get_data(killed_unit, "breed")
                if not enigma:breed_is_monster(breed) then
                    return
                end
                
                card.living_monsters[killed_unit] = nil

                local us = card.context.unit
                if killed_unit == card.dueling_monster then
                    card:end_duel()
                end
            end,
            player_killed = function(card, killed_unit, killing_blow)
                local us = card.context.unit
                if killed_unit ~= us then
                    return
                end
                if card.dueling_monster then
                    card:end_duel()
                end
            end,
        },
        description_lines = {
            {
                format = "base_honorable_duel_description",
                parameters = { 20, 20 }
            }
        },
        condition_descriptions = {
            {
                format = "base_honorable_duel_condition"
            }
        },
    },
    long_rest = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_local = function(card)
            local discard_pile = game.local_data.discard_pile
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
    harness_discord = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        duration = 15,
        on_game_start_local = function()
            for i=1,4 do
                game:shuffle_new_card_into_draw_pile("base/dormant_crystal")
            end
        end,
        multiply_time_scale = function(card, multiplier)
            enigma:multiply_time_scale(multiplier)
        end,
        on_play_local = function(card)
            local time_multiplier = 1
            local increased_duration_per_crystal = 0.25
            local crystals = card.context:get_cards_in_hand("base/dormant_crystal")
            time_multiplier = time_multiplier + (#crystals * increased_duration_per_crystal)

            local effect = 4 -- Slow down time to 1/effect
            local effect_inv = 1 / effect
            local calculated_duration = card.duration * effect_inv * time_multiplier

            enigma:multiply_time_scale(effect_inv)
            card:rpc_others("multiply_time_scale", effect_inv)
            enigma:multiply_player_gravity_scale(card.context.unit, effect)
            enigma:multiply_player_movement_speed(card.context.unit, effect)

            local multiply_stat = function(stat_name, stat_base_value, multiplier)
                local current_value = buff:get_current_stat_value(card.context.unit, stat_name)
                local desired_value = (current_value + stat_base_value) * multiplier - stat_base_value
                local buff_amount = desired_value - current_value
                buff:update_stat(card.context.unit, stat_name, buff_amount)
            end
            local divide_stat = function(stat_name, multiplier)
                local buff_amount = (1 - 1/multiplier) * -1
                buff:update_stat(card.context.unit, stat_name, buff_amount)
            end
            local undivide_stat = function(stat_name, multiplier)
                local buff_amount = (1 - 1/multiplier)
                buff:update_stat(card.context.unit, stat_name, buff_amount)
            end
            
            for _,crystal in ipairs(crystals) do
                crystal:activate()
            end

            multiply_stat("attack_speed", 1, effect)
            multiply_stat("cooldown_regen", 1, effect)
            multiply_stat("vent_speed", 1, effect)
            multiply_stat("dodge_speed", 0, effect)
            multiply_stat("jump_force", 0, effect/2)
            divide_stat("reload_speed", effect)
            multiply_stat("overcharge_regen", 1, effect)
            multiply_stat("fatigue_regen", 1, effect)
            divide_stat("faster_revive", effect)
            divide_stat("reduced_ranged_charge_time", effect)

            enigma:invoke_delayed(function()
                enigma:multiply_time_scale(effect)
                card:rpc_others("multiply_time_scale", effect)
                enigma:multiply_player_gravity_scale(card.context.unit, effect_inv)
                enigma:multiply_player_movement_speed(card.context.unit, effect_inv)

                multiply_stat("attack_speed", 1, effect_inv)
                multiply_stat("cooldown_regen", 1, effect_inv)
                multiply_stat("vent_speed", 1, effect_inv)
                multiply_stat("dodge_speed", 0, effect_inv)
                multiply_stat("jump_force", 0, effect_inv*2)
                undivide_stat("reload_speed", effect)
                multiply_stat("overcharge_regen", 1, effect_inv)
                multiply_stat("fatigue_regen", 1, effect_inv)
                undivide_stat("faster_revive", effect)
                undivide_stat("reduced_ranged_charge_time", effect)

                for _,crystal in ipairs(crystals) do
                    crystal:deactivate()
                    game:discard_card(crystal)
                end
            end, calculated_duration)
        end,
        description_lines = {
            {
                format = "base_harness_discord_description_game_start",
                parameters = { 4 }
            },
            {
                format = "base_harness_discord_description",
                parameters = { 75, 25 }
            },
        }
    },
    planestrider = {
        rarity = RARE,
        cost = 1,
        texture = true,
        duration = 15,
        dodge_range_modifier = 1.0,
        dodge_speed_modifier = 3.0,
        no_clipping = false,
        on_play_local = function(card)
            buff:surge_stat(card.context.unit, "dodge_range", card.dodge_range_modifier, card.duration)
            buff:surge_stat(card.context.unit, "dodge_speed", card.dodge_speed_modifier, card.duration)
        end,
        charges = 3,
        events_local = {
            player_dodge = function(card, unit, direction)
                if #card.active_durations < 1 then
                    return
                end
                card.no_clipping = card.id.."/"..card.local_id
                enigma:apply_no_clip(card.context.unit, card.no_clipping)
            end,
            player_dodge_finished = function(card, unit)
                if not card.no_clipping then
                    return
                end
                enigma:remove_no_clip(card.context.unit, card.no_clipping)
                card.no_clipping = false
            end
        },
        description_lines = {
            {
                format = "description_dodge_range",
                parameters = { 100 }
            },
            {
                format = "description_dodge_speed",
                parameters = { 300 }
            },
        }
    },
    quick_stimulants = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            enigma:heal(us, 25, us, "heal_from_proc")
        end,
        charges = 5,
        description_lines = {
            {
                format = "description_restore_temporary_health",
                parameters = { 25 }
            },
        }
    },
    ranalds_bounty = {
        rarity = EPIC,
        cost = 1,
        texture = true,
        on_play_local = function(card)
            local random_card_template = enigma:get_random_card_definition()
            local new_card = game:add_new_card_to_hand(random_card_template.id)
            game:set_card_cost(new_card, 0)
        end,
        description_lines = {
            {
                format = "base_ranalds_bounty_description",
                parameters = { 0 }
            }
        }
    },
    ranalds_play = {
        rarity = LEGENDARY,
        cost = 1,
        texture = true,
        auto_play_chance_interval = 1,
        time_until_auto_play_chance = 1,
        auto_play_chance = 0.000577456, -- ~50% chance to auto play approximately for 20 minutes spent in your hand
        on_play_local = function(card)
            local hand_size = #game.local_data.hand
            if hand_size < 1 then
                return -- If no other cards in hand... nothing happens! Too bad!
            end
            local card_index = enigma:random_range_int(1, hand_size)
            game:play_card_from_hand(card_index, true)
        end,
        update_local = function(card, dt)
            if card:is_in_hand() then
                card.time_until_auto_play_chance = card.time_until_auto_play_chance - dt
                if card.time_until_auto_play_chance <= 0 then
                    if enigma:test_chance(card.auto_play_chance) then
                        card:play()
                    end
                    card.time_until_auto_play_chance = card.time_until_auto_play_chance + card.auto_play_chance_interval
                end
            end
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
    rat_banker = {
        rarity = EPIC,
        cost = 0,
        texture = true,
        principal = 0,
        interest = 0,
        compound_interval = 5,
        time_until_next_compound = 5,
        interest_rate = 0.012,
        update_local = function(card, dt)
            if card:is_in_hand() then
                card.time_until_next_compound = card.time_until_next_compound - dt
                if card.time_until_next_compound <= 0 then
                    card.time_until_next_compound = card.time_until_next_compound + card.compound_interval
                    local current_total = card.principal + card.interest
                    local new_interest = current_total * card.interest_rate
                    card.interest = card.interest + new_interest
                    card.description_lines[3].parameters[1] = current_total + new_interest
                    card:set_dirty()
                end
            end
        end,
        on_draw_local = function(card)
            card.time_until_next_compound = card.compound_interval
            local current_warpstone = warp:get_warpstone()
            warp:remove_warpstone(current_warpstone)
            card.principal = current_warpstone
            card.description_lines[1].parameters[1] = card.principal
            card.description_lines[3].parameters[1] = card.principal
            card:set_dirty()
        end,
        on_play_local = function(card)
            warp:add_warpstone(card.principal + card.interest)
            card.principal = 0
            card.interest = 0
        end,
        description_lines = {
            {
                format = "base_rat_banker_description_on_draw",
                parameters = { 0 }
            },
            {
                format = "base_rat_banker_description_interest",
            },
            {
                format = "base_rat_banker_description_on_play",
                parameters = { 0 }
            }
        }
    },
    retreat = {
        rarity = RARE,
        cost = 1,
        duration = 15,
        texture = true,
        on_play_local = function(card)
            buff:surge_stat(card.context.unit, "movement_speed", 0.5, card.duration)
            buff:surge_stat(card.context.unit, "dodge_range", 0.3, card.duration)
            buff:surge_stat(card.context.unit, "dodge_speed", 0.3, card.duration)
        end,
        events_local = {
            player_damaged = function(card, health_ext, _, damage_amount)
                if not card:is_in_hand() then
                    return
                end
                local damaged_unit = health_ext.unit
                if damaged_unit ~= card.context.unit or damage_amount < 60 then
                    return
                end
                card:play()
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
                parameters = { 60 }
            }
        }
    },
    revitalize = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        on_play_local = function(card)
            local cards = card.context:get_cards_in_discard_pile(function(c) return c.card_type == enigma.CARD_TYPE.attack end)
            for _,attack_card in ipairs(cards) do
                game:shuffle_card_into_draw_pile(attack_card)
            end
        end,
        description_lines = {
            {
                format = "base_revitalize_description",
            }
        }
    },
    spare_engine = {
        rarity = RARE,
        cost = 1,
        texture = true,
        warp_dust_increase = 0.15,
        on_location_changed_local = function(card, old, new)
            if new == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_increase)
            elseif old == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_increase * -1)
            end
        end,
        retain_descriptions = {
            {
                format = "base_spare_engine_retain",
                parameters = { 15 }
            },
        }
    },
    stolen_bell = {
        rarity = RARE,
        cost = 1,
        duration = 100,
        skaven_aggro_modifier = 50,
        power_level_skaven_modifier = 0.35,
        texture = true,
        on_play_server = function(card)
            buff:surge_stat(card.context.unit, "aggro_skaven", card.skaven_aggro_modifier, card.duration)
            buff:surge_stat(card.context.unit, "power_level_skaven", card.power_level_skaven_modifier, card.duration)
        end,
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
    the_red_raven = {
        rarity = LEGENDARY,
        cost = 5,
        texture = true,
        card_draw_multiplier_modifier = -0.30,
        draw_additional = true,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_multiplier_modifier)
            elseif old == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_multiplier_modifier * -1)
            end
        end,
        on_any_card_drawn_local = function(card, drawn_card)
            if card:is_in_hand() and drawn_card ~= card then
                if card.draw_additional then
                    card.draw_additional = false -- Don't trigger ourselves from this additional card draw
                    game:draw_card()
                else
                    card.draw_additional = true
                end
            end
        end,
        ephemeral = true,
        retain_descriptions = {
            {
                format = "base_the_red_raven_retain",
            },
            {
                format = "description_card_draw",
                parameters = { -30 }
            },
        }
    },
    ubersreik_hero = {
        rarity = RARE,
        cost = 1,
        texture = true,
        on_play_server = function(card)
            -- Find closest disabled ally and kill their disabler
            local us = card.context.unit
            local closest_unit_status = nil
            local closest_distance = nil
            
            local players_and_bots = enigma:player_and_bot_units()
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
            local players_and_bots = enigma:player_and_bot_units()
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
    vault = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        charges = 3,
        rotation_duration = 0.9,
        rotation_progress = 0,
        rotating = false,
        update_local = function(card, dt)
            if card.rotating then
                card.rotation_progress = card.rotation_progress + dt
                if card.rotation_progress > card.rotation_duration then
                    card.rotating = false
                end
                local player_rotation = enigma:lerp_yaw_pitch_roll(card.starting_yaw, card.starting_pitch, card.starting_roll, card.target_yaw, card.target_pitch, card.target_roll, card.rotation_progress / card.rotation_duration)
                enigma:set_first_person_rotation(card.context.unit, player_rotation)
            end
        end,
        on_play_local = function(card)
            enigma:apply_no_clip(card.context.unit, "enigma_base_vault")
            enigma:leap_forward(card.context.unit, 7, 7, 6, {
                finished = function(this, aborted, final_position)
                    enigma:remove_no_clip(card.context.unit, "enigma_base_vault")
                end
            })
            local first_person = ScriptUnit.extension(card.context.unit, "first_person_system")
            local starting_rotation = first_person:current_rotation()
            card.starting_yaw = Quaternion.yaw(starting_rotation)
            card.starting_pitch = Quaternion.pitch(starting_rotation)
            card.starting_roll = Quaternion.roll(starting_rotation)
            card.target_yaw = card.starting_yaw
            card.target_pitch = card.starting_pitch + math.rad(-180)
            card.target_roll = card.starting_roll + math.rad(180)
            card.rotating = true
            card.rotation_progress = 0
        end,
        condition_local = function(card)
            return enigma:on_ground(card.context.unit)
        end,
        description_lines = {
            {
                format = "base_vault_description"
            }
        }
    },
    warpfire_strikes = {
        rarity = COMMON,
        cost = 2,
        duration = 60,
        texture = true,
        on_play_local = function(card)
            -- TODO implement card
            enigma:echo(card.name.." "..enigma:localize("not_yet_implemented"))
        end,
        events_server = {
            enemy_damaged = function(card, health_ext, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if #card.active_durations < 1 then
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
        rarity = EPIC,
        cost = 1,
        duration = 31.4,
        texture = true,
        on_play_server = function(card)
            buff:surge_stat(card.context.unit, "power_level", .314, card.duration)
            buff:surge_stat(card.context.unit, "damage_taken", -.314, card.duration)
        end,
        on_play_local = function(card)
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
    warpstone_vapors = {
        rarity = RARE,
        cost = 2,
        texture = true,
        duration = 120,
        cooldown_regen_modifier = 1.75,
        on_play_local = function(card)
            buff:surge_stat(card.context.unit, "cooldown_regen", card.cooldown_regen_modifier, card.duration)
        end,
        description_lines = {
            {
                format = "description_cooldown_regen",
                parameters = { 175 }
            }
        }
    },
    warp_charge_reserve = {
        rarity = EPIC,
        cost = 1,
        texture = true,
        on_play_local = function(card)
            local charge_cards = card.context:get_cards_in_hand(function(c) return c.charges end)
            for _,charge_card in ipairs(charge_cards) do
                charge_card.charges = charge_card.charges + 1
                charge_card:set_dirty()
            end
        end,
        ephemeral = true,
        description_lines = {
            {
                format = "base_warp_charge_reserve_description",
                parameters = { 1 }
            }
        }
    },
    wrath_of_khorne = {
        rarity = EPIC,
        cost = 1,
        duration = 10,
        texture = true,
        on_play_server = function(card)
            buff:surge_stat(card.context.unit, "chance_instantly_slay_man_sized_enemy", 1.0, card.duration)
        end,
        description_lines = {
            {
                format = "description_execute_man_sized_enemy",
                parameters = { 100 }
            }
        }
    },
}

local chaos_cards = {
    incompetence = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        warp_dust_decrease = -0.1,
        card_draw_decrease = -0.1,
        on_location_changed_local = function(card, old, new)
            if new == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_decrease)
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_decrease)
            elseif old == "hand" then
                buff:update_stat(card.context.unit, "warp_dust_multiplier", card.warp_dust_decrease * -1)
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_decrease * -1)
            end
        end,
        retain_descriptions = {
            {
                format = "base_incompetence_retain",
                parameters = { -10, -10 }
            }
        },
        ephemeral = true
    },
    injury = {
        rarity = EPIC,
        cost = 0,
        times_drawn = 0,
        damage_per_draw = 5,
        texture = true,
        on_draw_server = function(card)
            card.times_drawn = card.times_drawn + 1
        end,
        on_draw_local = function(card)
            card.times_drawn = card.times_drawn + 1
            card.description_lines[1].parameters[2] = card.damage_per_draw * card.times_drawn
            card:set_dirty()
        end,
        on_play_server = function(card)
            enigma:force_damage(card.context.unit, card.damage_per_draw * card.times_drawn)
        end,
        description_lines = {
            {
                format = "base_injury_description",
                parameters = { 5, 0 }
            },
        },
        echo = true
    },
    life_sap = {
        rarity = RARE,
        cost = 2,
        texture = true,
        on_any_card_drawn_server = function(card, other_card)
            if not card:is_in_hand() or other_card == card then
                return
            end
            enigma:force_damage(card.context.unit, 10)
        end,
        sounds_2D = {
            on_draw = "curse_lifetap"
        },
        retain_descriptions = {
            {
                format = "base_life_sap_retain",
                parameters = { 10 }
            }
        },
        ephemeral = true
    },
    parasite = {
        rarity = EPIC,
        cost = 2,
        texture = true,
        damage = 1,
        damage_interval = 5,
        on_location_changed_server = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                card.time_until_damage = card.damage_interval
            end
        end,
        update_server = function(card, dt)
            if not card:is_in_hand() then
                return
            end
            card.time_until_damage = card.time_until_damage - dt
            if card.time_until_damage <= 0 then
                enigma:force_damage(card.context.unit, 1)
                card.time_until_damage = card.damage_interval
            end
        end,
        retain_descriptions = {
            {
                format = "base_parasite_retain",
                parameters = { 1, 5 }
            }
        },
        ephemeral = true
    },
    silence = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "cannot_use_career_skill", 1)
            elseif old == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "cannot_use_career_skill", -1)
            end
        end,
        sounds_2D = {
            on_draw = "curse_confuse"
        },
        retain_descriptions = {
            {
                format = "base_silence_retain",
            },
        },
        ephemeral = true
    },
    slow = {
        rarity = RARE,
        cost = 1,
        texture = true,
        dodge_decrease = -0.25,
        on_location_changed_local = function(card, old, new)
            if new == "hand" then
                buff:update_stat(card.context.unit, "dodge_range", card.dodge_decrease)
                buff:update_stat(card.context.unit, "dodge_speed", card.dodge_decrease)
            elseif old == "hand" then
                buff:update_stat(card.context.unit, "dodge_range", card.dodge_decrease * -1)
                buff:update_stat(card.context.unit, "dodge_speed", card.dodge_decrease * -1)
            end
        end,
        sounds_2D = {
            on_draw = "curse_decrepify"
        },
        retain_descriptions = {
            {
                format = "description_dodge_range_and_speed",
                parameters = { -25, -25 }
            }
        },
        ephemeral = true
    },
    thorn = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            enigma:force_damage(card.context.unit, 5)
        end,
        description_lines = {
            {
                format = "description_take_damage",
                parameters = { 5 }
            }
        },
        ephemeral = true
    },
    virus = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        infection_duration = 60,
        power_level_reduction = -0.15,
        on_play_local = function(card)
            -- Pick a random peer, set the infected_peer property and then sync it
            local peer_ids = {}
            for peer_id,_ in pairs(game.peer_data) do
                table.insert(peer_ids, peer_id)
            end
            if #peer_ids < 1 then
                return
            end
            local selected_peer_id = peer_ids[enigma:random_range_int(1, #peer_ids)]
            card.infected_peer = selected_peer_id
            card:rpc_peer(selected_peer_id, "become_infected")
        end,
        become_infected = function(card)
            game:shuffle_new_card_into_draw_pile(card.id)
        end,
        apply_power_reduction_change = function(card, change)
            buff:update_stat(card.context.unit, "power_level", change)
        end,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                card.remaining_infection_duration = card.infection_duration
                card:rpc_server("apply_power_reduction_change", card.power_level_reduction)
            elseif old == enigma.CARD_LOCATION.hand then
                card:rpc_server("apply_power_reduction_change", card.power_level_reduction * -1)
            end
        end,
        update_local = function(card, dt)
            if card.location == enigma.CARD_LOCATION.hand then
                card.remaining_infection_duration = card.remaining_infection_duration - dt
                local previous_int_seconds = card.remaining_infection_duration_int
                card.remaining_infection_duration_int = math.ceil(card.remaining_infection_duration)
                if card.remaining_infection_duration <= 0 then
                    local played = card:play()
                    if not played then
                        card.remaining_infection_duration = 1 -- If we couldn't play the card for some reason, try again in 1 second
                    end
                end
                if card.remaining_infection_duration_int ~= previous_int_seconds then
                    card.auto_descriptions[1].parameters[2] = card.remaining_infection_duration_int
                    card:set_dirty()
                end
            end
        end,
        description_lines = {
            {
                format = "base_virus_description",
            }
        },
        retain_descriptions = {
            {
                format = "description_power_level",
                parameters = { -15 }
            }
        },
        auto_descriptions = {
            {
                format = "base_virus_auto",
                parameters = { 60, 60 }
            }
        },
        ephemeral = true,
        unplayable = true
    },
    vulnerability = {
        rarity = RARE,
        cost = 0,
        duration = 60,
        texture = true,
        on_play_server = function(card)
            buff:surge_stat(card.context.unit, "damage_taken", 0.25, card.duration)
        end,
        description_lines = {
            {
                format = "description_damage_taken",
                parameters = { 25 }
            }
        },
        ephemeral = true
    },
}

local set_default_texture_names = function(cards)
    for id,def in pairs(cards) do
        if def.texture == true then
            def.texture = "enigma_base_"..tostring(id)
        elseif def.texture == false then
            def.texture = nil
        end
    end
end
set_default_texture_names(passive_cards)
set_default_texture_names(attack_cards)
set_default_texture_names(ability_cards)
set_default_texture_names(chaos_cards)

pack_handle.register_passive_cards(passive_cards)
pack_handle.register_attack_cards(attack_cards)
pack_handle.register_ability_cards(ability_cards)
pack_handle.register_chaos_cards(chaos_cards)