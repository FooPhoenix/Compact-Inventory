local InventoryType       = require("inventory.inventory_type")
local SourceCapabilities  = require("inventory.source_capabilities")
local SourceType          = require("inventory.source_type")

local SourceEditorController = { }

local GUI_NAME = {
    title                          = MOD_PREFIX .. "MW_title",
    source_editor_column           = MOD_PREFIX .. "MW_source-editor-column",
    source_table                   = MOD_PREFIX .. "MW_source-table",
    source_slot_button             = MOD_PREFIX .. "MW_source-slot-button",
    inventory_slot_button          = MOD_PREFIX .. "MW_inventory-slot-button",
    source_editor_actions          = MOD_PREFIX .. "MW_source-editor-actions",
    source_editor_confirm_button   = MOD_PREFIX .. "MW_source-editor-confirm",
    source_selector_column         = MOD_PREFIX .. "MW_source-selector-column",
    source_selector_list           = MOD_PREFIX .. "MW_source-selector-list",
    source_selector_cancel_button  = MOD_PREFIX .. "MW_source-selector-cancel",
    source_selector_add_button     = MOD_PREFIX .. "MW_source-selector-add",
    inventory_selector_column      = MOD_PREFIX .. "MW_inventory-selector-column",
    inventory_selector_content     = MOD_PREFIX .. "MW_inventory-selector-content",
    inventory_selector_actions     = MOD_PREFIX .. "MW_inventory-selector-actions",
    current_vehicle_checkbox       = MOD_PREFIX .. "MW_current-vehicle-checkbox"
}

local SOURCE_SLOT_COLUMNS = 10
local SOURCE_INDEX_TAG    = MOD_PREFIX .. "MW_SourceIndex"
local INVENTORY_TYPE_TAG  = MOD_PREFIX .. "MW_InventoryType"

local UI_INVENTORY_TYPES = {
    {
        inventory_type = InventoryType.character_main,
        caption        = "Main inventory",
        section        = "character"
    },
    {
        inventory_type = InventoryType.character_ammo,
        caption        = "Ammo",
        section        = "character"
    },
    {
        inventory_type = InventoryType.character_trash,
        caption        = "Trash",
        section        = "character"
    },
    {
        inventory_type = InventoryType.vehicle_main,
        caption        = "Vehicle main inventory",
        section        = "vehicle"
    },
    {
        inventory_type = InventoryType.vehicle_ammo,
        caption        = "Vehicle ammo",
        section        = "vehicle"
    },
    {
        inventory_type = InventoryType.vehicle_trash,
        caption        = "Vehicle trash",
        section        = "vehicle"
    }
}

