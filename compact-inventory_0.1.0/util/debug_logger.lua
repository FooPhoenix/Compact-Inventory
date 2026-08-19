-- [DEBUG-ONLY] Temporary debug logger used while validating GUI hover and filter behavior. --

local DEBUG_FILE = "compact-inventory-debug.log"

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.clear()
    helpers.write_file(DEBUG_FILE, "", false)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.write(lua_player, message)
    assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Debug logger requires a valid LuaPlayer !")      -- [DEBUG-ONLY] . --
    assert(type(message) == "string", "Debug message must be a string !")                                                               -- [DEBUG-ONLY] . --

    lua_player.print(message)
    helpers.write_file(DEBUG_FILE, message .. "\n", true)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
