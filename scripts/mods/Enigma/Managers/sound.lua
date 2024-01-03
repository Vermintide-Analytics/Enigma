local enigma = get_mod("Enigma")

local sm = {
    world = nil,
    wwise_world = nil
}
enigma.managers.sound = sm

local set_world = function(world)
    sm.world = world
    sm.wwise_world = Managers.world:wwise_world(world)
    if not sm.wwise_world then
        sm.world = nil
        enigma:warning("No wwise world found for "..tostring(world).." to initialize Sound Manager")
        return
    end
end

sm.start_game = function(self)
    local world = Managers.world and Managers.world:has_world("level_world") and Managers.world:world("level_world")
    if not world then
        enigma:warning("No world found to initialize Sound Manager")
        return false
    end
    set_world(world)
    return true
end

sm.end_game = function(self)
    self.world = nil
    self.wwise_world = nil
end

sm.trigger = function(self, event_name) -- Shorthand for trigger_2D
    return self:trigger_2D(event_name)
end
sm.trigger_2D = function(self, event_name)
    if not self.wwise_world then
        enigma:warning("Could not trigger sound event \""..tostring(event_name).."\"\nSound Manager not initialized")
        return
    end
    return WwiseWorld.trigger_event(self.wwise_world, event_name)
end

sm.trigger_at_position = function(self, event_name, position)
    if not self.wwise_world then
        enigma:warning("Could not trigger sound event \""..tostring(event_name).."\"\nSound Manager not initialized")
        return
    end
    return WwiseWorld.trigger_event(self.wwise_world, event_name, position)
end

sm.trigger_at_unit = function(self, event_name, unit)
    if not self.wwise_world then
        enigma:warning("Could not trigger sound event \""..tostring(event_name).."\"\nSound Manager not initialized")
        return
    end
    return WwiseWorld.trigger_event(self.wwise_world, event_name, unit)
end