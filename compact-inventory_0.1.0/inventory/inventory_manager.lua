
local ItemKey                = require("util.item_key")
local ItemOrder              = require("util.item_order")
local InventoryWindowFactory = require("gui.inventory_window")
local InventorySourceFactory = require("inventory.inventory_source")

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
--- @field private manager        InventoryManager                The InventoryManager that owns the inventory.
--- @field private source         InventorySource                 The InventorySource monitored by the inventory.
--- @field private configuration  table?                          The declarative configuration used to resolve the source.
--- @field private id             integer                         The inventory identifier in its manager.
--- @field private name           string                          The user-visible inventory name.
--- @field private windows        table<integer, InventoryWindow> The inventory windows indexed by their stable ID.
--- @field private next_window_id integer                         The next inventory window identifier to allocate.
--- @field private content        table                           The current aggregated inventory content.
--- @field private counts         table<string, integer>          The current item counts indexed by stable item key.
--- @field private previous       table<string, string>           Previous item links used by last-change ordering.
--- @field private next           table<string, string>           Next item links used by last-change ordering.
--- @field private first          string?                         The first item key in last-change ordering.
--- @field private last           string?                         The last item key in last-change ordering.
--- @field private initialized    boolean                         Whether a non-empty baseline has been initialized.
---
--
local inventory_metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

inventory_metatable.object_name = "Inventory"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryMetatable", inventory_metatable)
inventory_metatable.__index = inventory_metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function inventory_detachItem(inventory, item_key)
    local previous_key = inventory.previous[item_key]
    local next_key     = inventory.next[item_key]

    if previous_key then
        inventory.next[previous_key] = next_key
    elseif inventory.first == item_key then
        inventory.first = next_key
    else
        return
    end

    if next_key then
        inventory.previous[next_key] = previous_key
    else
        inventory.last = previous_key
    end

    inventory.previous[item_key] = nil
    inventory.next[item_key]     = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function inventory_prependItem(inventory, item_key)
    local first_key = inventory.first

    inventory.previous[item_key] = nil
    inventory.next[item_key]     = first_key

    if first_key then
        inventory.previous[first_key] = item_key
    else
        inventory.last = item_key
    end

    inventory.first = item_key
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function inventory_initializeState(inventory, content)
    assert(#content > 0, "Inventory baseline cannot be initialized from empty content !")      -- [DEBUG-ONLY] . --

    local previous_key

    for _, item in ipairs(content) do
        local item_key = ItemKey.create(item.name, item.quality)

        inventory.counts[item_key]   = item.count
        inventory.previous[item_key] = previous_key

        if previous_key then
            inventory.next[previous_key] = item_key
        else
            inventory.first = item_key
        end

        previous_key = item_key
    end

    inventory.last        = previous_key
    inventory.initialized = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getID()
    assert(type(self.id) == "number" and self.id > 0, "Inventory ID must be a positive integer !")      -- [DEBUG-ONLY] . --
    return self.id
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getName()
    if self.name == nil then
        self.name = "Inventory " .. self:getID()
    end

    assert(type(self.name) == "string", "Inventory name must be a string !")      -- [DEBUG-ONLY] . --
    return self.name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:setName(name)
    assert(type(name) == "string", "Inventory name must be a string !")      -- [DEBUG-ONLY] . --
    self.name = name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getSource()
    return self.source
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getConfiguration()
    return self.configuration
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getWindows()
    assert(type(self.windows) == "table", "Inventory windows must be a table !")      -- [DEBUG-ONLY] . --
    return self.windows
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getWindow(window_id)
    assert(type(window_id) == "number" and window_id > 0 and window_id % 1 == 0, "Inventory window ID must be valid !")      -- [DEBUG-ONLY] . --
    return self:getWindows()[window_id]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:createWindow()
    local window_id = self.next_window_id

    self.next_window_id = window_id + 1

    local window = InventoryWindowFactory.create(self.manager.lua_player, self, window_id)
    self.windows[window_id] = window

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:removeWindow(window_or_id)
    local window_id = type(window_or_id) == "number" and window_or_id or window_or_id and window_or_id:getID()
    local window    = window_id and self.windows[window_id] or nil

    assert(window and window.object_name == "InventoryWindow", "Inventory window does not exist !")      -- [DEBUG-ONLY] . --
    assert(window:getInventory() == self, "Inventory window belongs to another Inventory !")              -- [DEBUG-ONLY] . --

    InventoryWindowFactory.destroy(window)
    self.windows[window_id] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:getContent()
    return self.content
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:update()
    assert(self.source and self.source.object_name == "InventorySource", "Inventory must have a valid InventorySource !")      -- [DEBUG-ONLY] . --
    assert(#changed_items == 0 and next(changed_delta) == nil, "Inventory working buffers must be empty !")                     -- [DEBUG-ONLY] . --

    local content_by_key = { }

    for _, lua_inventory in ipairs(self.source:getInventories()) do
        if lua_inventory.valid then
            for _, item in ipairs(lua_inventory.get_contents()) do
                local item_key     = ItemKey.create(item.name, item.quality)
                local content_item = content_by_key[item_key]

                if content_item then
                    content_item.count = content_item.count + item.count
                else
                    content_by_key[item_key] = {
                        name    = item.name,
                        quality = item.quality,
                        count   = item.count
                    }
                end
            end
        end
    end

    local content = { }

    for _, item in pairs(content_by_key) do
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
        local item_key  = ItemKey.create(item.name, item.quality)
        local old_count = self.counts[item_key]

        seen[item_key] = true

        if old_count ~= item.count then
            changed_items[#changed_items + 1] = item_key
            changed_delta[item_key] = math.abs(item.count - (old_count or 0))
            self.counts[item_key] = item.count
        end
    end

    for item_key in pairs(self.counts) do
        if not seen[item_key] then
            inventory_detachItem(self, item_key)
            self.counts[item_key]   = nil
            self.previous[item_key] = nil
            self.next[item_key]     = nil
        end
    end

    table.sort(changed_items, function(item_a, item_b)
        if changed_delta[item_a] ~= changed_delta[item_b] then
            return changed_delta[item_a] > changed_delta[item_b]
        end

        return item_a < item_b
    end)

    for index = #changed_items, 1, -1 do
        local item_key = changed_items[index]

        inventory_detachItem(self, item_key)
        inventory_prependItem(self, item_key)

        changed_delta[item_key] = nil
        changed_items[index]    = nil
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function inventory_metatable:sortByLastChange(items)
    if not self.initialized and #items > 0 then
        inventory_initializeState(self, items)
    end

    local items_by_key = { }
    local sorted_items = { }

    for _, item in ipairs(items) do
        items_by_key[ItemKey.create(item.name, item.quality)] = item
    end

    local item_key = self.first

    while item_key do
        local item = items_by_key[item_key]

        assert(item, "Last change order contains an item that is not in the current inventory !")      -- [DEBUG-ONLY] . --

        if item then
            sorted_items[#sorted_items + 1] = item
        end

        item_key = self.next[item_key]
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

local function sourcesMatch(source, lua_inventories)
    local source_inventories = source:getInventories()

    if #source_inventories ~= #lua_inventories then
        return false
    end

    for _, lua_inventory in ipairs(lua_inventories) do
        local found = false

        for _, source_lua_inventory in ipairs(source_inventories) do
            if source_lua_inventory == lua_inventory then
                found = true
                break
            end
        end

        if not found then
            return false
        end
    end

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function resolveConfiguration(configuration)
    assert(type(configuration) == "table", "Inventory configuration must be a table !")                    -- [DEBUG-ONLY] . --
    assert(type(configuration.entities) == "table", "Inventory configuration entities must be a table !") -- [DEBUG-ONLY] . --
    assert(configuration.options == nil or type(configuration.options) == "table", "Inventory configuration options must be a table !") -- [DEBUG-ONLY] . --

    local lua_inventories = { }

    for _, entity_configuration in ipairs(configuration.entities) do
        assert(type(entity_configuration) == "table", "Inventory entity configuration must be a table !")                      -- [DEBUG-ONLY] . --
        assert(entity_configuration.entity and entity_configuration.entity.valid, "Inventory entity must be valid !")           -- [DEBUG-ONLY] . --
        assert(type(entity_configuration.inventory_types) == "table", "Inventory types must be a table !")                      -- [DEBUG-ONLY] . --
        assert(entity_configuration.options == nil or type(entity_configuration.options) == "table", "Inventory entity options must be a table !") -- [DEBUG-ONLY] . --

        local entity = entity_configuration.entity

        for _, inventory_type in ipairs(entity_configuration.inventory_types) do
            assert(type(inventory_type) == "number", "Inventory type must be a defines.inventory value !")      -- [DEBUG-ONLY] . --

            local lua_inventory = entity.get_inventory(inventory_type)

            if lua_inventory and lua_inventory.valid then
                local duplicate = false

                for _, existing_inventory in ipairs(lua_inventories) do
                    if existing_inventory == lua_inventory then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    lua_inventories[#lua_inventories + 1] = lua_inventory
                end
            end
        end
    end

    return lua_inventories
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager_metatable:monitorConfiguration(configuration)
    local lua_inventories = resolveConfiguration(configuration)

    assert(#lua_inventories > 0, "Inventory configuration did not resolve any LuaInventory !")      -- [DEBUG-ONLY] . --

    if #lua_inventories == 0 then
        return nil
    end

    for _, inventory in pairs(self.inventories) do
        if sourcesMatch(inventory:getSource(), lua_inventories) then
            if inventory.configuration == nil then
                inventory.configuration = configuration
            end

            return inventory
        end
    end

    local source = InventorySourceFactory.new(table.unpack(lua_inventories))
    local inventory = self:monitorInventory(source)

    inventory.configuration = configuration
    inventory:update()

    return inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager_metatable:monitorInventory(source)
    assert(source and source.object_name == "InventorySource", "Source must be a valid InventorySource !")                    -- [DEBUG-ONLY] . --

    if source.inventory then
        assert(source.inventory.object_name == "Inventory", "InventorySource contains an invalid Inventory reference !")     -- [DEBUG-ONLY] . --
        assert(source.inventory.manager == self, "InventorySource is already monitored by another InventoryManager !")       -- [DEBUG-ONLY] . --

        return source.inventory
    end

    local inventory_id = self.next_inventory_id

    local inventory = {                                  ---@type Inventory
        id             = inventory_id,
        name           = "Inventory " .. inventory_id,
        manager        = self,
        source         = source,
        configuration  = nil,
        windows        = { },
        next_window_id = 1,
        content        = { },
        counts         = { },
        previous       = { },
        next           = { },
        first          = nil,
        last           = nil,
        initialized    = false
    }

    setmetatable(inventory, inventory_metatable)

    self.inventories[inventory_id] = inventory
    self.next_inventory_id = inventory_id + 1
    source.inventory = inventory

    return inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

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

    local source     = inventory.source
    local window_ids = { }

    for window_id in pairs(inventory:getWindows()) do
        window_ids[#window_ids + 1] = window_id
    end

    for _, window_id in ipairs(window_ids) do
        inventory:removeWindow(window_id)
    end

    self.inventories[inventory.id] = nil
    source.inventory = nil
    InventorySourceFactory.destroy(source)

    inventory.name          = nil
    inventory.windows       = nil
    inventory.configuration = nil
    inventory.source        = nil
    inventory.manager       = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager_metatable:getInventories()
    return self.inventories
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager_metatable:updateInventory(lua_inventory)
    self:updateInventories({ lua_inventory })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

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

function factory.get(player)
    local player_index = resolve_player(player)
    local manager = storage.inventory_managers[player_index]     ---@type InventoryManager

    assert(manager and manager.object_name == "InventoryManager", "Player does not have a valid InventoryManager !")  -- [DEBUG-ONLY] . --

    return manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(player)
    local player_index = resolve_player(player)
    local manager = storage.inventory_managers[player_index]     ---@type InventoryManager

    assert(manager and manager.object_name == "InventoryManager", "Player does not have a valid InventoryManager !")  -- [DEBUG-ONLY] . --

    local inventory_ids = { }

    for inventory_id in pairs(manager.inventories) do
        inventory_ids[#inventory_ids + 1] = inventory_id
    end

    for _, inventory_id in ipairs(inventory_ids) do
        manager:unmonitorInventory(manager.inventories[inventory_id])
    end

    manager.inventories = { }
    manager.lua_player = nil
    storage.inventory_managers[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory