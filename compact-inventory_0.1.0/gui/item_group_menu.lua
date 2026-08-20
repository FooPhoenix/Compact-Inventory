local ItemOrder            = require("util.item_order")
local InventoryViewFactory = require("inventory.inventory_view")
local HoverTrackerFactory  = require("gui.hover_tracker")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode   = InventoryViewFactory.sort_modes
local FilterMode = InventoryViewFactory.filter_modes

local CUSTOM_SORT_MAX_HEIGHT = 405      -- Approximately 10 item rows.

local GUI_NAME = {
    menu                       = MOD_PREFIX .. "IG_options-menu",
    columns_flow               = MOD_PREFIX .. "IG_options-columns-flow",
    group_column               = MOD_PREFIX .. "IG_options-group-column",
    group_title                = MOD_PREFIX .. "IG_options-group-title",
    group_filler               = MOD_PREFIX .. "IG_options-group-filler",
    move_up_button             = MOD_PREFIX .. "IG_options-move-up",
    move_down_button           = MOD_PREFIX .. "IG_options-move-down",
    sort_column_wrapper        = MOD_PREFIX .. "IG_options-sort-wrapper",
    sort_outer_frame           = MOD_PREFIX .. "IG_options-sort-outer-frame",
    sort_inner_frame           = MOD_PREFIX .. "IG_options-sort-inner-frame",
    sort_column                = MOD_PREFIX .. "IG_options-sort-column",
    sort_title                 = MOD_PREFIX .. "IG_options-sort-title",
    sort_toggle_button         = MOD_PREFIX .. "IG_options-sort-toggle",
    custom_sort_column_wrapper = MOD_PREFIX .. "IG_options-custom-sort-wrapper",
    custom_sort_outer_frame    = MOD_PREFIX .. "IG_options-custom-sort-outer-frame",
    custom_sort_inner_frame    = MOD_PREFIX .. "IG_options-custom-sort-inner-frame",
    custom_sort_column         = MOD_PREFIX .. "IG_options-custom-sort-column",
    custom_sort_title          = MOD_PREFIX .. "IG_options-custom-sort-title",
    custom_sort_scroll         = MOD_PREFIX .. "IG_options-custom-sort-scroll",
    custom_sort_table          = MOD_PREFIX .. "IG_options-custom-sort-table",
    filter_column_wrapper      = MOD_PREFIX .. "IG_options-filter-wrapper",
    filter_outer_frame         = MOD_PREFIX .. "IG_options-filter-outer-frame",
    filter_inner_frame         = MOD_PREFIX .. "IG_options-filter-inner-frame",
    filter_column              = MOD_PREFIX .. "IG_options-filter-column",
    filter_title               = MOD_PREFIX .. "IG_options-filter-title",
    filter_mode_flow           = MOD_PREFIX .. "IG_options-filter-mode-flow",
    filter_blacklist_label     = MOD_PREFIX .. "IG_options-filter-blacklist-label",
    filter_switch              = MOD_PREFIX .. "IG_options-filter-switch",
    filter_whitelist_label     = MOD_PREFIX .. "IG_options-filter-whitelist-label",
    filter_table               = MOD_PREFIX .. "IG_options-filter-table",
    filter_toggle_button       = MOD_PREFIX .. "IG_options-filter-toggle",
    delete_group_button        = MOD_PREFIX .. "IG_options-delete-group"
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
local hover_trackers       = { }

local factory = {
    exposed_gui_names = {
        menu                 = GUI_NAME.menu,
        move_up_button       = GUI_NAME.move_up_button,
        move_down_button     = GUI_NAME.move_down_button,
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

local function isNonAuthoritativeLeaveElement(lua_element)
    return lua_element.name == GUI_NAME.filter_blacklist_label
        or lua_element.name == GUI_NAME.filter_whitelist_label
        or lua_element.name == GUI_NAME.filter_switch
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

local function refreshMoveButtons(menu, item_group, window)
    local group_column = menu[GUI_NAME.columns_flow][GUI_NAME.group_column]
    local move_up      = group_column[GUI_NAME.move_up_button]
    local move_down    = group_column[GUI_NAME.move_down_button]
    local group_index

    for index, group in ipairs(window:getItemGroups()) do
        if group == item_group then
            group_index = index
            break
        end
    end

    assert(group_index, "ItemGroup must exist in InventoryWindow here !")      -- [DEBUG-ONLY] . --
    assert(move_up and move_down, "ItemGroup move buttons must exist here !")  -- [DEBUG-ONLY] . --

    move_up.enabled   = group_index > 1
    move_down.enabled = group_index < #window:getItemGroups()
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

    local filter_table       = getFilterTable(menu)
    local visible_slot_count = item_group:getVisibleFilterSlotCount()

    -- Factorio already updates the choose-elem-button that triggered on_gui_elem_changed.
    -- Rebuild the table only when the number of visible rows actually changed.
    if #filter_table.children == visible_slot_count then
        return
    end

    local group_id = item_group:getID()
    local filters  = item_group:getFilters()

    filter_table.clear()

    for slot_index = 1, visible_slot_count do
        filter_table.add({
            type               = "choose-elem-button",
            name               = MOD_PREFIX .. "IG_options-filter-slot-" .. slot_index,
            elem_type          = "item",
            item               = filters[slot_index],
            raise_hover_events = true,
            tags               = {
                [GROUP_ID_TAG_NAME]    = group_id,
                [FILTER_SLOT_TAG_NAME] = slot_index
            }
        })
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.moveItemGroup(window, item_group, offset)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup does not exist or is invalid !")  -- [DEBUG-ONLY] . --
    assert(offset == -1 or offset == 1, "ItemGroup move offset must be -1 or 1 !")                               -- [DEBUG-ONLY] . --

    local item_groups = window:getItemGroups()
    local group_index

    for index, group in ipairs(item_groups) do
        if group == item_group then
            group_index = index
            break
        end
    end

    assert(group_index, "ItemGroup must exist in InventoryWindow here !")      -- [DEBUG-ONLY] . --

    local target_index = group_index + offset

    if target_index < 1 or target_index > #item_groups then
        return
    end

    item_groups[group_index], item_groups[target_index] = item_groups[target_index], item_groups[group_index]
    window:getGroupsContainer().swap_children(group_index, target_index)
    window:refreshLockGUI()

    local menu = window:getPlayer().gui.screen[GUI_NAME.menu]

    if menu then
        refreshMoveButtons(menu, item_group, window)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Open the group options menu at the cursor location.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--- @param item_group ItemGroup        The affected item group.
--- @param location GuiLocation        The cursor display location.
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
    addGroupAction(group_column, GUI_NAME.move_up_button, "Move up", true, group_id)
    addGroupAction(group_column, GUI_NAME.move_down_button, "Move down", true, group_id)
    addGroupAction(group_column, GUI_NAME.sort_toggle_button, "Sorting options  >", true, group_id)
    addGroupAction(group_column, GUI_NAME.filter_toggle_button, "Filtering options  >", true, group_id)
    addGroupAction(group_column, GUI_NAME.delete_group_button, "Delete group", true, group_id)
    refreshMoveButtons(menu, item_group, window)

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

    local custom_sort_column = addRaisedColumn(
        columns_flow,
        GUI_NAME.custom_sort_column_wrapper,
        GUI_NAME.custom_sort_outer_frame,
        GUI_NAME.custom_sort_inner_frame,
        GUI_NAME.custom_sort_column,
        false
    )

    addColumnTitle(custom_sort_column, menu, GUI_NAME.custom_sort_title, "Custom sort", false)

    local custom_sort_scroll = custom_sort_column.add({
        type               = "scroll-pane",
        name               = GUI_NAME.custom_sort_scroll,
        vertical_scroll_policy = "auto",
        horizontal_scroll_policy = "never",
        raise_hover_events = true
    })

    custom_sort_scroll.style.maximal_height = CUSTOM_SORT_MAX_HEIGHT

    local custom_sort_table = custom_sort_scroll.add({
        type               = "table",
        name               = GUI_NAME.custom_sort_table,
        column_count       = 10,
        raise_hover_events = true
    })

    custom_sort_table.style.horizontal_spacing = 0
    custom_sort_table.style.vertical_spacing   = 0

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
                [GROUP_ID_TAG_NAME] = group_id
            }
        })
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

    local filter_mode_flow = filter_column.add({
        type               = "flow",
        name               = GUI_NAME.filter_mode_flow,
        direction          = "horizontal",
        raise_hover_events = true
    })

    filter_mode_flow.style.horizontal_spacing       = 4
    filter_mode_flow.style.horizontally_stretchable = true
    filter_mode_flow.style.vertical_align           = "center"

    filter_mode_flow.add({
        type               = "label",
        name               = GUI_NAME.filter_blacklist_label,
        caption            = "Blacklist",
        raise_hover_events = true
    })

    filter_mode_flow.add({
        type               = "switch",
        name               = GUI_NAME.filter_switch,
        switch_state       = item_group:getFilterMode() == FilterMode.blacklist and "left" or "right",
        allow_none_state   = false,
        raise_hover_events = true,
        tags               = {
            [GROUP_ID_TAG_NAME] = group_id
        }
    })

    filter_mode_flow.add({
        type               = "label",
        name               = GUI_NAME.filter_whitelist_label,
        caption            = "Whitelist",
        raise_hover_events = true
    })

    local filter_table = filter_column.add({
        type               = "table",
        name               = GUI_NAME.filter_table,
        column_count       = 10,
        raise_hover_events = true
    })

    filter_table.style.horizontal_spacing = 0
    filter_table.style.vertical_spacing   = 0

    factory.refreshFilterTable(window, item_group)

    local tracker = HoverTrackerFactory.new()
    tracker:onHover(game.tick)
    hover_trackers[lua_player.index] = tracker

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

