local function flSetBrokenApplyDamage(vehicle, amount)
    if vehicle == nil or vehicle.addDamageAmount == nil then
        return false
    end

    vehicle:addDamageAmount(amount, true)
    return true
end

function FarmingLive:setBroken(playerName, vehicleOverride, damageOverride, fromNetwork)
print("[FarmingLive] setBroken wurde gestartet für: " .. tostring(playerName))
    if not g_currentMission then
        FarmingLive:endActiveEvent()
        return
    end

    local playerVehicle = vehicleOverride
    if playerVehicle == nil then
        if not g_localPlayer then
            print("[FarmingLive - SetBroken] Kein lokaler Spieler gefunden.")
            FarmingLive:endActiveEvent()
            return
        end

        playerVehicle = self:requireCurrentVehicle(playerName, self.setBroken, playerName)
        if not playerVehicle then
            return
        end
    end

    if playerVehicle.addDamageAmount then
        local damageAmount = tonumber(damageOverride) or math.random(1, 100)

        if not flSetBrokenApplyDamage(playerVehicle, damageAmount) then
            print("[FarmingLive - SetBroken] Schaden konnte nicht angewendet werden.")
            FarmingLive:endActiveEvent()
            return
        end

        local isServer = g_currentMission:getIsServer()
        local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true
        if isMp and not isServer and not fromNetwork then
            FarmingLiveSetBrokenEvent.sendToServer(playerVehicle, damageAmount)
        end

        local vehicleName = playerVehicle.getFullName and playerVehicle:getFullName() or "Unbekanntes Fahrzeug"
        self:showThrottledFormattedWarning("setBrokenWarn", FarmingLive.config.setBroken.message, 5000, 5000, playerName, nil, vehicleName)

        print(string.format(
            "[FarmingLive - SetBroken] Fahrzeug ID %s auf kaputt gesetzt, Schaden: %d%%",
            tostring(playerVehicle.id), damageAmount
        ))

        FarmingLive:monitorVehicleDamage(playerVehicle)
    else
        print("[FarmingLive - SetBroken] Dieses Fahrzeug unterstützt kein Schadenssystem.")
        FarmingLive:endActiveEvent()
    end
end

function FarmingLive:monitorVehicleDamage(vehicle)
    local motor = vehicle.spec_motorized and vehicle.spec_motorized.motor
    if not motor then
        self:endActiveEvent()
        return
    end

    local origStartMotor = motor.vehicle.startMotor

    local inCycle = false
    local state = nil
    local intervalStart = 0
    local intervalDur = 0

    local function startBlockPhase()
        state = "block"
        inCycle = true
        intervalStart = g_time
        intervalDur = math.random(5000, 7000)
        vehicle:stopMotor(true)
        motor.vehicle.startMotor = function(selfVehicle, ...)
            local remS = math.max(0, math.ceil((intervalStart + intervalDur - g_time) / 1000))
            FarmingLive:showThrottledFormattedWarning("setBrokenWarn", FarmingLive.config.setBroken.failmessage, 1000, 1000, remS)
            return false
        end
        print(string.format("[FarmingLive - SetBroken/Monitor] Block für %d ms", intervalDur))
    end

    local function startRunPhase()
        state = "run"
        inCycle = true
        intervalStart = g_time
        intervalDur = math.random(5000, 45000)
        motor.vehicle.startMotor = origStartMotor
        print("[FarmingLive - SetBroken/Monitor] Motor wieder freigegeben für Nutzzeit.")
    end

    local monitor = {}
    function monitor:update(dt)
        if vehicle == nil or vehicle.getDamageAmount == nil then
            motor.vehicle.startMotor = origStartMotor
            FarmingLive:removeUpdateable(self)
            FarmingLive:endActiveEvent()
            return
        end

        local dmg = vehicle:getDamageAmount() * 100
        if dmg == 0 then
            motor.vehicle.startMotor = origStartMotor
            FarmingLive:removeUpdateable(self)
            print("[FarmingLive - SetBroken/Monitor] Fahrzeug repariert, Monitoring beendet.")
            FarmingLive:endActiveEvent()
            return
        end

        if not inCycle and dmg > 25 then
            startRunPhase()
            return
        end

        if inCycle and g_time >= (intervalStart + intervalDur) then
            if state == "run" then
                startBlockPhase()
            else
                startRunPhase()
            end
        end
    end

    FarmingLive:addUpdateable(monitor)
end
