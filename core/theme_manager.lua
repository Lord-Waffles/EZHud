local config = require('config')
local lfs_loaded, lfs = pcall(require, 'lfs')
if not lfs_loaded then
    lfs = nil
end

local theme_manager = {}

local THEMES_DIRECTORY = 'themes'
local SUPPORTED_ASSET_EXTENSIONS = {
    png = true,
    jpg = true,
    jpeg = true,
    dds = true,
    bmp = true,
    tga = true,
}

local function sanitize_theme_name(theme_name)
    if type(theme_name) ~= 'string' then
        return nil, 'Invalid theme name.'
    end

    theme_name = theme_name:match('^%s*(.-)%s*$') or theme_name
    if theme_name == '' then
        return nil, 'Theme name cannot be empty.'
    end

    if not theme_name:match('^[%w%-_]+$') then
        return nil, 'Theme names may only include letters, numbers, dashes, and underscores.'
    end

    return theme_name
end

local function addon_path(relative_path)
    return windower.addon_path .. relative_path
end

local function file_exists(relative_path)
    local full_path = addon_path(relative_path)
    local file = io.open(full_path, 'rb')
    if file then
        file:close()
        return true
    end

    return false
end

local function ensure_directory(full_path)
    if type(full_path) ~= 'string' or full_path == '' then
        return false
    end

    if lfs then
        local normalized = full_path:gsub('\\', '/')
        local path = ''

        for part in normalized:gmatch('[^/]+') do
            if path == '' and part:match('^%a:$') then
                path = part .. '/'
            else
                path = path .. part
            end

            local attributes = lfs.attributes(path)
            if attributes then
                if attributes.mode ~= 'directory' then
                    return false
                end
            else
                local success = lfs.mkdir(path)
                if not success then
                    return false
                end
            end

            if path:sub(-1) ~= '/' then
                path = path .. '/'
            end
        end

        return true
    end

    if windower.dir_exists and windower.dir_exists(full_path) then
        return true
    end

    if windower.create_dir and windower.create_dir(full_path) then
        return true
    end

    return false
end

local function get_theme_directory(theme_name)
    return string.format('%s/%s', THEMES_DIRECTORY, theme_name)
end

local function find_theme_file(theme_name)
    local theme_directory = get_theme_directory(theme_name)
    local possible_files = {
        string.format('%s/%s.lua', theme_directory, theme_name),
        string.format('%s/theme.lua', theme_directory),
    }

    for _, relative_path in ipairs(possible_files) do
        if file_exists(relative_path) then
            return relative_path
        end
    end

    return nil, string.format('Theme "%s" does not contain a Lua settings file.', theme_name)
end

local function is_array(tbl)
    local count = 0
    for k in pairs(tbl) do
        if type(k) ~= 'number' then
            return false
        end
        count = count + 1
    end

    for index = 1, count do
        if tbl[index] == nil then
            return false
        end
    end

    return true
end

local function deep_merge(target, source)
    for key, value in pairs(source) do
        if type(value) == 'table' then
            if type(target[key]) ~= 'table' or is_array(value) then
                target[key] = {}
            end
            deep_merge(target[key], value)
        else
            target[key] = value
        end
    end
end

