FarmingLiveRecipe.register("SetDrivingDirection", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"drivingEnforce", "mintime"}, {"drivingEnforce", "maxtime"}),
    FarmingLiveRecipe.queue("enforceDrivingDirection", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMinutes"))
}, { category = "vehicle", module = "EnforceDrivingDirection" })
