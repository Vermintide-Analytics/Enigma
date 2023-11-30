local enigma = get_mod("Enigma")

-- Values for a 512x828 card display
local DEFAULT_CARD_WIDTH = 512
local DEFAULT_CARD_HEIGHT = 828
local DEFAULT_CARD_FRAME_THICKNESS = 4
local DEFAULT_PRETTY_MARGIN = 10

local DEFAULT_CARD_NAME_BOX_WIDTH = DEFAULT_CARD_WIDTH - 180
local DEFAULT_CARD_NAME_BOX_HEIGHT = 110

local DEFAULT_CARD_IMAGE_WIDTH = DEFAULT_CARD_WIDTH - DEFAULT_CARD_FRAME_THICKNESS*2
local DEFAULT_CARD_IMAGE_HEIGHT = 310

local DEFAULT_CARD_DETAILS_WIDTH = DEFAULT_CARD_WIDTH - DEFAULT_CARD_FRAME_THICKNESS*2 - DEFAULT_PRETTY_MARGIN*2
local DEFAULT_CARD_DETAILS_HEIGHT = 360

local DEFAULT_CARD_NAME_FONT_SIZE = 64
local DEFAULT_CARD_DETAILS_FONT_SIZE = 32

-- Card vertical breakdown (default size)
-- Frame 4
-- Margin 10
-- Name Box 110
-- Margin 10
-- Image 310
-- Margin 10
-- Details 360
-- Margin 10
-- Frame 4

local ui_common = {
    card_colors = {
        passive = {
            255,
            205,
            198,
            111
        },
        surge = {
            255,
            187,
            124,
            118
        },
        ability = {
            255,
            118,
            130,
            187
        },
        default = {
            255,
            255,
            255,
            255
        }
    }
}

ui_common.add_card_widgets = function(widget_defs, card_scenegraph_id, card_widget_name, card_width)

end

