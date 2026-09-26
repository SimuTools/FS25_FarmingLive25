FarmingLiveRecipe.register("Uselessnotifi", {
    FarmingLiveRecipe.call("showUser", FarmingLiveRecipe.ctx("playerName"))
}, { category = "ui", module = "Messages" })

FarmingLiveRecipe.register("showSimu", {
    FarmingLiveRecipe.call("showSimu", FarmingLiveRecipe.ctx("playerName"))
}, { category = "ui", module = "Messages" })

FarmingLiveRecipe.register("showHi", {
    FarmingLiveRecipe.call("showHi", FarmingLiveRecipe.ctx("playerName"))
}, { category = "ui", module = "Messages" })
