MOD_PREFIX = "FooPhoenix_CI_"

local ItemOrder                 = require("util.item_order")
local PresetManagerFactory      = require("util.preset_manager")
local InventoryViewFactory      = require("inventory.inventory_view")
local InventoryManagerFactory   = require("inventory.inventory_manager")
local WindowsManager            = require("gui.windows_manager")
local ItemGroupMenuFactory      = require("gui.item_group_menu")

local SortMode   = InventoryViewFactory.sort_modes
local FilterMode = InventoryViewFactory.filter_modes

local PRESET_CONTEXT_FILTER      = "Filter"
local PRESET_CONTEXT_CUSTOM_SORT = "Custom sort"

local custom_sort_selections = { }
local preset_contexts        = { }
local filter_preset_manager
local custom_sort_preset_manager

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

local function initializePresetStorage()
    storage.presets = storage.presets or { }
    storage.presets.filters = storage.presets.filters or { }
    storage.presets.custom_sort = storage.presets.custom_sort or { }
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

script.on_event(defines.events.on_gui_click, function(event)
    local main_gui_names = WindowsManager.exposed_gui_names.MainWindow
    local gui_names      = WindowsManager.exposed_gui_names.InventoryWindow
    local menu_names     = ItemGroupMenuFactory.exposed_gui_names
    local window         = WindowsManager.hasWindowMainInventory(event.player_index)
        and WindowsManager.getWindowMainInventory(event.player_index)
        or nil

    if event.element.name == main_gui_names.close_button then
        WindowsManager.getMainWindow(event.player_index):setVisible(false)

    elseif event.element.name == gui_names.close_button then
        ItemGroupMenuFactory.close(event.player_index)
        window:setVisible(false)

    elseif event.element.name == gui_names.add_button then
        window:createItemGroup()

    elseif event.element.name == gui_names.lock_button then
        ItemGroupMenuFactory.close(event.player_index)
        window:setLocked(true)

    elseif event.element.name == gui_names.group_unlock_button then
        window:setLocked(false)

    elseif event.element.name == gui_names.group_rename_button then
        window:startRename(event.element.tags[gui_names.group_id_tag_name])

    elseif event.element.name == gui_names.group_confirm_button then
        window:confirmRename(event.element.tags[gui_names.group_id_tag_name])

    elseif event.element.name == gui_names.group_cancel_button then
        window:cancelRename(event.element.tags[gui_names.group_id_tag_name])

    elseif event.element.name == gui_names.group_menu_button then
        local group_id   = event.element.tags[gui_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        ItemGroupMenuFactory.open(window, item_group, event.cursor_display_location)

    elseif event.element.name == menu_names.move_up_button
        or event.element.name == menu_names.move_down_button then

        local group_id   = event.element.tags[menu_names.group_id_tag_name]
        local item_group = window:getItemGroupByID(group_id)
        local offset     = event.element.name == menu_names.move_up_button and -1 or 1

        assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --
        ItemGroupMenuFactory.moveItemGroup(window, item_group, offset)

    elseif event.element.name == menu_names.sort_toggle_button then
        ItemGroupMenuFactory.toggleSortColumn(event.player_index)

    elseif event.element.name == menu_names.filter_toggle_button then
        ItemGroupMenuFactory.toggleFilterColumn(event.player_index)

    elseif event.element.name == menu_names.preset_toggle_button then
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

    elseif event.element.name == menu_names.preset_save_button then
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

    elseif event.element.tags[menu_names.preset_delete_tag_name] then
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

    elseif event.element.tags[menu_names.preset_name_tag_name] then
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

    elseif event.button == defines.mouse_button_type.left
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
        and event.button == defines.mouse_button_type.right then

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

    elseif event.element.name == menu_names.delete_group_button then
        local group_id = event.element.tags[menu_names.group_id_tag_name]

        ItemGroupMenuFactory.close(event.player_index)

        if #window:getItemGroups() == 1 then
            WindowsManager.destroyWindowMainInventory(event.player_index)
        else
            window:removeItemGroup(group_id)
        end

    elseif event.element.tags[menu_names.sort_tag_name] then
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

    local window     = WindowsManager.getWindowMainInventory(event.player_index)
    local group_id   = event.element.tags[menu_names.group_id_tag_name]
    local item_group = window:getItemGroupByID(group_id)

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    item_group:setFilter(slot_index, event.element.elem_value)
    item_group:setFilterPresetName(nil)
    window:refreshGroup(item_group)
    ItemGroupMenuFactory.refreshFilterTable(window, item_group)
    ItemGroupMenuFactory.clearPresetSelection(event.player_index)
end)

script.on_event(defines.events.on_gui_switch_state_changed, function(event)
    local menu_names = ItemGroupMenuFactory.exposed_gui_names

    if event.element.name ~= menu_names.filter_switch then
        return
    end

    local window     = WindowsManager.getWindowMainInventory(event.player_index)
    local group_id   = event.element.tags[menu_names.group_id_tag_name]
    local item_group = window:getItemGroupByID(group_id)

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
    local window  = WindowsManager.hasWindowMainInventory(event.player_index)
        and WindowsManager.getWindowMainInventory(event.player_index)
        or nil

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
    local gui_names = WindowsManager.exposed_gui_names.InventoryWindow

    if event.element.name == gui_names.group_name_field then
        WindowsManager.getWindowMainInventory(event.player_index):confirmRename(
            event.element.tags[gui_names.group_id_tag_name]
        )
    end
end)

script.on_event(defines.events.on_gui_hover, function(event)
    ItemGroupMenuFactory.onHover(event)
end)

script.on_event(defines.events.on_gui_leave, function(event)
    ItemGroupMenuFactory.onLeave(event)
end)

script.on_event(defines.events.on_tick, function(event)
    ItemGroupMenuFactory.onTick(event)
end)

local function updateWindowMaxHeight(player_index)
    if WindowsManager.hasWindowMainInventory(player_index) then
        WindowsManager.getWindowMainInventory(player_index):updateMaxHeight()
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
