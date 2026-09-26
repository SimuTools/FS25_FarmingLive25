FarmingLiveRecipe.register("GoWalk", {
    FarmingLiveRecipe.run(function(self, ctx)
        ctx.durationMinutes = math.random(1, 2)
    end),
    FarmingLiveRecipe.queue("walkingEvent", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("durationMinutes"))
}, { category = "player", module = "Walking" })
