local function flTrim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function flResolveMode(mode)
    local normalized = flTrim(mode)
    if normalized == "" or normalized:lower() == "default" or normalized:lower() == "global" or normalized:lower() == "inherit" then
        return nil
    end
    return normalized
end

local function flGetSpeedKph(vehicle)
    if vehicle == nil then
        return 0
    end

    if vehicle.getLastSpeed ~= nil then
        local speed = vehicle:getLastSpeed()
        if speed ~= nil then
            return (tonumber(speed) or 0) * 3.6
        end
    end

    if vehicle.lastSpeedReal ~= nil then
        return (tonumber(vehicle.lastSpeedReal) or 0) * 3.6
    end

    return 0
end

local function flTemplate(template, values)
    local text = FarmingLive:resolveTemplate(template, template)
    return (tostring(text):gsub("{([%w_]+)}", function(key)
        local value = values[key]
        if value == nil then
            return "{" .. tostring(key) .. "}"
        end
        return tostring(value)
    end))
end

local function flGetEnhancedVehicleState(vehicle)
    if vehicle == nil or type(vehicle) ~= "table" then
        return nil
    end

    local vData = vehicle.vData
    if type(vData) ~= "table" then
        return nil
    end

    if type(vData.is) ~= "table" or type(vData.want) ~= "table" then
        return nil
    end

    return vData
end

local function flDisableEnhancedVehicleSnap(vehicle)
    local vData = flGetEnhancedVehicleState(vehicle)
    if vData == nil then
        return nil
    end

    local state = {
        is5 = vData.is[5],
        want5 = vData.want[5],
        is6 = vData.is[6],
        want6 = vData.want[6],
        axisSidePrev = vData.axisSidePrev
    }

    vData.is[5] = false
    vData.want[5] = false
    vData.is[6] = false
    vData.want[6] = false
    vData.axisSidePrev = 0

    return state
end

local function flRestoreEnhancedVehicleSnap(vehicle, state)
    local vData = flGetEnhancedVehicleState(vehicle)
    if vData == nil or state == nil then
        return
    end

    vData.is[5] = state.is5
    vData.want[5] = state.want5
    vData.is[6] = state.is6
    vData.want[6] = state.want6
    vData.axisSidePrev = state.axisSidePrev or 0
end

