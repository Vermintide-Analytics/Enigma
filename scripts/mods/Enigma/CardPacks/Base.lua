local enigma = get_mod("Enigma")

local COMMON = enigma.CARD_RARITY.common
local RARE = enigma.CARD_RARITY.rare
local EPIC = enigma.CARD_RARITY.epic
local LEGENDARY = enigma.CARD_RARITY.legendary

local pack_handle = enigma.managers.card_pack:register_card_pack("Enigma", "base", "base")

local game = enigma.managers.game
local buff = enigma.managers.buff
local warp = enigma.managers.warp


--[[ CARD DEFINITION TEMPLATE

    CARD_NAME = {
        rarity = RARITY,
        cost = COST,
        --texture = "enigma_base_"..TEXTURE,
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

pack_handle.register_passive_cards({
    caffeinated = {
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
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_collar_cage",
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
    eshin_counter_intelligence = {
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_eshin_counter_intelligence",
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
    executioner = {
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
    plated_armor = {
        rarity = LEGENDARY,
        cost = 2,
        texture = "enigma_base_plated_armor",
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
    soul_safe = {
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_soul_safe",
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
        texture = "enigma_base_spartan",
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
    the_mill = {
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_the_mill",
        effect_interval = 60,
        time_until_next_effect = 0,
        update_always = function(card, dt)
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
        update_local = function(card, dt)
            card:update_always(dt)
        end,
        out_of_play_update_local = function(card, dt)
            card:update_always(dt)
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
    tough_skin = {
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
        rarity = EPIC,
        cost = 4,
        texture = "enigma_base_veteran",
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
    warp_flesh = {
        rarity = RARE,
        cost = 2,
        texture = "enigma_base_warp_flesh",
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
})

pack_handle.register_attack_cards({
    cyclone_strike = {
        rarity = RARE,
        cost = 0,
        texture = "enigma_base_cyclone_strike",
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
    quick_stab = {
        rarity = COMMON,
        cost = 0,
        texture = "enigma_base_quick_stab",
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
        texture = "enigma_base_slam",
        damage_enemies = function(card)
            local us = card.context.unit
            local nearby_ai_units = enigma:get_ai_units_around_unit(us, 8)
            for _,unit in ipairs(nearby_ai_units) do
                card:hit_enemy(unit, us, nil, DamageProfileTemplates.heavy_slashing_linesman, 5)
            end
        end,
        on_play_local = function(card)
            enigma:apply_no_clip(card.context.unit, "enigma_base_slam")
            enigma:leap_forward(card.context.unit, 0.5, 0.1, 10, {
                finished = function(this, aborted, final_position)
                    card:rpc_server("damage_enemies")
                    enigma:remove_no_clip(card.context.unit, "enigma_base_slam")
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
    }
})

pack_handle.register_ability_cards({
    blood_transfusion = {
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_blood_transfusion",
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
    divine_insurance = {
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
    dubious_insurance = {
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
        texture = "enigma_base_field_medicine",
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
        texture = "enigma_base_gluttonous_jug",
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
    long_rest = {
        rarity = LEGENDARY,
        cost = 3,
        texture = "enigma_base_long_rest",
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
    quick_stimulants = {
        rarity = COMMON,
        cost = 0,
        texture = "enigma_base_quick_stimulants",
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
    ranalds_play = {
        rarity = LEGENDARY,
        cost = 1,
        texture = "enigma_base_ranalds_play",
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
        texture = "enigma_base_rat_banker",
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
        texture = "enigma_base_retreat",
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
    spare_engine = {
        rarity = RARE,
        cost = 1,
        texture = "enigma_base_spare_engine",
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
        texture = "enigma_base_stolen_bell",
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
    ubersreik_hero = {
        rarity = RARE,
        cost = 1,
        texture = "enigma_base_ubersreik_hero",
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
        texture = "enigma_base_vault",
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
        texture = "enigma_base_warpfire_strikes",
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
        texture = "enigma_base_warpstone_pie",
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
    wrath_of_khorne = {
        rarity = EPIC,
        cost = 1,
        duration = 10,
        texture = "enigma_base_wrath_of_khorne",
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
})

pack_handle.register_chaos_cards({
    incompetence = {
        rarity = COMMON,
        cost = 1,
        texture = "enigma_base_incompetence",
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
        texture = "enigma_base_injury",
        on_location_changed_server = function(card, old, new)
            if new == enigma.CARD_LOCATION.hand and old == enigma.CARD_LOCATION.draw_pile then
                card.times_drawn = card.times_drawn + 1
                card.description_lines[1].parameters[2] = card.damage_per_draw * card.times_drawn
                card:set_dirty()
            end
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
        texture = "enigma_base_life_sap",
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
        texture = "enigma_base_parasite",
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
        texture = "enigma_base_silence",
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
        texture = "enigma_base_slow",
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
        texture = "enigma_base_thorn",
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
        texture = "enigma_base_virus",
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
        texture = "enigma_base_vulnerability",
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
})