
local InventoryViewFactory = require("inventory.inventory_view")
local ItemGroupFactory      = require("gui.item_group")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SortMode = InventoryViewFactory.sort_modes

local GUI_NAME = {
    main_frame           = MOD_PREFIX .. "IW_frame",
    title_bar            = MOD_PREFIX .. "IW_titlebar",
    dragger              = MOD_PREFIX .. "IW_dragger",
    add_button           = MOD_PREFIX .. "IW_add-button",
    lock_button          = MOD_PREFIX .. "IW_lock-button",
    close_button         = MOD_PREFIX .. "IW_close",
    content_frame        = MOD_PREFIX .. "IW_content-frame",
    groups_scroll        = MOD_PREFIX .. "IW_groups-scroll",
    groups_container     = MOD_PREFIX .. "IW_groups-container",
    group_frame          = MOD_PREFIX .. "IG_frame",
    group_header         = MOD_PREFIX .. "IG_header",
    group_title          = MOD_PREFIX .. "IG_title",
    group_rename_button  = MOD_PREFIX .. "IG_rename-button",
    group_name_field     = MOD_PREFIX .. "IG_name-field",
    group_confirm_button = MOD_PREFIX .. "IG_confirm-button",
    group_spacer         = MOD_PREFIX .. "IG_spacer",
    group_sort_icon      = MOD_PREFIX .. "IG_sort-icon",
    group_menu_button    = MOD_PREFIX .. "IG_menu-button",
    group_unlock_button  = MOD_PREFIX .. "IG_unlock-button",
    inventory_grid       = MOD_PREFIX .. "IG_grid",
    shortcut_button      = MOD_PREFIX .. "main-window-toggle"
}

local SORT_SPRITE = {
    [SortMode.standard]         = MOD_PREFIX .. "sort-standard",
    [SortMode.count_ascending]  = MOD_PREFIX .. "sort-count-asc",
    [SortMode.count_descending] = MOD_PREFIX .. "sort-count-desc",
    [SortMode.inventory]        = MOD_PREFIX .. "sort-inventory",
    [SortMode.last_change]      = MOD_PREFIX .. "sort-last-change",
    [SortMode.custom]           = MOD_PREFIX .. "sort-custom"
}

local SORT_TAG_NAME     = MOD_PREFIX .. "SortID"
local GROUP_ID_TAG_NAME = MOD_PREFIX .. "ItemGroupID"

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventoryWindowMetatable.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventoryWindowMetatable
---
--- ### This class groups all functions used to create and manage an inventory window.
---
--- @field private lua_player     LuaPlayer       The player that owns the window.
--- @field private item_groups    ItemGroup[]     The ordered item groups displayed by the window.
--- @field private next_group_id  integer         The next stable ItemGroup identifier.
--- @field private locked         boolean         Whether the window is displayed in locked mode.
--- @field         valid          boolean         Whether the window is valid or not.
--- @field         object_name    string          The object name of the window.
---
--
local metatable = { }

metatable.object_name = "InventoryWindow"
script.register_metatable(MOD_PREFIX .. "InventoryWindowMetatable", metatable)

metatable.__index = function(self, key)                                         ---@private
    if key == "valid" then
        return metatable.isValid(self)
    end

    return metatable[key]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getPlayer()
    assert(self.lua_player and self.lua_player.valid and self.lua_player.object_name == "LuaPlayer", "Player must be valid here !")      -- [DEBUG-ONLY] . --
    return self.lua_player
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getItemGroups()
    assert(self.item_groups and #self.item_groups > 0, "InventoryWindow must contain at least one ItemGroup !")      -- [DEBUG-ONLY] . --
    return self.item_groups
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getDefaultItemGroup()
    local item_group = self:getItemGroups()[1]

    assert(item_group and item_group.object_name == "ItemGroup", "Default ItemGroup must be valid here !")      -- [DEBUG-ONLY] . --

    return item_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getItemGroupByID(group_id)
    assert(type(group_id) == "number" and group_id > 0, "ItemGroup ID must be a positive integer !")      -- [DEBUG-ONLY] . --

    for _, item_group in ipairs(self:getItemGroups()) do
        if item_group:getID() == group_id then
            return item_group
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getFrame()
    local lua_player = self:getPlayer()
    local frame = lua_player.gui.screen[GUI_NAME.main_frame]

    assert(frame, "GUI frame does not exist !")      -- [DEBUG-ONLY] . --

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getGroupsContainer()
    local content   = self:getFrame()[GUI_NAME.content_frame]
    local scroll    = content and content[GUI_NAME.groups_scroll]
    local container = scroll and scroll[GUI_NAME.groups_container]

    assert(container, "ItemGroup container must exist here !")      -- [DEBUG-ONLY] . --

    return container
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getGroupFrame(item_group)
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup must be valid here !")      -- [DEBUG-ONLY] . --

    local group = self:getGroupsContainer()[GUI_NAME.group_frame .. "-" .. item_group:getID()]

    assert(group, "ItemGroup GUI frame must exist here !")      -- [DEBUG-ONLY] . --

    return group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getGroupHeader(window, item_group)
    local header = window:getGroupFrame(item_group)[GUI_NAME.group_header]

    assert(header, "ItemGroup header must exist here !")      -- [DEBUG-ONLY] . --

    return header
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function setGroupLockGUI(group, locked, first_group)
    group.style = locked and MOD_PREFIX .. "locked-window-frame" or "frame"
    group.style.padding                  = locked and 0 or 2
    group.style.horizontally_stretchable = true

    local header        = group[GUI_NAME.group_header]
    local rename_button = header and header[GUI_NAME.group_rename_button]
    local menu_button   = header and header[GUI_NAME.group_menu_button]
    local unlock_button = header and header[GUI_NAME.group_unlock_button]

    assert(header and rename_button and menu_button and unlock_button, "ItemGroup lock GUI must be complete here !")      -- [DEBUG-ONLY] . --

    rename_button.visible = not locked
    menu_button.visible   = not locked
    unlock_button.visible = locked and first_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isValid()                                                    ---@private
    local lua_player = self.lua_player

    if not lua_player or not lua_player.valid then
        return false
    end

    assert(lua_player.object_name == "LuaPlayer", "Player must be a LuaPlayer here !")      -- [DEBUG-ONLY] . --

    if not self.item_groups or #self.item_groups == 0 then
        return false
    end

    for _, item_group in ipairs(self.item_groups) do
        if not item_group or item_group.object_name ~= "ItemGroup" then
            return false
        end
    end

    return lua_player.gui.screen[GUI_NAME.main_frame] ~= nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:updateMaxHeight()
    local lua_player = self:getPlayer()
    local content    = self:getFrame()[GUI_NAME.content_frame]
    local scroll     = content and content[GUI_NAME.groups_scroll]

    assert(scroll, "ItemGroup scroll pane must exist here !")      -- [DEBUG-ONLY] . --

    local display_height = math.floor(lua_player.display_resolution.height / lua_player.display_scale)

    scroll.style.maximal_height = math.max(120, display_height - 32)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refreshGroup(item_group)
    assert(item_group and item_group.object_name == "ItemGroup", "ItemGroup must be valid here !")      -- [DEBUG-ONLY] . --

    local group = self:getGroupFrame(item_group)
    local grid  = group[GUI_NAME.inventory_grid]

    assert(grid, "ItemGroup inventory grid must exist here !")      -- [DEBUG-ONLY] . --

    grid.clear()

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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refresh()
    for _, item_group in ipairs(self:getItemGroups()) do
        self:refreshGroup(item_group)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:refreshSortIcon(group_id)
    local item_group = self:getItemGroupByID(group_id)

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    local icon = getGroupHeader(self, item_group)[GUI_NAME.group_sort_icon]

    assert(icon, "ItemGroup sort icon must exist here !")      -- [DEBUG-ONLY] . --

    icon.sprite = SORT_SPRITE[item_group:getSortMode()]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setSortMode(group_id, sort_mode)
    local item_group = self:getItemGroupByID(group_id)

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    item_group:setSortMode(sort_mode)
    self:refreshSortIcon(group_id)
    self:refreshGroup(item_group)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:startRename(group_id)
    local item_group = self:getItemGroupByID(group_id)

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    local header        = getGroupHeader(self, item_group)
    local title         = header[GUI_NAME.group_title]
    local rename_button = header[GUI_NAME.group_rename_button]
    local name_field    = header[GUI_NAME.group_name_field]
    local confirm       = header[GUI_NAME.group_confirm_button]

    assert(title and rename_button and name_field and confirm, "ItemGroup rename GUI must be complete here !")      -- [DEBUG-ONLY] . --

    name_field.text = item_group:getName()

    title.visible         = false
    rename_button.visible = false
    name_field.visible    = true
    confirm.visible       = true

    name_field.focus()
    name_field.select_all()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:confirmRename(group_id)
    local item_group = self:getItemGroupByID(group_id)

    assert(item_group, "ItemGroup must exist here !")      -- [DEBUG-ONLY] . --

    local header        = getGroupHeader(self, item_group)
    local title         = header[GUI_NAME.group_title]
    local rename_button = header[GUI_NAME.group_rename_button]
    local name_field    = header[GUI_NAME.group_name_field]
    local confirm       = header[GUI_NAME.group_confirm_button]

    assert(title and rename_button and name_field and confirm, "ItemGroup rename GUI must be complete here !")      -- [DEBUG-ONLY] . --

    item_group:setName(name_field.text)
    title.caption = item_group:getName()

    title.visible         = true
    rename_button.visible = true
    name_field.visible    = false
    confirm.visible       = false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:createItemGroup()
    local inventory  = self:getDefaultItemGroup():getView():getInventory()
    local item_group = ItemGroupFactory.new(inventory, self.next_group_id)

    self.next_group_id = self.next_group_id + 1
    self.item_groups[#self.item_groups + 1] = item_group

    factory.createItemGroupGUI(self, item_group)
    self:refreshGroup(item_group)
    self:updateMaxHeight()

    local content = self:getFrame()[GUI_NAME.content_frame]
    local scroll  = content[GUI_NAME.groups_scroll]

    scroll.scroll_to_element(self:getGroupFrame(item_group))

    return item_group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:removeItemGroup(group_id)
    assert(#self:getItemGroups() > 1, "The last ItemGroup must not be removed directly !")      -- [DEBUG-ONLY] . --

    for index, item_group in ipairs(self.item_groups) do
        if item_group:getID() == group_id then
            self:getGroupFrame(item_group).destroy()
            table.remove(self.item_groups, index)
            self:updateMaxHeight()
            return
        end
    end

    assert(false, "ItemGroup to remove does not exist !")      -- [DEBUG-ONLY] . --
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:isLocked()
    return self.locked == true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setLocked(locked)
    assert(type(locked) == "boolean", "Locked state must be a boolean !")      -- [DEBUG-ONLY] . --

    if self.locked == locked then
        return
    end

    self.locked = locked

    local frame     = self:getFrame()
    local title_bar = frame[GUI_NAME.title_bar]
    local content   = frame[GUI_NAME.content_frame]

    assert(title_bar and content, "InventoryWindow lock GUI must be complete here !")      -- [DEBUG-ONLY] . --

    title_bar.visible = not locked

    frame.style = locked and MOD_PREFIX .. "locked-window-frame" or "frame"
    frame.style.left_padding   = locked and 0 or 4
    frame.style.right_padding  = locked and 0 or 4
    frame.style.top_padding    = locked and 0 or 3
    frame.style.bottom_padding = locked and 0 or 4

    content.style = locked and MOD_PREFIX .. "locked-content-frame" or "inside_shallow_frame"
    content.style.padding                  = locked and 0 or 2
    content.style.horizontally_stretchable = true

    for index, item_group in ipairs(self:getItemGroups()) do
        setGroupLockGUI(self:getGroupFrame(item_group), locked, index == 1)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:toggleLocked()
    self:setLocked(not self:isLocked())
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:setVisible(visible)
    if visible then
        self:updateMaxHeight()
        self:refresh()
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
-- ║ InventoryWindowFactory.                                                                                        ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

factory = {
    exposed_gui_names = {
        close_button         = GUI_NAME.close_button,
        add_button           = GUI_NAME.add_button,
        lock_button          = GUI_NAME.lock_button,
        group_rename_button  = GUI_NAME.group_rename_button,
        group_name_field     = GUI_NAME.group_name_field,
        group_confirm_button = GUI_NAME.group_confirm_button,
        group_menu_button    = GUI_NAME.group_menu_button,
        group_unlock_button  = GUI_NAME.group_unlock_button,
        shortcut_button      = GUI_NAME.shortcut_button,
        sort_tag_name        = SORT_TAG_NAME,
        group_id_tag_name    = GROUP_ID_TAG_NAME
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.create(player, inventory)
    local player_index, lua_player = resolve_player(player)

    assert(inventory and inventory.object_name == "Inventory", "You need to provide a valid Inventory !")      -- [DEBUG-ONLY] . --

    local window = {                                        ---@type InventoryWindow
        lua_player    = lua_player,
        item_groups   = {
            ItemGroupFactory.new(inventory, 1)
        },
        next_group_id = 2,
        locked        = false
    }

    setmetatable(window, metatable)
    factory.createGUI(window)

    assert(storage.windows.main_inventory[player_index] == nil, "Inventory window already exists !")      -- [DEBUG-ONLY] . --

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
    window.lua_player     = nil
    window.item_groups    = nil
    window.next_group_id  = nil
    window.locked         = nil

    storage.windows.main_inventory[player_index] = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.createItemGroupGUI(window, item_group)                         ---@private
    local container = window:getGroupsContainer()
    local group_id  = item_group:getID()
    local tags      = {
        [GROUP_ID_TAG_NAME] = group_id
    }

    local group = container.add({
        type      = "frame",
        name      = GUI_NAME.group_frame .. "-" .. group_id,
        direction = "vertical"
    })

    group.style.padding                  = 2
    group.style.horizontally_stretchable = true

    local header = group.add({
        type      = "flow",
        name      = GUI_NAME.group_header,
        direction = "horizontal"
    })

    header.style.horizontal_spacing       = 2
    header.style.horizontally_stretchable = true
    header.style.vertical_align           = "center"

    local group_title = header.add({
        type    = "label",
        name    = GUI_NAME.group_title,
        caption = item_group:getName()
    })

    group_title.style.top_margin    = 0
    group_title.style.bottom_margin = 0

    local rename_button = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_rename_button,
        sprite  = "utility/rename_icon",
        style   = "button",
        tooltip = "Rename group",
        tags    = tags
    })

    rename_button.style.width   = 16
    rename_button.style.height  = 16
    rename_button.style.padding = 0

    local name_field = header.add({
        type                  = "textfield",
        name                  = GUI_NAME.group_name_field,
        text                  = item_group:getName(),
        icon_selector         = true,
        lose_focus_on_confirm = true,
        visible               = false,
        tags                  = tags
    })

    name_field.style.width  = 180
    name_field.style.height = 28

    local confirm = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_confirm_button,
        sprite  = "utility/enter",
        style   = "green_button",
        tooltip = "Confirm group name",
        visible = false,
        tags    = tags
    })

    confirm.style.width   = 28
    confirm.style.height  = 28
    confirm.style.padding = 0

    local spacer = header.add({
        type = "empty-widget",
        name = GUI_NAME.group_spacer
    })

    spacer.style.horizontally_stretchable = true

    local sort_icon = header.add({
        type    = "sprite",
        name    = GUI_NAME.group_sort_icon,
        sprite  = SORT_SPRITE[item_group:getSortMode()],
        tooltip = "Current sorting"
    })

    sort_icon.style.width  = 22
    sort_icon.style.height = 22

    local menu_button = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_menu_button,
        sprite  = MOD_PREFIX .. "group-menu",
        style   = "frame_action_button",
        tooltip = "Group options",
        tags    = tags
    })

    menu_button.style.width   = 22
    menu_button.style.height  = 22
    menu_button.style.padding = 0

    local unlock_button = header.add({
        type    = "sprite-button",
        name    = GUI_NAME.group_unlock_button,
        sprite  = MOD_PREFIX .. "window-unlock",
        style   = "frame_action_button",
        tooltip = "Unlock window",
        visible = false
    })

    unlock_button.style.width   = 22
    unlock_button.style.height  = 22
    unlock_button.style.padding = 0

    local grid = group.add({
        type         = "table",
        name         = GUI_NAME.inventory_grid,
        column_count = 10
    })

    grid.style.horizontal_spacing = 0
    grid.style.vertical_spacing   = 0

    if window:isLocked() then
        setGroupLockGUI(group, true, #container.children == 1)
    end

    return group
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.createGUI(window)                                              ---@private
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")                                  -- [DEBUG-ONLY] . --
    assert(window.lua_player and window.lua_player.valid and window.lua_player.object_name == "LuaPlayer", "Player must exist here !")  -- [DEBUG-ONLY] . --
    assert(window.lua_player.gui.screen[GUI_NAME.main_frame] == nil, "GUI frame already exists !")                                       -- [DEBUG-ONLY] . --

    local frame = window.lua_player.gui.screen.add({
        type      = "frame",
        name      = GUI_NAME.main_frame,
        direction = "vertical"
    })

    frame.style.left_padding   = 4
    frame.style.right_padding  = 4
    frame.style.top_padding    = 3
    frame.style.bottom_padding = 4

    local title_bar = frame.add({
        type      = "flow",
        name      = GUI_NAME.title_bar,
        direction = "horizontal"
    })

    title_bar.style.horizontal_spacing       = 2
    title_bar.style.horizontally_stretchable = true

    local dragger = title_bar.add({
        type  = "empty-widget",
        name  = GUI_NAME.dragger,
        style = "draggable_space"
    })

    dragger.style.horizontally_stretchable = true
    dragger.style.height = 16
    dragger.drag_target  = frame

    local add_button = title_bar.add({
        type    = "sprite-button",
        name    = GUI_NAME.add_button,
        sprite  = "utility/add_white",
        style   = "frame_action_button",
        tooltip = "Add group"
    })

    add_button.style.width   = 16
    add_button.style.height  = 16
    add_button.style.padding = 0

    local lock = title_bar.add({
        type    = "sprite-button",
        name    = GUI_NAME.lock_button,
        sprite  = MOD_PREFIX .. "window-unlock",
        style   = "frame_action_button",
        tooltip = "Lock window"
    })

    lock.style.width   = 16
    lock.style.height  = 16
    lock.style.padding = 0

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

    local content = frame.add({
        type      = "frame",
        name      = GUI_NAME.content_frame,
        direction = "vertical",
        style     = "inside_shallow_frame"
    })

    content.style.padding                  = 2
    content.style.horizontally_stretchable = true

    local scroll = content.add({
        type                     = "scroll-pane",
        name                     = GUI_NAME.groups_scroll,
        direction                = "vertical",
        style                    = "naked_scroll_pane",
        horizontal_scroll_policy = "never",
        vertical_scroll_policy   = "auto"
    })

    scroll.style.padding                  = 0
    scroll.style.horizontally_stretchable = true

    local container = scroll.add({
        type      = "flow",
        name      = GUI_NAME.groups_container,
        direction = "vertical"
    })

    container.style.vertical_spacing         = 2
    container.style.horizontally_stretchable = true

    for _, item_group in ipairs(window:getItemGroups()) do
        factory.createItemGroupGUI(window, item_group)
    end

    frame.auto_center = true
    window:updateMaxHeight()
    window:setVisible(true)

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory