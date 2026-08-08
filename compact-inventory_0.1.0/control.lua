local GUI = {
    frame = "FooPhoenix.CI.frame",
    titlebar = "FooPhoenix.CI.titlebar",
    title = "FooPhoenix.CI.title",
    dragger = "FooPhoenix.CI.dragger",
    close = "FooPhoenix.CI.close",
    grid = "FooPhoenix.CI.grid"
}

-- [CHANGELOG] 2026.08.08-11:53 Changed UI :: Make internal names more resilient to mod conflicts. --

local GRID_COLUMNS = 10
local SHORTCUT_NAME = "FooPhoenix.CI.main-window-toggle"


local function get_frame(player)
    return player.gui.screen[GUI.frame]
end


local function create_gui(player)
    local old_frame = get_frame(player)

    if old_frame then
        old_frame.destroy()
    end

    local frame = player.gui.screen.add({
        type = "frame",
        name = GUI.frame,
        direction = "vertical"
    })

    local titlebar = frame.add({
        type = "flow",
        name = GUI.titlebar,
        direction = "horizontal"
    })

    titlebar.style.horizontal_spacing = 8
    titlebar.style.horizontally_stretchable = true

    titlebar.add({
        type = "label",
        name = GUI.title,
        caption = "Inventory",
        style = "frame_title"
    })

    local dragger = titlebar.add({
        type = "empty-widget",
        name = GUI.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 24
    dragger.drag_target = frame

    titlebar.add({
        type = "sprite-button",
        name = GUI.close,
        sprite = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style = "frame_action_button",
        tooltip = "Close"
    })

    local grid = frame.add({
        type = "table",
        name = GUI.grid,
        column_count = GRID_COLUMNS
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing = 0

    frame.auto_center = true

    return frame
end


local function refresh_gui(player)
    local frame = get_frame(player)

    if not frame then
        frame = create_gui(player)
    end

    local grid = frame[GUI.grid]
    grid.clear()

    local inventory = player.get_main_inventory()

    if not inventory then
        return
    end

    for _, item in ipairs(inventory.get_contents()) do
        grid.add({
            type = "sprite-button",
            sprite = "item/" .. item.name,
            style = "slot_button",
            number = item.count,
            quality = item.quality,
            elem_tooltip = {
                type = "item-with-quality",
                name = item.name,
                quality = item.quality
            }
        })
    end
end


local function set_gui_visible(player, visible)
    local frame = get_frame(player)

    if not frame then
        frame = create_gui(player)
        refresh_gui(player)
    end

    frame.visible = visible
    player.set_shortcut_toggled(SHORTCUT_NAME, visible)
end


local function initialize_player(player)
    create_gui(player)
    refresh_gui(player)
    set_gui_visible(player, true)
end


script.on_init(function()
    for _, player in pairs(game.players) do
        initialize_player(player)
    end
end)


script.on_configuration_changed(function()
    for _, player in pairs(game.players) do
        initialize_player(player)
    end
end)


script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)

    if player then
        initialize_player(player)
    end
end)


script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.get_player(event.player_index)

    if player then
        refresh_gui(player)
    end
end)


script.on_event(defines.events.on_gui_click, function(event)
    if not event.element.valid or event.element.name ~= GUI.close then
        return
    end

    local player = game.get_player(event.player_index)

    if player then
        set_gui_visible(player, false)
    end
end)


script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= SHORTCUT_NAME then
        return
    end

    local player = game.get_player(event.player_index)

    if not player then
        return
    end

    local frame = get_frame(player)
    set_gui_visible(player, not (frame and frame.visible))
end)
