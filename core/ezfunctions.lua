--[[
        Copyright Ac 2025, Rook & Makto (Bahamut)
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
require('strings')
require('math')

local ezfunctions = {}

-- A function to convert the x, y co-ords of something into % of screen width, height
function ezfunctions.convert_to_screen_percent(tbl)
    if not tbl or type(tbl) ~= 'table' then
        return nil, 'Invalid table'
    end

    local windower_settings = windower.get_windower_settings()
    local screen_w = windower_settings.ui_x_res
    local screen_h = windower_settings.ui_y_res

    local key_x = tbl.x ~= nil and 'x' or (tbl.width and 'width' or nil)
    local key_y = tbl.y ~= nil and 'y' or (tbl.height and 'height' or nil)

    if key_x and screen_w and tbl[key_x] then
        tbl[key_x] = tbl[key_x] / screen_w
    end

    if key_y and screen_h and tbl[key_y] then
        tbl[key_y] = tbl[key_y] / screen_h
    end

    return tbl
end

-- a function that converts screen % to pixels 
function ezfunctions.convert_to_screen_pixels(tbl)
    if not tbl or type(tbl) ~= 'table' then
        return nil, 'Invalid table'
    end

    local windower_settings = windower.get_windower_settings()
    local screen_w = windower_settings.ui_x_res
    local screen_h = windower_settings.ui_y_res

    -- Determine axis keys
    local key_x = tbl.x ~= nil and 'x' or (tbl.width and 'width' or nil)
    local key_y = tbl.y ~= nil and 'y' or (tbl.height and 'height' or nil)

    if key_x and screen_w and tbl[key_x] then
        tbl[key_x] = tbl[key_x] * screen_w
    end

    if key_y and screen_h and tbl[key_y] then
        tbl[key_y] = tbl[key_y] * screen_h
    end

    return tbl
end

-- linearly interpolate between two numeric values
function ezfunctions.lerp(a, b, t)
    a = tonumber(a) or 0
    b = tonumber(b) or 0
    t = tonumber(t) or 0

    if t < 0 then
        t = 0
    elseif t > 1 then
        t = 1
    end

    return a + (b - a) * t
end

return ezfunctions
