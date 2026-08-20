
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

---@enum FilterMode
local FilterMode = {
    blacklist = 1,
    whitelist = 2
}

local FILTER_COLUMNS = 10
local MIN_FILTER_ROWS = 2

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryViewMetatable.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryViewMetatable
---
--- ### This class groups all functions used to project an Inventory for display.
---
--- @field private inventory    Inventory               The logical inventory projected by the view.
--- @field private sort_mode    SortMode                The current sorting mode.
--- @field private filter_mode  FilterMode              The current filtering mode.
--- @field private filters      table<integer, string>  The positioned item filters.
--- @field private custom_order integer[]               The custom item order using base ItemOrder identifiers.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "InventoryView"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryViewMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function createDefaultCustomOrder()
    local custom_order = { }

    for index = 1, ItemOrder.getItemCount() do
        custom_order[index] = ItemOrder.getItemID(index)
    end

    return custom_order
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getInventory()

    assert(self.inventory and self.inventory.object_name == "Inventory", "InventoryView must have a valid Inventory !")      -- [DEBUG-ONLY] . --

    return self.inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getSortMode()
    return self.sort_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setSortMode(sort_mode)

    assert(type(sort_mode) == "number" and sort_mode >= 1 and sort_mode <= 6, "Sort mode must be a number between 1 and 6 !")      -- [DEBUG-ONLY] . --

    self.sort_mode = sort_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getCustomOrder()
    if not self.custom_order then
        self.custom_order = createDefaultCustomOrder()
    end

    assert(type(self.custom_order) == "table", "InventoryView custom order must be a table !")      -- [DEBUG-ONLY] . --

    return self.custom_order
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:moveCustomItem(source_index, target_index)

    local custom_order = self:getCustomOrder()

    assert(type(source_index) == "number" and source_index >= 1 and source_index <= #custom_order and source_index % 1 == 0, "Custom sort source index must be valid !")      -- [DEBUG-ONLY] . --
    assert(type(target_index) == "number" and target_index >= 1 and target_index <= #custom_order and target_index % 1 == 0, "Custom sort target index must be valid !")      -- [DEBUG-ONLY] . --

    if source_index == target_index then
        return
    end

    local item_id = table.remove(custom_order, source_index)

    if source_index < target_index then
        target_index = target_index - 1
    end

    table.insert(custom_order, target_index, item_id)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFilterMode()
    return self.filter_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setFilterMode(filter_mode)

    assert(filter_mode == FilterMode.blacklist or filter_mode == FilterMode.whitelist, "Filter mode must be valid !")      -- [DEBUG-ONLY] . --

    self.filter_mode = filter_mode
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFilters()
    assert(type(self.filters) == "table", "InventoryView filters must be a table !")      -- [DEBUG-ONLY] . --
    return self.filters
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setFilter(slot_index, item_name)

    assert(type(slot_index) == "number" and slot_index > 0 and slot_index % 1 == 0, "Filter slot index must be a positive integer !")      -- [DEBUG-ONLY] . --
    assert(item_name == nil or type(item_name) == "string", "Filter item must be a string or nil !")                                      -- [DEBUG-ONLY] . --

    self.filters[slot_index] = item_name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getVisibleFilterSlotCount()

    local last_used_slot = 0

    for slot_index, item_name in pairs(self:getFilters()) do
        if item_name and slot_index > last_used_slot then
            last_used_slot = slot_index
        end
    end

    local visible_rows = last_used_slot > 0
        and math.floor((last_used_slot - 1) / FILTER_COLUMNS) + 2
        or MIN_FILTER_ROWS

    if visible_rows < MIN_FILTER_ROWS then
        visible_rows = MIN_FILTER_ROWS
    end

    return visible_rows * FILTER_COLUMNS
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function filterItems(view, items)

    local filter_lookup = { }

    for _, item_name in pairs(view:getFilters()) do
        if item_name then
            filter_lookup[item_name] = true
        end
    end

    local filtered_items = { }
    local whitelist      = (view:getFilterMode() == FilterMode.whitelist)

    for _, item in ipairs(items) do
        local matched = filter_lookup[item.name] == true

        if matched == whitelist then
            filtered_items[#filtered_items + 1] = item
        end
    end

    return filtered_items
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the projected inventory content according to the current sorting and filtering modes.
--
--- Sorting always operates on the complete logical inventory. Filtering is applied afterwards so hiding an item never
--- alters or invalidates stateful ordering strategies such as last-change ordering.
--
--- -----
--- @return table      @ The item list to display.
--
function metatable:getContent()

    local inventory = self:getInventory()
    local items     = inventory:getContent()
    local sorted_items

    if self.sort_mode == SortMode.standard then
        sorted_items = items

    elseif self.sort_mode == SortMode.inventory then

        local items_by_order = { }
        sorted_items         = { }

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

    elseif self.sort_mode == SortMode.last_change then
        sorted_items = inventory:sortByLastChange(items)

    elseif self.sort_mode == SortMode.count_ascending or self.sort_mode == SortMode.count_descending then
        sorted_items = { }

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

    else
        sorted_items = items
    end

    return filterItems(self, sorted_items)
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

local factory = {
    sort_modes   = SortMode,
    filter_modes = FilterMode
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.new(inventory)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --

    local view = {                                      ---@type InventoryView
        inventory    = inventory,
        sort_mode    = SortMode.standard,
        filter_mode  = FilterMode.blacklist,
        filters      = { },
        custom_order = createDefaultCustomOrder()
    }

    setmetatable(view, metatable)

    return view
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
