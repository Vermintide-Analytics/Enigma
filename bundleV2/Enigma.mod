return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Enigma` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Enigma", {
			mod_script       = "scripts/mods/Enigma/Enigma",
			mod_data         = "scripts/mods/Enigma/Enigma_data",
			mod_localization = "scripts/mods/Enigma/Enigma_localization",
		})
	end,
	packages = {
		"resource_packages/Enigma/Enigma",
	},
}
