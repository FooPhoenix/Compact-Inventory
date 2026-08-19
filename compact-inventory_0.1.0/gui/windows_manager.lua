
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local InventoryWindowFactory  = require("gui.inventory_window")
local InventorySourceFactory  = require("inventory.inventory_source")
local InventoryManagerFactory = require("inventory.inventory_manager")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

---
--- @class WindowsManager
---
--- ### This class groups all functions used to create and manage GUI windows.
---
--
local manager = {
    exposed_gui_names = {
        InventoryWindow = InventoryWindowFactory.exposed_gui_names
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initialize()

    storage.windows = { }
    storage.windows.main_inventory = { }

    for _, lua_player in pairs(game.players) do
        manager.initializePlayer(lua_player)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initializePlayer(player)

    local _, lua_player = resolve_player(player)
    local lua_inventory = lua_player.get_main_inventory()

    assert(lua_inventory and lua_inventory.valid, "Player must have a valid main LuaInventory !")      -- [DEBUG-ONLY] . --

    local source    = InventorySourceFactory.new(lua_inventory)
    local inventory = InventoryManagerFactory.get(lua_player):monitorInventory(source)

    inventory:update()
    InventoryWindowFactory.create(lua_player, inventory)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.hasWindowMainInventory(player)

    local player_index = resolve_player(player)
    local window = storage.windows.main_inventory[player_index]

    return window ~= nil and window.valid
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.createWindowMainInventory(player)

    local player_index, lua_player = resolve_player(player)

    assert(not manager.hasWindowMainInventory(lua_player), "Player already has a main inventory window !")      -- [DEBUG-ONLY] . --

    if storage.windows.main_inventory[player_index] then
        storage.windows.main_inventory[player_index] = nil
    end

    local lua_inventory = lua_player.get_main_inventory()

    assert(lua_inventory and lua_inventory.valid, "Player must have a valid main LuaInventory !")      -- [DEBUG-ONLY] . --

    local inventory

    for _, monitored_inventory in pairs(InventoryManagerFactory.get(lua_player):getInventories()) do
        if monitored_inventory:getSource():containsInventory(lua_inventory) then
            assert(inventory == nil, "Several monitored Inventory contain the player's main LuaInventory !")      -- [DEBUG-ONLY] . --
            inventory = monitored_inventory
        end
    end

    assert(inventory, "No monitored Inventory contains the player's main LuaInventory !")      -- [DEBUG-ONLY] . --

    return InventoryWindowFactory.create(lua_player, inventory)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.destroyWindowMainInventory(player)
    InventoryWindowFactory.destroy(player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getWindowMainInventory(player)

    local player_index = resolve_player(player)

    assert(storage.windows.main_inventory[player_index], "Player does not have a main inventory window !")                                    -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].valid, "Player does not have a main inventory window !")                              -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].object_name == "InventoryWindow", "Player does not have a valid inventory window !") -- [DEBUG-ONLY] . --

    return storage.windows.main_inventory[player_index]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return manager
