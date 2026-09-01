local HoverTrackerFactory = require("gui.hover_tracker")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local GUI_NAME = {
    menu            = MOD_PREFIX .. "WP_menu",
    title_flow      = MOD_PREFIX .. "WP_title-flow",
    title           = MOD_PREFIX .. "WP_title",
    name_field      = MOD_PREFIX .. "WP_name-field",
    source_checkbox = MOD_PREFIX .. "WP_source-checkbox",
    groups_flow     = MOD_PREFIX .. "WP_groups-flow",
    actions_flow    = MOD_PREFIX .. "WP_actions-flow",
    cancel_button   = MOD_PREFIX .. "WP_cancel-button",
    save_button     = MOD_PREFIX .. "WP_save-button"
}

local GROUP_ID_TAG_NAME     = MOD_PREFIX .. "WP_GroupID"
local INVENTORY_ID_TAG_NAME = MOD_PREFIX .. "MenuInventoryID"
local WINDOW_ID_TAG_NAME    = MOD_PREFIX .. "MenuWindowID"
local hover_trackers        = { }

local factory = {
    exposed_gui_names = {
        menu              = GUI_NAME.menu,
        cancel_button     = GUI_NAME.cancel_button,
        save_button       = GUI_NAME.save_button,
        group_id_tag_name = GROUP_ID_TAG_NAME
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

function factory.open(window, location)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(location and location.x and location.y, "Cursor display location must be valid here !")            -- [DEBUG-ONLY] . --

    local lua_player = window:getPlayer()

    factory.close(lua_player)

    local menu = lua_player.gui.screen.add({
        type               = "frame",
        name               = GUI_NAME.menu,
        direction          = "vertical",
        raise_hover_events = true,
        tags               = {
            [INVENTORY_ID_TAG_NAME] = window:getInventory():getID(),
            [WINDOW_ID_TAG_NAME]    = window:getID()
        }
    })

    menu.location = {
        x = location.x - 4,
        y = location.y - 4
    }

    local title_flow = menu.add({
        type               = "flow",
        name               = GUI_NAME.title_flow,
        direction          = "horizontal",
        raise_hover_events = true
    })

    title_flow.style.horizontal_spacing       = 4
    title_flow.style.horizontally_stretchable = true
    title_flow.style.vertical_align           = "center"

    local title = title_flow.add({
        type               = "label",
        name               = GUI_NAME.title,
        caption            = "Save window preset",
        style              = "frame_title",
        raise_hover_events = true
    })

    title.style.font = "default-bold"
    title.drag_target = menu

    local dragger = title_flow.add({
        type               = "empty-widget",
        style              = "draggable_space",
        raise_hover_events = true
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 16
    dragger.drag_target  = menu

    local name_field = menu.add({
        type               = "textfield",
        name               = GUI_NAME.name_field,
        raise_hover_events = true
    })

    name_field.style.width = 240
    name_field.focus()

    local source_checkbox = menu.add({
        type               = "checkbox",
        name               = GUI_NAME.source_checkbox,
        caption            = "Inventory source",
        state              = window:getInventory():getConfiguration() ~= nil,
        enabled            = window:getInventory():getConfiguration() ~= nil,
        raise_hover_events = true
    })

    local groups_flow = menu.add({
        type               = "flow",
        name               = GUI_NAME.groups_flow,
        direction          = "vertical",
        raise_hover_events = true
    })

    groups_flow.style.vertical_spacing = 2

    groups_flow.add({
        type               = "label",
        caption            = "Groups",
        raise_hover_events = true
    }).style.font = "default-bold"

    for _, item_group in ipairs(window:getItemGroups()) do
        groups_flow.add({
            type               = "checkbox",
            caption            = item_group:getName(),
            state              = true,
            raise_hover_events = true,
            tags               = {
                [GROUP_ID_TAG_NAME] = item_group:getID()
            }
        })
    end

    local actions = menu.add({
        type               = "flow",
        name               = GUI_NAME.actions_flow,
        direction          = "horizontal",
        raise_hover_events = true
    })

    actions.style.horizontal_spacing       = 4
    actions.style.horizontally_stretchable = true

    local spacer = actions.add({
        type               = "empty-widget",
        raise_hover_events = true
    })

    spacer.style.horizontally_stretchable = true

    actions.add({
        type               = "button",
        name               = GUI_NAME.cancel_button,
        caption            = "Cancel",
        raise_hover_events = true
    })

    actions.add({
        type               = "button",
        name               = GUI_NAME.save_button,
        caption            = "Save",
        style              = "green_button",
        raise_hover_events = true
    })

    local tracker = HoverTrackerFactory.new()
    tracker:onHover(game.tick)
    hover_trackers[lua_player.index] = tracker

    menu.bring_to_front()

    return menu
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.getSelection(window)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local menu = window:getPlayer().gui.screen[GUI_NAME.menu]

    assert(menu, "Window preset menu must exist here !")      -- [DEBUG-ONLY] . --

    local name_field      = menu[GUI_NAME.name_field]
    local source_checkbox = menu[GUI_NAME.source_checkbox]
    local groups_flow     = menu[GUI_NAME.groups_flow]

    assert(name_field and source_checkbox and groups_flow, "Window preset controls must exist here !")      -- [DEBUG-ONLY] . --

    local selected_groups = { }

    for _, element in ipairs(groups_flow.children) do
        local group_id = element.tags[GROUP_ID_TAG_NAME]

        if group_id and element.state then
            selected_groups[group_id] = true
        end
    end

    return name_field.text, source_checkbox.state, selected_groups
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
    if event.element.name ~= GUI_NAME.menu then
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
