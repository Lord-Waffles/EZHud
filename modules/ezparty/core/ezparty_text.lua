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

local ezparty_text = {}

-- Libs
local texts = require('texts')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

-- Constants / defaults
local DEFAULT_MEMBER_COUNT = 5
local TEXT_KEYS = {'name', 'hpp', 'hp_label', 'hp_value', 'mp_label', 'mp_value', 'tp_label', 'tp_value'}

local TEXT_PROFILES = {
    name = {
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

local function darker_color(color, factor)
    factor = factor or 0.6
    return {
        red = clamp_color_value((color.red or 0) * factor),
        green = clamp_color_value((color.green or 0) * factor),
        blue = clamp_color_value((color.blue or 0) * factor),
        alpha = clamp_color_value(color.alpha or 255),
    }
end

local function determine_health_color(percent, default_color)
    default_color = default_color or {}
    local alpha = clamp_color_value(default_color.alpha or 255)

    if percent > 50 then
        return {
            red = default_color.red or 255,
            green = default_color.green or 255,
            blue = default_color.blue or 255,
            alpha = alpha,
        }
    elseif percent > 25 then
        return { red = 255, green = 215, blue = 0, alpha = alpha }
    elseif percent > 0 then
        return { red = 255, green = 80, blue = 80, alpha = alpha }
    else
        return { red = 180, green = 40, blue = 40, alpha = alpha }
    end
end

local function apply_pulse_color(text_obj, base_color, target_color, speed)
    if not text_obj or not base_color or not target_color then
        return
    end

    local pulse = (math.sin(os.clock() * speed) + 1) * 0.5
    local blended = blend_color(base_color, target_color, pulse)
    text_obj:color(blended.red, blended.green, blended.blue)
    text_obj:alpha(blended.alpha)
end

local function apply_entry_color(entry, color)
    if not entry or not entry.text then
        return
    end

    local config = entry.config or {}
    local base_color = config.color or {}
    local stroke = config.stroke or {}

    entry.text:alpha(clamp_color_value(color.alpha or base_color.alpha or 255))
    entry.text:color(
        clamp_color_value(color.red or base_color.red or 255),
        clamp_color_value(color.green or base_color.green or 255),
        clamp_color_value(color.blue or base_color.blue or 255)
    )

    if entry.text.stroke_color then
        entry.text:stroke_color(
            clamp_color_value(stroke.red or 0),
            clamp_color_value(stroke.green or 0),
            clamp_color_value(stroke.blue or 0)
        )
    end

    if entry.text.stroke_alpha then
        entry.text:stroke_alpha(clamp_color_value(stroke.alpha or 255))
    end

    if entry.text.stroke_width then
        entry.text:stroke_width(math.max(0, stroke.width or 0))
    end
end

local function update_resource_colors(entry, member)
    if not entry or not member then
        return
    end

    local hp_percent = math.max(0, math.min(100, math.floor(tonumber(member.hpp) or 0)))
    local mp_percent = math.max(0, math.min(100, math.floor(tonumber(member.mpp) or 0)))

    local hpp_entry = entry.hpp
    if hpp_entry and hpp_entry.text then
        local hp_color = determine_health_color(hp_percent, (hpp_entry.config or {}).color)
        apply_entry_color(hpp_entry, hp_color)
        if hp_percent <= 20 then
            apply_pulse_color(hpp_entry.text, hp_color, darker_color(hp_color, 0.55), 3.0)
        end
    end

    local hp_value_entry = entry.hp_value
    if hp_value_entry and hp_value_entry.text then
        local hp_value_color = determine_health_color(hp_percent, (hp_value_entry.config or {}).color)
        apply_entry_color(hp_value_entry, hp_value_color)
        if hp_percent <= 20 then
            apply_pulse_color(hp_value_entry.text, hp_value_color, darker_color(hp_value_color, 0.55), 3.0)
        end
    end

    local mp_value_entry = entry.mp_value
    if mp_value_entry and mp_value_entry.text then
        local default_mp_color = mp_value_entry.config and mp_value_entry.config.color or { red = 255, green = 255, blue = 255, alpha = 255 }
        local mp_color = determine_health_color(mp_percent, default_mp_color)
        apply_entry_color(mp_value_entry, mp_color)
        if mp_percent <= 20 then
            apply_pulse_color(mp_value_entry.text, mp_color, darker_color(mp_color, 0.55), 3.2)
        end
    end
end

-- Runtime state
local text_entries = {
    player = {},
    members = {},
}
local layout_state

-- Utility helpers
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

local function merge_text_profile(default_profile, override)
    local profile = deepcopy(default_profile or {})

    if override then
        if override.offset then
            profile.offset = deepcopy(override.offset)
        end

        if override.font then
            profile.font = override.font
        end

        if override.size then
            profile.size = override.size
        end

        if override.color then
            profile.color = deepcopy(override.color)
        end

        if override.stroke then
            profile.stroke = deepcopy(override.stroke)
        end

        if override.bold ~= nil then
            profile.bold = override.bold
        end

        if override.italic ~= nil then
            profile.italic = override.italic
        end

        if override.right ~= nil then
            profile.right = override.right
        end

        if override.bottom ~= nil then
            profile.bottom = override.bottom
        end
    end

    return profile
end

local function build_profile_set(overrides)
    local set = {}
    for _, key in ipairs(TEXT_KEYS) do
        set[key] = merge_text_profile(TEXT_PROFILES[key], overrides and overrides[key])
    end
    return set
end

local function resolve_text_profiles(addon_settings)
    local profiles = (((addon_settings or {}).ezparty or {}).gui_profiles) or {}

    return {
        player = build_profile_set(profiles.player),
        member = build_profile_set(profiles.member),
    }
end

local function destroy_text_entry(entry)
    if not entry then
        return
    end

    for _, info in pairs(entry) do
        local text_obj = info and info.text
        if text_obj and text_obj.destroy then
            text_obj:destroy()
        end
    end
end

local function destroy_all_text_entries()
    for key, entry in pairs(text_entries.player) do
        destroy_text_entry(entry)
        text_entries.player[key] = nil
    end

    for index, entry in pairs(text_entries.members) do
        destroy_text_entry(entry)
        text_entries.members[index] = nil
    end
end

local function resolve_screen_dimensions()
    local settings = windower.get_windower_settings()
    return settings.ui_x_res, settings.ui_y_res
end

local function hide_entry(entry)
    if not entry then
        return
    end

    for key, info in pairs(entry) do
        if key ~= 'position' and type(info) == 'table' then
            local text_obj = info.text
            if text_obj and text_obj.hide then
                text_obj:hide()
            end
        end
    end
end

local function hide_all_visible_text()
    for _, entry in pairs(text_entries.player) do
        hide_entry(entry)
    end

    for _, entry in pairs(text_entries.members) do
        hide_entry(entry)
    end
end

local function format_numeric(value)
    local number = tonumber(value)
    if not number then
        return nil
    end

    number = math.floor(number + 0.5)
    local sign = number < 0 and '-' or ''
    local digits = tostring(math.abs(number))

    local formatted = digits:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    if formatted:sub(1, 1) == ',' then
        formatted = formatted:sub(2)
    end

    return sign .. formatted
end

local function apply_text(entry, key, value)
    if not entry or key == 'position' then
        return
    end

    local slot = entry[key]
    if not slot or not slot.text then
        return
    end

    if value and value ~= '' then
        local display_value = value
        if type(display_value) ~= 'string' then
            display_value = tostring(display_value)
        end

        slot.text:text(display_value)
        if slot.text.show then
            slot.text:show()
        else
            slot.text:visible(true)
        end
    else
        if slot.text.hide then
            slot.text:hide()
        else
            slot.text:visible(false)
        end
    end
end

local function format_percent(value)
    local number = tonumber(value)
    if not number then
        return nil
    end
    return string.format('%d%%', math.max(0, math.floor(number + 0.5)))
end

local function update_text_entry(entry, member)
    if not entry then
        return
    end

    if not member or not member.name then
        hide_entry(entry)
        return
    end

    apply_text(entry, 'name', member.name or '')
    apply_text(entry, 'hpp', format_percent(member.hpp) or '')
    apply_text(entry, 'hp_label', 'HP')
    apply_text(entry, 'hp_value', format_numeric(member.hp) or tostring(member.hp or ''))
    apply_text(entry, 'mp_label', 'MP')
    apply_text(entry, 'mp_value', format_numeric(member.mp) or tostring(member.mp or ''))
    apply_text(entry, 'tp_label', 'TP')
    apply_text(entry, 'tp_value', format_numeric(member.tp) or tostring(member.tp or ''))

    update_resource_colors(entry, member)
end

local function compute_member_positions(addon_settings, scale)
    local screen_w, screen_h = resolve_screen_dimensions()
    local spacing = math.floor(((addon_settings.ezparty.layout and addon_settings.ezparty.layout.vertical_spacing) or 50) * scale + 0.5)
    local member_size = addon_settings.ezparty.member_frame and addon_settings.ezparty.member_frame.size or {}
    local width = math.floor((member_size.width or 0) * scale + 0.5)
    local height = math.floor((member_size.height or 0) * scale + 0.5)

    local member_pos_config = deepcopy(addon_settings.ezparty.member_frame and addon_settings.ezparty.member_frame.pos or {})
    local base
    if not member_pos_config or ((member_pos_config.x or 0) == 0 and (member_pos_config.y or 0) == 0) then
        base = {
            x = screen_w - width,
            y = screen_h - height - (height + spacing) * (DEFAULT_MEMBER_COUNT - 1),
        }
    else
        base = ez.convert_to_screen_pixels(member_pos_config) or { x = 0, y = 0 }
    end

    local positions = {}
    for index = 1, DEFAULT_MEMBER_COUNT do
        positions[index] = {
            x = base.x,
            y = base.y + (height + spacing) * (index - 1),
            width = width,
            height = height,
        }
    end

    return positions, spacing
end

local function compute_player_positions(addon_settings, scale, member_positions, spacing)
    local screen_w, screen_h = resolve_screen_dimensions()
    local player_frame = addon_settings.ezparty.player_frame or {}

    local positions = {
        one = nil,
        two = nil,
    }

    local one_config = deepcopy(player_frame.one and player_frame.one.pos or {})
    local one_size = player_frame.one and player_frame.one.size or {}
    local one_width = math.floor((one_size.width or 0) * scale + 0.5)
    local one_height = math.floor((one_size.height or 0) * scale + 0.5)

    if player_frame.one and player_frame.one.enable ~= false then
        if not one_config or ((one_config.x or 0) == 0 and (one_config.y or 0) == 0) then
            local anchor_y
            if member_positions and member_positions[1] then
                anchor_y = member_positions[1].y - spacing - one_height
            else
                anchor_y = screen_h - one_height - spacing * DEFAULT_MEMBER_COUNT
            end
            positions.one = {
                x = screen_w - one_width,
                y = anchor_y,
                width = one_width,
                height = one_height,
            }
        else
            local pixel_pos = ez.convert_to_screen_pixels(one_config) or { x = 0, y = 0 }
            positions.one = {
                x = pixel_pos.x or 0,
                y = pixel_pos.y or 0,
                width = one_width,
                height = one_height,
            }
        end
    end

    local two_config = deepcopy(player_frame.two and player_frame.two.pos or {})
    local two_size = player_frame.two and player_frame.two.size or {}
    local two_width = math.floor((two_size.width or 0) * scale + 0.5)
    local two_height = math.floor((two_size.height or 0) * scale + 0.5)

    if player_frame.two and player_frame.two.enable ~= false then
        if not two_config or ((two_config.x or 0) == 0 and (two_config.y or 0) == 0) then
            positions.two = {
                x = math.floor(screen_w / 2 - two_width / 2),
                y = math.floor(screen_h - (screen_h / 4.3)),
                width = two_width,
                height = two_height,
            }
        else
            local pixel_pos = ez.convert_to_screen_pixels(two_config) or { x = 0, y = 0 }
            positions.two = {
                x = pixel_pos.x or 0,
                y = pixel_pos.y or 0,
                width = two_width,
                height = two_height,
            }
        end
    end

    return positions
end

local function compute_layout(addon_settings)
    if not addon_settings or not addon_settings.ezparty then
        return nil
    end

    local scale = tonumber(addon_settings.ezparty.scale) or 1
    local member_positions, spacing = compute_member_positions(addon_settings, scale)
    local player_positions = compute_player_positions(addon_settings, scale, member_positions, spacing)

    return {
        scale = scale,
        spacing = spacing,
        members = member_positions,
        player = player_positions,
    }
end

local function scale_value(value, scale)
    return math.floor((value or 0) * scale + 0.5)
end

local function create_text_settings(base, config, scale)
    local offset = config.offset or { x = 0, y = 0 }
    local pos_x = math.floor((base.x or 0) + scale_value(offset.x or 0, scale))
    local pos_y = math.floor((base.y or 0) + scale_value(offset.y or 0, scale))

    local color = config.color or {}
    local stroke = config.stroke or {}

    local settings = {
        pos = { x = pos_x, y = pos_y },
        bg = {
            visible = false,
            alpha = 0,
            red = 0,
            green = 0,
            blue = 0,
        },
        flags = {
            bold = config.bold and true or false,
            italic = config.italic and true or false,
            right = config.right and true or false,
            bottom = config.bottom and true or false,
            draggable = false,
        },
        padding = 0,
        text = {
            font = config.font or 'Arial',
            size = math.max(1, scale_value(config.size or 12, scale)),
            alpha = color.alpha or 255,
            red = color.red or 255,
            green = color.green or 255,
            blue = color.blue or 255,
            stroke = {
                width = math.max(0, scale_value(stroke.width or 0, scale)),
                alpha = stroke.alpha or 255,
                red = stroke.red or 0,
                green = stroke.green or 0,
                blue = stroke.blue or 0,
            },
        },
    }

    return settings
end

local function instantiate_text_entry(base, scale, profile_set)
    local entry = {}

    for _, key in ipairs(TEXT_KEYS) do
        local profile = (profile_set and profile_set[key]) or TEXT_PROFILES[key]
        if profile then
            local settings = create_text_settings(base, profile, scale)
            local text_obj = texts.new('', settings)

            if profile.size then
                text_obj:size(settings.text.size)
            end

            text_obj:visible(false)
            entry[key] = {
                text = text_obj,
                config = deepcopy(profile),
            }
        end
    end

    entry.position = deepcopy(base)
    return entry
end

function ezparty_text.create(addon_settings)
    destroy_all_text_entries()

    layout_state = compute_layout(addon_settings)
    if not layout_state then
        return nil
    end

    local profile_sets = resolve_text_profiles(addon_settings)

    if layout_state.player and layout_state.player.one then
        text_entries.player.one = instantiate_text_entry(layout_state.player.one, layout_state.scale, profile_sets.player)
    end

    if layout_state.player and layout_state.player.two then
        text_entries.player.two = instantiate_text_entry(layout_state.player.two, layout_state.scale, profile_sets.player)
    end

    if layout_state.members then
        for index, position in ipairs(layout_state.members) do
            text_entries.members[index] = instantiate_text_entry(position, layout_state.scale, profile_sets.member)
        end
    end

    return {
        layout = deepcopy(layout_state),
        player = text_entries.player,
        members = text_entries.members,
    }
end

function ezparty_text.get_layout()
    return layout_state and deepcopy(layout_state) or nil
end

function ezparty_text.get_text_entries()
    return text_entries
end

function ezparty_text.update()
    if not layout_state then
        return
    end

    local party = windower.ffxi.get_party()
    if not party then
        hide_all_visible_text()
        return
    end

    local player_data = party.p0 or party[0]
    if text_entries.player.one then
        update_text_entry(text_entries.player.one, player_data)
    end

    if text_entries.player.two then
        update_text_entry(text_entries.player.two, player_data)
    end

    for index = 1, DEFAULT_MEMBER_COUNT do
        local member_key = 'p' .. tostring(index)
        update_text_entry(text_entries.members[index], party[member_key])
    end
end

return ezparty_text
