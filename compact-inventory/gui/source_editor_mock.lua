-- [TEMPORARY] Visual-only source editor renderer used while the new MainWindow UI is being prototyped. --

local SourceEditorMock = { }

local CREATION_COLUMN_NAME       = MOD_PREFIX .. "MW_creation-column"
local CREATION_TITLE_NAME        = MOD_PREFIX .. "MW_creation-title"
local SOURCE_TABS_NAME           = MOD_PREFIX .. "MW_creation-tabs"
local CREATION_ACTIONS_NAME      = MOD_PREFIX .. "MW_creation-actions"
local SOURCE_EDITOR_COLUMN_NAME  = MOD_PREFIX .. "MW_source-editor-column"
local SOURCE_SELECTOR_COLUMN_NAME = MOD_PREFIX .. "MW_source-selector-column"
local SOURCE_TABLE_NAME          = MOD_PREFIX .. "MW_source-table"
local SOURCE_SELECTOR_TYPE_NAME  = MOD_PREFIX .. "MW_source-selector-type"
local SOURCE_SELECTOR_LIST_NAME  = MOD_PREFIX .. "MW_source-selector-list"
local TITLE_NAME                 = MOD_PREFIX .. "MW_title"
local TITLE_ADD_BUTTON_NAME      = MOD_PREFIX .. "MW_add"
local CREATE_BUTTON_NAME         = MOD_PREFIX .. "MW_creation-create"
local CANCEL_BUTTON_NAME         = MOD_PREFIX .. "MW_creation-cancel"
local SOURCE_SLOT_BUTTON_NAME    = MOD_PREFIX .. "MW_source-slot-button"
local SLOT_COLUMNS               = 10

SourceEditorMock.exposed_gui_names = {
    slot_button            = SOURCE_SLOT_BUTTON_NAME,
    selector_cancel_button = CANCEL_BUTTON_NAME,
    selector_add_button    = CREATE_BUTTON_NAME
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

local function addSlot(cell, sprite, number, tooltip)
    local wrapper = cell.add({
        type      = "flow",
        direction = "horizontal"
    })

    local definition = {
        type    = "sprite-button",
        name    = SOURCE_SLOT_BUTTON_NAME,
        style   = "slot_button",
        tooltip = tooltip
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

local function addSlotCell(parent, slots)
    local cell = parent.add({
        type         = "table",
        column_count = SLOT_COLUMNS
    })

    cell.style.horizontal_spacing = 0
    cell.style.vertical_spacing   = 0

    for _, slot in ipairs(slots) do
        addSlot(cell, slot.sprite, slot.number, slot.tooltip)
    end

    -- An empty slot is the standard Factorio affordance for adding another entry.
    addSlot(cell, nil, nil, "Add")

    return cell
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addActions(parent)
    local actions = parent.add({
        type      = "flow",
        name      = CREATION_ACTIONS_NAME,
        direction = "horizontal"
    })

    actions.style.horizontally_stretchable = true
    actions.style.horizontal_spacing       = 4

    local spacer = actions.add({ type = "empty-widget" })
    spacer.style.horizontally_stretchable = true

    actions.add({
        type    = "button",
        name    = CANCEL_BUTTON_NAME,
        caption = "Cancel"
    })

    actions.add({
        type    = "button",
        name    = CREATE_BUTTON_NAME,
        caption = "Create",
        style   = "green_button"
    })

    return actions
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addSourceEditorColumn(parent, main_window)
    local column = parent.add({
        type      = "flow",
        name      = SOURCE_EDITOR_COLUMN_NAME,
        direction = "vertical"
    })

    column.style.horizontally_stretchable = true
    column.style.vertical_spacing         = 4

    local outer = column.add({
        type      = "frame",
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    outer.style.padding = 2

    local inner = outer.add({
        type      = "frame",
        direction = "vertical"
    })

    inner.style.padding = 2

    local source_table = inner.add({
        type                  = "table",
        name                  = SOURCE_TABLE_NAME,
        column_count          = 2,
        style                 = MOD_PREFIX .. "source-editor-table",
        draw_horizontal_lines = true
    })

    source_table.style.horizontal_spacing = 6
    source_table.style.vertical_spacing   = 4

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

    addSlotCell(source_table, {
        {
            sprite  = "utility/side_menu_players_icon",
            tooltip = main_window:getPlayer().name
        },
        {
            sprite  = "entity/wooden-chest",
            number  = 10,
            tooltip = "Wooden chest × 10"
        },
        {
            sprite  = "entity/car",
            number  = 2,
            tooltip = "Car × 2"
        }
    })

    addSlotCell(source_table, {
        {
            sprite  = "utility/side_menu_players_icon",
            tooltip = "Character main inventory"
        },
        {
            sprite  = "entity/car",
            tooltip = "Vehicle main inventory"
        }
    })

    addSlotCell(source_table, { })
    addSlotCell(source_table, { })

    return column
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addSourceSelectorColumn(parent, main_window)
    local column = parent.add({
        type      = "flow",
        name      = SOURCE_SELECTOR_COLUMN_NAME,
        direction = "vertical",
        visible   = false
    })

    column.style.horizontally_stretchable = true
    column.style.vertical_spacing         = 4

    column.add({
        type    = "label",
        caption = "Source type",
        style   = "heading_2_label"
    })

    column.add({
        type           = "drop-down",
        name           = SOURCE_SELECTOR_TYPE_NAME,
        items          = {
            "Players",
            "Logistic networks",
            "Train stop / path",
            "Chests",
            "Other entities"
        },
        selected_index = 1
    })

    local selector_frame = column.add({
        type      = "frame",
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    selector_frame.style.padding = 4

    selector_frame.add({
        type    = "label",
        caption = "Players",
        style   = "heading_2_label"
    })

    local selector_list = selector_frame.add({
        type      = "flow",
        name      = SOURCE_SELECTOR_LIST_NAME,
        direction = "vertical"
    })

    selector_list.add({
        type    = "checkbox",
        caption = main_window:getPlayer().name,
        state   = true
    })

    return column
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getNavigationControls(main_window)
    local frame           = main_window:getFrame()
    local title           = findGuiElement(frame, TITLE_NAME)
    local title_add       = findGuiElement(frame, CREATE_BUTTON_NAME)
    local windows_column  = findGuiElement(frame, MOD_PREFIX .. "MW_windows-column")
    local creation_column = findGuiElement(frame, CREATION_COLUMN_NAME)
    local editor_column   = findGuiElement(frame, SOURCE_EDITOR_COLUMN_NAME)
    local selector_column = findGuiElement(frame, SOURCE_SELECTOR_COLUMN_NAME)
    local actions         = findGuiElement(frame, CREATION_ACTIONS_NAME)
    local cancel          = actions and findGuiElement(actions, CANCEL_BUTTON_NAME)
    local confirm         = actions and findGuiElement(actions, CREATE_BUTTON_NAME)

    assert(title and title_add and windows_column and creation_column, "Main window navigation controls must exist here !")      -- [DEBUG-ONLY] . --
    assert(editor_column and selector_column and cancel and confirm, "Source editor navigation controls must exist here !")      -- [DEBUG-ONLY] . --

    return title, title_add, windows_column, creation_column, editor_column, selector_column, cancel, confirm
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function showWindows(main_window)
    local title, title_add, windows_column, creation_column = getNavigationControls(main_window)

    main_window:refresh()
    windows_column.visible  = true
    creation_column.visible = false
    title.caption           = "Compact Inventory"
    title_add.visible       = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function showEditorView(main_window)
    local title, title_add, windows_column, creation_column, editor_column, selector_column, _, confirm = getNavigationControls(main_window)
    local edit_mode = confirm.caption == "Save"

    windows_column.visible  = false
    creation_column.visible = true
    editor_column.visible   = true
    selector_column.visible = false
    title.caption           = edit_mode and "Edit inventory" or "Create inventory"
    title_add.visible       = false
    confirm.caption         = edit_mode and "Save" or "Create"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showEditor(main_window)
    local _, _, windows_column, _, editor_column, selector_column = getNavigationControls(main_window)

    if windows_column.visible then
        showEditorView(main_window)
    elseif selector_column.visible then
        showEditorView(main_window)
    elseif editor_column.visible then
        showWindows(main_window)
    else
        showEditorView(main_window)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showSelector(main_window)
    local title, title_add, windows_column, creation_column, editor_column, selector_column, _, confirm = getNavigationControls(main_window)

    windows_column.visible  = false
    creation_column.visible = true
    editor_column.visible   = false
    selector_column.visible = true
    title.caption           = "Select source"
    title_add.visible       = false
    confirm.caption         = "Add"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.render(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --

    local frame           = main_window:getFrame()
    local creation_column = findGuiElement(frame, CREATION_COLUMN_NAME)
    local creation_title  = findGuiElement(frame, CREATION_TITLE_NAME)
    local tabs            = findGuiElement(frame, SOURCE_TABS_NAME)
    local old_actions     = findGuiElement(frame, CREATION_ACTIONS_NAME)
    local title_add       = findGuiElement(frame, TITLE_ADD_BUTTON_NAME)

    assert(creation_column and tabs and title_add, "Legacy source editor controls must exist here !")      -- [DEBUG-ONLY] . --

    -- The title-bar add button shares the creation action name while this UI skeleton owns navigation.
    -- They have different parents, so the duplicate name is valid and lets the central click handler route both here.
    title_add.name = CREATE_BUTTON_NAME

    if creation_title then
        creation_title.destroy()
    end

    if old_actions then
        old_actions.destroy()
    end

    tabs.destroy()

    addSourceEditorColumn(creation_column, main_window)
    addSourceSelectorColumn(creation_column, main_window)

    local filler = creation_column.add({ type = "empty-widget" })
    filler.style.vertically_stretchable = true

    addActions(creation_column)

    local title, restored_add, windows_column = getNavigationControls(main_window)
    title.caption          = "Compact Inventory"
    restored_add.visible   = true
    windows_column.visible = true
    creation_column.visible = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorMock
