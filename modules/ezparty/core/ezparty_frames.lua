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

local ezparty_frames = {}

-- Libs
local images = require('images')
local config = require('config')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

local DEFAULT_MEMBER_COUNT = 5
local COORD_OVERFLOW_FACTOR = 100

-- Variables
local player_frame = {}
local member_frames = {}
local frames_visible = false
local ui_width = windower.get_windower_settings().ui_x_res
local ui_height = windower.get_windower_settings().ui_y_res

local function refresh_ui_dimensions()
    local settings = windower.get_windower_settings() or {}
    ui_width = settings.ui_x_res or ui_width or 0
    ui_height = settings.ui_y_res or ui_height or 0
end

local function apply_image_visibility(image, visible)
    if not image then
        return
    end

    if visible then
        if image.show then
            image:show()
        end
    else
        if image.hide then
            image:hide()
        end
    end
end

-- EZ Party Module
local ezparty = {}
ezparty.player_frame = {}
ezparty.member_frames = {}

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

local function resolve_spacing(addon_settings, scale)
    local base_spacing = 50
    if addon_settings.ezparty and addon_settings.ezparty.layout then
        base_spacing = tonumber(addon_settings.ezparty.layout.vertical_spacing) or base_spacing
    end
    return math.floor((base_spacing * scale) + 0.5)
end

local function resolve_pixel_position(pos)
    if type(pos) ~= 'table' then
        return 0, 0
    end

    local x = tonumber(pos.x) or 0
    local y = tonumber(pos.y) or 0

    local function needs_percent_conversion(value)
        if value == 0 then
            return false
        end
        return math.abs(value) <= 1
    end

    local screen_w = ui_width or 0
    local screen_h = ui_height or 0

    if screen_w > 0 and math.abs(x) > (screen_w * COORD_OVERFLOW_FACTOR) then
        while math.abs(x) > screen_w do
            x = x / screen_w
        end
    end

    if screen_h > 0 and math.abs(y) > (screen_h * COORD_OVERFLOW_FACTOR) then
        while math.abs(y) > screen_h do
            y = y / screen_h
        end
    end

    if screen_w > 0 and needs_percent_conversion(x) then
        x = x * screen_w
    end

    if screen_h > 0 and needs_percent_conversion(y) then
        y = y * screen_h
    end

    return x, y
end

local function resolve_member_base(addon_settings, width, height, spacing)
    local stack_height = 0
    if height > 0 then
        stack_height = height
    end
    if height > 0 or spacing > 0 then
        stack_height = height + math.max(0, (height + spacing) * (DEFAULT_MEMBER_COUNT - 1))
    end

    local max_x = math.max(0, ui_width - width)
    local max_y = math.max(0, ui_height - stack_height)

    local config_pos = (addon_settings.ezparty.member_frame and addon_settings.ezparty.member_frame.pos) or {}
    if (config_pos.x or 0) == 0 and (config_pos.y or 0) == 0 then
        return {
            x = max_x,
            y = max_y,
            from_settings = false,
        }
    end

    local raw_x = tonumber(config_pos.x) or 0
    local raw_y = tonumber(config_pos.y) or 0
    local pos_x, pos_y = resolve_pixel_position(config_pos)

    local overflow_x = ui_width > 0 and math.abs(raw_x) > (ui_width * COORD_OVERFLOW_FACTOR)
    local overflow_y = ui_height > 0 and math.abs(raw_y) > (ui_height * COORD_OVERFLOW_FACTOR)
    local clamped_x = math.min(math.max(pos_x, 0), max_x)
    local clamped_y = math.min(math.max(pos_y, 0), max_y)
    local was_clamped = (clamped_x ~= pos_x) or (clamped_y ~= pos_y)

    if (overflow_x or overflow_y or was_clamped) and addon_settings.ezparty and addon_settings.ezparty.member_frame then
        addon_settings.ezparty.member_frame.pos = ez.convert_to_screen_percent({ x = clamped_x, y = clamped_y })
        config.save(addon_settings)
    end

    return {
        x = math.floor(clamped_x or 0),
        y = math.floor(clamped_y or 0),
        from_settings = true,
    }
end

local function sanitize_image_config(source)
    local config = deepcopy(source or {})
    local pos = config.pos or {}
    config.pos = {
        x = tonumber(pos.x) or 0,
        y = tonumber(pos.y) or 0,
    }
    return config
end

