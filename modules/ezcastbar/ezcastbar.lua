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
local resources = require('resources')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

local DEFAULT_FRAME_PATH = 'gui/ezcastbar/ezcastbar_bg.png'
local DEFAULT_BAR_PATH = 'gui/ezcastbar/ezcastbar_bar.png'
local LEGACY_FRAME_PATH = 'gui/ezcastbar/castbar_frame.png'
local LEGACY_BAR_PATH = 'gui/ezcastbar/castbar_bar.png'

local ACTION_CATEGORY_MAGIC_START = 8
local ACTION_CATEGORY_MAGIC_FINISH = 4
local ACTION_CATEGORY_JA_FINISH = 15
local ACTION_CATEGORY_WS_FINISH = 6
local INTERRUPT_PARAM = 28787

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

local DEFAULT_FRAME_SIZE = { width = 350, height = 13 }
local DEFAULT_BAR_SIZE = { width = 346, height = 9 }
local DEFAULT_BAR_OFFSET = { x = 2, y = 2 }
local DEFAULT_FADE_DURATION = 0.6
local LABEL_OFFSET_Y = 24
local FEEDBACK_OFFSET_Y = 18
local FEEDBACK_FADE_DURATION = 1.0
local FADE_HOLD_DURATION = 0.2

local DEFAULT_TEXT_COLOR = { red = 120, green = 210, blue = 255 }
local SUCCESS_TEXT_COLOR = { red = 140, green = 255, blue = 180 }
local INTERRUPT_TEXT_COLOR = { red = 255, green = 145, blue = 145 }
local SUCCESS_BAR_COLOR = { red = 120, green = 255, blue = 170 }
local INTERRUPT_BAR_COLOR = { red = 255, green = 120, blue = 120 }
local FEEDBACK_TEXT_COLOR = { red = 255, green = 230, blue = 120 }
local WHITE = { red = 255, green = 255, blue = 255 }

