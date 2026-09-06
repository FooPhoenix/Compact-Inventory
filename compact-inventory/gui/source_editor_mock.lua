-- [TRANSITION] Temporary compatibility router while control.lua is migrated to MainWindow's source editor API. --

local SourceEditorCompatibility = {
    exposed_gui_names = {
        slot_button            = MOD_PREFIX .. "MW_source-slot-button",
        selector_cancel_button = MOD_PREFIX .. "MW_source-selector-cancel",
        selector_add_button    = MOD_PREFIX .. "MW_source-selector-add"
    }
}

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorCompatibility.showEditor(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --
    main_window:showSourceEditor()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorCompatibility.showSelector(main_window)
    assert(main_window and main_window.object_name == "MainWindow", "Main window must exist here !")      -- [DEBUG-ONLY] . --
    main_window:showSourceSelector()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function SourceEditorCompatibility.render(_)
    -- MainWindow now owns and builds the source editor directly.
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return SourceEditorCompatibility