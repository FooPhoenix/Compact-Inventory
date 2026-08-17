
local MOD_PREFIX = "FooPhoenix_CI_"

data:extend({
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-standard",
        filename = "__compact-inventory__/graphics/sort-standard.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-count-asc",
        filename = "__compact-inventory__/graphics/sort-by-count-asc.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-count-desc",
        filename = "__compact-inventory__/graphics/sort-by-count-desc.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-inventory",
        filename = "__compact-inventory__/graphics/sort-inventory.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-last-change",
        filename = "__compact-inventory__/graphics/sort-last-change.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "sort-custom",
        filename = "__compact-inventory__/graphics/sort-custom.png",
        size = 16,
        x = 32
    },
    {
        type = "shortcut",
        name = MOD_PREFIX .. "main-window-toggle",
        action = "lua",
        toggleable = true,
        localised_name = "Compact inventory",
        icons = {
            {
                icon = "__base__/graphics/icons/signal/signal_I.png",
                icon_size = 64
            }
        },
        small_icons = {
            {
                icon = "__base__/graphics/icons/signal/signal_I.png",
                icon_size = 64
            }
        }
    }
})

local function addSortDropdownStyle(name, filename)
    data.raw["gui-style"].default[MOD_PREFIX .. name] = {
        type   = "dropdown_style",
        parent = "dropdown",
        icon   = {
            filename = filename,
            size     = 16,
            x        = 32
        }
    }
end

addSortDropdownStyle("sort-dropdown-standard",    "__compact-inventory__/graphics/sort-standard.png")
addSortDropdownStyle("sort-dropdown-count-asc",   "__compact-inventory__/graphics/sort-by-count-asc.png")
addSortDropdownStyle("sort-dropdown-count-desc",  "__compact-inventory__/graphics/sort-by-count-desc.png")
addSortDropdownStyle("sort-dropdown-inventory",   "__compact-inventory__/graphics/sort-inventory.png")
addSortDropdownStyle("sort-dropdown-last-change", "__compact-inventory__/graphics/sort-last-change.png")
addSortDropdownStyle("sort-dropdown-custom",      "__compact-inventory__/graphics/sort-custom.png")
