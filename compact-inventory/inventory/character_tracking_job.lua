local SchedulerFactory = require("util.scheduler")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local TRACKING_INTERVAL = 10

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJobMetatable.                                                                               ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class CharacterTrackingJobMetatable
---
--- ### This class groups all functions used to track one player's physical character and vehicle context.
---
--- @field private player_index       integer              The tracked player index.
--- @field private previous_character LuaEntity?           The last resolved physical character.
--- @field private previous_vehicle   LuaEntity?           The last resolved physical vehicle.
--- @field private sources            InventorySource[]    The dynamic InventorySource interested in this player.
--- @field         next_tick          integer?             The next tracking tick requested by the job.
--- @field private current_bucket     SchedulerBucket?     The SchedulerBucket currently containing the job.
---
--
local metatable = { }

metatable.object_name = "CharacterTrackingJob"
script.register_metatable(MOD_PREFIX .. "CharacterTrackingJobMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getCharacter(lua_player)
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

function metatable:registerSource(source)
    assert(source and source.object_name == "InventorySource", "CharacterTrackingJob can only register InventorySource !")      -- [DEBUG-ONLY] . --

    self.sources = self.sources or { }

    for _, registered_source in ipairs(self.sources) do
        if registered_source == source then
            return false
        end
    end

    self.sources[#self.sources + 1] = source

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:unregisterSource(source)
    assert(source and source.object_name == "InventorySource", "CharacterTrackingJob can only unregister InventorySource !")      -- [DEBUG-ONLY] . --

    self.sources = self.sources or { }

    for index, registered_source in ipairs(self.sources) do
        if registered_source == source then
            table.remove(self.sources, index)
            return true
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function migrateSources(job, lua_player)
    if job.sources then
        return
    end

    job.sources = { }

    for _, manager in pairs(storage.inventory_managers or { }) do
        for _, inventory in pairs(manager:getInventories()) do
            local source = inventory:getSource()

            if source:usesPlayer(lua_player) then
                job:registerSource(source)
            end
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Execute the scheduled physical-context tracking check.
--
--- Character and vehicle are read during the same execution and propagated as one snapshot. This prevents a character
--- replacement from temporarily leaving vehicle-backed sources synchronized against the previous physical context.
--
--- -----
--- @param tick integer      The tick being executed by the Scheduler.
--
function metatable:execute(tick)
    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "CharacterTrackingJob execution tick must be a positive integer !")      -- [DEBUG-ONLY] . --

    local lua_player = game.get_player(self.player_index)

    if not lua_player or not lua_player.valid then
        self.next_tick = nil
        return
    end

    migrateSources(self, lua_player)

    local lua_character = getCharacter(lua_player)
    local lua_vehicle   = lua_player.physical_vehicle

    if lua_vehicle and not lua_vehicle.valid then
        lua_vehicle = nil
    end

    local character_changed = lua_character ~= self.previous_character
    local vehicle_changed   = lua_vehicle ~= self.previous_vehicle

    if character_changed or vehicle_changed then
        for _, source in ipairs(self.sources) do
            if source:updatePlayerContext(lua_player, lua_character, lua_vehicle, character_changed, vehicle_changed) then
                local inventory = source.inventory

                if inventory then
                    inventory:update()
                end
            end
        end

        self.previous_character = lua_character
        self.previous_vehicle   = lua_vehicle
    end

    self.next_tick = tick + TRACKING_INTERVAL
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJob.                                                                                        ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class CharacterTrackingJob: CharacterTrackingJobMetatable
---
--- ### This class represents the scheduled physical-context tracking job for one player.
---
--- @field private player_index       integer              The tracked player index.
--- @field private previous_character LuaEntity?           The last resolved physical character.
--- @field private previous_vehicle   LuaEntity?           The last resolved physical vehicle.
--- @field private sources            InventorySource[]    The dynamic InventorySource interested in this player.
--- @field         next_tick          integer?             The next tracking tick requested by the job.
--- @field private current_bucket     SchedulerBucket?     The SchedulerBucket currently containing the job.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJobFactory.                                                                                 ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function factory.get(player)
    local player_index = resolve_player(player)

    return storage.character_tracking_jobs and storage.character_tracking_jobs[player_index] or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Ensure one character tracking job exists for a player.
--
--- -----
--- @param player integer|LuaPlayer      The player that must be tracked.
---
--- @return CharacterTrackingJob         @ Returns the player's tracking job.
--
function factory.ensure(player)
    local player_index, lua_player = resolve_player(player)

    storage.character_tracking_jobs = storage.character_tracking_jobs or { }

    local job = storage.character_tracking_jobs[player_index]

    if not job then
        local lua_vehicle = lua_player.physical_vehicle

        if lua_vehicle and not lua_vehicle.valid then
            lua_vehicle = nil
        end

        job = {      ---@type CharacterTrackingJob
            player_index       = player_index,
            previous_character = getCharacter(lua_player),
            previous_vehicle   = lua_vehicle,
            sources            = { },
            next_tick          = game.tick + TRACKING_INTERVAL,
            current_bucket     = nil
        }

        setmetatable(job, metatable)
        storage.character_tracking_jobs[player_index] = job
    else
        migrateSources(job, lua_player)
    end

    assert(job.object_name == "CharacterTrackingJob", "Player character tracking job must be valid !")      -- [DEBUG-ONLY] . --

    SchedulerFactory.get():register(job)

    return job
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
