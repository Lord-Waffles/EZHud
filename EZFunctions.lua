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

-- Libs

config = require('config')
texts  = require('texts')
images = require('images')
require('resources')

local ezfunctions = {}

-- Default settings for creating settings.xml on first load
function ezfunctions.create_defaults(settings)
        settings = settings or {}

        -- EZ Party
        settings.ezparty = settings.ezparty or {}
        settings.ezparty.enabled = settings.ezparty.enabled ~= false

        local hud = settings.ezparty.hud or {}
        settings.ezparty.hud = hud
        hud.enabled = hud.enabled ~= false
        hud.scale = hud.scale or 1
        hud.draggable = hud.draggable or false

        hud.player_frame = hud.player_frame or {
                size = { x = 500 , y = 75 },
                offset = { x = 0 , y = 0 },
                path =  windower.addon_path .. 'gui/player_frame_bg.png',
        }
        hud.player_frame.size = hud.player_frame.size or { x = 500 , y = 75 }
        hud.player_frame.offset = hud.player_frame.offset or { x = 0 , y = 0 }
        hud.player_frame.x = hud.player_frame.x or hud.player_frame.size.x
        hud.player_frame.y = hud.player_frame.y or hud.player_frame.size.y

        --hud.x_pos = windower.get_settings().ui_res_x - hud.player_frame.size.x
        --hud.y_pos = windower.get_settings().ui_rez_y - (hud.player_frame.size.y * 6)

        hud.player_panel = hud.player_panel or {
                size = { x = 500 , y = 75 },
                path = windower.addon_path .. 'gui/player_panel_bg.png',
                offset = { x = 25 , y = 25 }
        }
        hud.player_panel.size = hud.player_panel.size or { x = 500 , y = 75 }
        hud.player_panel.offset = hud.player_panel.offset or { x = 25 , y = 25 }

        hud.hp = hud.hp or {
                size = { x = 119 , y = 9 },
                path = windower.addon_path .. 'gui/hp_bar.png',
                offset = { x = 57 , y = 27 }
        }
        hud.hp.size = hud.hp.size or { x = 119 , y = 9 }
        hud.hp.offset = hud.hp.offset or { x = 57 , y = 27 }

        hud.mp = hud.mp or {
                size = { x = 119 , y = 9 },
                path = windower.addon_path .. 'gui/mp_bar.png',
                offset = { x = 206 , y = 27 }
        }
        hud.mp.size = hud.mp.size or { x = 119 , y = 9 }
        hud.mp.offset = hud.mp.offset or { x = 206 , y = 27 }

        hud.tp = hud.tp or {
                size = { x = 119 , y = 9 },
                path = windower.addon_path .. 'gui/tp_bar.png',
                offset = { x = 355 , y = 27 }
        }
        hud.tp.size = hud.tp.size or { x = 119 , y = 9 }
        hud.tp.offset = hud.tp.offset or { x = 355 , y = 27 }

        -- EZ Mount
        settings.ezmount = settings.ezmount or {}
        settings.ezmount.bind = settings.ezmount.bind or '^numpad9'
        settings.ezmount.name = settings.ezmount.name or 'raptor'
        settings.ezmount.enable_bind = settings.ezmount.enable_bind or false

        -- EZ Cure
        settings.ezcure = settings.ezcure or {}
        settings.ezcure.enable_bind = settings.ezcure.enable_bind or false
        settings.ezcure.bind = settings.ezcure.bind or 'numpad5'

        return settings

end

-- Check for a specific buff ID & return boolean
function ezfunctions.has_buff(buff_id)
	local player = windower.ffxi.get_player()
	
    for _, id in ipairs(player.buffs or {}) do
        if id == buff_id then
            return true
        end
    end
    return false
end

return ezfunctions