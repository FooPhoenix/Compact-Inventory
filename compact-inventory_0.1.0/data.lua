
-- [CHANGELOG] 2026.08.08-11:53 Changed UI :: Make internal names more resilient to mod conflicts. --

data:extend({
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-standard",
        filename = "__compact-inventory__/graphics/sort-standard.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-count-asc",
        filename = "__compact-inventory__/graphics/sort-by-count-asc.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-count-desc",
        filename = "__compact-inventory__/graphics/sort-by-count-desc.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-inventory",
        filename = "__compact-inventory__/graphics/sort-inventory.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-last-change",
        filename = "__compact-inventory__/graphics/sort-last-change.png",
        size = 16,
        x = 32
    },
    {
        type = "sprite",
        name = "FooPhoenix_CI_sort-custom",
        filename = "__compact-inventory__/graphics/sort-custom.png",
        size = 16,
        x = 32
    },
    {
        type = "shortcut",
        name = "FooPhoenix_CI_main-window-toggle",
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
