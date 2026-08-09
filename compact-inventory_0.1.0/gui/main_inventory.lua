
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Constant Declaration.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local GUI_NAME = {
    main_frame     = "FooPhoenix_CI_MIW_frame",
    title_bar      = "FooPhoenix_CI_MIW_titlebar",
    title          = "FooPhoenix_CI_MIW_title",
    dragger        = "FooPhoenix_CI_MIW_dragger",
    close_button   = "FooPhoenix_CI_MIW_close",
    inventory_grid = "FooPhoenix_CI_MIW_grid"
}

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainInventoryWindowMetatable.                                                                                  ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class MainInventoryWindowMetatable
---
--- ### This class groups all functions used to create and manage the main inventory window.
---
--- @field player      LuaPlayer          The player that own the window.
--- @field valid       boolean            Whether the window is valid or not.
--- @field object_name string             The object name of the window.
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "LuaMainInventoryWindow"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.__index = function(self, key)                                         ---@private
    if key == "valid" then
        return metatable.isValid(self)
    end

    return metatable[key]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFrame()

    assert(self.player and self.player.valid and self.player.object_name == "LuaPlayer", "Player must be valid here !")      -- [DEBUG-ONLY] . --
    assert(self.player.gui.screen[GUI_NAME.main_frame], "GUI frame does not exist!")                                        -- [DEBUG-ONLY] . --

    return self.player.gui.screen[GUI_NAME.main_frame]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isValid()                                                    ---@private
    
    local player = self.player
    
    if not player then
        return false
    elseif not player.valid then
        return false
    end
    
    assert(player.object_name == "LuaPlayer", "Player must be a LuaPlayer here !")      -- [DEBUG-ONLY] In any way this should never happen. --

    if not player.gui.screen[GUI_NAME.main_frame] then
        return false
    end
    
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refresh()

    local grid   = self:getFrame()[GUI_NAME.inventory_grid]
    local player = self.player

    assert(player and player.valid and player.object_name == "LuaPlayer", "Player must exist here !")                    -- [DEBUG-ONLY] . --

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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the visibility of the window.
--
--- -----
--- @param visible boolean      The visibility of the window.
--
function metatable:setVisible(visible)
    if visible == true then
        self:refresh()
    end
    self:getFrame().visible = visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the visibility of the window.
--
--- -----
--- @return boolean      @ The visibility of the window.
--
function metatable:isVisible()
    return self:getFrame().visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Toggle the visibility of the window.
--
function metatable:toggleVisibility()
    self:setVisible(not self:isVisible())
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainInventoryWindow.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class MainInventoryWindow: MainInventoryWindowMetatable
---
--- ### This class is a main inventory window instance.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainInventoryWindowFactory.                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class MainInventoryWindowFactory
---
--- ### This class groups all functions used to create and manage the main inventory window.
---
--
local factory = {
    exposed_gui_names = {
        close_button = GUI_NAME.close_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new main inventory window.
--
--- -----
--- @param player LuaPlayer      The player that will own the window.
--
--- @return MainInventoryWindow  @ Returns the created window.
--
function factory.create(player)

    local player_index, player = resolve_player(player)

    ---@diagnostic disable-next-line: missing-fields
    local window = {                                        ---@type MainInventoryWindow
        player = player
    }

    setmetatable(window, metatable)

    factory.createGUI(window)
    
    assert(storage.windows.main_inventory[player.index] == nil, "Main inventory window already exists!")    -- [DEBUG-ONLY] . --
    
    storage.windows.main_inventory[player.index] = window
    
    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(player)

    local player_index, player = resolve_player(player)
    local window = storage.windows.main_inventory[player_index]                 ---@type MainInventoryWindow

    assert(window and window.object_name == "LuaMainInventoryWindow", "Window does not exist or is invalid !")              -- [DEBUG-ONLY] . --
    assert(window.player and window.player.valid and window.player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.player == player, "Player must be the same as the window one !")                                          -- [DEBUG-ONLY] . --

    window:setVisible(false)
    window:getFrame().destroy()
    window.player = nil

    storage.windows.main_inventory[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create the GUI of the main inventory window.
--- [_private_]
--
--- -----
--- @param window MainInventoryWindow       The window that will own the GUI.
--
--- @return LuaGuiElement                   @ Returns the created GUI frame.
--
function factory.createGUI(window)          ---@private

    assert(window and window.object_name == "LuaMainInventoryWindow", "Window does not exist or is invalid !")                  -- [DEBUG-ONLY] . --
    assert(window.player and window.player.valid and window.player.object_name == "LuaPlayer", "Player must exist here !")      -- [DEBUG-ONLY] . --
    assert(window.player.gui.screen[GUI_NAME.main_frame] == nil, "GUI frame already exists!")                                   -- [DEBUG-ONLY] . --

    local frame = window.player.gui.screen.add({
        type      = "frame",
        name      = GUI_NAME.main_frame,
        direction = "vertical"
    })

    local title_bar = frame.add({
        type      = "flow",
        name      = GUI_NAME.title_bar,
        direction = "horizontal"
    })

    title_bar.style.horizontal_spacing       = 8
    title_bar.style.horizontally_stretchable = true

    title_bar.add({
        type    = "label",
        name    = GUI_NAME.title,
        caption = "Inventory",
        style   = "frame_title"
    })

    local dragger = title_bar.add({
        type  = "empty-widget",
        name  = GUI_NAME.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 24
    dragger.drag_target  = frame

    title_bar.add({
        type           = "sprite-button",
        name           = GUI_NAME.close_button,
        sprite         = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style          = "frame_action_button",
        tooltip        = "Close"
    })

    local grid = frame.add({
        type         = "table",
        name         = GUI_NAME.inventory_grid,
        column_count = 10
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    frame.auto_center = true

    window:setVisible(true)

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
