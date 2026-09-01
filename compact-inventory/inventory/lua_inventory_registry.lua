
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ LuaInventoryRegistryEntry.                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class LuaInventoryRegistryEntry
---
--- @field lua_inventory LuaInventory      The registered LuaInventory.
--- @field references    integer           The number of InventorySource references to the LuaInventory.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ LuaInventoryRegistry.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class LuaInventoryRegistry
---
--- @field entries table<integer, LuaInventoryRegistryEntry>      The registered LuaInventory indexed by internal ID.
--- @field next_id integer                                        The next internal ID to allocate.
---

local registry = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getStorage()
    if not storage.lua_inventory_registry then
        storage.lua_inventory_registry = {
            entries = { },
            next_id = 1
        }
    end

    return storage.lua_inventory_registry      ---@type LuaInventoryRegistry
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Register a LuaInventory and acquire one reference to it.
--
--- Existing LuaInventory are found by linear search because Factorio LuaObjects cannot be used as persistent table
--- keys. This cost is intentionally paid only when an InventorySource is created.
--
--- -----
--- @param lua_inventory LuaInventory      The LuaInventory to register.
---
--- @return integer                        @ Returns the internal LuaInventory ID.
--
function registry.register(lua_inventory)
    assert(lua_inventory ~= nil, "LuaInventory cannot be nil !")                                                       -- [DEBUG-ONLY] . --
    assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "LuaInventory must be a LuaObject !")  -- [DEBUG-ONLY] . --
    assert(lua_inventory.valid, "LuaInventory must be valid !")                                                        -- [DEBUG-ONLY] . --
    assert(lua_inventory.object_name == "LuaInventory", "LuaInventory must be a LuaInventory !")                       -- [DEBUG-ONLY] . --

    local persistent_registry = getStorage()

    for id, entry in pairs(persistent_registry.entries) do
        if entry.lua_inventory == lua_inventory then
            assert(type(entry.references) == "number" and entry.references > 0, "LuaInventory registry reference count must be positive !")      -- [DEBUG-ONLY] . --

            entry.references = entry.references + 1
            return id
        end
    end

    local id = persistent_registry.next_id

    persistent_registry.next_id = id + 1
    persistent_registry.entries[id] = {
        lua_inventory = lua_inventory,
        references    = 1
    }

    return id
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Release one reference to a registered LuaInventory.
--
--- The registry entry is removed when its last reference is released. Internal IDs are never reused.
--
--- -----
--- @param id integer      The internal LuaInventory ID to release.
--
function registry.unregister(id)
    assert(type(id) == "number" and id > 0 and id % 1 == 0, "LuaInventory registry ID must be a positive integer !")      -- [DEBUG-ONLY] . --

    local persistent_registry = getStorage()
    local entry               = persistent_registry.entries[id]

    assert(entry, "LuaInventory registry entry does not exist !")                                      -- [DEBUG-ONLY] . --
    assert(type(entry.references) == "number" and entry.references > 0, "LuaInventory registry reference count must be positive !")      -- [DEBUG-ONLY] . --

    entry.references = entry.references - 1

    if entry.references == 0 then
        persistent_registry.entries[id] = nil
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get a registered LuaInventory by its internal ID.
--
--- -----
--- @param id integer      The internal LuaInventory ID.
---
--- @return LuaInventory   @ Returns the registered LuaInventory.
--
function registry.get(id)
    assert(type(id) == "number" and id > 0 and id % 1 == 0, "LuaInventory registry ID must be a positive integer !")      -- [DEBUG-ONLY] . --

    local entry = getStorage().entries[id]

    assert(entry and entry.lua_inventory, "LuaInventory registry entry does not exist !")      -- [DEBUG-ONLY] . --

    return entry.lua_inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return registry
