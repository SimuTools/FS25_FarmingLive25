FarmingLiveRecipe.register("DriveThat", {
    FarmingLiveRecipe.randomRange("lockMinutes", {"driveThat", "minLockMinutes"}, {"driveThat", "maxLockMinutes"}),
    FarmingLiveRecipe.queue("driveThat", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("lockMinutes"))
}, { category = "vehicle", module = "DriveThat" })
