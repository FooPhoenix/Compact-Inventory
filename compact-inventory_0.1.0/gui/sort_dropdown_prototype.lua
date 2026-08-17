
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    title_bar           = MOD_PREFIX .. "IW_titlebar",
    sort_toolbar_button = MOD_PREFIX .. "IW_sort-toolbar-button",
    sort_dropdown       = MOD_PREFIX .. "IW_sort-dropdown"
}

local SORT_STYLE = {
    [SortMode.standard]         = MOD_PREFIX .. "sort-dropdown-standard",
    [SortMode.count_ascending]  = MOD_PREFIX .. "sort-dropdown-count-asc",
    [SortMode.count_descending] = MOD_PREFIX .. "sort-dropdown-count-desc",
    [SortMode.inventory]        = MOD_PREFIX .. "sort-dropdown-inventory",
    [SortMode.last_change]      = MOD_PREFIX .. "sort-dropdown-last-change",
    [SortMode.custom]           = MOD_PREFIX .. "sort-dropdown-custom"
}

local SORT_ITEMS = {
    "Standard sorting",
    "Sort by quantity ascending",
    "Sort by quantity descending",
    "Inventory order",
    "Sort by last change",
    "Custom sorting"
}

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SortDropdownPrototype.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = {
    exposed_gui_names = {
        sort_dropdown = GUI_NAME.sort_dropdown
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Attach the experimental native sorting dropdown to an InventoryWindow.
--
--- -----
--- @param window InventoryWindow      The window that receives the prototype dropdown.
--
function factory.attach(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local frame     = window:getFrame()
    local title_bar = frame[GUI_NAME.title_bar]
    local sort_mode = window:getDefaultItemGroup():getSortMode()

    assert(title_bar, "InventoryWindow title bar must exist here !")      -- [DEBUG-ONLY] . --

    title_bar[GUI_NAME.sort_toolbar_button].visible = false
    window:getToolbar().visible = false

    if title_bar[GUI_NAME.sort_dropdown] then
        title_bar[GUI_NAME.sort_dropdown].destroy()
    end

    title_bar.add({
        type           = "drop-down",
        name           = GUI_NAME.sort_dropdown,
        items          = SORT_ITEMS,
        selected_index = sort_mode,
        style          = SORT_STYLE[sort_mode],
        tooltip        = "Sorting"
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Apply a selection made in the experimental sorting dropdown.
--
--- -----
--- @param window InventoryWindow       The affected inventory window.
--- @param lua_element LuaGuiElement    The dropdown that raised the event.
--
function factory.applySelection(window, lua_element)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(lua_element and lua_element.valid and lua_element.object_name == "LuaGuiElement", "Dropdown must be a valid LuaGuiElement !")      -- [DEBUG-ONLY] . --
    assert(lua_element.name == GUI_NAME.sort_dropdown, "Unexpected dropdown element !")      -- [DEBUG-ONLY] . --

    local sort_mode = lua_element.selected_index

    assert(SORT_STYLE[sort_mode], "Unexpected sorting mode !")      -- [DEBUG-ONLY] . --

    window:setSortMode(sort_mode)
    lua_element.style = SORT_STYLE[sort_mode]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
