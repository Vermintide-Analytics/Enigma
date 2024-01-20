local data = require("scripts/ui/hud_ui/component_list_definitions/hud_component_list_inn_deus")

local enigma_data = require("scripts/mods/Enigma/ui/hud_component/enigma_hud_components")

local components = {}
local visibility_groups = {}

table.append(components, data.components)
table.append(components, enigma_data.components)

table.append(visibility_groups, data.visibility_groups)
table.append(visibility_groups, enigma_data.visibility_groups)

return {
	components = components,
	visibility_groups = visibility_groups
}
