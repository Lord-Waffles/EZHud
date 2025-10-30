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

-- Libs
require('tables')
require('strings')

local ezdefaults = {}

-- Set default module settings
-- EZ Party Default Settings
ezdefaults.ezparty = {}
-- ezdefaults.ezparty.reset = true
ezdefaults.ezparty.enable = true
ezdefaults.ezparty.scale = .6
ezdefaults.ezparty.layout = {}
ezdefaults.ezparty.layout.vertical_spacing = 32
ezdefaults.ezparty.layout.draggable = false

-- Party Player Frame Default Settings
ezdefaults.ezparty.player_frame = {}
ezdefaults.ezparty.player_frame.linked = true                             -- when true, player frame position is linked to member frames
ezdefaults.ezparty.player_frame.unique = true                             -- when true, player frame uses a unique image separate from member frames
ezdefaults.ezparty.player_frame.one = {}
ezdefaults.ezparty.player_frame.one.pos = {}
ezdefaults.ezparty.player_frame.one.pos.x = 0
ezdefaults.ezparty.player_frame.one.pos.y = 0
ezdefaults.ezparty.player_frame.one.visible = false
ezdefaults.ezparty.player_frame.one.color = {}
ezdefaults.ezparty.player_frame.one.color.alpha = 255
ezdefaults.ezparty.player_frame.one.color.red = 255
ezdefaults.ezparty.player_frame.one.color.green = 255
ezdefaults.ezparty.player_frame.one.color.blue = 255
ezdefaults.ezparty.player_frame.one.size = {}
ezdefaults.ezparty.player_frame.one.size.width = 730
ezdefaults.ezparty.player_frame.one.size.height = 150
ezdefaults.ezparty.player_frame.one.texture = {}
ezdefaults.ezparty.player_frame.one.texture.path = 'gui/ezparty/player_frame.png' 
ezdefaults.ezparty.player_frame.one.texture.fit = false
ezdefaults.ezparty.player_frame.one.repeatable = {}
ezdefaults.ezparty.player_frame.one.repeatable.x = 1
ezdefaults.ezparty.player_frame.one.repeatable.y = 1
ezdefaults.ezparty.player_frame.one.draggable = false
ezdefaults.ezparty.player_frame.one.enable = false
ezdefaults.ezparty.player_frame.two = {}
ezdefaults.ezparty.player_frame.two.pos = {}
ezdefaults.ezparty.player_frame.two.pos.x = 0
ezdefaults.ezparty.player_frame.two.pos.y = 0
ezdefaults.ezparty.player_frame.two.visible = false
ezdefaults.ezparty.player_frame.two.color = {}
ezdefaults.ezparty.player_frame.two.color.alpha = 255
ezdefaults.ezparty.player_frame.two.color.red = 255
ezdefaults.ezparty.player_frame.two.color.green = 255
ezdefaults.ezparty.player_frame.two.color.blue = 255
ezdefaults.ezparty.player_frame.two.size = {}
ezdefaults.ezparty.player_frame.two.size.width = 730
ezdefaults.ezparty.player_frame.two.size.height = 150
ezdefaults.ezparty.player_frame.two.texture = {}
ezdefaults.ezparty.player_frame.two.texture.path = 'gui/ezparty/player_frame.png'
ezdefaults.ezparty.player_frame.two.texture.fit = false
ezdefaults.ezparty.player_frame.two.repeatable = {}
ezdefaults.ezparty.player_frame.two.repeatable.x = 1
ezdefaults.ezparty.player_frame.two.repeatable.y = 1
ezdefaults.ezparty.player_frame.two.draggable = false
ezdefaults.ezparty.player_frame.two.enable = true

-- Member Frame Default Settings
ezdefaults.ezparty.member_frame = {}
ezdefaults.ezparty.member_frame.enable = true
ezdefaults.ezparty.member_frame.linked = true

