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

local function flKeepEnhancedVehicleSnapDisabled(vehicle, state)
  if vehicle == nil or state == nil then
    return
  end

  local vData = flGetEnhancedVehicleState(vehicle)
  if vData == nil then
    return
  end

  vData.is[5] = false
  vData.want[5] = false
  vData.is[6] = false
  vData.want[6] = false
  vData.axisSidePrev = 0
end

local function flResolveMode(mode)
  local normalized = tostring(mode or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if normalized == "" or normalized == "default" or normalized == "global" or normalized == "inherit" then
    return nil
  end
  return mode
end

local function flFindTireClusterByIndex(self, vehicle, clusterIndex)
  if clusterIndex == nil then
    return nil
  end

  local allClusters = self:getAllTireEffectClusters(vehicle)
  for _, entry in ipairs(allClusters or {}) do
    if tonumber(entry.index) == tonumber(clusterIndex) then
      return entry.cluster
    end
  end

  return nil
end

local function flShouldApplyTirePhysics(vehicle)
  if g_currentMission ~= nil and g_currentMission:getIsServer() then
    return true
  end

  if g_localPlayer ~= nil and g_localPlayer.getCurrentVehicle ~= nil then
    local localVehicle = g_localPlayer:getCurrentVehicle()
    if localVehicle ~= nil and localVehicle == vehicle then
      return true
    end
  end

  return false
end

local function flBuildFlatTireSyncOptions(self, cfg, rootVehicle, durationMinutes, messageMode)
  local minutes = math.max(1, tonumber(durationMinutes) or 1)
  local driftDirection = (math.random() > 0.5) and 1 or -1
  local clusterIndex, cluster = self:getTireEffectCluster(rootVehicle, driftDirection)

  if clusterIndex == nil or cluster == nil then
    return nil
  end

  driftDirection = (cluster.side ~= 0) and cluster.side or driftDirection

  local pullMin = tonumber(cfg.pullStrengthMin) or 0.20
  local pullMax = tonumber(cfg.pullStrengthMax) or 0.30
  if pullMax < pullMin then pullMin, pullMax = pullMax, pullMin end

  local wobbleStrengthMin = tonumber(cfg.wobbleStrengthMin) or 0.05
  local wobbleStrengthMax = tonumber(cfg.wobbleStrengthMax) or 0.10
  if wobbleStrengthMax < wobbleStrengthMin then wobbleStrengthMin, wobbleStrengthMax = wobbleStrengthMax, wobbleStrengthMin end

  local forwardClampMin = tonumber(cfg.forwardClampMin) or 0.55
  local forwardClampMax = tonumber(cfg.forwardClampMax) or 0.67
  if forwardClampMax < forwardClampMin then forwardClampMin, forwardClampMax = forwardClampMax, forwardClampMin end

  return {
    instanceId = (g_time or 0) + math.random(1, 999999),
    durationMs = minutes * 60 * 1000,
    clusterIndex = clusterIndex,
    driftDirection = driftDirection,
    basePull = pullMin + (math.random() * (pullMax - pullMin)),
    wobbleStrength = wobbleStrengthMin + (math.random() * (wobbleStrengthMax - wobbleStrengthMin)),
    forwardClamp = forwardClampMin + (math.random() * (forwardClampMax - forwardClampMin)),
    brakePulseMs = math.max(350, tonumber(cfg.brakePulseMs) or 900),
    wobbleMs = math.max(120, tonumber(cfg.wobbleMs) or 260),
    tickIntervalMs = math.max(500, tonumber(cfg.tickIntervalMs) or 4500),
    messageMode = messageMode
  }
end

function FarmingLive:flatTireChaos(playerName, durationMinutes, vehicleOverride, syncOptions, fromNetwork)
  if g_currentMission == nil then
    self:endActiveEvent()
    return
  end

  local cfg = FarmingLive.config.flatTire or {}
  local rootVehicle = vehicleOverride
  if rootVehicle == nil then
    if not g_localPlayer then
      self:endActiveEvent()
      return
    end

    rootVehicle = self:requireCurrentVehicle(playerName, self.flatTireChaos, playerName, durationMinutes)
    if rootVehicle == nil then
      return
    end
  end

  local messageMode = flResolveMode((type(syncOptions) == "table" and syncOptions.messageMode) or cfg.messageMode)
  local options = syncOptions
  if type(options) ~= "table" then
    options = flBuildFlatTireSyncOptions(self, cfg, rootVehicle, durationMinutes, messageMode)
  end

  if options == nil then
    self:showWarning((self.config.flatTire and self.config.flatTire.noSupport) or "Für dieses Fahrzeug konnte kein Reifen für einen echten Plattfuß gefunden werden.", 5000, messageMode)
    self:endActiveEvent()
    return
  end

  local clusterIndex = tonumber(options.clusterIndex)
  local cluster = flFindTireClusterByIndex(self, rootVehicle, clusterIndex)
  if clusterIndex == nil or cluster == nil then
    self:showWarning((self.config.flatTire and self.config.flatTire.noSupport) or "Für dieses Fahrzeug konnte kein Reifen für einen echten Plattfuß gefunden werden.", 5000, messageMode)
    self:endActiveEvent()
    return
  end

  local totalMs = math.max(1000, tonumber(options.durationMs) or (math.max(1, tonumber(durationMinutes) or 1) * 60 * 1000))
  local endTime = (g_time or 0) + totalMs
  local instanceId = tostring(options.instanceId or (g_time or 0))
  local hookKey = "flatTireChaos:" .. tostring(rootVehicle) .. ":" .. instanceId
  local effectKey = "flatTireChaos:" .. tostring(rootVehicle) .. ":" .. instanceId
  local enhancedVehicleState = nil
  local driftDirection = tonumber(options.driftDirection) or ((math.random() > 0.5) and 1 or -1)
  local shouldApplyPhysics = flShouldApplyTirePhysics(rootVehicle)
  local skipMessages = options.skipMessages == true

  local driftText = driftDirection < 0 and (cfg.pullLeft or "links") or (cfg.pullRight or "rechts")
  local basePull = tonumber(options.basePull) or 0.25
  local wobbleStrength = tonumber(options.wobbleStrength) or 0.08
  local forwardClamp = tonumber(options.forwardClamp) or 0.60
  local brakePulseMs = math.max(350, tonumber(options.brakePulseMs) or 900)
  local wobbleMs = math.max(120, tonumber(options.wobbleMs) or 260)
  local tickIntervalMs = math.max(500, tonumber(options.tickIntervalMs) or 4500)

  local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true
  local isServer = g_currentMission:getIsServer()

  if isMp and not isServer and not fromNetwork then
    FarmingLiveFlatTireEvent.sendToServer(rootVehicle, playerName, options)
  end

  local function hookFn(selfVeh, axisForward, axisSide, doHandbrake, dt)
    local now = g_time or 0
    local wobble = math.sin(now / wobbleMs) * wobbleStrength
    local newAxisSide = math.max(-1, math.min(1, (axisSide or 0) + (driftDirection * basePull) + wobble))
    local newAxisForward = axisForward

    if newAxisForward ~= nil and newAxisForward > 0 then
      newAxisForward = math.min(newAxisForward, forwardClamp)
    end

    local pulseWindow = now % brakePulseMs
    local pulseBrake = pulseWindow <= math.floor(brakePulseMs * 0.18)

    if selfVeh.spec_drivable ~= nil then
      selfVeh.spec_drivable.steeringInput = newAxisSide
    end

    return newAxisForward, newAxisSide, doHandbrake or pulseBrake, dt
  end

  FarmingLive:setTireEffectAmount(rootVehicle, effectKey, clusterIndex, 1)
  if shouldApplyPhysics then
    enhancedVehicleState = flDisableEnhancedVehicleSnap(rootVehicle)
    FarmingLive:attachVehiclePhysicsHook(rootVehicle, hookKey, hookFn)
  end

  if not skipMessages then
    local minutes = math.max(1, math.floor((totalMs + 59999) / 60000))
    FarmingLive:showFormattedWarning(FarmingLive.config.flatTire.start, 5000, playerName, minutes, driftText, FarmingLive:messageMode(messageMode))
  end

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0
    if now >= endTime then
      FarmingLive:clearTireEffect(rootVehicle, effectKey)
      if shouldApplyPhysics then
        FarmingLive:detachVehiclePhysicsHook(rootVehicle, hookKey)
        flRestoreEnhancedVehicleSnap(rootVehicle, enhancedVehicleState)
      end
      if not skipMessages then
        FarmingLive:showFormattedWarning(FarmingLive.config.flatTire.done, 5000, playerName, FarmingLive:messageMode(messageMode))
      end
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if not FarmingLive:isLiveEntity(rootVehicle) then
      FarmingLive:clearTireEffect(rootVehicle, effectKey)
      if shouldApplyPhysics then
        FarmingLive:detachVehiclePhysicsHook(rootVehicle, hookKey)
        flRestoreEnhancedVehicleSnap(rootVehicle, enhancedVehicleState)
      end
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    FarmingLive:setTireEffectAmount(rootVehicle, effectKey, clusterIndex, 1)

    if shouldApplyPhysics then
      flKeepEnhancedVehicleSnapDisabled(rootVehicle, enhancedVehicleState)
      FarmingLive:attachVehiclePhysicsHook(rootVehicle, hookKey, hookFn)
    end

    if not skipMessages then
      local remaining = math.max(1, math.ceil((endTime - now) / 1000))
      FarmingLive:showThrottledWarning("flatTireTick", FarmingLive:formatMessage(FarmingLive.config.flatTire.tick, playerName, remaining, driftText), 1200, tickIntervalMs, messageMode)
    end
  end

  FarmingLive:addUpdateable(watcher)
end
