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

 1) //ez buffid   | Returns current players buffs and their associated IDs to chat
 2) //ez buff     | WIP
 3) //ez mount    | Mount/Dismount with a single hotkey (if bind is enabled then default key: CTRL + NUMPAD9)
 3) //ez cure     | Heals the lowest health target  (if bind is enabled then default key: NUMPAD5)
 4) //ez unlock   | 
 5) //ez lock     | 
 6) //ez reset    | 
 
 -------------------------------Addon Settings----------------------------------------------]]

-- Addon Info
_addon.name = 'EZ Hud'
_addon.author = 'Rook & Makto'
_addon.version = '1.0.0'
_addon.command = 'ez'
_addon.language = 'english'

-- Libraries
local config = require('config')
local texts  = require('texts')
local images = require('images')
local ezparty = require('EZParty')
local ezcure = require('EZCure')
local ezfunctions = require('EZFunctions')

-- Initialize Addon
local screen_width = windower.get_windower_settings().ui_x_res
local screen_height = windower.get_windower_settings().ui_y_res
local defaults = {}
addon_settings = config.load(defaults) -- only will load defaults if data/settings.xml doesn't exist
--addon_settings:save()                 -- This is here to create the data/settings.xml with the defaults if it doesn't exist, if it does exist it will just re-save existing settings

-- EZ Party Create GUI
if addon_settings.ezparty.enabled == true then
	ezparty.init()
end

---------------------------------Set Binds------------------------------------------------]]

-- EZ Mount Bind
if addon_settings.ezmount.enable_bind == true then
	windower.send_command('bind '.. addon_settings.ezmount.bind .. ' input //ez mount')
end

-- EZ Cure Bind
if addon_settings.ezcure.enable_bind == true then
	windower.send_command('bind '.. addon_settings.ezcure.bind .. ' input //ez cure')
end

-----------------------------PreRender Frame Loop-----------------------------------------]]

windower.register_event('prerender', function()

        local party = windower.ffxi.get_party()
        if not party then -- Not sure if get_party is = nil during loading screens/cutscenes or any other time... but if it is nil it probably isn't a good time to load the GUI
                return
        end
		
		-- Set Variables
		
        local hp_tbl = ezparty.player_hp
        local mp_tbl = ezparty.player_mp
        local tp_tbl = ezparty.player_tp
        local player_panel = ezparty.player_panel
        local hp_size = ezparty.hp_size or { width = 0, height = 0 }
        local mp_size = ezparty.mp_size or { width = 0, height = 0 }
        local tp_size = ezparty.tp_size or { width = 0, height = 0 }

        if not (hp_tbl and mp_tbl and tp_tbl and player_panel) then
                return
        end



        for i = 0, 5 do
                local member = party['p'..i]
                local panel = player_panel[i]
                local hp_image = hp_tbl[i]
                local mp_image = mp_tbl[i]
                local tp_image = tp_tbl[i]

                if member and member.name then
				
                        -- Enable Player health bars and panel
                        if panel then panel:show() end
                        if hp_image then hp_image:show() end
                        if mp_image then mp_image:show() end
                        if tp_image then tp_image:show() end

                        local hp = member.hpp or 0
                        local mp = member.mpp or 0
                        local tp = member.tp or 0

                        if hp_image then
                                hp_image:size((hp_size.width or 0) * (hp / 100), hp_size.height or 0)
                        end
                        if mp_image then
                                mp_image:size((mp_size.width or 0) * (mp / 100), mp_size.height or 0)
                        end
                        if tp_image then
                                tp_image:size((tp_size.width or 0) * (math.min(tp, 1000) / 1000), tp_size.height or 0)
                        end
                else
						-- Hide panels if no party member exists
                        if panel then panel:hide() end
                        if hp_image then hp_image:hide() end
                        if mp_image then mp_image:hide() end
                        if tp_image then tp_image:hide() end
                end
        end
end)

---------------------------Addon Commands-------------------------------------------------]]

windower.register_event('addon command', function(command)

	-- Get Player Info
	local player = windower.ffxi.get_player() 

	-- EZ Buff IDs
	if command:lower() == 'buffid' then
		windower.add_to_chat(108, "Buff ID's: "..table.concat(player.buffs, ", "))
	end
	
	-- EZ Mount
	if command:lower() == 'mount' then
		if ezfunctions.has_buff(252) == false then
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