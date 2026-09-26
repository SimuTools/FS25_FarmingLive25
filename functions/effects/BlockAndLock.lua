function FarmingLive:blockMotorAndLockVehicle(a, b)
    local fromNetwork = false
    local playerName, vehicle

    if type(a) == "table" and a.spec_motorized ~= nil then
        vehicle    = a
        playerName = b
        fromNetwork = true
    else
        playerName = a
        if g_localPlayer ~= nil then
            vehicle = g_localPlayer:getCurrentVehicle()
        end
    end

    print(string.format("[FarmingLive] blockMotorAndLockVehicle gestartet (fromNetwork=%s) für: %s",
        tostring(fromNetwork), tostring(playerName)))

    if vehicle == nil or vehicle.spec_motorized == nil then
        self:queueVehicleRetry(playerName, self.blockMotorAndLockVehicle, playerName)
        print("[FarmingLive] blockMotorAndLockVehicle -> Vehicle queueEvent/kein motorized")
        return
    end

    if vehicle._farmingLiveLockActive then
        print("[FarmingLive] blockMotorAndLockVehicle -> bereits aktiv, überspringe.")
        return
    end
    vehicle._farmingLiveLockActive = true

    local motor = vehicle.spec_motorized.motor

    local lockMsg = FarmingLive:formatMessage(
        FarmingLive.config.BlockAndLock.KEYOUT,
        playerName
    )
    FarmingLive:showThrottledWarning("BlockAndLockWarn", lockMsg, 5000, 5000)

    motor.vehicle:stopMotor(true)
    if vehicle.spec_drivable then
        vehicle.spec_drivable.brakeInput = 1
    end

    local origGetStarted  = motor.vehicle.getIsMotorStarted
    local origGetStopped  = motor.vehicle.getIsMotorStopped
    local origGetRpm      = motor.vehicle.getMotorRpm
    local origUpdateSound = motor.vehicle.updateSound
    local origUpdateSmoke = motor.vehicle.updateSmoke

    motor.vehicle.getIsMotorStarted = function() return false end
    motor.vehicle.getIsMotorStopped = function() return true  end
    motor.vehicle.getMotorRpm       = function() return 0     end
    motor.vehicle.updateSound       = function() end
    motor.vehicle.updateSmoke       = function() end

    local origSteer, origAccel, origBrake =
        vehicle.setSteeringInput,
        vehicle.setAccelerationInput,
        vehicle.setBrakeInput

    vehicle.setSteeringInput     = function() end
    vehicle.setAccelerationInput = function() end
    vehicle.setBrakeInput        = function(self)
        if vehicle.spec_drivable then vehicle.spec_drivable.brakeInput = 1 end
    end

    local origStartMotor = motor.vehicle.startMotor
    local canStart = false
    motor.vehicle.startMotor = function(self, ...)
        if canStart then
            return origStartMotor(self, ...)
        else
            local warn = FarmingLive:formatMessage(
                FarmingLive.config.BlockAndLock.KEYOUT,
                playerName
            )
            FarmingLive:showWarning(warn, 1000)
            return false
        end
    end
    if g_currentMission.missionDynamicInfo.isMultiplayer and not fromNetwork then

        FarmingLiveLockDoorEvent.sendToServer(vehicle, playerName)
    elseif not g_currentMission.missionDynamicInfo.isMultiplayer then
    end
    local watch = {}
    function watch:update(dt)
        local currentVehicle = (g_localPlayer ~= nil) and g_localPlayer:getCurrentVehicle() or nil
        if currentVehicle ~= vehicle then
            vehicle.setSteeringInput     = origSteer
            vehicle.setAccelerationInput = origAccel
            vehicle.setBrakeInput        = origBrake
            if vehicle.spec_drivable then
                vehicle.spec_drivable.brakeInput = 0
            end

            canStart = true
            motor.vehicle.startMotor = origStartMotor

            motor.vehicle.getIsMotorStarted = origGetStarted
            motor.vehicle.getIsMotorStopped = origGetStopped
            motor.vehicle.getMotorRpm       = origGetRpm
            motor.vehicle.updateSound       = origUpdateSound
            motor.vehicle.updateSmoke       = origUpdateSmoke

            vehicle._farmingLiveLockActive = nil

            local unlockMsg = FarmingLive:formatMessage(
                FarmingLive.config.BlockAndLock.KEYFOUND,
                playerName
            )
            FarmingLive:showWarning(unlockMsg, 5000)
            if FarmingLive.endActiveEvent ~= nil then
                FarmingLive:endActiveEvent()
            end
            g_currentMission:removeUpdateable(self)
        end
    end
    g_currentMission:addUpdateable(watch)
end
