
local ItemOrder = require("util.item_order")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Constant Declaration.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---@enum SortMode
local SortMode = {
    standard         = 1,
    count_ascending  = 2,
    count_descending = 3,
    inventory        = 4,
    last_change      = 5,
    custom           = 6
}

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryViewMetatable.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryViewMetatable
---
--- ### This class groups all functions used to project an Inventory for display.
---
--- @field private inventory Inventory      The logical inventory projected by the view.
--- @field private sort_mode SortMode       The current sorting mode.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "InventoryView"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryViewMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the logical Inventory projected by the view.
--
--- -----
--- @return Inventory      @ The projected Inventory.
--
function metatable:getInventory()

    assert(self.inventory and self.inventory.object_name == "Inventory", "InventoryView must have a valid Inventory !")      -- [DEBUG-ONLY] . --

    return self.inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the current sorting mode.
--
--- -----
--- @return SortMode      @ The current sorting mode.
--
function metatable:getSortMode()
    return self.sort_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the sorting mode.
--
--- -----
--- @param sort_mode SortMode      The sorting mode to activate.
--
function metatable:setSortMode(sort_mode)

    assert(type(sort_mode) == "number" and sort_mode >= 1 and sort_mode <= 6, "Sort mode must be a number between 1 and 6 !")      -- [DEBUG-ONLY] . --

    self.sort_mode = sort_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the projected inventory content according to the current sorting mode.
--
--- -----
--- @return table      @ The item list to display.
--
function metatable:getContent()

    local inventory = self:getInventory()
    local items     = inventory:getContent()

    if self.sort_mode == SortMode.standard then
        return items
    end

    if self.sort_mode == SortMode.inventory then

        local items_by_order = { }
        local sorted_items   = { }

        for _, item in ipairs(items) do
            items_by_order[ItemOrder.get(item.name, item.quality)] = item
        end

        for _, lua_inventory in ipairs(inventory:getSource():getInventories()) do
            if lua_inventory.valid then
                for slot_index = 1, #lua_inventory do
                    local stack = lua_inventory[slot_index]

                    if stack.valid_for_read then
                        local order = ItemOrder.get(stack.name, stack.quality.name)
                        local item  = items_by_order[order]

                        if item then
                            sorted_items[#sorted_items + 1] = item
                            items_by_order[order] = nil
                        end
                    end
                end
            end
        end

        assert(#sorted_items == #items, "Inventory sorting did not resolve every item !")      -- [DEBUG-ONLY] . --

        return sorted_items
    end

    if self.sort_mode == SortMode.last_change then
        return inventory:sortByLastChange(items)
    end

    if self.sort_mode ~= SortMode.count_ascending and self.sort_mode ~= SortMode.count_descending then
        return items
    end

    local sorted_items = { }

    for index, item in ipairs(items) do
        sorted_items[index] = item
    end

    table.sort(sorted_items, function(item_a, item_b)

        if item_a.count ~= item_b.count then
            if self.sort_mode == SortMode.count_ascending then
                return item_a.count < item_b.count
            else
                return item_a.count > item_b.count
            end
        end

        local order_a = ItemOrder.get(item_a.name, item_a.quality)
        local order_b = ItemOrder.get(item_b.name, item_b.quality)

        return order_a < order_b
    end)

    return sorted_items
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryView.                                                                                                ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryView: InventoryViewMetatable
---
--- ### This class represents a display projection of a logical Inventory.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryViewFactory.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryViewFactory
---
--- ### This class groups all functions used to create inventory views.
---
local factory = {
    sort_modes = SortMode
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new inventory view.
--
--- -----
--- @param inventory Inventory      The logical Inventory projected by the view.
--
--- @return InventoryView          @ Returns the created InventoryView.
--
function factory.new(inventory)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --

    local view = {                                      ---@type InventoryView
        inventory = inventory,
        sort_mode = SortMode.standard
    }

    setmetatable(view, metatable)

    return view
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
