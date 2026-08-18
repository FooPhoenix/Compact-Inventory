
local InventoryViewFactory = require("inventory.inventory_view")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    sort_toolbar_button = MOD_PREFIX .. "IW_sort-toolbar-button",
    sort_menu           = MOD_PREFIX .. "IW_sort-menu",
    sort_menu_entries   = MOD_PREFIX .. "IW_sort-menu-entries"
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
        sort_menu = GUI_NAME.sort_menu
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
        if lua_element.name == GUI_NAME.sort_menu then
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
        "[SortMenu] #" .. state.sequence .. " " .. event_name ..
        " | " .. getElementDebugName(lua_element) ..
        " | tick " .. tick
    )
end

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
        type               = "table",
        name               = GUI_NAME.sort_menu_entries,
        column_count       = 2,
        raise_hover_events = true
    })

    entries.style.horizontal_spacing = 4
    entries.style.vertical_spacing   = 0

    for sort_mode = SortMode.standard, SortMode.custom do
        entries.add({
            type               = "sprite-button",
            name               = MOD_PREFIX .. "IW_sort-menu-icon-" .. sort_mode,
            sprite             = SORT_SPRITE[sort_mode],
            style              = "frame_action_button",
            tooltip            = SORT_CAPTION[sort_mode],
            raise_hover_events = true,
            tags               = {
                [SORT_TAG_NAME] = sort_mode
            }
        })

        local button = entries.add({
            type               = "button",
            name               = MOD_PREFIX .. "IW_sort-menu-button-" .. sort_mode,
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

--- ### Close the experimental sorting menu if it exists.
--
--- -----
--- @param player integer|LuaPlayer      The player that owns the menu.
--
function factory.close(player)

    local player_index, lua_player = resolve_player(player)
    local menu = lua_player.gui.screen[GUI_NAME.sort_menu]

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
                lua_player.print("[SortMenu] CLOSE | last event was LEAVE | tick " .. event.tick)
                factory.close(lua_player)
            else
                hover_state[player_index] = nil
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
