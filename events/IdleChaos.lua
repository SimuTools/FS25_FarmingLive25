FarmingLive:registerCommand("IdleChaos", function(self, playerName, userInput)
    local minutes = tonumber(userInput)
    if minutes == nil or minutes <= 0 then
        minutes = 1
    end

    self:queueEvent(self.idleChaosEvent, minutes, playerName)
end, { category = "vehicle", module = "IdleChaos" })