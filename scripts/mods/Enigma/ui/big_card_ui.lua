local definitions = local_require("scripts/mods/Enigma/ui/big_card_ui_definitions")
local DO_RELOAD = true
EnigmaBigCardUI = class(EnigmaBigCardUI)

local enigma = get_mod("Enigma")

EnigmaBigCardUI.init = function(self, parent, ingame_ui_context)
	self._parent = parent
	self.network_event_delegate = ingame_ui_context.network_event_delegate
	self.camera_manager = ingame_ui_context.camera_manager
	self.ui_renderer = ingame_ui_context.ui_top_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.is_in_inn = ingame_ui_context.is_in_inn
	self.is_server = ingame_ui_context.is_server
	self.world_manager = ingame_ui_context.world_manager
	self.input_manager = ingame_ui_context.input_manager
	self.matchmaking_manager = Managers.matchmaking
	local world = self.world_manager:world("level_world")
	self.wwise_world = Managers.world:wwise_world(world)

	self:create_ui_elements()
end

EnigmaBigCardUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.display_widget = UIWidget.init(definitions.widgets.fullscreen_display)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

EnigmaBigCardUI.update = function (self, dt)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

    local card = enigma.managers.ui.big_card_to_display
	if not card then
		return
	end
	
	if card.texture then
		self.display_widget.content.card_image = card.texture
	else
		self.display_widget.content.card_image = "enigma_card_image_placeholder"
	end

	if card.card_type == enigma.CARD_TYPE.passive then
		self.display_widget.style.card_background.color[2] = 205
		self.display_widget.style.card_background.color[3] = 198
		self.display_widget.style.card_background.color[4] = 111
	elseif card.card_type == enigma.CARD_TYPE.surge then
		self.display_widget.style.card_background.color[2] = 187
		self.display_widget.style.card_background.color[3] = 124
		self.display_widget.style.card_background.color[4] = 118
	elseif card.card_type == enigma.CARD_TYPE.ability then
		self.display_widget.style.card_background.color[2] = 118
		self.display_widget.style.card_background.color[3] = 130
		self.display_widget.style.card_background.color[4] = 187
	else
		self.display_widget.style.card_background.color[2] = 255
		self.display_widget.style.card_background.color[3] = 255
		self.display_widget.style.card_background.color[4] = 255
	end
	self.display_widget.content.card_name = card.name
	self:draw(dt)
end

EnigmaBigCardUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_menu")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, self.display_widget)
	UIRenderer.end_pass(ui_renderer)
end