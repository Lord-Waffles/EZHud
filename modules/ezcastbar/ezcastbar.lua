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

local ezcastbar = {}

local images = require('images')
local texts = require('texts')
local packets = require('packets')
local resources = require('resources')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

local INTERRUPT_MESSAGES = {
    [62] = true, -- Unable to cast spells at this time.
    [63] = true, -- Unable to cast while asleep.
    [64] = true, -- Unable to cast while petrified.
    [65] = true, -- Unable to cast while silenced.
    [66] = true, -- Unable to cast while amnesic.
    [67] = true, -- Unable to cast while charmed.
    [71] = true, -- Unable to cast while stunned.
    [72] = true, -- Unable to cast while bound.
    [73] = true, -- Unable to cast while paralyzed.
    [74] = true, -- Unable to cast while deep sleep.
    [75] = true, -- Unable to cast while terrorized.
    [95] = true, -- Unable to cast while weakened.
    [420] = true, -- Unable to cast while weakened (trust variation).
    [421] = true,
    [422] = true,
    [423] = true,
    [556] = true, -- Unable to cast due to status.
    [557] = true,
    [558] = true,
    [559] = true,
    [560] = true,
    [561] = true,
    [562] = true,
    [563] = true,
    [564] = true,
    [565] = true,
    [566] = true,
    [567] = true,
    [568] = true,
    [569] = true,
    [570] = true,
    [571] = true,
    [572] = true,
    [573] = true,
    [574] = true,
    [575] = true,
    [576] = true,
    [577] = true,
    [578] = true,
    [579] = true,
    [280] = true, -- Spell canceled.
    [281] = true,
    [282] = true,
    [283] = true,
    [284] = true,
    [285] = true,
    [287] = true,
    [534] = true,
    [535] = true,
    [536] = true,
    [537] = true,
    [538] = true,
    [646] = true,
    [647] = true,
}

local state = {
    addon_settings = nil,
    settings = nil,
    enabled = false,
    frame = nil,
    bar = nil,
    label = nil,
    events = {},
    current_cast = nil,
    player_id = nil,
    dimensions = { width = 300, height = 25 },
    position = { x = 0, y = 0 },
}

local function clamp(value, minimum, maximum)
    if minimum and value < minimum then
        return minimum
    end
    if maximum and value > maximum then
        return maximum
    end
    return value
end

local function unregister_event(name)
    if state.events[name] then
        windower.unregister_event(state.events[name])
        state.events[name] = nil
    end
end

local function unregister_events()
    for name, id in pairs(state.events) do
        if id then
            windower.unregister_event(id)
        end
        state.events[name] = nil
    end
end

local function destroy_objects()
    if state.frame and state.frame.destroy then
        state.frame:destroy()
    end
    if state.bar and state.bar.destroy then
        state.bar:destroy()
    end
    if state.label and state.label.destroy then
        state.label:destroy()
    end

    state.frame = nil
    state.bar = nil
    state.label = nil
end

local function hide_objects()
    if state.bar and state.bar.hide then
        state.bar:hide()
    end
    if state.frame and state.frame.hide then
        state.frame:hide()
    end
    if state.label and state.label.hide then
        state.label:hide()
    end
end

local function clear_cast()
    state.current_cast = nil
    hide_objects()
end

local function ensure_player_id()
    local player = windower.ffxi.get_player()
    state.player_id = player and player.id or nil
end

local function ensure_objects()
    if state.frame and state.bar then
        return
    end

    state.frame = images.new({
        size = { width = 1, height = 1 },
        texture = { path = '' },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        draggable = false,
        visible = false,
    })

    state.bar = images.new({
        size = { width = 1, height = 1 },
        texture = { path = '' },
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        draggable = false,
        visible = false,
    })

    state.label = texts.new('', {
        font = 'Arial',
        size = 12,
        bold = true,
        draggable = false,
        bg = { alpha = 0 },
        flags = { right = false, bottom = false },
        stroke = { width = 2, alpha = 180 },
    })
    if state.label.alignment then
        state.label:alignment('center')
    end
    state.label:hide()
end

local function resolve_dimensions(config)
    local size = config.size or {}
    local width = tonumber(size.width) or tonumber(size[1]) or 300
    local height = tonumber(size.height) or tonumber(size[2]) or 25

    width = clamp(math.floor(width + 0.5), 50)
    height = clamp(math.floor(height + 0.5), 10)

    state.dimensions.width = width
    state.dimensions.height = height

    return width, height
end

local function resolve_position(config, width, height)
    local screen = windower.get_windower_settings() or {}
    local screen_w = tonumber(screen.ui_x_res) or 0
    local screen_h = tonumber(screen.ui_y_res) or 0

    local offset = config.offset or {}
    local offset_x = tonumber(offset.x) or tonumber(offset[1]) or 0
    local offset_y = tonumber(offset.y) or tonumber(offset[2]) or 0

    if math.abs(offset_x) <= 1 and math.abs(offset_y) <= 1 then
        local converted = ez.convert_to_screen_pixels({ x = offset_x, y = offset_y })
        offset_x = converted and converted.x or offset_x
        offset_y = converted and converted.y or offset_y
    end

    local pos_x = math.floor((screen_w / 2) - (width / 2) + offset_x + 0.5)
    local pos_y = math.floor((screen_h / 2) + offset_y + 0.5)

    return pos_x, pos_y
end

