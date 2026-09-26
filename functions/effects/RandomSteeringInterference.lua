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

local function flCreateDeterministicRng(seed)
  local state = math.floor(math.abs(tonumber(seed) or 1)) % 2147483647
  if state <= 0 then
    state = 1
  end

  return function(minValue, maxValue)
    state = (state * 48271) % 2147483647
    local normalized = state / 2147483647

    if minValue == nil and maxValue == nil then
      return normalized
    end

    if maxValue == nil then
      maxValue = minValue
      minValue = 1
    end

    minValue = tonumber(minValue) or 0
    maxValue = tonumber(maxValue) or minValue
    if maxValue < minValue then
      minValue, maxValue = maxValue, minValue
    end

    if math.floor(minValue) == minValue and math.floor(maxValue) == maxValue then
      return minValue + math.floor(normalized * ((maxValue - minValue) + 1))
    end

    return minValue + (normalized * (maxValue - minValue))
  end
end

local function flBuildRandomSteerSyncOptions(minMinutes, maxMinutes, cfgMessageMode)
  local minM = tonumber(minMinutes) or 1
  local maxM = tonumber(maxMinutes) or 5
  if maxM < minM then
    maxM = minM
  end

  local seed = math.floor((g_time or 0) + math.random(1, 999999))
  local rand = flCreateDeterministicRng(seed)
  local totalMs = rand(minM * 60 * 1000, maxM * 60 * 1000)
  local setSpeedKmh = rand(1, 99)

  return {
    instanceId = (g_time or 0) + math.random(1, 999999),
    durationMs = totalMs,
    seed = seed,
    setSpeedKmh = setSpeedKmh,
    messageMode = cfgMessageMode
  }
end

