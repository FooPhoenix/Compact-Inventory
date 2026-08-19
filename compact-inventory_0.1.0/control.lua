
MOD_PREFIX = "FooPhoenix_CI_"

local ItemOrder                       = require("util.item_order")
local InventoryManagerFactory         = require("inventory.inventory_manager")
local WindowsManager                  = require("gui.windows_manager")
local SortMenuPrototypeFactory        = require("gui.sort_menu_prototype")
local ItemGroupLayoutPrototypeFactory = require("gui.item_group_layout_prototype")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### This function receive a player index or a LuaPlayer and will return both.
--
---@param player integer|LuaPlayer      The player to resolve.
--
---@return integer                      @ The player index.
---@return LuaPlayer                    @ The player.
--
function resolve_player(player)

    local player_index

    assert(player ~= nil)                                                                                                   -- [DEBUG-ONLY] . --
    assert(type(player) == "number" or type(player) == "table" or type(player) == "userdata", "You need to provide a index or a LuaObject ! " .. type(player) )            -- [DEBUG-ONLY] . --

    if type(player) == "number" then
        assert(player > 0, "Index must be > 0 !")                                                                           -- [DEBUG-ONLY] Paranoiac mode. --
        player_index = player
        player = game.get_player(player_index) --[[@as LuaPlayer]]
        assert(player ~= nil, "Player with index " .. player_index .. " does not exist !" )                                 -- [DEBUG-ONLY] . --
    else
        assert(player and player.valid, "You need to provide a valid LuaPlayer !" )                                         -- [DEBUG-ONLY] . --
        assert(player.object_name == "LuaPlayer", "You do not provided a LuaPlayer !" )                                     -- [DEBUG-ONLY] . --
        player_index = player.index
    end

    return player_index, player
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function attachPrototypesToWindow(window)
    ItemGroupLayoutPrototypeFactory.attach(window)
    SortMenuPrototypeFactory.attach(window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function attachPrototypes()
    for _, lua_player in pairs(game.players) do
        attachPrototypesToWindow(WindowsManager.getWindowMainInventory(lua_player))
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_init(function()
    ItemOrder.initialize()
    InventoryManagerFactory.initialize()
    WindowsManager.initialize()
    attachPrototypes()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_configuration_changed(function()

    -- [DEBUG-ONLY] Used only to reinit the mod for the moment. --

    for _, lua_player in pairs(game.players) do
        local screen = lua_player.gui.screen
        for _, frame in pairs(screen.children) do
            frame.destroy()     -- Very dangerous, but it is only for testing purposes.
        end
    end

    ItemOrder.initialize()
    InventoryManagerFactory.initialize()
    WindowsManager.initialize()
    attachPrototypes()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_player_created, function(event)
    InventoryManagerFactory.initializePlayer(event.player_index)
    WindowsManager.initializePlayer(event.player_index)

    attachPrototypesToWindow(WindowsManager.getWindowMainInventory(event.player_index))
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local _, lua_player = resolve_player(event.player_index)
    local lua_inventory = lua_player.get_main_inventory()

    if lua_inventory then
        InventoryManagerFactory.get(lua_player):updateInventory(lua_inventory)
    end

    if WindowsManager.hasWindowMainInventory(lua_player) then
        local window = WindowsManager.getWindowMainInventory(lua_player)

        if window:isVisible() then
            window:refresh()
        end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_gui_click, function(event)

    local gui_names       = WindowsManager.exposed_gui_names.InventoryWindow
    local layout_names    = ItemGroupLayoutPrototypeFactory.exposed_gui_names
    local menu_names      = SortMenuPrototypeFactory.exposed_gui_names

    if event.element.name == gui_names.close_button then
        SortMenuPrototypeFactory.close(event.player_index)
        WindowsManager.getWindowMainInventory(event.player_index):setVisible(false)

    elseif event.element.name == layout_names.group_menu_button then
        SortMenuPrototypeFactory.open(
            WindowsManager.getWindowMainInventory(event.player_index),
            event.cursor_display_location
        )

    elseif event.element.name == menu_names.sort_toggle_button then
        SortMenuPrototypeFactory.toggleSortColumn(event.player_index)

    elseif event.element.name == menu_names.delete_group_button then
        SortMenuPrototypeFactory.close(event.player_index)
        WindowsManager.destroyWindowMainInventory(event.player_index)

    elseif event.element.tags[gui_names.sort_tag_name] then
        local window = WindowsManager.getWindowMainInventory(event.player_index)

        window:setSortMode(event.element.tags[gui_names.sort_tag_name])
        ItemGroupLayoutPrototypeFactory.refreshSortButton(window)
        SortMenuPrototypeFactory.close(event.player_index)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_gui_hover, function(event)
    SortMenuPrototypeFactory.onHover(event)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_gui_leave, function(event)
    SortMenuPrototypeFactory.onLeave(event)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_tick, function(event)
    SortMenuPrototypeFactory.onTick(event)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == WindowsManager.exposed_gui_names.InventoryWindow.shortcut_button then
        SortMenuPrototypeFactory.close(event.player_index)

        if WindowsManager.hasWindowMainInventory(event.player_index) then
            WindowsManager.getWindowMainInventory(event.player_index):toggleVisibility()
        else
            local window = WindowsManager.createWindowMainInventory(event.player_index)
            attachPrototypesToWindow(window)
        end
    end
end)