local function apply_visual_settings(config)
    ensure_objects()

    local width, height = resolve_dimensions(config)
    local pos_x, pos_y = resolve_position(config, width, height)

    local frame_path = config.image_frame or 'gui/ezcastbar/castbar_frame.png'
    local bar_path = config.image_bar or 'gui/ezcastbar/castbar_bar.png'

    if state.frame.path then
        state.frame:path(windower.addon_path .. frame_path)
    end
    state.frame:size(width, height)
    state.frame:pos(pos_x, pos_y)
    state.frame:hide()

    if state.bar.path then
        state.bar:path(windower.addon_path .. bar_path)
    end
    state.bar:size(1, height)
    state.bar:pos(pos_x, pos_y)
    state.bar:hide()

    state.position.x = pos_x
    state.position.y = pos_y

    if state.label then
        state.label:text('')
        state.label:pos(pos_x + width / 2, pos_y + (height / 2) - 10)
        state.label:hide()
    end
end

local function ensure_enabled()
    if not state.settings or state.settings.enable == false then
        clear_cast()
        return false
    end
    return true
end

local function show_cast(name)
    if not ensure_enabled() then
        return
    end

    ensure_objects()

    if state.frame and state.frame.show then
        state.frame:show()
    end
    if state.bar and state.bar.show then
        state.bar:show()
    end
    if state.label then
        state.label:text(name or '')
        state.label:show()
    end
end

local function finish_cast()
    clear_cast()
end

local function set_bar_progress(progress)
    if not state.bar then
        return
    end

    local width = clamp(progress, 0, 1) * state.dimensions.width
    local height = state.dimensions.height
    width = math.max(math.floor(width + 0.5), 1)

    state.bar:pos(state.position.x, state.position.y)
    state.bar:size(width, height)
end

local function start_cast(spell_id, spell_name, duration)
    if not ensure_enabled() then
        return
    end

    duration = tonumber(duration) or 0
    if duration <= 0 then
        duration = 1
    end

    local now = os.clock()
    state.current_cast = {
        spell_id = spell_id,
        name = spell_name or 'Casting',
        start_time = now,
        end_time = now + duration,
        duration = duration,
    }

    show_cast(state.current_cast.name)
    set_bar_progress(0)
end

local function interrupt_cast()
    clear_cast()
end

local function on_action(act)
    if not state.player_id or not act then
        return
    end

    if act.actor_id ~= state.player_id then
        return
    end

    if not state.current_cast then
        return
    end

    -- Categories for completed magic actions.
    if act.category == 8 or act.category == 15 or act.category == 6 then
        finish_cast()
    end
end

local function on_action_message(target_id, actor_id, message_id)
    if not state.player_id then
        return
    end

    if actor_id ~= state.player_id then
        return
    end

    if not state.current_cast then
        return
    end

    if INTERRUPT_MESSAGES[message_id] then
        interrupt_cast()
    end
end

local function on_outgoing_chunk(id, data)
    if id ~= 0x037 then
        return
    end

    if not ensure_enabled() then
        return
    end

    local packet = packets.parse('outgoing', data)
    if not packet or packet.id ~= 0x037 then
        return
    end

    local spell_id = packet.Spell or packet.SpellID or packet['Spell']
    if not spell_id then
        return
    end

    local spell = resources.spells[spell_id]
    local name = spell and spell.en or ('Spell #' .. tostring(spell_id))
    local duration = spell and spell.cast_time or 0

    -- Convert cast time from seconds*60 (resource units) to seconds when needed.
    if duration and duration > 0 and duration > 10 then
        duration = duration / 60
    end

    start_cast(spell_id, name, duration)
end

local function on_login()
    ensure_player_id()
    clear_cast()
end

local function on_logout()
    clear_cast()
end

local function on_zone_change()
    clear_cast()
end

local function update_events()
    unregister_events()

    if not ensure_enabled() then
        return
    end

    state.events.action = windower.register_event('action', on_action)
    state.events.action_message = windower.register_event('action message', on_action_message)
    state.events.outgoing = windower.register_event('outgoing chunk', on_outgoing_chunk)
    state.events.load = windower.register_event('load', on_login)
    state.events.login = windower.register_event('login', on_login)
    state.events.zone = windower.register_event('zone change', on_zone_change)
    state.events.logout = windower.register_event('logout', on_logout)
end

function ezcastbar.init(addon_settings)
    state.addon_settings = addon_settings
    state.settings = addon_settings and addon_settings.ezcastbar or nil
    state.enabled = state.settings and state.settings.enable ~= false

    ensure_player_id()

    if not ensure_enabled() then
        destroy_objects()
        unregister_events()
        return
    end

    clear_cast()
    apply_visual_settings(state.settings)
    update_events()
end

function ezcastbar.reload(addon_settings)
    ezcastbar.init(addon_settings or state.addon_settings)
end

function ezcastbar.update()
    if not state.current_cast or not ensure_enabled() then
        return
    end

    local now = os.clock()
    local cast = state.current_cast
    local duration = cast.duration or 0
    if duration <= 0 then
        finish_cast()
        return
    end

    if now >= cast.end_time then
        finish_cast()
        return
    end

    local progress = (now - cast.start_time) / duration
    set_bar_progress(progress)
end

function ezcastbar.destroy()
    unregister_events()
    clear_cast()
    destroy_objects()
end

function ezcastbar.show_test_bar(duration)
    if not ensure_enabled() then
        return false
    end

    duration = tonumber(duration) or 5
    if duration <= 0 then
        duration = 5
    end

    start_cast(0, 'Test Spell', duration)
    return true
end

return ezcastbar
