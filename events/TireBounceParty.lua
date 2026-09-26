FarmingLiveRecipe.register("TireParty", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"tireParty", "minMinutes"}, {"tireParty", "maxMinutes"}),
    FarmingLiveRecipe.queue("tireBounceParty", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMinutes"))
}, { category = "vehicle", module = "TireBounceParty" })
