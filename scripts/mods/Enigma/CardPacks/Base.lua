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
local sound = enigma.managers.sound

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
    battle_scars = {
        rarity = EPIC,
        cost = 6,
        initial_cost = 6,
        texture = true,
        damage_taken_modifier = -0.10,
        damage_taken = 0,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "damage_taken", card.damage_taken_modifier)
        end,
        events_local = {
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                local damaged_unit = self.unit
                local us = card.context.unit

                if not card:is_in_hand() or damaged_unit ~= us or damage_type == "temporary_health_degen" then
                    return
                end

                card.damage_taken = card.damage_taken + damage_amount
                local previous_card_cost = card.cost
                while card.damage_taken >= 100 do
                    card.damage_taken = card.damage_taken - 100
                    card.cost = card.cost - 1
                end
                if previous_card_cost ~= card.cost then
                    card:set_dirty()
                end
            end
        },
        ephemeral = true,
        description_lines = {
            {
                format = "description_damage_taken",
                parameters = { -10 }
            },
        },
        retain_descriptions = {
            {
                format = "base_battle_scars_retain",
                parameters = { 1, 100 }
            }
        }
    },
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
    bone_host = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        primordial = true,
        ephemeral = true,
        summon_count = 1,
        cooldown_interval = 15,
        current_cooldown = 0,
        update_server = function(card, dt)
            if card.current_cooldown > 0 then
                card.current_cooldown = card.current_cooldown - dt
            end
        end,
        events_server = {
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                local damaged_unit = self.unit
                local us = card.context.unit

                if damaged_unit ~= us or damage_type == "temporary_health_degen" then
                    return
                end

                local attacker_side = Managers.state.side.side_by_unit[attacker_unit]
                local player_side = Managers.state.side.side_by_unit[us]
                
                if attacker_side == player_side or card.current_cooldown > 0 then
                    return
                end

                card.current_cooldown = card.cooldown_interval
                for i=1,card:times_played() do
                    for j=1,card.summon_count do
                        enigma:spawn_pet(us, "pet_skeleton", "hireling", Vector3(0, 3, 0))
                    end
                end
            end
        },
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        required_resource_packages = {
            "resource_packages/careers/bw_necromancer"
        },
        description_lines = {
            {
                format = "base_bone_host_description",
                parameters = { 15 }
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
        end,
        sounds_2D = {
            on_play = "sip_swallow"
        },
    },
    collar_cage = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_packmaster", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_collar_cage_description"
            }
        },
    },
    continual_blows = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        on_any_card_played_local = function(card, played_card)
            if played_card.card_type == enigma.CARD_TYPE.attack then
                for i=1,card:times_played() do
                    if enigma:test_chance(0.5) then
                        game:draw_card()
                    end
                end
            end
        end,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_continual_blows_description",
                parameters = { 50 }
            }
        }
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
        },
        sounds_2D = {
            on_play = "deep_breath"
        },
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
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
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
            on_play = "legendary_buff_2"
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
            if card:times_played() > 0 then
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
                if card:times_played() > 0 then
                    local attacker = attacker_unit or source_attacker_unit
                    local breed = attacker and Unit.get_data(attacker, "breed")
                    if not breed or not breed.is_player or attacker == card.context.unit then
                        return
                    end
                    card.calculated_power_boost = card.calculated_power_boost + card.power_boost_per_damage_dealt * damage_amount
                end
            end,
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if card:times_played() > 0 then
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
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_khornes_pact_description",
            }
        }
    },
    leaden_boots = {
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
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_leaden_boots_description"
            }
        },
    },
    nurgles_brew = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        trigger_gas_cloud = function(card, multiplier)
            multiplier = multiplier or 1
            local us = card.context.unit
            local duration = 5 * multiplier
            local init_radius = 58 * multiplier
            local init_damage = 15 * multiplier
            local radius = 8 * multiplier
            local damage = 10 * multiplier
            local damage_interval = 0.5 * multiplier

            local damage_players = false
            enigma:create_gas_cloud(us, enigma:unit_position(us), duration, init_radius, init_damage, radius, damage, damage_interval, damage_players)
        end,
        events_local = {
            player_healed = function(card, health_extension, healer_unit, heal_amount, heal_source_name, heal_type)
                if card:times_played() < 1 then
                    return
                end

                local healed_unit = health_extension.unit
                local us = card.context.unit

                if healed_unit ~= us or (heal_type ~= "healing_draught" and heal_type ~= "healing_draught_temp_health") then
                    return
                end
                card:rpc_server("trigger_gas_cloud", card:times_played())
            end,
            player_drank_potion = function(card, player_unit, item_name)
                if card:times_played() < 1 then
                    return
                end

                local us = card.context.unit

                if player_unit ~= us then
                    return
                end
                card:rpc_server("trigger_gas_cloud", card:times_played())
            end,
        },
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_nurgles_brew_description"
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
            on_play = "legendary_buff_2"
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
    raw_power = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        attack_card_power_modifier = 1,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "attack_card_power_multiplier", card.attack_card_power_modifier)
        end,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "description_attack_card_power",
                parameters = { 100 }
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
    slaaneshs_ring = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        required_damage_taken = 300,
        events_server = {
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                local damaged_unit = self.unit
                local us = card.context.unit

                if damaged_unit ~= us or damage_type == "temporary_health_degen" then
                    return
                end
                if card:times_played() == 0 then
                    return
                end

                -- Heal nearby allies based on damage taken
                local max_heal = damage_amount * 0.25
                local max_heal_distance = 1
                local min_heal_distance = 14
                local range = min_heal_distance - max_heal_distance
                local players_and_bots = enigma:player_and_bot_units()
                for _,unit in ipairs(players_and_bots) do
                    if unit ~= us then -- Skip ourselves
                        local distance = math.clamp(enigma:distance_between_units(unit, us), max_heal_distance, min_heal_distance)
                        local distance_lerp_value = (distance - max_heal_distance) / range
                        local calculated_heal = math.lerp(max_heal, 0, distance_lerp_value)
                        enigma:heal(unit, calculated_heal, us)
                    end
                end
            end
        },
        events_local = {
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                local damaged_unit = self.unit
                local us = card.context.unit

                if damaged_unit ~= us or damage_type == "temporary_health_degen" then
                    return
                end
                if card:times_played() > 0 or not card:is_in_hand() then
                    return
                end

                card.required_damage_taken = card.required_damage_taken - damage_amount
                card.condition_descriptions[1].parameters[2] = card.required_damage_taken
                card:set_dirty()
            end
        },
        condition_local = function(card)
            return card.required_damage_taken <= 0
        end,
        ephemeral = true,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_slaaneshs_ring_description",
            }
        },
        condition_descriptions = {
            {
                format = "base_slaaneshs_ring_condition",
                parameters = { 300, 300 }
            }
        },
    },
    soul_safe = {
        rarity = LEGENDARY,
        cost = 3,
        texture = true,
        on_play_server = function(card)
            buff:update_stat(card.context.unit, "chance_ignore_leech", 1.0)
        end,
        sounds_2D = {
            on_play = "legendary_buff_2"
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
            on_play = "legendary_buff_2"
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
            if card:times_played() > 0 then
                card.time_until_next_effect = card.time_until_next_effect - dt
                if card.time_until_next_effect <= 0 then
                    card.time_until_next_effect = card.time_until_next_effect + card.effect_interval
                    for i=1,card:times_played() do
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
            if card:times_played() < 1 then
                card.time_until_next_effect = card.effect_interval
            end
        end,
        ephemeral = true,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
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
            on_play = "legendary_buff_2"
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
    tzeentchs_sigil = {
        rarity = LEGENDARY,
        cost = 2,
        texture = true,
        events_server = {
            player_damaged = function(card, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                local damaged_unit = self.unit
                local us = card.context.unit

                if card:times_played() == 0 or damaged_unit ~= us or damage_type == "temporary_health_degen" then
                    return
                end
                local attacker = attacker_unit or source_attacker_unit
                if not attacker or attacker_unit == us or source_attacker_unit == us then
                    return
                end

                -- Ignore specials
                local attacker_breed = Unit.get_data(attacker, "breed")
                if not attacker_breed or attacker_breed.special then
                    return
                end

                -- Damage the attacker for twice what we received, with a chance to execute
                local damage_to_deal = damage_amount * 2
                if damage_to_deal == 0 then
                    return
                end
                local enemy_health_ext = ScriptUnit.extension(attacker_unit, "health_system")
                if not enemy_health_ext then
                    return
                end
                local enemy_health = enemy_health_ext:current_health()
                local ratio = math.clamp(damage_to_deal / enemy_health, 0, 1)
                local max_chance = 0.1
                local chance = max_chance * ratio
                if enigma:test_chance(chance) then
                    enigma:execute_unit(attacker_unit, us)
                else
                    enigma:force_damage(attacker_unit, damage_to_deal, us)
                end
            end
        },
        ephemeral = true,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_tzeentchs_sigil_description",
                parameters = { 10 }
            }
        }
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
            if card:times_played() > 0 then
                card.next_heal_time = card.next_heal_time - dt
                if card.next_heal_time <= 0 then
                    card.next_heal_time = card.next_heal_time + card.heal_interval
                    enigma:heal(card.context.unit, 5*card:times_played())
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
        crit_power_modifier = 0.12,
        on_play_local = function(card)
            buff:update_stat(card.context.unit, "critical_strike_effectiveness", card.crit_power_modifier)
        end,
        description_lines = {
            {
                format = "description_critical_strike_power",
                parameters = { 12 }
            }
        }
    },
}

