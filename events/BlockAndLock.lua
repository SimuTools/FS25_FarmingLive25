FarmingLiveRecipe.register("lockDoor", {
    FarmingLiveRecipe.queue("blockMotorAndLockVehicle", FarmingLiveRecipe.ctx("playerName"))
}, { category = "vehicle", module = "BlockAndLock" })
