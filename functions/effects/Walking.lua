function FarmingLive:walkingEvent(playerName, durationInMinutes)
    print("[FarmingLive] walkingEvent gestartet für: " .. tostring(playerName))

    local modSelf = self
    local vehicle = self:getCurrentVehicle()
    if vehicle then
        self:leaveVehicle(vehicle)
        print("[FarmingLive] Spieler aus Fahrzeug geworfen")
    end

    if not g_localPlayer or not g_localPlayer.rootNode then
        self:endActiveEvent()
        return
    end

    local totalSeconds = (durationInMinutes or 1) * 60
    local walkedSeconds = 0
    local lastX, lastY, lastZ = getWorldTranslation(g_localPlayer.rootNode)
    local minMoveDist = 0.1

    local player = self:getLocalMissionPlayer()
    if not player then
        self:endActiveEvent()
        return
    end

    local preventEnter = true
    local entryBlock = self:blockVehicleEntry(
        player,
        function(target)
            return preventEnter and target == vehicle
        end,
        function(_, target, ...)
            local rem = math.max(0, totalSeconds - math.floor(walkedSeconds))
            modSelf:showThrottledFormattedWarning(
                "WalkingNoEnter",
                FarmingLive.config.walking.enterBlocked,
                1000,
                1000,
                playerName,
                rem
            )
            return false
        end
    )

    self:showThrottledFormattedWarning(
        "WalkingStart",
        FarmingLive.config.walking.start,
        3000,
        3000,
        playerName,
        durationInMinutes
    )

    local warnTemplates = {
        FarmingLive.config.walking.warn1,
        FarmingLive.config.walking.warn2,
        FarmingLive.config.walking.warn3,
        FarmingLive.config.walking.warn4,
        FarmingLive.config.walking.warn5
    }

    local rotateMs = 30000
    local nextRotateAt = g_time
    local currentTemplate = self:pickDifferent(warnTemplates, nil)

    local watcher = {}
    function watcher:update(dt)
        local currentVehicle = modSelf:getCurrentVehicle()
        if currentVehicle then
            modSelf:leaveVehicle(currentVehicle)
        end

        local x, y, z = getWorldTranslation(g_localPlayer.rootNode)
        local dx, dy, dz = x - lastX, y - lastY, z - lastZ
        if math.sqrt(dx * dx + dy * dy + dz * dz) >= minMoveDist then
            walkedSeconds = walkedSeconds + dt / 1000
            lastX, lastY, lastZ = x, y, z
        end

        local remTime = math.max(0, totalSeconds - math.floor(walkedSeconds))
        local mm, ss = modSelf:formatClock(remTime)

        local now = g_time
        if now >= nextRotateAt then
            currentTemplate = modSelf:pickDifferent(warnTemplates, currentTemplate)
            nextRotateAt = now + rotateMs
        end

        modSelf:showThrottledFormattedWarning(
            "WalkingTick",
            currentTemplate,
            1000,
            1000,
            playerName,
            nil,
            mm,
            ss
        )

        if walkedSeconds >= totalSeconds then
            preventEnter = false
            modSelf:restoreVehicleEntryBlock(entryBlock)
            modSelf:showThrottledFormattedWarning(
                "WalkingDone",
                FarmingLive.config.walking.done,
                3000,
                3000,
                playerName
            )
            modSelf:removeUpdateable(self)
            modSelf:endActiveEvent()
        end
    end

    self:addUpdateable(watcher)
end