function factory.toggleCustomSortColumn(player)

    local _, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if not menu then
        return
    end

    local columns_flow = menu[GUI_NAME.columns_flow]
    local wrapper      = columns_flow and columns_flow[GUI_NAME.custom_sort_column_wrapper]

    assert(wrapper, "Custom sort options wrapper must exist here !")      -- [DEBUG-ONLY] . --

    wrapper.visible = not wrapper.visible
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

function factory.suspendHoverUntilReenter(player)
    local player_index = resolve_player(player)
    local tracker = hover_trackers[player_index]

    if tracker then
        tracker:suspendUntilReenter()
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.close(player)

    local player_index, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if menu then
        menu.destroy()
    end

    hover_trackers[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onHover(event)
    if not isMenuElement(event.element) then
        return
    end

    local tracker = hover_trackers[event.player_index]

    if tracker then
        tracker:onHover(event.tick)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onLeave(event)
    if not isMenuElement(event.element) or isNonAuthoritativeLeaveElement(event.element) then
        return
    end

    local tracker = hover_trackers[event.player_index]

    if tracker then
        tracker:onLeave(event.tick)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onTick(event)
    for player_index, tracker in pairs(hover_trackers) do
        if tracker:shouldClose(event.tick) then
            local lua_player = game.get_player(player_index)

            if lua_player then
                factory.close(lua_player)
            else
                hover_trackers[player_index] = nil
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
