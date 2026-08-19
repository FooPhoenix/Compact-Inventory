
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
        type = "sprite",
        name = MOD_PREFIX .. "window-unlock",
        filename = "__base__/graphics/icons/signal/signal-unlock.png",
        size = 64
    },
    {
        type = "sprite",
        name = MOD_PREFIX .. "group-delete",
        filename = "__base__/graphics/icons/signal/signal-trash-bin.png",
        size = 64
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
