--[[
        Copyright 2025, Rook & Makto (Bahamut)
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

            * Redistributions of source code must retain the above copyright
              notice, this list of conditions and the following disclaimer.
            * Redistributions in binary form must reproduce the above copyright
              notice, this list of conditions and the following disclaimer in the
              documentation and/or other materials provided with the distribution.
            * Neither the name of xivbar nor the
              names of its contributors may be used to endorse or promote products
              derived from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
        ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
        WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL ROOOK/MAKTO BE LIABLE FOR ANY
        DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
        (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
        LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
        ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
        SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local ezparty_bars = {}

-- Libs
local images = require('images')
local ez = require('core.ezfunctions')
local ezparty_text = require('modules.ezparty.core.ezparty_text')
local definitions = require('modules.ezgui_creator.core.definitions')
require('tables')
require('math')

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

local DEFAULT_MEMBER_COUNT = 5

local BAR_TEXTURES = {
    hp = 'gui/ezparty/HP_bar.png',
    mp = 'gui/ezparty/MP_bar.png',
    tp = 'gui/ezparty/TP_bar.png',
}

local BAR_KEYS = { 'hp', 'mp', 'tp' }
local ELEMENT_KEY_MAP = {
    hp_bar = 'hp',
    mp_bar = 'mp',
    tp_bar = 'tp',
}

local DEFAULT_BAR_CONFIG = {
    player = {
        hp = {
            offset = { x = 146, y = 94 },
            size = { width = 438, height = 30 },
            texture = BAR_TEXTURES.hp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
        mp = {
            offset = { x = 318, y = 94 },
            size = { width = 438, height = 30 },
            texture = BAR_TEXTURES.mp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
        tp = {
            offset = { x = 488, y = 94 },
            size = { width = 438, height = 30 },
            texture = BAR_TEXTURES.tp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
    },
    member = {
        hp = {
            offset = { x = 140, y = 94 },
            size = { width = 420, height = 28 },
            texture = BAR_TEXTURES.hp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
        mp = {
            offset = { x = 308, y = 94 },
            size = { width = 420, height = 28 },
            texture = BAR_TEXTURES.mp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
        tp = {
            offset = { x = 476, y = 94 },
            size = { width = 420, height = 28 },
            texture = BAR_TEXTURES.tp,
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
        },
    },
}

local TP_STAGE_CONFIGS = {
    [1] = {
        base_color = { red = 170, green = 225, blue = 255, alpha = 255 },
        pulse_color = { red = 220, green = 245, blue = 255, alpha = 255 },
        freq = 3.2,
        alpha = { min = 170, max = 255 },
    },
    [2] = {
        base_color = { red = 140, green = 255, blue = 140, alpha = 255 },
        pulse_color = { red = 200, green = 255, blue = 200, alpha = 255 },
        freq = 4.6,
        alpha = { min = 185, max = 255 },
    },
    [3] = {
        base_color = { red = 255, green = 205, blue = 80, alpha = 255 },
        pulse_color = { red = 255, green = 235, blue = 120, alpha = 255 },
        freq = 6.5,
        alpha = { min = 200, max = 255 },
    },
}

local bar_entries = {
    player = {},
    members = {},
}

local layout_state

local function extract_bar_config(definition)
    local config = {}
    if not definition then
        return config
    end

    for _, element in ipairs(definition.elements or {}) do
        local key = element and ELEMENT_KEY_MAP[element.key]
        if key then
            config[key] = {
                offset = deepcopy(element.offset or {}),
                size = deepcopy(element.size or {}),
                texture = element.texture or BAR_TEXTURES[key],
                color = deepcopy(element.color or {}),
            }
        end
    end

    return config
end

local function merge_bar_config(primary, fallback)
    primary = primary or {}
    fallback = fallback or {}

    for _, key in ipairs(BAR_KEYS) do
        local entry = primary[key] or {}
        local default_entry = fallback[key] or {}

        entry.offset = deepcopy(entry.offset or default_entry.offset or { x = 0, y = 0 })
        entry.size = deepcopy(entry.size or default_entry.size or { width = 0, height = 0 })
        entry.texture = entry.texture or default_entry.texture or BAR_TEXTURES[key]
        entry.color = deepcopy(entry.color or default_entry.color or { red = 255, green = 255, blue = 255, alpha = 255 })

        primary[key] = entry
    end

    return primary
end

local function resolve_bar_configs(addon_settings)
    local default_player = merge_bar_config(extract_bar_config(definitions.get_default('player')), DEFAULT_BAR_CONFIG.player)
    local default_member = merge_bar_config(extract_bar_config(definitions.get_default('member')), DEFAULT_BAR_CONFIG.member)

    local player_definition = definitions.resolve(addon_settings, 'player')
    local member_definition = definitions.resolve(addon_settings, 'member')

    local configs = {
        player = merge_bar_config(extract_bar_config(player_definition), default_player),
        member = merge_bar_config(extract_bar_config(member_definition), default_member),
    }

    return configs
end

local function clamp_color_value(value)
    return math.max(0, math.min(255, math.floor((tonumber(value) or 0) + 0.5)))
end

local function blend_color(from_color, to_color, t)
    return {
        red = clamp_color_value(ez.lerp(from_color.red or 0, to_color.red or 0, t)),
        green = clamp_color_value(ez.lerp(from_color.green or 0, to_color.green or 0, t)),
        blue = clamp_color_value(ez.lerp(from_color.blue or 0, to_color.blue or 0, t)),
        alpha = clamp_color_value(ez.lerp(from_color.alpha or 255, to_color.alpha or 255, t)),
    }
end

local function destroy_bar_entry(entry)
    if not entry then
        return
    end

    for _, resource in pairs(entry) do
        local image = resource and resource.image
        if image and image.destroy then
            image:destroy()
        end
    end
end

local function destroy_all_bars()
    for key, entry in pairs(bar_entries.player) do
        destroy_bar_entry(entry)
        bar_entries.player[key] = nil
    end

    for index, entry in pairs(bar_entries.members) do
        destroy_bar_entry(entry)
        bar_entries.members[index] = nil
    end
end

local function scale_value(value, scale)
    return math.floor((value or 0) * scale + 0.5)
end

local function instantiate_bar(base, scale, key, config)
    if not config then
        return nil
    end

    local offset = config.offset or { x = 0, y = 0 }
    local size = config.size or { width = 0, height = 0 }
    local color = config.color or { red = 255, green = 255, blue = 255, alpha = 255 }
    local texture = config.texture or BAR_TEXTURES[key]

    local pos_x = math.floor((base.x or 0) + scale_value(offset.x or 0, scale))
    local pos_y = math.floor((base.y or 0) + scale_value(offset.y or 0, scale))
    local width = math.max(0, scale_value(size.width or 0, scale))
    local height = math.max(0, scale_value(size.height or 0, scale))

    local texture_path = texture
    if texture_path and not texture_path:match('^[\\/]+') and not texture_path:match('^%a:[\\/]') then
        texture_path = windower.addon_path .. texture_path
    end

    local image = images.new({
        pos = { x = pos_x, y = pos_y },
        size = { width = width, height = height },
        visible = false,
        draggable = false,
        texture = texture_path and { path = texture_path, fit = false } or nil,
        color = {
            red = color.red or 255,
            green = color.green or 255,
            blue = color.blue or 255,
            alpha = color.alpha or 255,
        },
        repeatable = { x = 1, y = 1 },
        layer = 4,
    })

    if image and image.hide then
        image:hide()
    end

    return {
        image = image,
        max_size = { width = width, height = height },
        base_color = {
            red = color.red or 255,
            green = color.green or 255,
            blue = color.blue or 255,
            alpha = color.alpha or 255,
        },
    }
end

local function instantiate_bar_entry(base, scale, config)
    local entry = {}
    for _, key in ipairs(BAR_KEYS) do
        entry[key] = instantiate_bar(base, scale, key, config and config[key])
    end
    entry.position = base
    return entry
end

local function hide_bar_entry(entry)
    if not entry then
        return
    end

    for _, resource in pairs(entry) do
        local image = resource and resource.image
        if image and image.hide then
            image:hide()
        end
    end
end

local function apply_percent_bar(resource, percent)
    if not resource or not resource.image then
        return
    end

    local ratio = math.max(0, math.min(1, percent or 0))
    local width = math.floor((resource.max_size.width or 0) * ratio + 0.5)
    resource.image:size(width, resource.max_size.height or 0)
    resource.image:show()

    local base_color = resource.base_color or { red = 255, green = 255, blue = 255, alpha = 255 }
    resource.image:color(base_color.red or 255, base_color.green or 255, base_color.blue or 255)
    resource.image:alpha(base_color.alpha or 255)
end

local function apply_tp_visuals(resource, tp_value)
    if not resource or not resource.image then
        return
    end

    local image = resource.image
    local stage = 0
    if tp_value >= 3000 then
        stage = 3
    elseif tp_value >= 2000 then
        stage = 2
    elseif tp_value >= 1000 then
        stage = 1
    end

    if stage == 0 then
        local base_color = resource.base_color or { red = 255, green = 255, blue = 255, alpha = 255 }
        image:color(base_color.red or 255, base_color.green or 255, base_color.blue or 255)
        image:alpha(base_color.alpha or 255)
        return
    end

    local cfg = TP_STAGE_CONFIGS[stage]
    local pulse = (math.sin(os.clock() * cfg.freq) + 1) * 0.5
    local blended = blend_color(cfg.base_color, cfg.pulse_color or cfg.base_color, pulse)
    image:color(blended.red, blended.green, blended.blue)

    local alpha_cfg = cfg.alpha or { min = 200, max = 255 }
    local alpha = clamp_color_value(ez.lerp(alpha_cfg.min or 200, alpha_cfg.max or 255, pulse))
    image:alpha(alpha)
end

local function update_tp_bar(resource, tp_value)
    if not resource or not resource.image then
        return
    end

    local clamped = math.max(0, math.min(tp_value or 0, 1000))
    local ratio = clamped / 1000
    local width = math.floor((resource.max_size.width or 0) * ratio + 0.5)
    resource.image:size(width, resource.max_size.height or 0)
    resource.image:show()

    apply_tp_visuals(resource, tp_value or 0)
end

local function update_bar_set(entry, member)
    if not entry then
        return
    end

    if not member or not member.name then
        hide_bar_entry(entry)
        return
    end

    local hp_percent = math.max(0, math.min(100, tonumber(member.hpp) or 0))
    local mp_percent = math.max(0, math.min(100, tonumber(member.mpp) or 0))
    local tp_value = math.max(0, tonumber(member.tp) or 0)

    apply_percent_bar(entry.hp, hp_percent / 100)
    apply_percent_bar(entry.mp, mp_percent / 100)
    update_tp_bar(entry.tp, tp_value)
end

function ezparty_bars.create(addon_settings)
    destroy_all_bars()

    layout_state = ezparty_text.get_layout()
    if not layout_state and addon_settings then
        ezparty_text.create(addon_settings)
        layout_state = ezparty_text.get_layout()
    end

    if not layout_state then
        return nil
    end

    local scale = layout_state.scale or (addon_settings and addon_settings.ezparty and addon_settings.ezparty.scale) or 1
    local bar_configs = resolve_bar_configs(addon_settings)

    if layout_state.player then
        if layout_state.player.one then
            bar_entries.player.one = instantiate_bar_entry(layout_state.player.one, scale, bar_configs.player)
        end
        if layout_state.player.two then
            bar_entries.player.two = instantiate_bar_entry(layout_state.player.two, scale, bar_configs.player)
        end
    end

    if layout_state.members then
        for index, position in ipairs(layout_state.members) do
            bar_entries.members[index] = instantiate_bar_entry(position, scale, bar_configs.member)
        end
    end

    return {
        layout = layout_state,
        entries = bar_entries,
    }
end

function ezparty_bars.update()
    if not layout_state then
        return
    end

    local party = windower.ffxi.get_party()
    if not party then
        for _, entry in pairs(bar_entries.player) do
            hide_bar_entry(entry)
        end
        for _, entry in pairs(bar_entries.members) do
            hide_bar_entry(entry)
        end
        return
    end

    local player_data = party.p0 or party[0]
    if bar_entries.player.one then
        update_bar_set(bar_entries.player.one, player_data)
    end
    if bar_entries.player.two then
        update_bar_set(bar_entries.player.two, player_data)
    end

    for index = 1, DEFAULT_MEMBER_COUNT do
        local member_key = 'p' .. tostring(index)
        update_bar_set(bar_entries.members[index], party[member_key])
    end
end

function ezparty_bars.destroy()
    destroy_all_bars()
    layout_state = nil
end

return ezparty_bars
