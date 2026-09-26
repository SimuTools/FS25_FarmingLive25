FarmingLiveRecipe.register("lockInteriorCam", {
    FarmingLiveRecipe.randomRange("duration", {"lockInteriorCamera", "IntoriorCamMinTime"}, {"lockInteriorCamera", "IntoriorCamMaxTime"}),
    FarmingLiveRecipe.queue("lockInteriorCamera", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("duration"))
}, { category = "camera", module = "CameraLockInterior" })
