
local ItemOrder       = require("util.item_order")
local LastChangeOrder = require("util.last_change_order")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Constant Declaration.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local GUI_NAME = {
    main_frame              = "FooPhoenix_CI_MIW_frame",
    title_bar               = "FooPhoenix_CI_MIW_titlebar",
    title                   = "FooPhoenix_CI_MIW_title",
    dragger                 = "FooPhoenix_CI_MIW_dragger",
    close_button            = "FooPhoenix_CI_MIW_close",
    sort_toolbar_button     = "FooPhoenix_CI_MIW_sort-toolbar-button",
    content_flow            = "FooPhoenix_CI_MIW_content-flow",
    sort_toolbar            = "FooPhoenix_CI_MIW_sort-toolbar",
    sort_standard_button    = "FooPhoenix_CI_MIW_sort-standard",
    sort_count_asc_button   = "FooPhoenix_CI_MIW_sort-count-asc",
    sort_count_desc_button  = "FooPhoenix_CI_MIW_sort-count-desc",
    sort_inventory_button   = "FooPhoenix_CI_MIW_sort-inventory",
    sort_last_change_button = "FooPhoenix_CI_MIW_sort-last-change",
    sort_custom_button      = "FooPhoenix_CI_MIW_sort-custom",
    inventory_grid          = "FooPhoenix_CI_MIW_grid",
    shortcut_button         = "FooPhoenix_CI_main-window-toggle"
}

---@enum SortMode
local SortMode = {
    standard         = 1,
    count_ascending  = 2,
    count_descending = 3,
    inventory        = 4,
    last_change      = 5,
    custom           = 6
}

local SORT_SPRITE = {
    [SortMode.standard]         = "FooPhoenix_CI_sort-standard",
    [SortMode.count_ascending]  = "FooPhoenix_CI_sort-count-asc",
    [SortMode.count_descending] = "FooPhoenix_CI_sort-count-desc",
    [SortMode.inventory]        = "FooPhoenix_CI_sort-inventory",
    [SortMode.last_change]      = "FooPhoenix_CI_sort-last-change",
    [SortMode.custom]           = "FooPhoenix_CI_sort-custom"
}

local SORT_TAG_NAME = "FooPhoenix_CI_SortID"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryWindowMetatable.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryWindowMetatable
---
--- ### This class groups all functions used to create and manage an inventory window.
---
--- @field private player      LuaPlayer          The player that own the window.
--- @field private sort_mode   SortMode           The current sorting mode.
--- @field         valid       boolean            Whether the window is valid or not.
--- @field         object_name string             The object name of the window.
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "InventoryWindow"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "InventoryWindowMetatable", metatable)
metatable.__index = function(self, key)                                         ---@private
    if key == "valid" then
        return metatable.isValid(self)
    end

    return metatable[key]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Refresh the buttons state matching the current sorting mode.
