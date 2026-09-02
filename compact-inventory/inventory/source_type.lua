-- Source types describe how an InventorySource resolves the objects that can provide inventory content.
-- Only `player` is implemented for now. The remaining values reserve the descriptive model used by future source resolvers.
local SourceType = {
    player           = "player",
    entities         = "entities",
    logistic_network = "logistic_network",
    train_stop       = "train_stop",
    train_path       = "train_path"
}

return SourceType
