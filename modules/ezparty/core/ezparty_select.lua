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

local ezparty_select = {}

-- Libs
local images = require('images')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

-- Internal state
local pointer_image
local pointer_dimensions = { width = 0, height = 0 }
local frame_positions = {}
local pointer_visible = false
local update_event_id
local logout_event_id

local DEFAULT_MEMBER_COUNT = 5
local POINTER_TEXTURE = 'gui/hand_pointer/name_point_right.png'

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

local function resolve_screen_dimensions()
    local settings = windower.get_windower_settings()
    return settings.ui_x_res, settings.ui_y_res
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

    local positions = {}

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
            positions[0] = {
                x = screen_w - one_width,
                y = anchor_y,
                width = one_width,
                height = one_height,
            }
        else
            local pixel_pos = ez.convert_to_screen_pixels(one_config) or { x = 0, y = 0 }
            positions[0] = {
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
            positions.player_two = {
                x = math.floor(screen_w / 2 - two_width / 2),
                y = math.floor(screen_h - (screen_h / 4.3)),
                width = two_width,
                height = two_height,
            }
        else
            local pixel_pos = ez.convert_to_screen_pixels(two_config) or { x = 0, y = 0 }
            positions.player_two = {
                x = pixel_pos.x or 0,
                y = pixel_pos.y or 0,
                width = two_width,
                height = two_height,
            }
        end
    end

    return positions
end

local function compute_frame_positions(addon_settings)
    if not addon_settings or not addon_settings.ezparty then
        return {}
    end

    local scale = tonumber(addon_settings.ezparty.scale) or 1
    local members, spacing = compute_member_positions(addon_settings, scale)
    local players = compute_player_positions(addon_settings, scale, members, spacing)

    local positions = {}
    for index, info in ipairs(members) do
        positions[index] = info
    end

    for key, value in pairs(players) do
        positions[key] = value
    end

    positions.scale = scale
    return positions
end

local function ensure_pointer(scale)
    local pointer_size = math.max(48, math.floor(96 * (scale or 1) + 0.5))
    pointer_dimensions.width = pointer_size
    pointer_dimensions.height = pointer_size

    if pointer_image and pointer_image.destroy then
        pointer_image:destroy()
        pointer_image = nil
    end

    pointer_image = images.new({
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        size = { width = pointer_dimensions.width, height = pointer_dimensions.height },
        texture = { path = POINTER_TEXTURE },
        visible = false,
        draggable = false,
    })

    pointer_image:size(pointer_dimensions.width, pointer_dimensions.height)
    pointer_image:path(windower.addon_path .. POINTER_TEXTURE)
    pointer_image:hide()
    pointer_visible = false
end

local function set_pointer_visibility(visible)
    if not pointer_image then
        return
    end

    if visible and not pointer_visible then
        pointer_image:show()
        pointer_visible = true
    elseif not visible and pointer_visible then
        pointer_image:hide()
        pointer_visible = false
    end
end

local function resolve_target_slot()
    local target = windower.ffxi.get_mob_by_target('t')
    if not target then
        return nil
    end

    local target_id = target.id
    if not target_id then
        return nil
    end

    local player = windower.ffxi.get_player()
    if player and player.id == target_id then
        return 0
    end

    local party = windower.ffxi.get_party()
    if not party then
        return nil
    end

    for index = 0, DEFAULT_MEMBER_COUNT do
        local key = 'p' .. tostring(index)
        local member = party[key]
        if member then
            local member_id = (member.mob and member.mob.id) or member.id
            if member_id == target_id then
                return index
            end
        end
    end

    return nil
end

local function update_pointer_position()
    if not pointer_image then
        return
    end

    local slot_index = resolve_target_slot()
    if not slot_index then
        set_pointer_visibility(false)
        return
    end

    local frame = frame_positions[slot_index]
    if not frame then
        set_pointer_visibility(false)
        return
    end

    local offset_x = math.floor(pointer_dimensions.width * 0.75)
    local offset_y = math.floor(pointer_dimensions.height * 0.1)

    local pos_x = math.floor((frame.x or 0) - offset_x)
    local pos_y = math.floor((frame.y or 0) + ((frame.height or 0) / 2) - (pointer_dimensions.height / 2) - offset_y)

    pointer_image:pos(pos_x, pos_y)
    set_pointer_visibility(true)
end

local function unregister_events()
    if update_event_id then
        windower.unregister_event(update_event_id)
        update_event_id = nil
    end

    if logout_event_id then
        windower.unregister_event(logout_event_id)
        logout_event_id = nil
    end
end

function ezparty_select.create(addon_settings)
    unregister_events()

    if not addon_settings or not addon_settings.ezparty or addon_settings.ezparty.enable == false then
        if pointer_image then
            pointer_image:hide()
        end
        return
    end

    frame_positions = compute_frame_positions(addon_settings)
    ensure_pointer(frame_positions.scale or 1)

    update_event_id = windower.register_event('prerender', function()
        update_pointer_position()
    end)

    logout_event_id = windower.register_event('logout', function()
        set_pointer_visibility(false)
    end)

    update_pointer_position()
end

return ezparty_select