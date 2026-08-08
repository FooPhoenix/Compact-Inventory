
-- [CHANGELOG] 2026.08.08-11:53 Changed UI :: Make internal names more resilient to mod conflicts. --

data:extend({
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
