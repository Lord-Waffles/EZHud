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

_addon.name = 'EZ Hud'
_addon.author = 'Rook & Makto'
_addon.version = '1.0.0'
_addon.command = 'ez'
_addon.language = 'english'

-- Libs
local config = require('config')
local ez = require('core.ezfunctions')
local ezparty = require('modules.ezparty.ezparty')
local ezmount = require('modules.ezmount.ezmount')
local ezcastbar = require('modules.ezcastbar.ezcastbar')
local ezgui_creator = require('modules.ezgui_creator.ezgui_creator')
local theme_manager = require('core.theme_manager')
local ezdefaults = require('core.ezdefaults') or {}
require('tables')
require('strings')

-- Configure/load data/settings.xml
local addon_settings = config.load(ezdefaults)
config.save(addon_settings)

ezparty.init(addon_settings)
ezgui_creator.init(addon_settings)
ezmount.init(addon_settings)
ezcastbar.init(addon_settings)

-- Run module inits on login
windower.register_event('login', function()
  ezparty.init(addon_settings)
  ezmount.init(addon_settings)
  ezcastbar.init(addon_settings)
end)

windower.register_event('logout', function()
  ezmount.destroy()
  ezcastbar.destroy()
end)


-- Addon command handler
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower() or ''

    if command == 'debug' then
        windower.add_to_chat(tostring(addon_settings))
        return
    end

    if command == 'gc' then
        local action = args[1] and args[1]:lower() or ''
        if action == 'open' then
            ezgui_creator.open()
        elseif action == 'close' then
            ezgui_creator.close()
        else
            ezgui_creator.toggle()
        end
        return
    end

    if command == 'load' then
        local theme_name = args[1]
        if not theme_name then
            windower.add_to_chat(123, 'Usage: //ez load <theme>')
            return
        end

        local success, message = theme_manager.load(theme_name, addon_settings)
        if success then
            ezparty.init(addon_settings)
            ezgui_creator.init(addon_settings)
            ezmount.init(addon_settings)
            ezcastbar.init(addon_settings)
            windower.add_to_chat(207, message)
        else
            windower.add_to_chat(123, message)
        end
        return
    end

    if command == 'export' then
        local theme_name = args[1]
        if not theme_name then
            windower.add_to_chat(123, 'Usage: //ez export <theme>')
            return
        end

        local success, message = theme_manager.export(theme_name, addon_settings)
        if success then
            windower.add_to_chat(207, string.format('Theme exported to %s.', message))
        else
            windower.add_to_chat(123, message)
        end
        return
    end

    if command == 'reload' then
      windower.send_command('lua reload ezhud')
    end
end)

local hud_state = {
    visible = nil,
}

local function should_show_ui()
    local info = windower.ffxi.get_info()
    if not info or not info.logged_in then
        return false
    end

    local player = windower.ffxi.get_player()
    if not player then
        return false
    end

    if player.status == 4 then
        return false
    end

    local party = windower.ffxi.get_party()
    if not party then
        return false
    end

    local self_entry = party.p0 or party[0]
    if not self_entry or self_entry.hpp == nil then
        return false
    end

    return true
end

local function update_ui_visibility()
    local should_show = should_show_ui()

    if should_show ~= hud_state.visible then
        hud_state.visible = should_show

        if ezparty.set_visible then
            ezparty.set_visible(should_show)
        end
        if ezmount.set_visible then
            ezmount.set_visible(should_show)
        end
        if ezcastbar.set_visible then
            ezcastbar.set_visible(should_show)
        end
    end

    return hud_state.visible
end

-- Prerender loop
windower.register_event('prerender', function()
    if update_ui_visibility() then
        ezparty.update()
        ezcastbar.update()
    end
end)
