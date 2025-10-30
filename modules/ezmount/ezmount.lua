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

local ezmount = {}

-- Libs
local images = require('images')
local ez = require('core.ezfunctions')
require('tables')
require('strings')
require('math')

local HOVER_TEXTURE = 'gui/ezparty/ezmount_hover.png'
local PRESSED_TEXTURE = 'gui/ezparty/ezmount_click.png'
local TEXTURE_WIDTH = 290
local TEXTURE_HEIGHT = 337

local buttons = {
    player_one = {},
    player_two = {},
}

local last_frames = {
    player_one = nil,
    player_two = nil,
}

local addon_config
local mouse_event_id
local hovered_button
local pressed_button
local geometry_event_id

local function deepcopy(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deepcopy(v)
    end

    return copy
end

local function resolve_screen_dimensions()
    local settings = windower.get_windower_settings() or {}
    return settings.ui_x_res or 0, settings.ui_y_res or 0
end

local function compute_member_anchor(addon_settings, scale)
    if not addon_settings or not addon_settings.ezparty then
        return nil
    end

    local screen_w, screen_h = resolve_screen_dimensions()
    local layout = addon_settings.ezparty.layout or {}
    local spacing = math.floor(((layout.vertical_spacing or 50) * scale) + 0.5)

    local member_frame = addon_settings.ezparty.member_frame or {}
    local size = member_frame.size or {}
    local width = math.floor(((size.width or 0) * scale) + 0.5)
    local height = math.floor(((size.height or 0) * scale) + 0.5)

    local position_config = deepcopy(member_frame.pos or {})
    local base
    if not position_config or ((position_config.x or 0) == 0 and (position_config.y or 0) == 0) then
        base = {
            x = screen_w - width,
            y = screen_h - height - (height + spacing) * 4,
        }
    else
        base = ez.convert_to_screen_pixels(position_config) or { x = 0, y = 0 }
    end

    return {
        x = base.x or 0,
        y = base.y or 0,
        width = width,
        height = height,
        spacing = spacing,
    }
end

local function compute_player_frames(addon_settings)
    local frames = {}
    if not addon_settings or addon_settings.ezmount and addon_settings.ezmount.enable == false then
        return frames
    end

    if not addon_settings.ezparty or addon_settings.ezparty.enable == false then
        return frames
    end

    local scale = tonumber(addon_settings.ezparty.scale) or 1
    local screen_w, screen_h = resolve_screen_dimensions()
    local anchor = compute_member_anchor(addon_settings, scale)
    local player_frame = addon_settings.ezparty.player_frame or {}

    local one_config = deepcopy(player_frame.one and player_frame.one.pos or {})
    local one_size = player_frame.one and player_frame.one.size or {}
    local one_enabled = player_frame.one and player_frame.one.enable ~= false
    local one_base_width = tonumber(one_size.width) or 0
    local one_base_height = tonumber(one_size.height) or 0
    local one_width = math.floor(((one_base_width) * scale) + 0.5)
    local one_height = math.floor(((one_base_height) * scale) + 0.5)

    if one_enabled and one_width > 0 and one_height > 0 then
        if not one_config or ((one_config.x or 0) == 0 and (one_config.y or 0) == 0) then
            local anchor_y
            if anchor then
                anchor_y = anchor.y - (anchor.spacing or 0) - one_height
            else
                anchor_y = screen_h - one_height - ((anchor and anchor.spacing) or math.floor(32 * scale + 0.5)) * 5
            end

            frames.player_one = {
                x = screen_w - one_width,
                y = anchor_y,
                width = one_width,
                height = one_height,
                base_width = one_base_width,
                base_height = one_base_height,
                scale = scale,
            }
        else
            local pos = ez.convert_to_screen_pixels(one_config) or { x = 0, y = 0 }
            frames.player_one = {
                x = math.floor(pos.x or 0 + 0.5),
                y = math.floor(pos.y or 0 + 0.5),
                width = one_width,
                height = one_height,
                base_width = one_base_width,
                base_height = one_base_height,
                scale = scale,
            }
        end
    end

    local two_config = deepcopy(player_frame.two and player_frame.two.pos or {})
    local two_size = player_frame.two and player_frame.two.size or {}
    local two_enabled = player_frame.two and player_frame.two.enable ~= false
    local two_base_width = tonumber(two_size.width) or 0
    local two_base_height = tonumber(two_size.height) or 0
    local two_width = math.floor(((two_base_width) * scale) + 0.5)
    local two_height = math.floor(((two_base_height) * scale) + 0.5)

    if two_enabled and two_width > 0 and two_height > 0 then
        if not two_config or ((two_config.x or 0) == 0 and (two_config.y or 0) == 0) then
            frames.player_two = {
                x = math.floor(screen_w / 2 - two_width / 2 + 0.5),
                y = math.floor(screen_h - (screen_h / 4.3) + 0.5),
                width = two_width,
                height = two_height,
                base_width = two_base_width,
                base_height = two_base_height,
                scale = scale,
            }
        else
            local pos = ez.convert_to_screen_pixels(two_config) or { x = 0, y = 0 }
            frames.player_two = {
                x = math.floor(pos.x or 0 + 0.5),
                y = math.floor(pos.y or 0 + 0.5),
                width = two_width,
                height = two_height,
                base_width = two_base_width,
                base_height = two_base_height,
                scale = scale,
            }
        end
    end

    return frames
end

local function destroy_button(button)
    if not button then
        return
    end

    if button.hover and button.hover.destroy then
        button.hover:destroy()
    end
    if button.pressed and button.pressed.destroy then
        button.pressed:destroy()
    end

    button.hover = nil
    button.pressed = nil
    button.area = nil
    button.visible = false
end

local function destroy_all_buttons()
    destroy_button(buttons.player_one)
    destroy_button(buttons.player_two)

    hovered_button = nil
    pressed_button = nil
    last_frames.player_one = nil
    last_frames.player_two = nil
end

local function deactivate()
    if mouse_event_id then
        windower.unregister_event(mouse_event_id)
        mouse_event_id = nil
    end

    if geometry_event_id then
        windower.unregister_event(geometry_event_id)
        geometry_event_id = nil
    end

    destroy_all_buttons()
end

local function ensure_button_objects(button)
    if button.hover and button.pressed then
        return
    end

    button.hover = images.new({
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        size = { width = 1, height = 1 },
        texture = { path = HOVER_TEXTURE },
        visible = false,
        draggable = false,
    })

    button.pressed = images.new({
        color = { red = 255, green = 255, blue = 255, alpha = 255 },
        size = { width = 1, height = 1 },
        texture = { path = PRESSED_TEXTURE },
        visible = false,
        draggable = false,
    })

    button.hover:path(windower.addon_path .. HOVER_TEXTURE)
    button.pressed:path(windower.addon_path .. PRESSED_TEXTURE)

    button.hover:hide()
    button.pressed:hide()
end

local function apply_geometry(button, frame_info)
    if not button or not frame_info then
        return
    end

    ensure_button_objects(button)

    local frame_height = math.max(frame_info.height or 0, 1)
    local frame_width = math.max(frame_info.width or 0, 1)
    local base_height = math.max(frame_info.base_height or 0, 0)
    local base_width = math.max(frame_info.base_width or 0, 0)

    local scale_factor = 0
    if base_height > 0 then
        scale_factor = frame_height / base_height
    elseif base_width > 0 then
        scale_factor = frame_width / base_width
    end
    if scale_factor <= 0 then
        scale_factor = tonumber(frame_info.scale) or 1
    end
    if scale_factor <= 0 then
        scale_factor = frame_height / TEXTURE_HEIGHT
    end

    local button_width = math.max(math.floor(TEXTURE_WIDTH * scale_factor + 0.5), 1)
    local button_height = math.max(math.floor(TEXTURE_HEIGHT * scale_factor + 0.5), 1)

    local button_x = math.floor((frame_info.x or 0) + 0.5)
    local button_y = math.floor((frame_info.y or 0) + 0.5)

    button.area = {
        x = button_x,
        y = button_y,
        width = button_width,
        height = button_height,
    }

    button.hover:size(button_width, button_height)
    button.hover:pos(button_x, button_y)
    button.hover:hide()

    button.pressed:size(button_width, button_height)
    button.pressed:pos(button_x, button_y)
    button.pressed:hide()

    button.visible = true
end

local function point_in_area(x, y, area)
    if not area then
        return false
    end

    return x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height
end

local function set_hover(button)
    if hovered_button and hovered_button ~= button then
        if hovered_button.hover and hovered_button.hover.hide and hovered_button ~= pressed_button then
            hovered_button.hover:hide()
        end
    end

    hovered_button = button

    if hovered_button and hovered_button ~= pressed_button and hovered_button.hover then
        hovered_button.hover:show()
    end
end

local function clear_hover(button)
    if hovered_button == button then
        if hovered_button and hovered_button.hover and hovered_button ~= pressed_button then
            hovered_button.hover:hide()
        end
        hovered_button = nil
    end
end

local function trigger_mount()
    if not addon_config or not addon_config.ezmount then
        return
    end

    local mount_name = addon_config.ezmount.name
    if not mount_name or mount_name == '' then
        return
    end

    local safe_name = tostring(mount_name):gsub('%%', '%%%%')
    windower.send_command(('input /mount "%s"'):format(safe_name))
end

local function handle_mouse(type, x, y, _delta, _blocked)
    if not buttons.player_one.visible and not buttons.player_two.visible then
        return
    end

    x = x or 0
    y = y or 0

    if type == 0 or type == nil then
        local new_hover
        for _, button in ipairs({ buttons.player_one, buttons.player_two }) do
            if button.visible and button.area and point_in_area(x, y, button.area) then
                new_hover = button
                break
            end
        end

        if new_hover then
            set_hover(new_hover)
        else
            clear_hover(hovered_button)
        end
    elseif type == 1 then
        for _, button in ipairs({ buttons.player_one, buttons.player_two }) do
            if button.visible and button.area and point_in_area(x, y, button.area) then
                pressed_button = button
                if pressed_button.hover and pressed_button.hover.hide then
                    pressed_button.hover:hide()
                end
                if pressed_button.pressed and pressed_button.pressed.show then
                    pressed_button.pressed:show()
                end
                return true
            end
        end
    elseif type == 2 then
        if pressed_button then
            local was_pressed = pressed_button
            if was_pressed.pressed and was_pressed.pressed.hide then
                was_pressed.pressed:hide()
            end

            if point_in_area(x, y, was_pressed.area) then
                if was_pressed.hover and was_pressed.hover.show then
                    was_pressed.hover:show()
                end
                trigger_mount()
                pressed_button = nil
                return true
            end

            pressed_button = nil
            clear_hover(was_pressed)
        end
    end
end

local function frames_equal(a, b)
    if a == nil and b == nil then
        return true
    end
    if not a or not b then
        return false
    end

    return a.x == b.x
        and a.y == b.y
        and a.width == b.width
        and a.height == b.height
        and a.base_width == b.base_width
        and a.base_height == b.base_height
        and a.scale == b.scale
end

local function copy_frame(frame)
    if not frame then
        return nil
    end

    return {
        x = frame.x,
        y = frame.y,
        width = frame.width,
        height = frame.height,
        base_width = frame.base_width,
        base_height = frame.base_height,
        scale = frame.scale,
    }
end

local function apply_frame_positions(addon_settings)
    local frames = compute_player_frames(addon_settings)

    if frames.player_one then
        if not frames_equal(frames.player_one, last_frames.player_one) then
            apply_geometry(buttons.player_one, frames.player_one)
            last_frames.player_one = copy_frame(frames.player_one)
        end
    elseif last_frames.player_one then
        destroy_button(buttons.player_one)
        last_frames.player_one = nil
    end

    if frames.player_two then
        if not frames_equal(frames.player_two, last_frames.player_two) then
            apply_geometry(buttons.player_two, frames.player_two)
            last_frames.player_two = copy_frame(frames.player_two)
        end
    elseif last_frames.player_two then
        destroy_button(buttons.player_two)
        last_frames.player_two = nil
    end

    if (buttons.player_one.visible or buttons.player_two.visible) and not mouse_event_id then
        mouse_event_id = windower.register_event('mouse', handle_mouse)
    elseif not buttons.player_one.visible and not buttons.player_two.visible and mouse_event_id then
        windower.unregister_event(mouse_event_id)
        mouse_event_id = nil
    end
end

function ezmount.init(settings)
    addon_config = settings

    deactivate()

    if not settings or not settings.ezmount or settings.ezmount.enable == false then
        return
    end

    apply_frame_positions(settings)

    if not geometry_event_id then
        geometry_event_id = windower.register_event('prerender', function()
            if addon_config and addon_config.ezmount and addon_config.ezmount.enable ~= false then
                apply_frame_positions(addon_config)
            end
        end)
    end
end

function ezmount.destroy()
    deactivate()
end

return ezmount
