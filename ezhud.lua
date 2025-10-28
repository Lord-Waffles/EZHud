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
local texts = require('texts')
local images = require('images')
local ez = require('core.ezfunctions')
local ezparty = require('modules.ezparty.ezparty')
local ezdefaults = require('core.ezdefaults') or {}
require('tables')
require('strings')

-- Configure/load data/settings.xml
local addon_settings = config.load(ezdefaults)
config.save(addon_settings)

ezparty.init(addon_settings)

-- Run module inits on login
windower.register_event('login', function()
  ezparty.init(addon_settings)
end)


-- Addon command handler
windower.register_event('addon command', function(command)
    command = command:lower()

    if command == 'debug' then
            windower.add_to_chat(tostring(addon_settings))
        return
    end
end)

-- Prerender loop
windower.register_event('prerender', function()

end)