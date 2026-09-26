FarmingLiveRecipe.register("HonkiHonkiHonk", {
    FarmingLiveRecipe.set("durationMs", 15000),
    FarmingLiveRecipe.queue("triggerHonkForDuration", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMs"))
}, { category = "vehicle", module = "Honk" })
