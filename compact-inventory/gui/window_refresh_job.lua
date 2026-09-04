
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

local function getRefreshRate(window)
    local refresh_rate = window.refresh_rate

    assert(type(refresh_rate) == "number" and refresh_rate > 0 and refresh_rate % 1 == 0, "InventoryWindow refresh rate must be a positive integer !")      -- [DEBUG-ONLY] . --

    return refresh_rate
end

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

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Execute the scheduled window refresh.
--
--- -----
--- @param tick integer      The tick being executed by the Scheduler.
--
function metatable:execute(tick)
    assert(type(tick) == "number" and tick >= 0 and tick % 1 == 0, "WindowRefreshJob execution tick must be a positive integer !")      -- [DEBUG-ONLY] . --

    local window = self:getWindow()

    if not window.valid then
        self.next_tick = nil
        return
    end

    window:getInventory():update()

    if window:isVisible() then
        window:refresh()
    end

    self.next_tick = tick + getRefreshRate(window)
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
--
--- @return WindowRefreshJob           @ Returns the created WindowRefreshJob.
--
function factory.new(window)

    assert(window and window.object_name == "InventoryWindow", "WindowRefreshJob requires a valid InventoryWindow !")      -- [DEBUG-ONLY] . --

    local job = {      ---@type WindowRefreshJob
        window         = window,
        next_tick      = game.tick + getRefreshRate(window),
        current_bucket = nil
    }

    setmetatable(job, metatable)

    return job
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
