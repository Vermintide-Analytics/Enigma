local enigma = get_mod("Enigma")



local em = {
    events = {}
}
for _,evt in pairs(enigma.EVENTS) do
    em.events[evt] = {
        callbacks = {}
    }
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

reg_hook_safe(GenericHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    em:_invoke_event_callbacks(enigma.EVENTS.enemy_damaged, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end, "enigma_event_enemy_damaged")

reg_hook_safe(PlayerUnitHealthExtension, "add_damage", function(self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
    em:_invoke_event_callbacks(enigma.EVENTS.player_damaged, self, attacker_unit, damage_amount, hit_zone_name, damage_type, hit_position, damage_direction, damage_source_name, hit_ragdoll_actor, source_attacker_unit, hit_react_type, is_critical_strike, added_dot, first_hit, total_hits, attack_type, backstab_multiplier)
end, "enigma_event_player_damaged")