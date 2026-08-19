
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    menu                 = MOD_PREFIX .. "IG_options-menu",
    group_column         = MOD_PREFIX .. "IG_options-group-column",
    group_title          = MOD_PREFIX .. "IG_options-group-title",
    sort_column_wrapper  = MOD_PREFIX .. "IG_options-sort-wrapper",
    sort_separator       = MOD_PREFIX .. "IG_options-sort-separator",
    sort_column          = MOD_PREFIX .. "IG_options-sort-column",
    sort_title           = MOD_PREFIX .. "IG_options-sort-title",
    sort_toggle_button   = MOD_PREFIX .. "IG_options-sort-toggle",
    delete_group_button  = MOD_PREFIX .. "IG_options-delete-group"
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

local hover_state = { }

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SortMenuPrototype.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = {
    exposed_gui_names = {
        menu                = GUI_NAME.menu,
        sort_toggle_button  = GUI_NAME.sort_toggle_button,
        delete_group_button = GUI_NAME.delete_group_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getElementDebugName(lua_element)
    if lua_element.name and lua_element.name ~= "" then
        return lua_element.name
    end

    return "<" .. lua_element.type .. ">"
end

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

local function recordEvent(lua_player, event_name, lua_element, tick)

    local player_index = lua_player.index
    local state = hover_state[player_index] or {
        sequence_tick = tick,
        sequence      = 0
    }

    if state.sequence_tick ~= tick then
        state.sequence_tick = tick
        state.sequence      = 0
    end

    state.sequence        = state.sequence + 1
    state.last_event      = event_name
    state.last_event_tick = tick

    hover_state[player_index] = state

    lua_player.print(
        "[GroupMenu] #" .. state.sequence .. " " .. event_name ..
        " | " .. getElementDebugName(lua_element) ..
        " | tick " .. tick
    )
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addColumnTitle(parent, menu, name, caption)
    local title = parent.add({
        type               = "label",
        name               = name,
        caption            = caption,
        style              = "frame_title",
        raise_hover_events = true
    })

    title.drag_target = menu

    return title
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addGroupAction(parent, name, caption, enabled)
    local button = parent.add({
        type               = "button",
        name               = name,
        caption            = caption,
        enabled            = enabled,
        raise_hover_events = true
    })

    button.style.horizontally_stretchable = true

    return button
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Attach the experimental floating group menu to an InventoryWindow.
--
--- -----
--- @param window InventoryWindow      The window that receives the prototype menu.
--
function factory.attach(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    window:getToolbar().visible = false
    factory.close(window:getPlayer())
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Open the experimental group options menu at the cursor location.
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
        name               = GUI_NAME.menu,
        direction          = "horizontal",
        raise_hover_events = true
    })

    menu.location = {
        x = location.x - 4,
        y = location.y - 4
    }

    local group_column = menu.add({
        type               = "flow",
        name               = GUI_NAME.group_column,
        direction          = "vertical",
        raise_hover_events = true
    })

    group_column.style.vertical_spacing = 2

    addColumnTitle(group_column, menu, GUI_NAME.group_title, "Group options")

    addGroupAction(group_column, MOD_PREFIX .. "IG_options-rename", "Rename", false)
    addGroupAction(group_column, MOD_PREFIX .. "IG_options-move-up", "Move up", false)
    addGroupAction(group_column, MOD_PREFIX .. "IG_options-move-down", "Move down", false)

    addGroupAction(group_column, GUI_NAME.sort_toggle_button, "Sorting options  >", true)
    addGroupAction(group_column, GUI_NAME.delete_group_button, "Delete group", true)

    local sort_wrapper = menu.add({
        type               = "flow",
        name               = GUI_NAME.sort_column_wrapper,
        direction          = "horizontal",
        visible            = false,
        raise_hover_events = true
    })

    sort_wrapper.style.horizontal_spacing = 4

    sort_wrapper.add({
        type               = "line",
        name               = GUI_NAME.sort_separator,
        direction          = "vertical",
        raise_hover_events = true
    })

    local sort_column = sort_wrapper.add({
        type               = "flow",
        name               = GUI_NAME.sort_column,
        direction          = "vertical",
        raise_hover_events = true
    })

    sort_column.style.vertical_spacing = 2

    addColumnTitle(sort_column, menu, GUI_NAME.sort_title, "Sort options")

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
            resize_to_sprite    = false,
            raise_hover_events = true
        }).style.size = 32

        local button = row.add({
            type               = "button",
            caption            = SORT_CAPTION[sort_mode],
            raise_hover_events = true,
            tags               = {
                [SORT_TAG_NAME] = sort_mode
            }
        })

        button.style.horizontally_stretchable = true
    end

    hover_state[lua_player.index] = {
        last_event      = "HOVER",
        last_event_tick = game.tick,
        sequence_tick   = game.tick,
        sequence        = 0
    }

    menu.bring_to_front()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.toggleSortColumn(player)

    local _, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.menu]

    if not menu then
        return
    end

    local sort_wrapper = menu[GUI_NAME.sort_column_wrapper]

    assert(sort_wrapper, "Sort options wrapper must exist here !")      -- [DEBUG-ONLY] . --

    sort_wrapper.visible = not sort_wrapper.visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Close the experimental group menu if it exists.
--
--- -----
--- @param player integer|LuaPlayer      The player that owns the menu.
--
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

    if not isMenuElement(event.element) then
        return
    end

    local lua_player = game.get_player(event.player_index)

    if not lua_player then
        return
    end

    recordEvent(lua_player, "HOVER", event.element, event.tick)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onLeave(event)

    if not isMenuElement(event.element) then
        return
    end

    local lua_player = game.get_player(event.player_index)

    if not lua_player then
        return
    end

    recordEvent(lua_player, "LEAVE", event.element, event.tick)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.onTick(event)
    for player_index, state in pairs(hover_state) do
        if state.last_event_tick == event.tick - 1 and state.last_event == "LEAVE" then
            local lua_player = game.get_player(player_index)

            if lua_player then
                lua_player.print("[GroupMenu] CLOSE | last event was LEAVE | tick " .. event.tick)
                factory.close(lua_player)
            else
                hover_state[player_index] = nil
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
