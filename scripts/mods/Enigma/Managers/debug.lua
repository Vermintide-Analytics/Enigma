local enigma = get_mod("Enigma")

local dm = {
    aura_color = ColorBox(255, 255, 255, 0),
    aura_radius = nil
}
enigma.managers.debug = dm

enigma:command("draw_aura", "Draw a sphere of a specific radius around you. If no radius provided, hides the sphere", function(radius)
    if not radius then
        dm.aura_radius = nil
        enigma:echo("Debug aura visualization turned off")
        return
    end
    dm.aura_radius = radius
    if dm.line_object then
        World.destroy_line_object(dm.line_object_world, dm.line_object)
    end
    dm.line_object_world = Managers.world:world("level_world")
    dm.line_object = World.create_line_object(dm.line_object_world)
    enigma:echo("Debug aura visualization radius set to "..tostring(radius))
end)

dm.update = function(self, dt)
    if self.aura_radius then
        local local_player_unit = enigma:local_player_unit()
        local center = Unit.world_position(local_player_unit, 0)
        LineObject.add_sphere(self.line_object, self.aura_color:unbox(), center, self.aura_radius, 50, 10)
        LineObject.dispatch(self.line_object_world, self.line_object)
        LineObject.reset(self.line_object)
    end

end
enigma:register_mod_event_callback("update", dm, "update")