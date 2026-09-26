FarmingLiveRecipe.register("toggleWipers", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"toggleWipers", "TOGWipersMinTime"}, {"toggleWipers", "TOGWipersMaxTime"}),
    FarmingLiveRecipe.queue("toggleWipers", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMinutes"))
}, { category = "vehicle", module = "Wipers" })
