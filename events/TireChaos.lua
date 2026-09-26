FarmingLiveRecipe.register("TireChaos", {
    FarmingLiveRecipe.run(function(self, ctx)
        local useParty = math.random() > 0.5

        if useParty then
            local minMinutes = tonumber((self.config.tireParty and self.config.tireParty.minMinutes) or 1) or 1
            local maxMinutes = tonumber((self.config.tireParty and self.config.tireParty.maxMinutes) or minMinutes) or minMinutes
            if maxMinutes < minMinutes then minMinutes, maxMinutes = maxMinutes, minMinutes end
            ctx.durationMinutes = math.random(minMinutes, maxMinutes)
            self:queueEvent(self.tireBounceParty, ctx.playerName, ctx.durationMinutes)
        else
            local minMinutes = tonumber((self.config.flatTire and self.config.flatTire.minMinutes) or 1) or 1
            local maxMinutes = tonumber((self.config.flatTire and self.config.flatTire.maxMinutes) or minMinutes) or minMinutes
            if maxMinutes < minMinutes then minMinutes, maxMinutes = maxMinutes, minMinutes end
            ctx.durationMinutes = math.random(minMinutes, maxMinutes)
            self:queueEvent(self.flatTireChaos, ctx.playerName, ctx.durationMinutes)
        end
    end)
}, { category = "vehicle", module = "TireChaos" })