local attack_cards = {
    aftershock = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        min_quakes = 2,
        max_quakes = 4,
        damage_amount = 3, -- 4 quakes will kill a gor, but not a stormvermin
        quake_effects = function(card)
            local us = card.context.unit
            sound:trigger_at_unit("rumble", us)
            enigma:camera_shake("ring_explosion", enigma:unit_position(us), 1.5, 4.5, 0.3, 0)
        end,
        do_quake = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 4)
            for _,unit in ipairs(nearby_ai_units) do
                card:damage(unit, card.damage_amount, us)
                enigma:stun_enemy(unit, us, 0.1)
            end
            card:quake_effects()
            card:rpc_others("quake_effects")
        end,
        on_play_server = function(card)
            local num_quakes = enigma:random_range_int(card.min_quakes, card.max_quakes)
            for delay=1,num_quakes do
                enigma:invoke_delayed(function()
                    card:do_quake()
                end, delay)
            end
        end,
        description_lines = {
            {
                format = "base_aftershock_description",
                parameters = { 2, 4 }
            }
        },
        hide_in_deck_editor = true,
        allow_in_deck = false
    },
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
                card:hit_enemy(enemy, us, nil, DamageProfileTemplates.medium_pointy_smiter_flat_1h, 2.25)
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
        },
        sounds_2D = {
            on_play = "parry_slice"
        },
    },
    cyclone_strike = {
        rarity = RARE,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 6)
            for _,unit in ipairs(nearby_ai_units) do
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_slashing_linesman, 3)
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
    earthquake = {
        rarity = EPIC,
        cost = 2,
        texture = true,
        min_quakes = 4,
        max_quakes = 7,
        damage_amount = 5, -- 6 quakes will kill raiders, but not chaos warriors
        quake_effects = function(card)
            local us = card.context.unit
            sound:trigger_at_unit("rumble", us)
            enigma:camera_shake("ring_explosion", enigma:unit_position(us), 3, 8, 0.6, 0)
        end,
        do_quake = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 7)
            for _,unit in ipairs(nearby_ai_units) do
                card:damage(unit, card.damage_amount, us)
                enigma:stun_enemy(unit, us, 0.1)
            end
            card:quake_effects()
            card:rpc_others("quake_effects")
        end,
        on_play_server = function(card)
            local num_quakes = enigma:random_range_int(card.min_quakes, card.max_quakes)
            for delay=1,num_quakes do
                enigma:invoke_delayed(function()
                    card:do_quake()
                end, delay)
            end
        end,
        on_play_local = function(card)
            for i=1,2 do
                game:add_new_card_to_hand("base/aftershock")
            end
        end,
        description_lines = {
            {
                format = "base_earthquake_description",
                parameters = { 4, 7, 2 }
            }
        },
        related_cards = {
            "base/aftershock"
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
        },
        sounds_2D = {
            on_play = "big_slice"
        },
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
    sucker_punch = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        damage_amount = 6, -- Enough to kill an ungor or slave rat, nothing else
        on_play_server = function(card)
            local us = card.context.unit
            local ai_units_to_stab = enigma:get_ai_units_in_front_of_unit(us, 2.5, 60)
            for _,unit in ipairs(ai_units_to_stab) do
                card:damage(unit, card.damage_amount, us)
                enigma:stun_enemy(unit, us, 3)
            end
        end,
        sounds_2D = {
            on_play = "punch"
        },
        description_lines = {
            {
                format = "base_sucker_punch_description",
                parameters = { 3 }
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
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_blunt_tank, 5)
            end
        end,
        on_draw_local = function(card)
            local cost = enigma:random_range_int(0, 2)
            game:set_card_cost(card, cost)
        end,
        sounds_2D = {
            on_play = "whoosh_thud_thud"
        },
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
    apple = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        heal_amount = 10,
        add_apple_seed_chance = 0.05,
        on_play_server = function(card)
            local us = card.context.unit
            enigma:heal(us, card.heal_amount, us)
        end,
        on_play_local = function(card)
            if enigma:test_chance(card.add_apple_seed_chance) then
                game:add_new_card_to_hand("base/apple_seed")
            end
        end,
        description_lines = {
            {
                format = "description_restore_health",
                parameters = { 10 }
            },
            {
                format = "base_apple_description",
                parameters = { 5 }
            },
        },
        ephemeral = true,
        related_cards = {
            "base/apple_seed"
        },
        sounds_2D = {
            on_play = "apple_crunch"
        },
        hide_in_deck_editor = true,
        allow_in_deck = false,
    },
    apple_seed = {
        rarity = EPIC,
        cost = 0,
        texture = true,
        growth_duration = 60,
        on_play_local = function(card)
            game:add_new_card_to_hand("base/apple_tree")
        end,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                card.remaining_growth_duration = card.growth_duration
            end
        end,
        update_local = function(card, dt)
            if card:is_in_hand() then
                card.remaining_growth_duration = card.remaining_growth_duration - dt
                local previous_int_seconds = card.remaining_growth_duration_int
                card.remaining_growth_duration_int = math.ceil(card.remaining_growth_duration)
                if card.remaining_growth_duration <= 0 then
                    local played = card:play()
                    if not played then
                        card.remaining_growth_duration = 1 -- If we couldn't play the card for some reason, try again in 1 second
                    end
                end
                if card.remaining_growth_duration_int ~= previous_int_seconds then
                    card.auto_descriptions[1].parameters[2] = card.remaining_growth_duration_int
                    card:set_dirty()
                end
            end
        end,
        unplayable = true,
        ephemeral = true,
        description_lines = {
            {
                format = "base_apple_seed_description",
            }
        },
        auto_descriptions = {
            {
                format = "base_apple_seed_auto",
                parameters = { 60, 60 }
            }
        },
        sounds_2D = {
            on_play = "tree_grow"
        },
        related_cards = {
            "base/apple_tree"
        }
    },
    apple_tree = {
        rarity = EPIC,
        cost = 2,
        texture = true,
        apple_interval = 60,
        apples_when_played = 4,
        on_play_local = function(card)
            for i=1,5 do
                game:add_new_card_to_hand("base/apple")
            end
        end,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                card.time_until_next_apple = card.apple_interval
            end
        end,
        update_local = function(card, dt)
            if card:is_in_hand() then
                card.time_until_next_apple = card.time_until_next_apple - dt
                local previous_int_seconds = card.time_until_next_apple_int
                card.time_until_next_apple_int = math.ceil(card.time_until_next_apple)
                if card.time_until_next_apple <= 0 then
                    game:add_new_card_to_hand("base/apple")
                    card.time_until_next_apple = card.time_until_next_apple + card.apple_interval
                end
                if card.time_until_next_apple_int ~= previous_int_seconds then
                    card.retain_descriptions[1].parameters[2] = card.time_until_next_apple_int
                    card:set_dirty()
                end
            end
        end,
        description_lines = {
            {
                format = "base_apple_tree_description",
                parameters = { 4 }
            }
        },
        retain_descriptions = {
            {
                format = "base_apple_tree_retain",
                parameters = { 60, 60 }
            }
        },
        sounds_2D = {
            on_play = "tree_chop"
        },
        related_cards = {
            "base/apple"
        },
        hide_in_deck_editor = true,
        allow_in_deck = false,
    },
    battlecry = {
        rarity = COMMON,
        cost = 1,
        texture = true,
        duration = 20,
        on_play_server = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 6)
            for _,unit in ipairs(nearby_ai_units) do
                AiUtils.taunt_unit(unit, us, 20, false)
            end
        end,
        description_lines = {
            {
                format = "base_battlecry_description"
            }
        }
    },
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
        },
        sounds_2D = {
            on_play = "wisp_sigh"
        },
    },
    delayed_bomb = {
        rarity = RARE,
        cost = 2,
        texture = true,
        on_play_server = function(card)
            sound:trigger("clock_ticking_fade_out")
            enigma:invoke_delayed(function()
                sound:trigger("clock_ticking_fade_in")
            end, 60 - 4.96)
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
    devour_pet = {
        rarity = COMMON,
        cost = 0,
        texture = true,
        charges = 2,
        on_play_server = function(card)
            local us = card.context.unit
            local controlled_units, num_controlled_units = enigma:get_controlled_unit_data(us)
            if num_controlled_units > 0 then
                local unit_list = {}
                for unit,_ in pairs(controlled_units) do
                    table.insert(unit_list, unit)
                end
                local random_index = enigma:random_range_int(1, num_controlled_units)
                enigma:execute_unit(unit_list[random_index], us)
            end
            enigma:heal(us, 50)
        end,
        condition_local = function(card)
            local _, num_controlled_units = enigma:get_controlled_unit_data(card.context.unit)
            if num_controlled_units and num_controlled_units > 0 then
                return true
            end
            return false
        end,
        description_lines = {
            {
                format = "base_devour_pet_description",
                parameters = { 50 }
            }
        },
        condition_descriptions = {
            {
                format = "base_devour_pet_condition"
            }
        },
        sounds_2D = {
            on_play = "crunch"
        },
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
        },
        sounds_2D = {
            on_play = "flame_extinguish"
        },
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
    fanaticism = {
        rarity = RARE,
        cost = X,
        texture = true,
        duration = 200,
        base_temporary_healing_received_modifier = 0.3,
        on_play_server = function(card, play_type, net_x_cost)
            local us = card.context.unit
            local health_ext = ScriptUnit.extension(us, "health_system")
            if not health_ext then
                return
            end

            local current_health = health_ext:current_health()
            local desired_health = math.max(current_health / math.pow(2, net_x_cost), 1)
            local damage_to_deal = current_health - desired_health
            enigma:force_damage(us, damage_to_deal)

            local healing_buff = card.base_temporary_healing_received_modifier * net_x_cost
            buff:surge_stat(us, "temporary_healing_received", healing_buff, card.duration)
        end,
        description_lines = {
            {
                format = "base_fanaticism_description",
                parameters = { X, 30, X },
                x_cost_parameters = { 0, false, 0 }
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
    grave_legion = {
        rarity = RARE,
        cost = 2,
        texture = true,
        summon_count = 8,
        on_play_server = function(card)
            local angle = math.pi * 2 / card.summon_count
            local offset = Vector3(0, 2, 0)
            local rotation = Quaternion.axis_angle(Vector3(0, 0, 1), angle)
            for i=1,card.summon_count do
                enigma:spawn_pet(card.context.unit, "pet_skeleton", "hireling", offset)
                offset = Quaternion.rotate(rotation, offset)
            end
        end,
        required_resource_packages = {
            "resource_packages/careers/bw_necromancer"
        },
        description_lines = {
            {
                format = "base_grave_legion_description",
                parameters = { 8 }
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
        play_slowdown_sound = function(card)
            sound:trigger("time_slowdown")
        end,
        play_speedup_sound = function(card)
            sound:trigger("time_speedup")
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
            card:play_slowdown_sound()
            card:rpc_others("play_slowdown_sound")
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
            multiply_stat("card_draw_per_second_multiplier", 0, effect)
            multiply_stat("warp_dust_per_second_multiplier", 0, effect)

            enigma:invoke_delayed(function()
                card:play_speedup_sound()
                card:rpc_others("play_speedup_sound")
            end, calculated_duration - 3.46*effect_inv)
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
                multiply_stat("card_draw_per_second_multiplier", 0, effect_inv)
                multiply_stat("warp_dust_per_second_multiplier", 0, effect_inv)

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
        },
        related_cards = {
            "base/dormant_crystal"
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
            -- DEBUG
            local cached_condition_met = card.condition_server_met

            if not card.living_monsters then
                if cached_condition_met then -- DEBUG
                    enigma:info("Honorable Duel condition: previously "..tostring(cached_condition_met)..", now false because not card.living monsters")
                end
                return false
            end
            for unit,state in pairs(card.living_monsters) do
                if state == "alive" then
                    if not Unit.alive(unit) then
                        card.living_monsters[unit] = nil
                    else
                        if not cached_condition_met then -- DEBUG
                            enigma:info("Honorable Duel condition: previously "..tostring(cached_condition_met)..", now true because found an \"alive\" monster")
                        end
                        return true
                    end
                end
            end
            if cached_condition_met then -- DEBUG
                enigma:info("Honorable Duel condition: previously "..tostring(cached_condition_met)..", now false because no \"alive\" monster found")
            end
            return false
        end,
        events_server = {
            enemy_spawned = function(card, spawned_unit, breed, ...)
                if enigma:breed_is_monster(breed) then
                    enigma:info("Honorable Duel tracking spawned monster: "..tostring(spawned_unit))
                    card.living_monsters[spawned_unit] = "alive"
                end
            end,
            enemy_killed = function(card, killed_unit, killing_blow)
                local breed = Unit.get_data(killed_unit, "breed")
                if not enigma:breed_is_monster(breed) then
                    return
                end
                
                enigma:info("Honorable Duel no longer tracking dead monster: "..tostring(killed_unit))
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
                    enigma:info("Honorable Duel resetting monster state: "..tostring(card.dueling_monster))
                    card.living_monsters[card.dueling_monster] = nil
                    card:end_duel()
                end
            end,
        },
        sounds_2D = {
            on_play = "boxing_bell"
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
    living_catalysts = {
        rarity = RARE,
        cost = 1,
        texture = true,
        duration = 300,
        power_level_modifier = 0.02,
        on_play_server = function(card)
            local us = card.context.unit
            local controlled_units, num_controlled_units = enigma:get_controlled_unit_data(us)
            for unit,_ in pairs(controlled_units) do
                enigma:execute_unit(unit, us)
            end
            local power_increase = card.power_level_modifier * num_controlled_units
            if power_increase > 0 then
                buff:surge_stat(card.context.unit, "power_level", power_increase, card.duration)
            end
        end,
        condition_local = function(card)
            local _, num_controlled_units = enigma:get_controlled_unit_data(card.context.unit)
            if num_controlled_units and num_controlled_units > 0 then
                return enigma:on_ground(card.context.unit)
            end
            return false
        end,
        description_lines = {
            {
                format = "base_living_catalysts_description",
                parameters = { 2 }
            }
        }
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
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_long_rest_description",
                parameters = { 5 }
            }
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
    ranalds_touch = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        cards_to_add_by_rarity = {
            [enigma.CARD_RARITY.rare] = 1,
            [enigma.CARD_RARITY.epic] = 1,
            [enigma.CARD_RARITY.legendary] = 1,
        },
        added_cards = {},
        on_play_local = function(card)
            for rarity,num_to_add in pairs(card.cards_to_add_by_rarity) do
                for i=1,num_to_add do
                    local random_card_predicate = function(template)
                        return template.rarity == rarity
                    end
                    local random_card_template = enigma:get_random_card_definition(random_card_predicate)
                    local new_card = game:shuffle_new_card_into_draw_pile(random_card_template.id)
                    game:add_card_cost(new_card, -1)
                    table.insert(new_card.description_lines, {
                        format = "description_draw_a_card"
                    })
                    new_card:set_dirty()
                    card.added_cards[new_card] = true
                end
            end
        end,
        on_any_card_played_local = function(card, played_card)
            if card.added_cards[played_card] then
                game:draw_card()
            end
        end,
        primordial = true,
        ephemeral = true,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_ranalds_touch_description",
                parameters = { 1, 1, 1, 1 }
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
    refined_techniques = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        on_play_local = function(card)
            local cards = card.context:get_cards_in_hand(function(c) return c.card_type == enigma.CARD_TYPE.attack end)
            for _,attack_card in ipairs(cards) do
                attack_card.echo = true
                game:add_card_cost(attack_card, -2)
            end
        end,
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
        description_lines = {
            {
                format = "base_refined_techniques_description",
                parameters = { -2 }
            }
        }
    },
    renewal = {
        rarity = RARE,
        cost = 1,
        texture = true,
        health_percent_threshold = 0.1,
        on_play_server = function(card)
            local us = card.context.unit
            local health_extension = ScriptUnit.extension(us, "health_system")
            if not health_extension then
                return
            end
            local max = health_extension:get_max_health()
            local current_permanent = health_extension:current_permanent_health()
            local heal_amount = max - current_permanent
            enigma:heal(us, heal_amount)
        end,
        condition_local = function(card)
            local us = card.context.unit
            local health_ext = ScriptUnit.extension(us, "health_system")
            return health_ext and health_ext:current_permanent_health_percent() <= card.health_percent_threshold
        end,
        description_lines = {
            {
                format = "base_renewal_description"
            }
        },
        condition_descriptions = {
            {
                format = "base_renewal_condition",
                parameters = { 10 }
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
        sounds_2D = {
            on_play = "legendary_buff_2"
        },
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
        sounds_2D = {
            on_draw = "engine_start"
        },
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
    stupefy = {
        rarity = EPIC,
        cost = 0,
        texture = true,
        on_play_server = function(card)
            local us = card.context.unit
            local nearby = enigma:get_ai_units_around_unit(us, 6)
            for _,unit in ipairs(nearby) do
                enigma:stun_enemy(unit, us, 7)
            end
        end,
        on_play_local = function(card)
            game:draw_card()
        end,
        echo = true,
        description_lines = {
            {
                format = "base_stupefy_description",
                parameters = { 7 }
            },
            {
                format = "description_draw_a_card"
            }
        }
    },
    the_red_raven = {
        rarity = LEGENDARY,
        cost = 0,
        texture = true,
        duplicate_card_chance = 0.50,
        card_draw_multiplier_modifier = -0.50,
        on_any_card_played_local = function(card, played_card)
            if card:is_in_hand() and enigma:test_chance(card.duplicate_card_chance) then
                local id = played_card.id
                local new_card = game:shuffle_new_card_into_draw_pile(id)
                if not new_card then
                    enigma:warning("Could not shuffle copy of "..tostring(id).." into draw pile")
                    return
                end
                played_card:copy_to(new_card)
                new_card.ephemeral = true
                enigma:info("The Red Raven shuffled new copy of "..tostring(id).." into draw pile")
                sound:trigger("raven_caw")
            end
        end,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_multiplier_modifier)
            elseif old == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "card_draw_multiplier", card.card_draw_multiplier_modifier * -1)
            end
        end,
        ephemeral = true,
        sounds_2D = {
            on_draw = "raven_caw"
        },
        retain_descriptions = {
            {
                format = "base_the_red_raven_retain",
                parameters = { 50 }
            },
            {
                format = "description_card_draw",
                parameters = { -50 }
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
        sounds_2D = {
            on_play = "harmonious_bell"
        },
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
            enigma:leap_forward(card.context.unit, 7, 7, 8, {
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
        sounds_2D = {
            on_play = "deep_whoosh"
        },
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
        events_server = {
            enemy_damaged = function(card, health_ext, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
                if #card.active_durations < 1 then
                    return
                end
                local is_melee_hit = attack_type == "light_attack" or attack_type == "heavy_attack"
                if is_melee_hit and health_ext and health_ext.unit and attacker_unit == card.context.unit then
                    enigma:add_dot(health_ext.unit, attacker_unit, "burning_dot", 10)
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
        sounds_2D = {
            on_play = "deep_breath_distorted"
        },
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
    warp_inoculation = {
        rarity = COMMON,
        cost = X,
        texture = true,
        duration = 20,
        increased_invincible_duration_per_warpstone = 0.2,
        apply_invincible = function(card, duration)
            local us = card.context.unit
            enigma:apply_perk(us, "invincible")
            enigma:invoke_delayed(function()
                enigma:remove_perk(us, "invincible")
            end, duration)
        end,
        apply_drunk = function(card, duration)
            local us = card.context.unit
            local status = ScriptUnit.extension(us, "status_system")
            if not us or not status then
                return
            end
            enigma:apply_perk(us, "drunk_stagger")
            status:add_intoxication_level(3)
            enigma:invoke_delayed(function()
                enigma:remove_perk(us, "drunk_stagger")
                status:add_intoxication_level(-3)
            end, duration)
        end,
        on_play_local = function(card, play_type, net_x_cost)
            local drunk_duration = card.duration
            local invincible_duration_multiplier = 1 + (net_x_cost * card.increased_invincible_duration_per_warpstone)
            local invincible_duration = drunk_duration * invincible_duration_multiplier
            card:apply_drunk(drunk_duration)
            card:rpc_server("apply_invincible", invincible_duration)
        end,
        description_lines = {
            {
                format = "base_warp_inoculation_description",
                parameters = { 20, X },
                x_cost_parameters = { false, 0}
            }
        }
    },
    willing_sacrifice = {
        rarity = RARE,
        cost = 0,
        texture = true,
        echo = true,
        on_play_server = function(card)
            local us = card.context.unit
            local our_status = ScriptUnit.extension(us, "status_system")
            if our_status:is_disabled() then
                enigma:warning("Willing Sacrifice could not play because the player was disabled at the time")
                return
            end

            local players_and_bots = enigma:player_and_bot_units()
            local ally_unit = nil
            local ally_status
            for _,unit in ipairs(players_and_bots) do
                if unit ~= us then -- Skip ourselves
                    local status = ScriptUnit.extension(unit, "status_system")
                    if status:is_knocked_down() or status:get_is_ledge_hanging() then
                        ally_unit = unit
                        ally_status = status
                    end
                end
            end
            if not ally_unit then
                enigma:warning("Willing Sacrifice could not find a disabled ally to free")
                return
            end
            if ally_status:is_knocked_down() then
                StatusUtils.set_revived_network(ally_unit, true, us)
            elseif ally_status:get_is_ledge_hanging() then
                StatusUtils.set_pulled_up_network(ally_unit, true, us)
            end
            our_status:set_knocked_down(true)
        end,
        condition_local = function(card)
            local us = card.context.unit
            local our_status = ScriptUnit.extension(us, "status_system")
            if not our_status or our_status:is_disabled() then
                return false
            end
            -- At least one ally is disabled
            local players_and_bots = enigma:player_and_bot_units()
            for _,unit in ipairs(players_and_bots) do
                if unit ~= us then -- Skip ourselves
                    local status = ScriptUnit.extension(unit, "status_system")
                    if status:is_knocked_down() or status:get_is_ledge_hanging() then
                        return true
                    end
                end
            end
            return false
        end,
        sounds_2D = {
            on_play = "harmonious_bell"
        },
        description_lines = {
            {
                format = "base_willing_sacrifice_description"
            },
        },
        condition_descriptions = {
            {
                format = "base_willing_sacrifice_condition"
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
    frailty = {
        rarity = RARE,
        cost = 1,
        texture = true,
        block_cost_modifier = 1,
        on_location_changed_local = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "block_cost", card.block_cost_modifier)
            end
            if old == enigma.CARD_LOCATION.hand then
                buff:update_stat(card.context.unit, "block_cost", card.block_cost_modifier * -1)
            end
        end,
        sounds_2D = {
            on_draw = "glass_break"
        },
        retain_descriptions = {
            {
                format = "description_block_cost",
                parameters = { 100 }
            }
        }
    },
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
        sounds_2D = {
            on_play = "cabbage_rip"
        },
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
        sounds_2D = {
            on_draw = "curse_terror"
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
        sounds_2D = {
            on_play = "glass_break"
        },
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