-- Source types describe how an InventorySource resolves the objects that can provide inventory content.
-- `player` is implemented. `vehicle` is reserved for explicit vehicle selection, distinct from a player's current vehicle.
-- The remaining values reserve the descriptive model used by future source resolvers.
local SourceType = {
    player           = "player",
    vehicle          = "vehicle",
    entities         = "entities",
    logistic_network = "logistic_network",
    train_stop       = "train_stop",
    train_path       = "train_path"
}

return SourceType
