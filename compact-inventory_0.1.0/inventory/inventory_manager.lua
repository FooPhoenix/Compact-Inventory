
local ItemOrder = require("util.item_order")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Local Working Buffers.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local changed_items = { }
local changed_delta = { }

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryMetatable.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryMetatable
---
--- ### This class groups all functions used to monitor an InventorySource.
---
--- @field private manager     InventoryManager      The InventoryManager that owns the inventory.
--- @field private source      InventorySource       The InventorySource monitored by the inventory.
--- @field private id          integer               The inventory identifier in its manager.
--- @field private content     table                 The current aggregated inventory content.
--- @field private counts      table<integer, integer> The current item counts indexed by item identifier.
--- @field private previous    table<integer, integer> Previous item links used by last-change ordering.
--- @field private next        table<integer, integer> Next item links used by last-change ordering.
--- @field private first       integer?              The first item identifier in last-change ordering.
--- @field private last        integer?              The last item identifier in last-change ordering.
--- @field private initialized boolean               Whether a non-empty baseline has been initialized.
---
--
local inventory_metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

inventory_metatable.object_name = "Inventory"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryMetatable", inventory_metatable)
inventory_metatable.__index = inventory_metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Detach an item from the last-change linked list.
--
--- -----
--- @param inventory Inventory      The inventory whose linked list must be modified.
--- @param item_id integer          The item identifier to detach.
--
local function inventory_detachItem(inventory, item_id)

    local previous_id = inventory.previous[item_id]
    local next_id     = inventory.next[item_id]

    if previous_id then
        inventory.next[previous_id] = next_id
    elseif inventory.first == item_id then
        inventory.first = next_id
    else
        return
    end

    if next_id then
        inventory.previous[next_id] = previous_id
    else
        inventory.last = previous_id
    end

    inventory.previous[item_id] = nil
    inventory.next[item_id]     = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Prepend an item to the last-change linked list.
