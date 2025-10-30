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

-- Variables
local player_frame = {}
local member_frames = {}
local ui_width = windower.get_windower_settings().ui_x_res
local ui_height = windower.get_windower_settings().ui_y_res

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

local function resolve_member_base(addon_settings, width, height, spacing)
    local config_pos = (addon_settings.ezparty.member_frame and addon_settings.ezparty.member_frame.pos) or {}
    if (config_pos.x or 0) == 0 and (config_pos.y or 0) == 0 then
        return {
            x = ui_width - width,
            y = math.max(0, ui_height - height - (height + spacing) * (DEFAULT_MEMBER_COUNT - 1) - spacing),
            from_settings = false,
        }
    end

    local pixels = ez.convert_to_screen_pixels(config_pos) or {}
    return {
        x = math.floor(pixels.x or 0),
        y = math.floor(pixels.y or 0),
        from_settings = true,
    }
end

function ezparty_frames.create(addon_settings)
    local scale = tonumber(addon_settings.ezparty.scale) or 1

    local spacing = resolve_spacing(addon_settings, scale)
    addon_settings.savedUI = addon_settings.savedUI or {}

    local player_one_config = deepcopy(addon_settings.ezparty.player_frame.one or {})
    local player_two_config = deepcopy(addon_settings.ezparty.player_frame.two or {})
    local member_config = deepcopy(addon_settings.ezparty.member_frame or {})

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
                player_frame[1] = images.new(deepcopy(addon_settings.ezparty.player_frame.one))
                player_frame[1]:size(player_one_width, player_one_height)

                local one_pos = player_one_config.pos or {}
                if (one_pos.x or 0) == 0 and (one_pos.y or 0) == 0 then
                    local default_x = ui_width - player_one_width
                    local default_y = member_base.y - spacing - player_one_height
                    player_frame[1]:pos(default_x, default_y)
                    addon_settings.ezparty.player_frame.one.pos = ez.convert_to_screen_percent({ x = default_x, y = default_y })
                    config.save(addon_settings)
                else
                    player_frame[1]:pos(ez.convert_to_screen_pixels(one_pos))
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
                player_frame[2] = images.new(deepcopy(addon_settings.ezparty.player_frame.two))
                player_frame[2]:size(player_two_width, player_two_height)

                local two_pos = player_two_config.pos or {}
                if (two_pos.x or 0) == 0 and (two_pos.y or 0) == 0 then
                    local default_x = math.floor(ui_width / 2 - player_two_width / 2)
                    local default_y = math.floor(ui_height - (ui_height / 4.3))
                    player_frame[2]:pos(default_x, default_y)
                    addon_settings.ezparty.player_frame.two.pos = ez.convert_to_screen_percent({ x = default_x, y = default_y })
                else
                    player_frame[2]:pos(ez.convert_to_screen_pixels(two_pos))
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
            member_frames[i] = images.new(deepcopy(addon_settings.ezparty.member_frame))
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
end

return ezparty_frames
