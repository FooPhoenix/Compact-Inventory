MOD_PREFIX = "FooPhoenix_CI_"

local ItemOrder                 = require("util.item_order")
local PresetManagerFactory      = require("util.preset_manager")
local InventoryViewFactory      = require("inventory.inventory_view")
local InventoryManagerFactory   = require("inventory.inventory_manager")
local WindowsManager            = require("gui.windows_manager")
local ItemGroupMenuFactory      = require("gui.item_group_menu")
local WindowPresetMenuFactory   = require("gui.window_preset_menu")
local WindowPresetFactory       = require("gui.window_preset")

local SortMode   = InventoryViewFactory.sort_modes
local FilterMode = InventoryViewFactory.filter_modes

local PRESET_CONTEXT_FILTER      = "Filter"
local PRESET_CONTEXT_CUSTOM_SORT = "Custom sort"

local INVENTORY_WINDOW_FRAME_PREFIX = MOD_PREFIX .. "IW_frame-"
local MENU_INVENTORY_ID_TAG_NAME    = MOD_PREFIX .. "MenuInventoryID"
local MENU_WINDOW_ID_TAG_NAME       = MOD_PREFIX .. "MenuWindowID"
local CREATION_SOURCE_GUI_NAMES     = {
    [MOD_PREFIX .. "MW_source-player"]            = true,
    [MOD_PREFIX .. "MW_source-player-vehicle"]    = true,
    [MOD_PREFIX .. "MW_source-selected-entities"] = true
}

local custom_sort_selections = { }
local preset_contexts        = { }
local filter_preset_manager
local custom_sort_preset_manager
local window_preset_manager

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

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

