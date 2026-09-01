
local InventoryManagerFactory = require("inventory.inventory_manager")

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Character inventory resolution.                                                                               ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local CHARACTER_INVENTORY_TYPES = {
    [defines.inventory.character_main]    = true,
    [defines.inventory.character_guns]    = true,
    [defines.inventory.character_ammo]    = true,
    [defines.inventory.character_armor]   = true,
    [defines.inventory.character_vehicle] = true,
    [defines.inventory.character_trash]   = true
}

local tracker = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getPlayerCharacter(lua_player)
    local lua_character = lua_player.character

    if lua_character and lua_character.valid then
        return lua_character
    end

    lua_character = lua_player.cutscene_character

    if lua_character and lua_character.valid then
        return lua_character
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function resolveConfiguration(configuration)
    assert(type(configuration) == "table", "Inventory configuration must be a table !")                    -- [DEBUG-ONLY] . --
    assert(type(configuration.entities) == "table", "Inventory configuration entities must be a table !") -- [DEBUG-ONLY] . --

    local lua_inventories = { }

    for _, entity_configuration in ipairs(configuration.entities) do
        local entity = entity_configuration.entity

        assert(entity and entity.valid, "Inventory configuration entity must be valid !")                   -- [DEBUG-ONLY] . --
        assert(type(entity_configuration.inventory_types) == "table", "Inventory types must be a table !") -- [DEBUG-ONLY] . --

        for _, inventory_type in ipairs(entity_configuration.inventory_types) do
            local inventory_owner = entity

            if entity.object_name == "LuaPlayer" and CHARACTER_INVENTORY_TYPES[inventory_type] then
                inventory_owner = getPlayerCharacter(entity)

                if not inventory_owner then
                    return nil
                end
            end

            local lua_inventory = inventory_owner.get_inventory(inventory_type)

            if lua_inventory and lua_inventory.valid then
                local duplicate = false

                for _, existing_inventory in ipairs(lua_inventories) do
                    if existing_inventory == lua_inventory then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    lua_inventories[#lua_inventories + 1] = lua_inventory
                end
            end
        end
    end

    return lua_inventories
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Resynchronize all configured inventories owned by one player.
--
--- Character-backed sources keep their previous LuaInventory while the player temporarily has no resolvable physical
--- character. Once a character is available again, changed LuaInventory are replaced atomically in the source.
--
--- -----
--- @param player integer|LuaPlayer      The player whose character-backed sources must be resynchronized.
--
function tracker.resynchronize(player)
    local _, lua_player = resolve_player(player)
    local manager       = InventoryManagerFactory.get(lua_player)

    for _, inventory in pairs(manager:getInventories()) do
        local configuration = inventory:getConfiguration()

        if configuration then
            local lua_inventories = resolveConfiguration(configuration)

            if lua_inventories and #lua_inventories > 0 then
                if inventory:getSource():replaceInventories(lua_inventories) then
                    inventory:update()
                end
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return tracker
