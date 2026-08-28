
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerBucketMetatable.                                                                                     ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerBucketMetatable
---
--- ### This class groups all functions used to manage a scheduler bucket.
---
--- @field private tick integer          The tick associated with the bucket.
--- @field private jobs SchedulerJob[]   The jobs scheduled for the tick.
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
--- @field private tick integer          The tick associated with the bucket.
--- @field private jobs SchedulerJob[]   The jobs scheduled for the tick.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ SchedulerJob.                                                                                                 ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class SchedulerJob
---
--- ### This class describes the scheduling data shared by all scheduler jobs.
---
--- @field         next_tick      integer?           The next tick requested by the job owner, or nil to unregister it.
--- @field private current_bucket SchedulerBucket?   The bucket currently containing the job. Managed only by Scheduler.
--- @field         execute        fun(self: SchedulerJob, tick: integer)      Executes the job and updates its next requested tick.
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
--- @param scheduler Scheduler      The scheduler owning the bucket.
--- @param tick      integer        The tick associated with the bucket.
---
--- @return SchedulerBucket         @ Returns the scheduler bucket associated with the tick.
--
local function getBucket(scheduler, tick)

    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "Scheduler bucket tick must be a positive integer !")  -- [DEBUG-ONLY] . --

    local bucket = scheduler.scheduled_jobs[tick]

    if not bucket then
        bucket = bucket_factory.new(tick)
        scheduler.scheduled_jobs[tick] = bucket
    end

    return bucket
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Register a job according to its requested next tick.
---
--- The job owner only manages `next_tick`. The scheduler exclusively manages `current_bucket` and moves the job
--- between buckets when required. Setting `next_tick` to nil unregisters the job.
--
--- -----
--- @param job SchedulerJob      The job to register, move or unregister.
--
function metatable:register(job)

    assert(type(job) == "table", "Scheduler job must be a table !")                                                                                      -- [DEBUG-ONLY] . --
    assert(job.next_tick == nil or (type(job.next_tick) == "number" and job.next_tick >= 0 and job.next_tick % 1 == 0), "Scheduler job next tick must be nil or a positive integer !")  -- [DEBUG-ONLY] . --

    local current_bucket = job.current_bucket
    local next_tick      = job.next_tick

    if current_bucket and current_bucket.tick == next_tick then
        return
    end

    if current_bucket then
        assert(self.scheduled_jobs[current_bucket.tick] == current_bucket, "Scheduler job current bucket must belong to this Scheduler !")      -- [DEBUG-ONLY] . --

        local removed = false

        for index, scheduled_job in ipairs(current_bucket.jobs) do
            if scheduled_job == job then
                table.remove(current_bucket.jobs, index)
                removed = true
                break
            end
        end

        assert(removed, "Scheduler job must exist in its current bucket !")      -- [DEBUG-ONLY] . --

        job.current_bucket = nil

        if #current_bucket.jobs == 0 then
            self.scheduled_jobs[current_bucket.tick] = nil
        end
    end

    if next_tick == nil then
        return
    end

    local bucket = getBucket(self, next_tick)

    bucket.jobs[#bucket.jobs + 1] = job
    job.current_bucket = bucket
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Execute all jobs scheduled for a tick.
---
--- The current bucket is detached before any job executes. This allows jobs to request their next tick without
--- mutating the bucket being iterated. Each job is re-registered after execution according to its new `next_tick`.
--
--- -----
--- @param tick integer      The tick to execute.
--
function metatable:execute(tick)
    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "Scheduler execution tick must be a positive integer !")      -- [DEBUG-ONLY] . --

    local bucket = self.scheduled_jobs[tick]

    if not bucket then
        return
    end

    self.scheduled_jobs[tick] = nil

    local jobs = bucket.jobs
    bucket.jobs = { }

    for _, job in ipairs(jobs) do
        assert(job.current_bucket == bucket, "Scheduled job must belong to the executed bucket !")      -- [DEBUG-ONLY] . --
        assert(type(job.execute) == "function", "Scheduled job must provide an execute method !")       -- [DEBUG-ONLY] . --
        job.current_bucket = nil
    end

    for _, job in ipairs(jobs) do
        job:execute(tick)
        self:register(job)
    end
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

--- ### Initialize the persistent scheduler.
--
function factory.initialize()
    storage.scheduler = factory.new()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the persistent scheduler.
--
--- -----
--- @return Scheduler      @ Returns the persistent scheduler.
--
function factory.get()
    assert(storage.scheduler and storage.scheduler.object_name == "Scheduler", "Scheduler must be initialized !")      -- [DEBUG-ONLY] . --
    return storage.scheduler
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
