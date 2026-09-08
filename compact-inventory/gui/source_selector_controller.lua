local SourceType             = require("inventory.source_type")
local SourceEditorController = require("gui.source_editor_controller")
local EntityPreviewWindow    = require("gui.entity_preview_window")
local WindowsManager         = require("gui.windows_manager")

local SourceSelectorController = { }

local GUI_NAME = {
    source_selector_column          = MOD_PREFIX .. "MW_source-selector-column",
    source_selector_type            = MOD_PREFIX .. "MW_source-selector-type",
    source_selector_tabs            = MOD_PREFIX .. "MW_source-selector-tabs",       -- Legacy transient GUI, removed on first use.
    source_selector_panels          = MOD_PREFIX .. "MW_source-selector-panels",
    source_selector_player_content  = MOD_PREFIX .. "MW_source-selector-player-content",
    source_selector_vehicle_content = MOD_PREFIX .. "MW_source-selector-vehicle-content",
    source_selector_list            = MOD_PREFIX .. "MW_source-selector-list",
    source_selector_player_checkbox = MOD_PREFIX .. "MW_source-selector-player-checkbox",
    source_selector_actions         = MOD_PREFIX .. "MW_source-selector-actions",
    source_selector_add_button      = MOD_PREFIX .. "MW_source-selector-add",
    vehicle_scroll                  = MOD_PREFIX .. "MW_source-selector-vehicle-scroll",
    vehicle_table                   = MOD_PREFIX .. "MW_source-selector-vehicle-table",
    vehicle_slot_button             = MOD_PREFIX .. "MW_source-selector-vehicle-slot"
}

local VEHICLE_INDEX_TAG      = MOD_PREFIX .. "MW_SourceSelectorVehicleIndex"
local VEHICLE_SELECTION_TOOL = MOD_PREFIX .. "vehicle-selection-tool"
local MAIN_WINDOW_SHORTCUT   = MOD_PREFIX .. "main-window-toggle"
local VEHICLE_SLOT_COLUMNS   = 10
local VEHICLE_VISIBLE_ROWS   = 10
local VEHICLE_SLOT_SIZE      = 40
local PREVIEW_SIZE           = VEHICLE_VISIBLE_ROWS * VEHICLE_SLOT_SIZE

local SOURCE_TYPES = {
    SourceType.player,
    SourceType.vehicle
}

local shortcut_handler
local preview_hover_handler
local preview_leave_handler

SourceSelectorController.exposed_gui_names = {
    source_type_dropdown   = GUI_NAME.source_selector_type,
    vehicle_slot_button    = GUI_NAME.vehicle_slot_button,
    vehicle_index_tag_name = VEHICLE_INDEX_TAG
}

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

local function copyArray(values)
    local result = { }

    for index, value in ipairs(values or { }) do
        result[index] = value
    end

    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getSelectionSessions()
    storage.source_selection_sessions = storage.source_selection_sessions or { }
    return storage.source_selection_sessions
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getSourceTypeIndex(source_type)
    for index, candidate in ipairs(SOURCE_TYPES) do
        if candidate == source_type then
            return index
        end
    end

    return 1
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getSelectorColumn(main_window)
    local selector_column = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_column)

    assert(selector_column, "Source selector column must exist here !")      -- [DEBUG-ONLY] . --
    return selector_column
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getSelectorActions(main_window)
    local selector_column = getSelectorColumn(main_window)
    local actions         = selector_column[GUI_NAME.source_selector_actions]
    local add_button      = actions and actions[GUI_NAME.source_selector_add_button]

    assert(add_button, "Source selector Add button must exist here !")      -- [DEBUG-ONLY] . --
    return add_button
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function ensureSelectorPanels(main_window)
    local selector_column = getSelectorColumn(main_window)
    local dropdown        = selector_column[GUI_NAME.source_selector_type]
    local panels          = selector_column[GUI_NAME.source_selector_panels]

    assert(dropdown, "Source type dropdown must exist here !")      -- [DEBUG-ONLY] . --

    dropdown.items = { "Player", "Vehicle" }

    if panels then
        return dropdown, panels
    end

    local legacy_tabs = selector_column[GUI_NAME.source_selector_tabs]

    if legacy_tabs then
        legacy_tabs.destroy()
    else
        local old_selector_list = findGuiElement(selector_column, GUI_NAME.source_selector_list)

        if old_selector_list then
            local old_panel = old_selector_list.parent
            assert(old_panel, "Legacy source selector panel must exist here !")      -- [DEBUG-ONLY] . --
            old_panel.destroy()
        end
    end

    panels = selector_column.add({
        type      = "flow",
        name      = GUI_NAME.source_selector_panels,
        direction = "vertical",
        index     = dropdown.get_index_in_parent() + 1
    })

    panels.style.horizontally_stretchable = true

    local player_content = panels.add({
        type      = "frame",
        name      = GUI_NAME.source_selector_player_content,
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    player_content.style.padding = 4

    player_content.add({
        type    = "label",
        caption = "Players",
        style   = "heading_2_label"
    })

    local player_list = player_content.add({
        type      = "flow",
        name      = GUI_NAME.source_selector_list,
        direction = "vertical"
    })

    player_list.add({
        type    = "checkbox",
        name    = GUI_NAME.source_selector_player_checkbox,
        caption = main_window:getPlayer().name,
        state   = true
    })

    local vehicle_content = panels.add({
        type      = "frame",
        name      = GUI_NAME.source_selector_vehicle_content,
        direction = "vertical",
        style     = "inside_shallow_frame",
        visible   = false
    })

    vehicle_content.style.padding = 4

    vehicle_content.add({
        type    = "label",
        caption = "Vehicles",
        style   = "heading_2_label"
    })

    local vehicle_scroll = vehicle_content.add({
        type                     = "scroll-pane",
        name                     = GUI_NAME.vehicle_scroll,
        direction                = "vertical",
        vertical_scroll_policy   = "auto",
        horizontal_scroll_policy = "never"
    })

    vehicle_scroll.style.padding                  = 0
    vehicle_scroll.style.maximal_height           = VEHICLE_VISIBLE_ROWS * VEHICLE_SLOT_SIZE
    vehicle_scroll.style.horizontally_stretchable = true

    local vehicle_table = vehicle_scroll.add({
        type         = "table",
        name         = GUI_NAME.vehicle_table,
        column_count = VEHICLE_SLOT_COLUMNS
    })

    vehicle_table.style.horizontal_spacing = 0
    vehicle_table.style.vertical_spacing   = 0

    return dropdown, panels
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function setSelectedPanel(main_window, source_type)
    local _, panels       = ensureSelectorPanels(main_window)
    local player_content  = panels[GUI_NAME.source_selector_player_content]
    local vehicle_content = panels[GUI_NAME.source_selector_vehicle_content]

    assert(player_content and vehicle_content, "Source selector panels must exist here !")      -- [DEBUG-ONLY] . --

    player_content.visible  = source_type == SourceType.player
    vehicle_content.visible = source_type == SourceType.vehicle
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addVehicleSlot(parent, lua_vehicle, vehicle_index)
    local wrapper = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    local definition = {
        type               = "sprite-button",
        name               = GUI_NAME.vehicle_slot_button,
        style              = "slot_button",
        tooltip            = lua_vehicle and lua_vehicle.name or "Add vehicle",
        tags               = { },
        raise_hover_events = lua_vehicle ~= nil
    }

    if lua_vehicle then
        definition.sprite = "entity/" .. lua_vehicle.name
        definition.tags[VEHICLE_INDEX_TAG] = vehicle_index
    end

    return wrapper.add(definition)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function renderVehicleDraft(main_window)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state
    local drafts         = selector_state and selector_state.drafts
    local vehicle_draft  = drafts and drafts[SourceType.vehicle]
    local vehicle_table  = findGuiElement(getSelectorColumn(main_window), GUI_NAME.vehicle_table)

    assert(vehicle_draft and vehicle_table, "Vehicle source selector draft and table must exist here !")      -- [DEBUG-ONLY] . --

    vehicle_table.clear()

    for vehicle_index, lua_vehicle in ipairs(vehicle_draft.vehicles) do
        if lua_vehicle and lua_vehicle.valid and lua_vehicle.object_name == "LuaEntity" then
            addVehicleSlot(vehicle_table, lua_vehicle, vehicle_index)
        end
    end

    addVehicleSlot(vehicle_table)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function containsVehicle(vehicles, lua_vehicle)
    for _, selected_vehicle in ipairs(vehicles) do
        if selected_vehicle == lua_vehicle then
            return true
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function findPlayerInConfiguration(configuration, lua_player, ignored_source_index, ignored_target_index)
    for source_index, source in ipairs(configuration.sources or { }) do
        if source.type == SourceType.player then
            for target_index, selected_player in ipairs(source.players or { }) do
                local ignored = source_index == ignored_source_index and target_index == ignored_target_index

                if not ignored and selected_player == lua_player then
                    return true
                end
            end
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshConfirm(main_window)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state

    if not selector_state then
        return
    end

    local add_button = getSelectorActions(main_window)

    if selector_state.selected_type == SourceType.player then
        local checkbox = findGuiElement(getSelectorColumn(main_window), GUI_NAME.source_selector_player_checkbox)
        local source   = selector_state.source_index
            and main_window.editor_state.configuration.sources[selector_state.source_index]
            or nil

        add_button.enabled = checkbox ~= nil
            and checkbox.state
            and (source == nil or source.type == SourceType.player)
        return
    end

    -- Vehicle sources remain draft-only until their runtime configuration path is implemented.
    add_button.enabled = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function finishVehicleSelection(player_index, clear_cursor)
    local sessions = getSelectionSessions()
    local session  = sessions[player_index]

    if not session then
        return false
    end

    sessions[player_index] = nil

    local lua_player = game.get_player(player_index)

    if lua_player and lua_player.valid and clear_cursor then
        local cursor_stack = lua_player.cursor_stack

        if cursor_stack and cursor_stack.valid_for_read and cursor_stack.name == VEHICLE_SELECTION_TOOL then
            lua_player.clear_cursor()
        end
    end

    if WindowsManager.hasMainWindow(player_index) then
        WindowsManager.getMainWindow(player_index):setVisible(true)
    end

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function installShortcutHandler()
    local current_handler = script.get_event_handler(defines.events.on_lua_shortcut)

    if current_handler == shortcut_handler then
        return
    end

    local previous_handler = current_handler

    shortcut_handler = function(event)
        if event.prototype_name == MAIN_WINDOW_SHORTCUT
            and getSelectionSessions()[event.player_index] then

            finishVehicleSelection(event.player_index, true)
            return
        end

        if previous_handler then
            previous_handler(event)
        end
    end

    script.on_event(defines.events.on_lua_shortcut, shortcut_handler)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function beginVehicleSelection(main_window)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state

    assert(selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --
    assert(selector_state.selected_type == SourceType.vehicle, "Vehicle selection requires the Vehicle source type !")      -- [DEBUG-ONLY] . --

    local lua_player = main_window:getPlayer()

    if not lua_player.clear_cursor() then
        return false
    end

    installShortcutHandler()

    local sessions = getSelectionSessions()
    sessions[lua_player.index] = {
        source_type    = SourceType.vehicle,
        selector_state = selector_state,
        tool            = VEHICLE_SELECTION_TOOL
    }

    lua_player.cursor_stack.set_stack({
        name  = VEHICLE_SELECTION_TOOL,
        count = 1
    })

    main_window:setVisible(false)
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function onVehicleSelection(event)
    local sessions = getSelectionSessions()
    local session  = sessions[event.player_index]

    if not session or event.item ~= VEHICLE_SELECTION_TOOL then
        return
    end

    local main_window = WindowsManager.hasMainWindow(event.player_index)
        and WindowsManager.getMainWindow(event.player_index)
        or nil

    local selector_state = main_window
        and main_window.editor_state
        and main_window.editor_state.selector_state
        or nil

    if selector_state ~= session.selector_state
        or selector_state.selected_type ~= SourceType.vehicle then

        finishVehicleSelection(event.player_index, true)
        return
    end

    local vehicles = selector_state.drafts[SourceType.vehicle].vehicles

    for _, lua_entity in ipairs(event.entities or { }) do
        if lua_entity.valid
            and lua_entity.object_name == "LuaEntity"
            and (lua_entity.type == "car" or lua_entity.type == "spider-vehicle")
            and not containsVehicle(vehicles, lua_entity) then

            vehicles[#vehicles + 1] = lua_entity
        end
    end

    finishVehicleSelection(event.player_index, true)
    renderVehicleDraft(main_window)
    refreshConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function onCursorStackChanged(event)
    local session = getSelectionSessions()[event.player_index]

    if not session then
        return
    end

    local lua_player   = game.get_player(event.player_index)
    local cursor_stack = lua_player and lua_player.cursor_stack or nil

    if cursor_stack
        and cursor_stack.valid_for_read
        and cursor_stack.name == session.tool then

        return
    end

    finishVehicleSelection(event.player_index, false)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function showVehiclePreview(event)
    if event.element.name ~= GUI_NAME.vehicle_slot_button then
        return false
    end

    local vehicle_index = event.element.tags[VEHICLE_INDEX_TAG]

    if not vehicle_index or not WindowsManager.hasMainWindow(event.player_index) then
        return false
    end

    local main_window    = WindowsManager.getMainWindow(event.player_index)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state
    local vehicle_draft  = selector_state and selector_state.drafts and selector_state.drafts[SourceType.vehicle]
    local lua_vehicle    = vehicle_draft and vehicle_draft.vehicles[vehicle_index] or nil

    if not lua_vehicle or not lua_vehicle.valid or lua_vehicle.object_name ~= "LuaEntity" then
        return false
    end

    EntityPreviewWindow.show(main_window:getPlayer(), lua_vehicle, main_window:getFrame(), {
        size     = PREVIEW_SIZE,
        offset_x = main_window:getWidth(),
        offset_y = 0
    })

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function hideVehiclePreview(event)
    if event.element.name ~= GUI_NAME.vehicle_slot_button then
        return false
    end

    local lua_player = game.get_player(event.player_index)

    if not lua_player then
        return false
    end

    return EntityPreviewWindow.hide(lua_player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function installPreviewHandlers()
    local current_hover_handler = script.get_event_handler(defines.events.on_gui_hover)

    if current_hover_handler ~= preview_hover_handler then
        local previous_hover_handler = current_hover_handler

        preview_hover_handler = function(event)
            showVehiclePreview(event)

            if previous_hover_handler then
                previous_hover_handler(event)
            end
        end

        script.on_event(defines.events.on_gui_hover, preview_hover_handler)
    end

    local current_leave_handler = script.get_event_handler(defines.events.on_gui_leave)

    if current_leave_handler ~= preview_leave_handler then
        local previous_leave_handler = current_leave_handler

        preview_leave_handler = function(event)
            hideVehiclePreview(event)

            if previous_leave_handler then
                previous_leave_handler(event)
            end
        end

        script.on_event(defines.events.on_gui_leave, preview_leave_handler)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.show(main_window, element)
    local source_editor_names = SourceEditorController.exposed_gui_names
    local source_index        = element and element.tags[source_editor_names.source_index_tag_name] or nil
    local target_index        = element and element.tags[source_editor_names.source_target_index_tag_name] or nil
    local source              = source_index and main_window.editor_state.configuration.sources[source_index] or nil

    installPreviewHandlers()
    main_window:showSourceSelector(source_index, source)

    local selector_state = main_window.editor_state.selector_state
    local dropdown       = ensureSelectorPanels(main_window)
    local selected_type  = source and source.type or SourceType.player

    if selected_type ~= SourceType.player and selected_type ~= SourceType.vehicle then
        selected_type = SourceType.player
    end

    selector_state.target_index  = target_index
    selector_state.selected_type = selected_type
    selector_state.drafts        = {
        [SourceType.player] = {
            selected = false
        },
        [SourceType.vehicle] = {
            vehicles = source and source.type == SourceType.vehicle and copyArray(source.vehicles) or { }
        }
    }

    local already_used = findPlayerInConfiguration(
        main_window.editor_state.configuration,
        main_window:getPlayer(),
        source_index,
        target_index
    )

    local checkbox = findGuiElement(getSelectorColumn(main_window), GUI_NAME.source_selector_player_checkbox)

    assert(checkbox, "Player source selector checkbox must exist here !")      -- [DEBUG-ONLY] . --

    checkbox.state   = not already_used
    checkbox.enabled = not already_used
    selector_state.drafts[SourceType.player].selected = checkbox.state

    dropdown.selected_index = getSourceTypeIndex(selected_type)
    setSelectedPanel(main_window, selected_type)

    renderVehicleDraft(main_window)
    refreshConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.selectType(main_window, selected_index)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state

    assert(selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --
    assert(SOURCE_TYPES[selected_index] ~= nil, "Selected source type index must be valid !")      -- [DEBUG-ONLY] . --

    local dropdown = ensureSelectorPanels(main_window)

    selector_state.selected_type = SOURCE_TYPES[selected_index]
    dropdown.selected_index      = selected_index

    setSelectedPanel(main_window, selector_state.selected_type)
    refreshConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.refresh(main_window)
    local editor_state = main_window.editor_state

    if not editor_state then
        return
    end

    if editor_state.inventory_selector_state then
        SourceEditorController.refreshSelector(main_window)
        return
    end

    local selector_state = editor_state.selector_state

    if not selector_state then
        return
    end

    local checkbox = findGuiElement(getSelectorColumn(main_window), GUI_NAME.source_selector_player_checkbox)

    if checkbox then
        selector_state.drafts[SourceType.player].selected = checkbox.state
    end

    refreshConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.cancel(main_window)
    local editor_state = main_window.editor_state

    if editor_state and editor_state.inventory_selector_state then
        SourceEditorController.cancelSelector(main_window)
        return
    end

    assert(editor_state and editor_state.selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    EntityPreviewWindow.hide(main_window:getPlayer())
    main_window:showSourceEditor()
    SourceEditorController.refresh(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.add(main_window)
    local editor_state = main_window.editor_state

    if editor_state and editor_state.inventory_selector_state then
        return SourceEditorController.addSelector(main_window)
    end

    local selector_state = editor_state and editor_state.selector_state

    assert(selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    if selector_state.selected_type ~= SourceType.player then
        return false
    end

    local checkbox = findGuiElement(getSelectorColumn(main_window), GUI_NAME.source_selector_player_checkbox)

    if not checkbox or not checkbox.state then
        return false
    end

    local sources    = editor_state.configuration.sources
    local source     = selector_state.source_index and sources[selector_state.source_index] or nil
    local lua_player = main_window:getPlayer()

    if source then
        if source.type ~= SourceType.player then
            return false
        end

        assert(type(source.players) == "table", "Player source must contain a players table !")      -- [DEBUG-ONLY] . --

        if selector_state.target_index then
            assert(source.players[selector_state.target_index] ~= nil, "Source target must exist here !")      -- [DEBUG-ONLY] . --
            source.players[selector_state.target_index] = lua_player
        else
            source.players[#source.players + 1] = lua_player
        end
    else
        sources[#sources + 1] = {
            type            = SourceType.player,
            players         = { lua_player },
            inventory_types = { },
            options         = { }
        }
    end

    EntityPreviewWindow.hide(main_window:getPlayer())
    main_window:showSourceEditor()
    SourceEditorController.refresh(main_window)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.onVehicleSlotClick(main_window, element, button)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state

    assert(selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    local vehicle_index = element.tags[VEHICLE_INDEX_TAG]

    if button == defines.mouse_button_type.right and vehicle_index then
        local vehicles = selector_state.drafts[SourceType.vehicle].vehicles

        assert(vehicles[vehicle_index] ~= nil, "Vehicle draft target must exist here !")      -- [DEBUG-ONLY] . --

        EntityPreviewWindow.hide(main_window:getPlayer())
        table.remove(vehicles, vehicle_index)
        renderVehicleDraft(main_window)
        refreshConfirm(main_window)
        return true
    end

    if button == defines.mouse_button_type.left and not vehicle_index then
        EntityPreviewWindow.hide(main_window:getPlayer())
        return beginVehicleSelection(main_window)
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.isSelectionActive(player_index)
    return getSelectionSessions()[player_index] ~= nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.cancelSelection(player_index)
    return finishVehicleSelection(player_index, true)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_player_selected_area, onVehicleSelection)
script.on_event(defines.events.on_player_alt_selected_area, onVehicleSelection)
script.on_event(defines.events.on_player_cursor_stack_changed, onCursorStackChanged)

return SourceSelectorController
