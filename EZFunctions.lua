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

local ezfunctions = {}

-- Default settings for creating settings.xml on first load
local function ezfunctions.create_defaults(settings)
	
	-- EZ Party
	settings.ezparty.hud.enabled = true
	settings.ezparty.hud.scale = 1
	settings.ezparty.hud.draggable = false
	settings.ezparty.hud.player_frame = {
		size = { x = 500 , y = 75 } ,
		path =  windower.addon_path .. 'gui/player_frame_bg.png' ,	
	}
	settings.ezparty.hud.x_pos = windower.get_settings().ui_res_x - settings.ezparty.hud.player_frame.x 
	settings.ezparty.hud.y_pos = windower.get_settings().ui_res_y - (settings.ezparty.hud.player_frame.y * 6) 
	settings.ezparty.hud.player_panel = {
		size = { x = 500 , y = 75 },
		path = windower.addon_path .. 'gui/player_panel_bg.png' ,
		offset = { x = 25 , y = 25  }
	}
	settings.ezparty.hud.hp = {
		size = { x = 119 , y = 9 },
		path = windower.addon_path .. 'gui/hp_bar.png',
		offset = { x = 57 , y = 27 }
	}
	settings.ezparty.hud.mp = {
		size = { x = 119 , y = 9 },
		path = windower.addon_path .. 'gui/mp_bar.png',
		offset = { x = 206 , y = 27 }
	}
	settings.ezparty.hud.tp = {
		size = { x = 119 , y = 9 },
		path = windower.addon_path .. 'gui/tp_bar.png',
		offset = { x = 355 , y = 27 }
	}
	
	-- EZ Mount
	settings.ezmount.bind = '^numpad9'
	settings.ezmount.name = 'raptor'
	settings.ezmount.enable_bind = false
	
	-- EZ Cure
	settings.ezcure.enable_bind = false
	settings.ezcure.bind = 'numpad5'
	
	return settings
	
end

-- Check for a specific buff ID & return boolean
local function ezfunctions.has_buff(buff_id)
	local player = windower.ffxi.get_player()
	
    for _, id in ipairs(player.buffs or {}) do
        if id == buff_id then
            return true
        end
    end
    return false
end

return ezfunctions