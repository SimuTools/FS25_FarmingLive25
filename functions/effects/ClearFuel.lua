function FarmingLive:clearFuel(playerName)
print("[FarmingLive] clearFuel wurde gestartet für: " .. tostring(playerName))     
   if not g_localPlayer then
        print("[FarmingLive] Kein lokaler Spieler gefunden.")
		FarmingLive:endActiveEvent()
        return
    end

    local playerVehicle = self:getCurrentVehicle()
    if not playerVehicle or not playerVehicle.emptyAllFillUnits then
        local farmId = nil
        if playerVehicle and playerVehicle.getOwnerFarmId then
            farmId = playerVehicle:getOwnerFarmId()
        end
        if farmId == nil then
            farmId = self:getLocalFarmId()
        end

        playerVehicle = self:findOwnedVehicle(farmId, function(vehicle)
            return vehicle.emptyAllFillUnits ~= nil
        end, true)
    end

    if not playerVehicle then
        self:queueVehicleRetry(playerName, self.clearFuel, playerName)
        return
    end

    local vehicleName = playerVehicle:getFullName()
    playerVehicle:emptyAllFillUnits(true)

    self:showFormattedWarning(FarmingLive.config.clearFuel.message, 5000, playerName, nil, vehicleName)
    print("[FarmingLive - ClearAll] Cleared All for vehicle: " .. vehicleName .. " (ID: " .. tostring(playerVehicle.id) .. ")")
	FarmingLive:endActiveEvent()
    if not g_server then
        FarmingLiveClearFuelEvent.sendToServer(playerVehicle, playerName)
    end
end
