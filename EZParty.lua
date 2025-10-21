--[[
        Copyright © 2025, Rook & Makto (Bahamut)
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
-- Libraries
local config = require('config')
local texts  = require('texts')

-----------------------------------------Init-------------------------------------------------]] 
local addon_settings = config.load()
local hud_scale = tonumber(addon_settings.ezparty.hud.scale) or 1
local ezparty = {}
local screen_width = windower.get_windower_settings().ui_x_res
local screen_height = windower.get_windower_settings().ui_y_res
local player_frame = {}
local player_panel = {}
local slot_occupancy = {}
local player_hp = {}
local player_mp = {}
local player_tp = {}
local slot_position = {}
local frame_size = { width = 0, height = 0 }
local panel_size = { width = 0, height = 0 }
local hp_size = { width = 0, height = 0 }
local mp_size = { width = 0, height = 0 }
local tp_size = { width = 0, height = 0 }

local function scale_value(value, scale)
        return (tonumber(value) or 0) * scale
end

local function scaled_size(size, scale)
        size = size or {}

        return {
                width = scale_value(size.x, scale),
                height = scale_value(size.y, scale),
        }
end

local function scaled_offset(offset, scale)
        offset = offset or {}

        return {
                x = scale_value(offset.x, scale),
                y = scale_value(offset.y, scale),
        }
end

function ezparty.init()
        addon_settings = config.load()

        local hud = addon_settings.ezparty and addon_settings.ezparty.hud or {}

        hud_scale = tonumber(hud.scale) or 1

        local frame = hud.player_frame or {}
        local panel = hud.player_panel or {}
        local hp = hud.hp or {}
        local mp = hud.mp or {}
        local tp = hud.tp or {}

        local frame_texture = windower.addon_path .. (frame.texture_path or '')
        local panel_texture = windower.addon_path .. (panel.texture_path or '')
        local hp_texture = windower.addon_path .. (hp.texture_path or '')
        local mp_texture = windower.addon_path .. (mp.texture_path or '')
        local tp_texture = windower.addon_path .. (tp.texture_path or '')

        frame_size = scaled_size(frame.size, hud_scale)
        panel_size = scaled_size(panel.size, hud_scale)
        hp_size = scaled_size(hp.size, hud_scale)
        mp_size = scaled_size(mp.size, hud_scale)
        tp_size = scaled_size(tp.size, hud_scale)

        local panel_offset = scaled_offset(panel.offset, hud_scale)
        local hp_offset = scaled_offset(hp.offset, hud_scale)
        local mp_offset = scaled_offset(mp.offset, hud_scale)
        local tp_offset = scaled_offset(tp.offset, hud_scale)

        slot_position = {}
        local frame_width = frame_size.width
        local frame_height = frame_size.height
        local base_x = screen_width - frame_width
        local base_y = screen_height - (frame_height * 6)

        for i = 0, 5 do
                slot_position[i] = {
                        x = base_x,
                        y = base_y + (frame_height * i),
                }

                player_frame[i] = images.new{
                        pos = { x = slot_position[i].x, y = slot_position[i].y },
                        visible = true,
                        color = { alpha = 255, red = 255, green = 255, blue = 255 },
                        size = { width = frame_size.width, height = frame_size.height },
                        texture = { path = frame_texture, fit = false },
                        repeatable = { x = 1, y = 1 },
                        draggable = false,
                        layer = 1,
                }
                player_frame[i].scaled_size = { width = frame_size.width, height = frame_size.height }

                player_panel[i] = images.new{
					pos = {
						x = slot_position[i].x + panel_offset.x,
						y = slot_position[i].y + panel_offset.y,
					},
					visible = true,
					color = { alpha = 255, red = 255, green = 255, blue = 255 },
					size = { width = panel_size.width, height = panel_size.height },
					texture = { path = panel_texture, fit = false },
					repeatable = { x = 1, y = 1 },
					draggable = true,
					layer = 2,
					group = i,
                }
                player_panel[i].scaled_size = { width = panel_size.width, height = panel_size.height }

                player_hp[i] = images.new{
					pos = {
						x = slot_position[i].x + hp_offset.x,
						y = slot_position[i].y + hp_offset.y,
					},
					visible = true,
					color = { alpha = 255, red = 255, green = 255, blue = 255 },
					size = { width = hp_size.width, height = hp_size.height },
					texture = { path = hp_texture, fit = false },
					repeatable = { x = 1, y = 1 },
					draggable = false,
					layer = 3,
					group = i,
                }
                player_hp[i].scaled_size = { width = hp_size.width, height = hp_size.height }

                player_mp[i] = images.new{
					pos = {
						x = slot_position[i].x + mp_offset.x,
						y = slot_position[i].y + mp_offset.y,
					},
					visible = true,
					color = { alpha = 255, red = 255, green = 255, blue = 255 },
					size = { width = mp_size.width, height = mp_size.height },
					texture = { path = mp_texture, fit = false },
					repeatable = { x = 1, y = 1 },
					draggable = false,
					layer = 3,
					group = i,
                }
                player_mp[i].scaled_size = { width = mp_size.width, height = mp_size.height }

                player_tp[i] = images.new{
					pos = {
						x = slot_position[i].x + tp_offset.x,
						y = slot_position[i].y + tp_offset.y,
					},
					visible = true,
					color = { alpha = 255, red = 255, green = 255, blue = 255 },
					size = { width = tp_size.width, height = tp_size.height },
					texture = { path = tp_texture, fit = false },
					repeatable = { x = 1, y = 1 },
					draggable = false,
					layer = 3,
					group = i,
                }
                player_tp[i].scaled_size = { width = tp_size.width, height = tp_size.height }

                player_frame.index = i
                slot_occupancy[i] = player_frame[i]
                player_frame[i]:show()
        end

        ezparty.slot_position = slot_position
        ezparty.hud_scale = hud_scale
        ezparty.player_frame = player_frame
        ezparty.player_panel = player_panel
        ezparty.player_hp = player_hp
        ezparty.player_mp = player_mp
        ezparty.player_tp = player_tp
        ezparty.frame_size = frame_size
        ezparty.panel_size = panel_size
        ezparty.hp_size = hp_size
        ezparty.mp_size = mp_size
        ezparty.tp_size = tp_size
end

-- Not certain if this is needed - but just incase we will expose it again outside the loop
ezparty.slot_position = slot_position
ezparty.hud_scale = hud_scale
ezparty.player_frame = player_frame
ezparty.player_panel = player_panel
ezparty.player_hp = player_hp
ezparty.player_mp = player_mp
ezparty.player_tp = player_tp
ezparty.frame_size = frame_size
ezparty.panel_size = panel_size
ezparty.hp_size = hp_size
ezparty.mp_size = mp_size
ezparty.tp_size = tp_size

return ezparty