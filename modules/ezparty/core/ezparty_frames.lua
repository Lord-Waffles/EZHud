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
local texts = require('texts')
local config = require('config')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

-- Variables
local player_frame = {}
local member_frames = {}
local text_keys = {'slot_label', 'name', 'hpp', 'hp_label', 'hp_value', 'mp_label', 'mp_value', 'tp_label', 'tp_value'}
local ui_width = windower.get_windower_settings().ui_x_res
local ui_height = windower.get_windower_settings().ui_y_res

-- EZ Party Module
local ezparty = {}
ezparty.player_frame = {}
ezparty.member_frames = {}

function ezparty_frames.create(addon_settings)
    local scale = addon_settings.ezparty.scale or 1
    local saved_res = {}

    local spacing = addon_settings.ezparty.layout.vertical_spacing or 50
    addon_settings.savedUI = {}

    -- Set up player frame settings
    local pframe = {}
    pframe.width = addon_settings.ezparty.player_frame.one.size.width * scale
    pframe.height = addon_settings.ezparty.player_frame.one.size.height * scale
    pframe.one = {}
    pframe.one.pos = addon_settings.ezparty.player_frame.one.pos
    pframe.two = {}
    pframe.two.pos = addon_settings.ezparty.player_frame.two.pos
    pframe.linked = addon_settings.ezparty.player_frame.linked

    -- Set up member frame settings
    local mframe = {}
    mframe.width = addon_settings.ezparty.member_frame.size.width * scale
    mframe.height = addon_settings.ezparty.member_frame.size.height * scale
    mframe.pos = {}
    mframe.pos = addon_settings.ezparty.member_frame.pos

    for i = 0, 5 do
        -- Create player frames if enabled
        if i == 0 then
            ---------------------------------Player Frame 1------------------------------------
            if addon_settings.ezparty.player_frame.one.enable ~= false then
                player_frame[1] = images.new(addon_settings.ezparty.player_frame.one)
                player_frame[1]:size(pframe.width, pframe.height)

                -- If no position set in settings, default to bottom right above member frames
                -- else convert settings.xml back to pixels
                if pframe.one.pos.x == 0 and pframe.one.pos.y == 0 then
                    player_frame[1]:pos( ui_width - pframe.width , ui_height - (spacing * 5 ) - (mframe.height * 5) - pframe.height )
                    addon_settings.ezparty.player_frame.one.pos = ez.convert_to_screen_percent(player_frame[1].pos)
                    config.save(addon_settings)
                else
                    player_frame[1]:pos(ez.convert_to_screen_pixels(addon_settings.ezparty.player_frame.one.pos))
                end

                -- If unique player frame is disabled, use member frame image
                if addon_settings.ezparty.player_frame.unique ~= true then
                    player_frame[1]:path(windower.addon_path .. addon_settings.ezparty.member_frame.texture.path)
                else
                    player_frame[1]:path(windower.addon_path .. addon_settings.ezparty.player_frame.one.texture.path)
                end
            end
            ---------------------------------Player Frame 2------------------------------------
            if addon_settings.ezparty.player_frame.two.enable ~= false then
                player_frame[2] = images.new(addon_settings.ezparty.player_frame.two)
                player_frame[2]:size(pframe.width, pframe.height)
                -- If no position set in settings, default to lower middle screen
                if pframe.two.pos.x == 0 and pframe.two.pos.y == 0 then
                    player_frame[2]:pos( ui_width / 2 - pframe.width / 2, ui_height - (ui_height / 4.3) )
                    addon_settings.ezparty.player_frame.two.pos = ez.convert_to_screen_percent(player_frame[2].pos)
                    --config.save(addon_settings)
                else
                    player_frame[2]:pos(ez.convert_to_screen_pixels(addon_settings.ezparty.player_frame.two.pos))
                end


                -- If unique player frame is disabled, use member frame image
                if addon_settings.ezparty.player_frame.unique ~= true then
                    player_frame[2]:path(windower.addon_path .. addon_settings.ezparty.member_frame.textuer.path)
                else
                    player_frame[2]:path(windower.addon_path .. addon_settings.ezparty.player_frame.two.texture.path)
                end
            end
        else
            -- Create member frames
            local mf_img = windower.addon_path .. addon_settings.ezparty.member_frame.texture.path
            member_frames[i] = images.new(addon_settings.ezparty.member_frame)
            member_frames[i]:size(mframe.width, mframe.height)
            member_frames[i]:path(mf_img)

            if i == 1 then
                if mframe.pos.x == 0 and mframe.pos.y == 0 then
                    member_frames[i]:pos( ui_width - mframe.width , ui_height - (spacing * ( 6 - i )) - (mframe.height * (6 - i)) )
                    member_frames[i]:show()
                    ezparty.member_frames[i] = {x = ui_width - mframe.width, y = ui_height - (spacing * ( 5 - i )) - (mframe.height * (5 - i))}
                    addon_settings.ezparty.member_frame.pos = ez.convert_to_screen_percent(ezparty.member_frames[i].pos)
                    --config.save(addon_settings)
                else
                    member_frames[i]:pos(ez.convert_to_screen_pixels(addon_settings.ezparty.member_frame.pos))
                    ezparty.member_frames[i] = ez.convert_to_screen_pixels(addon_settings.ezparty.member_frame.pos)
                end
            else
                --windower.add_to_chat(108, tostring(member_one.x))
                member_frames[i]:pos(ezparty.member_frames[1].x, ezparty.member_frames[1].y + (spacing * (i - 2)) + (mframe.height * (i - 2)))
            end
            member_frames[i]:path(windower.addon_path .. 'gui/ezparty/member_frame.png')
            member_frames[i]:show()
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