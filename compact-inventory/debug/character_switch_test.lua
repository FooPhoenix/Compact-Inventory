local factory = { }

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
        name      = character_a.name,
        position  = position,
        force     = character_a.force,
        direction = character_a.direction
    })

    assert(character_b and character_b.valid, "Could not create the second debug character !")      -- [DEBUG-ONLY] . --

    state = {
        character_a = character_a,
        character_b = character_b
    }

    storage.debug_character_switch_test[lua_player.index] = state

    return state
end

function factory.switch(player)
    local _, lua_player = resolve_player(player)
    local state = getOrCreateCharacters(lua_player)

    if not state then
        return
    end

    if lua_player.character == state.character_a then
        lua_player.character = state.character_b
    else
        lua_player.character = state.character_a
    end
end

return factory
