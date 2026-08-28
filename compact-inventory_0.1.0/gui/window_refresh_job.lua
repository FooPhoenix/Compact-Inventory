
-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ WindowRefreshJobMetatable.                                                                                    ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class WindowRefreshJobMetatable
---
--- ### This class groups all functions used to manage a scheduled InventoryWindow refresh.
---
--- @field private window         InventoryWindow      The InventoryWindow associated with the job.
--- @field         next_tick      integer?             The next tick requested by the InventoryWindow.
--- @field private current_bucket SchedulerBucket?     The SchedulerBucket currently containing the job. Managed only by Scheduler.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "WindowRefreshJob"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "WindowRefreshJobMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Get the InventoryWindow associated with the job.
--
--- -----
--- @return InventoryWindow      @ Returns the InventoryWindow associated with the job.
--
function metatable:getWindow()

    assert(self.window and self.window.object_name == "InventoryWindow", "WindowRefreshJob must have a valid InventoryWindow !")      -- [DEBUG-ONLY] . --

    return self.window
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ WindowRefreshJob.                                                                                             ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class WindowRefreshJob: WindowRefreshJobMetatable
---
--- ### This class represents a scheduled InventoryWindow refresh job.
---
--- @field private window         InventoryWindow      The InventoryWindow associated with the job.
--- @field         next_tick      integer?             The next tick requested by the InventoryWindow.
--- @field private current_bucket SchedulerBucket?     The SchedulerBucket currently containing the job. Managed only by Scheduler.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ WindowRefreshJobFactory.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class WindowRefreshJobFactory
---
--- ### This class groups all functions used to create window refresh jobs.
---
local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new window refresh job.
--
--- -----
--- @param window InventoryWindow      The InventoryWindow associated with the job.
---
--- @return WindowRefreshJob           @ Returns the created window refresh job.
--
function factory.new(window)

    assert(window and window.object_name == "InventoryWindow", "WindowRefreshJob requires a valid InventoryWindow !")      -- [DEBUG-ONLY] . --

    local job = {      ---@type WindowRefreshJob
        window         = window,
        next_tick      = game.tick + window:getRefreshRate(),
        current_bucket = nil
    }

    setmetatable(job, metatable)

    return job
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
