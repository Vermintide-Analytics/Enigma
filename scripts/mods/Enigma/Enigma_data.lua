local enigma = get_mod("Enigma")

return {
	name = "Enigma",
	description = enigma:localize("mod_description"),
	is_togglable = false,
	options = {
		widgets = {
			{
				setting_id = "card_mode_hotkey",
				type = "keybind",
				title = "card_mode_hotkey_name",
				tooltip = "card_mode_hotkey_description",
				keybind_global = true,
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "card_mode_key_pressed",
				default_value = {}
			},
		}
	},
	custom_gui_textures = {
		textures = {
			"enigma_test_material"
		},
		ui_renderer_injections = {
			{
				"ingame_ui",
				"materials/Enigma/enigma_test_material"
			},
			{
				"ingame_ui",
				"materials/Enigma/card/background"
			},
			{
				"ingame_ui",
				"materials/Enigma/card/frame"
			},
			{
				"ingame_ui",
				"materials/Enigma/card/image_placeholder"
			},
			{
				"ingame_ui",
				"materials/Enigma/art/base/caffeinated"
			},
		}
	}
}
