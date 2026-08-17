
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
--- @field private inventory_view InventoryView      The inventory projection displayed by the group.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "ItemGroup"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "ItemGroupMetatable", metatable)
metatable.__index = metatable

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
--
--- @return ItemGroup              @ Returns the created item group.
--
function factory.new(inventory)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --

    local item_group = {                                  ---@type ItemGroup
        inventory_view = InventoryViewFactory.new(inventory)
    }

    setmetatable(item_group, metatable)

    return item_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
