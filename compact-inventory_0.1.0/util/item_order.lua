
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Constant Declaration.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local QUALITY_ORDER_GAP  = 256
local QUALITY_KEY_PREFIX = "\31"      -- ASCII Unit Separator cannot appear in prototype names.

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

--- ### Compare two prototypes using their standard order and name fallback.
--
--- -----
--- @param prototype_a LuaPrototypeBase      The first prototype.
--- @param prototype_b LuaPrototypeBase      The second prototype.
--
--- @return boolean                          @ Whether prototype_a must be placed before prototype_b.
--
local function comparePrototypes(prototype_a, prototype_b)

    if prototype_a.order ~= prototype_b.order then
        return prototype_a.order < prototype_b.order
    end

    return prototype_a.name < prototype_b.name
end

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

--- ### Build the global item and quality ordering indexes.
--
function ItemOrder.initialize()

    local item_prototypes    = { }
    local quality_prototypes = { }

    for _, item_prototype in pairs(prototypes.item) do
        item_prototypes[#item_prototypes + 1] = item_prototype
    end

    for _, quality_prototype in pairs(prototypes.quality) do
        quality_prototypes[#quality_prototypes + 1] = quality_prototype
    end

    table.sort(item_prototypes, compareItemPrototypes)
    table.sort(quality_prototypes, comparePrototypes)

    assert(#quality_prototypes < QUALITY_ORDER_GAP, "Too many quality prototypes for the item order gap !")      -- [DEBUG-ONLY] . --

    storage.item_order = { }

    for index, item_prototype in ipairs(item_prototypes) do
        storage.item_order[item_prototype.name] = index * QUALITY_ORDER_GAP
    end

    for index, quality_prototype in ipairs(quality_prototypes) do
        storage.item_order[QUALITY_KEY_PREFIX .. quality_prototype.name] = index
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the global Factorio order index of an item, optionally including its quality.
--
--- -----
--- @param item_name string                The item prototype name.
--- @param quality_name? string            The quality prototype name.
--
--- @return integer                        @ The global Factorio order index.
--
function ItemOrder.get(item_name, quality_name)

    assert(storage.item_order, "Item order index is not initialized !")                                 -- [DEBUG-ONLY] . --
    assert(storage.item_order[item_name], "Item does not exist in the item order index: " .. item_name)  -- [DEBUG-ONLY] . --

    local order = storage.item_order[item_name]

    if quality_name then
        local quality_order = storage.item_order[QUALITY_KEY_PREFIX .. quality_name]

        assert(quality_order, "Quality does not exist in the item order index: " .. quality_name)         -- [DEBUG-ONLY] . --

        order = order + quality_order
    end

    return order
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return ItemOrder
