local enigma = get_mod("Enigma")

enigma.EVENTS = {

    enemy_damaged = "enemy_damaged", -- health_extension, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier
    enemy_healed = "enemy_healed", -- health_extension, healer_unit, heal_amount, heal_source_name, heal_type
    enemy_killed = "enemy_killed", -- killed_unit, killing_blow
    enemy_spawned = "enemy_spawned", -- spawned_unit, breed, spawn_pos, spawn_category, spawn_type, optional_data
    enemy_staggered = "enemy_staggered",

    player_block = "player_block", -- blocking_unit, attacker_unit, fatigue_type
    player_block_broken = "player_block_broken", -- blocking_unit, attacker_unit, fatigue_type
    player_damaged = "player_damaged", -- health_extension, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier
    player_disabled = "player_disabled", -- disabled_unit, disable_type, disabler
    player_dodge = "player_dodge", -- dodging_player_unit, dodge_direction
    player_dodge_finished = "player_dodge_finished", -- dodging_player_unit
    player_freed = "player_freed",
    player_healed = "player_healed", -- health_extension, healer_unit, heal_amount, heal_source_name, heal_type
    player_hooked = "player_hooked", -- disabled_unit, disabler
    player_invisible = "player_invisible", -- player_unit
    player_jump = "player_jump", -- jumping_player_unit
    player_killed = "player_killed", -- killed_unit, killing_blow
    player_knocked_down = "player_knocked_down", -- unit
    player_leeched = "player_leeched", -- disabled_unit, disabler
    player_picked_up_from_respawn = "player_picked_up_from_respawn", -- player_unit, helper_unit
    player_pounced = "player_pounced", -- disabled_unit, disabler
    player_reload = "player_reload", -- reloading_unit
    player_respawn = "player_respawn", -- respawned_player_unit
    player_timed_block = "player_timed_block", -- blocking_unit, attacker_unit
    player_revived = "player_revived", -- revived_unit, reviver_unit
    player_visible = "player_visible", -- player_unit
    player_waiting_for_rescue = "player_waiting_for_rescue", -- player_unit

}

local em = {
    events = {}
}
for _,evt in pairs(enigma.EVENTS) do
    em.events[evt] = {}
end
enigma.managers.event = em


local reg_hook_safe = function(obj, func_name, func, hook_id)
    enigma.managers.hook:hook_safe("Enigma", obj, func_name, func, hook_id)
end

em._add_event_callback = function(self, event, card, callback)
    local callbacks = event and self.events[event]
    if not callbacks then
        enigma:warning("Could not add callback for event ("..tostring(event)..")")
        return
    end
    if not card then
        enigma:warning("Cannot add event callback without specifying a card")
        return
    end
    if not callback then
        enigma:warning("Cannot add event callback without a callback")
        return
    end
    callbacks[card] = callback
    enigma:debug("Added callback to "..event.." for "..card.name)
end

em._remove_event_callback = function(self, event, card)
    local callbacks = event and self.events[event]
    if not callbacks then
        enigma:warning("Could not add callback for event ("..tostring(event)..")")
        return
    end
    if not card then
        enigma:warning("Cannot add event callback without specifying a card")
        return
    end
    callbacks[card] = nil
end

em.add_card_event_callbacks = function(self, card)
    if not card.events then
        return
    end
    for evt,cb in pairs(card.events) do
        if self.events[evt] then
            self.events[evt][card] = cb
        else
            enigma:warning("Unrecognized game event: "..tostring(evt))
        end
    end
end
em._add_card_local_event_callbacks = function(self, card)
    if not card.events_local then
        return
    end
    for evt,cb in pairs(card.events_local) do
        if self.events[evt] then
            self.events[evt][card] = cb
        else
            enigma:warning("Unrecognized game event: "..tostring(evt))
        end
    end
end
em._add_card_server_event_callbacks = function(self, card)
    if not card.events_server then
        return
    end
    for evt,cb in pairs(card.events_server) do
        if self.events[evt] then
            self.events[evt][card] = cb
        else
            enigma:warning("Unrecognized game event: "..tostring(evt))
        end
    end
end
em._add_card_remote_event_callbacks = function(self, card)
    if not card.events_remote then
        return
    end
    for evt,cb in pairs(card.events_remote) do
        if self.events[evt] then
            self.events[evt][card] = cb
        else
            enigma:warning("Unrecognized game event: "..tostring(evt))
        end
    end
end

em.remove_card_event_callbacks = function(self, card)
    for _,event_callbacks in pairs(self.events) do
        event_callbacks[card] = nil
    end
end

em.remove_all_card_event_callbacks = function(self)
    for evt,_ in pairs(self.events) do
        self.events[evt] = {}
    end
end

em._invoke_event_callbacks = function(self, event, ...)
    if not event or not self.events[event] then
        enigma:warning("Cannot invoke callbacks for nonexistent event ("..tostring(event)..")")
        return
    end
    
    for card,cb in pairs(self.events[event]) do
        if not cb then
            return
        end
        cb(card, ...)
    end
end

reg_hook_safe(ConflictDirector, "_post_spawn_unit", function(self, ai_unit, go_id, breed, spawn_pos, spawn_category, spawn_animation, optional_data, spawn_type)
    em:_invoke_event_callbacks(enigma.EVENTS.enemy_spawned, ai_unit, breed, spawn_pos, spawn_category, spawn_type, optional_data)
end, "enigma_event_enemy_spawned")

