
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

---
--- @class MainInventoryWindowManager
---
--- ### This class groups all functions used to create and manage the main inventory window.
---
--- @field player LuaPlayer      The player that own the window.
--
local manager = {
    GUI_ELEMENTS = { }    ---@type table<string, string>
}

---
--- @class MainInventoryWindow: MainInventoryWindowManager
---
--- ### This class is the main inventory window.
---

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local GUI_NAME = {
    frame    = "FooPhoenix_CI_MIW_frame",
    titlebar = "FooPhoenix_CI_MIW_titlebar",
    title    = "FooPhoenix_CI_MIW_title",
    dragger  = "FooPhoenix_CI_MIW_dragger",
    close    = "FooPhoenix_CI_MIW_close",
    grid     = "FooPhoenix_CI_MIW_grid"
}

-- CONSTANT for the inventory width.
local GRID_COLUMNS = 10                                     ---@type integer

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

manager.__index = manager                            ---@private

manager.GUI_ELEMENTS.close_button = GUI_NAME.close

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new main inventory window.
--
--- -----
--- @param player LuaPlayer      The player that will own the window.
--
--- @return MainInventoryWindow  @ Returns the created window.
--- @nodiscard
--
function manager:create(player)

    assert(player and player.valid, "Player must exist here!")    -- [DEBUG-ONLY] . --

    local window = {                                        ---@type MainInventoryWindow
        player = player
    }

    setmetatable(window, self)

    window:createGUI()
    window:setVisible(true)

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager:destroy()
   
    local player = self.player

    assert(player and player.valid, "Player must exist here!")                          -- [DEBUG-ONLY] . --
    
    local frame = self:getFrame()
    
    frame.destroy()
    self.player = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create the GUI of the main inventory window.
--- [_private_]
--
--- -----
--- @return LuaGuiElement        @ Returns the created GUI frame.
--
function manager:createGUI()          ---@private

    local player = self.player

    assert(player and player.valid, "Player must exist here!")                          -- [DEBUG-ONLY] . --
    assert(player.gui.screen[GUI_NAME.frame] == nil, "GUI frame already exists!")       -- [DEBUG-ONLY] . --

    local frame = player.gui.screen.add({
        type      = "frame",
        name      = GUI_NAME.frame,
        direction = "vertical"
    })

    local titlebar = frame.add({
        type      = "flow",
        name      = GUI_NAME.titlebar,
        direction = "horizontal"
    })

    titlebar.style.horizontal_spacing       = 8
    titlebar.style.horizontally_stretchable = true

    titlebar.add({
        type    = "label",
        name    = GUI_NAME.title,
        caption = "Inventory",
        style   = "frame_title"
    })

    local dragger = titlebar.add({
        type  = "empty-widget",
        name  = GUI_NAME.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 24
    dragger.drag_target  = frame

    titlebar.add({
        type           = "sprite-button",
        name           = GUI_NAME.close,
        sprite         = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style          = "frame_action_button",
        tooltip        = "Close"
    })

    local grid = frame.add({
        type         = "table",
        name         = GUI_NAME.grid,
        column_count = GRID_COLUMNS
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    frame.auto_center = true

    self:refresh()

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager:getFrame()           ---@private

    local player = self.player

    assert(player and player.valid, "Player must exist here!")                          -- [DEBUG-ONLY] . --
    assert(player.gui.screen[GUI_NAME.frame], "GUI frame does not exist!")              -- [DEBUG-ONLY] . --

    return player.gui.screen[GUI_NAME.frame]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function manager:refresh()

    local player = self.player

    assert(player and player.valid, "Player must exist here!")                          -- [DEBUG-ONLY] . --

    local grid      = self:getFrame()[GUI_NAME.grid]
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
function manager:setVisible(visible)

    local player = self.player

    assert(player and player.valid, "Player must exist here!")                          -- [DEBUG-ONLY] . --

    local frame = self:getFrame()

    frame.visible = visible
end


return manager
