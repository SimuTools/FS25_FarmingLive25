function FarmingLive:UselessBox(customHeaderText)
  print("[FarmingLive] UselessBox ausgelöst")
  
  local header = customHeaderText
  if not header or header == "" then
    header = "Simu Like Trains"
  end
  InfoDialog.show(header)
end

function createDirectoryIfNotExists(directoryPath)
    if not fileExists(directoryPath) then
        createFolder(directoryPath)
    end
end

function FarmingLive:loadMap(name)
    addModEventListener(FarmingLiveAddMoneyEvent)
    addModEventListener(FarmingLiveSetMassEvent)
    addModEventListener(FarmingLiveClearFuelEvent)
    addModEventListener(FarmingLiveDetachImplementsEvent)
    addModEventListener(FarmingLiveAttachmentDropEvent)
    addModEventListener(FarmingLiveAdjustDieselEvent)
    addModEventListener(FarmingLiveLockDoorEvent)
    addModEventListener(FarmingLiveSpeedLimitBlockEvent)
    addModEventListener(FarmingLiveBlockMotorEvent)
	addModEventListener(FarmingLiveDriveDirBlockEvent)
	addModEventListener(FarmingLiveLaunchVehicleEvent)
    addModEventListener(FarmingLiveSetDirtEvent)
    addModEventListener(FarmingLiveSetBrokenEvent)
    addModEventListener(FarmingLiveSetTimeEvent)
    addModEventListener(FarmingLiveFlatTireEvent)
    addModEventListener(FarmingLiveTirePartyEvent)
    addModEventListener(FarmingLiveRandomSteerEvent)
    addModEventListener(FarmingLiveForbidSteerEvent)
    addModEventListener(FarmingLiveInvertControlsEvent)

	
    local ctx = self:getNetworkContext()

    if not ctx.isClient then
        return
    end

    if self._flLoadMapInitialized then
        return
    end
    self._flLoadMapInitialized = true

    self:registerMessageConsoleCommands()
    self:registerConfigConsoleCommands()
    self:registerEventQueueConsoleCommands()
    self:registerEventMenuGui()

    print("\n##### FarmingLive #####\n")
    print("[FarmingLive - SimuTools] Thank you for using FarmingLive")
    print("[FarmingLive - SimuTools] Feedback or suggestions: https://discord.gg/C9yRZmQ6M3")
    print("[FarmingLive - SimuTools] Twitch: https://www.twitch.tv/simutools")
    print("[FarmingLive - SimuTools] FarmingLive Tutorial: https://youtu.be/8T8VfQRIEk")
	print("[FarmingLive - Iwan1803]  Webseite: https://iwan1803.de (Danke fürs Testen)")
    print("\n##### FarmingLive #####")

	FarmingLive._origGetCurrentVehicle = FarmingLive._origGetCurrentVehicle or nil
	FarmingLive._lastVehicle = FarmingLive._lastVehicle or nil
	
	local lang = FarmingLive:detectLanguage()
	FarmingLive:loadLocale(lang)
	

    local modSettingsPath = getUserProfileAppPath() .. "modSettings/" .. FarmingLive.modName .. "/"
    createDirectoryIfNotExists(modSettingsPath)

    self.xmlFilePath    = modSettingsPath .. "FarmingLiveCommand.xml"
    FarmingLive.configFilePath = modSettingsPath .. "FarmingLiveConfig.xml"

    if not fileExists(self.xmlFilePath) then
        local cmdXml = createXMLFile("FarmingLiveCommand", self.xmlFilePath, "commands")
        saveXMLFile(cmdXml)
        delete(cmdXml)
        print("[FarmingLive - CHANGE] Command XML file created at " .. self.xmlFilePath)
    end

    if not fileExists(FarmingLive.configFilePath) then
        local cfgXml = createXMLFile("FarmingLiveConfig", FarmingLive.configFilePath, "config")
        FarmingLive:addMissingConfigEntries(cfgXml)
        saveXMLFile(cfgXml)
        delete(cfgXml)
        print("[FarmingLive - CHANGE] Config XML file created at " .. FarmingLive.configFilePath)
    end

    local configXML = loadXMLFile("FarmingLiveConfig", FarmingLive.configFilePath)
    if not configXML then
        print("[FarmingLive - ERROR] Could not load config XML at " .. FarmingLive.configFilePath)
        return
    end

-- kleine Helfer fürs Laden
local function T(path, defaultKey)
  return FarmingLive:resolveTemplate(getXMLString(configXML, path) or defaultKey)
end
local function N(path, defaultNum)
  return getXMLInt(configXML, path) or defaultNum
end
local function S(path, defaultValue)
  return getXMLString(configXML, path) or defaultValue
end
local function F(path, defaultNum)
  return (getXMLFloat and getXMLFloat(configXML, path)) or getXMLInt(configXML, path) or defaultNum
end
local function NormalizeLegacyMessageMode(path, value)
  local s = tostring(value or "")
  local normalized = s:lower()
  if normalized == "warning" then
    setXMLString(configXML, path, "default")
    return "default", true
  end
  return value, false
end

FarmingLive:addMissingConfigEntries(configXML)

FarmingLive.config.tempMass = {
  weight  = N("config.tempMass.weight", DEFAULT_MASS),
  message = T("config.tempMass.message", DEFAULT_TEMPORARY_MASS_MESSAGE),
}

FarmingLive.config.fadeScreen = {
  duration       = N("config.fadeScreen.duration",       DEFAULT_FADE_SCREEN_DURATION),
  warningMessage = T("config.fadeScreen.warningMessage", DEFAULT_FADE_SCREEN_WARNING_MESSAGE),
}

FarmingLive.config.showUser = {
  warningMessage  = T("config.showUser.warningMessage",  DEFAULT_SHOW_USER_WARNING_MESSAGE),
  warningMessage2 = T("config.showUser.warningMessage2", DEFAULT_SHOW_USER_WARNING_MESSAGE2),
  warningMessage3 = T("config.showUser.warningMessage3", DEFAULT_SHOW_USER_WARNING_MESSAGE3),
  warningMessage4 = T("config.showUser.warningMessage4", DEFAULT_SHOW_USER_WARNING_MESSAGE4),
  warningMessage5 = T("config.showUser.warningMessage5", DEFAULT_SHOW_USER_WARNING_MESSAGE5),
  duration        = N("config.showUser.duration",        DEFAULT_SHOW_USER_DURATION),
  messageMode     = S("config.showUser.messageMode",     DEFAULT_SHOW_USER_MESSAGE_MODE),
}

FarmingLive.config.showHi = {
  warningMessage = T("config.showHi.warningMessage", DEFAULT_SHOW_HI_WARNING_MESSAGE),
  duration       = N("config.showHi.duration",       DEFAULT_SHOW_HI_DURATION),
  messageMode    = S("config.showHi.messageMode",    DEFAULT_SHOW_HI_MESSAGE_MODE),
}

FarmingLive.config.showSimu = {
  duration    = N("config.showSimu.duration",    DEFAULT_SHOW_SIMU_DURATION),
  messageMode = S("config.showSimu.messageMode", DEFAULT_SHOW_SIMU_MESSAGE_MODE),
}

FarmingLive.config.messageApi = {
  mode          = S("config.messageApi.mode",          DEFAULT_MESSAGE_API_MODE),
  background    = S("config.messageApi.background",    DEFAULT_MESSAGE_API_BACKGROUND),
  toastX        = F("config.messageApi.toastX",        DEFAULT_MESSAGE_API_TOAST_X),
  toastY        = F("config.messageApi.toastY",        DEFAULT_MESSAGE_API_TOAST_Y),
  toastScale    = F("config.messageApi.toastScale",    DEFAULT_MESSAGE_API_TOAST_SCALE),
  toastAlign    = S("config.messageApi.toastAlign",    DEFAULT_MESSAGE_API_TOAST_ALIGN),
  centerX       = F("config.messageApi.centerX",       DEFAULT_MESSAGE_API_CENTER_X),
  centerY       = F("config.messageApi.centerY",       DEFAULT_MESSAGE_API_CENTER_Y),
  centerScale   = F("config.messageApi.centerScale",   DEFAULT_MESSAGE_API_CENTER_SCALE),
  centerAlign   = S("config.messageApi.centerAlign",   DEFAULT_MESSAGE_API_CENTER_ALIGN),
  paddingX      = F("config.messageApi.paddingX",      DEFAULT_MESSAGE_API_PADDING_X),
  paddingY      = F("config.messageApi.paddingY",      DEFAULT_MESSAGE_API_PADDING_Y),
  bgR           = F("config.messageApi.bgR",           DEFAULT_MESSAGE_API_BG_R),
  bgG           = F("config.messageApi.bgG",           DEFAULT_MESSAGE_API_BG_G),
  bgB           = F("config.messageApi.bgB",           DEFAULT_MESSAGE_API_BG_B),
  bgA           = F("config.messageApi.bgA",           DEFAULT_MESSAGE_API_BG_A),
  textR         = F("config.messageApi.textR",         DEFAULT_MESSAGE_API_TEXT_R),
  textG         = F("config.messageApi.textG",         DEFAULT_MESSAGE_API_TEXT_G),
  textB         = F("config.messageApi.textB",         DEFAULT_MESSAGE_API_TEXT_B),
  textA         = F("config.messageApi.textA",         DEFAULT_MESSAGE_API_TEXT_A),
  consolePrefix = S("config.messageApi.consolePrefix", DEFAULT_MESSAGE_API_CONSOLE_PREFIX),
}

