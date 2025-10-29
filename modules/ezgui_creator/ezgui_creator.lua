local config = require('config')
local images = require('images')
local texts = require('texts')
local definitions = require('modules.ezgui_creator.core.definitions')

require('tables')
require('strings')

local ezgui_creator = {}

local state = {
    active = false,
    addon_settings = nil,
    overlay = nil,
    instruction = nil,
    background = nil,
    definition = nil,
    base_position = { x = 0, y = 0 },
    elements = {},
    selected = nil,
    highlight = nil,
    cursor = nil,
    cursor_position = nil,
    cursor_offset = { x = 0, y = 0 },
    element_buttons = {},
    clipboard = { type = nil, subset = nil, data = nil },
    button_groups = {
        persistent = {},
        main = {},
        editor = {},
        footer = {},
        settings = {},
    },
    labels = {},
    settings_labels = {},
    events = { mouse = nil, keyboard = nil },
    mouse_down_button = nil,
}

local refresh_settings_labels
local update_text_visual
local update_image_visual

local KEY_RELEASE_COMMANDS = {
    [200] = 'UP',
    [203] = 'LEFT',
    [205] = 'RIGHT',
    [208] = 'DOWN',
}

local function deepcopy(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepcopy(v)
    end
    return copy
end

local function get_screen_size()
    local settings = windower.get_windower_settings()
    return settings.ui_x_res or 1920, settings.ui_y_res or 1080
end

local function ensure_overlay()
    local width, height = get_screen_size()
    if state.overlay then
        state.overlay:size(width, height)
        state.overlay:pos(0, 0)
        state.overlay:show()
        return
    end

    state.overlay = images.new({
        color = { red = 0, green = 0, blue = 0, alpha = 255 },
        size = { width = width, height = height },
        draggable = false,
    })
    state.overlay:pos(0, 0)
    state.overlay:show()
end

local function destroy_overlay()
    if state.overlay then
        state.overlay:destroy()
        state.overlay = nil
    end
end

local function destroy_instruction()
    if state.instruction then
        state.instruction:destroy()
        state.instruction = nil
    end
end

local function destroy_background()
    if state.background then
        state.background:destroy()
        state.background = nil
    end
end

local function destroy_highlight()
    if state.highlight then
        state.highlight:destroy()
        state.highlight = nil
    end
end

local function ensure_cursor(force_recreate)
    if state.cursor and force_recreate then
        local pos_x, pos_y = state.cursor:pos()
        state.cursor:destroy()
        state.cursor = nil
        state.cursor_position = { x = pos_x, y = pos_y }
    end

    if state.cursor then
        state.cursor:visible(true)
        return
    end

    local target_x
    local target_y
    if state.cursor_position then
        target_x = state.cursor_position.x or 0
        target_y = state.cursor_position.y or 0
        state.cursor_position = nil
    else
        local screen_w, screen_h = get_screen_size()
        target_x = math.max(0, math.floor(screen_w / 2))
        target_y = math.max(0, math.floor(screen_h / 2))
    end

    state.cursor = texts.new('+', {
        text = {
            font = 'Arial',
            size = 20,
            alpha = 255,
            red = 255,
            green = 60,
            blue = 60,
            stroke = { width = 2, alpha = 220, red = 0, green = 0, blue = 0 },
        },
        bg = { visible = false },
        flags = { draggable = false, bold = true },
        pos = { x = target_x, y = target_y },
    })

    state.cursor:visible(true)
    local width, height = state.cursor:extents()
    state.cursor_offset = {
        x = math.floor((width or 0) / 2),
        y = math.floor((height or 0) / 2),
    }

    local pos_x = math.max(0, target_x - (state.cursor_offset.x or 0))
    local pos_y = math.max(0, target_y - (state.cursor_offset.y or 0))
    state.cursor:pos(pos_x, pos_y)
    state.cursor_position = { x = pos_x, y = pos_y }
end

local function destroy_cursor()
    if state.cursor then
        state.cursor:destroy()
        state.cursor = nil
    end
    state.cursor_position = nil
    state.cursor_offset = { x = 0, y = 0 }
end

local function destroy_labels(collection)
    local target = collection or state.labels
    for index = #target, 1, -1 do
        local label = target[index]
        if label and label.object then
            label.object:destroy()
        end
        target[index] = nil
    end
end

local function destroy_settings_labels()
    destroy_labels(state.settings_labels)
    state.settings_labels = {}
end

local function destroy_elements()
    for index, element in ipairs(state.elements or {}) do
        if element.object then
            if element.type == 'text' and element.object.destroy then
                element.object:destroy()
            elseif element.object.destroy then
                element.object:destroy()
            end
        end
        state.elements[index] = nil
    end
    state.elements = {}
end

local function update_element_palette_highlight()
    for _, entry in ipairs(state.element_buttons or {}) do
        local button = entry.button
        local is_selected = state.selected == entry.element
        if button then
            if button.background and button.background.color then
                if is_selected then
                    button.background:color(120, 190, 255)
                    button.background:alpha(255)
                else
                    button.background:color(60, 60, 70)
                    button.background:alpha(220)
                end
            end
            if button.label and button.label.color then
                if is_selected then
                    button.label:color(15, 20, 30)
                else
                    button.label:color(255, 255, 255)
                end
            end
        end
    end
end

local TEXT_CLIPBOARD_LABELS = {
    all = 'All',
    pos_x = 'X Position',
    pos_y = 'Y Position',
    font = 'Font Options',
}

local IMAGE_CLIPBOARD_LABELS = {
    all = 'All',
    pos_x = 'X Position',
    pos_y = 'Y Position',
    width = 'Width',
    height = 'Height',
}

local function clipboard_summary()
    local clip = state.clipboard or {}
    if not clip.type then
        return 'Clipboard: (empty)'
    end

    local type_label = clip.type == 'text' and 'Text' or 'Image'
    local subset_map = clip.type == 'text' and TEXT_CLIPBOARD_LABELS or IMAGE_CLIPBOARD_LABELS
    local subset_label = subset_map[clip.subset] or (clip.subset or 'Custom')
    return string.format('Clipboard: %s (%s)', type_label, subset_label)
end

local function set_clipboard(clip_type, subset, data)
    state.clipboard = {
        type = clip_type,
        subset = subset,
        data = deepcopy(data),
    }
    refresh_settings_labels()
end

local function copy_text_properties(subset)
    local element = state.selected
    if not element or element.type ~= 'text' then
        return
    end

    element.offset = element.offset or { x = 0, y = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    element.stroke = element.stroke or { width = 0, alpha = 255, red = 0, green = 0, blue = 0 }

    local payload = {}
    if subset == 'all' or subset == 'pos_x' then
        payload.offset = payload.offset or {}
        payload.offset.x = element.offset.x or 0
    end
    if subset == 'all' or subset == 'pos_y' then
        payload.offset = payload.offset or {}
        payload.offset.y = element.offset.y or 0
    end

    if subset == 'all' or subset == 'font' then
        payload.font = element.font
        payload.size = element.size
        payload.color = deepcopy(element.color)
        payload.stroke = deepcopy(element.stroke)
        payload.bold = element.bold
        payload.italic = element.italic
        payload.right = element.right
        payload.bottom = element.bottom
    end

    set_clipboard('text', subset, payload)
end

local function apply_text_payload(element, payload, subset)
    element.offset = element.offset or { x = 0, y = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    element.stroke = element.stroke or { width = 0, alpha = 255, red = 0, green = 0, blue = 0 }

    if payload.offset then
        if (subset == 'all' or subset == 'pos_x') and payload.offset.x ~= nil then
            element.offset.x = payload.offset.x
        end
        if (subset == 'all' or subset == 'pos_y') and payload.offset.y ~= nil then
            element.offset.y = payload.offset.y
        end
    end

    if subset == 'all' or subset == 'font' then
        if payload.font then element.font = payload.font end
        if payload.size then element.size = payload.size end
        if payload.color then element.color = deepcopy(payload.color) end
        if payload.stroke then element.stroke = deepcopy(payload.stroke) end
        if payload.bold ~= nil then element.bold = payload.bold end
        if payload.italic ~= nil then element.italic = payload.italic end
        if payload.right ~= nil then element.right = payload.right end
        if payload.bottom ~= nil then element.bottom = payload.bottom end
    end
end

local function paste_text_properties(subset)
    local element = state.selected
    local clip = state.clipboard
    if not element or element.type ~= 'text' or not clip or clip.type ~= 'text' then
        return
    end

    local payload = clip.data or {}
    local effective_subset = subset
    if clip.subset == 'all' then
        effective_subset = subset
    elseif clip.subset ~= subset and clip.subset ~= 'all' then
        -- If clipboard doesn't contain requested subset, abort.
        return
    end

    apply_text_payload(element, payload, effective_subset)
    update_text_visual(element)
    refresh_settings_labels()
    update_highlight()
    update_element_palette_highlight()
end

local function copy_image_properties(subset)
    local element = state.selected
    if not element or element.type ~= 'image' then
        return
    end

    element.offset = element.offset or { x = 0, y = 0 }
    element.size = element.size or { width = 0, height = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }

    local payload = {}
    if subset == 'all' or subset == 'pos_x' then
        payload.offset = payload.offset or {}
        payload.offset.x = element.offset.x or 0
    end
    if subset == 'all' or subset == 'pos_y' then
        payload.offset = payload.offset or {}
        payload.offset.y = element.offset.y or 0
    end
    if subset == 'all' or subset == 'width' then
        payload.size = payload.size or {}
        payload.size.width = element.size.width or 0
    end
    if subset == 'all' or subset == 'height' then
        payload.size = payload.size or {}
        payload.size.height = element.size.height or 0
    end
    if subset == 'all' then
        payload.color = deepcopy(element.color)
    end

    set_clipboard('image', subset, payload)
end

local function apply_image_payload(element, payload, subset)
    element.offset = element.offset or { x = 0, y = 0 }
    element.size = element.size or { width = 0, height = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }

    if payload.offset then
        if (subset == 'all' or subset == 'pos_x') and payload.offset.x ~= nil then
            element.offset.x = payload.offset.x
        end
        if (subset == 'all' or subset == 'pos_y') and payload.offset.y ~= nil then
            element.offset.y = payload.offset.y
        end
    end

    if payload.size then
        if (subset == 'all' or subset == 'width') and payload.size.width ~= nil then
            element.size.width = payload.size.width
        end
        if (subset == 'all' or subset == 'height') and payload.size.height ~= nil then
            element.size.height = payload.size.height
        end
    end

    if subset == 'all' and payload.color then
        element.color = deepcopy(payload.color)
    end
end

local function paste_image_properties(subset)
    local element = state.selected
    local clip = state.clipboard
    if not element or element.type ~= 'image' or not clip or clip.type ~= 'image' then
        return
    end

    local payload = clip.data or {}
    local effective_subset = subset
    if clip.subset == 'all' then
        effective_subset = subset
    elseif clip.subset ~= subset and clip.subset ~= 'all' then
        return
    end

    apply_image_payload(element, payload, effective_subset)
    update_image_visual(element)
    refresh_settings_labels()
    update_highlight()
    update_element_palette_highlight()
end

local function button_contains(button, x, y)
    return button.visible
        and x >= button.x and x <= (button.x + button.width)
        and y >= button.y and y <= (button.y + button.height)
end

local function show_button(button)
    if not button then
        return
    end

    button.visible = true
    if button.background then
        button.background:show()
    end
    if button.label then
        button.label:visible(true)
    end
end

local function hide_button(button)
    if not button then
        return
    end

    button.visible = false
    if button.background then
        button.background:hide()
    end
    if button.label then
        button.label:visible(false)
    end
end

local function destroy_button(button)
    if not button then
        return
    end

    if button.background then
        button.background:destroy()
    end
    if button.label then
        button.label:destroy()
    end
end

local function clear_buttons(group)
    local collection = state.button_groups[group]
    if not collection then
        return
    end

    for index = #collection, 1, -1 do
        destroy_button(collection[index])
        collection[index] = nil
    end
    state.button_groups[group] = {}
end

local function all_buttons()
    local aggregated = {}
    for _, collection in pairs(state.button_groups) do
        for _, button in ipairs(collection) do
            aggregated[#aggregated + 1] = button
        end
    end
    return aggregated
end

local function register_button(group, button)
    local collection = state.button_groups[group]
    if not collection then
        return
    end

    collection[#collection + 1] = button
end

local function create_instruction(text)
    destroy_instruction()

    local screen_w = get_screen_size()
    local pos_x = math.floor((screen_w - 800) / 2)

    local instruction = texts.new(text or '', {
        text = {
            font = 'Arial',
            size = 24,
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255,
            stroke = { width = 2, alpha = 200, red = 0, green = 0, blue = 0 },
        },
        bg = { visible = false },
        flags = { draggable = false },
        pos = { x = pos_x, y = 80 },
    })

    instruction:visible(true)
    state.instruction = instruction
end

local function create_button(label, x, y, width, height, callback, options)
    options = options or {}
    local background = images.new({
        color = {
            red = options.red or 40,
            green = options.green or 40,
            blue = options.blue or 40,
            alpha = options.alpha or 220,
        },
        size = { width = width, height = height },
        draggable = false,
    })
    background:pos(x, y)
    background:show()

    local label_text = texts.new(label or '', {
        text = {
            font = options.font or 'Arial',
            size = options.size or 16,
            alpha = 255,
            red = options.text_red or 255,
            green = options.text_green or 255,
            blue = options.text_blue or 255,
            stroke = { width = 2, alpha = 200, red = 0, green = 0, blue = 0 },
        },
        bg = { visible = false },
        flags = { draggable = false },
        pos = { x = x + 12, y = y + math.floor(height / 2) - 10 },
    })
    label_text:visible(true)

    local button = {
        x = x,
        y = y,
        width = width,
        height = height,
        callback = callback,
        background = background,
        label = label_text,
        visible = true,
    }

    function button:set_label(value)
        if self.label then
            self.label:text(value)
        end
    end

    function button:show()
        show_button(self)
    end

    function button:hide()
        hide_button(self)
    end

    function button:destroy()
        destroy_button(self)
    end

    function button:contains(px, py)
        return button_contains(self, px, py)
    end

    function button:activate()
        if self.callback then
            self.callback()
        end
    end

    return button
end

local function clear_view()
    destroy_instruction()
    destroy_background()
    destroy_highlight()
    destroy_elements()
    destroy_labels()
    destroy_settings_labels()

    clear_buttons('main')
    clear_buttons('editor')
    clear_buttons('footer')
    clear_buttons('settings')

    state.definition = nil
    state.selected = nil
    state.labels = {}
    state.element_buttons = {}
    state.mouse_down_button = nil
end

local function update_highlight()
    destroy_highlight()

    local element = state.selected
    if not element or not element.object then
        return
    end

    local x, y, width, height
    if element.type == 'text' then
        local settings = texts.settings(element.object)
        local pos_x, pos_y = element.object:pos()
        local extents_x, extents_y = element.object:extents()
        if settings.flags.right then
            pos_x = pos_x - extents_x
        end
        if settings.flags.bottom then
            pos_y = pos_y - extents_y
        end
        x = pos_x
        y = pos_y
        width = extents_x
        height = extents_y
    else
        x, y = element.object:pos()
        width, height = element.object:size()
    end

    state.highlight = images.new({
        color = { red = 120, green = 180, blue = 255, alpha = 120 },
        size = { width = width + 8, height = height + 8 },
        draggable = false,
    })
    state.highlight:pos(x - 4, y - 4)
    state.highlight:show()
end

refresh_settings_labels = function()
    if not state.selected then
        return
    end

    for _, entry in ipairs(state.settings_labels) do
        if entry.kind == 'text_font' then
            entry.object:text('Font: ' .. (state.selected.font or 'Arial'))
        elseif entry.kind == 'text_size' then
            entry.object:text('Font Size: ' .. tostring(state.selected.size or 12))
        elseif entry.kind == 'text_color' then
            local color = state.selected.color or { red = 255, green = 255, blue = 255, alpha = 255 }
            entry.object:text(string.format('Color (RGBA): %d / %d / %d / %d', color.red or 0, color.green or 0, color.blue or 0, color.alpha or 0))
        elseif entry.kind == 'text_flags' then
            local parts = {}
            if state.selected.bold then
                parts[#parts + 1] = 'Bold'
            end
            if state.selected.italic then
                parts[#parts + 1] = 'Italic'
            end
            entry.object:text('Style: ' .. (#parts > 0 and table.concat(parts, ', ') or 'Normal'))
        elseif entry.kind == 'image_size' then
            local size = state.selected.size or { width = 0, height = 0 }
            entry.object:text(string.format('Size: %d x %d', size.width or 0, size.height or 0))
        elseif entry.kind == 'image_color' then
            local color = state.selected.color or { red = 255, green = 255, blue = 255, alpha = 255 }
            entry.object:text(string.format('Tint (RGBA): %d / %d / %d / %d', color.red or 0, color.green or 0, color.blue or 0, color.alpha or 0))
        elseif entry.kind == 'copy_header' then
            entry.object:text('Copy / Paste Tools')
        elseif entry.kind == 'clipboard_info' then
            entry.object:text(clipboard_summary())
        end
    end
end

local function create_settings_label(kind, text, position)
    local label = texts.new(text or '', {
        text = {
            font = 'Arial',
            size = 18,
            alpha = 255,
            red = 220,
            green = 220,
            blue = 220,
            stroke = { width = 2, alpha = 180, red = 0, green = 0, blue = 0 },
        },
        bg = { visible = false },
        flags = { draggable = false },
        pos = { x = position.x, y = position.y },
    })
    label:visible(true)

    local entry = { object = label, kind = kind }
    state.settings_labels[#state.settings_labels + 1] = entry
    return entry
end

update_text_visual = function(element)
    if not element or not element.object then
        return
    end

    element.offset = element.offset or { x = 0, y = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    element.stroke = element.stroke or { width = 0, alpha = 255, red = 0, green = 0, blue = 0 }

    local color = element.color
    local stroke = element.stroke

    element.object:pos(state.base_position.x + (element.offset.x or 0), state.base_position.y + (element.offset.y or 0))
    element.object:font(element.font or 'Arial')
    element.object:size(element.size or 12)
    element.object:color(color.red or 255, color.green or 255, color.blue or 255)
    element.object:alpha(color.alpha or 255)
    element.object:stroke_width(stroke.width or 0)
    element.object:stroke_color(stroke.red or 0, stroke.green or 0, stroke.blue or 0)
    element.object:stroke_alpha(stroke.alpha or 255)
    if element.object.bold then
        element.object:bold(element.bold and true or false)
    end
    if element.object.italic then
        element.object:italic(element.italic and true or false)
    end
    if element.object.right_justified then
        element.object:right_justified(element.right and true or false)
    elseif element.object.right then
        element.object:right(element.right and true or false)
    end
    if element.object.bottom_justified then
        element.object:bottom_justified(element.bottom and true or false)
    elseif element.object.bottom then
        element.object:bottom(element.bottom and true or false)
    end
end

update_image_visual = function(element)
    if not element or not element.object then
        return
    end

    element.offset = element.offset or { x = 0, y = 0 }
    element.size = element.size or { width = 0, height = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }

    local color = element.color
    element.object:pos(state.base_position.x + (element.offset.x or 0), state.base_position.y + (element.offset.y or 0))
    element.object:size((element.size and element.size.width) or 0, (element.size and element.size.height) or 0)
    if element.texture then
        local texture_path = element.texture
        if type(texture_path) == 'string' then
            if not texture_path:match('^[\\/]+') and not texture_path:match('^%a:[\\/]') then
                texture_path = windower.addon_path .. texture_path
            end
            element.object:path(texture_path)
        end
    end
    if element.object.fit then
        element.object:fit(false)
    end
    element.object:color(color.red or 255, color.green or 255, color.blue or 255)
    element.object:alpha(color.alpha or 255)
end

local function rebuild_settings_panel()
    clear_buttons('settings')
    destroy_settings_labels()

    if not state.selected then
        return
    end

    local base_x = 60
    local base_y = 180

    if state.selected.type == 'text' then
        create_settings_label('text_font', '', { x = base_x, y = base_y })
        register_button('settings', create_button('Previous Font', base_x, base_y + 30, 220, 30, function()
            local fonts = definitions.available_fonts()
            local current = state.selected.font or fonts[1]
            local index
            for i, font in ipairs(fonts) do
                if font:lower() == current:lower() then
                    index = i
                    break
                end
            end
            index = (index or 1) - 1
            if index < 1 then
                index = #fonts
            end
            state.selected.font = fonts[index]
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))

        register_button('settings', create_button('Next Font', base_x, base_y + 66, 220, 30, function()
            local fonts = definitions.available_fonts()
            local current = state.selected.font or fonts[1]
            local index
            for i, font in ipairs(fonts) do
                if font:lower() == current:lower() then
                    index = i
                    break
                end
            end
            index = (index or 1) + 1
            if index > #fonts then
                index = 1
            end
            state.selected.font = fonts[index]
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))

        create_settings_label('text_size', '', { x = base_x, y = base_y + 110 })
        register_button('settings', create_button('Increase Size', base_x, base_y + 140, 220, 30, function()
            state.selected.size = (state.selected.size or 12) + 1
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Decrease Size', base_x, base_y + 176, 220, 30, function()
            state.selected.size = math.max(1, (state.selected.size or 12) - 1)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))

        create_settings_label('text_color', '', { x = base_x, y = base_y + 220 })
        register_button('settings', create_button('Red +', base_x, base_y + 250, 104, 28, function()
            state.selected.color.red = math.min(255, (state.selected.color.red or 0) + 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Red -', base_x + 116, base_y + 250, 104, 28, function()
            state.selected.color.red = math.max(0, (state.selected.color.red or 0) - 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Green +', base_x, base_y + 284, 104, 28, function()
            state.selected.color.green = math.min(255, (state.selected.color.green or 0) + 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Green -', base_x + 116, base_y + 284, 104, 28, function()
            state.selected.color.green = math.max(0, (state.selected.color.green or 0) - 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Blue +', base_x, base_y + 318, 104, 28, function()
            state.selected.color.blue = math.min(255, (state.selected.color.blue or 0) + 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Blue -', base_x + 116, base_y + 318, 104, 28, function()
            state.selected.color.blue = math.max(0, (state.selected.color.blue or 0) - 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Alpha +', base_x, base_y + 352, 104, 28, function()
            state.selected.color.alpha = math.min(255, (state.selected.color.alpha or 0) + 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Alpha -', base_x + 116, base_y + 352, 104, 28, function()
            state.selected.color.alpha = math.max(0, (state.selected.color.alpha or 0) - 5)
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))

        create_settings_label('text_flags', '', { x = base_x, y = base_y + 392 })
        register_button('settings', create_button('Toggle Bold', base_x, base_y + 422, 220, 30, function()
            state.selected.bold = not state.selected.bold
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Toggle Italic', base_x, base_y + 458, 220, 30, function()
            state.selected.italic = not state.selected.italic
            update_text_visual(state.selected)
            refresh_settings_labels()
        end))

        create_settings_label('copy_header', '', { x = base_x, y = base_y + 500 })
        create_settings_label('clipboard_info', '', { x = base_x, y = base_y + 530 })
        register_button('settings', create_button('Copy All', base_x, base_y + 560, 104, 28, function()
            copy_text_properties('all')
        end))
        register_button('settings', create_button('Paste All', base_x + 116, base_y + 560, 104, 28, function()
            paste_text_properties('all')
        end))
        register_button('settings', create_button('Copy X Pos', base_x, base_y + 594, 104, 28, function()
            copy_text_properties('pos_x')
        end))
        register_button('settings', create_button('Paste X Pos', base_x + 116, base_y + 594, 104, 28, function()
            paste_text_properties('pos_x')
        end))
        register_button('settings', create_button('Copy Y Pos', base_x, base_y + 628, 104, 28, function()
            copy_text_properties('pos_y')
        end))
        register_button('settings', create_button('Paste Y Pos', base_x + 116, base_y + 628, 104, 28, function()
            paste_text_properties('pos_y')
        end))
        register_button('settings', create_button('Copy Font Opt', base_x, base_y + 662, 104, 28, function()
            copy_text_properties('font')
        end))
        register_button('settings', create_button('Paste Font Opt', base_x + 116, base_y + 662, 104, 28, function()
            paste_text_properties('font')
        end))
    else
        create_settings_label('image_size', '', { x = base_x, y = base_y })
        register_button('settings', create_button('Increase Width', base_x, base_y + 30, 220, 30, function()
            state.selected.size.width = math.max(1, (state.selected.size.width or 0) + 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
            update_highlight()
        end))
        register_button('settings', create_button('Decrease Width', base_x, base_y + 66, 220, 30, function()
            state.selected.size.width = math.max(1, (state.selected.size.width or 0) - 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
            update_highlight()
        end))
        register_button('settings', create_button('Increase Height', base_x, base_y + 102, 220, 30, function()
            state.selected.size.height = math.max(1, (state.selected.size.height or 0) + 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
            update_highlight()
        end))
        register_button('settings', create_button('Decrease Height', base_x, base_y + 138, 220, 30, function()
            state.selected.size.height = math.max(1, (state.selected.size.height or 0) - 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
            update_highlight()
        end))

        create_settings_label('image_color', '', { x = base_x, y = base_y + 182 })
        register_button('settings', create_button('Alpha +', base_x, base_y + 212, 220, 30, function()
            state.selected.color.alpha = math.min(255, (state.selected.color.alpha or 0) + 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
        end))
        register_button('settings', create_button('Alpha -', base_x, base_y + 248, 220, 30, function()
            state.selected.color.alpha = math.max(0, (state.selected.color.alpha or 0) - 5)
            update_image_visual(state.selected)
            refresh_settings_labels()
        end))

        create_settings_label('copy_header', '', { x = base_x, y = base_y + 288 })
        create_settings_label('clipboard_info', '', { x = base_x, y = base_y + 318 })
        register_button('settings', create_button('Copy All', base_x, base_y + 348, 104, 28, function()
            copy_image_properties('all')
        end))
        register_button('settings', create_button('Paste All', base_x + 116, base_y + 348, 104, 28, function()
            paste_image_properties('all')
        end))
        register_button('settings', create_button('Copy X Pos', base_x, base_y + 382, 104, 28, function()
            copy_image_properties('pos_x')
        end))
        register_button('settings', create_button('Paste X Pos', base_x + 116, base_y + 382, 104, 28, function()
            paste_image_properties('pos_x')
        end))
        register_button('settings', create_button('Copy Y Pos', base_x, base_y + 416, 104, 28, function()
            copy_image_properties('pos_y')
        end))
        register_button('settings', create_button('Paste Y Pos', base_x + 116, base_y + 416, 104, 28, function()
            paste_image_properties('pos_y')
        end))
        register_button('settings', create_button('Copy Width', base_x, base_y + 450, 104, 28, function()
            copy_image_properties('width')
        end))
        register_button('settings', create_button('Paste Width', base_x + 116, base_y + 450, 104, 28, function()
            paste_image_properties('width')
        end))
        register_button('settings', create_button('Copy Height', base_x, base_y + 484, 104, 28, function()
            copy_image_properties('height')
        end))
        register_button('settings', create_button('Paste Height', base_x + 116, base_y + 484, 104, 28, function()
            paste_image_properties('height')
        end))
    end

    refresh_settings_labels()
end

local function select_element(element)
    if not element then
        return
    end

    element.offset = element.offset or { x = 0, y = 0 }
    if element.type == 'text' then
        element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
        element.stroke = element.stroke or { width = 0, alpha = 255, red = 0, green = 0, blue = 0 }
        element.color.red = element.color.red or 255
        element.color.green = element.color.green or 255
        element.color.blue = element.color.blue or 255
        element.color.alpha = element.color.alpha or 255
        element.stroke.width = element.stroke.width or 0
        element.stroke.alpha = element.stroke.alpha or 255
        element.stroke.red = element.stroke.red or 0
        element.stroke.green = element.stroke.green or 0
        element.stroke.blue = element.stroke.blue or 0
    else
        element.size = element.size or { width = 0, height = 0 }
        element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
        element.size.width = element.size.width or 0
        element.size.height = element.size.height or 0
        element.color.red = element.color.red or 255
        element.color.green = element.color.green or 255
        element.color.blue = element.color.blue or 255
        element.color.alpha = element.color.alpha or 255
    end

    state.selected = element
    rebuild_settings_panel()
    update_highlight()
    update_element_palette_highlight()
end

local function create_text_element(entry)
    local element = deepcopy(entry)
    element.offset = element.offset or { x = 0, y = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    element.stroke = element.stroke or { width = 0, alpha = 255, red = 0, green = 0, blue = 0 }
    element.color.red = element.color.red or 255
    element.color.green = element.color.green or 255
    element.color.blue = element.color.blue or 255
    element.color.alpha = element.color.alpha or 255
    element.stroke.width = element.stroke.width or 0
    element.stroke.alpha = element.stroke.alpha or 255
    element.stroke.red = element.stroke.red or 0
    element.stroke.green = element.stroke.green or 0
    element.stroke.blue = element.stroke.blue or 0
    element.object = texts.new(entry.sample or entry.label or '', {
        text = {
            font = entry.font or 'Arial',
            size = entry.size or 12,
            alpha = (entry.color and entry.color.alpha) or 255,
            red = (entry.color and entry.color.red) or 255,
            green = (entry.color and entry.color.green) or 255,
            blue = (entry.color and entry.color.blue) or 255,
            stroke = {
                width = (entry.stroke and entry.stroke.width) or 0,
                alpha = (entry.stroke and entry.stroke.alpha) or 255,
                red = (entry.stroke and entry.stroke.red) or 0,
                green = (entry.stroke and entry.stroke.green) or 0,
                blue = (entry.stroke and entry.stroke.blue) or 0,
            },
        },
        bg = { visible = false },
        flags = {
            draggable = false,
            bold = entry.bold and true or false,
            italic = entry.italic and true or false,
            right = entry.right and true or false,
            bottom = entry.bottom and true or false,
        },
        pos = {
            x = state.base_position.x + (entry.offset and entry.offset.x or 0),
            y = state.base_position.y + (entry.offset and entry.offset.y or 0),
        },
    })

    element.object:visible(true)
    update_text_visual(element)
    return element
end

local function create_image_element(entry)
    local element = deepcopy(entry)
    element.offset = element.offset or { x = 0, y = 0 }
    element.size = element.size or { width = 0, height = 0 }
    element.color = element.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    element.size.width = element.size.width or 0
    element.size.height = element.size.height or 0
    element.color.red = element.color.red or 255
    element.color.green = element.color.green or 255
    element.color.blue = element.color.blue or 255
    element.color.alpha = element.color.alpha or 255
    local texture_path = entry.texture
    if texture_path and not texture_path:match('^[\\/]+') and not texture_path:match('^%a:[\\/]') then
        texture_path = windower.addon_path .. texture_path
    end

    element.object = images.new({
        color = {
            alpha = (entry.color and entry.color.alpha) or 255,
            red = (entry.color and entry.color.red) or 255,
            green = (entry.color and entry.color.green) or 255,
            blue = (entry.color and entry.color.blue) or 255,
        },
        size = {
            width = (entry.size and entry.size.width) or 0,
            height = (entry.size and entry.size.height) or 0,
        },
        texture = texture_path and { path = texture_path, fit = false } or nil,
        draggable = false,
    })
    element.object:pos(state.base_position.x + (entry.offset and entry.offset.x or 0), state.base_position.y + (entry.offset and entry.offset.y or 0))
    element.object:size((entry.size and entry.size.width) or 0, (entry.size and entry.size.height) or 0)
    if texture_path then
        element.object:path(texture_path)
    end
    if element.object.fit then
        element.object:fit(false)
    end
    element.object:show()
    update_image_visual(element)
    return element
end

local function build_element_palette()
    clear_buttons('editor')
    state.element_buttons = {}

    local elements = state.elements or {}
    if #elements == 0 then
        update_element_palette_highlight()
        return
    end

    local screen_w = select(1, get_screen_size())
    local menu_width = 260
    local button_height = 34
    local spacing = 8
    local start_x = screen_w - menu_width - 80
    local start_y = 220

    local header = texts.new('UI Elements', {
        text = {
            font = 'Arial',
            size = 18,
            alpha = 255,
            red = 210,
            green = 210,
            blue = 210,
            stroke = { width = 2, alpha = 180, red = 0, green = 0, blue = 0 },
        },
        bg = { visible = false },
        flags = { draggable = false },
        pos = { x = start_x, y = start_y - 40 },
    })
    header:visible(true)
    state.labels[#state.labels + 1] = { object = header }

    for index, element in ipairs(elements) do
        local label = element.label or element.key or ('Element ' .. index)
        local button = create_button(label, start_x, start_y + (index - 1) * (button_height + spacing), menu_width, button_height, function()
            select_element(element)
        end, {
            red = 50,
            green = 60,
            blue = 70,
            alpha = 220,
        })
        register_button('editor', button)
        state.element_buttons[#state.element_buttons + 1] = { button = button, element = element }
    end

    update_element_palette_highlight()
end

local function spawn_definition(definition)
    destroy_background()
    destroy_elements()
    destroy_highlight()
    state.definition = definition

    local screen_w, screen_h = get_screen_size()
    local background_size = definition.background and definition.background.size or { width = 600, height = 200 }
    state.base_position.x = math.floor((screen_w - (background_size.width or 0)) / 2)
    state.base_position.y = math.floor((screen_h - (background_size.height or 0)) / 2)

    if definition.background then
        state.background = images.new({
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
            size = { width = background_size.width or 0, height = background_size.height or 0 },
            texture = definition.background.texture and { path = windower.addon_path .. definition.background.texture } or nil,
            draggable = false,
        })
        state.background:pos(state.base_position.x, state.base_position.y)
        state.background:size(background_size.width or 0, background_size.height or 0)
        if definition.background.texture then
            state.background:path(windower.addon_path .. definition.background.texture)
        end
        state.background:show()
    end

    for _, entry in ipairs(definition.elements or {}) do
        local element
        if entry.type == 'text' then
            element = create_text_element(entry)
        else
            element = create_image_element(entry)
        end
        state.elements[#state.elements + 1] = element
    end

    build_element_palette()
    if not state.selected and state.element_buttons[1] then
        select_element(state.element_buttons[1].element)
    else
        update_element_palette_highlight()
    end

    if #state.elements == 0 then
        local message = texts.new('Target customization is coming soon.', {
            text = {
                font = 'Arial',
                size = 20,
                alpha = 255,
                red = 255,
                green = 210,
                blue = 120,
                stroke = { width = 2, alpha = 220, red = 0, green = 0, blue = 0 },
            },
            bg = { visible = false },
            flags = { draggable = false },
            pos = { x = state.base_position.x + 40, y = state.base_position.y + 40 },
        })
        message:visible(true)
        state.labels[#state.labels + 1] = { object = message }
    end

    ensure_cursor(true)
end

local function enter_editor(key)
    local resolved = definitions.resolve(state.addon_settings, key)
    if not resolved then
        return
    end

    clear_view()
    create_instruction('Select a UI element from the list on the right.\nUse the arrow keys to nudge positions and the left panel controls to adjust settings.')
    spawn_definition(resolved)

    local screen_w, screen_h = get_screen_size()
    local footer_y = screen_h - 90

    register_button('footer', create_button('Return to Main Menu', 60, footer_y, 240, 34, function()
        ezgui_creator.show_main_menu()
    end))

    register_button('footer', create_button('Refresh', 320, footer_y, 160, 34, function()
        enter_editor(key)
    end))

    register_button('footer', create_button('Apply Changes', 500, footer_y, 200, 34, function()
        definitions.apply(state.addon_settings, key, state.elements)
        config.save(state.addon_settings)
        windower.add_to_chat(207, '[EZHud] Saved ' .. resolved.label .. ' settings.')
    end))

    register_button('footer', create_button('Close', screen_w - 220, footer_y, 160, 34, function()
        ezgui_creator.close()
    end))

    rebuild_settings_panel()
end

function ezgui_creator.show_main_menu()
    clear_view()

    if not state.active then
        return
    end

    create_instruction('Select which UI element you would like to customize.')

    local screen_w, screen_h = get_screen_size()
    local center_x = math.floor(screen_w / 2)
    local button_width = 260
    local spacing = 24
    local total_width = button_width * 3 + spacing * 2
    local start_x = math.floor(center_x - total_width / 2)
    local start_y = math.floor(screen_h / 2) - 40

    register_button('main', create_button('Player Frame', start_x, start_y, button_width, 48, function()
        enter_editor('player')
    end))

    register_button('main', create_button('Party Member Frame', start_x + button_width + spacing, start_y, button_width, 48, function()
        enter_editor('member')
    end))

    register_button('main', create_button('Target Frame', start_x + (button_width + spacing) * 2, start_y, button_width, 48, function()
        enter_editor('target')
    end))

    register_button('footer', create_button('Close', screen_w - 180, screen_h - 100, 140, 36, function()
        ezgui_creator.close()
    end))

    ensure_cursor(true)
end

local function create_close_button()
    local screen_w = select(1, get_screen_size())
    local close_button = create_button('X', screen_w - 70, 30, 40, 40, function()
        ezgui_creator.close()
    end, {
        size = 20,
        text_red = 255,
        text_green = 180,
        text_blue = 180,
        red = 80,
        green = 20,
        blue = 20,
    })
    register_button('persistent', close_button)
end

local function destroy_persistent_buttons()
    clear_buttons('persistent')
end

local function hit_test_element(x, y)
    for index = #state.elements, 1, -1 do
        local element = state.elements[index]
        if element and element.object then
            if element.type == 'text' then
                if element.object:hover(x, y) then
                    return element
                end
            else
                local pos_x, pos_y = element.object:pos()
                local width, height = element.object:size()
                if x >= pos_x and x <= pos_x + width and y >= pos_y and y <= pos_y + height then
                    return element
                end
            end
        end
    end
    return nil
end

local function handle_mouse(type, x, y, _delta, _blocked)
    if not state.active then
        return
    end

    if state.cursor then
        local offset_x = (state.cursor_offset and state.cursor_offset.x) or 0
        local offset_y = (state.cursor_offset and state.cursor_offset.y) or 0
        local cursor_x = (x or 0) - offset_x
        local cursor_y = (y or 0) - offset_y
        if cursor_x < 0 then
            cursor_x = 0
        end
        if cursor_y < 0 then
            cursor_y = 0
        end
        state.cursor:pos(cursor_x, cursor_y)
        state.cursor_position = { x = cursor_x, y = cursor_y }
    end

    if type == 1 then
        for _, button in ipairs(all_buttons()) do
            if button.visible and button:contains(x, y) then
                state.mouse_down_button = button
                return true
            end
        end

        local element = hit_test_element(x, y)
        if element then
            select_element(element)
            return true
        end
    elseif type == 2 then
        if state.mouse_down_button and state.mouse_down_button:contains(x, y) then
            state.mouse_down_button:activate()
            state.mouse_down_button = nil
            return true
        end
        state.mouse_down_button = nil
    end

    return true
end

local function handle_keyboard(dik, pressed, _flags, _blocked)
    if not state.active then
        return
    end

    local key_name = KEY_RELEASE_COMMANDS[dik]
    if key_name then
        windower.send_command(('setkey %s up'):format(key_name))
    end

    if pressed and state.selected then
        local moved = false
        if dik == 203 then -- Left
            state.selected.offset.x = (state.selected.offset.x or 0) - 1
            moved = true
        elseif dik == 205 then -- Right
            state.selected.offset.x = (state.selected.offset.x or 0) + 1
            moved = true
        elseif dik == 200 then -- Up
            state.selected.offset.y = (state.selected.offset.y or 0) - 1
            moved = true
        elseif dik == 208 then -- Down
            state.selected.offset.y = (state.selected.offset.y or 0) + 1
            moved = true
        end

        if moved then
            if state.selected.type == 'text' then
                update_text_visual(state.selected)
            else
                update_image_visual(state.selected)
            end
            update_highlight()
        end
    end

    return true
end

local function register_events()
    if not state.events.mouse then
        state.events.mouse = windower.register_event('mouse', handle_mouse)
    end
    if not state.events.keyboard then
        state.events.keyboard = windower.register_event('keyboard', handle_keyboard)
    end
end

local function unregister_events()
    if state.events.mouse then
        windower.unregister_event(state.events.mouse)
        state.events.mouse = nil
    end
    if state.events.keyboard then
        windower.unregister_event(state.events.keyboard)
        state.events.keyboard = nil
    end
end

function ezgui_creator.init(addon_settings)
    state.addon_settings = addon_settings
end

function ezgui_creator.open()
    if state.active then
        ezgui_creator.show_main_menu()
        return
    end

    if not state.addon_settings then
        return
    end

    state.active = true
    ensure_overlay()
    ensure_cursor()
    register_events()
    create_close_button()
    ezgui_creator.show_main_menu()
end

function ezgui_creator.close()
    if not state.active then
        return
    end

    clear_view()
    destroy_overlay()
    destroy_cursor()
    destroy_persistent_buttons()
    unregister_events()
    state.active = false
    state.selected = nil
end

function ezgui_creator.toggle()
    if state.active then
        ezgui_creator.close()
    else
        ezgui_creator.open()
    end
end

return ezgui_creator
