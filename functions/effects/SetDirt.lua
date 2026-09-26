function FarmingLive:setDirt(playerName, vehicleOverride, dirtOverride, fromNetwork)
print("[FarmingLive] setDirt wurde gestartet für: " .. tostring(playerName))

    if not g_currentMission then
        print("[FarmingLive - SetDirt] Mission nicht bereit")
        self:endActiveEvent()
        return
    end

    local vehicle = vehicleOverride
    if vehicle == nil then
        if not g_localPlayer then
            print("[FarmingLive - SetDirt] Spieler nicht bereit")
            self:endActiveEvent()
            return
        end

        vehicle = self:requireCurrentVehicle(playerName, self.setDirt, playerName)
        if not vehicle then
            return
        end
    end

    local currentDirt = 0
    if vehicle.getDirtAmount then
        currentDirt = vehicle:getDirtAmount()
    end

    local newDirt = tonumber(dirtOverride)
    if newDirt == nil then
        local absDelta = math.random(1, 100) / 100

        local sign
        if currentDirt <= 0 then
            sign = 1
        elseif currentDirt >= 1 then
            sign = -1
        else
            sign = (math.random() < 0.5) and -1 or 1
        end

        local delta = absDelta * sign
        newDirt = math.max(0, math.min(1, currentDirt + delta))
    else
        newDirt = math.max(0, math.min(1, newDirt))
    end

    local isServer = g_currentMission:getIsServer()
    local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true

    if vehicle.setDirtAmount then
        vehicle:setDirtAmount(newDirt)
    elseif vehicle.addDirtAmount then
        local delta = newDirt - currentDirt
        if delta > 0 then
            vehicle:addDirtAmount(delta)
        else
            vehicle:setDirtAmount(newDirt)
        end
    else
        print("[FarmingLive - SetDirt] Fahrzeug unterstützt keine Dirt-Funktion")
        self:endActiveEvent()
        return
    end

    if isMp and not isServer and not fromNetwork then
        FarmingLiveSetDirtEvent.sendToServer(vehicle, newDirt)
    end

    local vehicleName = (vehicle.getName and vehicle:getName()) or "Unbekanntes Fahrzeug"
    local template = FarmingLive.config.setDirt.cleanmessage
    if newDirt > currentDirt then
        template = FarmingLive.config.setDirt.message
    end

    self:showThrottledFormattedWarning("setDirtWarn", template, 5000, 5000, playerName, vehicleName)
    print(string.format(
        "[FarmingLive - SetDirt] Dirt %.2f -> %.2f auf %s (ID=%s)",
        currentDirt, newDirt, vehicleName, tostring(vehicle.id or "?")
    ))
    self:endActiveEvent()
end
