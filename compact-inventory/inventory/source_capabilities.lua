local InventoryType = require("inventory.inventory_type")
local SourceType    = require("inventory.source_type")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local PLAYER_INVENTORY_TYPES = {
    InventoryType.character_main,
    InventoryType.character_ammo,
    InventoryType.character_guns,
    InventoryType.character_armor,
    InventoryType.character_trash,
    InventoryType.vehicle_main,
    InventoryType.vehicle_ammo,
    InventoryType.vehicle_trash,
    InventoryType.vehicle_fuel
}

local SourceCapabilities = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function copyInventoryTypes(inventory_types)
    local result = { }

    for index, inventory_type in ipairs(inventory_types) do
        result[index] = inventory_type
    end

    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Return the InventoryType values that can meaningfully be requested by a source descriptor.
--
--- Availability is semantic, not a guarantee that a concrete LuaInventory currently exists. For example, vehicle
--- inventories remain available for a player source while the player is on foot.
--
function SourceCapabilities.getAvailableInventoryTypes(source_configuration)
    assert(type(source_configuration) == "table", "Source configuration must be a table !")      -- [DEBUG-ONLY] . --

    if source_configuration.type == SourceType.player then
        return copyInventoryTypes(PLAYER_INVENTORY_TYPES)
    end

    assert(false, "Source capabilities are not implemented for this SourceType !")      -- [DEBUG-ONLY] . --
    return { }
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceCapabilities.supportsInventoryType(source_configuration, inventory_type)
    for _, available_inventory_type in ipairs(SourceCapabilities.getAvailableInventoryTypes(source_configuration)) do
        if available_inventory_type == inventory_type then
            return true
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceCapabilities
