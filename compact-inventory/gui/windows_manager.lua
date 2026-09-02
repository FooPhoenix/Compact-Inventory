-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local MainWindowFactory        = require("gui.main_window")
local InventoryWindowFactory   = require("gui.inventory_window")
local InventoryWindowScheduler = require("gui.inventory_window_scheduler")
local InventoryManagerFactory  = require("inventory.inventory_manager")
local InventoryType            = require("inventory.inventory_type")
local SourceType               = require("inventory.source_type")
local SchedulerFactory         = require("util.scheduler")

InventoryWindowScheduler.install(InventoryWindowFactory)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local manager = {
    exposed_gui_names = {
        MainWindow      = MainWindowFactory.exposed_gui_names,
        InventoryWindow = InventoryWindowFactory.exposed_gui_names
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local scheduler_tick_handler

local function installSchedulerTickHandler()
    local current_handler = script.get_event_handler(defines.events.on_tick)

    if current_handler == scheduler_tick_handler then
        return
    end

    local previous_handler = current_handler

    scheduler_tick_handler = function(event)
        if storage.scheduler then
            SchedulerFactory.get():execute(event.tick)
        end

        if previous_handler then
            previous_handler(event)
        end
    end

    script.on_event(defines.events.on_tick, scheduler_tick_handler)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_load(function()
    installSchedulerTickHandler()
end)

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

local function refreshMainWindow(player)
    if manager.hasMainWindow(player) then
        manager.getMainWindow(player):refresh()
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initialize()
    SchedulerFactory.initialize()
    installSchedulerTickHandler()

    storage.windows = { }
    storage.windows.main = { }

    for _, lua_player in pairs(game.players) do
        manager.initializePlayer(lua_player)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initializePlayer(player)
    local _, lua_player = resolve_player(player)
    local inventory_manager = InventoryManagerFactory.get(lua_player)
    local inventory = inventory_manager:monitorConfiguration({
        sources = {
            {
                type   = SourceType.player,
                player = lua_player,
                inventory_types = {
                    InventoryType.character_main
                },
                options = { }
            }
        },
        options = { }
    })

    assert(inventory, "Player inventory configuration must resolve an Inventory !")      -- [DEBUG-ONLY] . --

    inventory_manager:ensureCharacterTracking()
    inventory:createWindow()
    MainWindowFactory.create(lua_player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.ensureCharacterTracking(player)
    return InventoryManagerFactory.get(player):ensureCharacterTracking()
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

function manager.rebuildGUI(player)
    local player_index, lua_player = resolve_player(player)
    local main_window = storage.windows and storage.windows.main and storage.windows.main[player_index] or nil
    local main_visible
    local main_location

    if main_window and main_window.object_name == "MainWindow" then
        local frame = lua_player.gui.screen[MOD_PREFIX .. "MW_frame"]

        if frame then
            main_visible  = frame.visible
            main_location = frame.location
            frame.destroy()
        end
    end

    local inventory_manager = InventoryManagerFactory.get(lua_player)

    for _, inventory in pairs(inventory_manager:getInventories()) do
        for _, window in pairs(inventory:getWindows()) do
            InventoryWindowScheduler.ensure(window)

            local frame       = lua_player.gui.screen[window:getFrameName()]
            local was_visible = frame and frame.visible or true
            local location    = frame and frame.location or nil
            local was_locked  = window:isLocked()

            if frame then
                frame.destroy()
            end

            if was_locked then
                window.locked = false
            end

            InventoryWindowFactory.createGUI(window)

            if location then
                window:getFrame().location = location
            end

            if was_locked then
                window:setLocked(true)
            end

            window:setVisible(was_visible)
        end
    end

    if main_window and main_window.object_name == "MainWindow" then
        MainWindowFactory.createGUI(main_window)

        if main_location then
            main_window:getFrame().location = main_location
        end

        main_window:setVisible(main_visible == true)
    end
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

    local window = inventory:createWindow()
    refreshMainWindow(player)

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.destroyWindowMainInventory(player)
    local inventory = getMainInventory(player)
    local window    = getFirstWindow(inventory)

    assert(window, "Player does not have a main inventory window !")      -- [DEBUG-ONLY] . --

    inventory:removeWindow(window)
    refreshMainWindow(player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getWindowMainInventory(player)
    local window = getFirstWindow(getMainInventory(player))

    assert(window and window.valid and window.object_name == "InventoryWindow", "Player does not have a valid inventory window !")      -- [DEBUG-ONLY] . --

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return manager
