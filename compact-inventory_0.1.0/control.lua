
local MainInventoryWindowManager = require("gui.main_inventory")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local SHORTCUT_NAME = "FooPhoenix_CI_main-window-toggle"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function initialize_player(player)

    assert(player, "Player must exist here!")    -- [DEBUG-ONLY] . --

    local window = MainInventoryWindowManager:create(player)

    storage.windows[player.index] = window
    window.player.set_shortcut_toggled(SHORTCUT_NAME, true)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_init(function()
    
    storage.windows = { }    ---@type table<integer, MainInventoryWindow>
    for _, player in pairs(game.players) do
        initialize_player(player)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_configuration_changed(function()
    
    -- [DEBUG-ONLY] Used only to reinit the mod for the moment. --
    
    local frame
    
    local windows = storage.windows or { }
    
    -- Remove everything.
    for index, window in pairs(windows) do
        window:destroy()
        windows[index] = nil
    end
    
    storage.windows = { }    ---@type table<integer, MainInventoryWindow>
    for _, player in pairs(game.players) do
        initialize_player(player)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)

    initialize_player(player)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_player_main_inventory_changed, function(event)

    local window = storage.windows[event.player_index]

    assert(window)    -- [DEBUG-ONLY] . --
    
    window:refresh()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == MainInventoryWindowManager.GUI_ELEMENTS.close_button then

        local window = storage.windows[event.player_index]

        assert(window)    -- [DEBUG-ONLY] . --

        window:setVisible(false)
        window.player.set_shortcut_toggled(SHORTCUT_NAME, false)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == SHORTCUT_NAME then

        local window = storage.windows[event.player_index]

        assert(window)    -- [DEBUG-ONLY] . --
        
        local visible = not window.player.is_shortcut_toggled(SHORTCUT_NAME)
        window:setVisible(visible)
        window.player.set_shortcut_toggled(SHORTCUT_NAME, visible)
    end
end)
