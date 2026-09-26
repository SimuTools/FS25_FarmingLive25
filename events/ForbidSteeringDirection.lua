FarmingLiveRecipe.register("SteerBan", {
    FarmingLiveRecipe.set("minMinutes", FarmingLiveRecipe.config({"forbiddenSteeringDir", "minMinutes"})),
    FarmingLiveRecipe.set("maxMinutes", FarmingLiveRecipe.config({"forbiddenSteeringDir", "maxMinutes"})),
    FarmingLiveRecipe.queue("forbidSteeringDirection", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("minMinutes"), FarmingLiveRecipe.ctx("maxMinutes"))
}, { category = "vehicle", module = "ForbidSteeringDirection" })
