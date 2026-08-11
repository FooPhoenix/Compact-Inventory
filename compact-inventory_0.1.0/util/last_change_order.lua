
local ItemOrder = require("util.item_order")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Local Working Buffers.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local changed_items = { }
local changed_delta = { }

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ LastChangeOrder.                                                                                               ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class LastChangeOrder
---
--- ### This utility tracks player inventory changes and maintains items in last-change order.
---
local LastChangeOrder = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Detach an item from the linked list.
--
--- -----
--- @param state table       The player last-change state.
--- @param item_id integer   The item identifier to detach.
--
local function detachItem(state, item_id)

    local previous_id = state.previous[item_id]
    local next_id     = state.next[item_id]

    if previous_id then
        state.next[previous_id] = next_id
    elseif state.first == item_id then
        state.first = next_id
    else
        return
    end

    if next_id then
        state.previous[next_id] = previous_id
    else
        state.last = previous_id
    end

    state.previous[item_id] = nil
    state.next[item_id]     = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Prepend an item to the linked list.
--
--- -----
--- @param state table       The player last-change state.
--- @param item_id integer   The item identifier to prepend.
--
local function prependItem(state, item_id)

    local first_id = state.first

    state.previous[item_id] = nil
    state.next[item_id]     = first_id

    if first_id then
        state.previous[first_id] = item_id
    else
        state.last = item_id
    end

    state.first = item_id
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Initialize the last-change state for one player.
--
--- -----
--- @param player integer|LuaPlayer      The player to initialize.
--
function LastChangeOrder.initializePlayer(player)

    local player_index, player = resolve_player(player)
    local inventory = player.get_main_inventory()

    local state = {
        counts     = { },
        seen       = { },
        previous   = { },
        next       = { },
        first      = nil,
        last       = nil,
        generation = 0
    }

    if inventory then
        local previous_id

        for _, item in ipairs(inventory.get_contents()) do
            local item_id = ItemOrder.get(item.name, item.quality)

            state.counts[item_id]   = item.count
            state.previous[item_id] = previous_id

            if previous_id then
                state.next[previous_id] = item_id
            else
                state.first = item_id
            end

            previous_id = item_id
        end

        state.last = previous_id
    end

    storage.last_change_order[player_index] = state
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Initialize the global last-change inventory tracking state.
--
function LastChangeOrder.initialize()

    storage.last_change_order = { }

    for _, player in pairs(game.players) do
        LastChangeOrder.initializePlayer(player)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Update one player's last-change state from the current main inventory contents.
--
--- -----
--- @param player integer|LuaPlayer      The player to update.
--
function LastChangeOrder.update(player)

    local player_index, player = resolve_player(player)
    local inventory = player.get_main_inventory()
    local state = storage.last_change_order[player_index]

    assert(state, "Last change state does not exist for player " .. player_index .. " !")      -- [DEBUG-ONLY] . --
    assert(#changed_items == 0 and next(changed_delta) == nil, "Last change working buffers must be empty !")      -- [DEBUG-ONLY] . --

    if not inventory then
        return
    end

    state.generation = state.generation + 1

    local generation = state.generation

    for _, item in ipairs(inventory.get_contents()) do
        local item_id   = ItemOrder.get(item.name, item.quality)
        local old_count = state.counts[item_id]

        state.seen[item_id] = generation

        if old_count ~= item.count then
            changed_items[#changed_items + 1] = item_id
            changed_delta[item_id] = math.abs(item.count - (old_count or 0))
            state.counts[item_id] = item.count
        end
    end

    for item_id in pairs(state.counts) do
        if state.seen[item_id] ~= generation then
            detachItem(state, item_id)
            state.counts[item_id]   = nil
            state.seen[item_id]     = nil
            state.previous[item_id] = nil
            state.next[item_id]     = nil
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

        detachItem(state, item_id)
        prependItem(state, item_id)

        changed_delta[item_id] = nil
        changed_items[index]   = nil
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Order the current item list using the maintained last-change linked list.
--
--- -----
--- @param player integer|LuaPlayer      The player whose order must be used.
--- @param items table                   The item list to order.
--
--- @return table                        @ The ordered item list.
--
function LastChangeOrder.sort(player, items)

    local player_index = resolve_player(player)
    local state = storage.last_change_order[player_index]

    assert(state, "Last change state does not exist for player " .. player_index .. " !")      -- [DEBUG-ONLY] . --

    local items_by_id  = { }
    local sorted_items = { }

    for _, item in ipairs(items) do
        items_by_id[ItemOrder.get(item.name, item.quality)] = item
    end

    local item_id = state.first

    while item_id do
        local item = items_by_id[item_id]

        assert(item, "Last change order contains an item that is not in the current inventory !")      -- [DEBUG-ONLY] . --

        if item then
            sorted_items[#sorted_items + 1] = item
        end

        item_id = state.next[item_id]
    end

    assert(#sorted_items == #items, "Last change sorting did not resolve every item !")      -- [DEBUG-ONLY] . --

    return sorted_items
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return LastChangeOrder
