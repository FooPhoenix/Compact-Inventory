local SourceType = require("inventory.source_type")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local SourceConfiguration = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function copyArray(values)
    local copy = { }

    for index, value in ipairs(values) do
        copy[index] = value
    end

    return copy
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function canonicalizeInventoryTypes(inventory_types)
    assert(type(inventory_types) == "table" and #inventory_types > 0, "Source must contain at least one InventoryType !")      -- [DEBUG-ONLY] . --

    local canonical_inventory_types = { }
    local seen = { }

    for _, inventory_type in ipairs(inventory_types) do
        assert(seen[inventory_type] == nil, "Source cannot contain the same InventoryType twice !")      -- [DEBUG-ONLY] . --

        seen[inventory_type] = true
        canonical_inventory_types[#canonical_inventory_types + 1] = inventory_type
    end

    return canonical_inventory_types
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function canonicalizePlayerSource(source_configuration)
    local players = source_configuration.players

    if players == nil and source_configuration.player ~= nil then
        players = { source_configuration.player }
    end

    assert(type(players) == "table" and #players > 0, "Player source must contain at least one player !")      -- [DEBUG-ONLY] . --

    local canonical_players = { }

    for _, lua_player in ipairs(players) do
        assert(lua_player and lua_player.valid and lua_player.object_name == "LuaPlayer", "Player source must contain valid LuaPlayer objects !")      -- [DEBUG-ONLY] . --

        for _, existing_player in ipairs(canonical_players) do
            assert(existing_player ~= lua_player, "Player source cannot contain the same LuaPlayer twice !")      -- [DEBUG-ONLY] . --
        end

        canonical_players[#canonical_players + 1] = lua_player
    end

    return {
        type            = SourceType.player,
        players         = canonical_players,
        inventory_types = canonicalizeInventoryTypes(source_configuration.inventory_types),
        options         = source_configuration.options or { }
    }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function validateUniquePlayerSelectors(sources)
    local players = { }

    for _, source_configuration in ipairs(sources) do
        if source_configuration.type == SourceType.player then
            for _, lua_player in ipairs(source_configuration.players) do
                for _, existing_player in ipairs(players) do
                    assert(existing_player ~= lua_player, "The same LuaPlayer cannot appear in multiple source descriptors !")      -- [DEBUG-ONLY] . --
                end

                players[#players + 1] = lua_player
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Convert a source configuration to the canonical persistent representation.
--
--- The canonical format groups equivalent selectors together. Player sources therefore use `players = { ... }`
--- even when the current caller still provides the legacy single-player `player = ...` placeholder form.
--
function SourceConfiguration.canonicalize(configuration)
    assert(type(configuration) == "table", "Inventory configuration must be a table !")                                  -- [DEBUG-ONLY] . --
    assert(type(configuration.sources) == "table" and #configuration.sources > 0, "Inventory configuration must contain at least one source !") -- [DEBUG-ONLY] . --

    local canonical = {
        sources = { },
        options = configuration.options or { }
    }

    for _, source_configuration in ipairs(configuration.sources) do
        assert(type(source_configuration) == "table", "Inventory source configuration must be a table !")      -- [DEBUG-ONLY] . --

        if source_configuration.type == SourceType.player then
            canonical.sources[#canonical.sources + 1] = canonicalizePlayerSource(source_configuration)
        else
            assert(false, "Source configuration canonicalization is not implemented for this SourceType !")      -- [DEBUG-ONLY] . --
        end
    end

    validateUniquePlayerSelectors(canonical.sources)

    return canonical
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Expand a canonical persistent configuration into the unit descriptors used by the current runtime resolvers.
--
--- One player descriptor containing N players becomes N runtime descriptors sharing the same InventoryType selection.
--
function SourceConfiguration.normalize(configuration)
    local canonical = SourceConfiguration.canonicalize(configuration)
    local normalized = {
        sources = { },
        options = canonical.options
    }

    for _, source_configuration in ipairs(canonical.sources) do
        if source_configuration.type == SourceType.player then
            for _, lua_player in ipairs(source_configuration.players) do
                normalized.sources[#normalized.sources + 1] = {
                    type            = SourceType.player,
                    player          = lua_player,
                    inventory_types = copyArray(source_configuration.inventory_types),
                    options         = source_configuration.options
                }
            end
        else
            assert(false, "Source configuration normalization is not implemented for this SourceType !")      -- [DEBUG-ONLY] . --
        end
    end

    return normalized
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceConfiguration
