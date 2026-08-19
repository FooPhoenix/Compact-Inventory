
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode   = InventoryViewFactory.sort_modes
local FilterMode = InventoryViewFactory.filter_modes

local GUI_NAME = {
    menu                  = MOD_PREFIX .. "IG_options-menu",
    columns_flow          = MOD_PREFIX .. "IG_options-columns-flow",
    group_column          = MOD_PREFIX .. "IG_options-group-column",
    group_title           = MOD_PREFIX .. "IG_options-group-title",
    group_filler          = MOD_PREFIX .. "IG_options-group-filler",
    sort_column_wrapper   = MOD_PREFIX .. "IG_options-sort-wrapper",
    sort_outer_frame      = MOD_PREFIX .. "IG_options-sort-outer-frame",
    sort_inner_frame      = MOD_PREFIX .. "IG_options-sort-inner-frame",
    sort_column           = MOD_PREFIX .. "IG_options-sort-column",
    sort_title            = MOD_PREFIX .. "IG_options-sort-title",
    sort_toggle_button    = MOD_PREFIX .. "IG_options-sort-toggle",
    filter_column_wrapper = MOD_PREFIX .. "IG_options-filter-wrapper",
    filter_outer_frame    = MOD_PREFIX .. "IG_options-filter-outer-frame",
    filter_inner_frame    = MOD_PREFIX .. "IG_options-filter-inner-frame",
    filter_column         = MOD_PREFIX .. "IG_options-filter-column",
    filter_title          = MOD_PREFIX .. "IG_options-filter-title",
    filter_switch         = MOD_PREFIX .. "IG_options-filter-switch",
    filter_table          = MOD_PREFIX .. "IG_options-filter-table",
    filter_toggle_button  = MOD_PREFIX .. "IG_options-filter-toggle",
    delete_group_button   = MOD_PREFIX .. "IG_options-delete-group"
}

local SORT_SPRITE = {
    [SortMode.standard]         = MOD_PREFIX .. "sort-standard",
    [SortMode.count_ascending]  = MOD_PREFIX .. "sort-count-asc",
    [SortMode.count_descending] = MOD_PREFIX .. "sort-count-desc",
    [SortMode.inventory]        = MOD_PREFIX .. "sort-inventory",
    [SortMode.last_change]      = MOD_PREFIX .. "sort-last-change",
    [SortMode.custom]           = MOD_PREFIX .. "sort-custom"
}

local SORT_CAPTION = {
    [SortMode.standard]         = "Standard sorting",
    [SortMode.count_ascending]  = "Sort by quantity ascending",
    [SortMode.count_descending] = "Sort by quantity descending",
    [SortMode.inventory]        = "Inventory order",
    [SortMode.last_change]      = "Sort by last change",
    [SortMode.custom]           = "Custom sorting"
}

local SORT_TAG_NAME        = MOD_PREFIX .. "SortID"
local GROUP_ID_TAG_NAME    = MOD_PREFIX .. "ItemGroupID"
local FILTER_SLOT_TAG_NAME = MOD_PREFIX .. "FilterSlot"
local hover_state          = { }

