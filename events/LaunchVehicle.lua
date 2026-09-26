FarmingLiveRecipe.register("launchVehicle", {
    FarmingLiveRecipe.run(function(self, ctx)
        ctx.upImpulse = math.random(1, FarmingLive.config.launchVehicle.LaunchVehicleUpImp)
        ctx.forwardImpulse = math.random(1, FarmingLive.config.launchVehicle.LaunchVehicleFwdImp)
    end),
    FarmingLiveRecipe.queue("launchVehicle", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("upImpulse"), FarmingLiveRecipe.ctx("forwardImpulse"))
}, { category = "vehicle", module = "LaunchVehicle" })
