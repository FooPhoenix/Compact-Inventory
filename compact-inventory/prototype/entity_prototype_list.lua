local EntityPrototypeList = { }

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

function EntityPrototypeList.build(options)
    assert(type(options) == "table", "Entity prototype list options must be a table !")
    assert(type(options.types) == "table" and #options.types > 0, "Entity prototype list requires at least one prototype type !")
    assert(options.filter == nil or type(options.filter) == "function", "Entity prototype list filter must be a function !")

    local names  = { }
    local lookup = { }
    local filter = options.filter

    for _, prototype_type in ipairs(options.types) do
        assert(type(prototype_type) == "string" and prototype_type ~= "", "Entity prototype type must be a non-empty string !")

        for name, prototype in pairs(data.raw[prototype_type] or { }) do
            if not lookup[name] and (not filter or filter(prototype, prototype_type)) then
                names[#names + 1] = name
                lookup[name] = true
            end
        end
    end

    table.sort(names)

    return names
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ --

return EntityPrototypeList
