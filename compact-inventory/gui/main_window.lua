
local InventoryManagerFactory = require("inventory.inventory_manager")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local WINDOW_LIST_MAX_HEIGHT       = 300      -- Approximately 10 inventory window rows in-game.
local CREATION_PRESET_MAX_HEIGHT   = 300      -- Approximately 10 preset rows in-game.
local TREE_INDENT                  = 16
local TREE_TOGGLE_WIDTH            = 16
local TREE_TOGGLE_HEIGHT           = 8
local TREE_ACTION_SIZE             = 16

local GUI_NAME = {
    main_frame                     = MOD_PREFIX .. "MW_frame",
    title_bar                      = MOD_PREFIX .. "MW_titlebar",
    title                          = MOD_PREFIX .. "MW_title",
    dragger                        = MOD_PREFIX .. "MW_dragger",
    add_button                     = MOD_PREFIX .. "MW_add",
    close_button                   = MOD_PREFIX .. "MW_close",
    windows_column                 = MOD_PREFIX .. "MW_windows-column",
    windows_scroll                 = MOD_PREFIX .. "MW_windows-scroll",
    windows_table                  = MOD_PREFIX .. "MW_windows-table",
    visibility_flow                = MOD_PREFIX .. "MW_visibility-flow",
    visibility_switch              = MOD_PREFIX .. "MW_visibility-switch",
    tree_inventory_toggle          = MOD_PREFIX .. "MW_tree-inventory-toggle",
    tree_window_toggle             = MOD_PREFIX .. "MW_tree-window-toggle",
    tree_label                     = MOD_PREFIX .. "MW_tree-label",
    tree_name_field                = MOD_PREFIX .. "MW_tree-name-field",
    tree_edit_button               = MOD_PREFIX .. "MW_tree-edit",
    tree_confirm_button            = MOD_PREFIX .. "MW_tree-confirm",
    tree_cancel_button             = MOD_PREFIX .. "MW_tree-cancel",
    tree_visibility_button         = MOD_PREFIX .. "MW_tree-visibility",
    tree_lock_button               = MOD_PREFIX .. "MW_tree-lock",
    tree_delete_button             = MOD_PREFIX .. "MW_tree-delete",
    creation_column                = MOD_PREFIX .. "MW_creation-column",
    creation_title                 = MOD_PREFIX .. "MW_creation-title",
    creation_columns               = MOD_PREFIX .. "MW_creation-columns",
    creation_source_column         = MOD_PREFIX .. "MW_creation-source-column",
    creation_preset_outer_frame    = MOD_PREFIX .. "MW_creation-preset-outer-frame",
    creation_preset_inner_frame    = MOD_PREFIX .. "MW_creation-preset-inner-frame",
    creation_preset_column         = MOD_PREFIX .. "MW_creation-preset-column",
    creation_preset_title          = MOD_PREFIX .. "MW_creation-preset-title",
    creation_preset_scroll         = MOD_PREFIX .. "MW_creation-preset-scroll",
    creation_preset_table          = MOD_PREFIX .. "MW_creation-preset-table",
    source_player                  = MOD_PREFIX .. "MW_source-player",
    source_player_vehicle          = MOD_PREFIX .. "MW_source-player-vehicle",
    source_selected_entities       = MOD_PREFIX .. "MW_source-selected-entities",
    creation_actions               = MOD_PREFIX .. "MW_creation-actions",
    creation_cancel_button         = MOD_PREFIX .. "MW_creation-cancel",
    creation_create_button         = MOD_PREFIX .. "MW_creation-create",
    shortcut_button                = MOD_PREFIX .. "main-window-toggle"
}

