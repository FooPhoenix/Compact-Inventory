local EntityPreviewWindow = { }

local GUI_NAME = {
    frame  = MOD_PREFIX .. "entity-preview-frame",
    camera = MOD_PREFIX .. "entity-preview-camera"
}

local TAG_NAME = {
    anchor_name = MOD_PREFIX .. "EntityPreviewAnchorName",
    offset_x    = MOD_PREFIX .. "EntityPreviewOffsetX",
    offset_y    = MOD_PREFIX .. "EntityPreviewOffsetY"
}

local DEFAULT_SIZE = 400
local DEFAULT_ZOOM = 0.75

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getFrame(lua_player)
    return lua_player.gui.screen[GUI_NAME.frame]
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function createFrame(lua_player)
    local frame = lua_player.gui.screen.add({
        type      = "frame",
        name      = GUI_NAME.frame,
        direction = "vertical",
        visible   = false
    })

    frame.style.padding = 0

    local camera = frame.add({
        type          = "camera",
        name          = GUI_NAME.camera,
        position      = { 0, 0 },
        surface_index = 1,
        zoom          = DEFAULT_ZOOM
    })

    camera.style.width  = DEFAULT_SIZE
    camera.style.height = DEFAULT_SIZE

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getOrCreateFrame(lua_player)
    return getFrame(lua_player) or createFrame(lua_player)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function updateLocation(frame, anchor_frame)
    local anchor_location = anchor_frame.location

    if not anchor_location then
        return false
    end

    local tags = frame.tags

    frame.location = {
        x = anchor_location.x + (tags[TAG_NAME.offset_x] or 0),
        y = anchor_location.y + (tags[TAG_NAME.offset_y] or 0)
    }

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function EntityPreviewWindow.show(lua_player, lua_entity, anchor_frame, options)
    assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Entity preview requires a valid LuaPlayer !")      -- [DEBUG-ONLY] . --
    assert(lua_entity and lua_entity.valid and lua_entity.object_name == "LuaEntity", "Entity preview requires a valid LuaEntity !")      -- [DEBUG-ONLY] . --
    assert(anchor_frame and anchor_frame.valid and anchor_frame.type == "frame", "Entity preview anchor must be a valid frame !")          -- [DEBUG-ONLY] . --

    options = options or { }

    local size   = options.size or DEFAULT_SIZE
    local frame  = getOrCreateFrame(lua_player)
    local camera = frame[GUI_NAME.camera]

    assert(type(size) == "number" and size > 0, "Entity preview size must be positive !")      -- [DEBUG-ONLY] . --
    assert(camera, "Entity preview camera must exist here !")                                   -- [DEBUG-ONLY] . --

    camera.style.width   = size
    camera.style.height  = size
    camera.position      = lua_entity.position
    camera.surface_index = lua_entity.surface.index
    camera.zoom          = options.zoom or DEFAULT_ZOOM
    camera.entity        = lua_entity

    frame.tags = {
        [TAG_NAME.anchor_name] = anchor_frame.name,
        [TAG_NAME.offset_x]    = options.offset_x or 0,
        [TAG_NAME.offset_y]    = options.offset_y or 0
    }

    updateLocation(frame, anchor_frame)
    frame.visible = true
    frame.bring_to_front()

    return frame
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function EntityPreviewWindow.hide(lua_player)
    assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Entity preview requires a valid LuaPlayer !")      -- [DEBUG-ONLY] . --

    local frame = getFrame(lua_player)

    if not frame then
        return false
    end

    local camera = frame[GUI_NAME.camera]

    if camera then
        camera.entity = nil
    end

    frame.visible = false
    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function EntityPreviewWindow.onAnchorLocationChanged(event)
    local lua_player = game.get_player(event.player_index)
    local frame      = lua_player and getFrame(lua_player) or nil

    if not frame or not frame.visible then
        return false
    end

    local tags = frame.tags

    if tags[TAG_NAME.anchor_name] ~= event.element.name then
        return false
    end

    return updateLocation(frame, event.element)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return EntityPreviewWindow
