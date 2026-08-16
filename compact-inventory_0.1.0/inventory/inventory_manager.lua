
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryMetatable.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryMetatable
---
--- ### This class groups all functions used to monitor an InventorySource.
---
--- @field private manager InventoryManager      The InventoryManager that owns the inventory.
--- @field private source  InventorySource       The InventorySource monitored by the inventory.
--- @field private id      integer               The inventory identifier in its manager.
---
--
local inventory_metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

inventory_metatable.object_name = "Inventory"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryMetatable", inventory_metatable)
inventory_metatable.__index = inventory_metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the InventorySource monitored by the inventory.
--
--- -----
--- @return InventorySource      @ The monitored InventorySource.
--
function inventory_metatable:getSource()
    return self.source
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Inventory.                                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class Inventory: InventoryMetatable
---
--- ### This class represents the monitored logical state of an InventorySource.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryManagerMetatable.                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryManagerMetatable
---
--- ### This class groups all functions used to monitor inventories for one player.
---
--- @field private lua_player          LuaPlayer            The player that owns the manager.
--- @field private inventories         table<integer, Inventory> The monitored inventories indexed by their internal ID.
--- @field private next_inventory_id   integer              The next inventory identifier to allocate.
---
--
local manager_metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

manager_metatable.object_name = "InventoryManager"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryManagerMetatable", manager_metatable)
manager_metatable.__index = manager_metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Start monitoring an InventorySource.
---
--- Returns the existing Inventory if this source is already monitored by this manager.
--
--- -----
--- @param source InventorySource      The InventorySource to monitor.
--
--- @return Inventory                 @ The Inventory monitoring the source.
--
function manager_metatable:monitorInventory(source)

    assert(source and source.object_name == "InventorySource", "Source must be a valid InventorySource !")          -- [DEBUG-ONLY] . --

    if source.inventory then
        assert(source.inventory.object_name == "Inventory", "InventorySource contains an invalid Inventory reference !")  -- [DEBUG-ONLY] . --
        assert(source.inventory.manager == self, "InventorySource is already monitored by another InventoryManager !")   -- [DEBUG-ONLY] . --

        return source.inventory
    end

    local inventory_id = self.next_inventory_id

    local inventory = {                                  ---@type Inventory
        id      = inventory_id,
        manager = self,
        source  = source
    }

    setmetatable(inventory, inventory_metatable)

    self.inventories[inventory_id] = inventory
    self.next_inventory_id = inventory_id + 1
    source.inventory = inventory

    return inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Stop monitoring an InventorySource or Inventory.
--
--- -----
--- @param source_or_inventory InventorySource|Inventory      The InventorySource or Inventory to stop monitoring.
--
function manager_metatable:unmonitorInventory(source_or_inventory)

    assert(source_or_inventory ~= nil, "InventorySource or Inventory cannot be nil !")                                -- [DEBUG-ONLY] . --

    local inventory

    if source_or_inventory.object_name == "InventorySource" then
        inventory = source_or_inventory.inventory
        assert(inventory, "InventorySource is not monitored !")                                                        -- [DEBUG-ONLY] . --

    elseif source_or_inventory.object_name == "Inventory" then
        inventory = source_or_inventory

    else
        assert(false, "You need to provide an InventorySource or Inventory !")                                         -- [DEBUG-ONLY] . --
        return
    end

    assert(inventory.manager == self, "Inventory does not belong to this InventoryManager !")                          -- [DEBUG-ONLY] . --
    assert(self.inventories[inventory.id] == inventory, "InventoryManager does not contain this Inventory !")           -- [DEBUG-ONLY] . --
    assert(inventory.source and inventory.source.inventory == inventory, "InventorySource relationship is invalid !")  -- [DEBUG-ONLY] . --

    self.inventories[inventory.id] = nil
    inventory.source.inventory = nil
    inventory.source  = nil
    inventory.manager = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get all Inventory monitored by this manager.
--
--- -----
--- @return table<integer, Inventory>      @ The monitored Inventory indexed by their internal ID.
--
function manager_metatable:getInventories()
    return self.inventories
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryManager.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryManager: InventoryManagerMetatable
---
--- ### This class owns all monitored Inventory for one player.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryManagerFactory.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryManagerFactory
---
--- ### This class groups all functions used to create and retrieve InventoryManager instances.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.initialize()

    storage.inventory_managers = { }

    for _, lua_player in pairs(game.players) do
        factory.initializePlayer(lua_player)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Initialize the InventoryManager for one player.
--
--- -----
--- @param player integer|LuaPlayer      The player that will own the manager.
--
--- @return InventoryManager             @ The created InventoryManager.
--
function factory.initializePlayer(player)

    local player_index, lua_player = resolve_player(player)

    assert(storage.inventory_managers[player_index] == nil, "Player already has an InventoryManager !")              -- [DEBUG-ONLY] . --

    local manager = {                                    ---@type InventoryManager
        lua_player        = lua_player,
        inventories       = { },
        next_inventory_id = 1
    }

    setmetatable(manager, manager_metatable)
    storage.inventory_managers[player_index] = manager

    return manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the InventoryManager for one player.
--
--- -----
--- @param player integer|LuaPlayer      The player whose manager is requested.
--
--- @return InventoryManager             @ The player's InventoryManager.
--
function factory.get(player)

    local player_index = resolve_player(player)
    local manager = storage.inventory_managers[player_index]     ---@type InventoryManager

    assert(manager and manager.object_name == "InventoryManager", "Player does not have a valid InventoryManager !")  -- [DEBUG-ONLY] . --

    return manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Destroy the InventoryManager for one player.
--
--- -----
--- @param player integer|LuaPlayer      The player whose manager must be destroyed.
--
function factory.destroy(player)

    local player_index = resolve_player(player)
    local manager = storage.inventory_managers[player_index]     ---@type InventoryManager

    assert(manager and manager.object_name == "InventoryManager", "Player does not have a valid InventoryManager !")  -- [DEBUG-ONLY] . --

    for _, inventory in pairs(manager.inventories) do
        inventory.source.inventory = nil
        inventory.source  = nil
        inventory.manager = nil
    end

    manager.inventories = { }
    manager.lua_player = nil
    storage.inventory_managers[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
