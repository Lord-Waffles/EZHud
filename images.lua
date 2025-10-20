--[[
    A library to facilitate image primitive creation and manipulation.
]]

require('EZParty')

local table = require('table')
local math = require('math')

local images = {}
local meta = {}

saved_images = {}
local dragged

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

_libs = _libs or {}
_libs.images = images

_meta = _meta or {}
_meta.Image = _meta.Image or {}
_meta.Image.__class = 'Image'
_meta.Image.__index = images

local set_value = function(t, key, value)
    local m = meta[t]
    m.values[key] = value
    m.images[key] = value ~= nil and (m.formats[key] and m.formats[key]:format(value) or tostring(value)) or m.defaults[key]
end

_meta.Image.__newindex = function(t, k, v)
    set_value(t, k, v)
    t:update()
end

--[[
    Local variables
]]

local default_settings = {}
default_settings.pos = {}
default_settings.pos.x = 0
default_settings.pos.y = 0
default_settings.visible = true
default_settings.color = {}
default_settings.color.alpha = 255
default_settings.color.red = 255
default_settings.color.green = 255
default_settings.color.blue = 255
default_settings.size = {}
default_settings.size.width = 0
default_settings.size.height = 0
default_settings.texture = {}
default_settings.texture.path = ''
default_settings.texture.fit = true
default_settings.repeatable = {}
default_settings.repeatable.x = 1
default_settings.repeatable.y = 1
default_settings.draggable = true

math.randomseed(os.clock())

local amend
amend = function(settings, defaults)
    for key, val in pairs(defaults) do
        if type(val) == 'table' then
            settings[key] = amend(settings[key] or {}, val)
        elseif settings[key] == nil then
            settings[key] = val
        end
    end

    return settings
end

local call_events = function(t, event, ...)
    if not meta[t].events[event] then
        return
    end

    -- Trigger registered post-reload events
    for _, event in ipairs(meta[t].events[event]) do
        event(t, meta[t].root_settings)
    end
end

local apply_settings = function(_, t, settings)
    settings = settings or meta[t].settings
    images.pos(t, settings.pos.x, settings.pos.y)
    images.visible(t, meta[t].status.visible)
    images.alpha(t, settings.color.alpha)
    images.color(t, settings.color.red, settings.color.green, settings.color.blue)
    images.size(t, settings.size.width, settings.size.height)
    images.fit(t, settings.texture.fit)
    images.path(t, settings.texture.path)
    images.repeat_xy(t, settings.repeatable.x, settings.repeatable.y)
    images.draggable(t, settings.draggable)

    call_events(t, 'reload')
end

function images.new(str, settings, root_settings)
    if type(str) ~= 'string' then
        str, settings, root_settings = '', str, settings
    end

    -- Sets the settings table to the provided settings, if not separately provided and the settings are a valid settings table
    if not _libs.config then
        root_settings = nil
    else
        root_settings =
            root_settings and class(root_settings) == 'settings' and
                root_settings
            or settings and class(settings) == 'settings' and
                settings
            or
                nil
    end

    t = {}
    local m = {}
    meta[t] = m
    m.name = (_addon and _addon.name or 'image') .. '_gensym_' .. tostring(t):sub(8) .. '_%.8x':format(16^8 * math.random()):sub(3)
    m.settings = settings or {}
	m.layer = (settings and settings.layer) or 1
	m.group = (settings and settings.group) or nil
    m.status = m.status or {visible = false, image = {}}
    m.root_settings = root_settings
    m.base_str = str

    m.events = {}

    m.keys = {}
    m.values = {}
    m.imageorder = {}
    m.defaults = {}
    m.formats = {}
    m.images = {}

    windower.prim.create(m.name)

    amend(m.settings, default_settings)
    if m.root_settings then
        config.save(m.root_settings)
    end

    if _libs.config and m.root_settings and settings then
        _libs.config.register(m.root_settings, apply_settings, t, settings)
    else
        apply_settings(_, t, settings)
    end

    -- Cache for deletion
    table.insert(saved_images, 1, t)

    return setmetatable(t, _meta.Image)
end

function images.update(t, attr)
    attr = attr or {}
    local m = meta[t]

    -- Add possibly new keys
    for key, value in pairs(attr) do
        m.keys[key] = true
    end

    -- Update all image segments
    for key in pairs(m.keys) do
        set_value(t, key, attr[key] == nil and m.values[key] or attr[key])
    end
end

