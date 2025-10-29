local definitions = {}

local DEFAULT_FONTS = {
    'Arial',
    'Calibri',
    'Cambria',
    'Consolas',
    'Courier New',
    'Futura',
    'Georgia',
    'Gill Sans',
    'Helvetica',
    'Optima',
    'Segoe UI',
    'Times New Roman',
    'Trebuchet MS',
    'Verdana',
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

local DEFAULT_TEXT_ELEMENTS = {
    name = {
        key = 'name',
        type = 'text',
        label = 'Name',
        sample = 'Player Name',
        offset = { x = 150, y = 26 },
        font = 'Arial',
        size = 20,
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        stroke = { width = 2, alpha = 220, red = 0, green = 0, blue = 0 },
        bold = true,
        italic = false,
        right = false,
        bottom = false,
    },
    hpp = {
        key = 'hpp',
        type = 'text',
        label = 'HP %',
        sample = '100%',
        offset = { x = 360, y = 26 },
        font = 'Arial',
        size = 20,
        color = { red = 230, green = 215, blue = 0, alpha = 255 },
        stroke = { width = 2, alpha = 220, red = 0, green = 0, blue = 0 },
        bold = true,
        italic = false,
        right = false,
        bottom = false,
    },
    hp_label = {
        key = 'hp_label',
        type = 'text',
        label = 'HP Label',
        sample = 'HP',
        offset = { x = 150, y = 68 },
        font = 'Arial',
        size = 14,
        color = { red = 255, green = 255, blue = 255, alpha = 220 },
        stroke = { width = 1, alpha = 180, red = 0, green = 0, blue = 0 },
        bold = false,
        italic = true,
        right = false,
        bottom = false,
    },
    hp_value = {
        key = 'hp_value',
        type = 'text',
        label = 'HP Value',
        sample = '3200',
        offset = { x = 222, y = 68 },
        font = 'Arial',
        size = 16,
        color = { red = 255, green = 215, blue = 0, alpha = 255 },
        stroke = { width = 1, alpha = 200, red = 0, green = 0, blue = 0 },
        bold = true,
        italic = false,
        right = false,
        bottom = false,
    },
    mp_label = {
        key = 'mp_label',
        type = 'text',
        label = 'MP Label',
        sample = 'MP',
        offset = { x = 320, y = 68 },
        font = 'Arial',
        size = 14,
        color = { red = 255, green = 255, blue = 255, alpha = 220 },
        stroke = { width = 1, alpha = 180, red = 0, green = 0, blue = 0 },
        bold = false,
        italic = true,
        right = false,
        bottom = false,
    },
    mp_value = {
        key = 'mp_value',
        type = 'text',
        label = 'MP Value',
        sample = '1580',
        offset = { x = 392, y = 68 },
        font = 'Arial',
        size = 16,
        color = { red = 200, green = 220, blue = 255, alpha = 255 },
        stroke = { width = 1, alpha = 200, red = 0, green = 0, blue = 0 },
        bold = true,
        italic = false,
        right = false,
        bottom = false,
    },
    tp_label = {
        key = 'tp_label',
        type = 'text',
        label = 'TP Label',
        sample = 'TP',
        offset = { x = 490, y = 68 },
        font = 'Arial',
        size = 14,
        color = { red = 255, green = 255, blue = 255, alpha = 220 },
        stroke = { width = 1, alpha = 180, red = 0, green = 0, blue = 0 },
        bold = false,
        italic = true,
        right = false,
        bottom = false,
    },
    tp_value = {
        key = 'tp_value',
        type = 'text',
        label = 'TP Value',
        sample = '1000',
        offset = { x = 560, y = 68 },
        font = 'Arial',
        size = 16,
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        stroke = { width = 1, alpha = 200, red = 0, green = 0, blue = 0 },
        bold = true,
        italic = false,
        right = false,
        bottom = false,
    },
}

local function build_player_elements()
    local elements = {}
    for _, key in ipairs({
        'name', 'hpp', 'hp_label', 'hp_value',
        'mp_label', 'mp_value', 'tp_label', 'tp_value',
    }) do
        elements[#elements + 1] = deepcopy(DEFAULT_TEXT_ELEMENTS[key])
    end

    elements[#elements + 1] = {
        key = 'hp_bar',
        type = 'image',
        label = 'HP Bar',
        texture = 'gui/ezparty/HP_bar.png',
        offset = { x = 146, y = 94 },
        size = { width = 438, height = 30 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    elements[#elements + 1] = {
        key = 'mp_bar',
        type = 'image',
        label = 'MP Bar',
        texture = 'gui/ezparty/MP_bar.png',
        offset = { x = 318, y = 94 },
        size = { width = 438, height = 30 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    elements[#elements + 1] = {
        key = 'tp_bar',
        type = 'image',
        label = 'TP Bar',
        texture = 'gui/ezparty/TP_bar.png',
        offset = { x = 488, y = 94 },
        size = { width = 438, height = 30 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    return elements
end

local function build_member_elements()
    local elements = {}
    for _, key in ipairs({
        'name', 'hpp', 'hp_label', 'hp_value',
        'mp_label', 'mp_value', 'tp_label', 'tp_value',
    }) do
        local entry = deepcopy(DEFAULT_TEXT_ELEMENTS[key])
        if key == 'name' then
            entry.sample = 'Party Member'
        end
        elements[#elements + 1] = entry
    end

    elements[#elements + 1] = {
        key = 'hp_bar',
        type = 'image',
        label = 'HP Bar',
        texture = 'gui/ezparty/HP_bar.png',
        offset = { x = 140, y = 94 },
        size = { width = 420, height = 28 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    elements[#elements + 1] = {
        key = 'mp_bar',
        type = 'image',
        label = 'MP Bar',
        texture = 'gui/ezparty/MP_bar.png',
        offset = { x = 308, y = 94 },
        size = { width = 420, height = 28 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    elements[#elements + 1] = {
        key = 'tp_bar',
        type = 'image',
        label = 'TP Bar',
        texture = 'gui/ezparty/TP_bar.png',
        offset = { x = 476, y = 94 },
        size = { width = 420, height = 28 },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
    }

    return elements
end

local DEFAULT_DEFINITIONS = {
    player = {
        key = 'player',
        label = 'Player Frame',
        background = {
            texture = 'gui/ezparty/player_frame.png',
            size = { width = 730, height = 150 },
        },
        elements = build_player_elements(),
    },
    member = {
        key = 'member',
        label = 'Party Member Frame',
        background = {
            texture = 'gui/ezparty/member_frame.png',
            size = { width = 631, height = 131 },
        },
        elements = build_member_elements(),
    },
    target = {
        key = 'target',
        label = 'Target Frame',
        background = {
            texture = 'gui/ezparty/target_frame.png',
            size = { width = 1649, height = 339 },
        },
        elements = {},
    },
}

local function merge_color(target, source)
    target = target or {}
    source = source or {}

    target.red = source.red or target.red or 255
    target.green = source.green or target.green or 255
    target.blue = source.blue or target.blue or 255
    target.alpha = source.alpha or target.alpha or 255
    return target
end

local function merge_stroke(target, source)
    target = target or {}
    source = source or {}

    target.width = source.width or target.width or 0
    target.alpha = source.alpha or target.alpha or 255
    target.red = source.red or target.red or 0
    target.green = source.green or target.green or 0
    target.blue = source.blue or target.blue or 0
    return target
end

local function merge_offset(target, source)
    target = target or {}
    source = source or {}

    target.x = source.x or target.x or 0
    target.y = source.y or target.y or 0
    return target
end

local function merge_size(target, source)
    target = target or {}
    source = source or {}

    target.width = source.width or target.width or 0
    target.height = source.height or target.height or 0
    return target
end

local function merge_text_element(element, saved)
    if not saved then
        return element
    end

    element.offset = merge_offset(deepcopy(element.offset), saved.offset)
    element.font = saved.font or element.font
    element.size = saved.size or element.size
    element.color = merge_color(deepcopy(element.color), saved.color)
    element.stroke = merge_stroke(deepcopy(element.stroke), saved.stroke)
    element.bold = saved.bold
    element.italic = saved.italic
    element.right = saved.right
    element.bottom = saved.bottom
    return element
end

local function merge_image_element(element, saved)
    if not saved then
        return element
    end

    element.offset = merge_offset(deepcopy(element.offset), saved.offset)
    element.size = merge_size(deepcopy(element.size), saved.size)
    element.texture = saved.texture or element.texture
    element.color = merge_color(deepcopy(element.color), saved.color)
    return element
end

local function merge_element(element, saved)
    if element.type == 'text' then
        return merge_text_element(element, saved)
    elseif element.type == 'image' or element.type == 'bar' then
        return merge_image_element(element, saved)
    end
    return element
end

function definitions.available_fonts()
    return deepcopy(DEFAULT_FONTS)
end

function definitions.get_default(key)
    local base = DEFAULT_DEFINITIONS[key]
    if not base then
        return nil
    end
    return deepcopy(base)
end

function definitions.resolve(addon_settings, key)
    local base = definitions.get_default(key)
    if not base then
        return nil
    end

    local saved_profiles = (((addon_settings or {}).ezparty or {}).gui_profiles or {})[key] or {}

    for _, element in ipairs(base.elements) do
        local saved = saved_profiles[element.key]
        if saved then
            merge_element(element, saved)
        end
    end

    return base
end

local function serialise_text(element)
    return {
        type = 'text',
        offset = deepcopy(element.offset or { x = 0, y = 0 }),
        font = element.font,
        size = element.size,
        color = deepcopy(element.color or {}),
        stroke = deepcopy(element.stroke or {}),
        bold = element.bold,
        italic = element.italic,
        right = element.right,
        bottom = element.bottom,
    }
end

local function serialise_image(element)
    return {
        type = 'image',
        offset = deepcopy(element.offset or { x = 0, y = 0 }),
        size = deepcopy(element.size or { width = 0, height = 0 }),
        texture = element.texture,
        color = deepcopy(element.color or {}),
    }
end

local function serialise_element(element)
    if element.type == 'text' then
        return serialise_text(element)
    elseif element.type == 'image' or element.type == 'bar' then
        return serialise_image(element)
    end
    return deepcopy(element)
end

function definitions.apply(addon_settings, key, elements)
    if not addon_settings then
        return
    end

    addon_settings.ezparty = addon_settings.ezparty or {}
    addon_settings.ezparty.gui_profiles = addon_settings.ezparty.gui_profiles or {}

    local profile = {}
    for _, element in ipairs(elements or {}) do
        profile[element.key] = serialise_element(element)
    end

    addon_settings.ezparty.gui_profiles[key] = profile
end

return definitions
