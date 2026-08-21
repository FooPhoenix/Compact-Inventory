
local MOD_PREFIX = "FooPhoenix_CI_"

local gui_style = data.raw["gui-style"].default

gui_style[MOD_PREFIX .. "locked-window-frame"] = {
    type                     = "frame_style",
    parent                   = "frame",
    graphical_set            = { },
    background_graphical_set = { },
    header_background        = { },
    padding                  = 0
}

gui_style[MOD_PREFIX .. "locked-content-frame"] = {
    type                     = "frame_style",
    parent                   = "inside_shallow_frame",
    graphical_set            = { },
    background_graphical_set = { },
    header_background        = { },
    padding                  = 0
}

gui_style[MOD_PREFIX .. "tree-label-button"] = {
    type               = "button_style",
    parent             = "transparent_button",
    padding            = 0,
    minimal_width      = 0,
    minimal_height     = 0,
    default_font_color = { 1, 1, 1 },
    hovered_font_color = { 1, 1, 1 },
    clicked_font_color = { 1, 1, 1 }
}

gui_style[MOD_PREFIX .. "tree-toggle-button"] = {
    type           = "button_style",
    parent         = "transparent_button",
    padding        = 0,
    minimal_width  = 0,
    minimal_height = 0
}

data:extend({
    {
        type = "sprite",
        name = MOD_PREFIX .. "cancel",
        filename = "__core__/graphics/cancel.png",
        size = 64
    },
    {
        type         = "sprite",
        name         = MOD_PREFIX .. "tree-expand",
        filename     = "__compact-inventory__/graphics/treeview_expand_slim.png",
        width        = 32,
        height       = 16,
        mipmap_count = 2,
        flags        = { "gui-icon" },
        scale        = 0.5
    },
    {
        type         = "sprite",
        name         = MOD_PREFIX .. "tree-collapse",
        filename     = "__compact-inventory__/graphics/treeview_collapse_slim.png",
        width        = 32,
        height       = 16,
        mipmap_count = 2,
        flags        = { "gui-icon" },
        scale        = 0.5
    },
    {
        type     = "sprite",
        name     = MOD_PREFIX .. "window-show",
        filename = "__compact-inventory__/graphics/Show_Grey.png",
        size     = 32,
        flags    = { "gui-icon" },
        scale    = 0.5
    },
    {
        type     = "sprite",
        name     = MOD_PREFIX .. "window-show-hover",
        filename = "__compact-inventory__/graphics/Show_Black.png",
        size     = 32,
        flags    = { "gui-icon" },
        scale    = 0.5
    },
    {
        type     = "sprite",
        name     = MOD_PREFIX .. "window-hide",
        filename = "__compact-inventory__/graphics/Hide_Gray.png",
        size     = 32,
        flags    = { "gui-icon" },
        scale    = 0.5
    },
    {
        type     = "sprite",
        name     = MOD_PREFIX .. "window-hide-hover",
        filename = "__compact-inventory__/graphics/Hide_Black.png",
        size     = 32,
        flags    = { "gui-icon" },
        scale    = 0.5
    },
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
        type = "sprite",
        name = MOD_PREFIX .. "group-menu",
        filename = "__core__/graphics/icons/mip/open-panel-options-8x16-white.png",
        width = 8,
        height = 16
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
