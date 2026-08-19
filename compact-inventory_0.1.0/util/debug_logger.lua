-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local DEFAULT_FILE = "compact-inventory-debug.log"

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Clear a debug log file from script-output.
--
--- -----
--- @param file_name? string      The log file name. Defaults to the Compact Inventory debug log.
--
function factory.clear(file_name)
    helpers.write_file(file_name or DEFAULT_FILE, "", false)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Write a debug message both on screen and in script-output.
--
--- -----
--- @param lua_player LuaPlayer   The player receiving the on-screen message.
--- @param message string         The message to write.
--- @param file_name? string      The log file name. Defaults to the Compact Inventory debug log.
--
function factory.write(lua_player, message, file_name)
    assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Debug logger requires a valid LuaPlayer !")      -- [DEBUG-ONLY] . --
    assert(type(message) == "string", "Debug message must be a string !")                                                               -- [DEBUG-ONLY] . --

    lua_player.print(message)
    helpers.write_file(file_name or DEFAULT_FILE, message .. "\n", true)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Build the GUI ancestry path of an element up to an optional root element name.
--
--- -----
--- @param lua_element LuaGuiElement      The starting GUI element.
--- @param root_name? string              Optional ancestor name required for a successful result.
--
--- @return string?                       @ The formatted path, or nil when root_name was not found.
--
function factory.getGuiPath(lua_element, root_name)
    local path       = { }
    local root_found = root_name == nil

    while lua_element do
        local name = lua_element.name ~= "" and lua_element.name or "<unnamed>"
        path[#path + 1] = lua_element.type .. ":" .. name

        if root_name and lua_element.name == root_name then
            root_found = true
            break
        end

        lua_element = lua_element.parent
    end

    return root_found and table.concat(path, " <- ") or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Write a GUI event with its complete element ancestry path.
--
--- -----
--- @param event EventData.on_gui_hover|EventData.on_gui_leave      The GUI event to log.
--- @param event_name string                                        The displayed event name.
--- @param root_name? string                                        Optional ancestor name used to filter events.
--- @param file_name? string                                        Optional log file name.
--
function factory.writeGuiEvent(event, event_name, root_name, file_name)
    local path = factory.getGuiPath(event.element, root_name)

    if not path then
        return
    end

    local lua_player = game.get_player(event.player_index)

    if lua_player then
        factory.write(lua_player, "[GUI] t=" .. event.tick .. " " .. event_name .. " " .. path, file_name)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Format an indexed table as a stable debug string.
--
--- -----
--- @param values table      The table to format.
---
--- @return string           @ A stable {index=value,...} representation.
--
function factory.formatIndexedTable(values)
    local entries = { }

    for index, value in pairs(values) do
        entries[#entries + 1] = tostring(index) .. "=" .. tostring(value)
    end

    table.sort(entries)

    return "{" .. table.concat(entries, ",") .. "}"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