function images.clear(t)
    local m = meta[t]
    m.keys = {}
    m.values = {}
    m.imageorder = {}
    m.images = {}
    m.defaults = {}
    m.formats = {}
end

-- Makes the primitive visible
function images.show(t)
    windower.prim.set_visibility(meta[t].name, true)
    meta[t].status.visible = true
end

-- Makes the primitive invisible
function images.hide(t)
    windower.prim.set_visibility(meta[t].name, false)
    meta[t].status.visible = false
end

-- Returns whether or not the image object is visible
function images.visible(t, visible)
    local m = meta[t]
    if visible == nil then
        return m.status.visible
    end

    windower.prim.set_visibility(m.name, visible)
    m.status.visible = visible
end

--[[
    The following methods all either set the respective values or return them, if no arguments to set them are provided.
]]

function images.pos(t, x, y)
    local m = meta[t]
    if x == nil then
        return m.settings.pos.x, m.settings.pos.y
    end

    windower.prim.set_position(m.name, x, y)
    m.settings.pos.x = x
    m.settings.pos.y = y
end

function images.pos_x(t, x)
    if x == nil then
        return meta[t].settings.pos.x
    end

    t:pos(x, meta[t].settings.pos.y)
end

function images.pos_y(t, y)
    if y == nil then
        return meta[t].settings.pos.y
    end

    t:pos(meta[t].settings.pos.x, y)
end

function images.size(t, width, height)
    local m = meta[t]
    if width == nil then
        return m.settings.size.width, m.settings.size.height
    end

    windower.prim.set_size(m.name, width, height)
    m.settings.size.width = width
    m.settings.size.height = height
end

function images.width(t, width)
    if width == nil then
        return meta[t].settings.size.width
    end

    t:size(width, meta[t].settings.size.height)
end

function images.height(t, height)
    if height == nil then
        return meta[t].settings.size.height
    end

    t:size(meta[t].settings.size.width, height)
end

function images.path(t, path)
    if path == nil then
        return meta[t].settings.texture.path
    end

    windower.prim.set_texture(meta[t].name, path)
    meta[t].settings.texture.path = path
end

function images.fit(t, fit)
    if fit == nil then
        return meta[t].settings.texture.fit
    end

    windower.prim.set_fit_to_texture(meta[t].name, fit)
    meta[t].settings.texture.fit = fit
end

function images.repeat_xy(t, x, y)
    local m = meta[t]
    if x == nil then
        return m.settings.repeatable.x, m.settings.repeatable.y
    end

    windower.prim.set_repeat(m.name, x, y)
    m.settings.repeatable.x = x
    m.settings.repeatable.y = y
end

function images.draggable(t, drag)
    if drag == nil then
        return meta[t].settings.draggable
    end

    meta[t].settings.draggable = drag
end

function images.color(t, red, green, blue)
    local m = meta[t]
    if red == nil then
        return m.settings.color.red, m.settings.color.green, m.settings.color.blue
    end

    windower.prim.set_color(m.name, m.settings.color.alpha, red, green, blue)
    m.settings.color.red = red
    m.settings.color.green = green
    m.settings.color.blue = blue
end

function images.alpha(t, alpha)
    local m = meta[t]
    if alpha == nil then
        return m.settings.color.alpha
    end

    windower.prim.set_color(m.name, alpha, m.settings.color.red, m.settings.color.green, m.settings.color.blue)
    m.settings.color.alpha = alpha
end

-- Sets/returns image transparency. Based on percentage values, with 1 being fully transparent, while 0 is fully opaque.
function images.transparency(t, alpha)
    local m = meta[t]
    if alpha == nil then
        return 1 - m.settings.color.alpha/255
    end

    alpha = math.floor(255*(1-alpha))
    windower.prim.set_color(m.name, alpha, m.settings.color.red, m.settings.color.green, m.settings.color.blue)
    m.settings.color.alpha = alpha
end

-- Returns true if the coordinates are currently over the image object
function images.hover(t, x, y)
    if not t:visible() then
        return false
    end

    local start_pos_x, start_pos_y = t:pos()
    local end_pos_x, end_pos_y = t:get_extents()

    return (start_pos_x <= x and x <= end_pos_x
        or start_pos_x >= x and x >= end_pos_x)
    and (start_pos_y <= y and y <= end_pos_y
        or start_pos_y >= y and y >= end_pos_y)
		
end