--------
ezdefaults.ezparty.member_frame.pos = {}
ezdefaults.ezparty.member_frame.pos.x = 0
ezdefaults.ezparty.member_frame.pos.y = 0
ezdefaults.ezparty.member_frame.visible = false
ezdefaults.ezparty.member_frame.color = {}
ezdefaults.ezparty.member_frame.color.alpha = 255
ezdefaults.ezparty.member_frame.color.red = 255
ezdefaults.ezparty.member_frame.color.green = 255
ezdefaults.ezparty.member_frame.color.blue = 255
ezdefaults.ezparty.member_frame.size = {}
ezdefaults.ezparty.member_frame.size.width = 631
ezdefaults.ezparty.member_frame.size.height = 131
ezdefaults.ezparty.member_frame.texture = {}
ezdefaults.ezparty.member_frame.texture.path = 'gui/ezparty/member_frame.png' 
ezdefaults.ezparty.member_frame.texture.fit = false
ezdefaults.ezparty.member_frame.repeatable = {}
ezdefaults.ezparty.member_frame.repeatable.x = 1
ezdefaults.ezparty.member_frame.repeatable.y = 1
ezdefaults.ezparty.member_frame.draggable = false
ezdefaults.ezparty.member_frame.offset = {}
ezdefaults.ezparty.member_frame.offset.x = 100
ezdefaults.ezparty.member_frame.offset.y = 0

-- Buff Display Default Settings
ezdefaults.ezparty.buffs = {}
ezdefaults.ezparty.buffs.enable = true
ezdefaults.ezparty.buffs.global_scale = 1                   -- global buff icon scale
ezdefaults.ezparty.buffs.player = {}
ezdefaults.ezparty.buffs.player.location = 'below'          -- options: 'below', 'left', 'right' , 'above'
ezdefaults.ezparty.buffs.player.horizontal_limit = 10       -- max number of buffs to display on player
ezdefaults.ezparty.buffs.player.vertical_limit = 2          -- max number of buff rows to display on player
ezdefaults.ezparty.buffs.player.scale = 1                   -- buff icon scale
ezdefaults.ezparty.buffs.player.offset = { x = 0, y = 0 }   -- buff icon offset
ezdefaults.ezparty.buffs.member = {}
ezdefaults.ezparty.buffs.member.location = 'below'
ezdefaults.ezparty.buffs.member.horizontal_limit = 10
ezdefaults.ezparty.buffs.member.vertical_limit = 2
ezdefaults.ezparty.buffs.member.scale = 1
ezdefaults.ezparty.buffs.member.offset = { x = 0, y = 0 }

-- Target Frame Defaults
ezdefaults.ezparty.target_frame = {}
ezdefaults.ezparty.target_frame.top_center_screen = {}
ezdefaults.ezparty.target_frame.above_member_frames = {}
ezdefaults.ezparty.target_frame.enable = true
ezdefaults.ezparty.target_frame.image = 'gui/ezparty/target_frame.png'
ezdefaults.ezparty.target_frame.size = { width = 1649, height = 339 }
ezdefaults.ezparty.target_frame.top_center_screen = {}
ezdefaults.ezparty.target_frame.top_center_screen.enable = true
ezdefaults.ezparty.target_frame.top_center_screen.offset = { x = 0, y = 0 }
ezdefaults.ezparty.target_frame.above_member_frames = {}
ezdefaults.ezparty.target_frame.above_member_frames.enable = false
ezdefaults.ezparty.target_frame.above_member_frames.offset = { x = 0, y = -10 }

-- EZ Castbar Defaults
ezdefaults.ezcastbar = {}
ezdefaults.ezcastbar.enable = true
ezdefaults.ezcastbar.image_frame = 'gui/ezcastbar/ezcastbar_bg.png'
ezdefaults.ezcastbar.image_bar = 'gui/ezcastbar/ezcastbar_bar.png'
ezdefaults.ezcastbar.scale = 1
ezdefaults.ezcastbar.size = { width = 350, height = 13 }
ezdefaults.ezcastbar.offset = { x = 0, y = 0 }
ezdefaults.ezcastbar.fade_duration = 0.6

-- EZ Mount Defaults
ezdefaults.ezmount = {}
ezdefaults.ezmount.enable = true
ezdefaults.ezmount.name = 'Raptor'

-- EZ Targeting Defaults
ezdefaults.eztargeting = {}
ezdefaults.eztargeting.enable = true

-- Saved UI settings
-- This section is for storing the current UI size when saving settings and position.
-- That way we can recall the difference in resolution if it were to change and adjust things like scale properly

ezdefaults.saved_ui_info = {}
ezdefaults.saved_ui_info.ui_res = {}
ezdefaults.saved_ui_info.ui_res.x = nil
ezdefaults.saved_ui_info.ui_res.y = nil
return ezdefaults
