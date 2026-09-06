local SourceCapabilities = require("inventory.source_capabilities")
local SourceType         = require("inventory.source_type")

local SourceEditorController = { }

local GUI_NAME = {
    source_editor_column          = MOD_PREFIX .. "MW_source-editor-column",
    source_table                  = MOD_PREFIX .. "MW_source-table",
    source_slot_button            = MOD_PREFIX .. "MW_source-slot-button",
    inventory_slot_button         = MOD_PREFIX .. "MW_inventory-slot-button",
    source_editor_actions         = MOD_PREFIX .. "MW_source-editor-actions",
    source_editor_confirm_button  = MOD_PREFIX .. "MW_source-editor-confirm",
    source_selector_column        = MOD_PREFIX .. "MW_source-selector-column",
    source_selector_list          = MOD_PREFIX .. "MW_source-selector-list",
    source_selector_cancel_button = MOD_PREFIX .. "MW_source-selector-cancel",
    source_selector_add_button    = MOD_PREFIX .. "MW_source-selector-add"
}

local SOURCE_SLOT_COLUMNS = 10

SourceEditorController.exposed_gui_names = {
    source_slot_button            = GUI_NAME.source_slot_button,
    inventory_slot_button         = GUI_NAME.inventory_slot_button,
    selector_cancel_button        = GUI_NAME.source_selector_cancel_button,
    selector_add_button           = GUI_NAME.source_selector_add_button
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

local function addSlot(parent, name, sprite, number, tooltip, enabled)
    local wrapper = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    local definition = {
        type    = "sprite-button",
        name    = name,
        style   = "slot_button",
        tooltip = tooltip,
        enabled = enabled ~= false
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

local function addSlotCell(parent, name, slots, add_tooltip, add_enabled)
    local cell = parent.add({
        type         = "table",
        column_count = SOURCE_SLOT_COLUMNS
    })

    cell.style.horizontal_spacing = 0
    cell.style.vertical_spacing   = 0

    for _, slot in ipairs(slots) do
        addSlot(cell, name, slot.sprite, slot.number, slot.tooltip, slot.enabled)
    end

    addSlot(cell, name, nil, nil, add_tooltip, add_enabled)

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

    local frame        = main_window:getFrame()
    local source_table = findGuiElement(frame, GUI_NAME.source_table)
    local editor       = findGuiElement(frame, GUI_NAME.source_editor_column)
    local actions      = editor and editor[GUI_NAME.source_editor_actions]
    local confirm      = actions and actions[GUI_NAME.source_editor_confirm_button]
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

    for _, source in ipairs(configuration.sources or { }) do
        local available_types = SourceCapabilities.getAvailableInventoryTypes(source)

        addSlotCell(
            source_table,
            GUI_NAME.source_slot_button,
            getPlayerSlots(source),
            "Edit source",
            true
        )

        addSlotCell(
            source_table,
            GUI_NAME.inventory_slot_button,
            { },
            #available_types > 0 and "Select inventories" or "No compatible inventories",
            #available_types > 0
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
    SourceEditorController.refresh(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.showSelector(main_window)
    main_window:showSourceSelector()

    local selector_list = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_list)
    local checkbox      = selector_list and getFirstCheckbox(selector_list)
    local add_button    = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_add_button)

    assert(checkbox and add_button, "Player source selector controls must exist here !")      -- [DEBUG-ONLY] . --

    checkbox.state    = true
    add_button.enabled = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.cancelSelector(main_window)
    assert(main_window.editor_state and main_window.editor_state.selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    main_window:showSourceEditor()
    SourceEditorController.refresh(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorController.addSelector(main_window)
    assert(main_window.editor_state and main_window.editor_state.selector_state, "Source selector state must exist here !")      -- [DEBUG-ONLY] . --

    local selector_list = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_list)
    local checkbox      = selector_list and getFirstCheckbox(selector_list)

    assert(checkbox, "Player source selector checkbox must exist here !")      -- [DEBUG-ONLY] . --

    if not checkbox.state then
        return false
    end

    local source = {
        type            = SourceType.player,
        players         = { main_window:getPlayer() },
        inventory_types = { },
        options         = { }
    }

    -- Validate the source shape against the same semantic capability layer used later by the inventory selector.
    assert(#SourceCapabilities.getAvailableInventoryTypes(source) > 0, "Player source must expose at least one InventoryType !")      -- [DEBUG-ONLY] . --

    local selector_state = main_window.editor_state.selector_state
    local sources        = main_window.editor_state.configuration.sources

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
    if not main_window.editor_state or not main_window.editor_state.selector_state then
        return
    end

    local selector_list = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_list)
    local checkbox      = selector_list and getFirstCheckbox(selector_list)
    local add_button    = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_add_button)

    if checkbox and add_button then
        add_button.enabled = checkbox.state
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorController
