local SourceType             = require("inventory.source_type")
local SourceEditorController = require("gui.source_editor_controller")

local SourceSelectorController = { }

local GUI_NAME = {
    source_selector_column          = MOD_PREFIX .. "MW_source-selector-column",
    source_selector_type            = MOD_PREFIX .. "MW_source-selector-type",
    source_selector_tabs            = MOD_PREFIX .. "MW_source-selector-tabs",
    source_selector_player_content  = MOD_PREFIX .. "MW_source-selector-player-content",
    source_selector_vehicle_content = MOD_PREFIX .. "MW_source-selector-vehicle-content",
    source_selector_list            = MOD_PREFIX .. "MW_source-selector-list",
    source_selector_player_checkbox = MOD_PREFIX .. "MW_source-selector-player-checkbox",
    source_selector_actions         = MOD_PREFIX .. "MW_source-selector-actions",
    source_selector_add_button      = MOD_PREFIX .. "MW_source-selector-add",
    vehicle_table                   = MOD_PREFIX .. "MW_source-selector-vehicle-table",
    vehicle_slot_button             = MOD_PREFIX .. "MW_source-selector-vehicle-slot"
}

local VEHICLE_INDEX_TAG = MOD_PREFIX .. "MW_SourceSelectorVehicleIndex"

local SOURCE_TYPES = {
    SourceType.player,
    SourceType.vehicle
}

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

local function ensureTabbedSelector(main_window)
    local selector_column = getSelectorColumn(main_window)
    local dropdown        = selector_column[GUI_NAME.source_selector_type]
    local tabbed_pane     = selector_column[GUI_NAME.source_selector_tabs]

    assert(dropdown, "Source type dropdown must exist here !")      -- [DEBUG-ONLY] . --

    dropdown.items = { "Player", "Vehicle" }

    if tabbed_pane then
        return dropdown, tabbed_pane
    end

    local old_selector_list = findGuiElement(selector_column, GUI_NAME.source_selector_list)

    if old_selector_list then
        local old_panel = old_selector_list.parent
        assert(old_panel, "Legacy source selector panel must exist here !")      -- [DEBUG-ONLY] . --
        old_panel.destroy()
    end

    tabbed_pane = selector_column.add({
        type  = "tabbed-pane",
        name  = GUI_NAME.source_selector_tabs,
        index = dropdown.get_index_in_parent() + 1
    })

    tabbed_pane.style.horizontally_stretchable = true

    local player_tab = tabbed_pane.add({
        type    = "tab",
        caption = "Player"
    })

    local player_content = tabbed_pane.add({
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

    local vehicle_tab = tabbed_pane.add({
        type    = "tab",
        caption = "Vehicle"
    })

    local vehicle_content = tabbed_pane.add({
        type      = "frame",
        name      = GUI_NAME.source_selector_vehicle_content,
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    vehicle_content.style.padding = 4

    vehicle_content.add({
        type    = "label",
        caption = "Vehicles",
        style   = "heading_2_label"
    })

    local vehicle_table = vehicle_content.add({
        type         = "table",
        name         = GUI_NAME.vehicle_table,
        column_count = 10
    })

    vehicle_table.style.horizontal_spacing = 0
    vehicle_table.style.vertical_spacing   = 0

    tabbed_pane.add_tab(player_tab, player_content)
    tabbed_pane.add_tab(vehicle_tab, vehicle_content)

    -- The dropdown is the visible navigation. Tabs only provide persistent content containers.
    player_tab.visible  = false
    vehicle_tab.visible = false

    return dropdown, tabbed_pane
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addVehicleSlot(parent, lua_vehicle, vehicle_index)
    local wrapper = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    local definition = {
        type    = "sprite-button",
        name    = GUI_NAME.vehicle_slot_button,
        style   = "slot_button",
        tooltip = lua_vehicle and lua_vehicle.name or "Add vehicle",
        tags    = { }
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
    local selector       = getSelectorColumn(main_window)
    local vehicle_table  = selector and findGuiElement(selector, GUI_NAME.vehicle_table)

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
        local selector_column = getSelectorColumn(main_window)
        local checkbox        = findGuiElement(selector_column, GUI_NAME.source_selector_player_checkbox)
        local source          = selector_state.source_index
            and main_window.editor_state.configuration.sources[selector_state.source_index]
            or nil

        add_button.enabled = checkbox ~= nil
            and checkbox.state
            and (source == nil or source.type == SourceType.player)
        return
    end

    -- Vehicle selection is intentionally not committable until the empty-slot selection workflow is implemented.
    add_button.enabled = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.show(main_window, element)
    local source_editor_names = SourceEditorController.exposed_gui_names
    local source_index        = element and element.tags[source_editor_names.source_index_tag_name] or nil
    local target_index        = element and element.tags[source_editor_names.source_target_index_tag_name] or nil
    local source              = source_index and main_window.editor_state.configuration.sources[source_index] or nil

    main_window:showSourceSelector(source_index, source)

    local selector_state = main_window.editor_state.selector_state
    local dropdown, tabs = ensureTabbedSelector(main_window)
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

    local selected_index = getSourceTypeIndex(selected_type)
    dropdown.selected_index = selected_index
    tabs.selected_tab_index = selected_index

    renderVehicleDraft(main_window)
    refreshConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceSelectorController.selectType(main_window, selected_index)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state

    assert(selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --
    assert(SOURCE_TYPES[selected_index] ~= nil, "Selected source type index must be valid !")      -- [DEBUG-ONLY] . --

    local dropdown, tabs = ensureTabbedSelector(main_window)

    selector_state.selected_type = SOURCE_TYPES[selected_index]
    dropdown.selected_index      = selected_index
    tabs.selected_tab_index      = selected_index

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

    local selector_column = getSelectorColumn(main_window)
    local checkbox        = findGuiElement(selector_column, GUI_NAME.source_selector_player_checkbox)

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

        table.remove(vehicles, vehicle_index)
        renderVehicleDraft(main_window)
        refreshConfirm(main_window)
        return true
    end

    -- Left click on the empty slot is intentionally reserved for the future entity selection workflow.
    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceSelectorController
