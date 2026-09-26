FarmingLiveRecipe.register("FadeScreen", {
    FarmingLiveRecipe.set("durationMs", FarmingLiveRecipe.config({"fadeScreen", "duration"})),
    FarmingLiveRecipe.queue("fadeScreenForDuration", FarmingLiveRecipe.ctx("durationMs"), FarmingLiveRecipe.ctx("playerName"))
}, { category = "screen", module = "FadeScreen" })
