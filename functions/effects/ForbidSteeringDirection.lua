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

local function flShouldApplyControlPhysics(vehicle)
  if vehicle == nil then
    return false
  end

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

local function flResolveMode(mode)
  local normalized = tostring(mode or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if normalized == "" or normalized == "default" or normalized == "global" or normalized == "inherit" then
    return nil
  end
  return mode
end

local function flBuildForbidSyncOptions(minMinutes, maxMinutes)
  local minM = tonumber(minMinutes) or 1
  local maxM = tonumber(maxMinutes) or 5
  if maxM < minM then maxM = minM end

  return {
    instanceId = (g_time or 0) + math.random(1, 999999),
    durationMs = math.random(minM * 60 * 1000, maxM * 60 * 1000),
    forbidLeft = math.random() > 0.5
  }
end

function FarmingLive:forbidSteeringDirection(playerName, minMinutes, maxMinutes, vehicleOverride, syncOptions, fromNetwork)
  print("[FarmingLive] forbidSteeringDirection gestartet für: " .. tostring(playerName))
  if g_currentMission == nil then self:endActiveEvent(); return end

  local rootVehicle = vehicleOverride
  if rootVehicle == nil then
    if not g_localPlayer then self:endActiveEvent(); return end
    rootVehicle = FarmingLive:getCurrentVehicleOrLast()
    if rootVehicle == nil or rootVehicle.spec_drivable == nil then
      self:queueOrRunVehicleAction(playerName, self.forbidSteeringDirection, playerName, minMinutes, maxMinutes)
      self:endActiveEvent()
      return
    end
  elseif rootVehicle.spec_drivable == nil then
    self:endActiveEvent()
    return
  end

  local options = type(syncOptions) == "table" and syncOptions or flBuildForbidSyncOptions(minMinutes, maxMinutes)
  local blockMs = math.max(1000, tonumber(options.durationMs) or 60000)
  local tEnd = (g_time or 0) + blockMs
  local forbidLeft = options.forbidLeft == true
  local hookKey = "forbidSteeringDirection:" .. tostring(rootVehicle) .. ":" .. tostring(options.instanceId or (g_time or 0))
  local shouldApplyPhysics = flShouldApplyControlPhysics(rootVehicle)
  local skipMessages = options.skipMessages == true
  local messageMode = flResolveMode(options.messageMode)
  local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true
  local isServer = g_currentMission:getIsServer()

  if isMp and not isServer and not fromNetwork then
    FarmingLiveForbidSteerEvent.sendToServer(rootVehicle, playerName, options)
  end

  if not shouldApplyPhysics then
    if not skipMessages then
      self:endActiveEvent()
    end
    return
  end

  local function fmt(ms)
    local s = math.max(0, math.ceil(ms/1000))
    return string.format("%d:%02d", math.floor(s/60), s%60)
  end

  local dirKey  = forbidLeft and "@FORBIDDIR_LEFT" or "@FORBIDDIR_RIGHT"
  local dirText = FarmingLive:resolveTemplate(dirKey, dirKey)

  if not skipMessages then
    local introMsg = FarmingLive:formatMessage(
      FarmingLive.config.forbiddenSteeringDir.BlockWarn,
      playerName,
      dirText,
      fmt(blockMs)
    )
    FarmingLive:showWarning(introMsg, 7000, messageMode)
  end

  local hookedVeh = nil
  local enhancedVehicleState = nil

  local function steeringPhysicsHook(selfVeh, axisForward, axisSide, doHandbrake, dt)
    local newSide = axisSide
    if (forbidLeft and (newSide or 0) < 0) or ((not forbidLeft) and (newSide or 0) > 0) then
      newSide = 0
      if selfVeh.spec_drivable ~= nil then
        selfVeh.spec_drivable.steeringInput = 0
      end
      if not skipMessages then
        local remaining = tEnd - (g_time or 0)
        local warn = FarmingLive:formatMessage(
          FarmingLive.config.forbiddenSteeringDir.BlockWarnTry,
          playerName, dirText, fmt(remaining)
        )
        FarmingLive:showThrottledWarning("forbidSteer", warn, 1000, 1000, messageMode)
      end
    end
    return axisForward, newSide, doHandbrake, dt
  end

  local function detachCurrent()
    if hookedVeh ~= nil then
      FarmingLive:detachVehiclePhysicsHook(hookedVeh, hookKey)
      if hookedVeh.spec_drivable ~= nil then
        hookedVeh.spec_drivable.steeringInput = 0
      end
      flRestoreEnhancedVehicleSnap(hookedVeh, enhancedVehicleState)
    end
    hookedVeh = nil
    enhancedVehicleState = nil
  end

  local function attachTo(v)
    if v == nil or v.spec_drivable == nil then
      return false
    end

    if hookedVeh == v then
      flKeepEnhancedVehicleSnapDisabled(v, enhancedVehicleState)
      FarmingLive:attachVehiclePhysicsHook(v, hookKey, steeringPhysicsHook)
      return true
    end

    detachCurrent()
    enhancedVehicleState = flDisableEnhancedVehicleSnap(v)
    FarmingLive:attachVehiclePhysicsHook(v, hookKey, steeringPhysicsHook)
    hookedVeh = v
    return true
  end

  attachTo(rootVehicle)

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0
    if now >= tEnd then
      detachCurrent()
      if not skipMessages then
        local doneMsg = FarmingLive:formatMessage(FarmingLive.config.forbiddenSteeringDir.BlockWarnReset, playerName)
        FarmingLive:showWarning(doneMsg, 7000, messageMode)
        FarmingLive:endActiveEvent()
      end
      g_currentMission:removeUpdateable(self)
      print("[FarmingLive] forbidSteeringDirection beendet")
      return
    end

    attachTo(hookedVeh or rootVehicle)

  end

  g_currentMission:addUpdateable(watcher)
end