local function flChoice(list)
    if list == nil or #list == 0 then
        return nil
    end
    return list[math.random(1, #list)]
end

function FarmingLive:idleChaosEvent(playerName, minutes)
    if not g_localPlayer or not g_currentMission then
        self:endActiveEvent()
        return
    end

    local rootVehicle = self:requireCurrentVehicle(playerName, self.idleChaosEvent, playerName, minutes)
    if rootVehicle == nil then
        return
    end

    if rootVehicle.spec_drivable == nil then
        self:queueVehicleRetry(playerName, self.idleChaosEvent, playerName, minutes)
        return
    end

    local cfg = self.config.idleChaos or {}
    local totalMs = math.max(1, tonumber(minutes) or 1) * 60 * 1000
    local minSpeedKph = math.max(0, tonumber(cfg.minSpeedKph) or 1)
    local minStandMs = math.max(100, tonumber(cfg.minStandMs) or 1200)
    local effectMinMs = math.max(500, tonumber(cfg.effectMinMs) or 3000)
    local effectMaxMs = math.max(effectMinMs, tonumber(cfg.effectMaxMs) or 8000)
    local cooldownMs = math.max(0, tonumber(cfg.cooldownMs) or 1000)
    local messageMode = flResolveMode(cfg.messageMode)

    local hookKey = "idleChaos"
    local timeLeftMs = totalMs
    local standTimerMs = 0
    local cooldownUntil = 0
    local activeEffect = nil
    local activeEffectLabel = nil
    local activeEffectEndsAt = 0
    local currentVehicle = rootVehicle
    local steeringCompatState = nil
    local motorBlockVehicle = nil
    local motorBlockOrigStart = nil

    local jitterMs = 0
    local jitterTarget = 0
    local jitterValue = 0
    local nextJitterJump = 0
    local oneSideDirection = nil
    local blockedDirection = nil

    local function showMessage(template, durationMs, extra)
        local values = {
            player = tostring(playerName or ""),
            minutes = math.max(1, tonumber(minutes) or 1),
            effect = tostring(activeEffectLabel or ""),
            seconds = math.max(0, math.ceil((activeEffectEndsAt - (g_time or 0)) / 1000))
        }

        if type(extra) == "table" then
            for k, v in pairs(extra) do
                values[k] = v
            end
        end

        self:showWarning(flTemplate(template, values), durationMs, messageMode)
    end

    local function stopMotorBlock()
        if motorBlockVehicle ~= nil and motorBlockOrigStart ~= nil then
            motorBlockVehicle.startMotor = motorBlockOrigStart
        end
        motorBlockVehicle = nil
        motorBlockOrigStart = nil
    end

    local function startMotorBlock(vehicle)
        stopMotorBlock()

        if vehicle == nil or vehicle.spec_motorized == nil or vehicle.spec_motorized.motor == nil then
            return
        end

        local target = vehicle.spec_motorized.motor.vehicle or vehicle
        motorBlockVehicle = target
        motorBlockOrigStart = target.startMotor

        target.startMotor = function(selfVeh, ...)
            return false
        end

        if target.stopMotor ~= nil then
            target:stopMotor(true)
        end
    end

    local function clearSteeringCompat()
        if currentVehicle ~= nil then
            self:detachVehiclePhysicsHook(currentVehicle, hookKey)
            flRestoreEnhancedVehicleSnap(currentVehicle, steeringCompatState)
        end
        steeringCompatState = nil
    end

    local function ensureSteeringCompat(vehicle)
        if vehicle == nil or vehicle.spec_drivable == nil then
            return false
        end

        if currentVehicle ~= vehicle then
            clearSteeringCompat()
            stopMotorBlock()
            currentVehicle = vehicle
        end

        if steeringCompatState == nil then
            steeringCompatState = flDisableEnhancedVehicleSnap(vehicle)
        else
            local vData = flGetEnhancedVehicleState(vehicle)
            if vData ~= nil then
                vData.is[5] = false
                vData.want[5] = false
                vData.is[6] = false
                vData.want[6] = false
                vData.axisSidePrev = 0
            end
        end

        return true
    end

    local function physicsHook(selfVeh, axisForward, axisSide, doHandbrake, dt)
        local newForward = axisForward
        local newSide = axisSide
        local newBrake = doHandbrake

        if activeEffect == "InvertSteer" then
            newSide = -(axisSide or 0)
            if selfVeh.spec_drivable ~= nil then
                selfVeh.spec_drivable.steeringInput = newSide
            end
        elseif activeEffect == "SteerJitter" then
            newSide = (axisSide or 0) + jitterValue
            if newSide > 1 then
                newSide = 1
            elseif newSide < -1 then
                newSide = -1
            end
            if selfVeh.spec_drivable ~= nil then
                selfVeh.spec_drivable.steeringInput = newSide
            end
        elseif activeEffect == "BlockOneDirection" then
            if blockedDirection == "forward" and newForward ~= nil and newForward > 0 then
                newForward = 0
                newBrake = true
            elseif blockedDirection == "reverse" and newForward ~= nil and newForward < 0 then
                newForward = 0
                newBrake = true
            end
        elseif activeEffect == "EngineStall" then
            if newForward ~= nil then
                newForward = 0
            end
            newBrake = true
        elseif activeEffect == "SteerOneSideOnly" then
            if oneSideDirection == "left" and newSide ~= nil and newSide > 0 then
                newSide = 0
            elseif oneSideDirection == "right" and newSide ~= nil and newSide < 0 then
                newSide = 0
            end
            if selfVeh.spec_drivable ~= nil then
                selfVeh.spec_drivable.steeringInput = newSide or 0
            end
        end

        return newForward, newSide, newBrake, dt
    end

    local EFFECTS = {
        {
            key = "InvertSteer",
            label = self:resolveTemplate("@IDLECHAOS_EFF_INVERT", "Lenkung invertiert")
        },
        {
            key = "SteerJitter",
            label = self:resolveTemplate("@IDLECHAOS_EFF_JITTER", "Zittriges Lenken")
        },
        {
            key = "BlockOneDirection",
            label = self:resolveTemplate("@IDLECHAOS_EFF_THROTTLE", "Vorwärts/Rückwärts blockiert")
        },
        {
            key = "EngineStall",
            label = self:resolveTemplate("@IDLECHAOS_EFF_ENGINESTALL", "Motor geht aus")
        },
        {
            key = "SteerOneSideOnly",
            label = self:resolveTemplate("@IDLECHAOS_EFF_STEERLOCKONE", "Lenkung nur in eine Richtung")
        }
    }

    local function disableActiveEffect()
        clearSteeringCompat()
        stopMotorBlock()
        activeEffect = nil
        activeEffectLabel = nil
        activeEffectEndsAt = 0
        oneSideDirection = nil
        blockedDirection = nil
        jitterMs = 0
        jitterTarget = 0
        jitterValue = 0
        nextJitterJump = 0
    end

    local function enableEffect(effect, vehicle)
        if effect == nil or vehicle == nil or vehicle.spec_drivable == nil then
            return false
        end

        disableActiveEffect()

        activeEffect = effect.key
        activeEffectLabel = effect.label
        activeEffectEndsAt = (g_time or 0) + math.random(effectMinMs, effectMaxMs)

        if activeEffect == "InvertSteer" then
            ensureSteeringCompat(vehicle)
            self:attachVehiclePhysicsHook(vehicle, hookKey, physicsHook)
        elseif activeEffect == "SteerJitter" then
            ensureSteeringCompat(vehicle)
            jitterMs = 0
            jitterTarget = 0
            jitterValue = 0
            nextJitterJump = 0
            self:attachVehiclePhysicsHook(vehicle, hookKey, physicsHook)
        elseif activeEffect == "BlockOneDirection" then
            ensureSteeringCompat(vehicle)
            blockedDirection = (math.random(0, 1) == 0) and "forward" or "reverse"
            self:attachVehiclePhysicsHook(vehicle, hookKey, physicsHook)
        elseif activeEffect == "EngineStall" then
            ensureSteeringCompat(vehicle)
            startMotorBlock(vehicle)
            self:attachVehiclePhysicsHook(vehicle, hookKey, physicsHook)
        elseif activeEffect == "SteerOneSideOnly" then
            ensureSteeringCompat(vehicle)
            oneSideDirection = (math.random(0, 1) == 0) and "left" or "right"
            self:attachVehiclePhysicsHook(vehicle, hookKey, physicsHook)
        else
            disableActiveEffect()
            return false
        end

        showMessage(cfg.effect or "@IDLECHAOS_EFFECT", 1800, { effect = activeEffectLabel })
        return true
    end

    showMessage(cfg.start or "@IDLECHAOS_START", 2600, { minutes = math.max(1, tonumber(minutes) or 1) })

    local watcher = {}

    function watcher:update(dt)
        local now = g_time or 0
        dt = tonumber(dt) or 0

        if dt <= 0 or not g_currentMission or not g_localPlayer then
            disableActiveEffect()
            self:removeUpdateable(self)
            FarmingLive:endActiveEvent()
            return
        end

        timeLeftMs = timeLeftMs - dt
        if timeLeftMs <= 0 then
            disableActiveEffect()
            FarmingLive:showWarning(flTemplate(cfg.done or "@IDLECHAOS_END", { player = tostring(playerName or "") }), 2600, messageMode)
            FarmingLive:removeUpdateable(self)
            FarmingLive:endActiveEvent()
            return
        end

        local liveVehicle = FarmingLive:getCurrentVehicleOrLast()
        if liveVehicle ~= nil and liveVehicle.spec_drivable ~= nil and liveVehicle ~= currentVehicle then
            disableActiveEffect()
            currentVehicle = liveVehicle
            standTimerMs = 0
            cooldownUntil = now + cooldownMs
        elseif liveVehicle ~= nil and liveVehicle.spec_drivable ~= nil then
            currentVehicle = liveVehicle
        end

        if currentVehicle == nil or currentVehicle.spec_drivable == nil then
            return
        end

        if activeEffect ~= nil then
            if activeEffect == "SteerJitter" then
                jitterMs = jitterMs + dt
                nextJitterJump = nextJitterJump - dt

                if nextJitterJump <= 0 then
                    jitterTarget = (math.random() * 2 - 1) * (0.55 + math.random() * 0.45)
                    nextJitterJump = math.random(70, 160)
                end

                jitterValue = jitterValue + (jitterTarget - jitterValue) * 0.28

                if math.random() < 0.06 then
                    jitterValue = jitterValue + (math.random() * 0.8 - 0.4)
                    if jitterValue > 1 then
                        jitterValue = 1
                    elseif jitterValue < -1 then
                        jitterValue = -1
                    end
                end
            end

            ensureSteeringCompat(currentVehicle)
            self:attachVehiclePhysicsHook(currentVehicle, hookKey, physicsHook)

            if activeEffectEndsAt > 0 and now >= activeEffectEndsAt then
                disableActiveEffect()
                cooldownUntil = now + cooldownMs
            end

            return
        end

        if now < cooldownUntil then
            return
        end

        local speedKph = flGetSpeedKph(currentVehicle)
        local isStanding = speedKph <= minSpeedKph

        if isStanding then
            standTimerMs = standTimerMs + dt

            FarmingLive:showThrottledFormattedWarning(
                "IdleChaosTick",
                cfg.tick or "@IDLECHAOS_TICK",
                1200,
                1000,
                playerName,
                math.ceil(minStandMs / 1000),
                self:messageMode(messageMode)
            )

            if standTimerMs >= minStandMs then
                standTimerMs = 0
                enableEffect(flChoice(EFFECTS), currentVehicle)
            end
        else
            standTimerMs = 0
        end
    end

    self:addUpdateable(watcher)
end