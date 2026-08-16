
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySourceMetatable.                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySourceMetatable
---
--- ### This class groups all functions used to manage an inventory source.
---
--- @field private lua_inventories LuaInventory[]       The LuaInventory contained in the source.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "InventorySource"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventorySourceMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get all LuaInventory contained in the source.
--
--- -----
--- @return LuaInventory[]      @ The LuaInventory contained in the source.
--
function metatable:getInventories()
    return self.lua_inventories
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Check whether a LuaInventory is contained in the source.
--
--- -----
--- @param lua_inventory LuaInventory      The LuaInventory to search for.
--
--- @return boolean                        @ Whether the LuaInventory is contained in the source.
--
function metatable:containsInventory(lua_inventory)

    assert(lua_inventory ~= nil, "LuaInventory cannot be nil !")                                                       -- [DEBUG-ONLY] . --
    assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "LuaInventory must be a LuaObject !")  -- [DEBUG-ONLY] . --
    assert(lua_inventory.valid, "LuaInventory must be valid !")                                                        -- [DEBUG-ONLY] . --
    assert(lua_inventory.object_name == "LuaInventory", "LuaInventory must be a LuaInventory !")                       -- [DEBUG-ONLY] . --

    for _, source_lua_inventory in ipairs(self.lua_inventories) do
        if source_lua_inventory == lua_inventory then
            return true
        end
    end

    return false
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySource.                                                                                              ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySource: InventorySourceMetatable
---
--- ### This class represents a logical inventory source containing zero or more LuaInventory.
---
--- @field private lua_inventories LuaInventory[]      The LuaInventory contained in the source.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySourceFactory.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySourceFactory
---
--- ### This class groups all functions used to create inventory sources.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new inventory source.
--
--- -----
--- @param ... LuaInventory      The LuaInventory to include in the source.
--
--- @return InventorySource      @ Returns the created inventory source.
--
function factory.new(...)

    local lua_inventory_count = select("#", ...)
    local lua_inventories     = { ... }

    local source = {                                     ---@type InventorySource
        lua_inventories = { }
    }

    for index = 1, lua_inventory_count do
        local lua_inventory = lua_inventories[index]

        assert(lua_inventory ~= nil, "InventorySource cannot contain nil LuaInventory !")                                            -- [DEBUG-ONLY] . --
        assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "InventorySource can only contain LuaObject !")  -- [DEBUG-ONLY] . --
        assert(lua_inventory.valid, "InventorySource can only contain valid LuaInventory !")                                         -- [DEBUG-ONLY] . --
        assert(lua_inventory.object_name == "LuaInventory", "InventorySource can only contain LuaInventory !")                       -- [DEBUG-ONLY] . --
    
        source.lua_inventories[index] = lua_inventory
    end

    setmetatable(source, metatable)

    return source
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
