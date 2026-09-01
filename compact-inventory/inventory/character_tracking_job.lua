
local CharacterTracker = require("inventory.character_tracker")
local SchedulerFactory = require("util.scheduler")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local TRACKING_INTERVAL = 10

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJobMetatable.                                                                               ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class CharacterTrackingJobMetatable
---
--- ### This class groups all functions used to track one player's physical character.
---
--- @field private player_index       integer              The tracked player index.
--- @field private previous_character LuaEntity?           The last resolved physical character.
--- @field         next_tick          integer?             The next tracking tick requested by the job.
--- @field private current_bucket     SchedulerBucket?     The SchedulerBucket currently containing the job.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "CharacterTrackingJob"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "CharacterTrackingJobMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Execute the scheduled character tracking check.
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

    local lua_character = CharacterTracker.getCharacter(lua_player)

    if lua_character ~= self.previous_character then
        CharacterTracker.resynchronize(lua_player)
        self.previous_character = lua_character
    end

    self.next_tick = tick + TRACKING_INTERVAL
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJob.                                                                                        ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class CharacterTrackingJob: CharacterTrackingJobMetatable
---
--- ### This class represents the scheduled physical-character tracking job for one player.
---
--- @field private player_index       integer              The tracked player index.
--- @field private previous_character LuaEntity?           The last resolved physical character.
--- @field         next_tick          integer?             The next tracking tick requested by the job.
--- @field private current_bucket     SchedulerBucket?     The SchedulerBucket currently containing the job.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ CharacterTrackingJobFactory.                                                                                 ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class CharacterTrackingJobFactory
---
--- ### This class groups all functions used to create and register player character tracking jobs.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Ensure one character tracking job exists for a player.
--
--- -----
--- @param player integer|LuaPlayer      The player that must be tracked.
--
--- @return CharacterTrackingJob         @ Returns the player's tracking job.
--
function factory.ensure(player)
    local player_index, lua_player = resolve_player(player)

    storage.character_tracking_jobs = storage.character_tracking_jobs or { }

    local job = storage.character_tracking_jobs[player_index]

    if not job then
        job = {      ---@type CharacterTrackingJob
            player_index       = player_index,
            previous_character = CharacterTracker.getCharacter(lua_player),
            next_tick          = game.tick + TRACKING_INTERVAL,
            current_bucket     = nil
        }

        setmetatable(job, metatable)
        storage.character_tracking_jobs[player_index] = job
    end

    assert(job.object_name == "CharacterTrackingJob", "Player character tracking job must be valid !")      -- [DEBUG-ONLY] . --

    SchedulerFactory.get():register(job)

    return job
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
