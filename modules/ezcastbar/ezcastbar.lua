_addon.name = 'EZCastbar'
_addon.author = 'Rook & Makto (standalone port)'
_addon.version = '1.0.0'
_addon.commands = {'ezcastbar', 'ezcb'}

local config = require('config')
local castbar = require('internal.castbar')

local settings = config.load(castbar.default_settings())

local function refresh_castbar()
    castbar.reload(settings)
end

local function set_enabled(value)
    local enabled = value and true or false
    if settings.enabled == enabled then
        return false
    end

    settings.enabled = enabled
    config.save(settings)
    refresh_castbar()
    return true
end

local function initialize_castbar()
    castbar.init(settings)
    castbar.on_load()
end

initialize_castbar()

windower.register_event('load', initialize_castbar)

windower.register_event('login', function()
    castbar.on_login()
end)

windower.register_event('logout', function()
    castbar.on_logout()
end)

windower.register_event('zone change', function()
    castbar.on_zone_change()
end)

windower.register_event('prerender', function()
    castbar.render()
end)

windower.register_event('action', function(act)
    castbar.handle_action(act)
end)

windower.register_event('action message', function(target_id, actor_id, message_id)
    castbar.handle_action_message(target_id, actor_id, message_id)
end)

windower.register_event('unload', function()
    castbar.destroy()
end)

windower.register_event('addon command', function(command, ...)
    local args = {...}
    local lower = command and command:lower() or 'help'

    if lower == 'reload' then
        config.reload(settings)
        refresh_castbar()
        windower.add_to_chat(207, '[EZCastbar] Settings reloaded.')
        return
    end

    if lower == 'enable' or lower == 'on' then
        if set_enabled(true) then
            windower.add_to_chat(207, '[EZCastbar] Enabled.')
        else
            windower.add_to_chat(207, '[EZCastbar] Already enabled.')
        end
        return
    end

    if lower == 'disable' or lower == 'off' then
        if set_enabled(false) then
            windower.add_to_chat(207, '[EZCastbar] Disabled.')
        else
            windower.add_to_chat(207, '[EZCastbar] Already disabled.')
        end
        return
    end

    if lower == 'toggle' then
        local new_value = not settings.enabled
        set_enabled(new_value)
        windower.add_to_chat(207, string.format('[EZCastbar] %s.', new_value and 'Enabled' or 'Disabled'))
        return
    end

    if lower == 'scale' then
        local value = tonumber(args[1])
        if value and value > 0 then
            settings.scale = value
            config.save(settings)
            refresh_castbar()
            windower.add_to_chat(207, string.format('[EZCastbar] Scale set to %.2f.', value))
        else
            windower.add_to_chat(207, '[EZCastbar] Usage: //ezcastbar scale <positive number>.')
        end
        return
    end

    if lower == 'test' or lower == 'preview' then
        local duration = tonumber(args[1]) or 5
        if castbar.show_test_bar(duration) then
            windower.add_to_chat(207, string.format('[EZCastbar] Preview running for %.1f seconds.', duration))
        else
            windower.add_to_chat(207, '[EZCastbar] Preview unavailable while disabled.')
        end
        return
    end

    if lower == 'help' or not command then
        windower.add_to_chat(207, '[EZCastbar] Commands: enable | disable | toggle | reload | test [seconds] | scale <value>')
        return
    end

    windower.add_to_chat(207, string.format('[EZCastbar] Unknown command: %s', tostring(command)))
end)
