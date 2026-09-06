-- [TEMPORARY] Visual-only source editor renderer used while the new MainWindow UI is being prototyped. --

local SourceEditorMock = { }

local SOURCE_TABLE_NAME          = MOD_PREFIX .. "MW_source-table"
local SOURCE_TABS_NAME           = MOD_PREFIX .. "MW_creation-tabs"
local SOURCE_SELECTOR_PANEL_NAME = MOD_PREFIX .. "MW_source-selector-panel"
local SOURCE_SLOT_BUTTON_NAME    = MOD_PREFIX .. "MW_source-slot-button"
local SELECTOR_CANCEL_BUTTON     = MOD_PREFIX .. "MW_source-selector-cancel"
local SELECTOR_ADD_BUTTON        = MOD_PREFIX .. "MW_source-selector-add"
local CREATE_BUTTON_NAME         = MOD_PREFIX .. "MW_creation-create"
local SLOT_COLUMNS               = 10

SourceEditorMock.exposed_gui_names = {
    slot_button            = SOURCE_SLOT_BUTTON_NAME,
    selector_cancel_button = SELECTOR_CANCEL_BUTTON,
    selector_add_button    = SELECTOR_ADD_BUTTON
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

    return cell.add(definition)
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

local function renderSelectorActions(main_window)
    local selector_panel = findGuiElement(main_window:getFrame(), SOURCE_SELECTOR_PANEL_NAME)

    assert(selector_panel, "Source selector panel must exist here !")      -- [DEBUG-ONLY] . --

    local old_actions = findGuiElement(selector_panel, MOD_PREFIX .. "MW_source-selector-actions")

    if old_actions then
        old_actions.destroy()
    end

    local actions = selector_panel.add({
        type      = "flow",
        name      = MOD_PREFIX .. "MW_source-selector-actions",
        direction = "horizontal"
    })

    actions.style.horizontally_stretchable = true
    actions.style.horizontal_spacing       = 4

    local spacer = actions.add({ type = "empty-widget" })
    spacer.style.horizontally_stretchable = true

    actions.add({
        type    = "button",
        name    = SELECTOR_CANCEL_BUTTON,
        caption = "Cancel"
    })

    actions.add({
        type    = "button",
        name    = SELECTOR_ADD_BUTTON,
        caption = "Add",
        style   = "green_button"
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showEditor(main_window)
    local tabs = findGuiElement(main_window:getFrame(), SOURCE_TABS_NAME)

    assert(tabs, "Source editor tabs must exist here !")      -- [DEBUG-ONLY] . --
    tabs.selected_tab_index = 1
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.showSelector(main_window)
    local tabs = findGuiElement(main_window:getFrame(), SOURCE_TABS_NAME)

    assert(tabs, "Source editor tabs must exist here !")      -- [DEBUG-ONLY] . --
    tabs.selected_tab_index = 2
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorMock.render(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --

    local source_table  = findGuiElement(main_window:getFrame(), SOURCE_TABLE_NAME)
    local create_button = findGuiElement(main_window:getFrame(), CREATE_BUTTON_NAME)

    assert(source_table and create_button, "Source editor controls must exist here !")      -- [DEBUG-ONLY] . --

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

    renderSelectorActions(main_window)
    SourceEditorMock.showEditor(main_window)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorMock
