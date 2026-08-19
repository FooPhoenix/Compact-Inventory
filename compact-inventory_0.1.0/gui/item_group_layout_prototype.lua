
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    title_bar            = MOD_PREFIX .. "IW_titlebar",
    title                = MOD_PREFIX .. "IW_title",
    dragger              = MOD_PREFIX .. "IW_dragger",
    close_button         = MOD_PREFIX .. "IW_close",
    add_button           = MOD_PREFIX .. "IW_add-button",
    lock_button          = MOD_PREFIX .. "IW_lock-button",
    sort_toolbar_button  = MOD_PREFIX .. "IW_sort-toolbar-button",
    content_flow         = MOD_PREFIX .. "IW_content-flow",
    sort_toolbar         = MOD_PREFIX .. "IW_sort-toolbar",
    inventory_grid       = MOD_PREFIX .. "IW_grid",
    group_frame          = MOD_PREFIX .. "IG_frame",
    group_header         = MOD_PREFIX .. "IG_header",
    group_title          = MOD_PREFIX .. "IG_title",
    group_rename_button  = MOD_PREFIX .. "IG_rename-button",
    group_name_field     = MOD_PREFIX .. "IG_name-field",
    group_confirm_button = MOD_PREFIX .. "IG_confirm-button",
    group_spacer         = MOD_PREFIX .. "IG_spacer",
    group_sort_icon      = MOD_PREFIX .. "IG_sort-icon",
    group_menu_button    = MOD_PREFIX .. "IG_menu-button"
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
        add_button           = GUI_NAME.add_button,
        lock_button          = GUI_NAME.lock_button,
        group_rename_button  = GUI_NAME.group_rename_button,
        group_name_field     = GUI_NAME.group_name_field,
        group_confirm_button = GUI_NAME.group_confirm_button,
        group_menu_button    = GUI_NAME.group_menu_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getGroupHeader(window)
    local content = window:getFrame()[GUI_NAME.content_flow]
    local group   = content and content[GUI_NAME.group_frame]
    local header  = group and group[GUI_NAME.group_header]

    assert(header, "Experimental ItemGroup header must exist here !")      -- [DEBUG-ONLY] . --

    return header
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Refresh the experimental group sorting icon.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--
function factory.refreshSortButton(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local icon = getGroupHeader(window)[GUI_NAME.group_sort_icon]

    assert(icon, "Experimental ItemGroup sort icon must exist here !")      -- [DEBUG-ONLY] . --

    icon.sprite = SORT_SPRITE[window:getDefaultItemGroup():getSortMode()]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Enter ItemGroup name editing mode.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--
function factory.startRename(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local header        = getGroupHeader(window)
    local title         = header[GUI_NAME.group_title]
    local rename_button = header[GUI_NAME.group_rename_button]
    local name_field    = header[GUI_NAME.group_name_field]
    local confirm       = header[GUI_NAME.group_confirm_button]

    assert(title and rename_button and name_field and confirm, "ItemGroup rename GUI must be complete here !")      -- [DEBUG-ONLY] . --

    name_field.text = window:getDefaultItemGroup():getName()

    title.visible         = false
    rename_button.visible = false
    name_field.visible    = true
    confirm.visible       = true

    name_field.focus()
    name_field.select_all()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Confirm the edited ItemGroup name.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--
function factory.confirmRename(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local header        = getGroupHeader(window)
    local title         = header[GUI_NAME.group_title]
    local rename_button = header[GUI_NAME.group_rename_button]
    local name_field    = header[GUI_NAME.group_name_field]
    local confirm       = header[GUI_NAME.group_confirm_button]

    assert(title and rename_button and name_field and confirm, "ItemGroup rename GUI must be complete here !")      -- [DEBUG-ONLY] . --

    local item_group = window:getDefaultItemGroup()

    item_group:setName(name_field.text)
    title.caption = item_group:getName()

    title.visible         = true
    rename_button.visible = true
    name_field.visible    = false
    confirm.visible       = false
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

    local add_button = title_bar.add({
        type    = "sprite-button",
        name    = GUI_NAME.add_button,
        sprite  = "utility/add_white",
        style   = "frame_action_button",
        tooltip = "Add group (not implemented yet)"
    })

    add_button.style.width   = 16
    add_button.style.height  = 16
    add_button.style.padding = 0

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

    title_bar.swap_children(close.get_index_in_parent(), add_button.get_index_in_parent())
    title_bar.swap_children(close.get_index_in_parent(), lock.get_index_in_parent())

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

    local item_group = window:getDefaultItemGroup()

    local group_title = header.add({
        type    = "label",
        name    = GUI_NAME.group_title,
        caption = item_group:getName()
    })

    group_title.style.top_margin    = 0
    group_title.style.bottom_margin = 0

    local rename_button = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_rename_button,
        sprite  = "utility/rename_icon",
        style   = "frame_action_button",
        tooltip = "Rename group"
    })

    rename_button.style.width   = 16
    rename_button.style.height  = 16
    rename_button.style.padding = 0

    local name_field = header.add({
        type                  = "textfield",
        name                  = GUI_NAME.group_name_field,
        text                  = item_group:getName(),
        icon_selector         = true,
        lose_focus_on_confirm = true,
        visible               = false
    })

    name_field.style.width  = 180
    name_field.style.height = 28

    local confirm = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_confirm_button,
        sprite  = "utility/check_mark",
        style   = "frame_action_button",
        tooltip = "Confirm group name",
        visible = false
    })

    confirm.style.width   = 28
    confirm.style.height  = 28
    confirm.style.padding = 0

    local spacer = header.add({
        type = "empty-widget",
        name = GUI_NAME.group_spacer
    })

    spacer.style.horizontally_stretchable = true

    local sort_icon = header.add({
        type    = "sprite",
        name    = GUI_NAME.group_sort_icon,
        sprite  = SORT_SPRITE[item_group:getSortMode()],
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
