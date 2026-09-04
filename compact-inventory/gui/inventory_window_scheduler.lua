
local SchedulerFactory        = require("util.scheduler")
local WindowRefreshJobFactory = require("gui.window_refresh_job")

-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

local DEFAULT_REFRESH_RATE = 10

local integration = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Ensure that an InventoryWindow owns a registered refresh job.
--
--- This is also used by the debug GUI rebuild path to upgrade persisted windows created before refresh jobs existed.
--
--- -----
--- @param window InventoryWindow      The InventoryWindow to initialize or repair.
--
function integration.ensure(window)
    assert(window and window.object_name == "InventoryWindow", "Window does not exist or is invalid !")      -- [DEBUG-ONLY] . --

    if window.refresh_rate == nil then
        window.refresh_rate = DEFAULT_REFRESH_RATE
    end

    assert(type(window.refresh_rate) == "number" and window.refresh_rate > 0 and window.refresh_rate % 1 == 0, "InventoryWindow refresh rate must be a positive integer !")      -- [DEBUG-ONLY] . --

    if not storage.scheduler then
        SchedulerFactory.initialize()
    end

    if not window.refresh_job then
        window.refresh_job = WindowRefreshJobFactory.new(window)
    end

    SchedulerFactory.get():register(window.refresh_job)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function integration.install(inventory_window_factory)
    assert(type(inventory_window_factory) == "table", "InventoryWindowFactory must be a table !")      -- [DEBUG-ONLY] . --

    local create  = inventory_window_factory.create
    local destroy = inventory_window_factory.destroy

    assert(type(create) == "function" and type(destroy) == "function", "InventoryWindowFactory lifecycle must exist !")      -- [DEBUG-ONLY] . --

    inventory_window_factory.create = function(...)
        local window = create(...)

        integration.ensure(window)

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
