local EntityPreviewWindow = { }

local GUI_NAME = {
    frame  = MOD_PREFIX .. "entity-preview-frame",
    camera = MOD_PREFIX .. "entity-preview-camera"
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

function EntityPreviewWindow.show(lua_player, lua_entity, anchor_frame, options)
    assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Entity preview requires a valid LuaPlayer !")      -- [DEBUG-ONLY] . --
    assert(lua_entity and lua_entity.valid and lua_entity.object_name == "LuaEntity", "Entity preview requires a valid LuaEntity !")      -- [DEBUG-ONLY] . --
    assert(anchor_frame and anchor_frame.valid and anchor_frame.type == "frame", "Entity preview anchor must be a valid frame !")          -- [DEBUG-ONLY] . --

    options = options or { }

    local size            = options.size or DEFAULT_SIZE
    local anchor_location = anchor_frame.location
    local frame           = getOrCreateFrame(lua_player)
    local camera          = frame[GUI_NAME.camera]

    assert(type(size) == "number" and size > 0, "Entity preview size must be positive !")      -- [DEBUG-ONLY] . --
    assert(anchor_location ~= nil, "Entity preview anchor must have a screen location !")       -- [DEBUG-ONLY] . --
    assert(camera, "Entity preview camera must exist here !")                                   -- [DEBUG-ONLY] . --

    camera.style.width   = size
    camera.style.height  = size
    camera.position      = lua_entity.position
    camera.surface_index = lua_entity.surface.index
    camera.zoom          = options.zoom or DEFAULT_ZOOM
    camera.entity        = lua_entity

    frame.location = {
        x = anchor_location.x + (options.offset_x or 0),
        y = anchor_location.y + (options.offset_y or 0)
    }

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

return EntityPreviewWindow
