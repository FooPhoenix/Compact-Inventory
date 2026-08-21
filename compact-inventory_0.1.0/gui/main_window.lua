
local InventoryManagerFactory = require("inventory.inventory_manager")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local WINDOW_LIST_MAX_HEIGHT = 300      -- Approximately 10 inventory window rows in-game.
local TREE_INDENT             = 16
local TREE_ACTION_WIDTH       = 44      -- Reserved for the future delete and show/hide actions.

local GUI_NAME = {
    main_frame               = MOD_PREFIX .. "MW_frame",
    title_bar                = MOD_PREFIX .. "MW_titlebar",
    title                    = MOD_PREFIX .. "MW_title",
    dragger                  = MOD_PREFIX .. "MW_dragger",
    add_button               = MOD_PREFIX .. "MW_add",
    close_button             = MOD_PREFIX .. "MW_close",
    windows_column           = MOD_PREFIX .. "MW_windows-column",
    windows_scroll           = MOD_PREFIX .. "MW_windows-scroll",
    windows_table            = MOD_PREFIX .. "MW_windows-table",
    tree_inventory_toggle    = MOD_PREFIX .. "MW_tree-inventory-toggle",
    tree_window_toggle       = MOD_PREFIX .. "MW_tree-window-toggle",
    tree_label               = MOD_PREFIX .. "MW_tree-label",
    creation_column          = MOD_PREFIX .. "MW_creation-column",
    creation_title           = MOD_PREFIX .. "MW_creation-title",
    source_player            = MOD_PREFIX .. "MW_source-player",
    source_player_vehicle    = MOD_PREFIX .. "MW_source-player-vehicle",
    source_selected_entities = MOD_PREFIX .. "MW_source-selected-entities",
    creation_actions         = MOD_PREFIX .. "MW_creation-actions",
    creation_cancel_button   = MOD_PREFIX .. "MW_creation-cancel",
    creation_create_button   = MOD_PREFIX .. "MW_creation-create",
    shortcut_button          = MOD_PREFIX .. "main-window-toggle"
}

local INVENTORY_ID_TAG_NAME = MOD_PREFIX .. "MW_InventoryID"
local WINDOW_ID_TAG_NAME    = MOD_PREFIX .. "MW_WindowID"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainWindowMetatable.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class MainWindowMetatable
---
--- @field private lua_player            LuaPlayer
--- @field private expanded_inventories  table<integer, boolean>
--- @field private expanded_windows      table<integer, table<integer, boolean>>
--- @field         valid                 boolean
--- @field         object_name           string
---
local metatable = { }

metatable.object_name = "MainWindow"
script.register_metatable(MOD_PREFIX .. "MainWindowMetatable", metatable)

