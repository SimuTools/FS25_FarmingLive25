FarmingLiveRecipe.register("cameraFun", {
    FarmingLiveRecipe.randomRange("duration", {"cameraFun", "TimeMin"}, {"cameraFun", "TimeMax"}),
    FarmingLiveRecipe.queue("cameraFun", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("duration"))
}, { category = "camera", module = "CameraFun" })