--
--- -----
--- @param window InventoryWindow      The window to refresh.
--
local function metatable_refreshSortButton(window)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                  -- [DEBUG-ONLY] . --
    assert(type(window.sort_mode) == "number" and window.sort_mode >= 1 and window.sort_mode <= 6, "Sort mode must be a number between 1 and 6 !")   -- [DEBUG-ONLY] . --

    local sort_mode = window.sort_mode
    local toolbar   = window:getToolbar()

    window:getFrame()[GUI_NAME.title_bar][GUI_NAME.sort_toolbar_button].sprite = SORT_SPRITE[sort_mode]

    for _, button in pairs(toolbar.children) do
        button.toggled = ( button.tags[SORT_TAG_NAME] == sort_mode )  -- Just added useless parenthesis, but it is for the sake of readability.
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Sort an item list according to the current sorting mode.
--
--- -----
--- @param window InventoryWindow      The window that owns the sorting mode.
--- @param inventory LuaInventory     The inventory used to determine physical slot order.
--- @param items table                The item list in Factorio standard order.
--
--- @return table                     @ The item list to display.
--
local function metatable_sortItems(window, inventory, items)

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                  -- [DEBUG-ONLY] . --
    assert(type(window.sort_mode) == "number" and window.sort_mode >= 1 and window.sort_mode <= 6, "Sort mode must be a number between 1 and 6 !")   -- [DEBUG-ONLY] . --

    if window.sort_mode == SortMode.standard then
        return items
    end

    if window.sort_mode == SortMode.inventory then

        local items_by_order = { }
        local sorted_items   = { }

        for _, item in ipairs(items) do
            items_by_order[ItemOrder.get(item.name, item.quality)] = item
        end

        for slot_index = 1, #inventory do
            local stack = inventory[slot_index]

            if stack.valid_for_read then
                local order = ItemOrder.get(stack.name, stack.quality.name)
                local item  = items_by_order[order]

                if item then
                    sorted_items[#sorted_items + 1] = item
                    items_by_order[order] = nil
                end
            end
        end

        assert(#sorted_items == #items, "Inventory sorting did not resolve every item !")      -- [DEBUG-ONLY] . --

        return sorted_items
    end

    if window.sort_mode == SortMode.last_change then
        return LastChangeOrder.sort(window:getPlayer(), items)
    end

    if window.sort_mode ~= SortMode.count_ascending and window.sort_mode ~= SortMode.count_descending then
        return items
    end

    local sorted_items = { }

    for index, item in ipairs(items) do
        sorted_items[index] = item
    end

    table.sort(sorted_items, function(item_a, item_b)

        if item_a.count ~= item_b.count then
            if window.sort_mode == SortMode.count_ascending then
                return item_a.count < item_b.count
            else
                return item_a.count > item_b.count
            end
        end

        local order_a = ItemOrder.get(item_a.name, item_a.quality)
        local order_b = ItemOrder.get(item_b.name, item_b.quality)

        return order_a < order_b
    end)

    return sorted_items
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getPlayer()

    assert(self.player and self.player.valid and self.player.object_name == "LuaPlayer", "Player must be valid here !")      -- [DEBUG-ONLY] . --

    return self.player
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFrame()

    local player = self:getPlayer()

    assert(player.gui.screen[GUI_NAME.main_frame], "GUI frame does not exist!")                                        -- [DEBUG-ONLY] . --

    return player.gui.screen[GUI_NAME.main_frame]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getToolbar()

    assert(self:getFrame()[GUI_NAME.content_flow] and self:getFrame()[GUI_NAME.content_flow][GUI_NAME.sort_toolbar], "GUI toolbar does not exist!")                                        -- [DEBUG-ONLY] . --

    return self:getFrame()[GUI_NAME.content_flow][GUI_NAME.sort_toolbar]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isValid()                                                    ---@private

    local player = self.player      -- Do not use getPlayer() here because of internal assert !

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

    local content = self:getFrame()[GUI_NAME.content_flow]
    local grid    = content[GUI_NAME.inventory_grid]
    local player  = self:getPlayer()

    local inventory = player.get_main_inventory()

    grid.clear()

    if not inventory then
        return
    end

    local reference_items = inventory.get_contents()
    local display_items   = metatable_sortItems(self, inventory, reference_items)

    for _, item in ipairs(display_items) do
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

--- ### Set the sorting mode.
--
--- -----
--- @param sort_mode SortMode      The sorting mode to activate.
--
function metatable:setSortMode(sort_mode)
    self.sort_mode = sort_mode
    metatable_refreshSortButton(self)
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the visibility of the sorting toolbar.
--
--- -----
--- @param visible boolean      The visibility of the toolbar.
--
function metatable:setToolbarVisibility(visible)

    local frame   = self:getFrame()
    local toolbar = self:getToolbar()

    toolbar.visible = visible
    frame[GUI_NAME.title_bar][GUI_NAME.sort_toolbar_button].toggled = visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the visibility of the sorting toolbar.
--
--- -----
--- @return boolean      @ The visibility of the toolbar.
--
function metatable:isToolbarVisible()
    return self:getToolbar().visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Toggle the visibility of the sorting toolbar.
--
function metatable:toggleToolbarVisibility()
    self:setToolbarVisibility(not self:isToolbarVisible())
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
    self:getPlayer().set_shortcut_toggled(GUI_NAME.shortcut_button, visible)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the visibility of the window.
--
--- -----
--- @return boolean      @ The visibility of the window.
--
function metatable:isVisible()
    return self:getFrame().visible  -- The truth come from the frame, not the shortcut.
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Toggle the visibility of the window.
--
function metatable:toggleVisibility()
    self:setVisible(not self:isVisible())
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryWindow.                                                                                               ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryWindow: InventoryWindowMetatable
---
--- ### This class is an inventory window instance.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryWindowFactory.                                                                                        ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryWindowFactory
---
--- ### This class groups all functions used to create and manage an inventory window.
---
--
local factory = {
    exposed_gui_names = {
        close_button        = GUI_NAME.close_button,
        sort_toolbar_button = GUI_NAME.sort_toolbar_button,
        shortcut_button     = GUI_NAME.shortcut_button,
        sort_tag_name       = SORT_TAG_NAME
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new inventory window.
--
--- -----
--- @param player LuaPlayer      The player that will own the window.
--
--- @return InventoryWindow      @ Returns the created window.
--
function factory.create(player)

    local player_index, player = resolve_player(player)

    ---@diagnostic disable-next-line: missing-fields
    local window = {                                        ---@type InventoryWindow
        player    = player,
        sort_mode = SortMode.standard
    }

    setmetatable(window, metatable)

    factory.createGUI(window)

    assert(storage.windows.main_inventory[player.index] == nil, "Inventory window already exists!")    -- [DEBUG-ONLY] . --

    storage.windows.main_inventory[player.index] = window

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(player)

    local player_index, player = resolve_player(player)
    local window = storage.windows.main_inventory[player_index]                 ---@type InventoryWindow

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                 -- [DEBUG-ONLY] . --
    assert(window.player and window.player.valid and window.player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.player == player, "Player must be the same as the window one !")                                          -- [DEBUG-ONLY] . --

    window:setVisible(false)
    window:getFrame().destroy()
    window.player    = nil
    window.sort_mode = nil

    storage.windows.main_inventory[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create the GUI of the inventory window.
--- [_private_]
--
--- -----
--- @param window InventoryWindow       The window that will own the GUI.
--
--- @return LuaGuiElement               @ Returns the created GUI frame.
--
function factory.createGUI(window)          ---@private

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                       -- [DEBUG-ONLY] . --
    assert(window.player and window.player.valid and window.player.object_name == "LuaPlayer", "Player must exist here !")    -- [DEBUG-ONLY] . --
    assert(window.player.gui.screen[GUI_NAME.main_frame] == nil, "GUI frame already exists!")                                 -- [DEBUG-ONLY] . --

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
        type    = "sprite-button",
        name    = GUI_NAME.sort_toolbar_button,
        sprite  = SORT_SPRITE[window.sort_mode],
        style   = "frame_action_button",
        tooltip = "Sorting"
    })

    title_bar.add({
        type           = "sprite-button",
        name           = GUI_NAME.close_button,
        sprite         = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style          = "frame_action_button",
        tooltip        = "Close"
    })

    local content = frame.add({
        type      = "flow",
        name      = GUI_NAME.content_flow,
        direction = "horizontal"
    })

    content.style.horizontal_spacing = 4

    local toolbar = content.add({
        type      = "flow",
        name      = GUI_NAME.sort_toolbar,
        direction = "vertical"
    })

    toolbar.style.vertical_spacing = 0

    local function addSortButton(name, sort_mode, tooltip)
        toolbar.add({
            type    = "sprite-button",
            name    = name,
            sprite  = SORT_SPRITE[sort_mode],
            style   = "frame_action_button",
            tooltip = tooltip,
            tags    = {
                [SORT_TAG_NAME] = sort_mode
            }
        })
    end

    addSortButton(GUI_NAME.sort_standard_button,    SortMode.standard,         "Standard sorting")
    addSortButton(GUI_NAME.sort_count_asc_button,   SortMode.count_ascending,  "Sort by quantity ascending")
    addSortButton(GUI_NAME.sort_count_desc_button,  SortMode.count_descending, "Sort by quantity descending")
    addSortButton(GUI_NAME.sort_inventory_button,   SortMode.inventory,        "Inventory order")
    addSortButton(GUI_NAME.sort_last_change_button, SortMode.last_change,      "Sort by last change")
    addSortButton(GUI_NAME.sort_custom_button,      SortMode.custom,           "Custom sorting")

    local grid = content.add({
        type         = "table",
        name         = GUI_NAME.inventory_grid,
        column_count = 10
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    frame.auto_center = true

    metatable_refreshSortButton(window)
    window:setToolbarVisibility(false)
    window:setVisible(true)

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
