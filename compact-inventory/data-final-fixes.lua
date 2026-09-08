local EntityPrototypeList = require("prototype.entity_prototype_list")

local MOD_PREFIX = "FooPhoenix_CI_"

local vehicle_names = EntityPrototypeList.build({
    types = {
        "car",
        "spider-vehicle"
    },
    filter = function(prototype)
        return prototype.selectable_in_game ~= false
    end
})

local vehicle_selection = {
    border_color       = { 0.3, 0.9, 1.0 },
    cursor_box_type    = "entity",
    mode               = { "any-entity" },
    entity_filter_mode = "whitelist",
    entity_filters     = vehicle_names
}

data:extend({
    {
        type                    = "selection-tool",
        name                    = MOD_PREFIX .. "vehicle-selection-tool",
        icon                    = "__base__/graphics/icons/car.png",
        icon_size               = 64,
        stack_size              = 1,
        flags                   = { "only-in-cursor", "not-stackable" },
        hidden                  = true,
        hidden_in_factoriopedia = true,
        select                  = vehicle_selection,
        alt_select              = vehicle_selection
    }
})
