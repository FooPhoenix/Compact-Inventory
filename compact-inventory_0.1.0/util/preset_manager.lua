-- [REFERENCE] Documentation      : https://luals.github.io/wiki/annotations/   --

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ PresetManagerMetatable.                                                                                      ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class PresetMetadata
--- @field id      integer
--- @field name    string
--- @field builtin boolean
---

---
--- @class Preset
--- @field id      integer
--- @field name    string
--- @field builtin boolean
--- @field data    table
---

---
--- @class PresetStorage
--- @field next_id integer
--- @field presets table<integer, Preset>
---

---
--- @class PresetManagerMetatable
---
--- ### This class manages named presets without knowing or depending on their data format.
---
--- Preset data is always copied when crossing the manager boundary. Callers can freely modify loaded data without
--- mutating the stored preset, and saving external data never keeps references owned by the caller.
---
--- @field private storage PresetStorage      The persistent storage namespace managed by this instance.
---
--
local metatable = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

metatable.object_name = "PresetManager"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

script.register_metatable(MOD_PREFIX .. "PresetManagerMetatable", metatable)
metatable.__index = metatable

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function deepCopy(value, copies)
    if type(value) ~= "table" then
        return value
    end

    copies = copies or { }

    if copies[value] then
        return copies[value]
    end

    local copy = { }
    copies[value] = copy

    for key, nested_value in pairs(value) do
        copy[deepCopy(key, copies)] = deepCopy(nested_value, copies)
    end

    return copy
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function findPresetByName(storage, name)
    for _, preset in pairs(storage.presets) do
        if preset.name == name then
            return preset
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getAvailableName(storage, base_name)
    if not findPresetByName(storage, base_name) then
        return base_name
    end

    local suffix = 1
    local name

    repeat
        name = base_name .. " (" .. suffix .. ")"
        suffix = suffix + 1
    until not findPresetByName(storage, name)

    return name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function createPreset(storage, name, data)
    local id = storage.next_id

    storage.next_id = id + 1
    storage.presets[id] = {
        id      = id,
        name    = name,
        builtin = false,
        data    = deepCopy(data)
    }

    return name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Load a preset by name.
--
--- The returned data is a deep copy and can be modified freely by the caller.
--
--- -----
--- @param name string      The preset name.
---
--- @return table?          @ A deep copy of the preset data, or nil when the preset does not exist.
--
function metatable:load(name)

    assert(type(name) == "string" and name ~= "", "Preset name must be a non-empty string !")      -- [DEBUG-ONLY] . --

    local preset = findPresetByName(self.storage, name)

    return preset and deepCopy(preset.data) or nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Save preset data under a name.
--
--- Existing user presets are overwritten. Builtin presets are immutable and automatically create a user copy using
--- the first available `name (n)` variant instead.
--
--- -----
--- @param name string      The requested preset name.
--- @param data table       The preset data to store.
---
--- @return string          @ The actual name used to save the preset.
--
function metatable:save(name, data)

    assert(type(name) == "string" and name ~= "", "Preset name must be a non-empty string !")      -- [DEBUG-ONLY] . --
    assert(type(data) == "table", "Preset data must be a table !")                                  -- [DEBUG-ONLY] . --

    local preset = findPresetByName(self.storage, name)

    if not preset then
        return createPreset(self.storage, name, data)
    end

    if preset.builtin then
        return createPreset(self.storage, getAvailableName(self.storage, name), data)
    end

    preset.data = deepCopy(data)

    return preset.name
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Delete a user preset by name.
--
--- Builtin presets are immutable and cannot be deleted.
--
--- -----
--- @param name string      The preset name.
---
--- @return boolean         @ True when a preset was deleted, false when it does not exist or is builtin.
--
function metatable:delete(name)

    assert(type(name) == "string" and name ~= "", "Preset name must be a non-empty string !")      -- [DEBUG-ONLY] . --

    local preset = findPresetByName(self.storage, name)

    if not preset or preset.builtin then
        return false
    end

    self.storage.presets[preset.id] = nil

    return true
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### List all available presets without exposing their stored data.
--
--- -----
--- @return PresetMetadata[]      @ Preset metadata ordered by stable identifier.
--
function metatable:list()

    local metadata = { }

    for _, preset in pairs(self.storage.presets) do
        metadata[#metadata + 1] = {
            id      = preset.id,
            name    = preset.name,
            builtin = preset.builtin
        }
    end

    table.sort(metadata, function(preset_a, preset_b)
        return preset_a.id < preset_b.id
    end)

    return metadata
end

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ PresetManager.                                                                                                ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

---
--- @class PresetManager: PresetManagerMetatable
---
--- ### This class manages one persistent namespace of format-agnostic presets.
---

-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗ --
-- ║ PresetManagerFactory.                                                                                         ║ --
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝ --

local factory = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

--- ### Create a preset manager bound to a persistent storage namespace.
--
--- An empty namespace is initialized automatically. The manager keeps the namespace by reference, therefore every
--- change is persisted directly in the supplied storage table.
--
--- -----
--- @param storage table      The persistent storage namespace owned by this manager.
---
--- @return PresetManager     @ The created preset manager.
--
function factory.new(storage)

    assert(type(storage) == "table", "Preset manager storage must be a table !")      -- [DEBUG-ONLY] . --

    if storage.next_id == nil then
        storage.next_id = 1
    end

    if storage.presets == nil then
        storage.presets = { }
    end

    assert(type(storage.next_id) == "number" and storage.next_id > 0 and storage.next_id % 1 == 0, "Preset storage next ID must be a positive integer !")      -- [DEBUG-ONLY] . --
    assert(type(storage.presets) == "table", "Preset storage presets must be a table !")                                                     -- [DEBUG-ONLY] . --

    local manager = {                ---@type PresetManager
        storage = storage
    }

    setmetatable(manager, metatable)

    return manager
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return factory
