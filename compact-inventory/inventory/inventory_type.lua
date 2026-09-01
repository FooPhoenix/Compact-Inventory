-- Static types reuse Factorio inventory IDs when the semantic meaning is identical. Dynamic types use mod-owned IDs
-- because their concrete LuaInventory depends on the source owner and current physical context.
-- Character/vehicle types always refer to the selected LuaPlayer or LuaEntity, not necessarily the local player.
local InventoryType = {
    character_main  = defines.inventory.character_main,
    character_ammo  = defines.inventory.character_ammo,
    character_guns  = defines.inventory.character_guns,
    character_armor = defines.inventory.character_armor,
    character_trash = defines.inventory.character_trash,

    vehicle_main  = "vehicle_main",
    vehicle_ammo  = "vehicle_ammo",
    vehicle_trash = "vehicle_trash",
    vehicle_fuel  = "vehicle_fuel",

    chest_main  = defines.inventory.chest,
    chest_trash = defines.inventory.logistic_container_trash,

    train_cargo = "train_cargo",
    train_fuel  = "train_fuel"
}

return InventoryType
