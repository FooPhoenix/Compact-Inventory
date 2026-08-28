
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerBucketMetatable.                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerBucketMetatable
---
--- ### This class groups all functions used to manage a scheduler bucket.
---
--- @field private tick integer      The tick associated with the bucket.
--- @field private jobs table[]      The jobs scheduled for the tick.
---
--
local bucket_metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

bucket_metatable.object_name = "SchedulerBucket"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "SchedulerBucketMetatable", bucket_metatable)
bucket_metatable.__index = bucket_metatable

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerBucket.                                                                                              ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerBucket: SchedulerBucketMetatable
---
--- ### This class represents all jobs scheduled for a specific tick.
---
--- @field private tick integer      The tick associated with the bucket.
--- @field private jobs table[]      The jobs scheduled for the tick.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerBucketFactory.                                                                                       ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local bucket_factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new scheduler bucket.
--
--- -----
--- @param tick integer      The tick associated with the bucket.
---
--- @return SchedulerBucket  @ Returns the created scheduler bucket.
--
function bucket_factory.new(tick)

    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "Scheduler bucket tick must be a positive integer !")  -- [DEBUG-ONLY] . --

    local bucket = {      ---@type SchedulerBucket
        tick = tick,
        jobs = { }
    }

    setmetatable(bucket, bucket_metatable)

    return bucket
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerMetatable.                                                                                           ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerMetatable
---
--- ### This class groups all functions used to manage scheduled jobs.
---
--- @field private scheduled_jobs table<integer, SchedulerBucket>      The scheduler buckets indexed by tick.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "Scheduler"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "SchedulerMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the scheduler bucket associated with a tick, creating it if necessary.
--
--- -----
--- @param tick integer      The tick associated with the bucket.
---
--- @return SchedulerBucket  @ Returns the scheduler bucket associated with the tick.
--
function metatable:getBucket(tick)

    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "Scheduler bucket tick must be a positive integer !")  -- [DEBUG-ONLY] . --

    local bucket = self.scheduled_jobs[tick]

    if not bucket then
        bucket = bucket_factory.new(tick)
        self.scheduled_jobs[tick] = bucket
    end

    return bucket
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ Scheduler.                                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class Scheduler: SchedulerMetatable
---
--- ### This class stores all scheduled jobs grouped by execution tick.
---
--- @field private scheduled_jobs table<integer, SchedulerBucket>      The scheduler buckets indexed by tick.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerFactory.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerFactory
---
--- ### This class groups all functions used to create schedulers.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new scheduler.
--
--- -----
--- @return Scheduler      @ Returns the created scheduler.
--
function factory.new()

    local scheduler = {      ---@type Scheduler
        scheduled_jobs = { }
    }

    setmetatable(scheduler, metatable)

    return scheduler
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