function FarmingLive:randomSteeringInterference(playerName, minMinutes, maxMinutes, vehicleOverride, syncOptions, fromNetwork)
  print("[FarmingLive] randomSteeringInterference gestartet für: " .. tostring(playerName))

  if g_currentMission == nil then
    self:endActiveEvent()
    return
  end

  local rootVehicle = vehicleOverride
  if rootVehicle == nil then
    if not g_localPlayer then
      self:endActiveEvent()
      return
    end

    rootVehicle = self:getCurrentVehicleOrLast()
    if rootVehicle == nil or rootVehicle.spec_drivable == nil then
      self:queueOrRunVehicleAction(playerName, self.randomSteeringInterference, playerName, minMinutes, maxMinutes)
      self:endActiveEvent()
      return
    end
  elseif rootVehicle.spec_drivable == nil then
    self:endActiveEvent()
    return
  end

  local options = type(syncOptions) == "table" and syncOptions or flBuildRandomSteerSyncOptions(minMinutes, maxMinutes, nil)
  local messageMode = flResolveMode(options.messageMode)
  local skipMessages = options.skipMessages == true
  local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true
  local isServer = g_currentMission:getIsServer()

  if isMp and not isServer and not fromNetwork then
    FarmingLiveRandomSteerEvent.sendToServer(rootVehicle, playerName, options)
  end

  local totalMs = math.max(1000, tonumber(options.durationMs) or 60000)
  local rng = flCreateDeterministicRng(options.seed)
  local tEnd = (g_time or 0) + totalMs
  local hookKey = "randomSteeringInterference:" .. tostring(rootVehicle) .. ":" .. tostring(options.instanceId or (g_time or 0))
  local shouldApplyPhysics = flShouldApplyControlPhysics(rootVehicle)

  if not shouldApplyPhysics then
    if not skipMessages then
      self:endActiveEvent()
    end
    return
  end

  local inSegment = false
  local nextSwitchTime = g_time or 0
  local segmentEndTime = g_time or 0
  local currentDir = 0
  local cruiseActive = false
  local setSpeedKmh = tonumber(options.setSpeedKmh) or rng(1, 99)
  local hookedVeh = nil
  local origCruiseState = nil
  local enhancedVehicleState = nil

  local function steeringPhysicsHook(selfVeh, axisForward, axisSide, doHandbrake, dt)
    if inSegment then
      if selfVeh.spec_drivable ~= nil then
        selfVeh.spec_drivable.steeringInput = currentDir
      end
      return axisForward, currentDir, doHandbrake, dt
    end

    return axisForward, axisSide, doHandbrake, dt
  end

  local function detachCurrent()
    if hookedVeh ~= nil then
      FarmingLive:detachVehiclePhysicsHook(hookedVeh, hookKey)

      if hookedVeh.spec_drivable ~= nil then
        hookedVeh.spec_drivable.steeringInput = 0
      end

      if cruiseActive then
        if origCruiseState ~= nil then
          hookedVeh.setCruiseControlState = origCruiseState
          origCruiseState(hookedVeh, 0)
        elseif hookedVeh.setCruiseControlState ~= nil then
          hookedVeh:setCruiseControlState(0)
        end
        cruiseActive = false
      elseif origCruiseState ~= nil then
        hookedVeh.setCruiseControlState = origCruiseState
      end

      flRestoreEnhancedVehicleSnap(hookedVeh, enhancedVehicleState)
    end

    hookedVeh = nil
    origCruiseState = nil
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

    origCruiseState = v.setCruiseControlState
    if origCruiseState ~= nil then
      v.setCruiseControlState = function(selfVeh, state)
        if cruiseActive and state == 0 then
          return
        end
        return origCruiseState(selfVeh, state)
      end
    end

    enhancedVehicleState = flDisableEnhancedVehicleSnap(v)

    FarmingLive:attachVehiclePhysicsHook(v, hookKey, steeringPhysicsHook)
    hookedVeh = v
    return true
  end

  if not skipMessages then
    local introMsg = FarmingLive:formatMessage(
      FarmingLive.config.randomSteer.BlockStart,
      playerName,
      string.format("%.1f", totalMs / 60000)
    )
    FarmingLive:showWarning(introMsg, 5000, messageMode)
  end

  attachTo(rootVehicle)

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0
    if now >= tEnd then
      detachCurrent()
      if not skipMessages then
        local doneMsg = FarmingLive:formatMessage(FarmingLive.config.randomSteer.BlockEnd, playerName)
        FarmingLive:showWarning(doneMsg, 5000, messageMode)
        FarmingLive:endActiveEvent()
      end
      g_currentMission:removeUpdateable(self)
      print("[FarmingLive] randomSteeringInterference beendet")
      return
    end

    local cur = hookedVeh or rootVehicle
    if cur ~= hookedVeh then
      attachTo(cur)
    elseif cur ~= nil then
      flKeepEnhancedVehicleSnapDisabled(cur, enhancedVehicleState)
      FarmingLive:attachVehiclePhysicsHook(cur, hookKey, steeringPhysicsHook)
    end

    if hookedVeh == nil then
      return
    end

    if inSegment then
      if now >= segmentEndTime then
        inSegment = false
        currentDir = 0
        nextSwitchTime = now + rng(100, 60000)

        if cruiseActive then
          if origCruiseState ~= nil then
            hookedVeh.setCruiseControlState = origCruiseState
            origCruiseState(hookedVeh, 0)
            hookedVeh.setCruiseControlState = function(selfVeh, state)
              if cruiseActive and state == 0 then
                return
              end
              return origCruiseState(selfVeh, state)
            end
          elseif hookedVeh.setCruiseControlState ~= nil then
            hookedVeh:setCruiseControlState(0)
          end
          cruiseActive = false
        end
      end
    else
      if now >= nextSwitchTime then
        inSegment = true
        local dir = (rng() > 0.5) and 1 or -1
        local strength = rng()
        currentDir = dir * strength
        segmentEndTime = now + rng(1000, 15000)

        if rng() < 0.5 and hookedVeh.setCruiseControlState ~= nil then
          hookedVeh:setCruiseControlState(1)
          if type(hookedVeh.setCruiseControlMaxSpeed) == "function" then
            hookedVeh:setCruiseControlMaxSpeed(setSpeedKmh, setSpeedKmh)
          end
          cruiseActive = true
        end
      end
    end
  end

  g_currentMission:addUpdateable(watcher)
end
