FarmingLiveRecipe.register("SwitchSeat", {
    FarmingLiveRecipe.queue("cycleVehicle", FarmingLiveRecipe.ctx("playerName"))
}, { category = "vehicle", module = "VehicleSwitch" })

FarmingLiveRecipe.register("LockOut", {
    FarmingLiveRecipe.set("minMinutes", 1),
    FarmingLiveRecipe.set("maxMinutes", 5),
    FarmingLiveRecipe.queue("lockOutCurrentVehicle", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("minMinutes"), FarmingLiveRecipe.ctx("maxMinutes"))
}, { category = "vehicle", module = "VehicleSwitch" })