function images.destroy(t)
    for i, t_needle in ipairs(saved_images) do
        if t == t_needle then
            table.remove(saved_images, i)
            break
        end
    end
    windower.prim.delete(meta[t].name)
    meta[t] = nil
end

function images.get_extents(t)
    local m = meta[t]
    
    local ext_x = m.settings.pos.x + m.settings.size.width
    local ext_y = m.settings.pos.y + m.settings.size.height

    return ext_x, ext_y
end

-- Handle drag and drop (group-aware, exclude lower layers than clicked)
windower.register_event('mouse', function(type, x, y, delta, blocked)
    addon_settings = config.load()
    if blocked then
        return
    end

    -- Mouse drag (move while button down)
    if type == 0 then
        if dragged then
            -- Move every item in this drag group using stored offsets
            for _, entry in ipairs(dragged.items) do
                local t = entry.t
                local ox = entry.ox
                local oy = entry.oy
                t:pos(x - dragged.cursor_dx + ox, y - dragged.cursor_dy + oy)
            end
            return true
        end

    -- Mouse left click (start dragging)
    elseif type == 1 then
        for i, t in ipairs(saved_images) do
            local m = meta[t]
            if m and m.settings.draggable and t:hover(x, y) then
                local clicked_layer = m.layer or 1
                local group_id = m.group

                -- Collect group members, but only those in layers >= clicked_layer
                local group_items = {}
                if group_id ~= nil then
                    for _, s in ipairs(saved_images) do
                        local ms = meta[s]
                        if ms and ms.group == group_id and (ms.layer or 1) >= clicked_layer then
                            table.insert(group_items, s)
                        end
                    end
                else
                    group_items = { t }
                end

                -- Remove group members from saved_images so we can reinsert them in the new order
                local temp_saved = {}
                for _, s in ipairs(saved_images) do
                    local keep = true
                    for _, g in ipairs(group_items) do
                        if s == g then
                            keep = false
                            break
                        end
                    end
                    if keep then
                        table.insert(temp_saved, s)
                    end
                end
                saved_images = temp_saved

                -- Build a layer map for these group_items and determine layer order (ascending)
                local layer_map = {}
                local layer_order = {}
                for _, s in ipairs(group_items) do
                    local ms = meta[s]
                    local layer = ms and (ms.layer or 1) or 1
                    layer_map[layer] = layer_map[layer] or {}
                    table.insert(layer_map[layer], s)
                    local found = false
                    for _, v in ipairs(layer_order) do if v == layer then found = true; break end end
                    if not found then table.insert(layer_order, layer) end
                end
                table.sort(layer_order) -- ascending

                -- Only process layers that are >= clicked_layer (I already filtered this), in ascending order
                local process_layers = {}
                for _, l in ipairs(layer_order) do
                    if l >= clicked_layer then
                        table.insert(process_layers, l)
                    end
                end

                -- Recreate primitives in ascending layer order (clicked layer first, then higher layers),
                -- so higher-layer items get created last and therefore draw on top.
                local clicked_base_x, clicked_base_y = t:pos()
                for _, layer in ipairs(process_layers) do
                    local items = layer_map[layer] or {}
                    for _, s in ipairs(items) do
                        local ms = meta[s]
                        if ms then
							-- My attempt to avoid the weird scaling bug by storing the settings locally in this loop before deletion
							-- and use them to re-create the image
							local cur_x, cur_y = s:pos()
							local cur_w, cur_h = s:size()
							local cur_path = ms.settings.texture.path
							local r, g, b = ms.settings.color.red, ms.settings.color.green, ms.settings.color.blue
							local a = ms.settings.color.alpha
							local vis = ms.status.visible
							
							if ms.layer == 2 and s.scaled_size then
								cur_w, cur_h = s.scaled_size.width, s.scaled_size.height
							end
						
                            windower.prim.delete(ms.name)
                            windower.prim.create(ms.name)

                            s:pos(cur_x, cur_y)
							
							if s.scaled_size then
								s:size(s.scaled_size.width, s.scaled_size.height)
							else
								s:size(cur_w, cur_h)
							end
							
							s:path(cur_path)
							s:color(r, g, b)
							s:alpha(a)
							s:visible(vis)

                            -- Insert at front to mark newest (drawn on top among saved_images)
                            table.insert(saved_images, 1, s)
                        end
                    end
                end

                -- Build dragged table storing per-item offsets (relative to clicked image)
                local cursor_dx = x - clicked_base_x
                local cursor_dy = y - clicked_base_y
                local dragged_items = {}
                for _, s in ipairs(group_items) do
                    local ms = meta[s]
                    if ms then
                        local ox = ms.settings.pos.x - clicked_base_x
                        local oy = ms.settings.pos.y - clicked_base_y
                        table.insert(dragged_items, { t = s, ox = ox, oy = oy })
                    end
                end

                dragged = {
                    image = t,
                    items = dragged_items,
                    cursor_dx = cursor_dx,
                    cursor_dy = cursor_dy,
                    group = group_id,
                    layer = clicked_layer
                }

                return true
            end
        end

    -- Mouse left release (stop dragging)
    elseif type == 2 then
		if dragged then
			-- Snap-to-slot logic (safe)
			local ok, err = pcall(function()
				local ezparty = require('EZParty')
				local slots = ezparty and ezparty.slot_position
				if dragged.group and slots then
					local dragged_meta = meta[dragged.image]
					local old_slot = dragged_meta.group
					local new_slot = nil

					-- Center of dragged panel
					local px, py = dragged.image:pos()
					local pw, ph = dragged.image:size()
					local cx, cy = px + pw / 2, py + ph / 2

					-- Find frame under cursor
					local ezparty = require('EZParty')
					local frames = ezparty and ezparty.player_frame or {}
					for i, frame in ipairs(frames) do
						local fx, fy = frame:pos()
						local fw, fh = frame:size()
						if cx >= fx and cx <= fx + fw and cy >= fy and cy <= fy + fh then
							new_slot = i
							break
						end
					end


					if new_slot and new_slot ~= old_slot then
						-- Move the panel currently at target slot back to old_slot
						for _, s in ipairs(saved_images) do
							local ms = meta[s]
							if ms and ms.group == new_slot and ms.layer == 2 then
								local ox, oy = slots[old_slot].x, slots[old_slot].y
								s:pos(ox, oy)
								ms.settings.pos.x, ms.settings.pos.y = ox, oy
								ms.group = old_slot
								break
							end
						end

						-- Snap dragged group to target slot
						local nx, ny = slots[new_slot].x, slots[new_slot].y
						local base_x, base_y = meta[dragged.image].settings.pos.x, meta[dragged.image].settings.pos.y

						for _, entry in ipairs(dragged.items) do
							local s = entry.t
							local ms = meta[s]
							local ox = ms.settings.pos.x - base_x
							local oy = ms.settings.pos.y - base_y
							s:pos(nx + ox, ny + oy)
							ms.settings.pos.x, ms.settings.pos.y = nx + ox, ny + oy
							ms.group = new_slot
						end
						dragged_meta.group = new_slot
					else
						-- Snap back to old slot
						local ox, oy = slots[dragged.group].x, slots[dragged.group].y
						local base_x, base_y = meta[dragged.image].settings.pos.x, meta[dragged.image].settings.pos.y
						for _, entry in ipairs(dragged.items) do
							local s = entry.t
							local ms = meta[s]
							local rx = ox + (ms.settings.pos.x - base_x)
							local ry = oy + (ms.settings.pos.y - base_y)
							s:pos(rx, ry)
							ms.settings.pos.x, ms.settings.pos.y = rx, ry
						end
					end
				end

				-- Persist new positions
				for _, entry in ipairs(dragged.items) do
					local s = entry.t
					local ms = meta[s]
					if ms and ms.root_settings then
						ms.settings.pos.x, ms.settings.pos.y = s:pos()
						config.save(ms.root_settings)
					end
				end
			end)

			-- Always clear drag, even if snapping threw a fit and broke
			dragged = nil
			return true
		end
	end
    return false
end)



-- Can define functions to execute every time the settings are reloaded
function images.register_event(t, key, fn)
    if not events[key] then
        error('Event %s not available for text objects.':format(key))
        return
    end

    local m = meta[t]
    m.events[key] = m.events[key] or {}
    m.events[key][#m.events[key] + 1] = fn
    return #m.events[key]
end

function images.unregister_event(t, key, fn)
    if not (events[key] and meta[t].events[key]) then
        return
    end

    if type(fn) == 'number' then
        table.remove(meta[t].events[key], fn)
    else
        for index, event in ipairs(meta[t].events[key]) do
            if event == fn then
                table.remove(meta[t].events[key], index)
                return
            end
        end
    end
end

-- Expose Meta because i'm having so many bugs its not funny and idk maybe this will be useful
images._meta = meta

return images

--[[
Copyright © 2015, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]