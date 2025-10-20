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
local addon_settings = config.load(defaults)
local hud_scale = addon_settings.ezparty.hud.scale
local ezparty = {}
local events = {
    reload = true,
    left_click = true,
    double_left_click = true,
    right_click = true,
    double_right_click = true,
    middle_click = true,
    scroll_up = true,
    scroll_down = true,
    hover = true,
    drag = true,
    right_drag = true
}
local screen_width = windower.get_windower_settings().ui_x_res
local screen_height = windower.get_windower_settings().ui_y_res
local player_frame = {} 
local player_panel = {}
local slot_occupancy = {} 
local player_hp = {}
local player_mp = {}
local player_tp = {}
local slot_position = {
    [1] = {x=screen_width - (500 * hud_scale), y=screen_height - ((75 * 6) * hud_scale)},
    [2] = {x=screen_width - (500 * hud_scale), y=screen_height - ((75 * 5) * hud_scale)},
    [3] = {x=screen_width - (500 * hud_scale), y=screen_height - ((75 * 4) * hud_scale)},
    [4] = {x=screen_width - (500 * hud_scale), y=screen_height - ((75 * 3) * hud_scale)},
    [5] = {x=screen_width - (500 * hud_scale), y=screen_height - ((75 * 2) * hud_scale)},
    [6] = {x=screen_width - (500 * hud_scale), y=screen_height - (75 * hud_scale)},
}

function ezparty.init()
	
	local player_frame_bg = windower.addon_path .. 'player_frame_bg.png'
	local player_panel_bg = windower.addon_path .. 'player_panel_bg.png'
	
	
	for i = 1, 6 do
	    local party = windower.ffxi.get_party()
		local group_id = i
		local member = party['p'..i - 1]
		
		player_frame[i] = images.new{
			pos = {x = slot_position[i].x, y = slot_position[i].y},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size = {width = 500 * hud_scale, height = 75 * hud_scale},
			texture = {path = player_frame_bg, fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 1,
		}
		
		-- Store the scaled size because why not. There is a bug and IDK WHAT IS GOING ON BUT FUCK PLEASE
		-- I'm desperate here so lets just be safe and store the scaled size nice and neat and expose its
		player_frame[i].scaled_size = { width = 500 * hud_scale, height = 75 * hud_scale }
		
		player_panel[i] = images.new{
			pos = {x = slot_position[i].x + (38 * hud_scale), y = slot_position[i].y + (2 * hud_scale)},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size = {width = 460 * hud_scale, height = 47 * hud_scale},
			texture = {path = player_panel_bg, fit = false},
			repeatable = {x = 1, y = 1},
			draggable = true,
			layer = 2,
			group = group_id,
		}	
		
		player_panel[i].scaled_size = { width = 460 * hud_scale, height = 47 * hud_scale }
		
		player_hp[i] = images.new{
			pos = {x = slot_position[i].x + ( 57 * hud_scale ) , y = slot_position[i].y + ( 27 * hud_scale )},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = {width = 119 * hud_scale, height = 9 * hud_scale},
			texture = {path = windower.addon_path .. 'HP_bar.png', fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = group_id,
		}
		
		player_hp[i].scaled_size = { width = 119 * hud_scale, height = 9 * hud_scale }
		
		player_mp[i] = images.new{
			pos = {x = slot_position[i].x + (206 * hud_scale) , y = slot_position[i].y + ( 26 * hud_scale )},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = {width = 119 * hud_scale , height = 9 * hud_scale},
			texture = {path = windower.addon_path .. 'MP_bar.png', fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = group_id,
		}
		
		player_mp[i].scaled_size = { width = 119 * hud_scale, height = 9 * hud_scale }
		
		player_tp[i] = images.new{
			pos = {x = slot_position[i].x + (355 * hud_scale) , y = slot_position[i].y + ( 26 * hud_scale )},
			visible = true,
			color = {alpha = 255, red = 255, green = 255, blue = 255},
			size  = {width = 119 * hud_scale, height = 9 * hud_scale},
			texture = {path = windower.addon_path .. 'TP_bar.png', fit = false},
			repeatable = {x = 1, y = 1},
			draggable = false,
			layer = 3,
			group = group_id,
		}
		
		player_tp[i].scaled_size = { width = 119 * hud_scale, height = 9 * hud_scale }
		
		player_frame.index = i
		slot_occupancy[i] = player_frame
	
		player_frame[i]:show()
		player_panel[i]:show()
		player_hp[i]:show()
		player_mp[i]:show()
		player_tp[i]:show()
		
	
	end
	
	-- This is important - NOTE TO SELF: Stop forgetting to expose tables | So many NILs were had because of this
	-- This is where we export VVVVVVVVVVVVVVVVVVVVVVVVVVVVV down there. Stop. Forgetting.
	ezparty.slot_position = slot_position
	ezparty.hud_scale     = hud_scale
	ezparty.player_frame  = player_frame
	ezparty.player_panel = player_panel
	ezparty.player_hp     = player_hp
	ezparty.player_mp     = player_mp
	ezparty.player_tp     = player_tp
end

ezparty.slot_position = slot_position
ezparty.hud_scale = hud_scale
ezparty.player_frame = player_frame

return ezparty