FarmingLive.config.clearFuel = {
  message = T("config.clearFuel.message", DEFAULT_CLEAR_FUEL_MESSAGE),
}

FarmingLive.config.setBroken = {
  message     = T("config.setBroken.message",     DEFAULT_SET_BROKEN_MESSAGE),
  failmessage = T("config.setBroken.failmessage", DEFAULT_WARNING_MOTOR_FAIL_MESSAGE),
}

FarmingLive.config.adjustMoney = {
  positiveMessage = T("config.adjustMoney.positiveMessage", DEFAULT_ADJUST_MONEY_POSITIVE_MESSAGE),
  negativeMessage = T("config.adjustMoney.negativeMessage", DEFAULT_ADJUST_MONEY_NEGATIVE_MESSAGE),
  MIN_VALUE       = N("config.adjustMoney.MIN_VALUE",       DEFAULT_MIN_VALUE),
  MAX_VALUE       = N("config.adjustMoney.MAX_VALUE",       DEFAULT_MAX_VALUE),
}

FarmingLive.config.setDirt = {
  message      = T("config.setDirt.message",       DEFAULT_SET_DIRT_MESSAGE),
  cleanmessage = T("config.setDirt.cleanmessage",  DEFAULT_SET_DIRT_CLEANMESSAGE),
}

FarmingLive.config.setTime = {
  message = T("config.setTime.message", DEFAULT_SETTIME_MESSAGE),
}

FarmingLive.config.setSpeed = {
  maxspeed              = N("config.setSpeed.maxspeed",  DEFAULT_MaxSpeed),
  minspeed              = N("config.setSpeed.minspeed",  DEFAULT_MinSpeed),
  maxtime               = N("config.setSpeed.maxtime",   DEFAULT_MaxTime),
  mintime               = N("config.setSpeed.mintime",   DEFAULT_MinTime),
  warningSpeedLimit     = T("config.setSpeed.warningSpeedLimit",     DEFAULT_WARNING_SPEED_LIMIT_MESSAGE),
  warningMotorPause     = T("config.setSpeed.warningMotorPause",     DEFAULT_WARNING_MOTOR_PAUSE_MESSAGE),
  warningMotorOverspeed = T("config.setSpeed.warningMotorOverspeed", DEFAULT_WARNING_MOTOR_OVERSPEED_MESSAGE),
  warningMotorBlocked   = T("config.setSpeed.warningMotorBlocked",   DEFAULT_WARNING_MOTOR_BLOCKED_MESSAGE),
}

FarmingLive.config.blockEngine = {
  warningMotorStopped = T("config.blockEngine.warningMotorStopped", DEFAULT_WARNING_MOTOR_STOPPED_MESSAGE),
  warningMotorActive  = T("config.blockEngine.warningMotorActive",  DEFAULT_WARNING_MOTOR_ACTIVE_MESSAGE),
  warningMotorIgnored = T("config.blockEngine.warningMotorIgnored", DEFAULT_WARNING_MOTOR_IGNORED_MESSAGE),
}

FarmingLive.config.blockTab = {
  maxtime        = N("config.blockTab.maxtime",        DEFAULT_BlockMaxTime),
  mintime        = N("config.blockTab.mintime",        DEFAULT_BlockMinTime),
  blockmessage   = T("config.blockTab.blockmessage",   DEFAULT_BlockTabMessage),
  unblockmessage = T("config.blockTab.unblockmessage", DEFAULT_BlockTabUnblockMessage),
  trytab         = T("config.blockTab.trytab",         DEFAULT_TryTabMessage),
}

FarmingLive.config.drivingEnforce = {
  maxtime              = N("config.drivingEnforce.maxtime",              DEFAULT_DriveDirMaxTime),
  mintime              = N("config.drivingEnforce.mintime",              DEFAULT_DriveDirMinTime),
  DriveDirWarnmessage  = T("config.drivingEnforce.DriveDirWarnmessage",  DEFAULT_DriveDirWarnmessage),
  DriveDirResetmessage = T("config.drivingEnforce.DriveDirResetmessage", DEFAULT_DriveDirResetmessage),
  BlockWarn            = T("config.drivingEnforce.BlockWarn",            DEFAULT_DriveDirBlockWarn),
  DriveDirForward      = T("config.drivingEnforce.DriveDirForward",      DEFAULT_DriveDirForward),
  DriveDirBackward     = T("config.drivingEnforce.DriveDirBackward",     DEFAULT_DriveDirBackward),
}

FarmingLive.config.cameraFun = {
  WarnMessage     = T("config.cameraFun.WarnMessage",     DEFAULT_cameraFun_WarnMessage),
  cameraBlocked   = T("config.cameraFun.cameraBlocked",   DEFAULT_cameraFun_cameraBlocked),
  cameraUnblocked = T("config.cameraFun.cameraUnblocked", DEFAULT_cameraFun_cameraUnblocked),
  ZoomMin         = T("config.cameraFun.ZoomMin",         DEFAULT_cameraFun_ZoomMin),
  ZoomMax         = T("config.cameraFun.ZoomMax",         DEFAULT_cameraFun_ZoomMax),
  UseZoom         = T("config.cameraFun.UseZoom",         DEFAULT_cameraFun_UseZoom),
  TimeMax         = T("config.cameraFun.TimeMax",         DEFAULT_cameraFun_TimeMax),
  TimeMin         = T("config.cameraFun.TimeMin",         DEFAULT_cameraFun_TimeMin),
}

FarmingLive.config.invertControls = {
  minMinutes    = N("config.invertControls.minMinutes", 1),
  maxMinutes    = N("config.invertControls.maxMinutes", 5),
  WarnMessage   = T("config.invertControls.WarnMessage",   DEFAULT_invertControlsWarnMessage),
  UnblockMessage= T("config.invertControls.UnblockMessage",DEFAULT_invertControlsUnblockMessage),
  BlockMessage  = T("config.invertControls.BlockMessage",  DEFAULT_invertControlsBlockMessage),
}

FarmingLive.config.adjustDiesel = {
  getFuel = T("config.adjustDiesel.getFuel", DEFAULT_Adjust_FUEL_GETMESSAGE),
  remFuel = T("config.adjustDiesel.remFuel", DEFAULT_Adjust_FUEL_REMMESSAGE),
}

FarmingLive.config.BlockAndLock = {
  KEYOUT   = T("config.BlockAndLock.KEYOUT",   DEFAULT_BlockAndLock_KEYOUT),
  KEYFOUND = T("config.BlockAndLock.KEYFOUND", DEFAULT_BlockAndLock_KEYFOUND),
}

FarmingLive.config.triggerHonk = {
  warnmessage = T("config.triggerHonk.warnmessage", DEFAULT_triggerHonk_warnmessage),
}

FarmingLive.config.forbiddenSteeringDir = {
  maxMinutes   = N("config.forbiddenSteeringDir.maxMinutes", 5),
  minMinutes   = N("config.forbiddenSteeringDir.minMinutes", 1),
  left         = T("config.forbiddenSteeringDir.left",         DEFAULT_forbiddenSteeringDirLeft),
  right        = T("config.forbiddenSteeringDir.right",        DEFAULT_forbiddenSteeringDirRight),
  BlockWarn    = T("config.forbiddenSteeringDir.BlockWarn",    DEFAULT_forbiddenSteeringDirBlockWarn),
  BlockWarnTry = T("config.forbiddenSteeringDir.BlockWarnTry", DEFAULT_forbiddenSteeringDirBlockWarnTry),
  BlockWarnReset = T("config.forbiddenSteeringDir.BlockWarnReset", DEFAULT_forbiddenSteeringDirBlockWarnReset),
}

