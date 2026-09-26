FarmingLiveRecipe.register("RandomSteer", {
    FarmingLiveRecipe.set("minMinutes", 5),
    FarmingLiveRecipe.set("maxMinutes", 5),
    FarmingLiveRecipe.queue("randomSteeringInterference", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("minMinutes"), FarmingLiveRecipe.ctx("maxMinutes"))
}, { category = "vehicle", module = "RandomSteeringInterference" })
