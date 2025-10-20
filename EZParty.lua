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
------------------------------------------------------------------------------------------
local addon_settings = config.load()
local hud_scale = addon_settings.ezparty.hud.scale
local ezparty = {}
local screen_width = windower.get_windower_settings().ui_x_res
local screen_height = windower.get_windower_settings().ui_y_res
local player_frame = {} 
local player_panel = {}
local slot_occupancy = {} 
local player_hp = {}
local player_mp = {}
local player_tp = {}

-- Generate slot position table accounting for hud_scale
local slot_position = {}
for i = 0, 5 do
	local current
	if i == 0 then
		current = { x = addon_settings.ezparty.hud.x_pos * hud_scale , y = addon_settings.ezparty.hud.y_pos * hud_scale }
	else 
		current.y = current.y - addon_settings.ezparty.hud.player_frame.size.y
		slot_position[i] = { x = current.x , y = current.y }
	end
end

function ezparty.init()
	
	local frame = addon_settings.ezparty.hud.player_frame
	local panel = addon_settings.ezparty.hud.player_panel
	local hp = addon_settings.ezparty.hud.hp
	local mp = addon_settings.ezparty.hud.mp
	local tp = addon_settings.ezparty.hud.tp
	
	-- Set Scale frame
	frame.offset.x = frame.offset.x * hud_scale 
	frame.offset.x = frame.offset.y * hud_scale 
	frame.size.x = frame.offset.x * hud_scale 
	frame.size.x = frame.offset.x * hud_scale 
	
	-- Set Scale Panel
	panel.offset.x = panel.offset.x * hud_scale 
	panel.offset.x = panel.offset.y * hud_scale 
	panel.size.x = panel.offset.x * hud_scale 
	panel.size.x = panel.offset.x * hud_scale 
	
	-- Set Scale HP
	hp.offset.x = hp.offset.x * hud_scale 
	hp.offset.x = hp.offset.y * hud_scale 
	hp.size.x = hp.offset.x * hud_scale 
	hp.size.x = hp.offset.x * hud_scale 
	
	-- Set Scale MP
	mp.offset.x = mp.offset.x * hud_scale 
	mp.offset.x = mp.offset.y * hud_scale 
	mp.size.x = mp.offset.x * hud_scale 
	mp.size.x = mp.offset.x * hud_scale 
	
	-- Set Scale TP
	tp.offset.x = tp.offset.x * hud_scale 
	tp.offset.x = tp.offset.y * hud_scale 
	tp.size.x = tp.offset.x * hud_scale 
	tp.size.x = tp.offset.x * hud_scale 
	
	--[[
	local hp_bar = { 
		path = addon_settings.ezparty.hud.hp_bar.path ,
		offset = { x = addon_settings.ezparty.hud.hp_bar.offset.x * hud_scale , y = addon_settings.ezparty.hud.hp_bar.offset.y * hud_scale } ,
		size = { x = addon_settings.ezparty.hud.hp_bar.size.x * hud_scale , y = addon_settings.ezparty.hud.hp_bar.y * hud_scale}
	}
	local mp_bar = { 
		path = addon_settings.ezparty.hud.mp_bar.path ,
		offset = { x = addon_settings.ezparty.hud.mp_bar.offset.x * hud_scale , y = addon_settings.ezparty.hud.mp_bar.offset.y * hud_scale } ,
		size = { x = addon_settings.ezparty.hud.mp_bar.x * hud_scale , y = addon_settings.ezparty.hud.mp_bar.y * hud_scale)
	}
	local tp_bar = { 
		path = addon_settings.ezparty.hud.tp_bar.path ,
		offset = { x = addon_settings.ezparty.hud.tp_bar.offset.x * hud_scale , y = addon_settings.ezparty.hud.tp_bar.offset.y * hud_scale } ,
		size = { x = addon_settings.ezparty.hud.tp_bar.x * hud_scale , y = addon_settings.ezparty.hud.tp_bar.y * hud_scale)
	}
	local pannel offset = { x = addon_settings.ezparty.player_pannel.offset.x * hud_scale , y = addon_settings.ezparty.player_pannel.offset.y * hud_scale }
	--]]
	
	
	for i = 0, 5 do
	    local party = windower.ffxi.get_party()
		
		player_frame[i] = images.new{
			pos = {x = slot_position[i].x + frame.offset.x  , y = slot_position[i].y + frame.offset.y},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size = frame.size,
			texture = {path = frame.path, fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 1,
		}
		
		-- Store the scaled size because why not. There is a bug and IDK WHAT IS GOING ON BUT FUCK PLEASE
		
		player_frame[i].scaled_size = frame.size
		
		player_panel[i] = images.new{
			pos = { x = slot_position[i].x + panel.offset.x , y = slot_position[i].y + panel.offset.y } ,
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size = panel.size ,
			texture = {path = panel.path , fit = false},
			repeatable = {x = 1, y = 1},
			draggable = true,
			layer = 2,
			group = i,
		}	
		
		player_panel[i].scaled_size = panel.size
		
		player_hp[i] = images.new{
			pos = {x = slot_position[i].x + hp.offset.x , y = slot_position[i].y + hp.offset.y},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = hp.size,
			texture = {path = hp.path , fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = i,
		}
		
		player_hp[i].scaled_size = hp.size
		
		player_mp[i] = images.new{
			pos = {x = slot_position[i].x + mp.offset.x , y = slot_position[i].y + mp.offset.y},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = mp.size,
			texture = {path = mp.path , fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = i,
		}
		
		player_mp[i].scaled_size = mp.size
		
		player_tp[i] = images.new{
			pos = {x = slot_position[i].x + tp.offset.x , y = slot_position[i].y + tp.offset.y},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = tp.size,
			texture = {path = tp.path , fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = i,
		}
		
		player_tp[i].scaled_size = tp.size
		
		player_frame.index = i -- Do i even use this anymore?
		slot_occupancy[i] = player_frame[i]
		
		panel.offset.y = panel.offset.y + ( addon_settings.ezparty.hud.player_panel.size.y * hud_scale )
		hp.offset.y = hp.offset.y + ( addon_settings.ezparty.hud.hp.size.y * hud_scale )
		mp.offset.y = mp.offset.y + ( addon_settings.ezparty.hud.mp.size.y * hud_scale )
		tp.offset.y = tp.offset.y + ( addon_settings.ezparty.hud.tp.size.y * hud_scale )
	
	end
	
	-- This is important - NOTE TO SELF: Stop forgetting to expose tables | So many NILs were had because of this
	-- This is where we export VVVVVVVVVVVVVVVVVVVVVVVVVVVVV down there. Stop. Forgetting.
	ezparty.slot_position = slot_position
	ezparty.hud_scale     = hud_scale
	ezparty.player_frame  = player_frame
	ezparty.player_panel  = player_panel
	ezparty.player_hp     = player_hp
	ezparty.player_mp     = player_mp
	ezparty.player_tp     = player_tp
end

ezparty.slot_position = slot_position
ezparty.hud_scale = hud_scale
ezparty.player_frame = player_frame

return ezparty