--
--- -----
--- @param inventory Inventory      The inventory whose linked list must be modified.
--- @param item_id integer          The item identifier to prepend.
--
local function inventory_prependItem(inventory, item_id)

    local first_id = inventory.first

    inventory.previous[item_id] = nil
    inventory.next[item_id]     = first_id

    if first_id then
        inventory.previous[first_id] = item_id
    else
        inventory.last = item_id
    end

    inventory.first = item_id
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Initialize the inventory state from a non-empty content baseline without recording changes.
--
--- -----
--- @param inventory Inventory      The inventory to initialize.
--- @param content table            The current inventory content in standard order.
--
local function inventory_initializeState(inventory, content)

    assert(#content > 0, "Inventory baseline cannot be initialized from empty content !")      -- [DEBUG-ONLY] . --

    local previous_id

    for _, item in ipairs(content) do
        local item_id = ItemOrder.get(item.name, item.quality)

        inventory.counts[item_id]   = item.count
        inventory.previous[item_id] = previous_id

        if previous_id then
            inventory.next[previous_id] = item_id
        else
            inventory.first = item_id
        end

        previous_id = item_id
    end

    inventory.last        = previous_id
    inventory.initialized = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the InventorySource monitored by the inventory.
--
--- -----
--- @return InventorySource      @ The monitored InventorySource.
--
function inventory_metatable:getSource()
    return self.source
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the current aggregated inventory content.
--
--- -----
--- @return table      @ The current inventory content in Factorio standard item order.
--
function inventory_metatable:getContent()
    return self.content
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Update the logical inventory state from every LuaInventory in its source.
--
--- The source content is aggregated before changes are detected, so one item spread over several LuaInventory is
--- tracked as one logical item quantity.
--
function inventory_metatable:update()

    assert(self.source and self.source.object_name == "InventorySource", "Inventory must have a valid InventorySource !")      -- [DEBUG-ONLY] . --
    assert(#changed_items == 0 and next(changed_delta) == nil, "Inventory working buffers must be empty !")                     -- [DEBUG-ONLY] . --

    local content_by_id = { }

    for _, lua_inventory in ipairs(self.source:getInventories()) do
        if lua_inventory.valid then
            for _, item in ipairs(lua_inventory.get_contents()) do
                local item_id = ItemOrder.get(item.name, item.quality)
                local content_item = content_by_id[item_id]

                if content_item then
                    content_item.count = content_item.count + item.count
                else
                    content_by_id[item_id] = {
                        name    = item.name,
                        quality = item.quality,
                        count   = item.count
                    }
                end
            end
        end
    end

    local content = { }

    for _, item in pairs(content_by_id) do
        content[#content + 1] = item
    end

    table.sort(content, function(item_a, item_b)
        return ItemOrder.get(item_a.name, item_a.quality) < ItemOrder.get(item_b.name, item_b.quality)
    end)

    self.content = content

    if not self.initialized then
        if #content > 0 then
            inventory_initializeState(self, content)
        end

        return
    end

    local seen = { }

    for _, item in ipairs(content) do
        local item_id   = ItemOrder.get(item.name, item.quality)
        local old_count = self.counts[item_id]

        seen[item_id] = true

        if old_count ~= item.count then
            changed_items[#changed_items + 1] = item_id
            changed_delta[item_id] = math.abs(item.count - (old_count or 0))
            self.counts[item_id] = item.count
        end
    end

    for item_id in pairs(self.counts) do
        if not seen[item_id] then
            inventory_detachItem(self, item_id)
            self.counts[item_id]   = nil
            self.previous[item_id] = nil
            self.next[item_id]     = nil
        end
    end

    table.sort(changed_items, function(item_a, item_b)
        if changed_delta[item_a] ~= changed_delta[item_b] then
            return changed_delta[item_a] > changed_delta[item_b]
        end

        return item_a < item_b
    end)

    for index = #changed_items, 1, -1 do
        local item_id = changed_items[index]

        inventory_detachItem(self, item_id)
        inventory_prependItem(self, item_id)

        changed_delta[item_id] = nil
        changed_items[index]   = nil
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Sort an item list using this inventory's maintained last-change order.
--
--- -----
--- @param items table      The item list to order.
--
--- @return table           @ The ordered item list.
--
function inventory_metatable:sortByLastChange(items)

    if not self.initialized and #items > 0 then
        inventory_initializeState(self, items)
    end

    local items_by_id  = { }
    local sorted_items = { }

    for _, item in ipairs(items) do
        items_by_id[ItemOrder.get(item.name, item.quality)] = item
    end

    local item_id = self.first

    while item_id do
        local item = items_by_id[item_id]

        assert(item, "Last change order contains an item that is not in the current inventory !")      -- [DEBUG-ONLY] . --

        if item then
            sorted_items[#sorted_items + 1] = item
        end

        item_id = self.next[item_id]
    end

    assert(#sorted_items == #items, "Last change sorting did not resolve every item !")      -- [DEBUG-ONLY] . --

    return sorted_items
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
--- @field private lua_player        LuaPlayer                 The player that owns the manager.
--- @field private inventories       table<integer, Inventory> The monitored inventories indexed by their internal ID.
--- @field private next_inventory_id integer                   The next inventory identifier to allocate.
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

    assert(source and source.object_name == "InventorySource", "Source must be a valid InventorySource !")                    -- [DEBUG-ONLY] . --

    if source.inventory then
        assert(source.inventory.object_name == "Inventory", "InventorySource contains an invalid Inventory reference !")     -- [DEBUG-ONLY] . --
        assert(source.inventory.manager == self, "InventorySource is already monitored by another InventoryManager !")       -- [DEBUG-ONLY] . --

        return source.inventory
    end

    local inventory_id = self.next_inventory_id

    local inventory = {                                  ---@type Inventory
        id          = inventory_id,
        manager     = self,
        source      = source,
        content     = { },
        counts      = { },
        previous    = { },
        next        = { },
        first       = nil,
        last        = nil,
        initialized = false
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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Update every monitored InventorySource containing one LuaInventory.
--
--- -----
--- @param lua_inventory LuaInventory      The LuaInventory whose content changed.
--
function manager_metatable:updateInventory(lua_inventory)
    self:updateInventories({ lua_inventory })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Update every monitored InventorySource containing at least one of the provided LuaInventory.
--
--- Each logical Inventory is updated at most once, even if several of its physical LuaInventory are provided.
--
--- -----
--- @param lua_inventories LuaInventory[]      The LuaInventory whose content changed.
--
function manager_metatable:updateInventories(lua_inventories)

    local inventories_to_update = { }

    for _, lua_inventory in ipairs(lua_inventories) do
        assert(lua_inventory and lua_inventory.valid and lua_inventory.object_name == "LuaInventory", "You need to provide valid LuaInventory !")  -- [DEBUG-ONLY] . --

        for _, inventory in pairs(self.inventories) do
            if inventory.source:containsInventory(lua_inventory) then
                inventories_to_update[inventory] = true
            end
        end
    end

    for inventory in pairs(inventories_to_update) do
        inventory:update()
    end
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
