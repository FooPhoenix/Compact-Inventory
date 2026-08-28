
local SchedulerFactory        = require("util.scheduler")
local WindowRefreshJobFactory = require("gui.window_refresh_job")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local DEFAULT_REFRESH_RATE = 10

local integration = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function installWindowMethods(window)
    local metatable = getmetatable(window)

    assert(metatable, "InventoryWindow metatable must exist here !")      -- [DEBUG-ONLY] . --

    if not metatable.getRefreshRate then
        function metatable:getRefreshRate()
            assert(type(self.refresh_rate) == "number" and self.refresh_rate > 0 and self.refresh_rate % 1 == 0, "InventoryWindow refresh rate must be a positive integer !")      -- [DEBUG-ONLY] . --
            return self.refresh_rate
        end
    end

    if not metatable.getRefreshJob then
        function metatable:getRefreshJob()
            assert(self.refresh_job and self.refresh_job.object_name == "WindowRefreshJob", "InventoryWindow must have a valid refresh job !")      -- [DEBUG-ONLY] . --
            return self.refresh_job
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function integration.install(inventory_window_factory)
    assert(type(inventory_window_factory) == "table", "InventoryWindowFactory must be a table !")      -- [DEBUG-ONLY] . --

    local create  = inventory_window_factory.create
    local destroy = inventory_window_factory.destroy

    assert(type(create) == "function" and type(destroy) == "function", "InventoryWindowFactory lifecycle must exist !")      -- [DEBUG-ONLY] . --

    inventory_window_factory.create = function(...)
        local window = create(...)

        installWindowMethods(window)

        window.refresh_rate = DEFAULT_REFRESH_RATE
        window.refresh_job  = WindowRefreshJobFactory.new(window)

        if not storage.scheduler then
            SchedulerFactory.initialize()
        end

        SchedulerFactory.get():register(window.refresh_job)

        return window
    end

    inventory_window_factory.destroy = function(window)
        assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

        if window.refresh_job then
            window.refresh_job.next_tick = nil
            SchedulerFactory.get():register(window.refresh_job)
            window.refresh_job = nil
        end

        window.refresh_rate = nil

        destroy(window)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return integration
