FarmingLiveRecipe.register("SpeedLimit", {
    FarmingLiveRecipe.randomRange("durationMinutes", {"setSpeed", "mintime"}, {"setSpeed", "maxtime"}),
    FarmingLiveRecipe.numberOrRandom("speedLimit", "userInput", {"setSpeed", "minspeed"}, {"setSpeed", "maxspeed"}),
    FarmingLiveRecipe.queue("setSpeedLimit", FarmingLiveRecipe.ctx("durationMinutes"), FarmingLiveRecipe.ctx("speedLimit"), FarmingLiveRecipe.ctx("playerName"))
}, { category = "vehicle", module = "SetSpeedLimit" })