SourceEditorController.exposed_gui_names = {
    source_slot_button            = GUI_NAME.source_slot_button,
    inventory_slot_button         = GUI_NAME.inventory_slot_button,
    selector_list                 = GUI_NAME.source_selector_list,
    selector_cancel_button        = GUI_NAME.source_selector_cancel_button,
    selector_add_button           = GUI_NAME.source_selector_add_button,
    current_vehicle_checkbox      = GUI_NAME.current_vehicle_checkbox,
    source_index_tag_name         = SOURCE_INDEX_TAG,
    inventory_type_tag_name       = INVENTORY_TYPE_TAG
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

local function getFirstCheckbox(parent)
    if parent.type == "checkbox" then
        return parent
    end

    for _, child in ipairs(parent.children) do
        local found = getFirstCheckbox(child)

        if found then
            return found
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getSourceSelectorControls(main_window)
    local selector_column = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_column)
    local selector_list   = selector_column and findGuiElement(selector_column, GUI_NAME.source_selector_list)
    local actions         = selector_column and findGuiElement(selector_column, MOD_PREFIX .. "MW_source-selector-actions")
    local add_button      = actions and actions[GUI_NAME.source_selector_add_button]

    assert(selector_list and add_button, "Player source selector controls must exist here !")      -- [DEBUG-ONLY] . --

    return selector_list, add_button
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addSlot(parent, name, sprite, number, tooltip, enabled, tags)
    local wrapper = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    local definition = {
        type    = "sprite-button",
        name    = name,
        style   = "slot_button",
        tooltip = tooltip,
        enabled = enabled ~= false,
        tags    = tags
    }

    if sprite then
        definition.sprite = sprite
    end

    if number and number > 1 then
        definition.number = number
    end

    return wrapper.add(definition)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addSlotCell(parent, name, slots, add_tooltip, add_enabled, tags)
    local cell = parent.add({
        type         = "table",
        column_count = SOURCE_SLOT_COLUMNS
    })

    cell.style.horizontal_spacing = 0
    cell.style.vertical_spacing   = 0

    for _, slot in ipairs(slots) do
        addSlot(cell, name, slot.sprite, slot.number, slot.tooltip, slot.enabled, tags)
    end

    addSlot(cell, name, nil, nil, add_tooltip, add_enabled, tags)

    return cell
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getPlayerSlots(source)
    local slots = { }

    for _, lua_player in ipairs(source.players or { }) do
        slots[#slots + 1] = {
            sprite  = "utility/side_menu_players_icon",
            tooltip = lua_player.name
        }
    end

    return slots
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function containsInventoryType(inventory_types, inventory_type)
    for _, selected_type in ipairs(inventory_types or { }) do
        if selected_type == inventory_type then
            return true
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getInventoryTypeCaption(inventory_type)
    for _, metadata in ipairs(UI_INVENTORY_TYPES) do
        if metadata.inventory_type == inventory_type then
            return metadata.caption
        end
    end

    return tostring(inventory_type)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getInventorySlots(source)
    local slots = { }

    for _, inventory_type in ipairs(source.inventory_types or { }) do
        local is_vehicle = inventory_type == InventoryType.vehicle_main
            or inventory_type == InventoryType.vehicle_ammo
            or inventory_type == InventoryType.vehicle_trash

        slots[#slots + 1] = {
            sprite  = is_vehicle and "entity/car" or "utility/side_menu_players_icon",
            tooltip = getInventoryTypeCaption(inventory_type)
        }
    end

    return slots
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getAvailableUiInventoryTypes(source)
    local result = { }

    for _, metadata in ipairs(UI_INVENTORY_TYPES) do
        if SourceCapabilities.supportsInventoryType(source, metadata.inventory_type) then
            result[#result + 1] = metadata
        end
    end

    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function findPlayerInConfiguration(configuration, lua_player, ignored_source_index)
    for source_index, source in ipairs(configuration.sources or { }) do
        if source_index ~= ignored_source_index and source.type == SourceType.player then
            for _, selected_player in ipairs(source.players or { }) do
                if selected_player == lua_player then
                    return true
                end
            end
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getInventorySelectorColumn(main_window)
    local editor_column = findGuiElement(main_window:getFrame(), GUI_NAME.source_editor_column)

    assert(editor_column, "Source editor column must exist here !")      -- [DEBUG-ONLY] . --

    local inventory_column = editor_column[GUI_NAME.inventory_selector_column]

    if inventory_column then
        return inventory_column
    end

    inventory_column = editor_column.add({
        type      = "flow",
        name      = GUI_NAME.inventory_selector_column,
        direction = "vertical",
        visible   = false
    })

    inventory_column.style.horizontally_stretchable = true
    inventory_column.style.vertical_spacing         = 4

    local content = inventory_column.add({
        type      = "flow",
        name      = GUI_NAME.inventory_selector_content,
        direction = "vertical"
    })

    content.style.horizontally_stretchable = true
    content.style.vertical_spacing         = 8

    local filler = inventory_column.add({ type = "empty-widget" })
    filler.style.vertically_stretchable = true

    local actions = inventory_column.add({
        type      = "flow",
        name      = GUI_NAME.inventory_selector_actions,
        direction = "horizontal"
    })

    actions.style.horizontally_stretchable = true
    actions.style.horizontal_spacing       = 4

    local spacer = actions.add({ type = "empty-widget" })
    spacer.style.horizontally_stretchable = true

    actions.add({
        type    = "button",
        name    = GUI_NAME.source_selector_cancel_button,
        caption = "Cancel"
    })

    actions.add({
        type    = "button",
        name    = GUI_NAME.source_selector_add_button,
        caption = "Add",
        style   = "green_button"
    })

    return inventory_column
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function setEditorContentVisible(main_window, visible)
    local editor_column    = findGuiElement(main_window:getFrame(), GUI_NAME.source_editor_column)
    local inventory_column = getInventorySelectorColumn(main_window)

    for _, child in ipairs(editor_column.children) do
        if child ~= inventory_column then
            child.visible = visible
        end
    end

    inventory_column.visible = not visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function restoreEditorView(main_window)
    local editor_state = main_window.editor_state
    local frame        = main_window:getFrame()
    local title        = findGuiElement(frame, GUI_NAME.title)
    local actions      = findGuiElement(frame, GUI_NAME.source_editor_actions)
    local confirm      = actions and actions[GUI_NAME.source_editor_confirm_button]

    assert(editor_state and title and confirm, "Source editor state and controls must exist here !")      -- [DEBUG-ONLY] . --

    setEditorContentVisible(main_window, true)
    title.caption   = editor_state.mode == "edit" and "Edit inventory" or "Create inventory"
    confirm.caption = editor_state.mode == "edit" and "Save" or "Create"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addInventoryCheckbox(parent, metadata, state)
    parent.add({
        type    = "checkbox",
        caption = metadata.caption,
        state   = state,
        tags    = {
            [INVENTORY_TYPE_TAG] = metadata.inventory_type
        }
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addPlayerInventoryPanel(parent, source, selected_types)
    local available = getAvailableUiInventoryTypes(source)
    local character = { }
    local vehicle   = { }

    for _, metadata in ipairs(available) do
        if metadata.section == "vehicle" then
            vehicle[#vehicle + 1] = metadata
        else
            character[#character + 1] = metadata
        end
    end

    if #character == 0 and #vehicle == 0 then
        return
    end

    local panel = parent.add({
        type      = "frame",
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    panel.style.padding = 6

    panel.add({
        type    = "label",
        caption = "Player",
        style   = "heading_2_label"
    })

    local columns = panel.add({
        type         = "table",
        column_count = 2
    })

    columns.style.horizontal_spacing = 18
    columns.style.vertical_spacing   = 0

    local character_list = columns.add({
        type      = "flow",
        name      = GUI_NAME.source_selector_list,
        direction = "vertical"
    })

    character_list.style.vertical_spacing = 4

    for _, metadata in ipairs(character) do
        addInventoryCheckbox(character_list, metadata, containsInventoryType(selected_types, metadata.inventory_type))
    end

    local vehicle_list = columns.add({
        type      = "flow",
        name      = GUI_NAME.source_selector_list,
        direction = "vertical"
    })

    vehicle_list.style.vertical_spacing = 4

    local has_vehicle_inventory = false

    for _, metadata in ipairs(vehicle) do
        if containsInventoryType(selected_types, metadata.inventory_type) then
            has_vehicle_inventory = true
            break
        end
    end

    vehicle_list.add({
        type    = "checkbox",
        name    = GUI_NAME.current_vehicle_checkbox,
        caption = "Include current vehicle",
        state   = has_vehicle_inventory
    })

    for _, metadata in ipairs(vehicle) do
        local checkbox = vehicle_list.add({
            type    = "checkbox",
            caption = metadata.caption,
            state   = containsInventoryType(selected_types, metadata.inventory_type),
            enabled = has_vehicle_inventory,
            tags    = {
                [INVENTORY_TYPE_TAG] = metadata.inventory_type
            }
        })

        checkbox.style.left_margin = 12
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function readInventorySelector(main_window)
    local editor_state   = main_window.editor_state
    local selector_state = editor_state and editor_state.inventory_selector_state

    assert(selector_state, "Inventory selector state must exist here !")      -- [DEBUG-ONLY] . --

    local inventory_column = getInventorySelectorColumn(main_window)
    local selected_types   = { }
    local include_vehicle  = false

    local function scan(element)
        if element.type == "checkbox" then
            if element.name == GUI_NAME.current_vehicle_checkbox then
                include_vehicle = element.state
            elseif element.state then
                local inventory_type = element.tags[INVENTORY_TYPE_TAG]

                if inventory_type then
                    selected_types[#selected_types + 1] = inventory_type
                end
            end
        end

        for _, child in ipairs(element.children) do
            scan(child)
        end
    end

    scan(inventory_column)

    if not include_vehicle then
        local filtered = { }

        for _, inventory_type in ipairs(selected_types) do
            if inventory_type ~= InventoryType.vehicle_main
                and inventory_type ~= InventoryType.vehicle_ammo
                and inventory_type ~= InventoryType.vehicle_trash then

                filtered[#filtered + 1] = inventory_type
            end
        end

        selected_types = filtered
    end

    selector_state.inventory_types         = selected_types
    selector_state.include_current_vehicle = include_vehicle
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshVehicleCheckboxes(main_window)
    local inventory_column = getInventorySelectorColumn(main_window)
    local master           = findGuiElement(inventory_column, GUI_NAME.current_vehicle_checkbox)

    if not master then
        return
    end

    local function update(element)
        if element.type == "checkbox" then
            local inventory_type = element.tags[INVENTORY_TYPE_TAG]

            if inventory_type == InventoryType.vehicle_main
                or inventory_type == InventoryType.vehicle_ammo
                or inventory_type == InventoryType.vehicle_trash then

                element.enabled = master.state

                if not master.state then
                    element.state = false
                end
            end
        end

        for _, child in ipairs(element.children) do
            update(child)
        end
    end

    update(inventory_column)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshInventorySelectorConfirm(main_window)
    local editor_state   = main_window.editor_state
    local selector_state = editor_state and editor_state.inventory_selector_state

    if not selector_state then
        return
    end

    local inventory_column = getInventorySelectorColumn(main_window)
    local actions          = inventory_column[GUI_NAME.inventory_selector_actions]
    local confirm          = actions and actions[GUI_NAME.source_selector_add_button]

    assert(confirm, "Inventory selector confirm button must exist here !")      -- [DEBUG-ONLY] . --
    confirm.enabled = #selector_state.inventory_types > 0
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.getFirstIncompleteSource(configuration)
    assert(type(configuration) == "table", "Source editor configuration must be a table !")      -- [DEBUG-ONLY] . --

    local sources = configuration.sources or { }

    if #sources == 0 then
        return 0
    end

    for source_index, source in ipairs(sources) do
        if type(source.players) ~= "table" or #source.players == 0 then
            return source_index
        end

        if type(source.inventory_types) ~= "table" or #source.inventory_types == 0 then
            return source_index
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.isConfigurationValid(configuration)
    return SourceEditorController.getFirstIncompleteSource(configuration) == nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.refresh(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --
    assert(main_window.editor_state and type(main_window.editor_state.configuration) == "table", "Source editor state must exist here !")      -- [DEBUG-ONLY] . --

    local frame         = main_window:getFrame()
    local source_table  = findGuiElement(frame, GUI_NAME.source_table)
    local editor        = findGuiElement(frame, GUI_NAME.source_editor_column)
    local actions       = editor and editor[GUI_NAME.source_editor_actions]
    local confirm       = actions and actions[GUI_NAME.source_editor_confirm_button]
    local configuration = main_window.editor_state.configuration

    assert(source_table and confirm, "Source editor controls must exist here !")      -- [DEBUG-ONLY] . --

    source_table.clear()

    local entity_header = source_table.add({
        type    = "label",
        caption = "Entities",
        style   = "heading_2_label"
    })

    entity_header.style.minimal_width = 180

    local inventory_header = source_table.add({
        type    = "label",
        caption = "Inventories",
        style   = "heading_2_label"
    })

    inventory_header.style.minimal_width = 180

    for source_index, source in ipairs(configuration.sources or { }) do
        local available_types = getAvailableUiInventoryTypes(source)
        local tags            = {
            [SOURCE_INDEX_TAG] = source_index
        }

        addSlotCell(
            source_table,
            GUI_NAME.source_slot_button,
            getPlayerSlots(source),
            "Edit source",
            true,
            tags
        )

        addSlotCell(
            source_table,
            GUI_NAME.inventory_slot_button,
            getInventorySlots(source),
            #available_types > 0 and "Select inventories" or "No compatible inventories",
            #available_types > 0,
            tags
        )
    end

    -- Permanent empty row used to add another source. Inventories stay disabled until a source exists on that row.
    addSlotCell(source_table, GUI_NAME.source_slot_button, { }, "Add source", true)
    addSlotCell(source_table, GUI_NAME.inventory_slot_button, { }, "Select a source first", false)

    confirm.enabled = SourceEditorController.isConfigurationValid(configuration)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.begin(main_window, mode, configuration, target_inventory_id)
    main_window:showSourceEditor(mode, configuration, target_inventory_id)
    restoreEditorView(main_window)
    SourceEditorController.refresh(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.showSelector(main_window, element)
    local source_index = element and element.tags[SOURCE_INDEX_TAG] or nil
    local source       = source_index and main_window.editor_state.configuration.sources[source_index] or nil

    main_window:showSourceSelector(source_index, source)

    local selector_list, add_button = getSourceSelectorControls(main_window)
    local checkbox                  = getFirstCheckbox(selector_list)
    local already_used              = findPlayerInConfiguration(
        main_window.editor_state.configuration,
        main_window:getPlayer(),
        source_index
    )

    assert(checkbox, "Player source selector checkbox must exist here !")      -- [DEBUG-ONLY] . --

    checkbox.state     = not already_used
    checkbox.enabled   = not already_used
    add_button.enabled = not already_used
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.showInventorySelector(main_window, element)
    assert(main_window.editor_state ~= nil, "Inventory selector requires an active source editor state !")      -- [DEBUG-ONLY] . --
    assert(main_window.editor_state.selector_state == nil, "Inventory selector cannot open while the source selector is active !")      -- [DEBUG-ONLY] . --
    assert(main_window.editor_state.inventory_selector_state == nil, "Inventory selector state already exists !")      -- [DEBUG-ONLY] . --

    local source_index = element.tags[SOURCE_INDEX_TAG]
    local source       = source_index and main_window.editor_state.configuration.sources[source_index] or nil

    assert(source, "Inventory selector source must exist here !")      -- [DEBUG-ONLY] . --

    local selected_types = { }

    for _, inventory_type in ipairs(source.inventory_types or { }) do
        if SourceCapabilities.supportsInventoryType(source, inventory_type) then
            selected_types[#selected_types + 1] = inventory_type
        end
    end

    main_window.editor_state.inventory_selector_state = {
        source_index            = source_index,
        inventory_types         = selected_types,
        include_current_vehicle = containsInventoryType(selected_types, InventoryType.vehicle_main)
            or containsInventoryType(selected_types, InventoryType.vehicle_ammo)
            or containsInventoryType(selected_types, InventoryType.vehicle_trash)
    }

    local frame            = main_window:getFrame()
    local title            = findGuiElement(frame, GUI_NAME.title)
    local inventory_column = getInventorySelectorColumn(main_window)
    local content          = inventory_column[GUI_NAME.inventory_selector_content]
    local actions          = inventory_column[GUI_NAME.inventory_selector_actions]
    local confirm          = actions and actions[GUI_NAME.source_selector_add_button]

    assert(title and content and confirm, "Inventory selector controls must exist here !")      -- [DEBUG-ONLY] . --

    content.clear()

    if source.type == SourceType.player then
        addPlayerInventoryPanel(content, source, selected_types)
    end

    setEditorContentVisible(main_window, false)
    title.caption   = "Select inventories"
    confirm.caption = #selected_types > 0 and "Save" or "Add"

    readInventorySelector(main_window)
    refreshInventorySelectorConfirm(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.cancelSelector(main_window)
    local editor_state = main_window.editor_state

    assert(editor_state, "Source editor state must exist here !")      -- [DEBUG-ONLY] . --

    if editor_state.inventory_selector_state then
        editor_state.inventory_selector_state = nil
        restoreEditorView(main_window)
        SourceEditorController.refresh(main_window)
        return
    end

    assert(editor_state.selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    main_window:showSourceEditor()
    SourceEditorController.refresh(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.addSelector(main_window)
    local editor_state = main_window.editor_state

    assert(editor_state, "Source editor state must exist here !")      -- [DEBUG-ONLY] . --

    if editor_state.inventory_selector_state then
        readInventorySelector(main_window)

        local selector_state = editor_state.inventory_selector_state

        if #selector_state.inventory_types == 0 then
            return false
        end

        local source = editor_state.configuration.sources[selector_state.source_index]

        assert(source, "Inventory selector source must exist here !")      -- [DEBUG-ONLY] . --

        source.inventory_types = selector_state.inventory_types
        editor_state.inventory_selector_state = nil

        restoreEditorView(main_window)
        SourceEditorController.refresh(main_window)
        return true
    end

    assert(editor_state.selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    local selector_list = getSourceSelectorControls(main_window)
    local checkbox      = getFirstCheckbox(selector_list)

    assert(checkbox, "Player source selector checkbox must exist here !")      -- [DEBUG-ONLY] . --

    if not checkbox.state then
        return false
    end

    local selector_state = editor_state.selector_state
    local existing       = selector_state.source_index and editor_state.configuration.sources[selector_state.source_index] or nil
    local source         = {
        type            = SourceType.player,
        players         = { main_window:getPlayer() },
        inventory_types = existing and existing.inventory_types or { },
        options         = existing and existing.options or { }
    }

    assert(#SourceCapabilities.getAvailableInventoryTypes(source) > 0, "Player source must expose at least one InventoryType !")      -- [DEBUG-ONLY] . --

    local sources = editor_state.configuration.sources

    if selector_state.source_index then
        sources[selector_state.source_index] = source
    else
        sources[#sources + 1] = source
    end

    main_window:showSourceEditor()
    SourceEditorController.refresh(main_window)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.refreshSelector(main_window)
    local editor_state = main_window.editor_state

    if not editor_state then
        return
    end

    if editor_state.inventory_selector_state then
        refreshVehicleCheckboxes(main_window)
        readInventorySelector(main_window)
        refreshInventorySelectorConfirm(main_window)
        return
    end

    if not editor_state.selector_state then
        return
    end

    local selector_list, add_button = getSourceSelectorControls(main_window)
    local checkbox                  = getFirstCheckbox(selector_list)

    if checkbox then
        add_button.enabled = checkbox.state
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorController
