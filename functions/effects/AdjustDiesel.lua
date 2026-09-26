function FarmingLive:adjustDieselRandomFillLevel(playerName)
print("[FarmingLive] adjustDieselRandomFillLevel wurde gestartet für: " .. tostring(playerName))
   if not g_localPlayer then
        print("[FarmingLive - adjustDiesel] Kein lokaler Spieler gefunden.")
        return
    end

    local playerVehicle = self:getCurrentVehicle()
    if not playerVehicle or not (playerVehicle.spec_fillUnit and playerVehicle.spec_fillUnit.fillUnits) then
        local farmId = nil
        if playerVehicle and playerVehicle.getOwnerFarmId then
            farmId = playerVehicle:getOwnerFarmId()
        end
        if farmId == nil then
            farmId = self:getLocalFarmId()
        end

        playerVehicle = self:findOwnedVehicle(farmId, function(vehicle)
            return vehicle.spec_fillUnit ~= nil and vehicle.spec_fillUnit.fillUnits ~= nil
        end, true)
    end

    if not playerVehicle then
       self:queueVehicleRetry(playerName, self.adjustDieselRandomFillLevel, playerName)
        return
    end

    local vehicleName = playerVehicle:getFullName()
    local dieselFillType = g_fillTypeManager:getFillTypeIndexByName("DIESEL")
    if dieselFillType == nil then
        print("[FarmingLive - adjustDiesel] FillTypes nicht gefunden!")
        self:endActiveEvent()
        return
    end

    local found = false
    local randomAdjustment = 0
    for idx, fillUnit in pairs(playerVehicle.spec_fillUnit.fillUnits) do
        if fillUnit.fillType == dieselFillType then
            found = true
            local currentLevel = fillUnit.fillLevel or 0
            local capacity = fillUnit.capacity or currentLevel
            local maxRemoval = math.max(0, currentLevel - 1)
            randomAdjustment = math.random(-maxRemoval, capacity)
            local newLevel = math.min(capacity, math.max(0, currentLevel + randomAdjustment))
            playerVehicle.spec_fillUnit.fillUnits[idx].fillLevel = newLevel

            print(string.format(
                "[FarmingLive - adjustDiesel] Adjusted Diesel fill level from %.2f to %.2f for vehicle: %s",
                currentLevel, newLevel, vehicleName
            ))

            local percent = 0
            if capacity > 0 then
                percent = math.floor((math.abs(randomAdjustment) / capacity) * 100)
            end

            local template = FarmingLive.config.adjustDiesel.remFuel
            local key = "remDiesel"
            if randomAdjustment > 0 then
                template = FarmingLive.config.adjustDiesel.getFuel
                key = "getDiesel"
            end

            self:showThrottledFormattedWarning(key, template, 5000, 5000, playerName, percent)
            self:showFormattedWarning(template, 5000, playerName, percent)
            break
        end
    end

    if not found then
        print("[FarmingLive - adjustDiesel] Keine Diesel-FillUnit gefunden.")
        self:endActiveEvent()
        return
    end

    if not g_server and found then
        FarmingLiveAdjustDieselEvent.sendToServer(playerVehicle, playerName, randomAdjustment)
    end
    self:endActiveEvent()
end
