local function flLaunchNow(vehicle, upImpulse, forwardImpulse)
    if vehicle == nil or vehicle.rootNode == nil then
        return false
    end

    local node = vehicle.rootNode
    local vx, vy, vz = getLinearVelocity(node)
    local cx, cy, cz = getWorldTranslation(node)
    local wx, wy, wz = localToWorld(node, 0, 0, 1)
    local dx, dy, dz = wx - cx, wy - cy, wz - cz
    local len = math.sqrt(dx * dx + dy * dy + dz * dz)

    if len > 0.0001 then
        dx, dy, dz = dx / len, dy / len, dz / len
    else
        dx, dy, dz = 0, 0, 1
    end

    setLinearVelocity(
        node,
        vx + dx * forwardImpulse,
        vy + upImpulse,
        vz + dz * forwardImpulse
    )

    return true
end

function FarmingLive:launchVehicle(playerName, upImpulse, forwardImpulse)
    print("[FarmingLive] launchVehicle wurde gestartet für: " .. tostring(playerName))

    if not g_localPlayer or not g_currentMission then
        FarmingLive:endActiveEvent()
        return
    end

    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle == nil then
        self:queueOrRunVehicleAction(playerName, self.launchVehicle, playerName, upImpulse, forwardImpulse)
        FarmingLive:endActiveEvent()
        return
    end

    upImpulse = tonumber(upImpulse) or tonumber(FarmingLive.config.launchVehicle.LaunchVehicleUpImp) or 10
    forwardImpulse = tonumber(forwardImpulse) or tonumber(FarmingLive.config.launchVehicle.LaunchVehicleFwdImp) or 5

    local countdownStart = 4
    local nextTickTime = g_time or 0
    local counter = countdownStart
    local launchAt = nil
    local finished = false

    local function getLaunchVehicle()
        local currentVehicle = g_localPlayer and g_localPlayer:getCurrentVehicle() or nil
        if currentVehicle ~= nil then
            return currentVehicle
        end
        return vehicle
    end

    local function showCountdown(value)
        local msg = tostring(value)

        if FarmingLive.config.launchVehicle ~= nil and FarmingLive.config.launchVehicle.CountdownMessage ~= nil then
            msg = FarmingLive:formatMessage(FarmingLive.config.launchVehicle.CountdownMessage, playerName, value)
        else
            msg = tostring(value)
        end

        FarmingLive:showWarning(msg, 900)
    end

    local function showLaunchMessage()
        local warnMessage = nil

        if FarmingLive.config.launchVehicle ~= nil then
            warnMessage = FarmingLive.config.launchVehicle.LaunchVehicleWarnMessage
        end

        if warnMessage ~= nil and warnMessage ~= "" then
            FarmingLive:showWarning(
                FarmingLive:formatMessage(warnMessage, playerName),
                5000
            )
        end
    end

    local updater = {}

    function updater:update(dt)
        if finished then
            return
        end

        local now = g_time or 0
        local targetVehicle = getLaunchVehicle()

        if targetVehicle == nil or targetVehicle.rootNode == nil then
            g_currentMission:removeUpdateable(self)
            FarmingLive:endActiveEvent()
            return
        end

        if launchAt ~= nil then
            if now >= launchAt then
                if not g_currentMission:getIsServer() then
                    FarmingLiveLaunchVehicleEvent.sendToServer(targetVehicle, upImpulse, forwardImpulse, playerName)
                else
                    flLaunchNow(targetVehicle, upImpulse, forwardImpulse)
                end

                showLaunchMessage()

                finished = true
                g_currentMission:removeUpdateable(self)
                FarmingLive:endActiveEvent()
                print("[FarmingLive] Event Beendet")
            end
            return
        end

        if now >= nextTickTime then
            showCountdown(counter)

            if counter <= 0 then
                launchAt = now + 1000
            else
                counter = counter - 1
            end

            nextTickTime = now + 1000
        end
    end

    g_currentMission:addUpdateable(updater)
end