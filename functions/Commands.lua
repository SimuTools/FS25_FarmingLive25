local function flCmdTrim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function flCmdBuildText(...)
    return flCmdTrim(table.concat({ ... }, " "))
end

local function flCmdLoadPendingCommandsFromXml(self)
    self.pendingCommands = self.pendingCommands or {}

    if #self.pendingCommands > 0 then
        return 0
    end

    local xmlFile = loadXMLFile("FarmingLiveCommand", self.xmlFilePath)
    if not xmlFile or xmlFile == 0 then
        print("[FarmingLive] Command-XML korrupt oder leer – lösche und lege neu an.")
        if xmlFile and xmlFile ~= 0 then
            delete(xmlFile)
        end

        if self.xmlFilePath and fileExists(self.xmlFilePath) then
            deleteFile(self.xmlFilePath)
        end

        local tmp = createXMLFile("FarmingLiveCommand", self.xmlFilePath, "commands")
        saveXMLFile(tmp)
        delete(tmp)

        xmlFile = loadXMLFile("FarmingLiveCommand", self.xmlFilePath)
        if not xmlFile or xmlFile == 0 then
            print("[FarmingLive - ERROR] Konnte Command-XML auch nach Neuanlage nicht laden, breche ab.")
            return 0
        end
    end

    local baseNode, idx, loaded = "commands.command", 0, 0
    while true do
        local path = string.format("%s(%d)", baseNode, idx)
        local name = getXMLString(xmlFile, path .. "#name")
        if not name then
            break
        end

        local player = getXMLString(xmlFile, path .. "#playerName")
        local input  = getXMLString(xmlFile, path .. "#userInput")
        table.insert(self.pendingCommands, { name = name, player = player, input = input })

        removeXMLProperty(xmlFile, path)
        idx = idx + 1
        loaded = loaded + 1
    end

    if idx > 0 then
        saveXMLFile(xmlFile)
    end
    delete(xmlFile)

    return loaded
end