local INVENTORY_ID_TAG_NAME            = MOD_PREFIX .. "MW_InventoryID"
local WINDOW_ID_TAG_NAME               = MOD_PREFIX .. "MW_WindowID"
local GROUP_ID_TAG_NAME                = MOD_PREFIX .. "MW_GroupID"
local CREATION_PRESET_NAME_TAG_NAME    = MOD_PREFIX .. "MW_CreationPresetName"
local CREATION_PRESET_DELETE_TAG_NAME  = MOD_PREFIX .. "MW_CreationPresetDelete"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ MainWindowMetatable.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class MainWindowMetatable
---
--- @field private lua_player                  LuaPlayer
--- @field private expanded_inventories        table<integer, boolean>
--- @field private expanded_windows            table<integer, table<integer, boolean>>
--- @field private rename_target               table?
--- @field private selected_window_preset_name string?
--- @field         valid                       boolean
--- @field         object_name                 string
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

local function isRenameTarget(window, tags)
    local target = window.rename_target

    return target ~= nil
        and target.inventory_id == tags[INVENTORY_ID_TAG_NAME]
        and target.window_id == tags[WINDOW_ID_TAG_NAME]
        and target.group_id == tags[GROUP_ID_TAG_NAME]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getInventorySourceTooltip(inventory)
    local lines = { "Sources:" }

    for _, lua_inventory in ipairs(inventory:getSource():getInventories()) do
        lines[#lines + 1] = "- " .. tostring(lua_inventory.name)
    end

    return table.concat(lines, "\n")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addActionSpace(row)
    local space = row.add({ type = "empty-widget" })

    space.style.width  = TREE_ACTION_SIZE
    space.style.height = TREE_ACTION_SIZE

    return space
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addActionButton(row, name, sprite, tooltip, tags, hovered_sprite, clicked_sprite, style)
    local definition = {
        type    = "sprite-button",
        name    = name,
        sprite  = sprite,
        style   = style or MOD_PREFIX .. "tree-action-button",
        tooltip = tooltip,
        tags    = tags
    }

    if hovered_sprite then
        definition.hovered_sprite = hovered_sprite
    end

    if clicked_sprite then
        definition.clicked_sprite = clicked_sprite
    end

    local button = row.add(definition)

    button.style.width   = TREE_ACTION_SIZE
    button.style.height  = TREE_ACTION_SIZE
    button.style.padding = 0

    return button
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addTreeRow(parent, level, toggle_name, expanded, caption, tags, options)
    options = options or { }

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
            type    = "sprite-button",
            name    = toggle_name,
            sprite  = expanded and MOD_PREFIX .. "tree-collapse" or MOD_PREFIX .. "tree-expand",
            style   = MOD_PREFIX .. "tree-toggle-button",
            tooltip = expanded and "Collapse" or "Expand",
            tags    = tags
        })

        toggle.style.width   = TREE_TOGGLE_WIDTH
        toggle.style.height  = TREE_TOGGLE_HEIGHT
        toggle.style.padding = 0
    else
        local toggle_space = row.add({ type = "empty-widget" })
        toggle_space.style.width = TREE_TOGGLE_WIDTH
    end

    if options.renaming then
        local name_field = row.add({
            type                  = "textfield",
            name                  = GUI_NAME.tree_name_field,
            text                  = caption,
            lose_focus_on_confirm = true,
            tags                  = tags
        })

        name_field.style.width = 180
        name_field.focus()
        name_field.select_all()
    elseif toggle_name then
        row.add({
            type    = "button",
            name    = GUI_NAME.tree_label,
            caption = caption,
            style   = MOD_PREFIX .. "tree-label-button",
            tags    = tags
        })
    else
        row.add({
            type    = "label",
            caption = caption
        })
    end

    if options.info_tooltip then
        row.add({
            type    = "sprite",
            sprite  = "info",
            tooltip = options.info_tooltip
        })
    end

    local spacer = row.add({ type = "empty-widget" })
    spacer.style.horizontally_stretchable = true

    if options.renaming then
        addActionButton(row, GUI_NAME.tree_confirm_button, "utility/enter", "Confirm name", tags, nil, nil, "green_button")
        addActionButton(row, GUI_NAME.tree_cancel_button, MOD_PREFIX .. "cancel", "Cancel rename", tags, nil, nil, "button")
        addActionSpace(row)
        addActionSpace(row)
        return row
    end

    if options.edit then
        addActionButton(row, GUI_NAME.tree_edit_button, MOD_PREFIX .. "rename-white", "Rename", tags)
    else
        addActionSpace(row)
    end

    if options.visible ~= nil then
        if options.visible then
            addActionButton(row, GUI_NAME.tree_visibility_button, MOD_PREFIX .. "window-hide", "Hide window", tags)
        else
            addActionButton(row, GUI_NAME.tree_visibility_button, MOD_PREFIX .. "window-show", "Show window", tags)
        end
    else
        addActionSpace(row)
    end

    if options.locked ~= nil then
        addActionButton(
            row,
            GUI_NAME.tree_lock_button,
            MOD_PREFIX .. "window-unlock",
            options.locked and "Unlock window" or "Lock window",
            tags
        )
    else
        addActionSpace(row)
    end

    if options.delete then
        addActionButton(row, GUI_NAME.tree_delete_button, MOD_PREFIX .. "group-delete", "Delete", tags)
    else
        addActionSpace(row)
    end

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

