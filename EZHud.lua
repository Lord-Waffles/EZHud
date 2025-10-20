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
		
-------------------------------Addon Commands---------------------------------------------

 1) //ez buffid   | Returns current players buffs and their associated IDss
 2) //ez buff     | WIP
 3) //ez mount    | Mount/Dismount with a single hotkey (default key: CTRL + NUMPAD9)
 3) //ez cure     | Heals the lowest health target 
 4) //ez unlock   | Allows party hud to be moved with the mouse
 5) //ez lock     | Locks the party Hud from being dragged. It also saves its location in data/settings.xml
 6) //ez reset    | Resets the location of the party hud to x = 100, y = 100
 
 -------------------------------Addon Settings----------------------------------------------]]

-- Addon Info
_addon.name = 'EZ Hud'
_addon.author = 'Rook & Makto'
_addon.version = '1.0.0'
_addon.command = 'ez'
_addon.language = 'english'

-- Libraries
config = require('config')
texts  = require('texts')
images = require('images')
ezparty = require('EZParty')
ezcure = require('EZCure')


local addon_settings = config.load(defaults)
config.save(addon_settings)

---------------------------------Addon Binds------------------------------------------------]]

windower.send_command('bind '..addon_settings.ezmount.bind..' input //ez mount')

--------------------------------------------------------------------------------------------]]


-- Initialize
local screen_width = windower.get_windower_settings().ui_x_res
local screen_height = windower.get_windower_settings().ui_y_res
ezparty.init()

-- Frame Update - We draw shit every frame because we can
windower.register_event('prerender', function()
	local party = windower.ffxi.get_party()
    local hp_tbl = ezparty.player_hp
    local mp_tbl = ezparty.player_mp
    local tp_tbl = ezparty.player_tp
    local hud_scale = ezparty.hud_scale or 1.0
	local player_panel = ezparty.player_panel

    if not (hp_tbl and mp_tbl and tp_tbl) then
        return
    end
	
	

    for i = 1, 6 do
        local member = party['p'..i - 1]
        if member and member.name then
			-- Enable Player health bars and panel
			player_panel[i]:show()
			hp_tbl[i]:show()
			mp_tbl[i]:show()
			tp_tbl[i]:show()
            local hp = member.hpp or 0
            local mp = member.mpp or 0
            local tp = member.tp or 0

            if hp_tbl[i] then hp_tbl[i]:size((119 * hud_scale) * (hp / 100), 9 * hud_scale) end
            if mp_tbl[i] then mp_tbl[i]:size((119 * hud_scale) * (mp / 100), 9 * hud_scale) end
            if tp_tbl[i] then tp_tbl[i]:size((119 * hud_scale) * (math.min(tp, 1000) / 1000), 9 * hud_scale) end
		else
			player_panel[i]:hide()
			hp_tbl[i]:hide()
			mp_tbl[i]:hide()
			tp_tbl[i]:hide()
        end
    end
end) 

---------------V--Functions--V--------------------------

-- Check if player has buff ID
local function has_buff(buff_id)
	player = windower.ffxi.get_player()
	
    for _, id in ipairs(player.buffs or {}) do
        if id == buff_id then
            return true
        end
    end
    return false
end

-----------------Addon Commands---------------------------

windower.register_event('addon command', function(command)

	-- Get Player Info
	local player = windower.ffxi.get_player() 

	-- EZ Buff IDs
	if command:lower() == 'buffid' and player.main_job_id == 5 then
		windower.add_to_chat(108, "Buff ID's: "..table.concat(player.buffs, ", "))
	end
	
	-- EZ Mount
	if command:lower() == 'mount' then
		if has_buff(252) == false then
			windower.send_command('input /mount '..addon_settings.ezmount.name)
		else
			windower.send_command('input /dismount')
		end
	end	
	
	-- EZ Auto Cure
	if command:lower() == 'cure' then
		ezcure.auto_cure(addon_settings)
	end
end)
		