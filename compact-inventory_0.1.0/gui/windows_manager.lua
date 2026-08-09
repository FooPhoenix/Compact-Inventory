
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local MainInventoryWindowFactory = require("gui.main_inventory")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

---
--- @class WindowsManager
---
--- ### This class groups all functions used to create and manage GUI windows.
---
--
local manager = {
    exposed_gui_names = {
        MainInventoryWindow = MainInventoryWindowFactory.exposed_gui_names
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initialize()

    storage.windows = { }
    storage.windows.main_inventory = { }

    for _, player in pairs(game.players) do
        manager.initializePlayer(player)
    end
    
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.initializePlayer(player)

    MainInventoryWindowFactory.create(player)

end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getWindowMainInventory(player)
   
    local player_index, player = resolve_player(player)
    
    assert(storage.windows.main_inventory[player_index], "Player does not have a main inventory window !")                                          -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].valid, "Player does not have a main inventory window !")                                    -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].object_name == "LuaMainInventoryWindow", "Player does not have a main inventory window !")  -- [DEBUG-ONLY] . --
    
    return storage.windows.main_inventory[player_index]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return manager
