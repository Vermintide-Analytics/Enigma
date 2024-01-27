local enigma = get_mod("Enigma")

local templates = ExplosionTemplates
local net_lookup = NetworkLookup.explosion_templates

local new_template = function(name, template)
    templates[name] = template
    local index = #net_lookup + 1
    net_lookup[index] = name
    net_lookup[name] = index
end

local simple_scale_template = function(template, scale)
    if template.explosion then
        local expl = template.explosion
        expl.radius = expl.radius and expl.radius * scale
        expl.max_damage_radius = expl.max_damage_radius and expl.max_damage_radius * scale
        expl.alert_enemies_radius = expl.alert_enemies_radius and expl.alert_enemies_radius * scale

        if expl.camera_effect then
            local cam = expl.camera_effect
            cam.near_distance = cam.near_distance and cam.near_distance * scale
            cam.far_distance = cam.far_distance and cam.far_distance * scale
        end
    end
    if template.aoe then
        local aoe = template.aoe
        aoe.radius = aoe.radius and aoe.radius * scale

        if aoe.nav_mesh_effect then
            local nav = aoe.nav_mesh_effect
            nav.particle_radius = nav.particle_radius and nav.particle_radius * scale
            nav.particle_spacing = nav.particle_spacing and nav.particle_spacing * scale
        end
    end
end

local grenade_no_ff = table.clone(templates.grenade)
grenade_no_ff.explosion.no_friendly_fire = true
new_template("grenade_no_ff", grenade_no_ff)

local grenade_no_ff_scaled_x3 = table.clone(templates.grenade)
grenade_no_ff_scaled_x3.explosion.no_friendly_fire = true
simple_scale_template(grenade_no_ff_scaled_x3, 3)
new_template("grenade_no_ff_scaled_x3", grenade_no_ff_scaled_x3)