FarmingLiveRecipe.register("RandomTabTrap", {
    FarmingLiveRecipe.randomRange("lockMinutes", {"tabTrap", "minLockMinutes"}, {"tabTrap", "maxLockMinutes"}),
    FarmingLiveRecipe.randomRange("switchCount", {"tabTrap", "minSwitchCount"}, {"tabTrap", "maxSwitchCount"}),
    FarmingLiveRecipe.queue(
        "randomTabTrap",
        FarmingLiveRecipe.ctx("playerName"),
        FarmingLiveRecipe.ctx("lockMinutes"),
        FarmingLiveRecipe.ctx("switchCount"),
        FarmingLiveRecipe.config({"tabTrap", "minSwitchDelayMs"}),
        FarmingLiveRecipe.config({"tabTrap", "maxSwitchDelayMs"})
    )
}, { category = "vehicle", module = "RandomTabTrap" })