local function serialize_value(value, indent_level, visited)
    indent_level = indent_level or 0
    visited = visited or {}

    local value_type = type(value)
    if value_type == 'table' then
        if visited[value] then
            return 'nil'
        end
        visited[value] = true

        local next_indent = indent_level + 1
        local indent = string.rep('    ', indent_level)
        local next_indent_str = string.rep('    ', next_indent)
        local output = {'{'}

        if next(value) ~= nil then
            if is_array(value) then
                table.insert(output, '\n')
                for index = 1, #value do
                    local serialized = serialize_value(value[index], next_indent, visited)
                    table.insert(output, next_indent_str .. serialized .. ',\n')
                end
            else
                local keys = {}
                for key in pairs(value) do
                    table.insert(keys, key)
                end
                table.sort(keys, function(a, b)
                    local type_a, type_b = type(a), type(b)
                    if type_a == type_b and (type_a == 'string' or type_a == 'number') then
                        return a < b
                    end
                    return tostring(a) < tostring(b)
                end)

                table.insert(output, '\n')
                for _, key in ipairs(keys) do
                    local serialized_key
                    if type(key) == 'string' and key:match('^[_%a][_%w]*$') then
                        serialized_key = key
                    else
                        serialized_key = '[' .. serialize_value(key, 0, visited) .. ']'
                    end

                    local serialized_value = serialize_value(value[key], next_indent, visited)
                    table.insert(output, string.format('%s%s = %s,\n', next_indent_str, serialized_key, serialized_value))
                end
            end
            table.insert(output, indent .. '}')
        else
            table.insert(output, '}')
        end

        visited[value] = nil
        return table.concat(output)
    elseif value_type == 'string' then
        return string.format('%q', value)
    elseif value_type == 'number' or value_type == 'boolean' then
        return tostring(value)
    else
        return 'nil'
    end
end

local function apply_theme_assets(settings, theme_name)
    local function recurse(container)
        for key, value in pairs(container) do
            if type(value) == 'table' then
                recurse(value)
            elseif type(value) == 'string' then
                local extension = value:match('%.([%a%d]+)$')
                if extension then
                    extension = extension:lower()
                end

                if extension and SUPPORTED_ASSET_EXTENSIONS[extension] then
                    local already_theme_path = value:find(THEMES_DIRECTORY .. '/' .. theme_name, 1, true)
                    if not already_theme_path then
                        local filename = value:match('([^/\\]+)$')
                        if filename then
                            local override_path = string.format('%s/%s/%s', THEMES_DIRECTORY, theme_name, filename)
                            if file_exists(override_path) then
                                container[key] = override_path
                            end
                        end
                    end
                end
            end
        end
    end

    recurse(settings)
end

function theme_manager.load(theme_name, addon_settings)
    local sanitized_name, error_message = sanitize_theme_name(theme_name)
    if not sanitized_name then
        return false, error_message
    end

    local theme_file, missing_message = find_theme_file(sanitized_name)
    if not theme_file then
        return false, missing_message
    end

    local chunk, load_error = loadfile(addon_path(theme_file))
    if not chunk then
        return false, string.format('Failed to load theme "%s": %s', sanitized_name, load_error)
    end

    local success, theme_data = pcall(chunk)
    if not success then
        return false, string.format('Failed to execute theme "%s": %s', sanitized_name, theme_data)
    end

    if type(theme_data) ~= 'table' then
        return false, string.format('Theme "%s" must return a table of settings.', sanitized_name)
    end

    addon_settings = addon_settings or {}
    deep_merge(addon_settings, theme_data)
    apply_theme_assets(addon_settings, sanitized_name)
    addon_settings.current_theme = sanitized_name
    config.save(addon_settings)

    return true, string.format('Theme "%s" loaded.', sanitized_name)
end

local function ensure_theme_directory_exists(theme_name)
    local directory = addon_path(get_theme_directory(theme_name))
    return ensure_directory(directory)
end

function theme_manager.export(theme_name, addon_settings)
    local sanitized_name, error_message = sanitize_theme_name(theme_name)
    if not sanitized_name then
        return false, error_message
    end

    if not addon_settings or type(addon_settings) ~= 'table' then
        return false, 'Addon settings are unavailable.'
    end

    if not ensure_theme_directory_exists(sanitized_name) then
        return false, string.format('Unable to create theme directory for "%s".', sanitized_name)
    end

    local relative_path = string.format('%s/%s.lua', get_theme_directory(sanitized_name), sanitized_name)
    local full_path = addon_path(relative_path)
    local file, err = io.open(full_path, 'w')
    if not file then
        return false, string.format('Unable to write theme file: %s', err or 'unknown error')
    end

    file:write('-- Auto-generated EZ Hud theme export\n')
    file:write('return ')
    file:write(serialize_value(addon_settings, 0, {}))
    file:write('\n')
    file:close()

    return true, relative_path
end

return theme_manager