local factory = {
    exposed_gui_names = {
        menu                 = GUI_NAME.menu,
        sort_toggle_button   = GUI_NAME.sort_toggle_button,
        filter_toggle_button = GUI_NAME.filter_toggle_button,
        filter_switch        = GUI_NAME.filter_switch,
        delete_group_button  = GUI_NAME.delete_group_button,
        sort_tag_name        = SORT_TAG_NAME,
        group_id_tag_name    = GROUP_ID_TAG_NAME,
        filter_slot_tag_name = FILTER_SLOT_TAG_NAME
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function isMenuElement(lua_element)
    while lua_element do
        if lua_element.name == GUI_NAME.menu then
            return true
        end

        lua_element = lua_element.parent
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function recordEvent(player_index, event_name, tick)
    hover_state[player_index] = {
        last_event      = event_name,
        last_event_tick = tick
    }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addColumnTitle(parent, menu, name, caption, with_dragger)
    local title_flow = parent.add({
        type               = "flow",
        direction          = "horizontal",
        raise_hover_events = true
    })

    title_flow.style.horizontal_spacing       = 4
    title_flow.style.horizontally_stretchable = true
    title_flow.style.vertical_align           = "center"

    local title = title_flow.add({
        type               = "label",
        name               = name,
        caption            = caption,
        style              = "frame_title",
        raise_hover_events = true
    })

    title.style.font = "default-bold"
    title.drag_target = menu

    if with_dragger then
        local dragger = title_flow.add({
            type               = "empty-widget",
            style              = "draggable_space",
            raise_hover_events = true
        })

        dragger.style.horizontally_stretchable = true
        dragger.style.height = 16
        dragger.drag_target  = menu
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addGroupAction(parent, name, caption, enabled, group_id)
    local button = parent.add({
        type               = "button",
        name               = name,
        caption            = caption,
        enabled            = enabled,
        raise_hover_events = true,
        tags               = {
            [GROUP_ID_TAG_NAME] = group_id
        }
    })

    button.style.horizontally_stretchable = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addRaisedColumn(parent, wrapper_name, outer_name, inner_name, column_name, visible)
    local wrapper = parent.add({
        type               = "flow",
        name               = wrapper_name,
        direction          = "horizontal",
        visible            = visible,
        raise_hover_events = true
    })

    local outer = wrapper.add({
        type               = "frame",
        name               = outer_name,
        direction          = "vertical",
        style              = "inside_shallow_frame",
        raise_hover_events = true
    })

    outer.style.padding = 2

    local inner = outer.add({
        type               = "frame",
        name               = inner_name,
        direction          = "vertical",
        raise_hover_events = true
    })

    inner.style.padding = 2

    local column = inner.add({
        type               = "flow",
        name               = column_name,
        direction          = "vertical",
        raise_hover_events = true
    })

    column.style.vertical_spacing = 2

    return column
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getFilterTable(menu)
    local columns_flow   = menu[GUI_NAME.columns_flow]
    local filter_wrapper = columns_flow and columns_flow[GUI_NAME.filter_column_wrapper]
    local outer          = filter_wrapper and filter_wrapper[GUI_NAME.filter_outer_frame]
    local inner          = outer and outer[GUI_NAME.filter_inner_frame]
    local column         = inner and inner[GUI_NAME.filter_column]
    local filter_table   = column and column[GUI_NAME.filter_table]

    assert(filter_table, "Filter table must exist here !")      -- [DEBUG-ONLY] . --

    return filter_table
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.refreshFilterTable(window, item_group)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup does not exist or is invalid !")  -- [DEBUG-ONLY] . --

    local lua_player = window:getPlayer()
    local menu       = lua_player.gui.screen[GUI_NAME.menu]

    if not menu then
        return
    end

    local filter_table = getFilterTable(menu)
    local group_id     = item_group:getID()
    local filters      = item_group:getFilters()

    filter_table.clear()

    for slot_index = 1, item_group:getVisibleFilterSlotCount() do
        filter_table.add({
            type               = "choose-elem-button",
            name               = MOD_PREFIX .. "IG_options-filter-slot-" .. slot_index,
            elem_type          = "item",
            elem_value         = filters[slot_index],
            raise_hover_events = true,
            tags               = {
                [GROUP_ID_TAG_NAME]    = group_id,
                [FILTER_SLOT_TAG_NAME] = slot_index
            }
        })
    end

    recordEvent(lua_player.index, "HOVER", game.tick)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Open the group options menu at the cursor location.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--- @param item_group ItemGroup        The affected item group.
--- @param location GuiLocation       The cursor display location.
--
function factory.open(window, item_group, location)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup does not exist or is invalid !")  -- [DEBUG-ONLY] . --
    assert(location and location.x and location.y, "Cursor display location must be valid here !")            -- [DEBUG-ONLY] . --

    local lua_player = window:getPlayer()
    local group_id   = item_group:getID()

    factory.close(lua_player)

    local menu = lua_player.gui.screen.add({
        type               = "frame",
        name               = GUI_NAME.menu,
        direction          = "horizontal",
        raise_hover_events = true,
        tags               = {
            [GROUP_ID_TAG_NAME] = group_id
        }
    })

    menu.location = {
        x = location.x - 4,
        y = location.y - 4
    }

    local columns_flow = menu.add({
        type               = "flow",
        name               = GUI_NAME.columns_flow,
        direction          = "horizontal",
        raise_hover_events = true
    })

    columns_flow.style.horizontal_spacing = 0

    local group_column = columns_flow.add({
        type               = "flow",
        name               = GUI_NAME.group_column,
        direction          = "vertical",
        raise_hover_events = true
    })

    group_column.style.vertical_spacing       = 2
    group_column.style.vertically_stretchable = true

    addColumnTitle(group_column, menu, GUI_NAME.group_title, "Group options", true)
    addGroupAction(group_column, MOD_PREFIX .. "IG_options-rename", "Rename", false, group_id)
    addGroupAction(group_column, MOD_PREFIX .. "IG_options-move-up", "Move up", false, group_id)
    addGroupAction(group_column, MOD_PREFIX .. "IG_options-move-down", "Move down", false, group_id)
    addGroupAction(group_column, GUI_NAME.sort_toggle_button, "Sorting options  >", true, group_id)
    addGroupAction(group_column, GUI_NAME.filter_toggle_button, "Filtering options  >", true, group_id)
    addGroupAction(group_column, GUI_NAME.delete_group_button, "Delete group", true, group_id)

    local filler = group_column.add({
        type               = "empty-widget",
        name               = GUI_NAME.group_filler,
        raise_hover_events = true
    })

    filler.style.vertically_stretchable   = true
    filler.style.horizontally_stretchable = true

    local sort_column = addRaisedColumn(
        columns_flow,
        GUI_NAME.sort_column_wrapper,
        GUI_NAME.sort_outer_frame,
        GUI_NAME.sort_inner_frame,
        GUI_NAME.sort_column,
        false
    )

    addColumnTitle(sort_column, menu, GUI_NAME.sort_title, "Sort options", false)

    for sort_mode = SortMode.standard, SortMode.custom do
        local row = sort_column.add({
            type               = "flow",
            direction          = "horizontal",
            raise_hover_events = true
        })

        row.style.horizontal_spacing = 4

        row.add({
            type               = "sprite",
            sprite             = SORT_SPRITE[sort_mode],
            resize_to_sprite   = false,
            raise_hover_events = true
        }).style.size = 32

        local button = row.add({
            type               = "button",
            caption            = SORT_CAPTION[sort_mode],
            raise_hover_events = true,
            tags               = {
                [SORT_TAG_NAME]     = sort_mode,
                [GROUP_ID_TAG_NAME] = group_id
            }
        })

        button.style.horizontally_stretchable = true
    end

    local filter_column = addRaisedColumn(
        columns_flow,
        GUI_NAME.filter_column_wrapper,
        GUI_NAME.filter_outer_frame,
        GUI_NAME.filter_inner_frame,
        GUI_NAME.filter_column,
        false
    )

    addColumnTitle(filter_column, menu, GUI_NAME.filter_title, "Filter options", false)

    filter_column.add({
        type                = "switch",
        name                = GUI_NAME.filter_switch,
        switch_state        = item_group:getFilterMode() == FilterMode.blacklist and "left" or "right",
        allow_none_state    = false,
        left_label_caption  = "Blacklist",
        right_label_caption = "Whitelist",
        raise_hover_events  = true,
        tags                = {
            [GROUP_ID_TAG_NAME] = group_id
        }
    })

    local filter_table = filter_column.add({
        type         = "table",
        name         = GUI_NAME.filter_table,
        column_count = 10
    })

    filter_table.style.horizontal_spacing = 0
    filter_table.style.vertical_spacing   = 0

    factory.refreshFilterTable(window, item_group)

    recordEvent(lua_player.index, "HOVER", game.tick)
    menu.bring_to_front()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.toggleSortColumn(player)

    local _, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if not menu then
        return
    end

    local columns_flow = menu[GUI_NAME.columns_flow]
    local sort_wrapper = columns_flow and columns_flow[GUI_NAME.sort_column_wrapper]

    assert(sort_wrapper, "Sort options wrapper must exist here !")      -- [DEBUG-ONLY] . --

    sort_wrapper.visible = not sort_wrapper.visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.toggleFilterColumn(player)

    local _, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if not menu then
        return
    end

    local columns_flow   = menu[GUI_NAME.columns_flow]
    local filter_wrapper = columns_flow and columns_flow[GUI_NAME.filter_column_wrapper]

    assert(filter_wrapper, "Filter options wrapper must exist here !")      -- [DEBUG-ONLY] . --

    filter_wrapper.visible = not filter_wrapper.visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.close(player)

    local player_index, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if menu then
        menu.destroy()
    end

    hover_state[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onHover(event)
    if isMenuElement(event.element) then
        recordEvent(event.player_index, "HOVER", event.tick)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onLeave(event)
    if isMenuElement(event.element) then
        recordEvent(event.player_index, "LEAVE", event.tick)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onTick(event)
    for player_index, state in pairs(hover_state) do
        if state.last_event_tick == event.tick - 1 and state.last_event == "LEAVE" then
            local lua_player = game.get_player(player_index)

            if lua_player then
                factory.close(lua_player)
            else
                hover_state[player_index] = nil
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
