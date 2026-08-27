local factory = { }

local SHORTCUT_NAME = MOD_PREFIX .. "debug-switch-character"
local LOG_PREFIX    = "[Compact Inventory / Character switch test] "

local function describeCharacter(lua_character)
    if not lua_character then
        return "nil"
    end

    if not lua_character.valid then
        return "invalid"
    end

    return lua_character.name .. "#" .. tostring(lua_character.unit_number)
end

local function logPlayerState(label, event)
    local lua_player = game.get_player(event.player_index)

    if not lua_player then
        return
    end

    log(
        LOG_PREFIX
        .. label
        .. " | tick=" .. tostring(event.tick)
        .. " | player=" .. tostring(event.player_index)
        .. " | controller=" .. tostring(lua_player.controller_type)
        .. " | character=" .. describeCharacter(lua_player.character)
    )
end

local function getOrCreateCharacters(lua_player)
    storage.debug_character_switch_test = storage.debug_character_switch_test or { }

    local state = storage.debug_character_switch_test[lua_player.index]

    if state then
        assert(state.character_a and state.character_a.valid, "Debug character A must still be valid !")      -- [DEBUG-ONLY] . --
        assert(state.character_b and state.character_b.valid, "Debug character B must still be valid !")      -- [DEBUG-ONLY] . --
        return state
    end

    local character_a = lua_player.character

    assert(character_a and character_a.valid, "Player must currently own a valid character to initialize the test !")      -- [DEBUG-ONLY] . --

    if not character_a or not character_a.valid then
        return nil
    end

    local position = character_a.surface.find_non_colliding_position(
        character_a.name,
        character_a.position,
        16,
        0.5
    )

    assert(position, "Could not find a position for the second debug character !")      -- [DEBUG-ONLY] . --

    if not position then
        return nil
    end

    local character_b = character_a.surface.create_entity({
        name     = character_a.name,
        position = position,
        force    = character_a.force,
        direction = character_a.direction
    })

    assert(character_b and character_b.valid, "Could not create the second debug character !")      -- [DEBUG-ONLY] . --

    state = {
        character_a = character_a,
        character_b = character_b
    }

    storage.debug_character_switch_test[lua_player.index] = state

    log(
        LOG_PREFIX
        .. "Initialized characters"
        .. " | player=" .. tostring(lua_player.index)
        .. " | A=" .. describeCharacter(character_a)
        .. " | B=" .. describeCharacter(character_b)
    )

    return state
end

function factory.switch(player)
    local _, lua_player = resolve_player(player)
    local state = getOrCreateCharacters(lua_player)

    if not state then
        return
    end

    local current = lua_player.character
    local target

    if current == state.character_a then
        target = state.character_b
    else
        target = state.character_a
    end

    log(
        LOG_PREFIX
        .. "Switch requested"
        .. " | tick=" .. tostring(game.tick)
        .. " | player=" .. tostring(lua_player.index)
        .. " | from=" .. describeCharacter(current)
        .. " | to=" .. describeCharacter(target)
    )

    lua_player.character = target

    log(
        LOG_PREFIX
        .. "Switch completed"
        .. " | tick=" .. tostring(game.tick)
        .. " | player=" .. tostring(lua_player.index)
        .. " | character=" .. describeCharacter(lua_player.character)
    )
end

script.on_event(defines.events.on_player_controller_changed, function(event)
    logPlayerState("on_player_controller_changed", event)
end)

script.on_nth_tick(1, function()
    local inventory_handler = script.get_event_handler(defines.events.on_player_main_inventory_changed)
    local shortcut_handler  = script.get_event_handler(defines.events.on_lua_shortcut)

    assert(inventory_handler, "Main inventory event handler must exist before installing the debug wrapper !")      -- [DEBUG-ONLY] . --
    assert(shortcut_handler, "Lua shortcut event handler must exist before installing the debug wrapper !")         -- [DEBUG-ONLY] . --

    script.on_event(defines.events.on_player_main_inventory_changed, function(event)
        logPlayerState("on_player_main_inventory_changed", event)
        inventory_handler(event)
    end)

    script.on_event(defines.events.on_lua_shortcut, function(event)
        if event.prototype_name == SHORTCUT_NAME then
            factory.switch(event.player_index)
            return
        end

        shortcut_handler(event)
    end)

    script.on_nth_tick(1, nil)
    log(LOG_PREFIX .. "Debug event wrappers installed.")
end)

return factory
