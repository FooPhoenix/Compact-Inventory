-- [TEMPORARY] Visual-only source editor renderer used while the new MainWindow UI is being prototyped. --

local SourceEditorMock = { }

local SOURCE_TABLE_NAME          = MOD_PREFIX .. "MW_source-table"
local SOURCE_TABS_NAME           = MOD_PREFIX .. "MW_creation-tabs"
local SOURCE_EDITOR_TAB_NAME     = MOD_PREFIX .. "MW_source-editor-tab"
local SOURCE_SELECTOR_TAB_NAME   = MOD_PREFIX .. "MW_source-selector-tab"
local SOURCE_EDITOR_PANEL_NAME   = MOD_PREFIX .. "MW_source-editor-panel"
local SOURCE_SELECTOR_PANEL_NAME = MOD_PREFIX .. "MW_source-selector-panel"
local CREATION_TITLE_NAME        = MOD_PREFIX .. "MW_creation-title"
local CREATION_ACTIONS_NAME      = MOD_PREFIX .. "MW_creation-actions"
local TITLE_NAME                 = MOD_PREFIX .. "MW_title"
local TITLE_ADD_BUTTON_NAME      = MOD_PREFIX .. "MW_add"
local CREATE_BUTTON_NAME         = MOD_PREFIX .. "MW_creation-create"
local CANCEL_BUTTON_NAME         = MOD_PREFIX .. "MW_creation-cancel"
local SOURCE_SLOT_BUTTON_NAME    = MOD_PREFIX .. "MW_source-slot-button"
local NAVIGATION_CONFIRM_BUTTON  = MOD_PREFIX .. "MW_source-navigation-confirm"
local NAVIGATION_CANCEL_BUTTON   = MOD_PREFIX .. "MW_source-navigation-cancel"
local SLOT_COLUMNS               = 10

SourceEditorMock.exposed_gui_names = {
    slot_button            = SOURCE_SLOT_BUTTON_NAME,
    selector_cancel_button = NAVIGATION_CANCEL_BUTTON,
    selector_add_button    = NAVIGATION_CONFIRM_BUTTON
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

local function findLabelByCaption(parent, caption)
    if parent.type == "label" and parent.caption == caption then
        return parent
    end

    for _, child in ipairs(parent.children) do
        local found = findLabelByCaption(child, caption)

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

local function getNavigationControls(main_window)
    local frame          = main_window:getFrame()
    local title          = findGuiElement(frame, TITLE_NAME)
    local title_add      = findGuiElement(frame, NAVIGATION_CONFIRM_BUTTON)
    local actions        = findGuiElement(frame, CREATION_ACTIONS_NAME)
    local cancel         = actions and findGuiElement(actions, NAVIGATION_CANCEL_BUTTON)
    local confirm        = actions and findGuiElement(actions, NAVIGATION_CONFIRM_BUTTON)
    local tabs           = findGuiElement(frame, SOURCE_TABS_NAME)
    local editor_panel   = findGuiElement(frame, SOURCE_EDITOR_PANEL_NAME)
    local selector_panel = findGuiElement(frame, SOURCE_SELECTOR_PANEL_NAME)

    assert(title and title_add and cancel and confirm and tabs and editor_panel and selector_panel, "Source editor navigation controls must exist here !")      -- [DEBUG-ONLY] . --

    return title, title_add, cancel, confirm, tabs, editor_panel, selector_panel
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function showWindows(main_window)
    local title, title_add = getNavigationControls(main_window)

    main_window:showWindowsList()
    title.caption    = "Compact Inventory"
    title_add.visible = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function showEditorView(main_window)
    local title, title_add, _, confirm, tabs = getNavigationControls(main_window)
    local edit_mode = confirm.caption == "Save"

    tabs.selected_tab_index = 1
    title.caption            = edit_mode and "Edit inventory" or "Create inventory"
    title_add.visible        = false
    confirm.caption          = edit_mode and "Save" or "Create"
    confirm.visible          = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showEditor(main_window)
    local _, _, _, _, tabs = getNavigationControls(main_window)
    local frame             = main_window:getFrame()
    local windows_column    = findGuiElement(frame, MOD_PREFIX .. "MW_windows-column")
    local creation_column   = findGuiElement(frame, MOD_PREFIX .. "MW_creation-column")

    assert(windows_column and creation_column, "Main window columns must exist here !")      -- [DEBUG-ONLY] . --

    if windows_column.visible then
        main_window:showCreationPanel(nil)
        showEditorView(main_window)
        return
    end

    if tabs.selected_tab_index == 2 then
        showEditorView(main_window)
        return
    end

    showWindows(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showSelector(main_window)
    local title, title_add, _, confirm, tabs = getNavigationControls(main_window)

    tabs.selected_tab_index = 2
    title.caption            = "Select source"
    title_add.visible        = false
    confirm.caption          = "Add"
    confirm.visible          = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.render(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --

    local frame             = main_window:getFrame()
    local source_table      = findGuiElement(frame, SOURCE_TABLE_NAME)
    local tabs              = findGuiElement(frame, SOURCE_TABS_NAME)
    local editor_tab        = findGuiElement(frame, SOURCE_EDITOR_TAB_NAME)
    local selector_tab      = findGuiElement(frame, SOURCE_SELECTOR_TAB_NAME)
    local creation_title    = findGuiElement(frame, CREATION_TITLE_NAME)
    local title_add         = findGuiElement(frame, TITLE_ADD_BUTTON_NAME)
    local create_button     = findGuiElement(frame, CREATE_BUTTON_NAME)
    local cancel_button     = findGuiElement(frame, CANCEL_BUTTON_NAME)

    assert(source_table and tabs and editor_tab and selector_tab and creation_title, "Source editor controls must exist here !")      -- [DEBUG-ONLY] . --
    assert(title_add and create_button and cancel_button, "Source editor action controls must exist here !")      -- [DEBUG-ONLY] . --

    -- Route all context navigation through the prototype handler instead of the legacy creation branches in control.lua.
    title_add.name     = NAVIGATION_CONFIRM_BUTTON
    create_button.name = NAVIGATION_CONFIRM_BUTTON
    cancel_button.name = NAVIGATION_CANCEL_BUTTON

    creation_title.visible = false
    editor_tab.visible      = false
    selector_tab.visible    = false

    local editor_hint = findLabelByCaption(frame, "The last empty row is kept available for adding another source.")
    local selector_hint = findLabelByCaption(frame, "Other source types are visual placeholders for now.")

    if editor_hint then
        editor_hint.destroy()
    end

    if selector_hint then
        selector_hint.destroy()
    end

    source_table.style = MOD_PREFIX .. "source-editor-table"
    source_table.draw_horizontal_lines = true
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

    create_button.enabled = true
    create_button.tooltip = nil
    tabs.selected_tab_index = 1

    local title, restored_add = getNavigationControls(main_window)
    title.caption         = "Compact Inventory"
    restored_add.visible  = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorMock
