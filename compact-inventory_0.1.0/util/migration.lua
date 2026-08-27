require("debug.character_switch_test")

local ItemKey   = require("util.item_key")
local ItemOrder = require("util.item_order")

local QUALITY_ORDER_GAP  = 256
local QUALITY_KEY_PREFIX = "\31"

local Migration = { }

local function getOldQualityByOffset()
    local quality_by_offset = { }

    for key, value in pairs(storage.item_order or { }) do
        if type(key) == "string" and key:sub(1, 1) == QUALITY_KEY_PREFIX then
            quality_by_offset[value] = key:sub(2)
        end
    end

    return quality_by_offset
end

local function oldBaseIDToName(item_id)
    return storage.item_order_names and storage.item_order_names[item_id] or nil
end

local function oldItemIDToKey(item_id, quality_by_offset)
    if type(item_id) == "string" then
        return item_id
    end

    assert(type(item_id) == "number", "Stored item identifier must be a number or string !")      -- [DEBUG-ONLY] . --

    local direct_name = oldBaseIDToName(item_id)

    if direct_name then
        return ItemKey.create(direct_name)
    end

    local base_id        = item_id - item_id % QUALITY_ORDER_GAP
    local item_name      = oldBaseIDToName(base_id)
    local quality_offset = item_id - base_id
    local quality_name   = quality_by_offset[quality_offset]

    assert(item_name, "Old item identifier cannot be resolved to an item name !")      -- [DEBUG-ONLY] . --
    assert(quality_name, "Old item identifier cannot be resolved to a quality name !") -- [DEBUG-ONLY] . --

    return item_name and ItemKey.create(item_name, quality_name) or nil
end

local function convertCustomOrder(order)
    if type(order) ~= "table" then
        return
    end

    for index, item in ipairs(order) do
        if type(item) == "number" then
            local item_name = oldBaseIDToName(item)

            assert(item_name, "Old custom-sort item identifier cannot be resolved !")      -- [DEBUG-ONLY] . --
            order[index] = item_name
        end
    end
end

local function convertLastChangeState(inventory, quality_by_offset)
    if not inventory.initialized or inventory.first == nil then
        return
    end

    local old_counts   = inventory.counts
    local old_next     = inventory.next
    local old_item     = inventory.first
    local new_counts   = { }
    local new_previous = { }
    local new_next     = { }
    local new_first
    local new_last
    local previous_key

    while old_item do
        local item_key = oldItemIDToKey(old_item, quality_by_offset)

        if item_key then
            new_counts[item_key]   = old_counts[old_item]
            new_previous[item_key] = previous_key

            if previous_key then
                new_next[previous_key] = item_key
            else
                new_first = item_key
            end

            previous_key = item_key
            new_last     = item_key
        end

        old_item = old_next[old_item]
    end

    inventory.counts   = new_counts
    inventory.previous = new_previous
    inventory.next     = new_next
    inventory.first    = new_first
    inventory.last     = new_last
end

local function forEachInventoryView(callback)
    for _, manager in pairs(storage.inventory_managers or { }) do
        for _, inventory in pairs(manager.inventories or { }) do
            for _, window in pairs(inventory.windows or { }) do
                for _, item_group in ipairs(window.item_groups or { }) do
                    if item_group.inventory_view then
                        callback(item_group.inventory_view)
                    end
                end
            end
        end
    end
end

local function forEachInventory(callback)
    for _, manager in pairs(storage.inventory_managers or { }) do
        for _, inventory in pairs(manager.inventories or { }) do
            callback(inventory)
        end
    end
end

local function forEachStoredCustomOrder(callback)
    forEachInventoryView(function(view)
        if view.custom_order then
            callback(view.custom_order)
        end
    end)

    local custom_sort_storage = storage.presets and storage.presets.custom_sort

    for _, preset in pairs(custom_sort_storage and custom_sort_storage.presets or { }) do
        if preset.data and preset.data.order then
            callback(preset.data.order)
        end
    end

    local window_storage = storage.presets and storage.presets.windows

    for _, preset in pairs(window_storage and window_storage.presets or { }) do
        for _, group in ipairs(preset.data and preset.data.groups or { }) do
            if group.custom_order then
                callback(group.custom_order)
            end
        end
    end
end

local function reconcileCustomOrder(order)
    local reconciled = { }
    local seen       = { }

    for _, item_name in ipairs(order or { }) do
        if type(item_name) == "string" and prototypes.item[item_name] and not seen[item_name] then
            reconciled[#reconciled + 1] = item_name
            seen[item_name] = true
        end
    end

    for index = 1, ItemOrder.getItemCount() do
        local item_name = ItemOrder.getName(ItemOrder.getItemID(index))

        if not seen[item_name] then
            reconciled[#reconciled + 1] = item_name
            seen[item_name] = true
        end
    end

    return reconciled
end

local function reconcileLastChangeState(inventory)
    if not inventory.initialized or inventory.first == nil then
        return
    end

    local old_counts   = inventory.counts
    local old_next     = inventory.next
    local item_key     = inventory.first
    local new_counts   = { }
    local new_previous = { }
    local new_next     = { }
    local new_first
    local new_last
    local previous_key

    while item_key do
        local next_key = old_next[item_key]

        if type(item_key) == "string" and ItemKey.exists(item_key) then
            new_counts[item_key]   = old_counts[item_key]
            new_previous[item_key] = previous_key

            if previous_key then
                new_next[previous_key] = item_key
            else
                new_first = item_key
            end

            previous_key = item_key
            new_last     = item_key
        end

        item_key = next_key
    end

    inventory.counts   = new_counts
    inventory.previous = new_previous
    inventory.next     = new_next
    inventory.first    = new_first
    inventory.last     = new_last
end

function Migration.prepareItemIdentityMigration()
    if not storage.item_order_names then
        return
    end

    local quality_by_offset = getOldQualityByOffset()

    forEachStoredCustomOrder(convertCustomOrder)

    forEachInventory(function(inventory)
        convertLastChangeState(inventory, quality_by_offset)
    end)
end

function Migration.reconcileItemData()
    forEachStoredCustomOrder(function(order)
        local reconciled = reconcileCustomOrder(order)

        for index = #order, 1, -1 do
            order[index] = nil
        end

        for index, item_name in ipairs(reconciled) do
            order[index] = item_name
        end
    end)

    forEachInventory(reconcileLastChangeState)
end

return Migration
