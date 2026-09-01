local InventoryType        = require("inventory.inventory_type")
local LuaInventoryRegistry = require("inventory.lua_inventory_registry")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Local Working Cache.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local inventory_content_cache      = { }
local inventory_content_cache_tick = nil

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Inventory type helpers.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local CHARACTER_INVENTORY_TYPES = {
    [InventoryType.character_main]  = defines.inventory.character_main,
    [InventoryType.character_ammo]  = defines.inventory.character_ammo,
    [InventoryType.character_guns]  = defines.inventory.character_guns,
    [InventoryType.character_armor] = defines.inventory.character_armor,
    [InventoryType.character_trash] = defines.inventory.character_trash
}

local VEHICLE_INVENTORY_TYPES = {
    [InventoryType.vehicle_main]  = true,
    [InventoryType.vehicle_ammo]  = true,
    [InventoryType.vehicle_trash] = true,
    [InventoryType.vehicle_fuel]  = true
}

local VALID_INVENTORY_TYPES = { }

for _, inventory_type in pairs(InventoryType) do
    VALID_INVENTORY_TYPES[inventory_type] = true
end

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

local function resolveVehicleInventory(lua_vehicle, inventory_type)
    if not lua_vehicle or not lua_vehicle.valid then
        return nil
    end

    if inventory_type == InventoryType.vehicle_fuel then
        local lua_inventory = lua_vehicle.get_fuel_inventory()
        return lua_inventory and lua_inventory.valid and lua_inventory or nil
    end

    local factorio_inventory_type

    if inventory_type == InventoryType.vehicle_main then
        if lua_vehicle.type == "car" then
            factorio_inventory_type = defines.inventory.car_trunk
        elseif lua_vehicle.type == "spider-vehicle" then
            factorio_inventory_type = defines.inventory.spider_trunk
        elseif lua_vehicle.type == "cargo-wagon" then
            factorio_inventory_type = defines.inventory.cargo_wagon
        end

    elseif inventory_type == InventoryType.vehicle_ammo then
        if lua_vehicle.type == "car" then
            factorio_inventory_type = defines.inventory.car_ammo
        elseif lua_vehicle.type == "spider-vehicle" then
            factorio_inventory_type = defines.inventory.spider_ammo
        elseif lua_vehicle.type == "artillery-wagon" then
            factorio_inventory_type = defines.inventory.artillery_wagon_ammo
        end

    elseif inventory_type == InventoryType.vehicle_trash then
        if lua_vehicle.type == "car" then
            factorio_inventory_type = defines.inventory.car_trash
        elseif lua_vehicle.type == "spider-vehicle" then
            factorio_inventory_type = defines.inventory.spider_trash
        end
    end

    if not factorio_inventory_type then
        return nil
    end

    local lua_inventory = lua_vehicle.get_inventory(factorio_inventory_type)
    return lua_inventory and lua_inventory.valid and lua_inventory or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function resolveInventory(owner, inventory_type, lua_character, lua_vehicle)
    assert(owner and owner.valid, "InventorySource owner must be valid !")                                      -- [DEBUG-ONLY] . --
    assert(VALID_INVENTORY_TYPES[inventory_type], "InventorySource contains an invalid InventoryType !")      -- [DEBUG-ONLY] . --

    if owner.object_name == "LuaPlayer" then
        if CHARACTER_INVENTORY_TYPES[inventory_type] then
            lua_character = lua_character or getPlayerCharacter(owner)

            if not lua_character then
                return nil
            end

            local lua_inventory = lua_character.get_inventory(CHARACTER_INVENTORY_TYPES[inventory_type])
            return lua_inventory and lua_inventory.valid and lua_inventory or nil
        end

        if VEHICLE_INVENTORY_TYPES[inventory_type] then
            lua_vehicle = lua_vehicle or owner.physical_vehicle
            return resolveVehicleInventory(lua_vehicle, inventory_type)
        end

        return nil
    end

    if owner.object_name ~= "LuaEntity" then
        return nil
    end

    if VEHICLE_INVENTORY_TYPES[inventory_type] then
        return resolveVehicleInventory(owner, inventory_type)
    end

    local factorio_inventory_type

    if inventory_type == InventoryType.chest_main then
        factorio_inventory_type = defines.inventory.chest
    elseif inventory_type == InventoryType.chest_trash then
        factorio_inventory_type = defines.inventory.logistic_container_trash
    else
        -- Train-wide sources intentionally remain unresolved until train support is implemented.
        return nil
    end

    local lua_inventory = owner.get_inventory(factorio_inventory_type)
    return lua_inventory and lua_inventory.valid and lua_inventory or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function registerResolvedInventories(lua_inventories)
    local registered_inventories = { }
    local registered_ids         = { }

    for _, lua_inventory in ipairs(lua_inventories) do
        assert(lua_inventory and lua_inventory.valid and lua_inventory.object_name == "LuaInventory", "InventorySource can only contain valid LuaInventory !")      -- [DEBUG-ONLY] . --

        registered_inventories[#registered_inventories + 1] = lua_inventory
        registered_ids[#registered_ids + 1] = LuaInventoryRegistry.register(lua_inventory)
    end

    return registered_inventories, registered_ids
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function unregisterResolvedInventories(inventory_data)
    for _, lua_inventory_id in ipairs(inventory_data.lua_inventory_ids) do
        LuaInventoryRegistry.unregister(lua_inventory_id)
    end
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySourceMetatable.                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySourceMetatable
---
--- ### This class groups all functions used to manage an inventory source.
---
--- @field private entries            table[]             The descriptive source entries grouped by owner.
--- @field private lua_inventories    LuaInventory[]      The flattened resolved LuaInventory contained in the source.
--- @field private lua_inventory_ids  integer[]           The flattened registry IDs matching `lua_inventories`.
--- @field private inventory          Inventory?          The Inventory currently monitoring the source.
---
--
local metatable = { }

metatable.object_name = "InventorySource"
script.register_metatable(MOD_PREFIX .. "InventorySourceMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function rebuildFlattenedInventories(source)
    local lua_inventories   = { }
    local lua_inventory_ids = { }

    for _, entry in ipairs(source.entries) do
        for _, inventory_data in pairs(entry.inventories) do
            for index, lua_inventory in ipairs(inventory_data.lua_inventories) do
                local duplicate = false

                for _, existing_inventory in ipairs(lua_inventories) do
                    if existing_inventory == lua_inventory then
                        duplicate = true
                        break
                    end
                end

                if not duplicate then
                    lua_inventories[#lua_inventories + 1] = lua_inventory
                    lua_inventory_ids[#lua_inventory_ids + 1] = inventory_data.lua_inventory_ids[index]
                end
            end
        end
    end

    source.lua_inventories   = lua_inventories
    source.lua_inventory_ids = lua_inventory_ids
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function replaceInventoryType(source, entry, inventory_type, lua_inventories)
    local inventory_data = entry.inventories[inventory_type]

    assert(inventory_data, "InventorySource entry does not contain this InventoryType !")      -- [DEBUG-ONLY] . --

    if #lua_inventories == #inventory_data.lua_inventories then
        local identical = true

        for index, lua_inventory in ipairs(lua_inventories) do
            if inventory_data.lua_inventories[index] ~= lua_inventory then
                identical = false
                break
            end
        end

        if identical then
            return false
        end
    end

    local new_lua_inventories, new_lua_inventory_ids = registerResolvedInventories(lua_inventories)

    unregisterResolvedInventories(inventory_data)

    inventory_data.lua_inventories   = new_lua_inventories
    inventory_data.lua_inventory_ids = new_lua_inventory_ids

    rebuildFlattenedInventories(source)

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getEntries()
    return self.entries
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getInventories()
    return self.lua_inventories
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getInventoryIDs()
    return self.lua_inventory_ids
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getTrackedPlayers()
    local players = { }

    for _, entry in ipairs(self.entries) do
        if entry.owner.object_name == "LuaPlayer" then
            for inventory_type in pairs(entry.inventories) do
                if CHARACTER_INVENTORY_TYPES[inventory_type] or VEHICLE_INVENTORY_TYPES[inventory_type] then
                    local duplicate = false

                    for _, lua_player in ipairs(players) do
                        if lua_player == entry.owner then
                            duplicate = true
                            break
                        end
                    end

                    if not duplicate then
                        players[#players + 1] = entry.owner
                    end

                    break
                end
            end
        end
    end

    return players
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:usesPlayer(player)
    local _, lua_player = resolve_player(player)

    for _, tracked_player in ipairs(self:getTrackedPlayers()) do
        if tracked_player == lua_player then
            return true
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Re-resolve only source entries that depend on one player's physical character or vehicle.
--
--- Character and vehicle are passed as one physical-context snapshot so a character replacement cannot leave vehicle
--- inventories synchronized against the previous character.
--
function metatable:updatePlayerContext(player, lua_character, lua_vehicle, character_changed, vehicle_changed)
    local _, lua_player = resolve_player(player)
    local changed = false

    for _, entry in ipairs(self.entries) do
        if entry.owner == lua_player then
            for inventory_type in pairs(entry.inventories) do
                local should_resolve = CHARACTER_INVENTORY_TYPES[inventory_type] and character_changed
                    or VEHICLE_INVENTORY_TYPES[inventory_type] and vehicle_changed

                if should_resolve then
                    local lua_inventory = resolveInventory(entry.owner, inventory_type, lua_character, lua_vehicle)
                    local lua_inventories = lua_inventory and { lua_inventory } or { }

                    if replaceInventoryType(self, entry, inventory_type, lua_inventories) then
                        changed = true
                    end
                end
            end
        end
    end

    return changed
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:getInventoryContent(index)
    assert(type(index) == "number" and index > 0 and index % 1 == 0, "InventorySource index must be a positive integer !")      -- [DEBUG-ONLY] . --
    assert(self.lua_inventories[index] ~= nil, "InventorySource LuaInventory does not exist !")                                  -- [DEBUG-ONLY] . --
    assert(self.lua_inventory_ids[index] ~= nil, "InventorySource LuaInventory ID does not exist !")                             -- [DEBUG-ONLY] . --

    local tick = game.tick

    if inventory_content_cache_tick ~= tick then
        inventory_content_cache      = { }
        inventory_content_cache_tick = tick
    end

    local lua_inventory_id = self.lua_inventory_ids[index]
    local content          = inventory_content_cache[lua_inventory_id]

    if content then
        return content
    end

    local lua_inventory = self.lua_inventories[index]

    if lua_inventory.valid then
        content = lua_inventory.get_contents()
    else
        content = { }
    end

    inventory_content_cache[lua_inventory_id] = content

    return content
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:containsInventory(lua_inventory)
    assert(lua_inventory ~= nil, "LuaInventory cannot be nil !")                                                       -- [DEBUG-ONLY] . --
    assert(type(lua_inventory) == "table" or type(lua_inventory) == "userdata", "LuaInventory must be a LuaObject !")  -- [DEBUG-ONLY] . --
    assert(lua_inventory.valid, "LuaInventory must be valid !")                                                        -- [DEBUG-ONLY] . --
    assert(lua_inventory.object_name == "LuaInventory", "LuaInventory must be a LuaInventory !")                       -- [DEBUG-ONLY] . --

    for _, source_lua_inventory in ipairs(self.lua_inventories) do
        if source_lua_inventory == lua_inventory then
            return true
        end
    end

    return false
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySource.                                                                                              ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class InventorySource: InventorySourceMetatable
---
--- ### This class represents a logical inventory source resolved from descriptive owner/type entries.
---
--- @field private entries            table[]             The descriptive source entries grouped by owner.
--- @field private lua_inventories    LuaInventory[]      The flattened resolved LuaInventory contained in the source.
--- @field private lua_inventory_ids  integer[]           The flattened registry IDs matching `lua_inventories`.
--- @field private inventory          Inventory?          The Inventory currently monitoring the source.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ InventorySourceFactory.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create an InventorySource from a descriptive inventory configuration.
--
--- One runtime entry is created per configured owner. Requested InventoryType are kept as map keys even when they
--- currently resolve no LuaInventory, allowing dynamic player sources to become available later.
--
function factory.new(configuration)
    assert(type(configuration) == "table", "Inventory configuration must be a table !")                    -- [DEBUG-ONLY] . --
    assert(type(configuration.entities) == "table", "Inventory configuration entities must be a table !") -- [DEBUG-ONLY] . --

    local source = {      ---@type InventorySource
        entries           = { },
        lua_inventories   = { },
        lua_inventory_ids = { }
    }

    for _, entity_configuration in ipairs(configuration.entities) do
        assert(type(entity_configuration) == "table", "Inventory entity configuration must be a table !")             -- [DEBUG-ONLY] . --
        assert(entity_configuration.entity and entity_configuration.entity.valid, "Inventory entity must be valid !")  -- [DEBUG-ONLY] . --
        assert(type(entity_configuration.inventory_types) == "table", "Inventory types must be a table !")             -- [DEBUG-ONLY] . --

        local owner = entity_configuration.entity
        local entry = {
            owner       = owner,
            inventories = { }
        }

        for _, inventory_type in ipairs(entity_configuration.inventory_types) do
            assert(VALID_INVENTORY_TYPES[inventory_type], "Inventory configuration contains an invalid InventoryType !")      -- [DEBUG-ONLY] . --
            assert(entry.inventories[inventory_type] == nil, "InventorySource cannot request the same InventoryType twice for one owner !")      -- [DEBUG-ONLY] . --

            local lua_inventory = resolveInventory(owner, inventory_type)
            local lua_inventories = lua_inventory and { lua_inventory } or { }
            local registered_inventories, registered_ids = registerResolvedInventories(lua_inventories)

            entry.inventories[inventory_type] = {
                lua_inventories   = registered_inventories,
                lua_inventory_ids = registered_ids
            }
        end

        source.entries[#source.entries + 1] = entry
    end

    setmetatable(source, metatable)
    rebuildFlattenedInventories(source)

    return source
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.destroy(source)
    assert(source and source.object_name == "InventorySource", "InventorySource does not exist or is invalid !")      -- [DEBUG-ONLY] . --
    assert(source.inventory == nil, "Monitored InventorySource cannot be destroyed !")                                 -- [DEBUG-ONLY] . --

    for _, entry in ipairs(source.entries) do
        for _, inventory_data in pairs(entry.inventories) do
            unregisterResolvedInventories(inventory_data)
        end
    end

    source.entries           = nil
    source.lua_inventories   = nil
    source.lua_inventory_ids = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
