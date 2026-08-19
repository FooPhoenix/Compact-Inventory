
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    title_bar           = MOD_PREFIX .. "IW_titlebar",
    title               = MOD_PREFIX .. "IW_title",
    dragger             = MOD_PREFIX .. "IW_dragger",
    close_button        = MOD_PREFIX .. "IW_close",
    lock_button         = MOD_PREFIX .. "IW_lock-button",
    sort_toolbar_button = MOD_PREFIX .. "IW_sort-toolbar-button",
    content_flow        = MOD_PREFIX .. "IW_content-flow",
    sort_toolbar        = MOD_PREFIX .. "IW_sort-toolbar",
    inventory_grid      = MOD_PREFIX .. "IW_grid",
    group_frame         = MOD_PREFIX .. "IG_frame",
    group_header        = MOD_PREFIX .. "IG_header",
    group_title         = MOD_PREFIX .. "IG_title",
    group_spacer        = MOD_PREFIX .. "IG_spacer",
    group_sort_icon     = MOD_PREFIX .. "IG_sort-icon",
    group_menu_button   = MOD_PREFIX .. "IG_menu-button"
}

local SORT_SPRITE = {
    [SortMode.standard]         = MOD_PREFIX .. "sort-standard",
    [SortMode.count_ascending]  = MOD_PREFIX .. "sort-count-asc",
    [SortMode.count_descending] = MOD_PREFIX .. "sort-count-desc",
    [SortMode.inventory]        = MOD_PREFIX .. "sort-inventory",
    [SortMode.last_change]      = MOD_PREFIX .. "sort-last-change",
    [SortMode.custom]           = MOD_PREFIX .. "sort-custom"
}

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ ItemGroupLayoutPrototype.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = {
    exposed_gui_names = {
        lock_button       = GUI_NAME.lock_button,
        group_menu_button = GUI_NAME.group_menu_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Refresh the experimental group sorting icon.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--
function factory.refreshSortButton(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local content = window:getFrame()[GUI_NAME.content_flow]
    local group   = content and content[GUI_NAME.group_frame]
    local header  = group and group[GUI_NAME.group_header]
    local icon    = header and header[GUI_NAME.group_sort_icon]

    assert(icon, "Experimental ItemGroup sort icon must exist here !")      -- [DEBUG-ONLY] . --

    icon.sprite = SORT_SPRITE[window:getDefaultItemGroup():getSortMode()]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Apply the experimental compact window and ItemGroup layout.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--
function factory.attach(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local frame     = window:getFrame()
    local title_bar = frame[GUI_NAME.title_bar]
    local title     = title_bar[GUI_NAME.title]
    local dragger   = title_bar[GUI_NAME.dragger]
    local close     = title_bar[GUI_NAME.close_button]
    local old_sort  = title_bar[GUI_NAME.sort_toolbar_button]
    local content   = frame[GUI_NAME.content_flow]

    assert(title_bar and title and dragger and close and old_sort and content, "InventoryWindow GUI must be complete here !")      -- [DEBUG-ONLY] . --

    title.visible    = false
    old_sort.visible = false

    frame.style.left_padding   = 4
    frame.style.right_padding  = 4
    frame.style.top_padding    = 3
    frame.style.bottom_padding = 4

    title_bar.style.horizontal_spacing = 2
    dragger.style.height               = 16

    close.style.width   = 16
    close.style.height  = 16
    close.style.padding = 0

    local lock = title_bar.add({
        type    = "sprite-button",
        name    = GUI_NAME.lock_button,
        sprite  = MOD_PREFIX .. "window-unlock",
        style   = "frame_action_button",
        tooltip = "Lock window (not implemented yet)"
    })

    lock.style.width   = 16
    lock.style.height  = 16
    lock.style.padding = 0

    title_bar.swap_children(lock.get_index_in_parent(), close.get_index_in_parent())

    content.destroy()

    content = frame.add({
        type      = "frame",
        name      = GUI_NAME.content_flow,
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    content.style.padding                  = 2
    content.style.horizontally_stretchable = true

    local group = content.add({
        type      = "frame",
        name      = GUI_NAME.group_frame,
        direction = "vertical"
    })

    group.style.padding                  = 2
    group.style.horizontally_stretchable = true

    local toolbar = group.add({
        type      = "flow",
        name      = GUI_NAME.sort_toolbar,
        direction = "vertical",
        visible   = false
    })

    toolbar.style.vertical_spacing = 0

    local header = group.add({
        type      = "flow",
        name      = GUI_NAME.group_header,
        direction = "horizontal"
    })

    header.style.horizontal_spacing       = 2
    header.style.horizontally_stretchable = true
    header.style.vertical_align           = "center"

    local group_title = header.add({
        type    = "label",
        name    = GUI_NAME.group_title,
        caption = "Inventory"
    })

    group_title.style.top_margin    = 0
    group_title.style.bottom_margin = 0

    local spacer = header.add({
        type = "empty-widget",
        name = GUI_NAME.group_spacer
    })

    spacer.style.horizontally_stretchable = true

    local sort_icon = header.add({
        type    = "sprite",
        name    = GUI_NAME.group_sort_icon,
        sprite  = SORT_SPRITE[window:getDefaultItemGroup():getSortMode()],
        tooltip = "Current sorting"
    })

    sort_icon.style.width  = 22
    sort_icon.style.height = 22

    local menu_button = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_menu_button,
        sprite  = MOD_PREFIX .. "group-menu",
        style   = "frame_action_button",
        tooltip = "Group options"
    })

    menu_button.style.width   = 22
    menu_button.style.height  = 22
    menu_button.style.padding = 0

    local grid = group.add({
        type         = "table",
        name         = GUI_NAME.inventory_grid,
        column_count = 10
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    factory.refreshSortButton(window)
    window:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
