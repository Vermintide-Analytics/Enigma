local loc = {
	mod_description = {
		en = "Enigma description",
	},
}

local base_card_pack_localizations = local_require("scripts/mods/Enigma/CardPacks/Base_localization")

table.merge(loc, base_card_pack_localizations)

return loc