metatable.__index = function(self, key)                                         ---@private
    if key == "valid" then
        return metatable.isValid(self)
    end

    return metatable[key]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function isInventoryExpanded(window, inventory_id)
    return window.expanded_inventories[inventory_id] ~= false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function isWindowExpanded(window, inventory_id, window_id)
    local inventory_windows = window.expanded_windows[inventory_id]

    return not inventory_windows or inventory_windows[window_id] ~= false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addTreeRow(parent, level, toggle_name, expanded, caption, tags)
    local row = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    row.style.horizontal_spacing       = 2
    row.style.horizontally_stretchable = true
    row.style.vertical_align           = "center"

    if level > 0 then
        local indent = row.add({ type = "empty-widget" })
        indent.style.width = TREE_INDENT * level
    end

    if toggle_name then
        local toggle = row.add({
            type    = "button",
            name    = toggle_name,
            caption = expanded and "⏷" or "⏵",
            style   = MOD_PREFIX .. "tree-toggle-button",
            tags    = tags
        })

        toggle.style.width = TREE_INDENT
    else
        local toggle_space = row.add({ type = "empty-widget" })
        toggle_space.style.width = TREE_INDENT
    end

    local label = row.add({
        type    = "button",
        name    = GUI_NAME.tree_label,
        caption = caption,
        style   = MOD_PREFIX .. "tree-label-button",
        tags    = tags
    })

    label.style.horizontally_stretchable = true

    local action_space = row.add({ type = "empty-widget" })
    action_space.style.width = TREE_ACTION_WIDTH

    return row
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getPlayer()
    assert(self.lua_player and self.lua_player.valid and self.lua_player.object_name == "LuaPlayer", "Player must be valid here !")      -- [DEBUG-ONLY] . --
    return self.lua_player
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFrame()
    local frame = self:getPlayer().gui.screen[GUI_NAME.main_frame]

    assert(frame, "Main window GUI frame does not exist !")      -- [DEBUG-ONLY] . --

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getWindowsTable()
    local windows_column = self:getFrame()[GUI_NAME.windows_column]
    local scroll         = windows_column and windows_column[GUI_NAME.windows_scroll]
    local windows_table  = scroll and scroll[GUI_NAME.windows_table]

    assert(windows_table, "Main window inventory list must exist here !")      -- [DEBUG-ONLY] . --

    return windows_table
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isValid()                                                    ---@private
    local lua_player = self.lua_player

    return lua_player ~= nil
        and lua_player.valid
        and lua_player.object_name == "LuaPlayer"
        and lua_player.gui.screen[GUI_NAME.main_frame] ~= nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refresh()
    local windows_table = self:getWindowsTable()
    local manager       = InventoryManagerFactory.get(self:getPlayer())
    local inventory_ids = { }

    windows_table.clear()

    for inventory_id in pairs(manager:getInventories()) do
        inventory_ids[#inventory_ids + 1] = inventory_id
    end

    table.sort(inventory_ids)

    for _, inventory_id in ipairs(inventory_ids) do
        local inventory          = manager:getInventories()[inventory_id]
        local inventory_expanded = isInventoryExpanded(self, inventory_id)
        local inventory_tags     = {
            [INVENTORY_ID_TAG_NAME] = inventory_id
        }

        addTreeRow(
            windows_table,
            0,
            GUI_NAME.tree_inventory_toggle,
            inventory_expanded,
            "Inventory " .. inventory_id,
            inventory_tags
        )

        if inventory_expanded then
            local window_ids = { }

            for window_id in pairs(inventory:getWindows()) do
                window_ids[#window_ids + 1] = window_id
            end

            table.sort(window_ids)

            for _, window_id in ipairs(window_ids) do
                local inventory_window = inventory:getWindow(window_id)

                if inventory_window and inventory_window.valid then
                    local window_expanded = isWindowExpanded(self, inventory_id, window_id)
                    local window_tags     = {
                        [INVENTORY_ID_TAG_NAME] = inventory_id,
                        [WINDOW_ID_TAG_NAME]    = window_id
                    }

                    addTreeRow(
                        windows_table,
                        1,
                        GUI_NAME.tree_window_toggle,
                        window_expanded,
                        "Window " .. window_id,
                        window_tags
                    )

                    if window_expanded then
                        for _, item_group in ipairs(inventory_window:getItemGroups()) do
                            addTreeRow(
                                windows_table,
                                2,
                                nil,
                                false,
                                item_group:getName(),
                                window_tags
                            )
                        end
                    end
                end
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleInventoryExpanded(inventory_id)
    assert(type(inventory_id) == "number" and inventory_id > 0, "Inventory ID must be valid here !")      -- [DEBUG-ONLY] . --

    self.expanded_inventories[inventory_id] = not isInventoryExpanded(self, inventory_id)
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleWindowExpanded(inventory_id, window_id)
    assert(type(inventory_id) == "number" and inventory_id > 0, "Inventory ID must be valid here !")           -- [DEBUG-ONLY] . --
    assert(type(window_id) == "number" and window_id > 0, "InventoryWindow ID must be valid here !")           -- [DEBUG-ONLY] . --

    self.expanded_windows[inventory_id] = self.expanded_windows[inventory_id] or { }
    self.expanded_windows[inventory_id][window_id] = not isWindowExpanded(self, inventory_id, window_id)
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:showWindowsList()
    local frame           = self:getFrame()
    local windows_column  = frame[GUI_NAME.windows_column]
    local creation_column = frame[GUI_NAME.creation_column]

    assert(windows_column and creation_column, "Main window columns must exist here !")      -- [DEBUG-ONLY] . --

    self:refresh()
    windows_column.visible  = true
    creation_column.visible = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:showCreationPanel()
    local frame           = self:getFrame()
    local windows_column  = frame[GUI_NAME.windows_column]
    local creation_column = frame[GUI_NAME.creation_column]
    local source_player   = creation_column and creation_column[GUI_NAME.source_player]

    assert(windows_column and creation_column and source_player, "Main window creation controls must exist here !")      -- [DEBUG-ONLY] . --

    source_player.state     = true
    windows_column.visible  = false
    creation_column.visible = true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getCreationConfiguration()
    local creation_column = self:getFrame()[GUI_NAME.creation_column]
    local source_player   = creation_column and creation_column[GUI_NAME.source_player]

    assert(source_player and source_player.state, "A supported inventory source must be selected !")      -- [DEBUG-ONLY] . --

    return {
        entities = {
            {
                entity = self:getPlayer(),
                inventory_types = {
                    defines.inventory.character_main
                },
                options = { }
            }
        },
        options = { }
    }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setVisible(visible)
    assert(type(visible) == "boolean", "Main window visibility must be a boolean !")      -- [DEBUG-ONLY] . --

    if visible then
        self:showWindowsList()
    end

    self:getFrame().visible = visible
    self:getPlayer().set_shortcut_toggled(GUI_NAME.shortcut_button, visible)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isVisible()
    return self:getFrame().visible
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleVisibility()
    self:setVisible(not self:isVisible())
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainWindowFactory.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = {
    exposed_gui_names = {
        add_button               = GUI_NAME.add_button,
        close_button             = GUI_NAME.close_button,
        tree_inventory_toggle    = GUI_NAME.tree_inventory_toggle,
        tree_window_toggle       = GUI_NAME.tree_window_toggle,
        inventory_id_tag_name    = INVENTORY_ID_TAG_NAME,
        window_id_tag_name       = WINDOW_ID_TAG_NAME,
        creation_cancel_button   = GUI_NAME.creation_cancel_button,
        creation_create_button   = GUI_NAME.creation_create_button,
        shortcut_button          = GUI_NAME.shortcut_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.create(player)
    local player_index, lua_player = resolve_player(player)

    assert(storage.windows.main[player_index] == nil, "Main window already exists !")      -- [DEBUG-ONLY] . --

    local window = {                              ---@type MainWindow
        lua_player           = lua_player,
        expanded_inventories = { },
        expanded_windows     = { }
    }

    setmetatable(window, metatable)
    factory.createGUI(window)

    storage.windows.main[player_index] = window

    return window
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(player)
    local player_index, lua_player = resolve_player(player)
    local window = storage.windows.main[player_index]                           ---@type MainWindow

    assert(window and window.object_name == "MainWindow", "Main window does not exist or is invalid !")                    -- [DEBUG-ONLY] . --
    assert(window.lua_player and window.lua_player.valid and window.lua_player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.lua_player == lua_player, "Player must be the same as the window one !")                                  -- [DEBUG-ONLY] . --

    window:setVisible(false)
    window:getFrame().destroy()
    window.lua_player           = nil
    window.expanded_inventories = nil
    window.expanded_windows     = nil

    storage.windows.main[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.createGUI(window)                                              ---@private
    assert(window and window.object_name == "MainWindow", "Main window does not exist or is invalid !")                                  -- [DEBUG-ONLY] . --
    assert(window.lua_player and window.lua_player.valid and window.lua_player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.lua_player.gui.screen[GUI_NAME.main_frame] == nil, "Main window GUI frame already exists !")                           -- [DEBUG-ONLY] . --

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

    title_bar.style.horizontal_spacing       = 2
    title_bar.style.horizontally_stretchable = true
    title_bar.style.vertical_align           = "center"

    local title = title_bar.add({
        type    = "label",
        name    = GUI_NAME.title,
        caption = "Compact Inventory",
        style   = "frame_title"
    })

    title.drag_target = frame

    local dragger = title_bar.add({
        type  = "empty-widget",
        name  = GUI_NAME.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 16
    dragger.drag_target  = frame

    local add = title_bar.add({
        type    = "sprite-button",
        name    = GUI_NAME.add_button,
        sprite  = "utility/add_white",
        style   = "frame_action_button",
        tooltip = "Create new window"
    })

    add.style.width   = 16
    add.style.height  = 16
    add.style.padding = 0

    local close = title_bar.add({
        type           = "sprite-button",
        name           = GUI_NAME.close_button,
        sprite         = "utility/close",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        style          = "frame_action_button",
        tooltip        = "Close"
    })

    close.style.width   = 16
    close.style.height  = 16
    close.style.padding = 0

    local windows_column = frame.add({
        type      = "flow",
        name      = GUI_NAME.windows_column,
        direction = "vertical"
    })

    windows_column.style.horizontally_stretchable = true

    local scroll = windows_column.add({
        type                     = "scroll-pane",
        name                     = GUI_NAME.windows_scroll,
        direction                = "vertical",
        vertical_scroll_policy   = "auto",
        horizontal_scroll_policy = "never"
    })

    scroll.style.maximal_height           = WINDOW_LIST_MAX_HEIGHT
    scroll.style.horizontally_stretchable = true

    local windows_table = scroll.add({
        type         = "table",
        name         = GUI_NAME.windows_table,
        column_count = 1
    })

    windows_table.style.horizontally_stretchable = true
    windows_table.style.vertical_spacing         = 2

    local creation_column = frame.add({
        type      = "flow",
        name      = GUI_NAME.creation_column,
        direction = "vertical",
        visible   = false
    })

    creation_column.style.horizontally_stretchable = true
    creation_column.style.vertical_spacing         = 4

    creation_column.add({
        type    = "label",
        name    = GUI_NAME.creation_title,
        caption = "Create new window"
    })

    creation_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_player,
        caption = "Player",
        state   = true
    })

    local player_vehicle = creation_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_player_vehicle,
        caption = "Player vehicle",
        state   = false
    })

    player_vehicle.enabled = false

    local selected_entities = creation_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_selected_entities,
        caption = "Selected entities",
        state   = false
    })

    selected_entities.enabled = false

    local filler = creation_column.add({
        type = "empty-widget"
    })

    filler.style.vertically_stretchable = true

    local actions = creation_column.add({
        type      = "flow",
        name      = GUI_NAME.creation_actions,
        direction = "horizontal"
    })

    actions.style.horizontally_stretchable = true
    actions.style.horizontal_spacing       = 4

    local spacer = actions.add({
        type = "empty-widget"
    })

    spacer.style.horizontally_stretchable = true

    actions.add({
        type    = "button",
        name    = GUI_NAME.creation_cancel_button,
        caption = "Cancel"
    })

    actions.add({
        type    = "button",
        name    = GUI_NAME.creation_create_button,
        caption = "Create",
        style   = "green_button"
    })

    frame.auto_center = true
    window:refresh()
    window:setVisible(false)

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
