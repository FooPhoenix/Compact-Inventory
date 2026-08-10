
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ ItemOrder.                                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class ItemOrder
---
--- ### This utility builds and exposes the global Factorio item ordering index.
---
local ItemOrder = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Compare two item prototypes using Factorio's standard item ordering rules.
--
--- -----
--- @param item_a LuaItemPrototype      The first item prototype.
--- @param item_b LuaItemPrototype      The second item prototype.
--
--- @return boolean                     @ Whether item_a must be placed before item_b.
--
local function compareItemPrototypes(item_a, item_b)

    local group_a = item_a.group
    local group_b = item_b.group

    if group_a.order ~= group_b.order then
        return group_a.order < group_b.order
    elseif group_a.name ~= group_b.name then
        return group_a.name < group_b.name
    end

    local subgroup_a = item_a.subgroup
    local subgroup_b = item_b.subgroup

    if subgroup_a.order ~= subgroup_b.order then
        return subgroup_a.order < subgroup_b.order
    elseif subgroup_a.name ~= subgroup_b.name then
        return subgroup_a.name < subgroup_b.name
    elseif item_a.order ~= item_b.order then
        return item_a.order < item_b.order
    end

    return item_a.name < item_b.name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Build the global item ordering index.
--
function ItemOrder.initialize()

    local item_prototypes = { }

    for _, item_prototype in pairs(prototypes.item) do
        item_prototypes[#item_prototypes + 1] = item_prototype
    end

    table.sort(item_prototypes, compareItemPrototypes)

    storage.item_order = { }

    for index, item_prototype in ipairs(item_prototypes) do
        storage.item_order[item_prototype.name] = index
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the global Factorio order index of an item.
--
--- -----
--- @param item_name string      The item prototype name.
--
--- @return integer              @ The global Factorio order index.
--
function ItemOrder.get(item_name)

    assert(storage.item_order, "Item order index is not initialized !")                                 -- [DEBUG-ONLY] . --
    assert(storage.item_order[item_name], "Item does not exist in the item order index: " .. item_name)  -- [DEBUG-ONLY] . --

    return storage.item_order[item_name]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return ItemOrder
