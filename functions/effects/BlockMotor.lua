function FarmingLive:blockMotor(playerName)
    print("[FarmingLive] blockMotor wurde gestartet für: " .. tostring(playerName))
    if not g_localPlayer then
        FarmingLive:endActiveEvent()
        return
    end

    local vehicle = FarmingLive:getCurrentVehicleOrLast()
    if not vehicle or not vehicle.spec_motorized then
        self:queueVehicleRetry(playerName, self.blockMotor, playerName)
        return
    end

    local motor = vehicle.spec_motorized.motor
    if not motor then
        FarmingLive:endActiveEvent()
        return
    end

    local blockMS      = 60 * 1000
    local startTime    = g_time
    local blockEndTime = startTime + blockMS

    local startMsg = FarmingLive:formatMessage(
        FarmingLive.config.blockEngine.warningMotorStopped,
        playerName
    )
    FarmingLive:showThrottledWarning("blockEngStartWarn", startMsg, 5000, 5000)

    motor.vehicle:stopMotor(true)
    if vehicle.spec_drivable then
        vehicle.spec_drivable.brakeInput = 1
    end

    if g_currentMission.missionDynamicInfo.isMultiplayer then
        FarmingLiveBlockMotorEvent.sendToServer(vehicle, blockMS, playerName)
    else
        FarmingLiveBlockMotorEvent.new(vehicle, blockMS, playerName):run(nil)
    end

    local origStartMotor = motor.vehicle.startMotor
    motor.vehicle.startMotor = function(self, ...)
        return false
    end

    local countdown = {}
    function countdown:update(dt)
        local now = g_time
        if now < blockEndTime then
            local remS = math.ceil((blockEndTime - now) / 1000)
            local warn = FarmingLive:formatMessage(
                FarmingLive.config.blockEngine.warningMotorIgnored,
                playerName,
                remS
            )
            FarmingLive:showThrottledWarning("blockEngWarn", warn, 1000, 1000)
        else
            motor.vehicle.startMotor = origStartMotor
            if vehicle.spec_drivable then
                vehicle.spec_drivable.brakeInput = 0
            end

            local doneMsg = FarmingLive:formatMessage(
                FarmingLive.config.blockEngine.warningMotorActive,
                playerName
            )
            FarmingLive:showThrottledWarning("blockEngUnWarn", doneMsg, 5000, 5000)

            g_currentMission:removeUpdateable(self)
            FarmingLive:endActiveEvent()
            print("[FarmingLive] blockMotor beendet")
        end
    end

    g_currentMission:addUpdateable(countdown)
end
