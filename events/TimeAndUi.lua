FarmingLiveRecipe.register("SetRandomTime", {
    FarmingLiveRecipe.call("setRandomTime", FarmingLiveRecipe.ctx("playerName"))
}, { category = "world", module = "TimeAndUi" })

FarmingLiveRecipe.register("UselessBox", {
    FarmingLiveRecipe.call("UselessBox", FarmingLiveRecipe.ctx("userInput"))
}, { category = "ui", module = "TimeAndUi" })
