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

local ezcure = {}
local party = windower.ffxi.get_party()
local lowestMember = party.p1
local lowest_percent = 100
local knownSpells = windower.ffxi.get_spells()

function ezcure.auto_cure(addon_settings)
	for i = 0, 5 do
		member = party['p'..i]
		if member and member.hpp and member.hpp < lowest_percent then
			lowestMember = member
			lowest_percent = member.hpp
		end
	end

	if lowestMember and lowestMember.name and lowest_percent ~= 100 then
		local cureType = 'Cure'
		
		if lowestMember.hpp >= 90 then
			if knownSpells[1] == true then
				windower.send_command('input /ma "cure" '..lowestMember.name)
			elseif knownSpells[2] == true then
				cureType = 'Cure II'
				windower.send_command('input /ma "cure ii" '..lowestMember.name)
			elseif knownSpells[3] == true then
				cureType = 'Cure III'
				windower.send_command('input /ma "cure iii" '..lowestMember.name)
			elseif knownSpells[4] == true then
				cureType = 'Cure IV'
				windower.send_command('input /ma "cure iv" '..lowestMember.name)
			else
				cureType = 'Dumbass'
				windower.add_to_chat(108, 'How about learning a Cure spell first? Noob')
			end
			
		elseif lowestMember.hpp >= 75 then
			if knownSpells[2] == true then
				cureType = 'Cure II'
				windower.send_command('input /ma "cure ii" '..lowestMember.name)
			elseif knownSpells[3] == true then
				cureType = 'Cure III'
				windower.send_command('input /ma "cure iii" '..lowestMember.name)
			elseif knownSpells[4] == true then
				cureType = 'Cure IV'
				windower.send_command('input /ma "cure iv" '..lowestMember.name)
			elseif knownSpells[1] == true then
				windower.send_command('input /ma "cure" '..lowestMember.name)
			else
				cureType = 'Dumbass'
				windower.add_to_chat(108, 'How about learning a Cure spell first? Noob')
			end
			
		elseif lowestMember.hpp >= 50 then
		
			if knownSpells[3] == true then
				cureType = 'Cure III'
				windower.send_command('input /ma "cure iii" '..lowestMember.name)
			elseif knownSpells[4] == true then
				cureType = 'Cure IV'
				windower.send_command('input /ma "cure iv" '..lowestMember.name)
			elseif knownSpells[2] == true then
				cureType = 'Cure II'
				windower.send_command('input /ma "cure ii" '..lowestMember.name)
			elseif knownSpells[1] == true then
				windower.send_command('input /ma "cure" '..lowestMember.name)
			else
				cureType = 'Dumbass'
				windower.add_to_chat(108, 'How about learning a Cure spell first? Noob')
			end

		else
			if knownSpells[4]== true then
				cureType = 'Cure IV'
				windower.send_command('input /ma "cure iv" '..lowestMember.name)
			elseif knownSpells[3] == true then
				cureType = 'Cure III'
				windower.send_command('input /ma "cure iii" '..lowestMember.name)
			elseif knownSpells[2] == true then
				cureType = 'Cure II'
				windower.send_command('input /ma "cure ii"'..lowestMember.name)
			elseif knownSpells[1] == true then
				windower.send_command('input /ma "cure i" '..lowestMember.name)
			else
				cureType = 'Dumbass'
				windower.add_to_chat(108, 'How about learning a Cure spell first? Noob')
			end
		end
		
		if cureType ~= 'Dumbass' then 
			windower.add_to_chat(108, 'Casting '..cureType..' on '..lowestMember.name..' | HP('..lowest_percent..'%)') 
		end
	else
		windower.add_to_chat(108, 'Everyone is full on HP')
	end	
end
return ezcure