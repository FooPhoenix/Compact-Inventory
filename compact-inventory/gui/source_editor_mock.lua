-- [TEMPORARY] Visual-only source editor renderer used while the new MainWindow UI is being prototyped. --

local SourceEditorMock = { }

local SOURCE_TABLE_NAME = MOD_PREFIX .. "MW_source-table"
local SLOT_COLUMNS       = 10

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

function SourceEditorMock.render(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --

    local source_table = findGuiElement(main_window:getFrame(), SOURCE_TABLE_NAME)

    assert(source_table, "Source editor table must exist here !")      -- [DEBUG-ONLY] . --

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
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorMock
