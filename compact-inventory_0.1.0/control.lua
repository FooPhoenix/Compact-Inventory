local GUI = {
    frame = "compact_inventory_frame",
    titlebar = "compact_inventory_titlebar",
    title = "compact_inventory_title",
    dragger = "compact_inventory_dragger",
    grid = "compact_inventory_grid"
}

local GRID_COLUMNS = 10


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


local function initialize_player(player)
    create_gui(player)
    refresh_gui(player)
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
    initialize_player(game.get_player(event.player_index))
end)


script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.get_player(event.player_index)

    if player then
        refresh_gui(player)
    end
end)