FarmingLive.config.randomSteer = {
  BlockStart   = T("config.randomSteer.BlockStart",   DEFAULT_RANDOMSTEER_BLOCKSTART),
  SegmentStart = T("config.randomSteer.SegmentStart", DEFAULT_RANDOMSTEER_SEGMENTSTART),
  BlockEnd     = T("config.randomSteer.BlockEnd",     DEFAULT_RANDOMSTEER_BLOCKEND),
  DirLeft      = T("config.randomSteer.DirLeft",      DEFAULT_RANDOMSTEER_DIRLEFT),
  DirRight     = T("config.randomSteer.DirRight",     DEFAULT_RANDOMSTEER_DIRRIGHT),
}

FarmingLive.config.launchVehicle = {
  LaunchVehicleUpImp       = N("config.launchVehicle.LaunchVehicleUpImp",  tonumber(DEFAULT_LAUNCHVEHUPIMP)),
  LaunchVehicleFwdImp      = N("config.launchVehicle.LaunchVehicleFwdImp", tonumber(DEFAULT_LAUNCHVEHFWDIMP)),
  LaunchVehicleWarnMessage = T("config.launchVehicle.LaunchVehicleWarnMessage", DEFAULT_LAUNCHVEHWARNMESSAGE),
}

FarmingLive.config.lockInteriorCamera = {
  IntoriorCamWarnMessage    = T("config.lockInteriorCamera.IntoriorCamWarnMessage",    DEFAULT_INTERIORCAMWARNMESSAGE),
  IntoriorCamBlockMessage   = T("config.lockInteriorCamera.IntoriorCamBlockMessage",   DEFAULT_INTERIORCAMBLOCKMESSAGE),
  IntoriorCamUnblockMessage = T("config.lockInteriorCamera.IntoriorCamUnblockMessage", DEFAULT_INTERIORCAMUNBLOCKMESSAGE),
  IntoriorCamMinTime        = N("config.lockInteriorCamera.IntoriorCamMinTime",        DEFAULT_INTERIORCAMMINTIME),
  IntoriorCamMaxTime        = N("config.lockInteriorCamera.IntoriorCamMaxTime",        DEFAULT_INTERIORCAMMAXTIME),
}

FarmingLive.config.toggleWipers = {
  TOGWipersWarnmessage       = T("config.toggleWipers.TOGWipersWarnmessage",       DEFAULT_TOGWIPERMESSAGE),
  TOGWipersDeaktivatemessage = T("config.toggleWipers.TOGWipersDeaktivatemessage", DEFAULT_TOGWIPERDEAKTIVATEMESSAGE),
  TOGWipersMinTime           = N("config.toggleWipers.TOGWipersMinTime",           DEFAULT_TOGWIPERMINTIME),
  TOGWipersMaxTime           = N("config.toggleWipers.TOGWipersMaxTime",           DEFAULT_TOGWIPERMAXTIME),
}

FarmingLive.config.walking = {
  start        = T("config.walking.start",        DEFAULT_WALKING_START),
  enterBlocked = T("config.walking.enterBlocked", DEFAULT_WALKING_ENTERBLOCKED),
  done         = T("config.walking.done",         DEFAULT_WALKING_DONE),
  warn1        = T("config.walking.warn1",        DEFAULT_WALKING_WARN1),
  warn2        = T("config.walking.warn2",        DEFAULT_WALKING_WARN2),
  warn3        = T("config.walking.warn3",        DEFAULT_WALKING_WARN3),
  warn4        = T("config.walking.warn4",        DEFAULT_WALKING_WARN4),
  warn5        = T("config.walking.warn5",        DEFAULT_WALKING_WARN5),
}

FarmingLive.config.flatTire = {
  minMinutes = N("config.flatTire.minMinutes", DEFAULT_FLAT_TIRE_MIN_MINUTES),
  maxMinutes = N("config.flatTire.maxMinutes", DEFAULT_FLAT_TIRE_MAX_MINUTES),
  brakePulseMs = N("config.flatTire.brakePulseMs", DEFAULT_FLAT_TIRE_BRAKE_PULSE_MS),
  wobbleMs   = N("config.flatTire.wobbleMs", DEFAULT_FLAT_TIRE_WOBBLE_MS),
  pullStrengthMin = F("config.flatTire.pullStrengthMin", DEFAULT_FLAT_TIRE_PULL_STRENGTH_MIN),
  pullStrengthMax = F("config.flatTire.pullStrengthMax", DEFAULT_FLAT_TIRE_PULL_STRENGTH_MAX),
  wobbleStrengthMin = F("config.flatTire.wobbleStrengthMin", DEFAULT_FLAT_TIRE_WOBBLE_STRENGTH_MIN),
  wobbleStrengthMax = F("config.flatTire.wobbleStrengthMax", DEFAULT_FLAT_TIRE_WOBBLE_STRENGTH_MAX),
  forwardClampMin = F("config.flatTire.forwardClampMin", DEFAULT_FLAT_TIRE_FORWARD_CLAMP_MIN),
  forwardClampMax = F("config.flatTire.forwardClampMax", DEFAULT_FLAT_TIRE_FORWARD_CLAMP_MAX),
  tickIntervalMs = N("config.flatTire.tickIntervalMs", DEFAULT_FLAT_TIRE_TICK_INTERVAL_MS),
  messageMode = S("config.flatTire.messageMode", DEFAULT_FLAT_TIRE_MESSAGE_MODE),
  start      = T("config.flatTire.start", DEFAULT_FLAT_TIRE_START),
  tick       = T("config.flatTire.tick", DEFAULT_FLAT_TIRE_TICK),
  done       = T("config.flatTire.done", DEFAULT_FLAT_TIRE_DONE),
  noSupport  = T("config.flatTire.noSupport", DEFAULT_FLAT_TIRE_NOSUPPORT),
  pullLeft   = T("config.flatTire.pullLeft", DEFAULT_FLAT_TIRE_PULLLEFT),
  pullRight  = T("config.flatTire.pullRight", DEFAULT_FLAT_TIRE_PULLRIGHT),
}

FarmingLive.config.tireParty = {
  minMinutes = N("config.tireParty.minMinutes", DEFAULT_TIRE_PARTY_MIN_MINUTES),
  maxMinutes = N("config.tireParty.maxMinutes", DEFAULT_TIRE_PARTY_MAX_MINUTES),
  minSwitchMs = N("config.tireParty.minSwitchMs", DEFAULT_TIRE_PARTY_MIN_SWITCH_MS),
  maxSwitchMs = N("config.tireParty.maxSwitchMs", DEFAULT_TIRE_PARTY_MAX_SWITCH_MS),
  flatMessageMs = N("config.tireParty.flatMessageMs", DEFAULT_TIRE_PARTY_FLAT_MESSAGE_MS),
  fullMessageMs = N("config.tireParty.fullMessageMs", DEFAULT_TIRE_PARTY_FULL_MESSAGE_MS),
  messageMode = S("config.tireParty.messageMode", DEFAULT_TIRE_PARTY_MESSAGE_MODE),
  start      = T("config.tireParty.start", DEFAULT_TIRE_PARTY_START),
  flat       = T("config.tireParty.flat", DEFAULT_TIRE_PARTY_FLAT),
  full       = T("config.tireParty.full", DEFAULT_TIRE_PARTY_FULL),
  done       = T("config.tireParty.done", DEFAULT_TIRE_PARTY_DONE),
  noSupport  = T("config.tireParty.noSupport", DEFAULT_TIRE_PARTY_NOSUPPORT),
}

FarmingLive.config.tabTrap = {
  minLockMinutes   = N("config.tabTrap.minLockMinutes", DEFAULT_TAB_TRAP_MIN_LOCK_MINUTES),
  maxLockMinutes   = N("config.tabTrap.maxLockMinutes", DEFAULT_TAB_TRAP_MAX_LOCK_MINUTES),
  minSwitchCount   = N("config.tabTrap.minSwitchCount", DEFAULT_TAB_TRAP_MIN_SWITCH_COUNT),
  maxSwitchCount   = N("config.tabTrap.maxSwitchCount", DEFAULT_TAB_TRAP_MAX_SWITCH_COUNT),
  minSwitchDelayMs = N("config.tabTrap.minSwitchDelayMs", DEFAULT_TAB_TRAP_MIN_SWITCH_DELAY_MS),
  maxSwitchDelayMs = N("config.tabTrap.maxSwitchDelayMs", DEFAULT_TAB_TRAP_MAX_SWITCH_DELAY_MS),
  start            = T("config.tabTrap.start", DEFAULT_TAB_TRAP_START),
  switch           = T("config.tabTrap.switch", DEFAULT_TAB_TRAP_SWITCH),
  locked           = T("config.tabTrap.locked", DEFAULT_TAB_TRAP_LOCKED),
  tryExit          = T("config.tabTrap.tryExit", DEFAULT_TAB_TRAP_TRY_EXIT),
  trySwitch        = T("config.tabTrap.trySwitch", DEFAULT_TAB_TRAP_TRY_SWITCH),
  done             = T("config.tabTrap.done", DEFAULT_TAB_TRAP_DONE),
  tooFewVehicles   = T("config.tabTrap.tooFewVehicles", DEFAULT_TAB_TRAP_TOO_FEW),
}

