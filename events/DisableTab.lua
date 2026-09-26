FarmingLiveRecipe.register("BlockTab", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"blockTab", "mintime"}, {"blockTab", "maxtime"}),
    FarmingLiveRecipe.queue("disableTabForVehicles", FarmingLiveRecipe.ctx("durationMinutes"), FarmingLiveRecipe.ctx("playerName"))
}, { category = "vehicle", module = "DisableTab" })
