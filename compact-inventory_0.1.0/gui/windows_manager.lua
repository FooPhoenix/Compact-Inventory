-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local MainWindowFactory       = require("gui.main_window")
local InventoryWindowFactory  = require("gui.inventory_window")
local InventorySourceFactory  = require("inventory.inventory_source")
local InventoryManagerFactory = require("inventory.inventory_manager")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local manager = {
    exposed_gui_names = {
        MainWindow      = MainWindowFactory.exposed_gui_names,
        InventoryWindow = InventoryWindowFactory.exposed_gui_names
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getMainInventory(player)
    local _, lua_player = resolve_player(player)
    local lua_inventory = lua_player.get_main_inventory()
    local inventory

    assert(lua_inventory and lua_inventory.valid, "Player must have a valid main LuaInventory !")      -- [DEBUG-ONLY] . --

    for _, monitored_inventory in pairs(InventoryManagerFactory.get(lua_player):getInventories()) do
        if monitored_inventory:getSource():containsInventory(lua_inventory) then
            assert(inventory == nil, "Several monitored Inventory contain the player's main LuaInventory !")      -- [DEBUG-ONLY] . --
            inventory = monitored_inventory
        end
    end

    return inventory
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getFirstWindow(inventory)
    if not inventory then
        return nil
    end

    local first_id

    for window_id, window in pairs(inventory:getWindows()) do
        if window.valid and (not first_id or window_id < first_id) then
            first_id = window_id
        end
    end

    return first_id and inventory:getWindow(first_id) or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initialize()
    storage.windows = { }
    storage.windows.main = { }

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
    inventory:createWindow()
    MainWindowFactory.create(lua_player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.hasMainWindow(player)
    local player_index = resolve_player(player)
    local window = storage.windows.main[player_index]

    return window ~= nil and window.valid
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getMainWindow(player)
    local player_index = resolve_player(player)
    local window = storage.windows.main[player_index]

    assert(window and window.valid and window.object_name == "MainWindow", "Player does not have a valid main window !")      -- [DEBUG-ONLY] . --

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

-- [TRANSITION] Compatibility helpers for control.lua while only one InventoryWindow can be created from the UI. --

function manager.hasWindowMainInventory(player)
    return getFirstWindow(getMainInventory(player)) ~= nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.createWindowMainInventory(player)
    local inventory = getMainInventory(player)

    assert(inventory, "No monitored Inventory contains the player's main LuaInventory !")      -- [DEBUG-ONLY] . --

    return inventory:createWindow()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.destroyWindowMainInventory(player)
    local inventory = getMainInventory(player)
    local window    = getFirstWindow(inventory)

    assert(window, "Player does not have a main inventory window !")      -- [DEBUG-ONLY] . --

    inventory:removeWindow(window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getWindowMainInventory(player)
    local window = getFirstWindow(getMainInventory(player))

    assert(window and window.valid and window.object_name == "InventoryWindow", "Player does not have a valid inventory window !")      -- [DEBUG-ONLY] . --

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return manager
