
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local InventoryWindowFactory = require("gui.inventory_window")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

---
--- @class WindowsManager
---
--- ### This class groups all functions used to create and manage GUI windows.
---
--
local manager = {
    exposed_gui_names = {
        InventoryWindow = InventoryWindowFactory.exposed_gui_names
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

    InventoryWindowFactory.create(player)

end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager.getWindowMainInventory(player)

    local player_index, player = resolve_player(player)

    assert(storage.windows.main_inventory[player_index], "Player does not have a main inventory window !")                                 -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].valid, "Player does not have a main inventory window !")                           -- [DEBUG-ONLY] . --
    assert(storage.windows.main_inventory[player_index].object_name == "InventoryWindow", "Player does not have a valid inventory window !")  -- [DEBUG-ONLY] . --

    return storage.windows.main_inventory[player_index]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return manager
