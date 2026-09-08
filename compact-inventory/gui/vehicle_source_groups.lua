local SourceType          = require("inventory.source_type")
local EntityPreviewWindow = require("gui.entity_preview_window")

local VehicleSourceGroups = { }

local GUI_NAME = {
    source_editor_column      = MOD_PREFIX .. "MW_source-editor-column",
    source_table              = MOD_PREFIX .. "MW_source-table",
    source_table_scroll       = MOD_PREFIX .. "MW_source-table-scroll",
    source_selector_column    = MOD_PREFIX .. "MW_source-selector-column",
    source_selector_actions   = MOD_PREFIX .. "MW_source-selector-actions",
    source_selector_add       = MOD_PREFIX .. "MW_source-selector-add",
    selector_vehicle_table    = MOD_PREFIX .. "MW_source-selector-vehicle-table"
}

local TARGET_PROTOTYPE_TAG = MOD_PREFIX .. "MW_SourceTargetPrototype"
local SOURCE_VISIBLE_ROWS  = 10
local SOURCE_ROW_HEIGHT    = 44
local SOURCE_HEADER_HEIGHT = 28
local SOURCE_SLOT_COLUMNS  = 10

local installed = false

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function findGuiElement(parent, name)
    if parent.name == name then
        return parent
    end

    for _, child in ipairs(parent.children) do
        local found = findGuiElement(child, name)

        if found then
            return found
        end
    end

    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function copyArray(values)
    local result = { }

    for index, value in ipairs(values or { }) do
        result[index] = value
    end

    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function ensureSourceTableScroll(main_window)
    local source_table = findGuiElement(main_window:getFrame(), GUI_NAME.source_table)

    assert(source_table, "Source editor table must exist here !")      -- [DEBUG-ONLY] . --

    if source_table.parent.type == "scroll-pane" then
        return source_table
    end

    local parent = source_table.parent

    source_table.destroy()

    local scroll = parent.add({
        type                     = "scroll-pane",
        name                     = GUI_NAME.source_table_scroll,
        direction                = "vertical",
        vertical_scroll_policy   = "auto",
        horizontal_scroll_policy = "never"
    })

    scroll.style.padding                  = 0
    scroll.style.maximal_height           = SOURCE_HEADER_HEIGHT + SOURCE_VISIBLE_ROWS * SOURCE_ROW_HEIGHT
    scroll.style.horizontally_stretchable = true

    source_table = scroll.add({
        type                  = "table",
        name                  = GUI_NAME.source_table,
        column_count          = 2,
        style                 = MOD_PREFIX .. "source-editor-table",
        draw_horizontal_lines = true
    })

    source_table.style.horizontal_spacing       = 6
    source_table.style.vertical_spacing         = 4
    source_table.style.horizontally_stretchable = true

    return source_table
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function addGroupedSourceSlot(parent, source_editor_controller, source_index, prototype_name, count)
    local wrapper = parent.add({
        type      = "flow",
        direction = "horizontal"
    })

    return wrapper.add({
        type    = "sprite-button",
        name    = source_editor_controller.exposed_gui_names.source_slot_button,
        style   = "slot_button",
        sprite  = "entity/" .. prototype_name,
        number  = count > 1 and count or nil,
        tooltip = count > 1 and prototype_name .. " × " .. count or prototype_name,
        tags    = {
            [source_editor_controller.exposed_gui_names.source_index_tag_name] = source_index,
            [TARGET_PROTOTYPE_TAG] = prototype_name
        }
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function compactVehicleSources(main_window, source_editor_controller)
    local source_table  = findGuiElement(main_window:getFrame(), GUI_NAME.source_table)
    local configuration = main_window.editor_state and main_window.editor_state.configuration

    assert(source_table and configuration, "Source editor table and configuration must exist here !")      -- [DEBUG-ONLY] . --

    for source_index, source in ipairs(configuration.sources or { }) do
        if source.type == SourceType.vehicle then
            local source_cell = source_table.children[source_index * 2 + 1]

            assert(source_cell and source_cell.type == "table", "Vehicle source cell must exist here !")      -- [DEBUG-ONLY] . --

            local groups = { }
            local lookup = { }

            for _, lua_vehicle in ipairs(source.vehicles or { }) do
                if lua_vehicle and lua_vehicle.valid and lua_vehicle.object_name == "LuaEntity" then
                    local group = lookup[lua_vehicle.name]

                    if not group then
                        group = {
                            name  = lua_vehicle.name,
                            count = 0
                        }

                        lookup[lua_vehicle.name] = group
                        groups[#groups + 1] = group
                    end

                    group.count = group.count + 1
                end
            end

            source_cell.clear()

            for _, group in ipairs(groups) do
                addGroupedSourceSlot(source_cell, source_editor_controller, source_index, group.name, group.count)
            end

            local wrapper = source_cell.add({
                type      = "flow",
                direction = "horizontal"
            })

            wrapper.add({
                type    = "sprite-button",
                name    = source_editor_controller.exposed_gui_names.source_slot_button,
                style   = "slot_button",
                tooltip = "Add source target",
                tags    = {
                    [source_editor_controller.exposed_gui_names.source_index_tag_name] = source_index
                }
            })
        end
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function renderVehicleDraft(main_window, source_selector_controller)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state
    local vehicle_draft  = selector_state and selector_state.drafts and selector_state.drafts[SourceType.vehicle]
    local vehicle_table  = findGuiElement(main_window:getFrame(), GUI_NAME.selector_vehicle_table)

    assert(vehicle_draft and vehicle_table, "Vehicle selector draft and table must exist here !")      -- [DEBUG-ONLY] . --

    vehicle_table.clear()

    for vehicle_index, lua_vehicle in ipairs(vehicle_draft.vehicles) do
        if lua_vehicle and lua_vehicle.valid and lua_vehicle.object_name == "LuaEntity" then
            local wrapper = vehicle_table.add({
                type      = "flow",
                direction = "horizontal"
            })

            wrapper.add({
                type               = "sprite-button",
                name               = source_selector_controller.exposed_gui_names.vehicle_slot_button,
                style              = "slot_button",
                sprite             = "entity/" .. lua_vehicle.name,
                tooltip            = lua_vehicle.name,
                raise_hover_events = true,
                tags               = {
                    [source_selector_controller.exposed_gui_names.vehicle_index_tag_name] = vehicle_index
                }
            })
        end
    end

    local wrapper = vehicle_table.add({
        type      = "flow",
        direction = "horizontal"
    })

    wrapper.add({
        type    = "sprite-button",
        name    = source_selector_controller.exposed_gui_names.vehicle_slot_button,
        style   = "slot_button",
        tooltip = "Add vehicle",
        tags    = { }
    })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function refreshVehicleConfirm(main_window)
    local selector_state = main_window.editor_state and main_window.editor_state.selector_state
    local selector       = findGuiElement(main_window:getFrame(), GUI_NAME.source_selector_column)
    local actions        = selector and selector[GUI_NAME.source_selector_actions]
    local add_button     = actions and actions[GUI_NAME.source_selector_add]
    local vehicle_draft  = selector_state and selector_state.drafts and selector_state.drafts[SourceType.vehicle]

    assert(add_button and vehicle_draft, "Vehicle selector controls and draft must exist here !")      -- [DEBUG-ONLY] . --

    add_button.enabled = selector_state.target_prototype ~= nil or #vehicle_draft.vehicles > 0
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function getVehicleGroup(source, prototype_name)
    local vehicles = { }

    for _, lua_vehicle in ipairs(source and source.vehicles or { }) do
        if lua_vehicle and lua_vehicle.valid and lua_vehicle.object_name == "LuaEntity" and lua_vehicle.name == prototype_name then
            vehicles[#vehicles + 1] = lua_vehicle
        end
    end

    return vehicles
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function vehicleExistsOutsideTarget(configuration, lua_vehicle, source_index, target_prototype)
    for current_source_index, source in ipairs(configuration.sources or { }) do
        if source.type == SourceType.vehicle then
            for _, existing_vehicle in ipairs(source.vehicles or { }) do
                local ignored = current_source_index == source_index
                    and target_prototype ~= nil
                    and existing_vehicle.name == target_prototype

                if not ignored and existing_vehicle == lua_vehicle then
                    return true
                end
            end
        end
    end

    return false
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

local function filterSelectedVehicles(configuration, vehicles, source_index, target_prototype)
    local result = { }

    for _, lua_vehicle in ipairs(vehicles) do
        if lua_vehicle and lua_vehicle.valid and lua_vehicle.object_name == "LuaEntity"
            and not vehicleExistsOutsideTarget(configuration, lua_vehicle, source_index, target_prototype) then

            local duplicate = false

            for _, selected_vehicle in ipairs(result) do
                if selected_vehicle == lua_vehicle then
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                result[#result + 1] = lua_vehicle
            end
        end
    end

    return result
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function VehicleSourceGroups.install(source_editor_controller, source_selector_controller)
    if installed then
        return
    end

    installed = true
    source_editor_controller.exposed_gui_names.source_target_prototype_tag_name = TARGET_PROTOTYPE_TAG

    local original_editor_refresh = source_editor_controller.refresh

    source_editor_controller.refresh = function(main_window)
        ensureSourceTableScroll(main_window)
        original_editor_refresh(main_window)
        compactVehicleSources(main_window, source_editor_controller)
    end

    local original_selector_show = source_selector_controller.show

    source_selector_controller.show = function(main_window, element)
        local source_index     = element and element.tags[source_editor_controller.exposed_gui_names.source_index_tag_name] or nil
        local target_prototype = element and element.tags[TARGET_PROTOTYPE_TAG] or nil
        local source           = source_index and main_window.editor_state.configuration.sources[source_index] or nil

        original_selector_show(main_window, element)

        local selector_state = main_window.editor_state.selector_state

        selector_state.target_prototype = target_prototype

        if selector_state.selected_type == SourceType.vehicle then
            selector_state.drafts[SourceType.vehicle].vehicles = target_prototype
                and getVehicleGroup(source, target_prototype)
                or { }

            renderVehicleDraft(main_window, source_selector_controller)
            refreshVehicleConfirm(main_window)
        end
    end

    local original_selector_add = source_selector_controller.add

    source_selector_controller.add = function(main_window)
        local editor_state   = main_window.editor_state
        local selector_state = editor_state and editor_state.selector_state

        if not selector_state or selector_state.selected_type ~= SourceType.vehicle then
            return original_selector_add(main_window)
        end

        local sources          = editor_state.configuration.sources
        local source_index     = selector_state.source_index
        local target_prototype = selector_state.target_prototype
        local source           = source_index and sources[source_index] or nil
        local draft            = selector_state.drafts[SourceType.vehicle]
        local vehicles         = filterSelectedVehicles(
            editor_state.configuration,
            draft.vehicles,
            source_index,
            target_prototype
        )

        if not target_prototype and #vehicles == 0 then
            draft.vehicles = vehicles
            renderVehicleDraft(main_window, source_selector_controller)
            refreshVehicleConfirm(main_window)
            return false
        end

        if source then
            assert(source.type == SourceType.vehicle, "Existing source must be a Vehicle source here !")      -- [DEBUG-ONLY] . --
            assert(type(source.vehicles) == "table", "Vehicle source must contain a vehicles table !")         -- [DEBUG-ONLY] . --

            if target_prototype then
                local updated = { }

                for _, lua_vehicle in ipairs(source.vehicles) do
                    if lua_vehicle.name ~= target_prototype then
                        updated[#updated + 1] = lua_vehicle
                    end
                end

                for _, lua_vehicle in ipairs(vehicles) do
                    updated[#updated + 1] = lua_vehicle
                end

                source.vehicles = updated
            else
                for _, lua_vehicle in ipairs(vehicles) do
                    source.vehicles[#source.vehicles + 1] = lua_vehicle
                end
            end
        else
            sources[#sources + 1] = {
                type            = SourceType.vehicle,
                vehicles        = copyArray(vehicles),
                inventory_types = { },
                options         = { }
            }
        end

        EntityPreviewWindow.hide(main_window:getPlayer())
        main_window:showSourceEditor()
        source_editor_controller.refresh(main_window)

        return true
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return VehicleSourceGroups