local state = {
    addon_settings = nil,
    settings = nil,
    enabled = false,
    suspended = false,
    frame = nil,
    bar = nil,
    label = nil,
    feedback_label = nil,
    events = {},
    current_cast = nil,
    player_id = nil,
    dimensions = {
        width = DEFAULT_FRAME_SIZE.width,
        height = DEFAULT_FRAME_SIZE.height,
    },
    bar_dimensions = {
        width = DEFAULT_BAR_SIZE.width,
        height = DEFAULT_BAR_SIZE.height,
    },
    bar_offset = {
        x = DEFAULT_BAR_OFFSET.x,
        y = DEFAULT_BAR_OFFSET.y,
    },
    label_offset = LABEL_OFFSET_Y,
    feedback_offset = FEEDBACK_OFFSET_Y,
    position = { x = 0, y = 0 },
    colors = {
        bar = { red = WHITE.red, green = WHITE.green, blue = WHITE.blue },
        label = {
            red = DEFAULT_TEXT_COLOR.red,
            green = DEFAULT_TEXT_COLOR.green,
            blue = DEFAULT_TEXT_COLOR.blue,
        },
        feedback = {
            red = FEEDBACK_TEXT_COLOR.red,
            green = FEEDBACK_TEXT_COLOR.green,
            blue = FEEDBACK_TEXT_COLOR.blue,
        },
    },
    feedback = nil,
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
    if state.feedback_label and state.feedback_label.destroy then
        state.feedback_label:destroy()
    end

    state.frame = nil
    state.bar = nil
    state.label = nil
    state.feedback_label = nil
    state.feedback = nil
end

local function file_exists(path)
    if not path or path == '' then
        return false
    end

    local file, _ = io.open(windower.addon_path .. path, 'rb')
    if file then
        file:close()
        return true
    end
    return false
end

local function resolve_texture_path(requested, default_path, legacy_path)
    if requested and requested ~= '' and file_exists(requested) then
        return requested
    end

    if legacy_path and requested == legacy_path and file_exists(default_path) then
        return default_path
    end

    if default_path and default_path ~= '' and file_exists(default_path) then
        return default_path
    end

    -- Fallback to the requested value even if missing so users notice the issue.
    return requested or default_path or ''
end

local function resolve_spell_from_action(act)
    if not act then
        return nil
    end

    local function lookup(id)
        id = tonumber(id)
        if not id or id == 0 then
            return nil
        end
        return resources.spells[id]
    end

    local spell = lookup(act.param)
    if spell then
        return spell
    end

    local targets = act.targets
    if not targets then
        return nil
    end

    for _, target in ipairs(targets) do
        local actions = target.actions
        if actions then
            for _, entry in ipairs(actions) do
                spell = lookup(entry.param or entry.message_param or entry.id)
                if spell then
                    return spell
                end
            end
        end
    end

    return nil
end

local function copy_color(color)
    if not color then
        return { red = 255, green = 255, blue = 255 }
    end

    return {
        red = color.red or 255,
        green = color.green or 255,
        blue = color.blue or 255,
    }
end

local function apply_bar_color(color)
    if not state.bar or not state.bar.color then
        return
    end

    color = copy_color(color)
    state.bar:color(color.red, color.green, color.blue)
    state.colors.bar = color
end

local function apply_label_color(color)
    if not state.label or not state.label.color then
        return
    end

    color = copy_color(color)
    state.label:color(color.red, color.green, color.blue)
    state.colors.label = color
end

local function apply_feedback_color(color)
    if not state.feedback_label or not state.feedback_label.color then
        return
    end

    color = copy_color(color or FEEDBACK_TEXT_COLOR)
    state.feedback_label:color(color.red, color.green, color.blue)
    state.colors.feedback = color
end

local function set_alpha(alpha)
    alpha = clamp(alpha or 1, 0, 1)
    local value = math.floor((alpha * 255) + 0.5)

    if state.frame and state.frame.alpha then
        state.frame:alpha(value)
    end
    if state.bar and state.bar.alpha then
        state.bar:alpha(value)
    end
    if state.label and state.label.alpha then
        state.label:alpha(value)
    end
end

local function reset_visual_state()
    apply_bar_color(WHITE)
    apply_label_color(DEFAULT_TEXT_COLOR)
    set_alpha(1)
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
    if state.feedback_label and state.feedback_label.hide then
        state.feedback_label:hide()
    end
end

local function clear_feedback()
    state.feedback = nil
    if state.feedback_label then
        if state.feedback_label.text then
            state.feedback_label:text('')
        end
        if state.feedback_label.alpha then
            state.feedback_label:alpha(0)
        end
        if state.feedback_label.hide then
            state.feedback_label:hide()
        end
    end
end

local function clear_cast()
    reset_visual_state()
    state.current_cast = nil
    clear_feedback()
    hide_objects()
end

local function ensure_player_id()
    local player = windower.ffxi.get_player()
    state.player_id = player and player.id or nil
end

local function ensure_objects()
    if not state.frame then
        state.frame = images.new({
            size = { width = 1, height = 1 },
            texture = { path = '' },
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
            draggable = false,
            visible = false,
            priority = 8,
        })
    end

    if not state.bar then
        state.bar = images.new({
            size = { width = 1, height = 1 },
            texture = { path = '' },
            color = { red = 255, green = 255, blue = 255, alpha = 255 },
            draggable = false,
            visible = false,
            priority = 9,
        })
    end

    if not state.label then
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
            state.label:alignment('left')
        end
        if state.label.right_justified then
            state.label:right_justified(false)
        end
        if state.label.bottom_justified then
            state.label:bottom_justified(false)
        end
        if state.label.priority then
            state.label:priority(10)
        end
        apply_label_color(DEFAULT_TEXT_COLOR)
        state.label:hide()
    end

    if not state.feedback_label then
        state.feedback_label = texts.new('', {
            font = 'Arial',
            size = 12,
            bold = true,
            draggable = false,
            bg = { alpha = 0 },
            flags = { right = false, bottom = false },
            stroke = { width = 2, alpha = 160 },
        })
        if state.feedback_label.alignment then
            state.feedback_label:alignment('left')
        end
        if state.feedback_label.right_justified then
            state.feedback_label:right_justified(false)
        end
        if state.feedback_label.bottom_justified then
            state.feedback_label:bottom_justified(false)
        end
        if state.feedback_label.priority then
            state.feedback_label:priority(10)
        end
        apply_feedback_color(FEEDBACK_TEXT_COLOR)
        state.feedback_label:hide()
    end
end

local function resolve_dimensions(config)
    config = config or {}
    local size = config.size or {}

    local explicit_scale = tonumber(config.scale)
    local width_config = tonumber(size.width) or tonumber(size[1])
    local height_config = tonumber(size.height) or tonumber(size[2])

    local scale = explicit_scale
    if not scale or scale <= 0 then
        if width_config and width_config > 0 then
            scale = width_config / DEFAULT_FRAME_SIZE.width
        elseif height_config and height_config > 0 then
            scale = height_config / DEFAULT_FRAME_SIZE.height
        end
    end

    if not scale or scale <= 0 then
        scale = 1
    end

    scale = clamp(scale, 0.25, 5)

    local width = math.floor((DEFAULT_FRAME_SIZE.width * scale) + 0.5)
    local height = math.floor((DEFAULT_FRAME_SIZE.height * scale) + 0.5)

    local scale_x = width / DEFAULT_FRAME_SIZE.width
    local scale_y = height / DEFAULT_FRAME_SIZE.height

    state.dimensions.width = width
    state.dimensions.height = height
    state.bar_dimensions.width = math.max(1, math.floor((DEFAULT_BAR_SIZE.width * scale_x) + 0.5))
   state.bar_dimensions.height = math.max(1, math.floor((DEFAULT_BAR_SIZE.height * scale_y) + 0.5))
   state.bar_offset.x = math.floor((DEFAULT_BAR_OFFSET.x * scale_x) + 0.5)
   state.bar_offset.y = math.floor((DEFAULT_BAR_OFFSET.y * scale_y) + 0.5)
   state.label_offset = math.max(1, math.floor((LABEL_OFFSET_Y * scale_y) + 0.5))
    state.feedback_offset = math.max(1, math.floor((FEEDBACK_OFFSET_Y * scale_y) + 0.5))

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
    local base_x = math.floor(((screen_w - width) / 2) + 0.5)
    local base_y = math.floor(((screen_h * (2 / 3)) - (height / 2)) + 0.5)

    if screen_h > 0 then
        base_y = clamp(base_y, 0, screen_h - height)
    end

    local pos_x = math.floor(base_x + offset_x + 0.5)
    local pos_y = math.floor(base_y + offset_y + 0.5)

    return pos_x, pos_y
end

local function apply_visual_settings(config)
    ensure_objects()

    local width, height = resolve_dimensions(config)
    local pos_x, pos_y = resolve_position(config, width, height)

    local frame_path = resolve_texture_path(config.image_frame, DEFAULT_FRAME_PATH, LEGACY_FRAME_PATH)
    local bar_path = resolve_texture_path(config.image_bar, DEFAULT_BAR_PATH, LEGACY_BAR_PATH)

    if state.settings then
        state.settings.image_frame = frame_path
        state.settings.image_bar = bar_path
    end

    if state.frame.path and frame_path and frame_path ~= '' then
        state.frame:path(windower.addon_path .. frame_path)
    end
    state.frame:size(width, height)
    state.frame:pos(pos_x, pos_y)
    state.frame:hide()

    if state.bar.path and bar_path and bar_path ~= '' then
        state.bar:path(windower.addon_path .. bar_path)
    end
    state.bar:size(state.bar_dimensions.width, state.bar_dimensions.height)
    state.bar:pos(pos_x + state.bar_offset.x, pos_y + state.bar_offset.y)
    state.bar:hide()

    state.position.x = pos_x
    state.position.y = pos_y

    local scale_y = state.dimensions.height / DEFAULT_FRAME_SIZE.height

    if state.label then
        state.label:text('')
        if state.label.size then
            local font_size = math.max(12, math.floor((18 * scale_y) + 0.5))
            state.label:size(font_size)
        end
        if state.label.bold then
            state.label:bold(true)
        end
        state.label:pos(pos_x + state.bar_offset.x, pos_y - state.label_offset)
        state.label:hide()
    end

    if state.feedback_label then
        state.feedback_label:text('')
        if state.feedback_label.size then
            local font_size = math.max(12, math.floor((16 * scale_y) + 0.5))
            state.feedback_label:size(font_size)
        end
        if state.feedback_label.bold then
            state.feedback_label:bold(true)
        end
        state.feedback_label:pos(pos_x + state.bar_offset.x, pos_y + state.dimensions.height + state.feedback_offset)
        if state.feedback_label.alpha then
            state.feedback_label:alpha(0)
        end
        state.feedback_label:hide()
    end

    reset_visual_state()
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
    reset_visual_state()

    if state.label then
        state.label:text(name or '')
        if state.label.bold then
            state.label:bold(true)
        end
        state.label:pos(state.position.x + state.bar_offset.x, state.position.y - state.label_offset)
        state.label:show()
    end

    if state.frame and state.frame.show then
        state.frame:show()
    end
end

local function set_bar_progress(progress)
    if not state.bar then
        return
    end

    progress = clamp(progress or 0, 0, 1)
    local width = math.floor((state.bar_dimensions.width * progress) + 0.5)
    state.bar:pos(state.position.x + state.bar_offset.x, state.position.y + state.bar_offset.y)

    if width <= 0 then
        state.bar:size(1, state.bar_dimensions.height)
        if state.bar.hide then
            state.bar:hide()
        end
        return
    end

    state.bar:size(width, state.bar_dimensions.height)
    if state.bar.show then
        state.bar:show()
    end
end

local function show_feedback(message)
    if not message or message == '' then
        return
    end

    ensure_objects()

    local formatted = string.format('- %s -', message)
    state.feedback = {
        text = formatted,
        start_time = os.clock(),
        duration = FEEDBACK_FADE_DURATION,
        reason = message,
    }

    if state.feedback_label then
        state.feedback_label:text(formatted)
        apply_feedback_color(FEEDBACK_TEXT_COLOR)
        if state.feedback_label.bold then
            state.feedback_label:bold(true)
        end
        if state.feedback_label.pos then
            state.feedback_label:pos(
                state.position.x + state.bar_offset.x,
                state.position.y + state.dimensions.height + state.feedback_offset
            )
        end
        if state.feedback_label.alpha then
            state.feedback_label:alpha(255)
        end
        if state.feedback_label.show then
            state.feedback_label:show()
        end
    end
end

local function update_feedback()
    if not state.feedback then
        return
    end

    local label = state.feedback_label
    if not label then
        state.feedback = nil
        return
    end

    local duration = state.feedback.duration or FEEDBACK_FADE_DURATION
    if duration <= 0 then
        clear_feedback()
        return
    end

    if label.pos then
        label:pos(
            state.position.x + state.bar_offset.x,
            state.position.y + state.dimensions.height + state.feedback_offset
        )
    end

    local elapsed = os.clock() - (state.feedback.start_time or 0)
    if elapsed >= duration then
        clear_feedback()
        return
    end

    local alpha = clamp(1 - (elapsed / duration), 0, 1)
    if label.alpha then
        label:alpha(math.floor((alpha * 255) + 0.5))
    end
end

local function finish_cast(is_success)
    if not state.current_cast then
        return
    end

    local cast = state.current_cast
    if cast.phase == 'finishing' or cast.phase == 'interrupted' then
        if is_success and not cast.success then
            cast.success = true
            apply_bar_color(SUCCESS_BAR_COLOR)
            apply_label_color(SUCCESS_TEXT_COLOR)
        end
        return
    end

    cast.phase = 'finishing'
    cast.success = is_success and true or false
    cast.fade_start = os.clock()
    local configured_fade = (state.settings and tonumber(state.settings.fade_duration)) or DEFAULT_FADE_DURATION
    if cast.success then
        cast.fade_duration = configured_fade
        cast.fade_hold = FADE_HOLD_DURATION
    else
        cast.fade_duration = math.max(configured_fade, FEEDBACK_FADE_DURATION)
        cast.fade_hold = 0
    end

    set_bar_progress(1)
    set_alpha(1)

    if cast.success then
        apply_bar_color(SUCCESS_BAR_COLOR)
        apply_label_color(SUCCESS_TEXT_COLOR)
    else
        apply_bar_color(WHITE)
        apply_label_color(DEFAULT_TEXT_COLOR)
    end

    if state.frame and state.frame.show then
        state.frame:show()
    end
    if state.bar and state.bar.show then
        state.bar:show()
    end
    if state.label then
        state.label:show()
    end
end

local function start_cast(spell_id, spell_name, duration)
    if state.suspended then
        return
    end

    if not ensure_enabled() then
        return
    end

    duration = tonumber(duration) or 0
    if duration <= 0 then
        duration = 1
    end

    if state.current_cast then
        clear_cast()
    end

    local now = os.clock()
    state.current_cast = {
        spell_id = spell_id,
        name = spell_name or 'Casting',
        start_time = now,
        end_time = now + duration,
        duration = duration,
        phase = 'casting',
        success = false,
        fade_start = nil,
        fade_duration = nil,
        fade_hold = 0,
        feedback_reason = nil,
    }

    show_cast(state.current_cast.name)
    set_bar_progress(0)
end

local function interrupt_cast(reason)
    if not state.current_cast then
        return
    end

    local cast = state.current_cast
    if cast.phase == 'finishing' and cast.success then
        return
    end
    if cast.phase == 'interrupted' and cast.feedback_reason == reason then
        return
    end

    cast.phase = 'interrupted'
    cast.success = false
    cast.fade_start = os.clock()
    local configured_fade = (state.settings and tonumber(state.settings.fade_duration)) or DEFAULT_FADE_DURATION
    cast.fade_duration = math.max(configured_fade, FEEDBACK_FADE_DURATION)
    cast.fade_hold = 0
    cast.feedback_reason = reason

    set_alpha(1)
    apply_bar_color(INTERRUPT_BAR_COLOR)
    apply_label_color(INTERRUPT_TEXT_COLOR)

    if reason and reason ~= '' then
        show_feedback(reason)
    else
        show_feedback('Spell Interrupted')
    end

    if state.frame and state.frame.show then
        state.frame:show()
    end
    if state.bar and state.bar.show then
        state.bar:show()
    end
    if state.label then
        state.label:show()
    end
end

local function resolve_action_message_text(message_id)
    if not message_id then
        return nil
    end

    local entry = resources.action_messages[message_id]
    if not entry then
        return nil
    end

    local text = entry.en
    if type(text) == 'table' then
        text = text[1]
    end

    return text
end

local function classify_action_message(message_id)
    local text = resolve_action_message_text(message_id)
    if not text or text == '' then
        return nil
    end

    local lowered = text:lower()
    lowered = lowered:gsub('<[^>]+>', '')
    lowered = lowered:gsub('%s+', ' ')

    local contains_resist = lowered:find('resist') and not lowered:find('resistance')

    if contains_resist or lowered:find('resists') or lowered:find('resisted') or lowered:find('no effect') or lowered:find('fails to take effect') or lowered:find('is immune') then
        return 'resisted'
    end

    if lowered:find('unable to cast') or lowered:find('fails to cast') or lowered:find('cannot cast') or lowered:find('fails to activate') or lowered:find('too far away') or lowered:find('out of range') or lowered:find('no target') or lowered:find('insufficient') then
        return 'failed'
    end

    if lowered:find('interrupt') or lowered:find('canceled') or lowered:find('cancelled') then
        return 'interrupted'
    end

    return nil
end

local function determine_magic_finish_result(act)
    if not act or not act.targets then
        return nil
    end

    local result = nil

    for _, target in ipairs(act.targets) do
        local actions = target.actions
        if actions then
            for _, entry in ipairs(actions) do
                local classification = classify_action_message(entry.message)
                if classification == 'resisted' then
                    return 'resisted'
                elseif classification == 'failed' then
                    result = 'failed'
                elseif classification == 'interrupted' and result ~= 'failed' then
                    result = 'interrupted'
                end
            end
        end
    end

    return result
end

local function interrupt_reason_from_message(message_id)
    local classification = classify_action_message(message_id)
    if classification == 'failed' then
        return 'Spell failed to cast'
    end
    if classification == 'resisted' then
        return 'Spell was resisted'
    end
    return 'Spell Interrupted'
end

local function on_action(act)
    if state.suspended then
        return
    end

    if not state.player_id or not act then
        return
    end

    if act.actor_id ~= state.player_id then
        return
    end

    local category = act.category

    if category == ACTION_CATEGORY_MAGIC_START then
        if act.param == INTERRUPT_PARAM then
            interrupt_cast('Spell Interrupted')
            return
        end

        local spell = resolve_spell_from_action(act)
        if not spell then
            return
        end

        local duration = tonumber(spell.cast_time) or 0
        if duration > 10 then
            duration = duration / 60
        end

        start_cast(spell.id, spell.en, duration)
        return
    end

    if not state.current_cast then
        return
    end

    if category == ACTION_CATEGORY_MAGIC_FINISH then
        local result = determine_magic_finish_result(act)
        if result == 'resisted' then
            finish_cast(false)
            show_feedback('Spell was resisted')
            return
        elseif result == 'failed' then
            finish_cast(false)
            show_feedback('Spell failed to cast')
            return
        elseif result == 'interrupted' then
            interrupt_cast('Spell Interrupted')
            return
        end
        finish_cast(true)
        return
    end

    if category == ACTION_CATEGORY_JA_FINISH
        or category == ACTION_CATEGORY_WS_FINISH then
        finish_cast(true)
    end
end

local function on_action_message(target_id, actor_id, message_id)
    if state.suspended then
        return
    end

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
        interrupt_cast(interrupt_reason_from_message(message_id))
    end
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

function ezcastbar.set_visible(visible)
    local show = visible ~= false
    local suspend = not show

    if state.suspended == suspend then
        return
    end

    state.suspended = suspend

    if suspend then
        clear_cast()
        hide_objects()
    else
        ensure_player_id()
    end
end

function ezcastbar.update()
    if state.suspended then
        return
    end

    update_feedback()

    if not ensure_enabled() then
        return
    end

    local cast = state.current_cast
    if not cast then
        return
    end

    local now = os.clock()

    if cast.phase == 'casting' then
        local duration = cast.duration or 0
        if duration <= 0 then
            finish_cast(true)
            return
        end

        local elapsed = now - cast.start_time
        local progress = clamp(elapsed / duration, 0, 1)
        set_bar_progress(progress)

        if elapsed >= duration then
            finish_cast(true)
        end
        return
    end

    if cast.phase == 'finishing' or cast.phase == 'interrupted' then
        local fade_start = cast.fade_start or now
        local fade_duration = cast.fade_duration or DEFAULT_FADE_DURATION
        local elapsed = now - fade_start
        local hold = cast.fade_hold or 0

        if elapsed < hold then
            set_alpha(1)
            return
        end

        local fade_elapsed = elapsed - hold

        if fade_duration <= 0 then
            clear_cast()
            return
        end

        if fade_elapsed >= fade_duration then
            clear_cast()
            return
        end

        local alpha = clamp(1 - (fade_elapsed / fade_duration), 0, 1)
        set_alpha(alpha)
    end
end

function ezcastbar.destroy()
    unregister_events()
    clear_cast()
    destroy_objects()
    state.suspended = false
end

function ezcastbar.show_test_bar(duration)
    if state.suspended or not ensure_enabled() then
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
