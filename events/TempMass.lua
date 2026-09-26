FarmingLiveRecipe.register("MassChange", {
    FarmingLiveRecipe.set("weight", FarmingLiveRecipe.config({"tempMass", "weight"})),
    FarmingLiveRecipe.queue("temporarilyIncreaseMass", FarmingLiveRecipe.ctx("playerName"), FarmingLiveRecipe.ctx("weight"))
}, { category = "vehicle", module = "TempMass" })
