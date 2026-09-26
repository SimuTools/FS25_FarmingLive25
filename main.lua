FarmingLive = {}
FarmingLive.modName = g_currentModName
FarmingLive.modDir = g_currentModDirectory
FarmingLive.config = {}
FarmingLive.warningTimestamps = {}
FarmingLive.pendingVehicleActions = {}

FarmingLive.eventQueue = {}
FarmingLive.activeEvent = nil

FarmingLive._prevHeadtrackState = nil
FarmingLive._hasPrevState = false
FarmingLive.i18n = { lang = g_languageShort or "de", map = {} }
FarmingLive._origGetCurrentVehicle = FarmingLive._origGetCurrentVehicle or nil
FarmingLive._lastVehicle = FarmingLive._lastVehicle or nil

FarmingLive.commandHandlers = {}
FarmingLive.commandMeta = {}
FarmingLive.disabledCommands = {}
FarmingLive.commandDispatchHistory = {}
FarmingLive.queuePaused = false

FarmingLive._messageUiState = {}
FarmingLive._flMessageConsoleCommandsRegistered = false
FarmingLive._flLoadMapInitialized = false
FarmingLive._flConfigConsoleCommandsRegistered = false
FarmingLive._flEventQueueConsoleCommandsRegistered = false

function FarmingLive:deleteMap()
    if self.unregisterMessageConsoleCommands ~= nil then
        self:unregisterMessageConsoleCommands()
    end

    if self.unregisterConfigConsoleCommands ~= nil then
        self:unregisterConfigConsoleCommands()
    end

    if self.unregisterEventQueueConsoleCommands ~= nil then
        self:unregisterEventQueueConsoleCommands()
    end

    self._flEventMenuKeyWasPressed = false
    self._messageUiState = {}
    self._flLoadMapInitialized = false
    self.queuePaused = false
    self.disabledCommands = {}
end