local function getInventoryWindow(player, inventory_id, window_id)
    local manager   = InventoryManagerFactory.get(player)
    local inventory = manager:getInventories()[inventory_id]
    local window    = inventory and inventory:getWindow(window_id) or nil

    return window and window.valid and window or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function resolveInventoryWindowFromElement(player, lua_element)
    local element = lua_element

    while element do
        local tags = element.tags
        local inventory_id = tags and tags[MENU_INVENTORY_ID_TAG_NAME]
        local window_id    = tags and tags[MENU_WINDOW_ID_TAG_NAME]

        if inventory_id and window_id then
            return getInventoryWindow(player, inventory_id, window_id)
        end

        local name = element.name

        if name then
            local parsed_inventory_id, parsed_window_id = name:match(
                "^" .. INVENTORY_WINDOW_FRAME_PREFIX .. "(%d+)%-(%d+)$"
            )

            if parsed_inventory_id and parsed_window_id then
                return getInventoryWindow(player, tonumber(parsed_inventory_id), tonumber(parsed_window_id))
            end
        end

        element = element.parent
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function tagItemGroupMenu(window)
    local menu_names = ItemGroupMenuFactory.exposed_gui_names
    local menu       = window:getPlayer().gui.screen[menu_names.menu]

    assert(menu, "ItemGroup menu must exist here !")      -- [DEBUG-ONLY] . --

    local tags = menu.tags
    tags[MENU_INVENTORY_ID_TAG_NAME] = window:getInventory():getID()
    tags[MENU_WINDOW_ID_TAG_NAME]     = window:getID()
    menu.tags = tags
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshMainWindow(player)
    if WindowsManager.hasMainWindow(player) then
        WindowsManager.getMainWindow(player):refresh()
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function initializePresetStorage()
    storage.presets = storage.presets or { }
    storage.presets.filters = storage.presets.filters or { }
    storage.presets.custom_sort = storage.presets.custom_sort or { }
    storage.presets.windows = storage.presets.windows or { }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getFilterPresetManager()
    if not filter_preset_manager then
        initializePresetStorage()
        filter_preset_manager = PresetManagerFactory.new(storage.presets.filters)
    end

    return filter_preset_manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getCustomSortPresetManager()
    if not custom_sort_preset_manager then
        initializePresetStorage()
        custom_sort_preset_manager = PresetManagerFactory.new(storage.presets.custom_sort)
    end

    return custom_sort_preset_manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getWindowPresetManager()
    if not window_preset_manager then
        initializePresetStorage()
        window_preset_manager = PresetManagerFactory.new(storage.presets.windows)
    end

    return window_preset_manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getFilterPresetData(item_group)
    return {
        mode    = item_group:getFilterMode(),
        filters = item_group:getFilters()
    }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function applyFilterPreset(item_group, data)
    assert(type(data) == "table", "Filter preset data must be a table !")      -- [DEBUG-ONLY] . --

    item_group:setFilterMode(data.mode)
    item_group:setFilters(data.filters)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getCustomSortPresetData(item_group)
    return {
        order = item_group:getCustomOrder()
    }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function applyCustomSortPreset(item_group, data)
    assert(type(data) == "table" and type(data.order) == "table", "Custom sort preset data must be valid !")      -- [DEBUG-ONLY] . --
    item_group:setCustomOrder(data.order)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function findGuiElement(parent, name)
    if parent.name == name then
        return parent
    end

    for _, child in ipairs(parent.children) do
        local found = findGuiElement(child, name)

        if found then
            return found
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function applyWindowPresetSourceToCreationUI(main_window, configuration)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --
    assert(type(configuration) == "table", "Window preset source configuration must be a table !")         -- [DEBUG-ONLY] . --

    local entities         = configuration.entities
    local entity_config    = type(entities) == "table" and entities[1] or nil
    local inventory_types  = entity_config and entity_config.inventory_types or nil
    local is_player_source = type(entities) == "table"
        and #entities == 1
        and entity_config.entity == main_window:getPlayer()
        and type(inventory_types) == "table"
        and #inventory_types == 1
        and inventory_types[1] == defines.inventory.character_main

    assert(is_player_source, "Window preset contains an unsupported source configuration !")      -- [DEBUG-ONLY] . --

    if not is_player_source then
        return false
    end

    local frame             = main_window:getFrame()
    local source_player     = findGuiElement(frame, MOD_PREFIX .. "MW_source-player")
    local source_vehicle    = findGuiElement(frame, MOD_PREFIX .. "MW_source-player-vehicle")
    local source_entities   = findGuiElement(frame, MOD_PREFIX .. "MW_source-selected-entities")

    assert(source_player and source_vehicle and source_entities, "Main window source controls must exist here !")      -- [DEBUG-ONLY] . --

    source_player.state   = true
    source_vehicle.state  = false
    source_entities.state = false

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshCustomSortEditor(window, item_group)
    local menu = window:getPlayer().gui.screen[ItemGroupMenuFactory.exposed_gui_names.menu]

    if not menu then
        return
    end

    local custom_sort_table = findGuiElement(menu, MOD_PREFIX .. "IG_options-custom-sort-table")
    local group_id          = item_group:getID()

    assert(custom_sort_table, "Custom sort table must exist here !")      -- [DEBUG-ONLY] . --

    custom_sort_table.clear()

    for _, item_id in ipairs(item_group:getCustomOrder()) do
        local item_name = ItemOrder.getName(item_id)

        custom_sort_table.add({
            type               = "sprite-button",
            sprite             = "item/" .. item_name,
            style              = "slot_button",
            elem_tooltip       = {
                type = "item",
                name = item_name
            },
            raise_hover_events = true,
            tags               = {
                [ItemGroupMenuFactory.exposed_gui_names.group_id_tag_name] = group_id
            }
        })
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function clearCurrentPreset(item_group, context)
    if context == PRESET_CONTEXT_FILTER then
        item_group:setFilterPresetName(nil)
    elseif context == PRESET_CONTEXT_CUSTOM_SORT then
        item_group:setCustomSortPresetName(nil)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getCurrentPreset(item_group, context)
    if context == PRESET_CONTEXT_FILTER then
        return item_group:getFilterPresetName()
    elseif context == PRESET_CONTEXT_CUSTOM_SORT then
        return item_group:getCustomSortPresetName()
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function setCurrentPreset(item_group, context, name)
    if context == PRESET_CONTEXT_FILTER then
        item_group:setFilterPresetName(name)
    elseif context == PRESET_CONTEXT_CUSTOM_SORT then
        item_group:setCustomSortPresetName(name)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getPresetManager(context)
    if context == PRESET_CONTEXT_FILTER then
        return getFilterPresetManager()
    elseif context == PRESET_CONTEXT_CUSTOM_SORT then
        return getCustomSortPresetManager()
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_init(function()
    ItemOrder.initialize()
    initializePresetStorage()
    InventoryManagerFactory.initialize()
    WindowsManager.initialize()
end)

