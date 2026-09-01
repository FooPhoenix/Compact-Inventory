
local LuaInventoryRegistry = require("inventory.lua_inventory_registry")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Local Working Cache.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local inventory_content_cache      = { }
local inventory_content_cache_tick = nil

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySourceMetatable.                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySourceMetatable
---
--- ### This class groups all functions used to manage an inventory source.
---
--- @field private lua_inventories    LuaInventory[]      The LuaInventory contained in the source.
--- @field private lua_inventory_ids  integer[]           The internal registry IDs matching `lua_inventories`.
--- @field private inventory          Inventory?           The Inventory currently monitoring the source.
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

--- ### Get the internal registry IDs associated with the source LuaInventory.
--
--- IDs use the same indexes as `getInventories()`.
--
--- -----
--- @return integer[]      @ The internal LuaInventory IDs contained in the source.
--
function metatable:getInventoryIDs()
    return self.lua_inventory_ids
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Replace all LuaInventory contained in the source.
--
--- Registry references are acquired for the new inventories before the old references are released. If the resolved
--- inventories are unchanged, the source is left untouched.
--
--- -----
--- @param lua_inventories LuaInventory[]      The new LuaInventory to monitor.
--
--- @return boolean                              @ Whether the source changed.
--
function metatable:replaceInventories(lua_inventories)
    assert(type(lua_inventories) == "table", "InventorySource replacement inventories must be a table !")      -- [DEBUG-ONLY] . --

    if #lua_inventories == #self.lua_inventories then
        local identical = true

        for index, lua_inventory in ipairs(lua_inventories) do
            if self.lua_inventories[index] ~= lua_inventory then
                identical = false
                break
            end
        end

        if identical then
            return false
        end
    end

    local new_lua_inventories   = { }
    local new_lua_inventory_ids = { }

    for index, lua_inventory in ipairs(lua_inventories) do
        assert(lua_inventory ~= nil, "InventorySource cannot contain nil LuaInventory !")                                            -- [DEBUG-ONLY] . --
        assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "InventorySource can only contain LuaObject !")  -- [DEBUG-ONLY] . --
        assert(lua_inventory.valid, "InventorySource can only contain valid LuaInventory !")                                         -- [DEBUG-ONLY] . --
        assert(lua_inventory.object_name == "LuaInventory", "InventorySource can only contain LuaInventory !")                       -- [DEBUG-ONLY] . --

        new_lua_inventories[index]   = lua_inventory
        new_lua_inventory_ids[index] = LuaInventoryRegistry.register(lua_inventory)
    end

    for _, lua_inventory_id in ipairs(self.lua_inventory_ids) do
        LuaInventoryRegistry.unregister(lua_inventory_id)
    end

    self.lua_inventories   = new_lua_inventories
    self.lua_inventory_ids = new_lua_inventory_ids

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the content of one LuaInventory contained in the source.
--
--- The LuaInventory is read at most once per game tick. Other InventorySource referencing the same registry ID reuse
--- the same cached content for the rest of the tick.
--
--- -----
--- @param index integer      The source LuaInventory index.
--
--- @return table             @ The LuaInventory content for the current game tick.
--
function metatable:getInventoryContent(index)
    assert(type(index) == "number" and index > 0 and index % 1 == 0, "InventorySource index must be a positive integer !")      -- [DEBUG-ONLY] . --
    assert(self.lua_inventories[index] ~= nil, "InventorySource LuaInventory does not exist !")                                  -- [DEBUG-ONLY] . --
    assert(self.lua_inventory_ids[index] ~= nil, "InventorySource LuaInventory ID does not exist !")                             -- [DEBUG-ONLY] . --

    local tick = game.tick

    if inventory_content_cache_tick ~= tick then
        inventory_content_cache      = { }
        inventory_content_cache_tick = tick
    end

    local lua_inventory_id = self.lua_inventory_ids[index]
    local content          = inventory_content_cache[lua_inventory_id]

    if content then
        return content
    end

    local lua_inventory = self.lua_inventories[index]

    if lua_inventory.valid then
        content = lua_inventory.get_contents()
    else
        content = { }
    end

    inventory_content_cache[lua_inventory_id] = content

    return content
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
--- @field private lua_inventories   LuaInventory[]      The LuaInventory contained in the source.
--- @field private lua_inventory_ids integer[]           The internal registry IDs matching `lua_inventories`.
--- @field private inventory         Inventory?          The Inventory currently monitoring the source.
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
--- Each LuaInventory is registered once during source creation so hot-path updates can use its pre-resolved internal
--- ID without repeating the registry lookup.
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
        lua_inventories   = { },
        lua_inventory_ids = { }
    }

    for index = 1, lua_inventory_count do
        local lua_inventory = lua_inventories[index]

        assert(lua_inventory ~= nil, "InventorySource cannot contain nil LuaInventory !")                                            -- [DEBUG-ONLY] . --
        assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "InventorySource can only contain LuaObject !")  -- [DEBUG-ONLY] . --
        assert(lua_inventory.valid, "InventorySource can only contain valid LuaInventory !")                                         -- [DEBUG-ONLY] . --
        assert(lua_inventory.object_name == "LuaInventory", "InventorySource can only contain LuaInventory !")                       -- [DEBUG-ONLY] . --

        source.lua_inventories[index]   = lua_inventory
        source.lua_inventory_ids[index] = LuaInventoryRegistry.register(lua_inventory)
    end

    setmetatable(source, metatable)

    return source
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Destroy an inventory source and release all LuaInventory registry references it owns.
--
--- -----
--- @param source InventorySource      The InventorySource to destroy.
--
function factory.destroy(source)
    assert(source and source.object_name == "InventorySource", "InventorySource does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(source.inventory == nil, "Monitored InventorySource cannot be destroyed !")                                 -- [DEBUG-ONLY] . --
    assert(type(source.lua_inventory_ids) == "table", "InventorySource LuaInventory IDs must exist !")                -- [DEBUG-ONLY] . --

    for _, lua_inventory_id in ipairs(source.lua_inventory_ids) do
        LuaInventoryRegistry.unregister(lua_inventory_id)
    end

    source.lua_inventories   = nil
    source.lua_inventory_ids = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
