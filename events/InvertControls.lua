FarmingLiveRecipe.register("InvertControls", {
    FarmingLiveRecipe.set("minMinutes", FarmingLiveRecipe.config({"invertControls", "minMinutes"})),
    FarmingLiveRecipe.set("maxMinutes", FarmingLiveRecipe.config({"invertControls", "maxMinutes"})),
    FarmingLiveRecipe.queue("invertControls", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("minMinutes"), FarmingLiveRecipe.ctx("maxMinutes"))
}, { category = "vehicle", module = "InvertControls" })