script.on_configuration_changed(function()
    for _, lua_player in pairs(game.players) do
        local screen = lua_player.gui.screen
        for _, frame in pairs(screen.children) do
            frame.destroy()     -- Very dangerous, but it is only for testing purposes.
        end
    end

    ItemOrder.initialize()
    initializePresetStorage()
    InventoryManagerFactory.initialize()
    WindowsManager.initialize()
end)

script.on_event(defines.events.on_player_created, function(event)
    InventoryManagerFactory.initializePlayer(event.player_index)
    WindowsManager.initializePlayer(event.player_index)
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local _, lua_player = resolve_player(event.player_index)
    local lua_inventory = lua_player.get_main_inventory()

    if not lua_inventory then
        return
    end

    local manager = InventoryManagerFactory.get(lua_player)

    manager:updateInventory(lua_inventory)

    for _, inventory in pairs(manager:getInventories()) do
        if inventory:getSource():containsInventory(lua_inventory) then
            for _, window in pairs(inventory:getWindows()) do
                if window.valid and window:isVisible() then
                    window:refresh()
                end
            end
        end
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    local main_gui_names    = WindowsManager.exposed_gui_names.MainWindow
    local gui_names         = WindowsManager.exposed_gui_names.InventoryWindow
    local menu_names        = ItemGroupMenuFactory.exposed_gui_names
    local preset_menu_names = WindowPresetMenuFactory.exposed_gui_names
    local window            = resolveInventoryWindowFromElement(event.player_index, event.element)

    if event.element.name == main_gui_names.close_button then
        WindowsManager.getMainWindow(event.player_index):setVisible(false)

    elseif event.element.name == main_gui_names.add_button then
        WindowsManager.getMainWindow(event.player_index):showCreationPanel(getWindowPresetManager():list())

    elseif event.element.name == main_gui_names.tree_inventory_toggle then
        WindowsManager.getMainWindow(event.player_index):toggleInventoryExpanded(
            event.element.tags[main_gui_names.inventory_id_tag_name]
        )

    elseif event.element.name == main_gui_names.tree_window_toggle then
        WindowsManager.getMainWindow(event.player_index):toggleWindowExpanded(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name]
        )

    elseif event.element.name == main_gui_names.tree_label then
        local inventory_id = event.element.tags[main_gui_names.inventory_id_tag_name]
        local window_id    = event.element.tags[main_gui_names.window_id_tag_name]

        if window_id then
            WindowsManager.getMainWindow(event.player_index):toggleWindowExpanded(inventory_id, window_id)
        else
            WindowsManager.getMainWindow(event.player_index):toggleInventoryExpanded(inventory_id)
        end

    elseif event.element.name == main_gui_names.tree_edit_button then
        WindowsManager.getMainWindow(event.player_index):startRename(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name],
            event.element.tags[main_gui_names.group_id_tag_name]
        )

    elseif event.element.name == main_gui_names.tree_confirm_button then
        local name_field = event.element.parent[main_gui_names.tree_name_field]

        assert(name_field, "Main window rename field must exist here !")      -- [DEBUG-ONLY] . --

        WindowsManager.getMainWindow(event.player_index):confirmRename(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name],
            event.element.tags[main_gui_names.group_id_tag_name],
            name_field.text
        )

    elseif event.element.name == main_gui_names.tree_cancel_button then
        WindowsManager.getMainWindow(event.player_index):cancelRename()

    elseif event.element.name == main_gui_names.tree_visibility_button then
        WindowsManager.getMainWindow(event.player_index):toggleWindowVisibility(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name]
        )

    elseif event.element.name == main_gui_names.tree_lock_button then
        ItemGroupMenuFactory.close(event.player_index)
        WindowPresetMenuFactory.close(event.player_index)
        WindowsManager.getMainWindow(event.player_index):toggleWindowLocked(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name]
        )

    elseif event.element.name == main_gui_names.tree_delete_button then
        local inventory_id = event.element.tags[main_gui_names.inventory_id_tag_name]
        local window_id    = event.element.tags[main_gui_names.window_id_tag_name]
        local group_id     = event.element.tags[main_gui_names.group_id_tag_name]
        local main_window  = WindowsManager.getMainWindow(event.player_index)

        ItemGroupMenuFactory.close(event.player_index)
        WindowPresetMenuFactory.close(event.player_index)

        if group_id then
            main_window:deleteItemGroup(inventory_id, window_id, group_id)
        else
            main_window:deleteWindow(inventory_id, window_id)
        end

    elseif event.element.tags[main_gui_names.creation_preset_delete_tag_name] then
        local preset_name = event.element.tags[main_gui_names.creation_preset_delete_tag_name]
        local manager     = getWindowPresetManager()
        local main_window = WindowsManager.getMainWindow(event.player_index)

        if manager:delete(preset_name) then
            if main_window:getSelectedWindowPresetName() == preset_name then
                main_window:toggleCreationPresetSelection(preset_name)
            end

            main_window:refreshCreationPresetList(manager:list())
        end

    elseif event.element.tags[main_gui_names.creation_preset_name_tag_name] then
        local preset_name = event.element.tags[main_gui_names.creation_preset_name_tag_name]
        local main_window = WindowsManager.getMainWindow(event.player_index)

        main_window:toggleCreationPresetSelection(preset_name)

        if main_window:getSelectedWindowPresetName() == preset_name then
            local data = getWindowPresetManager():load(preset_name)

            assert(data, "Selected window preset must exist here !")      -- [DEBUG-ONLY] . --

            if data and data.source then
                applyWindowPresetSourceToCreationUI(main_window, data.source)
            end
        end

    elseif event.element.name == main_gui_names.creation_cancel_button then
        WindowsManager.getMainWindow(event.player_index):showWindowsList()

    elseif event.element.name == main_gui_names.creation_create_button then
        local main_window   = WindowsManager.getMainWindow(event.player_index)
        local preset_name   = main_window:getSelectedWindowPresetName()
        local preset_data   = preset_name and getWindowPresetManager():load(preset_name) or nil
        local configuration = main_window:getCreationConfiguration()
        local inventory     = InventoryManagerFactory.get(event.player_index):monitorConfiguration(configuration)

        assert(inventory, "Inventory creation configuration must resolve an Inventory !")      -- [DEBUG-ONLY] . --

        if inventory then
            local created_window = inventory:createWindow()

            if preset_data then
                WindowPresetFactory.apply(created_window, preset_data)
            end
        end

        main_window:showWindowsList()

    elseif event.element.name == gui_names.close_button and window then
        ItemGroupMenuFactory.close(event.player_index)
        WindowPresetMenuFactory.close(event.player_index)
        window:setVisible(false)
        refreshMainWindow(event.player_index)

    elseif event.element.name == gui_names.save_button and window then
        ItemGroupMenuFactory.close(event.player_index)
        WindowPresetMenuFactory.open(window, event.cursor_display_location)

    elseif event.element.name == gui_names.add_button and window then
        WindowPresetMenuFactory.close(event.player_index)
        window:createItemGroup()
        refreshMainWindow(event.player_index)

    elseif event.element.name == gui_names.lock_button and window then
        ItemGroupMenuFactory.close(event.player_index)
        WindowPresetMenuFactory.close(event.player_index)
        window:setLocked(true)
        refreshMainWindow(event.player_index)

    elseif event.element.name == gui_names.group_unlock_button and window then
        window:setLocked(false)
        refreshMainWindow(event.player_index)

    elseif event.element.name == gui_names.group_rename_button and window then
        window:startRename(event.element.tags[gui_names.group_id_tag_name])

    elseif event.element.name == gui_names.group_confirm_button and window then
        window:confirmRename(event.element.tags[gui_names.group_id_tag_name])
        refreshMainWindow(event.player_index)

    elseif event.element.name == gui_names.group_cancel_button and window then
        window:cancelRename(event.element.tags[gui_names.group_id_tag_name])

    elseif event.element.name == gui_names.group_menu_button and window then
        local group_id   = event.element.tags[gui_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        WindowPresetMenuFactory.close(event.player_index)
        ItemGroupMenuFactory.open(window, item_group, event.cursor_display_location)
        tagItemGroupMenu(window)

    elseif event.element.name == preset_menu_names.cancel_button then
        WindowPresetMenuFactory.close(event.player_index)

    elseif event.element.name == preset_menu_names.save_button and window then
        local name, include_source, selected_groups = WindowPresetMenuFactory.getSelection(window)

        if name ~= "" then
            local data = window:getPresetData(include_source, selected_groups)

            getWindowPresetManager():save(name, data)
            WindowPresetMenuFactory.close(event.player_index)
        end

    elseif (event.element.name == menu_names.move_up_button
        or event.element.name == menu_names.move_down_button) and window then

        local group_id   = event.element.tags[menu_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)
        local offset     = event.element.name == menu_names.move_up_button and -1 or 1

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        ItemGroupMenuFactory.moveItemGroup(window, item_group, offset)
        refreshMainWindow(event.player_index)

    elseif event.element.name == menu_names.sort_toggle_button then
        ItemGroupMenuFactory.toggleSortColumn(event.player_index)

    elseif event.element.name == menu_names.filter_toggle_button then
        ItemGroupMenuFactory.toggleFilterColumn(event.player_index)

    elseif event.element.name == menu_names.preset_toggle_button and window then
        local context    = event.element.tags[menu_names.preset_context_tag_name]
        local group_id   = event.element.tags[menu_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)
        local manager    = getPresetManager(context)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        assert(manager, "Preset context must be supported here !")      -- [DEBUG-ONLY] . --

        preset_contexts[event.player_index] = context
        ItemGroupMenuFactory.togglePresetColumn(event.player_index, context)
        ItemGroupMenuFactory.refreshPresetList(event.player_index, manager:list(), context, group_id)

        local current_name = getCurrentPreset(item_group, context)

        if current_name then
            ItemGroupMenuFactory.selectPreset(event.player_index, current_name)
        end

    elseif event.element.name == menu_names.preset_save_button and window then
        local context = preset_contexts[event.player_index]
        local name    = ItemGroupMenuFactory.getPresetName(event.player_index)
        local manager = getPresetManager(context)

        if manager and name and name ~= "" then
            local group_id   = event.element.tags[menu_names.group_id_tag_name]
            local item_group = window:getItemGroupByID(group_id)
            local data       = context == PRESET_CONTEXT_FILTER
                and getFilterPresetData(item_group)
                or getCustomSortPresetData(item_group)

            assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

            local saved_name = manager:save(name, data)
            setCurrentPreset(item_group, context, saved_name)

            ItemGroupMenuFactory.refreshPresetList(event.player_index, manager:list(), context, group_id)
            ItemGroupMenuFactory.selectPreset(event.player_index, saved_name)
        end

    elseif event.element.tags[menu_names.preset_delete_tag_name] and window then
        local context     = event.element.tags[menu_names.preset_context_tag_name]
        local group_id    = event.element.tags[menu_names.group_id_tag_name]
        local preset_name = event.element.tags[menu_names.preset_delete_tag_name]
        local item_group  = window:getItemGroupByID(group_id)
        local manager     = getPresetManager(context)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        assert(manager, "Preset context must be supported here !")      -- [DEBUG-ONLY] . --

        if manager:delete(preset_name) then
            if getCurrentPreset(item_group, context) == preset_name then
                clearCurrentPreset(item_group, context)
            end

            ItemGroupMenuFactory.refreshPresetList(event.player_index, manager:list(), context, group_id)
        end

    elseif event.element.tags[menu_names.preset_name_tag_name] and window then
        local context     = event.element.tags[menu_names.preset_context_tag_name]
        local group_id    = event.element.tags[menu_names.group_id_tag_name]
        local item_group  = window:getItemGroupByID(group_id)
        local manager     = getPresetManager(context)
        local preset_name = ItemGroupMenuFactory.togglePresetSelection(event.player_index, event.element)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        assert(manager, "Preset context must be supported here !")      -- [DEBUG-ONLY] . --

        if not preset_name then
            clearCurrentPreset(item_group, context)
        else
            local data = manager:load(preset_name)

            assert(data, "Preset must exist here !")      -- [DEBUG-ONLY] . --

            if context == PRESET_CONTEXT_FILTER then
                applyFilterPreset(item_group, data)
                ItemGroupMenuFactory.refreshFilterEditor(window, item_group)
            else
                applyCustomSortPreset(item_group, data)
                custom_sort_selections[event.player_index] = nil
                refreshCustomSortEditor(window, item_group)
            end

            setCurrentPreset(item_group, context, preset_name)
            window:refreshGroup(item_group)
        end

    elseif window
        and event.button == defines.mouse_button_type.left
        and event.element.parent
        and event.element.parent.name == MOD_PREFIX .. "IG_options-custom-sort-table" then

        local custom_sort_table = event.element.parent
        local selected_button   = custom_sort_selections[event.player_index]

        if selected_button and not selected_button.valid then
            selected_button = nil
            custom_sort_selections[event.player_index] = nil
        end

        if not selected_button then
            event.element.toggled = true
            custom_sort_selections[event.player_index] = event.element

        elseif selected_button == event.element then
            event.element.toggled = false
            custom_sort_selections[event.player_index] = nil

        else
            local source_index = selected_button.get_index_in_parent()
            local target_index = event.element.get_index_in_parent()
            local group_id     = event.element.tags[menu_names.group_id_tag_name]
            local item_group   = window:getItemGroupByID(group_id)
            local insert_index = target_index

            assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

            if source_index < target_index then
                insert_index = target_index - 1
            end

            item_group:moveCustomItem(source_index, target_index)

            if source_index < insert_index then
                for index = source_index, insert_index - 1 do
                    custom_sort_table.swap_children(index, index + 1)
                end
            elseif source_index > insert_index then
                for index = source_index, insert_index + 1, -1 do
                    custom_sort_table.swap_children(index, index - 1)
                end
            end

            selected_button.toggled = false
            custom_sort_selections[event.player_index] = nil
            item_group:setCustomSortPresetName(nil)
            window:refreshGroup(item_group)
            ItemGroupMenuFactory.clearPresetSelection(event.player_index)
        end

    elseif event.element.tags[menu_names.filter_slot_tag_name]
        and event.button == defines.mouse_button_type.left then

        ItemGroupMenuFactory.suspendHoverUntilReenter(event.player_index)

    elseif event.element.tags[menu_names.filter_slot_tag_name]
        and event.button == defines.mouse_button_type.right
        and window then

        local slot_index = event.element.tags[menu_names.filter_slot_tag_name]
        local group_id   = event.element.tags[menu_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

        event.element.elem_value = nil
        item_group:setFilter(slot_index, nil)
        item_group:setFilterPresetName(nil)
        window:refreshGroup(item_group)
        ItemGroupMenuFactory.refreshFilterTable(window, item_group)
        ItemGroupMenuFactory.clearPresetSelection(event.player_index)

    elseif event.element.name == menu_names.delete_group_button and window then
        local group_id = event.element.tags[menu_names.group_id_tag_name]

        ItemGroupMenuFactory.close(event.player_index)
        WindowsManager.getMainWindow(event.player_index):deleteItemGroup(
            window:getInventory():getID(),
            window:getID(),
            group_id
        )

    elseif event.element.tags[menu_names.sort_tag_name] and window then
        local sort_mode = event.element.tags[menu_names.sort_tag_name]
        local group_id  = event.element.tags[menu_names.group_id_tag_name]

        window:setSortMode(group_id, sort_mode)

        if sort_mode == SortMode.custom then
            ItemGroupMenuFactory.toggleCustomSortColumn(event.player_index)
        else
            ItemGroupMenuFactory.close(event.player_index)
        end
    end
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    local menu_names = ItemGroupMenuFactory.exposed_gui_names
    local slot_index = event.element.tags[menu_names.filter_slot_tag_name]

    if not slot_index then
        return
    end

    local window     = resolveInventoryWindowFromElement(event.player_index, event.element)
    local group_id   = event.element.tags[menu_names.group_id_tag_name]
    local item_group = window and window:getItemGroupByID(group_id) or nil

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    item_group:setFilter(slot_index, event.element.elem_value)
    item_group:setFilterPresetName(nil)
    window:refreshGroup(item_group)
    ItemGroupMenuFactory.refreshFilterTable(window, item_group)
    ItemGroupMenuFactory.clearPresetSelection(event.player_index)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    if not CREATION_SOURCE_GUI_NAMES[event.element.name] or not event.element.state then
        return
    end

    local main_window = WindowsManager.getMainWindow(event.player_index)
    local preset_name = main_window:getSelectedWindowPresetName()

    if not preset_name then
        return
    end

    local data = getWindowPresetManager():load(preset_name)

    if data and data.source then
        main_window:toggleCreationPresetSelection(preset_name)
    end
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local main_gui_names = WindowsManager.exposed_gui_names.MainWindow

    if event.element.name == main_gui_names.visibility_switch then
        local main_window = WindowsManager.getMainWindow(event.player_index)

        if event.element.switch_state == "left" then
            main_window:setAllWindowsVisible(true)
        elseif event.element.switch_state == "right" then
            main_window:setAllWindowsVisible(false)
        else
            main_window:refreshVisibilitySwitch()
        end

        return
    end

    local menu_names = ItemGroupMenuFactory.exposed_gui_names

    if event.element.name ~= menu_names.filter_switch then
        return
    end

    local window     = resolveInventoryWindowFromElement(event.player_index, event.element)
    local group_id   = event.element.tags[menu_names.group_id_tag_name]
    local item_group = window and window:getItemGroupByID(group_id) or nil

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    item_group:setFilterMode(
        event.element.switch_state == "left" and FilterMode.blacklist or FilterMode.whitelist
    )

    item_group:setFilterPresetName(nil)
    window:refreshGroup(item_group)
    ItemGroupMenuFactory.clearPresetSelection(event.player_index)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    local menu_names = ItemGroupMenuFactory.exposed_gui_names

    if event.element.name ~= menu_names.preset_name_field then
        return
    end

    ItemGroupMenuFactory.clearPresetSelection(event.player_index)

    local context = preset_contexts[event.player_index]
    local window  = resolveInventoryWindowFromElement(event.player_index, event.element)

    if window and context then
        local menu     = event.element
        local group_id = nil

        while menu do
            if menu.name == menu_names.menu then
                group_id = menu.tags[menu_names.group_id_tag_name]
                break
            end
            menu = menu.parent
        end

        local item_group = group_id and window:getItemGroupByID(group_id) or nil

        if item_group then
            clearCurrentPreset(item_group, context)
        end
    end
end)

script.on_event(defines.events.on_gui_confirmed, function(event)
    local main_gui_names = WindowsManager.exposed_gui_names.MainWindow
    local gui_names      = WindowsManager.exposed_gui_names.InventoryWindow

    if event.element.name == main_gui_names.tree_name_field then
        WindowsManager.getMainWindow(event.player_index):confirmRename(
            event.element.tags[main_gui_names.inventory_id_tag_name],
            event.element.tags[main_gui_names.window_id_tag_name],
            event.element.tags[main_gui_names.group_id_tag_name],
            event.element.text
        )

    elseif event.element.name == gui_names.group_name_field then
        local window = resolveInventoryWindowFromElement(event.player_index, event.element)

        assert(window, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --

        window:confirmRename(event.element.tags[gui_names.group_id_tag_name])
        refreshMainWindow(event.player_index)
    end
end)

script.on_event(defines.events.on_gui_hover, function(event)
    ItemGroupMenuFactory.onHover(event)
    WindowPresetMenuFactory.onHover(event)
end)

script.on_event(defines.events.on_gui_leave, function(event)
    ItemGroupMenuFactory.onLeave(event)
    WindowPresetMenuFactory.onLeave(event)
end)

script.on_event(defines.events.on_tick, function(event)
    ItemGroupMenuFactory.onTick(event)
    WindowPresetMenuFactory.onTick(event)
end)

local function updateWindowMaxHeight(player_index)
    local manager = InventoryManagerFactory.get(player_index)

    for _, inventory in pairs(manager:getInventories()) do
        for _, window in pairs(inventory:getWindows()) do
            if window.valid then
                window:updateMaxHeight()
            end
        end
    end
end

script.on_event(defines.events.on_player_display_resolution_changed, function(event)
    updateWindowMaxHeight(event.player_index)
end)

script.on_event(defines.events.on_player_display_scale_changed, function(event)
    updateWindowMaxHeight(event.player_index)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == WindowsManager.exposed_gui_names.MainWindow.shortcut_button then
        WindowsManager.getMainWindow(event.player_index):toggleVisibility()
    end
end)