reg_hook_safe(GenericHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    em:_invoke_event_callbacks(enigma.EVENTS.enemy_damaged, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end, "enigma_event_enemy_damaged")

reg_hook_safe(PlayerUnitHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    em:_invoke_event_callbacks(enigma.EVENTS.player_damaged, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end, "enigma_event_player_damaged")

reg_hook_safe(GenericHealthExtension, "add_heal", function(self, healer_unit, heal_amount, heal_source_name, heal_type)
    em:_invoke_event_callbacks(enigma.EVENTS.enemy_healed, self, healer_unit, heal_amount, heal_source_name, heal_type)
end, "enigma_event_enemy_healed")

reg_hook_safe(PlayerUnitHealthExtension, "add_heal", function(self, healer_unit, heal_amount, heal_source_name, heal_type)
    em:_invoke_event_callbacks(enigma.EVENTS.player_healed, self, healer_unit, heal_amount, heal_source_name, heal_type)
end, "enigma_event_player_healed")

reg_hook_safe(BuffExtension, "trigger_procs", function(self, event, ...)
    if event == "on_player_disabled" then
        local arg = table.pack(...)
        if arg[1] == "assassin_pounced" then
            em:_invoke_event_callbacks(enigma.EVENTS.player_pounced, self._unit, arg[2])
        elseif arg[1] == "pack_master_grab" then
            em:_invoke_event_callbacks(enigma.EVENTS.player_hooked, self._unit, arg[2])
        elseif arg[1] == "corruptor_grab" then
            em:_invoke_event_callbacks(enigma.EVENTS.player_leeched, self._unit, arg[2])
        end
        em:_invoke_event_callbacks(enigma.EVENTS.player_disabled, self._unit, arg[1], arg[2])
    elseif event == "on_block" then
        local arg = table.pack(...)
        em:_invoke_event_callbacks(enigma.EVENTS.player_block, self._unit, arg[1], arg[2])
    elseif event == "on_block_broken" then
        local arg = table.pack(...)
        em:_invoke_event_callbacks(enigma.EVENTS.player_block_broken, self._unit, arg[1], arg[2])
    elseif event == "on_dodge" then
        local arg = table.pack(...)
        em:_invoke_event_callbacks(enigma.EVENTS.player_dodge, self._unit, arg[1])
    elseif event == "on_dodge_finished" then
        em:_invoke_event_callbacks(enigma.EVENTS.player_dodge_finished, self._unit)
    elseif event == "on_knocked_down" then
        em:_invoke_event_callbacks(enigma.EVENTS.player_knocked_down, self._unit)
    elseif event == "on_invisible" then
        em:_invoke_event_callbacks(enigma.EVENTS.player_invisible, self._unit)
    elseif event == "on_reload" then
        em:_invoke_event_callbacks(enigma.EVENTS.player_reload, self._unit)
    elseif event == "on_revived" then
        local arg = table.pack(...)
        em:_invoke_event_callbacks(enigma.EVENTS.player_revived, self._unit, arg[1])
    elseif event == "on_timed_block" then
        local arg = table.pack(...)
        em:_invoke_event_callbacks(enigma.EVENTS.player_timed_block, self._unit, arg[1])
    elseif event == "on_visible" then
        em:_invoke_event_callbacks(enigma.EVENTS.player_visible, self._unit)
    end
end, "enigma_event_trigger_procs")

reg_hook_safe(DeathSystem, "kill_unit", function(self, unit, killing_blow)
	local breed = Unit.get_data(unit, "breed")
    if not breed then
        return
    end
    if breed.is_player then
        em:_invoke_event_callbacks(enigma.EVENTS.player_killed, unit, killing_blow)
    else
        em:_invoke_event_callbacks(enigma.EVENTS.enemy_killed, unit, killing_blow)
    end
end, "enigma_event_kill_unit")

reg_hook_safe(GenericStatusExtension, "set_ready_for_assisted_respawn", function(self, status_bool, flavour_unit)
    if status_bool then
        em:_invoke_event_callbacks(enigma.EVENTS.player_waiting_for_rescue, self.unit)
    end
end, "enigma_event_player_waiting_for_rescue")

reg_hook_safe(PlayerCharacterStateWaitingForAssistedRespawn, "on_enter", function(self, unit, ...)
    enigma:info("Invoking player_respawn event. unit="..tostring(unit))
    em:_invoke_event_callbacks(enigma.EVENTS.player_respawn, unit)
end, "enigma_event_player_respawn")

reg_hook_safe(PlayerCharacterStateWaitingForAssistedRespawn, "on_exit", function(self, unit, ...)
    local helper_unit = self.status_extension:get_assisted_respawn_helper_unit()
    em:_invoke_event_callbacks(enigma.EVENTS.player_picked_up_from_respawn, unit, helper_unit)
    enigma:info("Invoking player_picked_up_from_respawn event. unit="..tostring(unit)..", helper_unit="..tostring(helper_unit))
end, "enigma_event_player_respawn")

reg_hook_safe(PlayerCharacterStateJumping, "on_enter", function(self, unit, ...)
    em:_invoke_event_callbacks(enigma.EVENTS.player_jump, unit)
end, "enigma_event_player_jump")