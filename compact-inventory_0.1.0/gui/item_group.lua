
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ ItemGroupMetatable.                                                                                            ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class ItemGroupMetatable
---
--- ### This class groups all functions used to manage an item group.
---
--- @field private id             integer            The stable group identifier inside its window.
--- @field private inventory_view InventoryView      The inventory projection displayed by the group.
--- @field private name           string             The displayed group name.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "ItemGroup"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "ItemGroupMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the stable group identifier inside its window.
--
--- -----
--- @return integer      @ The group identifier.
--
function metatable:getID()
    assert(type(self.id) == "number" and self.id > 0, "ItemGroup ID must be a positive integer !")      -- [DEBUG-ONLY] . --
    return self.id
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the InventoryView owned by the group.
--
--- -----
--- @return InventoryView      @ The inventory view owned by the group.
--
function metatable:getView()

    assert(self.inventory_view and self.inventory_view.object_name == "InventoryView", "ItemGroup must have a valid InventoryView !")      -- [DEBUG-ONLY] . --

    return self.inventory_view
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the displayed group name.
--
--- -----
--- @return string      @ The group name.
--
function metatable:getName()
    assert(type(self.name) == "string", "ItemGroup name must be a string !")      -- [DEBUG-ONLY] . --
    return self.name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the displayed group name.
--
--- -----
--- @param name string      The new group name.
--
function metatable:setName(name)
    assert(type(name) == "string", "ItemGroup name must be a string !")      -- [DEBUG-ONLY] . --
    self.name = name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the content displayed by the group.
--
--- -----
--- @return table      @ The item list to display.
--
function metatable:getContent()
    return self:getView():getContent()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the sorting mode used by the group.
--
--- -----
--- @return SortMode      @ The current sorting mode.
--
function metatable:getSortMode()
    return self:getView():getSortMode()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the sorting mode used by the group.
--
--- -----
--- @param sort_mode SortMode      The sorting mode to activate.
--
function metatable:setSortMode(sort_mode)
    self:getView():setSortMode(sort_mode)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the custom item order used by the group.
--
--- -----
--- @return integer[]      @ The custom base item identifiers in display order.
--
function metatable:getCustomOrder()
    return self:getView():getCustomOrder()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the filtering mode used by the group.
--
--- -----
--- @return FilterMode      @ The current filtering mode.
--
function metatable:getFilterMode()
    return self:getView():getFilterMode()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the filtering mode used by the group.
--
--- -----
--- @param filter_mode FilterMode      The filtering mode to activate.
--
function metatable:setFilterMode(filter_mode)
    self:getView():setFilterMode(filter_mode)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get all positioned item filters.
--
--- -----
--- @return table<integer, string>      @ The positioned item filters.
--
function metatable:getFilters()
    return self:getView():getFilters()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set one positioned item filter.
--
--- -----
--- @param slot_index integer      The filter slot index.
--- @param item_name string|nil    The item name, or nil to clear the slot.
--
function metatable:setFilter(slot_index, item_name)
    self:getView():setFilter(slot_index, item_name)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the number of filter slots that should currently be visible.
--
--- -----
--- @return integer      @ The number of visible filter slots.
--
function metatable:getVisibleFilterSlotCount()
    return self:getView():getVisibleFilterSlotCount()
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ ItemGroup.                                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class ItemGroup: ItemGroupMetatable
---
--- ### This class represents one logical group of items displayed in an InventoryWindow.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ ItemGroupFactory.                                                                                              ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class ItemGroupFactory
---
--- ### This class groups all functions used to create item groups.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new item group.
--
--- -----
--- @param inventory Inventory      The logical inventory projected by the group.
--- @param id integer               The stable identifier inside its window.
--
--- @return ItemGroup              @ Returns the created item group.
--
function factory.new(inventory, id)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --
    assert(type(id) == "number" and id > 0, "ItemGroup ID must be a positive integer !")                        -- [DEBUG-ONLY] . --

    local item_group = {                                  ---@type ItemGroup
        id             = id,
        inventory_view = InventoryViewFactory.new(inventory),
        name           = "Inventory"
    }

    setmetatable(item_group, metatable)

    return item_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
