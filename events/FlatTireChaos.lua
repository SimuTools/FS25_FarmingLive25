FarmingLiveRecipe.register("FlatTire", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"flatTire", "minMinutes"}, {"flatTire", "maxMinutes"}),
    FarmingLiveRecipe.queue("flatTireChaos", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMinutes"))
}, { category = "vehicle", module = "FlatTireChaos" })
