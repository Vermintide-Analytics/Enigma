local enigma = get_mod("Enigma")

local templates = ExplosionTemplates
local net_lookup = NetworkLookup.explosion_templates

local new_template = function(name, template)
    templates[name] = template
    local index = #net_lookup + 1
    net_lookup[index] = name
    net_lookup[name] = index
end

local grenade_no_ff = table.clone(templates.grenade)
grenade_no_ff.explosion.no_friendly_fire = true
new_template("grenade_no_ff", grenade_no_ff)