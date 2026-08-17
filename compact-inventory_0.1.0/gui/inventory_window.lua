
local InventoryViewFactory = require("inventory.inventory_view")
local ItemGroupFactory      = require("gui.item_group")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Constant Declaration.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local GUI_NAME = {
    main_frame              = MOD_PREFIX .. "IW_frame",
    title_bar               = MOD_PREFIX .. "IW_titlebar",
    title                   = MOD_PREFIX .. "IW_title",
    dragger                 = MOD_PREFIX .. "IW_dragger",
    close_button            = MOD_PREFIX .. "IW_close",
    sort_toolbar_button     = MOD_PREFIX .. "IW_sort-toolbar-button",
    content_flow            = MOD_PREFIX .. "IW_content-flow",
    sort_toolbar            = MOD_PREFIX .. "IW_sort-toolbar",
    sort_standard_button    = MOD_PREFIX .. "IW_sort-standard",
    sort_count_asc_button   = MOD_PREFIX .. "IW_sort-count-asc",
    sort_count_desc_button  = MOD_PREFIX .. "IW_sort-count-desc",
    sort_inventory_button   = MOD_PREFIX .. "IW_sort-inventory",
    sort_last_change_button = MOD_PREFIX .. "IW_sort-last-change",
    sort_custom_button      = MOD_PREFIX .. "IW_sort-custom",
    inventory_grid          = MOD_PREFIX .. "IW_grid",
    shortcut_button         = MOD_PREFIX .. "main-window-toggle"
}

local SortMode = InventoryViewFactory.sort_modes

local SORT_SPRITE = {
    [SortMode.standard]         = MOD_PREFIX .. "sort-standard",
    [SortMode.count_ascending]  = MOD_PREFIX .. "sort-count-asc",
    [SortMode.count_descending] = MOD_PREFIX .. "sort-count-desc",
    [SortMode.inventory]        = MOD_PREFIX .. "sort-inventory",
    [SortMode.last_change]      = MOD_PREFIX .. "sort-last-change",
    [SortMode.custom]           = MOD_PREFIX .. "sort-custom"
}

local SORT_TAG_NAME = MOD_PREFIX .. "SortID"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryWindowMetatable.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryWindowMetatable
---
--- ### This class groups all functions used to create and manage an inventory window.
---
--- @field private lua_player  LuaPlayer       The player that owns the window.
--- @field private item_groups ItemGroup[]     The ordered item groups displayed by the window.
--- @field         valid       boolean         Whether the window is valid or not.
--- @field         object_name string          The object name of the window.
---
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

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    local sort_mode = window:getDefaultItemGroup():getSortMode()
    local toolbar   = window:getToolbar()

    window:getFrame()[GUI_NAME.title_bar][GUI_NAME.sort_toolbar_button].sprite = SORT_SPRITE[sort_mode]

    for _, button in pairs(toolbar.children) do
        button.toggled = ( button.tags[SORT_TAG_NAME] == sort_mode )  -- Just added useless parenthesis, but it is for the sake of readability.
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getPlayer()

    assert(self.lua_player and self.lua_player.valid and self.lua_player.object_name == "LuaPlayer", "Player must be valid here !")      -- [DEBUG-ONLY] . --

    return self.lua_player
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get all item groups displayed by the window.
--
--- -----
--- @return ItemGroup[]      @ The ordered item groups displayed by the window.
--
function metatable:getItemGroups()

    assert(self.item_groups and #self.item_groups > 0, "InventoryWindow must contain at least one ItemGroup !")      -- [DEBUG-ONLY] . --

    return self.item_groups
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the default item group of the window.
--
--- -----
--- @return ItemGroup      @ The default item group.
--
function metatable:getDefaultItemGroup()

    local item_group = self:getItemGroups()[1]

    assert(item_group and item_group.object_name == "ItemGroup", "Default ItemGroup must be valid here !")      -- [DEBUG-ONLY] . --

    return item_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFrame()

    local lua_player = self:getPlayer()

    assert(lua_player.gui.screen[GUI_NAME.main_frame], "GUI frame does not exist!")      -- [DEBUG-ONLY] . --

    return lua_player.gui.screen[GUI_NAME.main_frame]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getToolbar()

    assert(self:getFrame()[GUI_NAME.content_flow] and self:getFrame()[GUI_NAME.content_flow][GUI_NAME.sort_toolbar], "GUI toolbar does not exist!")      -- [DEBUG-ONLY] . --

    return self:getFrame()[GUI_NAME.content_flow][GUI_NAME.sort_toolbar]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isValid()                                                    ---@private

    local lua_player = self.lua_player      -- Do not use getPlayer() here because of internal assert !

    if not lua_player then
        return false
    elseif not lua_player.valid then
        return false
    end

    assert(lua_player.object_name == "LuaPlayer", "Player must be a LuaPlayer here !")      -- [DEBUG-ONLY] In any way this should never happen. --

    if not self.item_groups or #self.item_groups == 0 then
        return false
    end

    for _, item_group in ipairs(self.item_groups) do
        if not item_group or item_group.object_name ~= "ItemGroup" then
            return false
        end
    end

    if not lua_player.gui.screen[GUI_NAME.main_frame] then
        return false
    end

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refresh()

    local content = self:getFrame()[GUI_NAME.content_flow]
    local grid    = content[GUI_NAME.inventory_grid]

    grid.clear()

    for _, item_group in ipairs(self:getItemGroups()) do
        for _, item in ipairs(item_group:getContent()) do
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
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Set the sorting mode of the default item group.
--
--- -----
--- @param sort_mode SortMode      The sorting mode to activate.
--
function metatable:setSortMode(sort_mode)
    self:getDefaultItemGroup():setSortMode(sort_mode)
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
--- @param player integer|LuaPlayer      The player that will own the window.
--- @param inventory Inventory           The logical inventory displayed by the window.
--
--- @return InventoryWindow              @ Returns the created window.
--
function factory.create(player, inventory)

    local player_index, lua_player = resolve_player(player)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --

    ---@diagnostic disable-next-line: missing-fields
    local window = {                                        ---@type InventoryWindow
        lua_player  = lua_player,
        item_groups = {
            ItemGroupFactory.new(inventory)
        }
    }

    setmetatable(window, metatable)

    factory.createGUI(window)

    assert(storage.windows.main_inventory[player_index] == nil, "Inventory window already exists!")      -- [DEBUG-ONLY] . --

    storage.windows.main_inventory[player_index] = window

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(player)

    local player_index, lua_player = resolve_player(player)
    local window = storage.windows.main_inventory[player_index]                 ---@type InventoryWindow

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                                  -- [DEBUG-ONLY] . --
    assert(window.lua_player and window.lua_player.valid and window.lua_player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.lua_player == lua_player, "Player must be the same as the window one !")                                                -- [DEBUG-ONLY] . --

    window:setVisible(false)
    window:getFrame().destroy()
    window.lua_player  = nil
    window.item_groups = nil

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

    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                                  -- [DEBUG-ONLY] . --
    assert(window.lua_player and window.lua_player.valid and window.lua_player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.lua_player.gui.screen[GUI_NAME.main_frame] == nil, "GUI frame already exists!")                                        -- [DEBUG-ONLY] . --

    local frame = window.lua_player.gui.screen.add({
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
        sprite  = SORT_SPRITE[window:getDefaultItemGroup():getSortMode()],
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