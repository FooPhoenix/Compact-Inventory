
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    menu                = MOD_PREFIX .. "IG_options-menu",
    columns_flow        = MOD_PREFIX .. "IG_options-columns-flow",
    group_column        = MOD_PREFIX .. "IG_options-group-column",
    group_title         = MOD_PREFIX .. "IG_options-group-title",
    group_filler        = MOD_PREFIX .. "IG_options-group-filler",
    sort_column_wrapper = MOD_PREFIX .. "IG_options-sort-wrapper",
    sort_outer_frame    = MOD_PREFIX .. "IG_options-sort-outer-frame",
    sort_inner_frame    = MOD_PREFIX .. "IG_options-sort-inner-frame",
    sort_column         = MOD_PREFIX .. "IG_options-sort-column",
    sort_title          = MOD_PREFIX .. "IG_options-sort-title",
    sort_toggle_button  = MOD_PREFIX .. "IG_options-sort-toggle",
    delete_group_button = MOD_PREFIX .. "IG_options-delete-group"
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

local SORT_TAG_NAME     = MOD_PREFIX .. "SortID"
local GROUP_ID_TAG_NAME = MOD_PREFIX .. "ItemGroupID"
local hover_state       = { }

local factory = {
    exposed_gui_names = {
        menu                = GUI_NAME.menu,
        sort_toggle_button  = GUI_NAME.sort_toggle_button,
        delete_group_button = GUI_NAME.delete_group_button,
        sort_tag_name       = SORT_TAG_NAME,
        group_id_tag_name   = GROUP_ID_TAG_NAME
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
    addGroupAction(group_column, GUI_NAME.delete_group_button, "Delete group", true, group_id)

    local filler = group_column.add({
        type               = "empty-widget",
        name               = GUI_NAME.group_filler,
        raise_hover_events = true
    })

    filler.style.vertically_stretchable   = true
    filler.style.horizontally_stretchable = true

    local sort_wrapper = columns_flow.add({
        type               = "flow",
        name               = GUI_NAME.sort_column_wrapper,
        direction          = "horizontal",
        visible            = false,
        raise_hover_events = true
    })

    local sort_outer = sort_wrapper.add({
        type               = "frame",
        name               = GUI_NAME.sort_outer_frame,
        direction          = "vertical",
        style              = "inside_shallow_frame",
        raise_hover_events = true
    })

    sort_outer.style.padding = 2

    local sort_inner = sort_outer.add({
        type               = "frame",
        name               = GUI_NAME.sort_inner_frame,
        direction          = "vertical",
        raise_hover_events = true
    })

    sort_inner.style.padding = 2

    local sort_column = sort_inner.add({
        type               = "flow",
        name               = GUI_NAME.sort_column,
        direction          = "vertical",
        raise_hover_events = true
    })

    sort_column.style.vertical_spacing = 2
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