FarmingLive.config.driveThat = {
  minLockMinutes = N("config.driveThat.minLockMinutes", DEFAULT_DRIVE_THAT_MIN_LOCK_MINUTES),
  maxLockMinutes = N("config.driveThat.maxLockMinutes", DEFAULT_DRIVE_THAT_MAX_LOCK_MINUTES),
  enterTimeoutMs = N("config.driveThat.enterTimeoutMs", DEFAULT_DRIVE_THAT_ENTER_TIMEOUT_MS),
  enterRetryMs   = N("config.driveThat.enterRetryMs", DEFAULT_DRIVE_THAT_ENTER_RETRY_MS),
  recoveryRetryMs = N("config.driveThat.recoveryRetryMs", DEFAULT_DRIVE_THAT_RECOVERY_RETRY_MS),
  messageMode    = S("config.driveThat.messageMode", DEFAULT_DRIVE_THAT_MESSAGE_MODE),
  start          = T("config.driveThat.start", DEFAULT_DRIVE_THAT_START),
  locked         = T("config.driveThat.locked", DEFAULT_DRIVE_THAT_LOCKED),
  tryExit        = T("config.driveThat.tryExit", DEFAULT_DRIVE_THAT_TRY_EXIT),
  trySwitch      = T("config.driveThat.trySwitch", DEFAULT_DRIVE_THAT_TRY_SWITCH),
  done           = T("config.driveThat.done", DEFAULT_DRIVE_THAT_DONE),
  failed         = T("config.driveThat.failed", DEFAULT_DRIVE_THAT_FAILED),
  tooFewVehicles = T("config.driveThat.tooFewVehicles", DEFAULT_DRIVE_THAT_TOO_FEW),
}

FarmingLive.config.mathGame = {
  minQuestions       = N("config.mathGame.minQuestions", DEFAULT_MATHGAME_MIN_QUESTIONS),
  maxQuestions       = N("config.mathGame.maxQuestions", DEFAULT_MATHGAME_MAX_QUESTIONS),
  minPenaltyMinutes  = N("config.mathGame.minPenaltyMinutes", DEFAULT_MATHGAME_MIN_PENALTY_MINUTES),
  maxPenaltyMinutes  = N("config.mathGame.maxPenaltyMinutes", DEFAULT_MATHGAME_MAX_PENALTY_MINUTES),
  questionTimeoutMs  = N("config.mathGame.questionTimeoutMs", DEFAULT_MATHGAME_QUESTION_TIMEOUT_MS),
  betweenQuestionMs  = N("config.mathGame.betweenQuestionMs", DEFAULT_MATHGAME_BETWEEN_QUESTION_MS),
  answerThreshold    = F("config.mathGame.answerThreshold", DEFAULT_MATHGAME_ANSWER_THRESHOLD),
  neutralThreshold   = F("config.mathGame.neutralThreshold", DEFAULT_MATHGAME_NEUTRAL_THRESHOLD),
  recenterMs         = N("config.mathGame.recenterMs", DEFAULT_MATHGAME_RECENTER_MS),
  startDelayMs       = N("config.mathGame.startDelayMs", DEFAULT_MATHGAME_START_DELAY_MS),
  messageMode        = S("config.mathGame.messageMode", DEFAULT_MATHGAME_MESSAGE_MODE),
  start              = T("config.mathGame.start", DEFAULT_MATHGAME_START),
  question           = T("config.mathGame.question", DEFAULT_MATHGAME_QUESTION),
  correct            = T("config.mathGame.correct", DEFAULT_MATHGAME_CORRECT),
  wrong              = T("config.mathGame.wrong", DEFAULT_MATHGAME_WRONG),
  timeout            = T("config.mathGame.timeout", DEFAULT_MATHGAME_TIMEOUT),
  resultNoPenalty    = T("config.mathGame.resultNoPenalty", DEFAULT_MATHGAME_RESULT_NOPENALTY),
  resultPenalty      = T("config.mathGame.resultPenalty", DEFAULT_MATHGAME_RESULT_PENALTY),
  penaltyStart       = T("config.mathGame.penaltyStart", DEFAULT_MATHGAME_PENALTY_START),
  penaltyTick        = T("config.mathGame.penaltyTick", DEFAULT_MATHGAME_PENALTY_TICK),
  penaltyDone        = T("config.mathGame.penaltyDone", DEFAULT_MATHGAME_PENALTY_DONE),
}

FarmingLive.config.idleChaos = {
  minSpeedKph = N("config.idleChaos.minSpeedKph", DEFAULT_IDLECHAOS_MIN_SPEED_KPH),
  minStandMs  = N("config.idleChaos.minStandMs",  DEFAULT_IDLECHAOS_STAND_MS),
  effectMinMs = N("config.idleChaos.effectMinMs", DEFAULT_IDLECHAOS_EFF_MIN_MS),
  effectMaxMs = N("config.idleChaos.effectMaxMs", DEFAULT_IDLECHAOS_EFF_MAX_MS),
  cooldownMs  = N("config.idleChaos.cooldownMs",  DEFAULT_IDLECHAOS_COOLDOWN_MS),
  start       = T("config.idleChaos.start",       DEFAULT_IDLECHAOS_START),
  tick        = T("config.idleChaos.tick",        DEFAULT_IDLECHAOS_TICK),
  effect      = T("config.idleChaos.effect",      DEFAULT_IDLECHAOS_EFFECT),
  done        = T("config.idleChaos.done",        DEFAULT_IDLECHAOS_END),
  messageMode = S("config.idleChaos.messageMode", DEFAULT_IDLECHAOS_MESSAGE_MODE),
}

    local __flLegacyChanged = false
    FarmingLive.config.showUser.messageMode, __flLegacyChanged = NormalizeLegacyMessageMode("config.showUser.messageMode", FarmingLive.config.showUser.messageMode)
    local __flChangedHi
    FarmingLive.config.showHi.messageMode, __flChangedHi = NormalizeLegacyMessageMode("config.showHi.messageMode", FarmingLive.config.showHi.messageMode)
    __flLegacyChanged = __flLegacyChanged or __flChangedHi
    local __flChangedSimu
    FarmingLive.config.showSimu.messageMode, __flChangedSimu = NormalizeLegacyMessageMode("config.showSimu.messageMode", FarmingLive.config.showSimu.messageMode)
    __flLegacyChanged = __flLegacyChanged or __flChangedSimu

    if __flLegacyChanged then
        saveXMLFile(configXML)
    end

    delete(configXML)
    print("[FarmingLive - HINT] Configuration loaded successfully from " .. FarmingLive.configFilePath)
end

