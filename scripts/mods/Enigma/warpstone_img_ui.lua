local definitions = local_require("scripts/mods/Enigma/warpstone_img_definitions")
local DO_RELOAD = true
WarpstoneImgUI = class(WarpstoneImgUI)

local enigma = get_mod("Enigma")

WarpstoneImgUI.init = function(self, parent, ingame_ui_context)
	self._parent = parent
	self.network_event_delegate = ingame_ui_context.network_event_delegate
	self.camera_manager = ingame_ui_context.camera_manager
	self.ui_renderer = ingame_ui_context.ui_renderer
	self.ingame_ui = ingame_ui_context.ingame_ui
	self.is_in_inn = ingame_ui_context.is_in_inn
	self.is_server = ingame_ui_context.is_server
	self.world_manager = ingame_ui_context.world_manager
	self.input_manager = ingame_ui_context.input_manager

	self:create_ui_elements()
end

WarpstoneImgUI.create_ui_elements = function (self)
	DO_RELOAD = false
	self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
	self.warpstone_img = UIWidget.init(definitions.widgets.fullscreen_warpstone_display)

	UIRenderer.clear_scenegraph_queue(self.ui_renderer)
end

WarpstoneImgUI.update = function (self, dt)
	if DO_RELOAD then
		self:create_ui_elements()
	end

	local ui_suspended = self.ingame_ui.menu_suspended

	if ui_suspended then
		return
	end

	if enigma.show_warpstone then
		self.warpstone_img.style.warpstone_texture.angle = self.warpstone_img.style.warpstone_texture.angle + dt
		self:draw(dt)
	end
end

WarpstoneImgUI.draw = function (self, dt)
	local input_service = self.input_manager:get_service("ingame_menu")
	local ui_renderer = self.ui_renderer

	UIRenderer.begin_pass(ui_renderer, self.ui_scenegraph, input_service, dt)
	UIRenderer.draw_widget(ui_renderer, self.warpstone_img)
	UIRenderer.end_pass(ui_renderer)
end