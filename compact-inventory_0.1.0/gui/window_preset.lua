-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function applyGroup(window, item_group, data)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup does not exist or is invalid !")  -- [DEBUG-ONLY] . --
    assert(type(data) == "table", "Window preset group data must be a table !")                                -- [DEBUG-ONLY] . --

    if data.name ~= nil then
        item_group:setName(data.name)
    end

    if data.custom_order ~= nil then
        item_group:setCustomOrder(data.custom_order)
    end

    if data.filter ~= nil then
        if data.filter.mode ~= nil then
            item_group:setFilterMode(data.filter.mode)
        end

        if data.filter.filters ~= nil then
            item_group:setFilters(data.filter.filters)
        end
    end

    if data.sort_mode ~= nil then
        item_group:setSortMode(data.sort_mode)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.apply(window, data)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(type(data) == "table", "Window preset data must be a table !")                                     -- [DEBUG-ONLY] . --

    if type(data.groups) ~= "table" or #data.groups == 0 then
        return
    end

    local first_group = window:getDefaultItemGroup()

    applyGroup(window, first_group, data.groups[1])

    for index = 2, #data.groups do
        applyGroup(window, window:createItemGroup(), data.groups[index])
    end

    for _, item_group in ipairs(window:getItemGroups()) do
        window:setItemGroupName(item_group:getID(), item_group:getName())
        window:refreshSortIcon(item_group:getID())
        window:refreshGroup(item_group)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
