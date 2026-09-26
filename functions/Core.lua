function FarmingLive:update(dt)
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle and #self.pendingVehicleActions > 0 then
        self._lastPendingExecTime = self._lastPendingExecTime or (g_time - 4000)

        if g_time - self._lastPendingExecTime >= 4000 then
            local entry = table.remove(self.pendingVehicleActions, 1)
            self:queueEvent(entry.func, table.unpack(entry.args))
            self._lastPendingExecTime = g_time
        end
    elseif not vehicle then
        self._lastPendingExecTime = nil
    end

    local ctx = self:getNetworkContext()

    if not ctx.isClient then
        return
    end
    self:checkForCommand(dt)
    self:checkEventMenuHotkey()
end

function FarmingLive:queueOrRunVehicleAction(playerName, actionFunc, ...)
    if not g_currentMission then return end

    local args = { ... }
    table.insert(self.pendingVehicleActions, { func = actionFunc, args = args })
end

function FarmingLive:notify(message, color, duration)
    if type(message) ~= "string" or message == "" then
        print("[FarmingLive] notify: Ungültige Nachricht.")
        return
    end

    color = color or HUD.COLOR.DEFAULT
    duration = duration or 5000

    if g_currentMission and g_currentMission.hud and g_currentMission.hud.addSideNotification then
        g_currentMission.hud:addSideNotification(color, message, duration)
    else
        print("[FarmingLive] HUD-Benachrichtigung nicht verfügbar, Text: " .. message)
    end
end

function FarmingLive:describeCallable(func)
    if type(func) ~= "function" then
        return tostring(func)
    end

    if self.commandHandlers ~= nil then
        for name, handler in pairs(self.commandHandlers) do
            if handler == func then
                return tostring(name)
            end
        end
    end

    return tostring(func)
end

function FarmingLive:runEvent(func, ...)
    self.activeEvent = {
        func = func,
        args = { ... },
        label = self:describeCallable(func),
        startedAt = g_time or 0,
        kind = "run"
    }
    func(self, table.unpack(self.activeEvent.args))
end

function FarmingLive:endActiveEvent()
    self.activeEvent = nil
    self:tryNextEvent()
end

function FarmingLive:queueEvent(eventFunc, ...)
    local args = { ... }

    table.insert(self.eventQueue, {
        func = eventFunc,
        args = args,
        label = self:describeCallable(eventFunc),
        queuedAt = g_time or 0
    })

    self:tryNextEvent()
end

function FarmingLive:tryNextEvent(forceRun)
    if self.activeEvent or #self.eventQueue == 0 then return false end
    if self.queuePaused and not forceRun then return false end

    local nextEvent = table.remove(self.eventQueue, 1)
    self.activeEvent = {
        func = nextEvent.func,
        args = nextEvent.args,
        label = nextEvent.label,
        startedAt = g_time or 0,
        kind = "queued"
    }
    nextEvent.func(self, table.unpack(nextEvent.args))
    return true
end

function FarmingLive:showThrottledWarning(key, message, duration, intervalMS, modeOverride)
    local now      = g_time or 0
    local lastTime = self.warningTimestamps[key] or 0
    if now - lastTime < intervalMS then return end
    self.warningTimestamps[key] = now
    self:showWarning(message, duration, modeOverride)
end

function FarmingLive:getNetworkContext()
    local mission = g_currentMission
    local isDedicated = (g_dedicatedServer ~= nil)
    local isServer    = mission:getIsServer() and not isDedicated
    local isClient    = mission:getIsClient() and not isDedicated

   return {
        isDedicatedServer = isDedicated,
        isMP              = mission.missionDynamicInfo.isMultiplayer == true,
        isServer          = isServer,
        isClient          = isClient
    }
end
