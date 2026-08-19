-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ HoverTrackerMetatable.                                                                                        ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class HoverTrackerMetatable
---
--- ### This class tracks hover state for GUI elements that close after the mouse leaves them.
---
--- @field private waiting_for_reenter boolean      Whether leave events must be ignored until the next hover.
--- @field private last_event          string?      The last tracked event name.
--- @field private last_event_tick     integer?     The tick of the last tracked event.
---
--
local metatable = { }

metatable.object_name = "HoverTracker"
script.register_metatable(MOD_PREFIX .. "HoverTrackerMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:onHover(tick)
    assert(type(tick) == "number", "Hover tick must be a number !")      -- [DEBUG-ONLY] . --

    self.waiting_for_reenter = false
    self.last_event          = "HOVER"
    self.last_event_tick     = tick
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:onLeave(tick)
    assert(type(tick) == "number", "Leave tick must be a number !")      -- [DEBUG-ONLY] . --

    if self.waiting_for_reenter then
        return
    end

    self.last_event      = "LEAVE"
    self.last_event_tick = tick
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:suspendUntilReenter()
    self.waiting_for_reenter = true
    self.last_event          = nil
    self.last_event_tick     = nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function metatable:shouldClose(tick)
    assert(type(tick) == "number", "Current tick must be a number !")      -- [DEBUG-ONLY] . --

    return not self.waiting_for_reenter
        and self.last_event == "LEAVE"
        and self.last_event_tick == tick - 1
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ HoverTrackerFactory.                                                                                          ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a new hover tracker.
--
--- -----
--- @return HoverTracker      @ Returns the created hover tracker.
--
function factory.new()
    local tracker = {                                      ---@type HoverTracker
        waiting_for_reenter = false,
        last_event          = nil,
        last_event_tick     = nil
    }

    setmetatable(tracker, metatable)

    return tracker
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