ui_common.update_card_display = function(scenegraph_nodes, widgets, card, card_width)
	local scaling_from_default = card_width / DEFAULT_CARD_WIDTH

    local card_height = DEFAULT_CARD_HEIGHT * scaling_from_default
    local card_frame_thickness = DEFAULT_CARD_FRAME_THICKNESS * scaling_from_default

	local pretty_margin = DEFAULT_PRETTY_MARGIN * scaling_from_default
    
    local inner_card_width = card_width - card_frame_thickness*2
    local inner_card_height = card_height - card_frame_thickness*2
    
	local card_name_box_width = DEFAULT_CARD_NAME_BOX_WIDTH * scaling_from_default
	local card_name_box_height = DEFAULT_CARD_NAME_BOX_HEIGHT * scaling_from_default
	local card_name_font_size = DEFAULT_CARD_NAME_FONT_SIZE * scaling_from_default

    local card_image_width = DEFAULT_CARD_IMAGE_WIDTH * scaling_from_default
	local card_image_height = DEFAULT_CARD_IMAGE_HEIGHT * scaling_from_default

	local card_details_width = DEFAULT_CARD_DETAILS_WIDTH * scaling_from_default
	local card_details_height = DEFAULT_CARD_DETAILS_HEIGHT * scaling_from_default
	local card_details_font_size = DEFAULT_CARD_DETAILS_FONT_SIZE * scaling_from_default

	-- Set scenegraph node sizes and positions
	scenegraph_nodes.card.size[1] = card_width
	scenegraph_nodes.card.size[2] = card_height

	scenegraph_nodes.card_name.size[1] = card_name_box_width
	scenegraph_nodes.card_name.size[2] = card_name_box_height
	scenegraph_nodes.card_name.position[2] = pretty_margin*-1 - card_frame_thickness

	scenegraph_nodes.card_image.size[1] = card_image_width
	scenegraph_nodes.card_image.size[2] = card_image_height
	scenegraph_nodes.card_image.position[2] = pretty_margin*-2 - card_name_box_height - card_frame_thickness

	scenegraph_nodes.card_details.size[1] = card_details_width
	scenegraph_nodes.card_details.size[2] = card_details_height
	scenegraph_nodes.card_details.position[2] = card_frame_thickness + pretty_margin

	-- Set widget sizes and offsets
    local card_widget = widgets.card
    local card_name_widget = widgets.card_name
    local card_image_widget = widgets.card_image
    local card_details_widget = widgets.card_details

	card_widget.style.card_background.texture_size[1] = card_width
	card_widget.style.card_background.texture_size[2] = card_height
	card_widget.style.card_frame.texture_size[1] = card_width
	card_widget.style.card_frame.texture_size[2] = card_height

	card_name_widget.style.card_name._dynamic_wraped_text = ""
	card_name_widget.style.card_name.font_size = card_name_font_size

	card_image_widget.style.card_image.texture_size[1] = card_image_width
	card_image_widget.style.card_image.texture_size[2] = card_image_height

	card_details_widget.style.card_text.area_size[1] = inner_card_width - pretty_margin*2
	card_details_widget.style.card_text.font_size = card_details_font_size

	for i=1,5 do
		local title_pass_name = "described_keyword_title_"..i
		local text_pass_name = "described_keyword_text_"..i
		local title_style = card_details_widget.style[title_pass_name]
		local text_style = card_details_widget.style[text_pass_name]

		title_style.area_size[1] = inner_card_width - pretty_margin*2
		title_style._dynamic_wraped_text = ""
		title_style.font_size = card_details_font_size
		
		text_style.area_size[1] = inner_card_width - pretty_margin*2
		text_style._dynamic_wraped_text = ""
		text_style.font_size = card_details_font_size
	end

	card_details_widget.style.simple_keywords_text.area_size[1] = inner_card_width - pretty_margin*2
	card_details_widget.style.simple_keywords_text._dynamic_wraped_text = ""
	card_details_widget.style.simple_keywords_text.font_size = card_details_font_size


    if card.texture then
		card_image_widget.content.card_image = card.texture
	else
		card_image_widget.content.card_image = "enigma_card_image_placeholder"
	end

	if card.card_type == enigma.CARD_TYPE.passive then
        card_widget.style.card_background.color = ui_common.card_colors.passive
	elseif card.card_type == enigma.CARD_TYPE.surge then
        card_widget.style.card_background.color = ui_common.card_colors.surge
	elseif card.card_type == enigma.CARD_TYPE.ability then
        card_widget.style.card_background.color = ui_common.card_colors.ability
	else
        card_widget.style.card_background.color = ui_common.card_colors.default
	end
	card_name_widget.content.card_name = card.name

	local num_description_lines = #card.description_lines
	local num_auto_descriptions = #card.auto_descriptions
	local num_condition_descriptions = #card.condition_descriptions
	local any_simple_keywords = card.channel or card.double_agent or card.ephemeral or card.infinite or card.unplayable or card.warp_hungry

	local num_rows = num_description_lines + num_auto_descriptions*2 + num_condition_descriptions*2 + (any_simple_keywords and 1 or 0)
	local details_vertical_space = scenegraph_nodes.card_details.size[2]
	local row_height = details_vertical_space / num_rows
	local current_vertical_offset = details_vertical_space/-2 + row_height/2

	if any_simple_keywords then
		local keywords = {}
		if card.channel then
			table.insert(keywords, enigma:localize("channel", card.channel))
		end
		if card.double_agent then
			table.insert(keywords, enigma:localize("double_agent"))
		end
		if card.ephemeral then
			table.insert(keywords, enigma:localize("ephemeral"))
		end
		if card.infinite then
			table.insert(keywords, enigma:localize("infinite"))
		end
		if card.unplayable then
			table.insert(keywords, enigma:localize("unplayable"))
		end
		if card.warp_hungry then
			table.insert(keywords, enigma:localize("warp_hungry", card.warp_hungry))
		end
		card_details_widget.content.simple_keywords_text = table.concat(keywords, ", ")
		card_details_widget.style.simple_keywords_text.offset[2] = current_vertical_offset
		card_details_widget.style.simple_keywords_text.area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + row_height
	else
		card_details_widget.content.simple_keywords_text = ""
	end

	for i=1,5 do
		local described_keyword_title = "described_keyword_title_"..i
		local described_keyword_text = "described_keyword_text_"..i
		card_details_widget.content[described_keyword_title] = ""
		card_details_widget.content[described_keyword_text] = ""
	end

	local described_keyword_index = 1
	local text_size = card_details_widget.style.described_keyword_text_1.font_size
	for _,auto_description_table in ipairs(card.auto_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local described_keyword_title = "described_keyword_title_"..described_keyword_index
		local described_keyword_text = "described_keyword_text_"..described_keyword_index

		current_vertical_offset = current_vertical_offset + row_height/2 - text_size/2 - 3

		card_details_widget.content[described_keyword_text] = auto_description_table.localized
		card_details_widget.style[described_keyword_text].offset[2] = current_vertical_offset
		card_details_widget.style[described_keyword_text].area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + text_size + 6

		card_details_widget.content[described_keyword_title] = enigma:localize("auto")
		card_details_widget.style[described_keyword_title].offset[2] = current_vertical_offset
		current_vertical_offset = current_vertical_offset + row_height*1.5 - 3 - text_size/2
		
		described_keyword_index = described_keyword_index + 1
	end
	for _,condition_description_table in ipairs(card.condition_descriptions) do
		if described_keyword_index > 5 then
			break
		end
		local described_keyword_title = "described_keyword_title_"..described_keyword_index
		local described_keyword_text = "described_keyword_text_"..described_keyword_index

		current_vertical_offset = current_vertical_offset + row_height/2 - text_size/2 - 3

		card_details_widget.content[described_keyword_text] = condition_description_table.localized
		card_details_widget.style[described_keyword_text].offset[2] = current_vertical_offset
		card_details_widget.style[described_keyword_text].area_size[2] = row_height
		current_vertical_offset = current_vertical_offset + text_size + 6

		card_details_widget.content[described_keyword_title] = enigma:localize("condition")
		card_details_widget.style[described_keyword_title].offset[2] = current_vertical_offset
		current_vertical_offset = current_vertical_offset + row_height*1.5 - 3 - text_size/2
		
		described_keyword_index = described_keyword_index + 1
	end

	if num_description_lines > 0 then
		local lines = {}
		for _,description_line_table in ipairs(card.description_lines) do
			table.insert(lines, description_line_table.localized)
		end
		card_details_widget.content.card_text = table.concat(lines, "\n")
		card_details_widget.style.card_text.offset[2] = current_vertical_offset
		card_details_widget.style.card_text.area_size[2] = row_height
		card_details_widget.style.card_text._dynamic_wraped_text = ""
		card_details_widget.style.card_text.font_size = card_details_font_size
	else
		card_details_widget.content.card_text = ""
	end
end

ui_common.update_card_display_if_needed = function(scenegraph, widgets, card, card_size)
    if card and (card.dirty or card ~= widgets.cached_card) then
        return ui_common.update_card_display(scenegraph, widgets, card, card_size)
    end
end

return ui_common