local GUI = {
    frame    = "FooPhoenix_CI_frame",
    titlebar = "FooPhoenix_CI_titlebar",
    title    = "FooPhoenix_CI_title",
    dragger  = "FooPhoenix_CI_dragger",
    close    = "FooPhoenix_CI_close",
    grid     = "FooPhoenix_CI_grid"
}

-- [CHANGELOG] 2026.08.08-11:53 Changed UI :: Make internal names more resilient to mod conflicts. --

-- [CHANGELOG] 2026.08.08-21:20 Fixed UI :: Fixed invalid names because of forbidden dots in names. --

local GRID_COLUMNS  = 10
local SHORTCUT_NAME = "FooPhoenix_CI_main-window-toggle"

local function create_gui(player)
    
    assert(player.gui.screen[GUI.frame] == nil, "GUI frame already exists!")    -- [DEBUG-ONLY] . --
    
    local frame = player.gui.screen.add({
        type      = "frame",
        name      = GUI.frame,
        direction = "vertical"
    })

    local titlebar = frame.add({
        type      = "flow",
        name      = GUI.titlebar,
        direction = "horizontal"
    })

    titlebar.style.horizontal_spacing       = 8
    titlebar.style.horizontally_stretchable = true

    titlebar.add({
        type    = "label",
        name    = GUI.title,
        caption = "Inventory",
        style   = "frame_title"
    })

    local dragger = titlebar.add({
        type  = "empty-widget",
        name  = GUI.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 24
    dragger.drag_target  = frame

    titlebar.add({
        type           = "sprite-button",
        name           = GUI.close,
        sprite         = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style          = "frame_action_button",
        tooltip        = "Close"
    })

    local grid = frame.add({
        type         = "table",
        name         = GUI.grid,
        column_count = GRID_COLUMNS
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    frame.auto_center = true

    return frame
end

-- [CHANGELOG] 2026.08.08-19:39 Changed UI :: Ensured the get_frame function always returns a valid instance to avoid later checks. --

local function get_frame(player)
    
    local frame = player.gui.screen[GUI.frame]
    
    if not frame then
        frame = create_gui(player)
    end
    
    return frame
end

local function refresh_gui(player)

    local frame     = get_frame(player)
    local grid      = frame[GUI.grid]
    local inventory = player.get_main_inventory()

    grid.clear()

    if not inventory then
        return
    end

    for _, item in ipairs(inventory.get_contents()) do
        grid.add({
            type         = "sprite-button",
            sprite       = "item/" .. item.name,
            style        = "slot_button",
            number       = item.count,
            quality      = item.quality,
            elem_tooltip = {
                type    = "item-with-quality",
                name    = item.name,
                quality = item.quality
            }
        })
    end
end


local function set_gui_visible(player, visible)
    
    local frame = get_frame(player)

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
    
    local frame
    for _, player in pairs(game.players) do
        frame = player.gui.screen[GUI.frame]
        
        if frame then
            frame.destroy()
        end
        
        initialize_player(player)
    end
end)


script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)

    assert(player)    -- [DEBUG-ONLY] . --
        
    initialize_player(player)
end)


script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.get_player(event.player_index)

    assert(player)    -- [DEBUG-ONLY] . --

    refresh_gui(player)
end)


script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name ~= GUI.close then
        return
    end

    local player = game.get_player(event.player_index)

    assert(player, "Player must exist here!")    -- [DEBUG-ONLY] . --
    
    set_gui_visible(player, false)
end)


script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name ~= SHORTCUT_NAME then
        return
    end

    local player = game.get_player(event.player_index)

    assert(player, "Player must exist here!")    -- [DEBUG-ONLY] . --

    local frame = get_frame(player)
    set_gui_visible(player, not frame.visible)
end)