local function flCmdSortedKeys(map)
    local keys = {}
    for k, _ in pairs(map or {}) do
        keys[#keys + 1] = tostring(k)
    end
    table.sort(keys)
    return keys
end

local function flCmdCountDisabled(disabledCommands)
    local count = 0
    for _, value in pairs(disabledCommands or {}) do
        if value then
            count = count + 1
        end
    end
    return count
end

local function flCmdBuildQueueEntries(self)
    local entries = {}

    flCmdLoadPendingCommandsFromXml(self)

    for i, entry in ipairs(self.pendingCommands or {}) do
        entries[#entries + 1] = {
            source = "pendingCommand",
            index = i,
            label = string.format("CMD %s | player=%s | input=%s", tostring(entry.name), tostring(entry.player), tostring(entry.input))
        }
    end

    for i, entry in ipairs(self.eventQueue or {}) do
        entries[#entries + 1] = {
            source = "eventQueue",
            index = i,
            label = string.format("EVENT %s | args=%d", tostring(entry.label or entry.func), #(entry.args or {}))
        }
    end

    for i, entry in ipairs(self.pendingVehicleActions or {}) do
        entries[#entries + 1] = {
            source = "vehicleAction",
            index = i,
            label = string.format("VEHICLE %s | args=%d", tostring(self:describeCallable(entry.func)), #(entry.args or {}))
        }
    end

    return entries
end

local function flCmdRestoreAllVehiclePhysicsHooks(self)
    local states = self._vehiclePhysicsHookStates
    if type(states) ~= "table" then
        return 0
    end

    local restored = 0
    for vehicle, state in pairs(states) do
        if vehicle ~= nil and state ~= nil and type(state.originalUpdateVehiclePhysics) == "function" then
            vehicle.updateVehiclePhysics = state.originalUpdateVehiclePhysics
            restored = restored + 1
        end
        states[vehicle] = nil
    end

    return restored
end

function FarmingLive:registerCommand(commandName, handler, meta)
    if type(commandName) ~= "string" or commandName == "" then
        print("[FarmingLive] registerCommand: ungültiger Command-Name.")
        return
    end

    if type(handler) ~= "function" then
        print(string.format("[FarmingLive] registerCommand: Handler für '%s' ist keine Funktion.", tostring(commandName)))
        return
    end

    self.commandHandlers = self.commandHandlers or {}
    self.commandMeta = self.commandMeta or {}
    self.disabledCommands = self.disabledCommands or {}
    self.commandDispatchHistory = self.commandDispatchHistory or {}
    self.commandHandlers[commandName] = handler
    self.commandMeta[commandName] = meta or {}
end

function FarmingLive:dispatchCommand(commandName, playerName, userInput)
    local handler = self.commandHandlers and self.commandHandlers[commandName]
    if handler == nil then
        print(string.format("[FarmingLive] Unbekannter Command '%s' (player=%s, input=%s)", tostring(commandName), tostring(playerName), tostring(userInput)))
        return false
    end

    if self.disabledCommands ~= nil and self.disabledCommands[commandName] then
        print(string.format("[FarmingLive] Command '%s' ist deaktiviert.", tostring(commandName)))
        return false
    end

    handler(self, playerName, userInput)

    self.commandDispatchHistory = self.commandDispatchHistory or {}
    self.commandDispatchHistory[commandName] = {
        lastRun = g_time or 0,
        player = playerName,
        input = userInput,
        count = ((self.commandDispatchHistory[commandName] and self.commandDispatchHistory[commandName].count) or 0) + 1
    }

    self._lastDispatchedCommand = {
        name = commandName,
        player = playerName,
        input = userInput,
        time = g_time or 0
    }

    return true
end

function FarmingLive:checkForCommand(dt)
    local ctx = self:getNetworkContext()
    if not ctx.isClient then
        return
    end

    flCmdLoadPendingCommandsFromXml(self)

    if self.queuePaused then
        return
    end

    local maxPerFrame = 1
    for _ = 1, math.min(maxPerFrame, #self.pendingCommands) do
        local cmd = table.remove(self.pendingCommands, 1)
        self:dispatchCommand(cmd.name, cmd.player, cmd.input)

        if #FarmingLive.eventQueue > 0 then
            local infoText = string.format("Warteschlange: %d Event(s) aktiv", #FarmingLive.eventQueue)
            if g_currentMission and g_currentMission.hud and g_currentMission.hud.addSideNotification then
                g_currentMission.hud:addSideNotification(HUD.COLOR.DEFAULT, infoText, 10000)
            end
        end
    end
end

function FarmingLive:registerEventQueueConsoleCommands()
    if self._flEventQueueConsoleCommandsRegistered then
        return
    end

    addConsoleCommand("flEventList", "Listet alle FarmingLive Event-Commands", "consoleCommandEventList", self)
    addConsoleCommand("flEventRun", "Startet einen Event-Command: flEventRun <command> [player] [input]", "consoleCommandEventRun", self)
    addConsoleCommand("flEventStop", "Stoppt bestmöglich aktives Event und leert Warteschlangen", "consoleCommandEventStop", self)
    addConsoleCommand("flEventDisable", "Deaktiviert einen Event-Command", "consoleCommandEventDisable", self)
    addConsoleCommand("flEventEnable", "Aktiviert einen Event-Command", "consoleCommandEventEnable", self)
    addConsoleCommand("flEventStatus", "Zeigt Event-/Queue-Status", "consoleCommandEventStatus", self)
    addConsoleCommand("flEventCooldowns", "Zeigt letzte Event-Ausführungen / Cooldowns", "consoleCommandEventCooldowns", self)

    addConsoleCommand("flQueueList", "Listet XML-, Event- und Fahrzeug-Warteschlangen", "consoleCommandQueueList", self)
    addConsoleCommand("flQueueClear", "Leert alle Warteschlangen", "consoleCommandQueueClear", self)
    addConsoleCommand("flQueueRemove", "Entfernt einen Warteschlangen-Eintrag nach Index", "consoleCommandQueueRemove", self)
    addConsoleCommand("flQueuePause", "Pausiert die FarmingLive-Warteschlangen", "consoleCommandQueuePause", self)
    addConsoleCommand("flQueueResume", "Setzt die FarmingLive-Warteschlangen fort", "consoleCommandQueueResume", self)
    addConsoleCommand("flQueueRunNext", "Führt den nächsten Warteschlangen-Eintrag sofort aus", "consoleCommandQueueRunNext", self)

    self._flEventQueueConsoleCommandsRegistered = true
end

function FarmingLive:unregisterEventQueueConsoleCommands()
    if not self._flEventQueueConsoleCommandsRegistered then
        return
    end

    removeConsoleCommand("flEventList")
    removeConsoleCommand("flEventRun")
    removeConsoleCommand("flEventStop")
    removeConsoleCommand("flEventDisable")
    removeConsoleCommand("flEventEnable")
    removeConsoleCommand("flEventStatus")
    removeConsoleCommand("flEventCooldowns")
    removeConsoleCommand("flQueueList")
    removeConsoleCommand("flQueueClear")
    removeConsoleCommand("flQueueRemove")
    removeConsoleCommand("flQueuePause")
    removeConsoleCommand("flQueueResume")
    removeConsoleCommand("flQueueRunNext")

    self._flEventQueueConsoleCommandsRegistered = false
end

function FarmingLive:consoleCommandEventList()
    local keys = flCmdSortedKeys(self.commandHandlers or {})
    print("[FarmingLive] Registrierte Event-Commands:")
    for _, name in ipairs(keys) do
        local meta = (self.commandMeta or {})[name] or {}
        local disabled = self.disabledCommands and self.disabledCommands[name] and "disabled" or "enabled"
        print(string.format("  %s [%s] category=%s module=%s", name, disabled, tostring(meta.category or "-"), tostring(meta.module or "-")))
    end
    return string.format("%d Event-Commands gelistet.", #keys)
end

function FarmingLive:consoleCommandEventRun(commandName, playerName, ...)
    local name = flCmdTrim(commandName)
    if name == "" then
        return "Benutzung: flEventRun <command> [player] [input]"
    end

    local player = flCmdTrim(playerName)
    if player == "" then
        player = "Console"
    end

    local input = flCmdBuildText(...)
    if input == "" then
        input = nil
    end

    local ok = self:dispatchCommand(name, player, input)
    if ok then
        return string.format("Event-Command '%s' gestartet.", name)
    end
    return string.format("Event-Command '%s' konnte nicht gestartet werden.", name)
end

function FarmingLive:consoleCommandEventStop()
    local restoredHooks = flCmdRestoreAllVehiclePhysicsHooks(self)
    local clearedEvents = #(self.eventQueue or {})
    local clearedCommands = #(self.pendingCommands or {})
    local clearedVehicle = #(self.pendingVehicleActions or {})
    local hadActive = self.activeEvent ~= nil

    self.eventQueue = {}
    self.pendingCommands = {}
    self.pendingVehicleActions = {}
    self.activeEvent = nil

    return string.format("Best effort stop: active=%s, queue=%d, pending=%d, vehicle=%d, hooks=%d", tostring(hadActive), clearedEvents, clearedCommands, clearedVehicle, restoredHooks)
end

function FarmingLive:consoleCommandEventDisable(commandName)
    local name = flCmdTrim(commandName)
    if name == "" then
        return "Benutzung: flEventDisable <command>"
    end

    if self.commandHandlers == nil or self.commandHandlers[name] == nil then
        return "Unbekannter Event-Command: " .. name
    end

    self.disabledCommands = self.disabledCommands or {}
    self.disabledCommands[name] = true
    return "Deaktiviert: " .. name
end

function FarmingLive:consoleCommandEventEnable(commandName)
    local name = flCmdTrim(commandName)
    if name == "" then
        return "Benutzung: flEventEnable <command>"
    end

    if self.commandHandlers == nil or self.commandHandlers[name] == nil then
        return "Unbekannter Event-Command: " .. name
    end

    self.disabledCommands = self.disabledCommands or {}
    self.disabledCommands[name] = nil
    return "Aktiviert: " .. name
end

function FarmingLive:consoleCommandEventStatus()
    local activeLabel = self.activeEvent and tostring(self.activeEvent.label or self.activeEvent.func or "active") or "none"
    local disabledCount = flCmdCountDisabled(self.disabledCommands)
    return string.format("active=%s | eventQueue=%d | pendingCommands=%d | pendingVehicle=%d | paused=%s | disabled=%d", activeLabel, #(self.eventQueue or {}), #(self.pendingCommands or {}), #(self.pendingVehicleActions or {}), tostring(self.queuePaused == true), disabledCount)
end

function FarmingLive:consoleCommandEventCooldowns()
    local keys = flCmdSortedKeys(self.commandHandlers or {})
    local now = g_time or 0
    local lines = 0

    print("[FarmingLive] Event-Cooldowns / letzte Ausführungen:")
    for _, name in ipairs(keys) do
        local meta = (self.commandMeta or {})[name] or {}
        local hist = (self.commandDispatchHistory or {})[name]
        local cooldownMs = tonumber(meta.cooldownMs or meta.cooldown or 0) or 0
        if hist ~= nil or cooldownMs > 0 then
            local age = hist and (now - (hist.lastRun or 0)) or nil
            print(string.format("  %s | cooldownMs=%d | lastAgoMs=%s | count=%s", name, cooldownMs, age and tostring(age) or "-", hist and tostring(hist.count or 1) or "0"))
            lines = lines + 1
        end
    end

    if lines == 0 then
        return "Keine expliziten Event-Cooldowns vorhanden; letzte Läufe noch nicht erfasst."
    end

    return string.format("%d Event-Einträge mit Cooldown-/Laufdaten gelistet.", lines)
end

function FarmingLive:consoleCommandQueueList()
    local entries = flCmdBuildQueueEntries(self)
    print(string.format("[FarmingLive] Queue paused=%s", tostring(self.queuePaused == true)))
    if self.activeEvent ~= nil then
        print(string.format("  ACTIVE | %s", tostring(self.activeEvent.label or self.activeEvent.func or "active")))
    end
    for i, entry in ipairs(entries) do
        print(string.format("  %d) %s", i, entry.label))
    end
    return string.format("%d Queue-Einträge gelistet.", #entries)
end

function FarmingLive:consoleCommandQueueClear()
    local count = #(self.pendingCommands or {}) + #(self.eventQueue or {}) + #(self.pendingVehicleActions or {})
    self.pendingCommands = {}
    self.eventQueue = {}
    self.pendingVehicleActions = {}
    return string.format("%d Queue-Einträge entfernt.", count)
end

function FarmingLive:consoleCommandQueueRemove(index)
    local idx = tonumber(index)
    if idx == nil then
        return "Benutzung: flQueueRemove <index>"
    end

    local entries = flCmdBuildQueueEntries(self)
    local entry = entries[idx]
    if entry == nil then
        return "Queue-Index nicht gefunden: " .. tostring(idx)
    end

    if entry.source == "pendingCommand" then
        table.remove(self.pendingCommands, entry.index)
    elseif entry.source == "eventQueue" then
        table.remove(self.eventQueue, entry.index)
    elseif entry.source == "vehicleAction" then
        table.remove(self.pendingVehicleActions, entry.index)
    end

    return "Entfernt: " .. tostring(entry.label)
end

function FarmingLive:consoleCommandQueuePause()
    self.queuePaused = true
    return "FarmingLive Queue pausiert."
end

function FarmingLive:consoleCommandQueueResume()
    self.queuePaused = false
    self:tryNextEvent()
    return "FarmingLive Queue fortgesetzt."
end

function FarmingLive:consoleCommandQueueRunNext()
    local prevPaused = self.queuePaused
    self.queuePaused = false

    local beforePending = #(self.pendingCommands or {})
    flCmdLoadPendingCommandsFromXml(self)
    local executed = false

    if #self.pendingCommands > 0 then
        local cmd = table.remove(self.pendingCommands, 1)
        executed = self:dispatchCommand(cmd.name, cmd.player, cmd.input)
    elseif not self.activeEvent and #self.eventQueue > 0 then
        executed = self:tryNextEvent(true)
    elseif #self.pendingVehicleActions > 0 and g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() ~= nil then
        local entry = table.remove(self.pendingVehicleActions, 1)
        self:queueEvent(entry.func, table.unpack(entry.args))
        executed = self:tryNextEvent(true) or true
    end

    self.queuePaused = prevPaused

    if executed then
        return "Nächster Queue-Eintrag ausgeführt."
    end
    return "Kein ausführbarer Queue-Eintrag vorhanden."
end