function FarmingLive:addMissingConfigEntries(xmlFile)
    local changed = false

    local function setDefault(path, value)
        if hasXMLProperty(xmlFile, path) then
            return false
        end

        if type(value) == "number" then
            if math.floor(value) == value then
                setXMLInt(xmlFile, path, value)
            elseif setXMLFloat ~= nil then
                setXMLFloat(xmlFile, path, value)
            else
                setXMLString(xmlFile, path, tostring(value))
            end
        elseif type(value) == "boolean" then
            setXMLString(xmlFile, path, value and "true" or "false")
        else
            setXMLString(xmlFile, path, tostring(value or ""))
        end

        print("[FarmingLive - CHANGE] Added missing config entry: " .. path .. " with value: " .. tostring(value))
        return true
    end

    local entries = {
        {"config.tempMass.weight", DEFAULT_MASS},
        {"config.tempMass.message", DEFAULT_TEMPORARY_MASS_MESSAGE},

        {"config.fadeScreen.duration", DEFAULT_FADE_SCREEN_DURATION},
        {"config.fadeScreen.warningMessage", DEFAULT_FADE_SCREEN_WARNING_MESSAGE},

        {"config.showUser.warningMessage", DEFAULT_SHOW_USER_WARNING_MESSAGE},
        {"config.showUser.warningMessage2", DEFAULT_SHOW_USER_WARNING_MESSAGE2},
        {"config.showUser.warningMessage3", DEFAULT_SHOW_USER_WARNING_MESSAGE3},
        {"config.showUser.warningMessage4", DEFAULT_SHOW_USER_WARNING_MESSAGE4},
        {"config.showUser.warningMessage5", DEFAULT_SHOW_USER_WARNING_MESSAGE5},
        {"config.showUser.duration", DEFAULT_SHOW_USER_DURATION},
        {"config.showUser.messageMode", DEFAULT_SHOW_USER_MESSAGE_MODE},

        {"config.showHi.warningMessage", DEFAULT_SHOW_HI_WARNING_MESSAGE},
        {"config.showHi.duration", DEFAULT_SHOW_HI_DURATION},
        {"config.showHi.messageMode", DEFAULT_SHOW_HI_MESSAGE_MODE},

        {"config.showSimu.duration", DEFAULT_SHOW_SIMU_DURATION},
        {"config.showSimu.messageMode", DEFAULT_SHOW_SIMU_MESSAGE_MODE},

        {"config.messageApi.mode", DEFAULT_MESSAGE_API_MODE},
        {"config.messageApi.background", DEFAULT_MESSAGE_API_BACKGROUND},
        {"config.messageApi.toastX", DEFAULT_MESSAGE_API_TOAST_X},
        {"config.messageApi.toastY", DEFAULT_MESSAGE_API_TOAST_Y},
        {"config.messageApi.toastScale", DEFAULT_MESSAGE_API_TOAST_SCALE},
        {"config.messageApi.toastAlign", DEFAULT_MESSAGE_API_TOAST_ALIGN},
        {"config.messageApi.centerX", DEFAULT_MESSAGE_API_CENTER_X},
        {"config.messageApi.centerY", DEFAULT_MESSAGE_API_CENTER_Y},
        {"config.messageApi.centerScale", DEFAULT_MESSAGE_API_CENTER_SCALE},
        {"config.messageApi.centerAlign", DEFAULT_MESSAGE_API_CENTER_ALIGN},
        {"config.messageApi.paddingX", DEFAULT_MESSAGE_API_PADDING_X},
        {"config.messageApi.paddingY", DEFAULT_MESSAGE_API_PADDING_Y},
        {"config.messageApi.bgR", DEFAULT_MESSAGE_API_BG_R},
        {"config.messageApi.bgG", DEFAULT_MESSAGE_API_BG_G},
        {"config.messageApi.bgB", DEFAULT_MESSAGE_API_BG_B},
        {"config.messageApi.bgA", DEFAULT_MESSAGE_API_BG_A},
        {"config.messageApi.textR", DEFAULT_MESSAGE_API_TEXT_R},
        {"config.messageApi.textG", DEFAULT_MESSAGE_API_TEXT_G},
        {"config.messageApi.textB", DEFAULT_MESSAGE_API_TEXT_B},
        {"config.messageApi.textA", DEFAULT_MESSAGE_API_TEXT_A},
        {"config.messageApi.consolePrefix", DEFAULT_MESSAGE_API_CONSOLE_PREFIX},

        {"config.clearFuel.message", DEFAULT_CLEAR_FUEL_MESSAGE},

        {"config.setBroken.message", DEFAULT_SET_BROKEN_MESSAGE},
        {"config.setBroken.failmessage", DEFAULT_WARNING_MOTOR_FAIL_MESSAGE},

        {"config.setTime.message", DEFAULT_SETTIME_MESSAGE},

        {"config.adjustMoney.positiveMessage", DEFAULT_ADJUST_MONEY_POSITIVE_MESSAGE},
        {"config.adjustMoney.negativeMessage", DEFAULT_ADJUST_MONEY_NEGATIVE_MESSAGE},
        {"config.adjustMoney.MIN_VALUE", DEFAULT_MIN_VALUE},
        {"config.adjustMoney.MAX_VALUE", DEFAULT_MAX_VALUE},

        {"config.setDirt.message", DEFAULT_SET_DIRT_MESSAGE},
        {"config.setDirt.cleanmessage", DEFAULT_SET_DIRT_CLEANMESSAGE},

        {"config.setSpeed.maxspeed", DEFAULT_MaxSpeed},
        {"config.setSpeed.minspeed", DEFAULT_MinSpeed},
        {"config.setSpeed.maxtime", DEFAULT_MaxTime},
        {"config.setSpeed.mintime", DEFAULT_MinTime},
        {"config.setSpeed.warningSpeedLimit", DEFAULT_WARNING_SPEED_LIMIT_MESSAGE},
        {"config.setSpeed.warningMotorPause", DEFAULT_WARNING_MOTOR_PAUSE_MESSAGE},
        {"config.setSpeed.warningMotorOverspeed", DEFAULT_WARNING_MOTOR_OVERSPEED_MESSAGE},
        {"config.setSpeed.warningMotorBlocked", DEFAULT_WARNING_MOTOR_BLOCKED_MESSAGE},

        {"config.blockEngine.warningMotorStopped", DEFAULT_WARNING_MOTOR_STOPPED_MESSAGE},
        {"config.blockEngine.warningMotorActive", DEFAULT_WARNING_MOTOR_ACTIVE_MESSAGE},
        {"config.blockEngine.warningMotorIgnored", DEFAULT_WARNING_MOTOR_IGNORED_MESSAGE},

        {"config.blockTab.maxtime", DEFAULT_BlockMaxTime},
        {"config.blockTab.mintime", DEFAULT_BlockMinTime},
        {"config.blockTab.blockmessage", DEFAULT_BlockTabMessage},
        {"config.blockTab.unblockmessage", DEFAULT_BlockTabUnblockMessage},
        {"config.blockTab.trytab", DEFAULT_TryTabMessage},

        {"config.drivingEnforce.maxtime", DEFAULT_DriveDirMaxTime},
        {"config.drivingEnforce.mintime", DEFAULT_DriveDirMinTime},
        {"config.drivingEnforce.DriveDirWarnmessage", DEFAULT_DriveDirWarnmessage},
        {"config.drivingEnforce.DriveDirResetmessage", DEFAULT_DriveDirResetmessage},
        {"config.drivingEnforce.BlockWarn", DEFAULT_DriveDirBlockWarn},
        {"config.drivingEnforce.DriveDirForward", DEFAULT_DriveDirForward},
        {"config.drivingEnforce.DriveDirBackward", DEFAULT_DriveDirBackward},

        {"config.cameraFun.WarnMessage", DEFAULT_cameraFun_WarnMessage},
        {"config.cameraFun.cameraBlocked", DEFAULT_cameraFun_cameraBlocked},
        {"config.cameraFun.cameraUnblocked", DEFAULT_cameraFun_cameraUnblocked},
        {"config.cameraFun.ZoomMin", DEFAULT_cameraFun_ZoomMin},
        {"config.cameraFun.ZoomMax", DEFAULT_cameraFun_ZoomMax},
        {"config.cameraFun.UseZoom", DEFAULT_cameraFun_UseZoom},
        {"config.cameraFun.TimeMax", DEFAULT_cameraFun_TimeMax},
        {"config.cameraFun.TimeMin", DEFAULT_cameraFun_TimeMin},

        {"config.forbiddenSteeringDir.minMinutes", 1},
        {"config.forbiddenSteeringDir.maxMinutes", 5},
        {"config.forbiddenSteeringDir.left", DEFAULT_forbiddenSteeringDirLeft},
        {"config.forbiddenSteeringDir.right", DEFAULT_forbiddenSteeringDirRight},
        {"config.forbiddenSteeringDir.BlockWarn", DEFAULT_forbiddenSteeringDirBlockWarn},
        {"config.forbiddenSteeringDir.BlockWarnTry", DEFAULT_forbiddenSteeringDirBlockWarnTry},
        {"config.forbiddenSteeringDir.BlockWarnReset", DEFAULT_forbiddenSteeringDirBlockWarnReset},

        {"config.invertControls.minMinutes", 1},
        {"config.invertControls.maxMinutes", 5},
        {"config.invertControls.WarnMessage", DEFAULT_invertControlsWarnMessage},
        {"config.invertControls.UnblockMessage", DEFAULT_invertControlsUnblockMessage},
        {"config.invertControls.BlockMessage", DEFAULT_invertControlsBlockMessage},

        {"config.adjustDiesel.getFuel", DEFAULT_Adjust_FUEL_GETMESSAGE},
        {"config.adjustDiesel.remFuel", DEFAULT_Adjust_FUEL_REMMESSAGE},

        {"config.BlockAndLock.KEYOUT", DEFAULT_BlockAndLock_KEYOUT},
        {"config.BlockAndLock.KEYFOUND", DEFAULT_BlockAndLock_KEYFOUND},

        {"config.triggerHonk.warnmessage", DEFAULT_triggerHonk_warnmessage},

        {"config.randomSteer.BlockStart", DEFAULT_RANDOMSTEER_BLOCKSTART},
        {"config.randomSteer.SegmentStart", DEFAULT_RANDOMSTEER_SEGMENTSTART},
        {"config.randomSteer.BlockEnd", DEFAULT_RANDOMSTEER_BLOCKEND},
        {"config.randomSteer.DirLeft", DEFAULT_RANDOMSTEER_DIRLEFT},
        {"config.randomSteer.DirRight", DEFAULT_RANDOMSTEER_DIRRIGHT},

        {"config.launchVehicle.LaunchVehicleUpImp", DEFAULT_LAUNCHVEHUPIMP},
        {"config.launchVehicle.LaunchVehicleFwdImp", DEFAULT_LAUNCHVEHFWDIMP},
        {"config.launchVehicle.LaunchVehicleWarnMessage", DEFAULT_LAUNCHVEHWARNMESSAGE},

        {"config.lockInteriorCamera.IntoriorCamWarnMessage", DEFAULT_INTERIORCAMWARNMESSAGE},
        {"config.lockInteriorCamera.IntoriorCamBlockMessage", DEFAULT_INTERIORCAMBLOCKMESSAGE},
        {"config.lockInteriorCamera.IntoriorCamMinTime", DEFAULT_INTERIORCAMMINTIME},
        {"config.lockInteriorCamera.IntoriorCamMaxTime", DEFAULT_INTERIORCAMMAXTIME},
        {"config.lockInteriorCamera.IntoriorCamUnblockMessage", DEFAULT_INTERIORCAMUNBLOCKMESSAGE},

        {"config.toggleWipers.TOGWipersWarnmessage", DEFAULT_TOGWIPERMESSAGE},
        {"config.toggleWipers.TOGWipersDeaktivatemessage", DEFAULT_TOGWIPERDEAKTIVATEMESSAGE},
        {"config.toggleWipers.TOGWipersMinTime", DEFAULT_TOGWIPERMINTIME},
        {"config.toggleWipers.TOGWipersMaxTime", DEFAULT_TOGWIPERMAXTIME},

        {"config.walking.start", DEFAULT_WALKING_START},
        {"config.walking.enterBlocked", DEFAULT_WALKING_ENTERBLOCKED},
        {"config.walking.done", DEFAULT_WALKING_DONE},
        {"config.walking.warn1", DEFAULT_WALKING_WARN1},
        {"config.walking.warn2", DEFAULT_WALKING_WARN2},
        {"config.walking.warn3", DEFAULT_WALKING_WARN3},
        {"config.walking.warn4", DEFAULT_WALKING_WARN4},
        {"config.walking.warn5", DEFAULT_WALKING_WARN5},

        {"config.idleChaos.minSpeedKph", DEFAULT_IDLECHAOS_MIN_SPEED_KPH},
        {"config.idleChaos.minStandMs", DEFAULT_IDLECHAOS_STAND_MS},
        {"config.idleChaos.effectMinMs", DEFAULT_IDLECHAOS_EFF_MIN_MS},
        {"config.idleChaos.effectMaxMs", DEFAULT_IDLECHAOS_EFF_MAX_MS},
        {"config.idleChaos.cooldownMs", DEFAULT_IDLECHAOS_COOLDOWN_MS},
        {"config.idleChaos.start", DEFAULT_IDLECHAOS_START},
        {"config.idleChaos.tick", DEFAULT_IDLECHAOS_TICK},
        {"config.idleChaos.effect", DEFAULT_IDLECHAOS_EFFECT},
        {"config.idleChaos.done", DEFAULT_IDLECHAOS_END},
        {"config.idleChaos.messageMode", DEFAULT_IDLECHAOS_MESSAGE_MODE},

        {"config.flatTire.minMinutes", DEFAULT_FLAT_TIRE_MIN_MINUTES},
        {"config.flatTire.maxMinutes", DEFAULT_FLAT_TIRE_MAX_MINUTES},
        {"config.flatTire.brakePulseMs", DEFAULT_FLAT_TIRE_BRAKE_PULSE_MS},
        {"config.flatTire.wobbleMs", DEFAULT_FLAT_TIRE_WOBBLE_MS},
        {"config.flatTire.pullStrengthMin", DEFAULT_FLAT_TIRE_PULL_STRENGTH_MIN},
        {"config.flatTire.pullStrengthMax", DEFAULT_FLAT_TIRE_PULL_STRENGTH_MAX},
        {"config.flatTire.wobbleStrengthMin", DEFAULT_FLAT_TIRE_WOBBLE_STRENGTH_MIN},
        {"config.flatTire.wobbleStrengthMax", DEFAULT_FLAT_TIRE_WOBBLE_STRENGTH_MAX},
        {"config.flatTire.forwardClampMin", DEFAULT_FLAT_TIRE_FORWARD_CLAMP_MIN},
        {"config.flatTire.forwardClampMax", DEFAULT_FLAT_TIRE_FORWARD_CLAMP_MAX},
        {"config.flatTire.tickIntervalMs", DEFAULT_FLAT_TIRE_TICK_INTERVAL_MS},
        {"config.flatTire.messageMode", DEFAULT_FLAT_TIRE_MESSAGE_MODE},
        {"config.flatTire.start", DEFAULT_FLAT_TIRE_START},
        {"config.flatTire.tick", DEFAULT_FLAT_TIRE_TICK},
        {"config.flatTire.done", DEFAULT_FLAT_TIRE_DONE},
        {"config.flatTire.noSupport", DEFAULT_FLAT_TIRE_NOSUPPORT},
        {"config.flatTire.pullLeft", DEFAULT_FLAT_TIRE_PULLLEFT},
        {"config.flatTire.pullRight", DEFAULT_FLAT_TIRE_PULLRIGHT},

        {"config.tireParty.minMinutes", DEFAULT_TIRE_PARTY_MIN_MINUTES},
        {"config.tireParty.maxMinutes", DEFAULT_TIRE_PARTY_MAX_MINUTES},
        {"config.tireParty.minSwitchMs", DEFAULT_TIRE_PARTY_MIN_SWITCH_MS},
        {"config.tireParty.maxSwitchMs", DEFAULT_TIRE_PARTY_MAX_SWITCH_MS},
        {"config.tireParty.flatMessageMs", DEFAULT_TIRE_PARTY_FLAT_MESSAGE_MS},
        {"config.tireParty.fullMessageMs", DEFAULT_TIRE_PARTY_FULL_MESSAGE_MS},
        {"config.tireParty.messageMode", DEFAULT_TIRE_PARTY_MESSAGE_MODE},
        {"config.tireParty.start", DEFAULT_TIRE_PARTY_START},
        {"config.tireParty.flat", DEFAULT_TIRE_PARTY_FLAT},
        {"config.tireParty.full", DEFAULT_TIRE_PARTY_FULL},
        {"config.tireParty.done", DEFAULT_TIRE_PARTY_DONE},
        {"config.tireParty.noSupport", DEFAULT_TIRE_PARTY_NOSUPPORT},

        {"config.tabTrap.minLockMinutes", DEFAULT_TAB_TRAP_MIN_LOCK_MINUTES},
        {"config.tabTrap.maxLockMinutes", DEFAULT_TAB_TRAP_MAX_LOCK_MINUTES},
        {"config.tabTrap.minSwitchCount", DEFAULT_TAB_TRAP_MIN_SWITCH_COUNT},
        {"config.tabTrap.maxSwitchCount", DEFAULT_TAB_TRAP_MAX_SWITCH_COUNT},
        {"config.tabTrap.minSwitchDelayMs", DEFAULT_TAB_TRAP_MIN_SWITCH_DELAY_MS},
        {"config.tabTrap.maxSwitchDelayMs", DEFAULT_TAB_TRAP_MAX_SWITCH_DELAY_MS},
        {"config.tabTrap.start", DEFAULT_TAB_TRAP_START},
        {"config.tabTrap.switch", DEFAULT_TAB_TRAP_SWITCH},
        {"config.tabTrap.locked", DEFAULT_TAB_TRAP_LOCKED},
        {"config.tabTrap.tryExit", DEFAULT_TAB_TRAP_TRY_EXIT},
        {"config.tabTrap.trySwitch", DEFAULT_TAB_TRAP_TRY_SWITCH},
        {"config.tabTrap.done", DEFAULT_TAB_TRAP_DONE},
        {"config.tabTrap.tooFewVehicles", DEFAULT_TAB_TRAP_TOO_FEW},

        {"config.driveThat.minLockMinutes", DEFAULT_DRIVE_THAT_MIN_LOCK_MINUTES},
        {"config.driveThat.maxLockMinutes", DEFAULT_DRIVE_THAT_MAX_LOCK_MINUTES},
        {"config.driveThat.enterTimeoutMs", DEFAULT_DRIVE_THAT_ENTER_TIMEOUT_MS},
        {"config.driveThat.enterRetryMs", DEFAULT_DRIVE_THAT_ENTER_RETRY_MS},
        {"config.driveThat.recoveryRetryMs", DEFAULT_DRIVE_THAT_RECOVERY_RETRY_MS},
        {"config.driveThat.messageMode", DEFAULT_DRIVE_THAT_MESSAGE_MODE},
        {"config.driveThat.start", DEFAULT_DRIVE_THAT_START},
        {"config.driveThat.locked", DEFAULT_DRIVE_THAT_LOCKED},
        {"config.driveThat.tryExit", DEFAULT_DRIVE_THAT_TRY_EXIT},
        {"config.driveThat.trySwitch", DEFAULT_DRIVE_THAT_TRY_SWITCH},
        {"config.driveThat.done", DEFAULT_DRIVE_THAT_DONE},
        {"config.driveThat.failed", DEFAULT_DRIVE_THAT_FAILED},
        {"config.driveThat.tooFewVehicles", DEFAULT_DRIVE_THAT_TOO_FEW},

        {"config.mathGame.minQuestions", DEFAULT_MATHGAME_MIN_QUESTIONS},
        {"config.mathGame.maxQuestions", DEFAULT_MATHGAME_MAX_QUESTIONS},
        {"config.mathGame.minPenaltyMinutes", DEFAULT_MATHGAME_MIN_PENALTY_MINUTES},
        {"config.mathGame.maxPenaltyMinutes", DEFAULT_MATHGAME_MAX_PENALTY_MINUTES},
        {"config.mathGame.questionTimeoutMs", DEFAULT_MATHGAME_QUESTION_TIMEOUT_MS},
        {"config.mathGame.betweenQuestionMs", DEFAULT_MATHGAME_BETWEEN_QUESTION_MS},
        {"config.mathGame.answerThreshold", DEFAULT_MATHGAME_ANSWER_THRESHOLD},
        {"config.mathGame.neutralThreshold", DEFAULT_MATHGAME_NEUTRAL_THRESHOLD},
        {"config.mathGame.recenterMs", DEFAULT_MATHGAME_RECENTER_MS},
        {"config.mathGame.startDelayMs", DEFAULT_MATHGAME_START_DELAY_MS},
        {"config.mathGame.messageMode", DEFAULT_MATHGAME_MESSAGE_MODE},
        {"config.mathGame.start", DEFAULT_MATHGAME_START},
        {"config.mathGame.question", DEFAULT_MATHGAME_QUESTION},
        {"config.mathGame.correct", DEFAULT_MATHGAME_CORRECT},
        {"config.mathGame.wrong", DEFAULT_MATHGAME_WRONG},
        {"config.mathGame.timeout", DEFAULT_MATHGAME_TIMEOUT},
        {"config.mathGame.resultNoPenalty", DEFAULT_MATHGAME_RESULT_NOPENALTY},
        {"config.mathGame.resultPenalty", DEFAULT_MATHGAME_RESULT_PENALTY},
        {"config.mathGame.penaltyStart", DEFAULT_MATHGAME_PENALTY_START},
        {"config.mathGame.penaltyTick", DEFAULT_MATHGAME_PENALTY_TICK},
        {"config.mathGame.penaltyDone", DEFAULT_MATHGAME_PENALTY_DONE}
    }

    for _, entry in ipairs(entries) do
        if setDefault(entry[1], entry[2]) then
            changed = true
        end
    end

    if changed then
        saveXMLFile(xmlFile)
    end