function metatable:getVisibilitySwitch()
    local windows_column    = self:getFrame()[GUI_NAME.windows_column]
    local visibility_flow   = windows_column and windows_column[GUI_NAME.visibility_flow]
    local visibility_switch = visibility_flow and visibility_flow[GUI_NAME.visibility_switch]

    assert(visibility_switch, "Main window visibility switch must exist here !")      -- [DEBUG-ONLY] . --

    return visibility_switch
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getCreationPresetTable()
    local creation_column = self:getFrame()[GUI_NAME.creation_column]
    local columns         = creation_column and creation_column[GUI_NAME.creation_columns]
    local outer           = columns and columns[GUI_NAME.creation_preset_outer_frame]
    local inner           = outer and outer[GUI_NAME.creation_preset_inner_frame]
    local preset_column   = inner and inner[GUI_NAME.creation_preset_column]
    local scroll          = preset_column and preset_column[GUI_NAME.creation_preset_scroll]
    local preset_table    = scroll and scroll[GUI_NAME.creation_preset_table]

    assert(preset_table, "Window preset creation controls must exist here !")      -- [DEBUG-ONLY] . --

    return preset_table
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getWindowVisibilityState()
    local manager       = InventoryManagerFactory.get(self:getPlayer())
    local visible_count = 0
    local window_count  = 0

    for _, inventory in pairs(manager:getInventories()) do
        for _, window in pairs(inventory:getWindows()) do
            if window.valid then
                window_count = window_count + 1

                if window:isVisible() then
                    visible_count = visible_count + 1
                end
            end
        end
    end

    if window_count == 0 then
        return "none"
    elseif visible_count == window_count then
        return "left"
    elseif visible_count == 0 then
        return "right"
    end

    return "none"
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refreshVisibilitySwitch()
    self:getVisibilitySwitch().switch_state = self:getWindowVisibilityState()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setAllWindowsVisible(visible)
    assert(type(visible) == "boolean", "Global window visibility must be a boolean !")      -- [DEBUG-ONLY] . --

    local manager = InventoryManagerFactory.get(self:getPlayer())

    for _, inventory in pairs(manager:getInventories()) do
        for _, window in pairs(inventory:getWindows()) do
            if window.valid and window:isVisible() ~= visible then
                window:setVisible(visible)
            end
        end
    end

    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refreshCreationPresetList(presets)
    assert(type(presets) == "table", "Window preset metadata list must be a table !")      -- [DEBUG-ONLY] . --

    local preset_table = self:getCreationPresetTable()

    preset_table.clear()

    for _, preset in ipairs(presets) do
        assert(type(preset.name) == "string" and preset.name ~= "", "Window preset metadata name must be valid !")      -- [DEBUG-ONLY] . --

        local name_button = preset_table.add({
            type    = "button",
            caption = preset.name,
            toggled = self.selected_window_preset_name == preset.name,
            tags    = {
                [CREATION_PRESET_NAME_TAG_NAME] = preset.name
            }
        })

        name_button.style.horizontally_stretchable = true

        preset_table.add({
            type    = "button",
            caption = "Delete",
            enabled = preset.builtin ~= true,
            tags    = {
                [CREATION_PRESET_DELETE_TAG_NAME] = preset.name
            }
        })
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleCreationPresetSelection(preset_name)
    assert(type(preset_name) == "string" and preset_name ~= "", "Window preset name must be valid !")      -- [DEBUG-ONLY] . --

    if self.selected_window_preset_name == preset_name then
        self.selected_window_preset_name = nil
    else
        self.selected_window_preset_name = preset_name
    end

    local preset_table = self:getCreationPresetTable()

    for _, element in ipairs(preset_table.children) do
        local name = element.tags[CREATION_PRESET_NAME_TAG_NAME]

        if name then
            element.toggled = name == self.selected_window_preset_name
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getSelectedWindowPresetName()
    return self.selected_window_preset_name
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
            inventory:getName(),
            inventory_tags,
            {
                info_tooltip = getInventorySourceTooltip(inventory),
                edit         = true,
                renaming     = isRenameTarget(self, inventory_tags)
            }
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
                        window_tags,
                        {
                            visible = inventory_window:isVisible(),
                            locked  = inventory_window:isLocked(),
                            delete  = true
                        }
                    )

                    if window_expanded then
                        for _, item_group in ipairs(inventory_window:getItemGroups()) do
                            local group_tags = {
                                [INVENTORY_ID_TAG_NAME] = inventory_id,
                                [WINDOW_ID_TAG_NAME]    = window_id,
                                [GROUP_ID_TAG_NAME]     = item_group:getID()
                            }

                            addTreeRow(
                                windows_table,
                                2,
                                nil,
                                false,
                                item_group:getName(),
                                group_tags,
                                {
                                    edit     = true,
                                    delete   = true,
                                    renaming = isRenameTarget(self, group_tags)
                                }
                            )
                        end
                    end
                end
            end
        end
    end

    self:refreshVisibilitySwitch()
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

function metatable:startRename(inventory_id, window_id, group_id)
    assert(type(inventory_id) == "number" and inventory_id > 0, "Inventory ID must be valid here !")      -- [DEBUG-ONLY] . --
    assert(window_id == nil or type(window_id) == "number" and window_id > 0, "InventoryWindow ID must be valid here !")      -- [DEBUG-ONLY] . --
    assert(group_id == nil or type(group_id) == "number" and group_id > 0, "ItemGroup ID must be valid here !")      -- [DEBUG-ONLY] . --
    assert(group_id == nil or window_id ~= nil, "ItemGroup rename requires an InventoryWindow !")      -- [DEBUG-ONLY] . --
    assert(window_id == nil or group_id ~= nil, "InventoryWindow names are not editable !")             -- [DEBUG-ONLY] . --

    self.rename_target = {
        inventory_id = inventory_id,
        window_id    = window_id,
        group_id     = group_id
    }

    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:cancelRename()
    self.rename_target = nil
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:confirmRename(inventory_id, window_id, group_id, name)
    assert(type(name) == "string", "Renamed value must be a string !")      -- [DEBUG-ONLY] . --

    local manager   = InventoryManagerFactory.get(self:getPlayer())
    local inventory = manager:getInventories()[inventory_id]

    assert(inventory and inventory.object_name == "Inventory", "Inventory must exist here !")      -- [DEBUG-ONLY] . --

    if group_id then
        local inventory_window = inventory:getWindow(window_id)

        assert(inventory_window and inventory_window.valid, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --
        inventory_window:setItemGroupName(group_id, name)
    else
        inventory:setName(name)
    end

    self.rename_target = nil
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleWindowVisibility(inventory_id, window_id)
    local inventory = InventoryManagerFactory.get(self:getPlayer()):getInventories()[inventory_id]
    local window    = inventory and inventory:getWindow(window_id) or nil

    assert(window and window.valid, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --

    window:toggleVisibility()
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleWindowLocked(inventory_id, window_id)
    local inventory = InventoryManagerFactory.get(self:getPlayer()):getInventories()[inventory_id]
    local window    = inventory and inventory:getWindow(window_id) or nil

    assert(window and window.valid, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --

    window:toggleLocked()
    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:deleteWindow(inventory_id, window_id)
    local manager   = InventoryManagerFactory.get(self:getPlayer())
    local inventory = manager:getInventories()[inventory_id]
    local window    = inventory and inventory:getWindow(window_id) or nil

    assert(window and window.valid, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --

    inventory:removeWindow(window)
    self.expanded_windows[inventory_id] = self.expanded_windows[inventory_id] or { }
    self.expanded_windows[inventory_id][window_id] = nil

    if next(inventory:getWindows()) == nil then
        self.expanded_inventories[inventory_id] = nil
        self.expanded_windows[inventory_id] = nil
        manager:unmonitorInventory(inventory)
    end

    self:refresh()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:deleteItemGroup(inventory_id, window_id, group_id)
    local manager   = InventoryManagerFactory.get(self:getPlayer())
    local inventory = manager:getInventories()[inventory_id]
    local window    = inventory and inventory:getWindow(window_id) or nil

    assert(window and window.valid, "InventoryWindow must exist here !")      -- [DEBUG-ONLY] . --

    if #window:getItemGroups() == 1 then
        self:deleteWindow(inventory_id, window_id)
    else
        window:removeItemGroup(group_id)
        self:refresh()
    end
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

function metatable:showCreationPanel(presets)
    local frame           = self:getFrame()
    local windows_column  = frame[GUI_NAME.windows_column]
    local creation_column = frame[GUI_NAME.creation_column]
    local columns         = creation_column and creation_column[GUI_NAME.creation_columns]
    local source_column   = columns and columns[GUI_NAME.creation_source_column]
    local source_player   = source_column and source_column[GUI_NAME.source_player]

    assert(windows_column and creation_column and source_player, "Main window creation controls must exist here !")      -- [DEBUG-ONLY] . --
    assert(type(presets) == "table", "Window preset metadata list must be a table !")                                     -- [DEBUG-ONLY] . --

    self.rename_target                = nil
    self.selected_window_preset_name  = nil
    source_player.state               = true
    windows_column.visible            = false
    creation_column.visible           = true

    self:refreshCreationPresetList(presets)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getCreationConfiguration()
    local creation_column = self:getFrame()[GUI_NAME.creation_column]
    local columns         = creation_column and creation_column[GUI_NAME.creation_columns]
    local source_column   = columns and columns[GUI_NAME.creation_source_column]
    local source_player   = source_column and source_column[GUI_NAME.source_player]

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
    else
        self.rename_target                = nil
        self.selected_window_preset_name  = nil
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
        add_button                        = GUI_NAME.add_button,
        close_button                      = GUI_NAME.close_button,
        visibility_switch                 = GUI_NAME.visibility_switch,
        tree_inventory_toggle             = GUI_NAME.tree_inventory_toggle,
        tree_window_toggle                = GUI_NAME.tree_window_toggle,
        tree_label                        = GUI_NAME.tree_label,
        tree_name_field                   = GUI_NAME.tree_name_field,
        tree_edit_button                  = GUI_NAME.tree_edit_button,
        tree_confirm_button               = GUI_NAME.tree_confirm_button,
        tree_cancel_button                = GUI_NAME.tree_cancel_button,
        tree_visibility_button            = GUI_NAME.tree_visibility_button,
        tree_lock_button                  = GUI_NAME.tree_lock_button,
        tree_delete_button                = GUI_NAME.tree_delete_button,
        inventory_id_tag_name             = INVENTORY_ID_TAG_NAME,
        window_id_tag_name                = WINDOW_ID_TAG_NAME,
        group_id_tag_name                 = GROUP_ID_TAG_NAME,
        creation_preset_name_tag_name      = CREATION_PRESET_NAME_TAG_NAME,
        creation_preset_delete_tag_name    = CREATION_PRESET_DELETE_TAG_NAME,
        creation_cancel_button            = GUI_NAME.creation_cancel_button,
        creation_create_button            = GUI_NAME.creation_create_button,
        shortcut_button                   = GUI_NAME.shortcut_button
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.create(player)
    local player_index, lua_player = resolve_player(player)

    assert(storage.windows.main[player_index] == nil, "Main window already exists !")      -- [DEBUG-ONLY] . --

    local window = {                              ---@type MainWindow
        lua_player                  = lua_player,
        expanded_inventories       = { },
        expanded_windows           = { },
        rename_target              = nil,
        selected_window_preset_name = nil
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
    window.lua_player                  = nil
    window.expanded_inventories        = nil
    window.expanded_windows            = nil
    window.rename_target               = nil
    window.selected_window_preset_name = nil

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

    local visibility_flow = windows_column.add({
        type      = "flow",
        name      = GUI_NAME.visibility_flow,
        direction = "horizontal"
    })

    visibility_flow.style.horizontal_spacing       = 4
    visibility_flow.style.horizontally_stretchable = true
    visibility_flow.style.vertical_align           = "center"

    local visibility_spacer = visibility_flow.add({ type = "empty-widget" })
    visibility_spacer.style.horizontally_stretchable = true

    visibility_flow.add({
        type    = "label",
        caption = "Show all"
    })

    visibility_flow.add({
        type             = "switch",
        name             = GUI_NAME.visibility_switch,
        switch_state     = "none",
        allow_none_state = true
    })

    visibility_flow.add({
        type    = "label",
        caption = "Hide all"
    })

    local visibility_spacer_right = visibility_flow.add({ type = "empty-widget" })
    visibility_spacer_right.style.horizontally_stretchable = true

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
        caption = "Create new window",
        style   = "frame_title"
    })

    local creation_columns = creation_column.add({
        type      = "flow",
        name      = GUI_NAME.creation_columns,
        direction = "horizontal"
    })

    creation_columns.style.horizontal_spacing = 4

    local source_column = creation_columns.add({
        type      = "flow",
        name      = GUI_NAME.creation_source_column,
        direction = "vertical"
    })

    source_column.style.vertical_spacing       = 4
    source_column.style.vertically_stretchable = true

    source_column.add({
        type    = "label",
        caption = "Source",
        style   = "frame_title"
    })

    source_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_player,
        caption = "Player",
        state   = true
    })

    local player_vehicle = source_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_player_vehicle,
        caption = "Player vehicle",
        state   = false
    })

    player_vehicle.enabled = false

    local selected_entities = source_column.add({
        type    = "radiobutton",
        name    = GUI_NAME.source_selected_entities,
        caption = "Selected entities",
        state   = false
    })

    selected_entities.enabled = false

    local preset_outer = creation_columns.add({
        type      = "frame",
        name      = GUI_NAME.creation_preset_outer_frame,
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    preset_outer.style.padding = 2

    local preset_inner = preset_outer.add({
        type      = "frame",
        name      = GUI_NAME.creation_preset_inner_frame,
        direction = "vertical"
    })

    preset_inner.style.padding = 2

    local preset_column = preset_inner.add({
        type      = "flow",
        name      = GUI_NAME.creation_preset_column,
        direction = "vertical"
    })

    preset_column.style.vertical_spacing = 2

    preset_column.add({
        type    = "label",
        name    = GUI_NAME.creation_preset_title,
        caption = "Presets",
        style   = "frame_title"
    })

    local preset_scroll = preset_column.add({
        type                     = "scroll-pane",
        name                     = GUI_NAME.creation_preset_scroll,
        vertical_scroll_policy   = "auto",
        horizontal_scroll_policy = "never"
    })

    preset_scroll.style.maximal_height = CREATION_PRESET_MAX_HEIGHT

    local preset_table = preset_scroll.add({
        type         = "table",
        name         = GUI_NAME.creation_preset_table,
        column_count = 2
    })

    preset_table.style.horizontal_spacing = 2
    preset_table.style.vertical_spacing   = 2

    local filler = creation_column.add({ type = "empty-widget" })
    filler.style.vertically_stretchable = true

    local actions = creation_column.add({
        type      = "flow",
        name      = GUI_NAME.creation_actions,
        direction = "horizontal"
    })

    actions.style.horizontally_stretchable = true
    actions.style.horizontal_spacing       = 4

    local spacer = actions.add({ type = "empty-widget" })
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
