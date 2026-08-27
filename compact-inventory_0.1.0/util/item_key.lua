
local SEPARATOR = "\31"

local ItemKey = { }

function ItemKey.create(item_name, quality_name)
    assert(type(item_name) == "string" and item_name ~= "", "Item name must be a non-empty string !")      -- [DEBUG-ONLY] . --
    assert(quality_name == nil or type(quality_name) == "string", "Quality name must be a string or nil !") -- [DEBUG-ONLY] . --

    return item_name .. SEPARATOR .. (quality_name or "")
end

function ItemKey.split(item_key)
    assert(type(item_key) == "string", "Item key must be a string !")      -- [DEBUG-ONLY] . --

    local separator_index = item_key:find(SEPARATOR, 1, true)

    assert(separator_index, "Item key separator is missing !")      -- [DEBUG-ONLY] . --

    if not separator_index then
        return item_key, nil
    end

    local item_name    = item_key:sub(1, separator_index - 1)
    local quality_name = item_key:sub(separator_index + 1)

    return item_name, quality_name ~= "" and quality_name or nil
end

function ItemKey.exists(item_key)
    local item_name, quality_name = ItemKey.split(item_key)

    if not prototypes.item[item_name] then
        return false
    end

    return quality_name == nil or prototypes.quality[quality_name] ~= nil
end

return ItemKey