end

-- function FarmingLive:fadeScreenForDuration(durationSeconds, playerName)
-- print("[FarmingLive] fadeScreenForDuration wurde gestartet für: " .. tostring(playerName))   
 -- local delayMS = math.random(10, 7000)

    -- if playerName then
        -- local warnText = FarmingLive:formatMessage(
            -- FarmingLive.config.fadeScreen.warningMessage,
            -- playerName,
            -- math.ceil(delayMS / 1000),
            -- nil
        -- )
		-- FarmingLive:showThrottledWarning("FadeScreen", warnText, 5000, 5000)
       -- -- FarmingLive:showWarning(warnText, 5000)
    -- end

    -- local fadeOutStartTime = g_time + delayMS

    -- local fadeOutUpdater = {}
    -- fadeOutUpdater.update = function(self, dt)
        -- if g_time >= fadeOutStartTime then

            -- g_currentMission:fadeScreen(1, 1000)
            -- g_currentMission:removeUpdateable(self)

            -- local fadeInTime = g_time + 1000 + (durationSeconds * 1000)

            -- local fadeInUpdater = {}
            -- fadeInUpdater.update = function(self2, dt2)
                -- if g_time >= fadeInTime then
                    -- g_currentMission:fadeScreen(-1, 1000)
                    -- g_currentMission:removeUpdateable(self2)
					-- FarmingLive:endActiveEvent()
                -- end
            -- end

            -- g_currentMission:addUpdateable(fadeInUpdater)
        -- end
    -- end

    -- g_currentMission:addUpdateable(fadeOutUpdater)
