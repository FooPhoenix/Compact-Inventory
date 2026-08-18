
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    sort_toolbar_button = MOD_PREFIX .. "IW_sort-toolbar-button",
    sort_menu           = MOD_PREFIX .. "IW_sort-menu"
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

local SORT_TAG_NAME = MOD_PREFIX .. "SortID"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SortMenuPrototype.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = {
    exposed_gui_names = {
        sort_menu = GUI_NAME.sort_menu
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Attach the experimental floating sorting menu to an InventoryWindow.
--
--- -----
--- @param window InventoryWindow      The window that receives the prototype menu.
--
function factory.attach(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local sort_button = window:getFrame()[MOD_PREFIX .. "IW_titlebar"][GUI_NAME.sort_toolbar_button]

    assert(sort_button, "InventoryWindow sort button must exist here !")      -- [DEBUG-ONLY] . --

    sort_button.visible = true
    window:getToolbar().visible = false

    factory.close(window:getPlayer())
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Open the experimental sorting menu at the cursor location.
--
--- -----
--- @param window InventoryWindow      The affected inventory window.
--- @param location GuiLocation       The cursor display location.
--
function factory.open(window, location)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(location and location.x and location.y, "Cursor display location must be valid here !")            -- [DEBUG-ONLY] . --

    local lua_player = window:getPlayer()

    factory.close(lua_player)

    local menu = lua_player.gui.screen.add({
        type               = "frame",
        name               = GUI_NAME.sort_menu,
        direction          = "vertical",
        raise_hover_events = true
    })

    menu.location = {
        x = location.x - 4,
        y = location.y - 4
    }

    local entries = menu.add({
        type         = "table",
        column_count = 2
    })

    entries.style.horizontal_spacing = 4
    entries.style.vertical_spacing   = 0

    for sort_mode = SortMode.standard, SortMode.custom do
        entries.add({
            type    = "sprite-button",
            sprite  = SORT_SPRITE[sort_mode],
            style   = "frame_action_button",
            tooltip = SORT_CAPTION[sort_mode],
            tags    = {
                [SORT_TAG_NAME] = sort_mode
            }
        })

        local button = entries.add({
            type    = "button",
            caption = SORT_CAPTION[sort_mode],
            tags    = {
                [SORT_TAG_NAME] = sort_mode
            }
        })

        button.style.horizontally_stretchable = true
    end

    menu.bring_to_front()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Close the experimental sorting menu if it exists.
--
--- -----
--- @param player integer|LuaPlayer      The player that owns the menu.
--
function factory.close(player)

    local _, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.sort_menu]

    if menu then
        menu.destroy()
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