function ezparty_frames.create(addon_settings)
    refresh_ui_dimensions()

    local scale = tonumber(addon_settings.ezparty.scale) or 1

    local spacing = resolve_spacing(addon_settings, scale)
    addon_settings.savedUI = addon_settings.savedUI or {}

    local player_one_config = sanitize_image_config(addon_settings.ezparty.player_frame.one)
    local player_two_config = sanitize_image_config(addon_settings.ezparty.player_frame.two)
    local member_config = sanitize_image_config(addon_settings.ezparty.member_frame)

    -- Set up player frame settings
    local player_one_width = math.floor(((player_one_config.size and player_one_config.size.width) or 0) * scale + 0.5)
    local player_one_height = math.floor(((player_one_config.size and player_one_config.size.height) or 0) * scale + 0.5)
    local player_two_width = math.floor(((player_two_config.size and player_two_config.size.width) or (player_one_config.size and player_one_config.size.width) or 0) * scale + 0.5)
    local player_two_height = math.floor(((player_two_config.size and player_two_config.size.height) or (player_one_config.size and player_one_config.size.height) or 0) * scale + 0.5)

    -- Set up member frame settings
    local member_frame_width = math.floor(((member_config.size and member_config.size.width) or 0) * scale + 0.5)
    local member_frame_height = math.floor(((member_config.size and member_config.size.height) or 0) * scale + 0.5)

    local member_base = resolve_member_base(addon_settings, member_frame_width, member_frame_height, spacing)
    local member_texture = (addon_settings.ezparty.member_frame.texture and addon_settings.ezparty.member_frame.texture.path) or 'gui/ezparty/member_frame.png'

    for i = 0, DEFAULT_MEMBER_COUNT do
        if i == 0 then
            ---------------------------------Player Frame 1------------------------------------
            if player_one_config.enable ~= false then
                player_frame[1] = images.new(deepcopy(player_one_config))
                player_frame[1]:size(player_one_width, player_one_height)

                local one_pos = player_one_config.pos or {}
                if (one_pos.x or 0) == 0 and (one_pos.y or 0) == 0 then
                    local default_x = ui_width - player_one_width
                    local default_y = member_base.y - spacing - player_one_height
                    player_frame[1]:pos(default_x, default_y)
                    addon_settings.ezparty.player_frame.one.pos = ez.convert_to_screen_percent({ x = default_x, y = default_y })
                    config.save(addon_settings)
                else
                    local pos_x, pos_y = resolve_pixel_position(one_pos)
                    player_frame[1]:pos(pos_x, pos_y)
                end

                if addon_settings.ezparty.player_frame.unique ~= true then
                    player_frame[1]:path(windower.addon_path .. member_texture)
                else
                    local texture_path = player_one_config.texture and player_one_config.texture.path
                    if texture_path then
                        player_frame[1]:path(windower.addon_path .. texture_path)
                    end
                end
            end

            ---------------------------------Player Frame 2------------------------------------
            if player_two_config.enable ~= false then
                player_frame[2] = images.new(deepcopy(player_two_config))
                player_frame[2]:size(player_two_width, player_two_height)

                local two_pos = player_two_config.pos or {}
                if (two_pos.x or 0) == 0 and (two_pos.y or 0) == 0 then
                    local default_x = math.floor(ui_width / 2 - player_two_width / 2)
                    local default_y = math.floor(ui_height - (ui_height / 4.3))
                    player_frame[2]:pos(default_x, default_y)
                    addon_settings.ezparty.player_frame.two.pos = ez.convert_to_screen_percent({ x = default_x, y = default_y })
                else
                    local pos_x, pos_y = resolve_pixel_position(two_pos)
                    player_frame[2]:pos(pos_x, pos_y)
                end

                if addon_settings.ezparty.player_frame.unique ~= true then
                    player_frame[2]:path(windower.addon_path .. member_texture)
                else
                    local texture_path = player_two_config.texture and player_two_config.texture.path
                    if texture_path then
                        player_frame[2]:path(windower.addon_path .. texture_path)
                    end
                end
            end
        else
            -- Create member frames
            local mf_img = windower.addon_path .. member_texture
            member_frames[i] = images.new(deepcopy(member_config))
            member_frames[i]:size(member_frame_width, member_frame_height)
            member_frames[i]:path(mf_img)

            local pos_x = member_base.x
            local pos_y = member_base.y + (member_frame_height + spacing) * (i - 1)
            member_frames[i]:pos(pos_x, pos_y)
            member_frames[i]:show()

            ezparty.member_frames[i] = {
                x = pos_x,
                y = pos_y,
                width = member_frame_width,
                height = member_frame_height,
            }

            if i == 1 and not member_base.from_settings then
                addon_settings.ezparty.member_frame.pos = ez.convert_to_screen_percent({ x = pos_x, y = pos_y })
                config.save(addon_settings)
            end
        end
    end

    if player_frame[1] then
        player_frame[1]:show()
        ezparty.player_frame.one = player_frame[1]
    end

    if player_frame[2] then
        player_frame[2]:show()
        ezparty.player_frame.two = player_frame[2]
    end

    for _, frame in pairs(member_frames) do
        apply_image_visibility(frame, true)
    end

    frames_visible = true
end

function ezparty_frames.set_visible(visible)
    visible = visible ~= false

    if frames_visible == visible then
        return
    end

    frames_visible = visible

    for _, frame in pairs(player_frame) do
        apply_image_visibility(frame, visible)
    end

    for _, frame in pairs(member_frames) do
        apply_image_visibility(frame, visible)
    end
end

return ezparty_frames