-- end

local function flCfgTrim(value)
    return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function flCfgTextToBool(value, defaultValue)
    if value == nil then
        return defaultValue == true
    end

    local t = type(value)
    if t == "boolean" then
        return value
    end
    if t == "number" then
        return value ~= 0
    end

    local s = tostring(value):lower()
    if s == "true" or s == "1" or s == "yes" or s == "on" then
        return true
    end
    if s == "false" or s == "0" or s == "no" or s == "off" then
        return false
    end

    return defaultValue == true
end

local function flCfgNormalizePath(path)
    local p = flCfgTrim(path)
    if p == "" then
        return nil
    end

    p = p:gsub("/", ".")
    p = p:gsub("%.+", ".")
    p = p:gsub("^%.", "")
    p = p:gsub("%.$", "")

    if p:sub(1, 7):lower() ~= "config." and p:lower() ~= "config" then
        p = "config." .. p
    end

    return p
end

local function flCfgSplitPath(path)
    local parts = {}
    for token in tostring(path or ""):gmatch("[^%.]+") do
        parts[#parts + 1] = token
    end
    return parts
end

local function flCfgGetRuntimeRef(self, xmlPath)
    local parts = flCfgSplitPath(xmlPath)
    if #parts < 2 or parts[1] ~= "config" then
        return nil, nil, nil
    end

    local node = self.config
    for i = 2, #parts - 1 do
        if type(node) ~= "table" then
            return nil, nil, nil
        end
        node = node[parts[i]]
        if node == nil then
            return nil, nil, nil
        end
    end

    local key = parts[#parts]
    local current = nil
    if type(node) == "table" then
        current = node[key]
    end
    return node, key, current
end

local function flCfgStringifyValue(value)
    if type(value) == "table" then
        local parts = {}
        local count = 0
        for k, v in pairs(value) do
            count = count + 1
            if count > 6 then
                parts[#parts + 1] = "..."
                break
            end
            parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    return tostring(value)
end

local function flCfgApplyRuntimeValue(self, xmlPath, rawValue)
    local parent, key, current = flCfgGetRuntimeRef(self, xmlPath)
    if type(parent) ~= "table" or key == nil then
        return false, "Pfad nicht in Runtime-Config gefunden: " .. tostring(xmlPath)
    end

    local valueType = type(current)
    local finalValue = rawValue

    if valueType == "number" then
        local num = tonumber(rawValue)
        if num == nil then
            return false, "Wert ist keine Zahl: " .. tostring(rawValue)
        end
        finalValue = num
    elseif valueType == "boolean" then
        finalValue = flCfgTextToBool(rawValue, current == true)
    else
        finalValue = tostring(rawValue or "")
        if finalValue:sub(1, 1) == "@" and self.resolveTemplate ~= nil then
            finalValue = self:resolveTemplate(finalValue, finalValue)
        end
    end

    parent[key] = finalValue
    return true, finalValue
end

local function flCfgWriteXmlValue(self, xmlPath, rawValue)
    if self.configFilePath == nil or self.configFilePath == "" then
        return false, "Config-Datei ist noch nicht initialisiert."
    end

    local xmlFile = loadXMLFile("FarmingLiveConfigRuntime", self.configFilePath)
    if not xmlFile then
        return false, "Config-XML konnte nicht geladen werden."
    end

    local _, _, current = flCfgGetRuntimeRef(self, xmlPath)
    local currentType = type(current)

    if currentType == "number" then
        local num = tonumber(rawValue)
        if num == nil then
            delete(xmlFile)
            return false, "Wert ist keine Zahl: " .. tostring(rawValue)
        end
        if math.floor(num) == num then
            setXMLInt(xmlFile, xmlPath, num)
        elseif setXMLFloat ~= nil then
            setXMLFloat(xmlFile, xmlPath, num)
        else
            setXMLString(xmlFile, xmlPath, tostring(num))
        end
    elseif currentType == "boolean" then
        setXMLString(xmlFile, xmlPath, flCfgTextToBool(rawValue, current == true) and "true" or "false")
    else
        setXMLString(xmlFile, xmlPath, tostring(rawValue or ""))
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)
    return true
end

local function flCfgReadRawXmlValue(self, xmlPath)
    if self.configFilePath == nil or self.configFilePath == "" then
        return nil
    end

    local xmlFile = loadXMLFile("FarmingLiveConfigRuntime", self.configFilePath)
    if not xmlFile then
        return nil
    end

    local value = getXMLString(xmlFile, xmlPath)
    delete(xmlFile)
    return value
end

local function flCfgCollectPaths(node, prefix, result)
    if type(node) ~= "table" then
        result[#result + 1] = prefix
        return
    end

    local keys = {}
    for k, _ in pairs(node) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    for _, key in ipairs(keys) do
        local childPrefix = prefix == "" and tostring(key) or (prefix .. "." .. tostring(key))
        if type(node[key]) == "table" then
            flCfgCollectPaths(node[key], childPrefix, result)
        else
            result[#result + 1] = childPrefix
        end
    end
end

local function flCfgReloadNodeFromXml(self, node, prefix)
    if type(node) ~= "table" then
        return
    end

    for key, value in pairs(node) do
        local childPath = prefix .. "." .. tostring(key)
        if type(value) == "table" then
            flCfgReloadNodeFromXml(self, value, childPath)
        else
            local raw = flCfgReadRawXmlValue(self, childPath)
            if raw ~= nil then
                flCfgApplyRuntimeValue(self, childPath, raw)
            end
        end
    end
end

function FarmingLive:reloadRuntimeConfigFromXml()
    if type(self.config) ~= "table" then
        return false, "Runtime-Config fehlt."
    end

    flCfgReloadNodeFromXml(self, self.config, "config")
    return true
end

function FarmingLive:registerConfigConsoleCommands()
    if self._flConfigConsoleCommandsRegistered then
        return
    end

    addConsoleCommand("flCfgGet", "Liest einen Config-Wert: flCfgGet <pfad>", "consoleCommandCfgGet", self)
    addConsoleCommand("flCfgSet", "Setzt einen Config-Wert: flCfgSet <pfad> <wert>", "consoleCommandCfgSet", self)
    addConsoleCommand("flCfgList", "Listet Config-Werte: flCfgList [section]", "consoleCommandCfgList", self)
    addConsoleCommand("flCfgSearch", "Sucht Config-Pfade: flCfgSearch <text>", "consoleCommandCfgSearch", self)
    addConsoleCommand("flCfgReload", "Lädt Runtime-Config neu aus der XML", "consoleCommandCfgReload", self)
    addConsoleCommand("flCfgFile", "Zeigt die Config-Datei", "consoleCommandCfgFile", self)
    addConsoleCommand("flCfgHelp", "Zeigt Hilfe für Config-Commands", "consoleCommandCfgHelp", self)

    self._flConfigConsoleCommandsRegistered = true
end

function FarmingLive:unregisterConfigConsoleCommands()
    if not self._flConfigConsoleCommandsRegistered then
        return
    end

    removeConsoleCommand("flCfgGet")
    removeConsoleCommand("flCfgSet")
    removeConsoleCommand("flCfgList")
    removeConsoleCommand("flCfgSearch")
    removeConsoleCommand("flCfgReload")
    removeConsoleCommand("flCfgFile")
    removeConsoleCommand("flCfgHelp")

    self._flConfigConsoleCommandsRegistered = false
end

function FarmingLive:consoleCommandCfgHelp()
    print("[FarmingLive] flCfgGet <pfad>")
    print("[FarmingLive] flCfgSet <pfad> <wert>")
    print("[FarmingLive] flCfgList [section]")
    print("[FarmingLive] flCfgSearch <text>")
    print("[FarmingLive] flCfgReload")
    print("[FarmingLive] flCfgFile")
    print("[FarmingLive] Beispiele: flCfgSet setSpeed.maxspeed 22 | flCfgSet showHi.warningMessage Hallo zusammen")
    return "FarmingLive Config-Hilfe ausgegeben."
end

function FarmingLive:consoleCommandCfgFile()
    return tostring(self.configFilePath or "")
end

function FarmingLive:consoleCommandCfgGet(path)
    local xmlPath = flCfgNormalizePath(path)
    if xmlPath == nil then
        return "Benutzung: flCfgGet <pfad>"
    end

    local _, _, runtimeValue = flCfgGetRuntimeRef(self, xmlPath)
    if runtimeValue == nil then
        return "Pfad nicht gefunden: " .. tostring(xmlPath)
    end

    local rawXml = flCfgReadRawXmlValue(self, xmlPath)
    return string.format("%s | raw=%s | runtime=%s", xmlPath, tostring(rawXml), flCfgStringifyValue(runtimeValue))
end

function FarmingLive:consoleCommandCfgSet(path, ...)
    local xmlPath = flCfgNormalizePath(path)
    if xmlPath == nil then
        return "Benutzung: flCfgSet <pfad> <wert>"
    end

    local rawValue = flCfgTrim(table.concat({ ... }, " "))
    if rawValue == "" then
        return "Benutzung: flCfgSet <pfad> <wert>"
    end

    local okRuntime, runtimeResult = flCfgApplyRuntimeValue(self, xmlPath, rawValue)
    if not okRuntime then
        return runtimeResult
    end

    local okXml, errXml = flCfgWriteXmlValue(self, xmlPath, rawValue)
    if not okXml then
        return errXml
    end

    if self.showWarning ~= nil then
        self:showWarning("Config gespeichert: " .. xmlPath, 2200, "mini")
    end

    return string.format("%s = %s", xmlPath, flCfgStringifyValue(runtimeResult))
end

function FarmingLive:consoleCommandCfgList(section)
    local filterPath = flCfgNormalizePath(section or "config") or "config"
    local parts = flCfgSplitPath(filterPath)
    local node = self
    if parts[1] ~= "config" then
        return "Ungültiger Bereich."
    end

    node = self.config
    for i = 2, #parts do
        if type(node) ~= "table" then
            return "Bereich nicht gefunden: " .. tostring(filterPath)
        end
        node = node[parts[i]]
        if node == nil then
            return "Bereich nicht gefunden: " .. tostring(filterPath)
        end
    end

    if type(node) ~= "table" then
        return string.format("%s = %s", filterPath, flCfgStringifyValue(node))
    end

    local collected = {}
    flCfgCollectPaths(node, filterPath == "config" and "config" or filterPath, collected)

    table.sort(collected)
    print("[FarmingLive] Config-Liste für " .. tostring(filterPath))
    for _, pathEntry in ipairs(collected) do
        local _, _, runtimeValue = flCfgGetRuntimeRef(self, pathEntry)
        print(string.format("  %s = %s", pathEntry, flCfgStringifyValue(runtimeValue)))
    end

    return string.format("%d Einträge gelistet für %s", #collected, tostring(filterPath))
end

function FarmingLive:consoleCommandCfgSearch(...)
    local query = flCfgTrim(table.concat({ ... }, " ")):lower()
    if query == "" then
        return "Benutzung: flCfgSearch <text>"
    end

    local collected = {}
    flCfgCollectPaths(self.config or {}, "config", collected)
    table.sort(collected)

    local hits = 0
    print("[FarmingLive] Config-Suche nach: " .. query)
    for _, pathEntry in ipairs(collected) do
        if pathEntry:lower():find(query, 1, true) ~= nil then
            local _, _, runtimeValue = flCfgGetRuntimeRef(self, pathEntry)
            print(string.format("  %s = %s", pathEntry, flCfgStringifyValue(runtimeValue)))
            hits = hits + 1
        end
    end

    return string.format("%d Treffer für '%s'", hits, query)
end

function FarmingLive:consoleCommandCfgReload()
    local ok, err = self:reloadRuntimeConfigFromXml()
    if not ok then
        return tostring(err)
    end

    if self.showWarning ~= nil then
        self:showWarning("Config aus XML neu geladen", 2200, "mini")
    end

    return "FarmingLive Config neu geladen."
end
