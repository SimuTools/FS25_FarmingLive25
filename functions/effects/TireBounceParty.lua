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

local function flCopyEntries(entries)
  local result = {}
  for i = 1, #entries do
    result[#result + 1] = entries[i]
  end
  return result
end

local function flUniquePush(result, entry)
  if entry == nil then
    return
  end

  for _, existing in ipairs(result) do
    if existing.index == entry.index then
      return
    end
  end

  result[#result + 1] = entry
end

local function flSortByFrontBack(entries)
  local sorted = flCopyEntries(entries or {})
  table.sort(sorted, function(a, b)
    return (tonumber(a.cluster.posZ) or 0) > (tonumber(b.cluster.posZ) or 0)
  end)
  return sorted
end

local function flSortByLeftRight(entries)
  local sorted = flCopyEntries(entries or {})
  table.sort(sorted, function(a, b)
    return (tonumber(a.cluster.posX) or 0) < (tonumber(b.cluster.posX) or 0)
  end)
  return sorted
end

local function flGetFrontCandidates(tireClusters)
  if tireClusters == nil or #tireClusters == 0 then
    return {}
  end

  local sorted = flSortByFrontBack(tireClusters)
  local frontZ = tonumber(sorted[1].cluster.posZ) or 0
  local rearZ = tonumber(sorted[#sorted].cluster.posZ) or 0
  local span = math.abs(frontZ - rearZ)
  local tolerance = math.max(0.25, span * 0.14)
  local result = {}

  for _, entry in ipairs(sorted) do
    local z = tonumber(entry.cluster.posZ) or 0
    if math.abs(z - frontZ) <= tolerance then
      result[#result + 1] = entry
    end
  end

  if #result == 0 then
    result[#result + 1] = sorted[1]
    if sorted[2] ~= nil then
      result[#result + 1] = sorted[2]
    end
  end

  return result
end

local function flGetRearCandidates(tireClusters)
  if tireClusters == nil or #tireClusters == 0 then
    return {}
  end

  local sorted = flSortByFrontBack(tireClusters)
  local frontZ = tonumber(sorted[1].cluster.posZ) or 0
  local rearZ = tonumber(sorted[#sorted].cluster.posZ) or 0
  local span = math.abs(frontZ - rearZ)
  local tolerance = math.max(0.25, span * 0.14)
  local result = {}

  for _, entry in ipairs(sorted) do
    local z = tonumber(entry.cluster.posZ) or 0
    if math.abs(z - rearZ) <= tolerance then
      result[#result + 1] = entry
    end
  end

  if #result == 0 then
    result[#result + 1] = sorted[#sorted]
    if sorted[#sorted - 1] ~= nil then
      result[#result + 1] = sorted[#sorted - 1]
    end
  end

  return result
end

local function flGetLeftCandidates(tireClusters)
  local result = {}

  for _, entry in ipairs(tireClusters or {}) do
    local x = tonumber(entry.cluster.posX) or 0
    if x < -0.01 then
      result[#result + 1] = entry
    end
  end

  if #result == 0 and tireClusters ~= nil and #tireClusters > 0 then
    local sorted = flSortByLeftRight(tireClusters)
    local leftX = tonumber(sorted[1].cluster.posX) or 0
    for _, entry in ipairs(sorted) do
      local x = tonumber(entry.cluster.posX) or 0
      if math.abs(x - leftX) <= 0.3 then
        result[#result + 1] = entry
      end
    end
  end

  return result
end

local function flGetRightCandidates(tireClusters)
  local result = {}

  for _, entry in ipairs(tireClusters or {}) do
    local x = tonumber(entry.cluster.posX) or 0
    if x > 0.01 then
      result[#result + 1] = entry
    end
  end

  if #result == 0 and tireClusters ~= nil and #tireClusters > 0 then
    local sorted = flSortByLeftRight(tireClusters)
    local rightX = tonumber(sorted[#sorted].cluster.posX) or 0
    for i = #sorted, 1, -1 do
      local x = tonumber(sorted[i].cluster.posX) or 0
      if math.abs(x - rightX) <= 0.3 then
        result[#result + 1] = sorted[i]
      end
    end
  end

  return result
end

local function flPickExtremeLeftRight(entries)
  if entries == nil or #entries == 0 then
    return {}
  end

  local sorted = flSortByLeftRight(entries)
  local result = {}
  flUniquePush(result, sorted[1])
  flUniquePush(result, sorted[#sorted])

  if #result < 2 then
    for _, entry in ipairs(sorted) do
      flUniquePush(result, entry)
      if #result >= 2 then
        break
      end
    end
  end

  return result
end

local function flPickExtremeFrontRear(entries)
  if entries == nil or #entries == 0 then
    return {}
  end

  local sorted = flSortByFrontBack(entries)
  local result = {}
  flUniquePush(result, sorted[1])
  flUniquePush(result, sorted[#sorted])

  if #result < 2 then
    for _, entry in ipairs(sorted) do
      flUniquePush(result, entry)
      if #result >= 2 then
        break
      end
    end
  end

  return result
end

local function flBuildTirePartyGroups(tireClusters)
  local groups = {}

  local frontPair = flPickExtremeLeftRight(flGetFrontCandidates(tireClusters))
  local rearPair = flPickExtremeLeftRight(flGetRearCandidates(tireClusters))
  local leftPair = flPickExtremeFrontRear(flGetLeftCandidates(tireClusters))
  local rightPair = flPickExtremeFrontRear(flGetRightCandidates(tireClusters))

  if #frontPair == 2 then
    groups[#groups + 1] = { key = "front", entries = frontPair }
  end

  if #rearPair == 2 then
    groups[#groups + 1] = { key = "rear", entries = rearPair }
  end

  if #leftPair == 2 then
    groups[#groups + 1] = { key = "left", entries = leftPair }
  end

  if #rightPair == 2 then
    groups[#groups + 1] = { key = "right", entries = rightPair }
  end

  return groups
end

local function flSeedNext(state)
  state.seed = (state.seed * 1103515245 + 12345) % 2147483648
  return state.seed
end

local function flSeedRandomInt(state, minValue, maxValue)
  if maxValue < minValue then
    minValue, maxValue = maxValue, minValue
  end

  local fraction = flSeedNext(state) / 2147483648
  return math.floor(minValue + (fraction * ((maxValue - minValue) + 1)))
end

local function flSeedRandomFloat(state, minValue, maxValue)
  if maxValue < minValue then
    minValue, maxValue = maxValue, minValue
  end

  local fraction = flSeedNext(state) / 2147483648
  return minValue + (fraction * (maxValue - minValue))
end

local function flPickNextGroupSeeded(groups, previousKey, rngState)
  if groups == nil or #groups == 0 then
    return nil
  end

  local candidates = {}
  for _, group in ipairs(groups) do
    if previousKey == nil or #groups == 1 or group.key ~= previousKey then
      candidates[#candidates + 1] = group
    end
  end

  if #candidates == 0 then
    candidates = groups
  end

  return candidates[flSeedRandomInt(rngState, 1, #candidates)]
end

local function flBuildTirePartySyncOptions(cfg, durationMinutes, messageMode)
  local minutes = math.max(1, tonumber(durationMinutes) or 1)

  return {
    instanceId = (g_time or 0) + math.random(1, 999999),
    durationMs = minutes * 60 * 1000,
    minSwitchMs = math.max(90, tonumber(cfg.minSwitchMs) or 140),
    maxSwitchMs = math.max(math.max(90, tonumber(cfg.minSwitchMs) or 140), tonumber(cfg.maxSwitchMs) or 260),
    flatMessageMs = math.max(150, tonumber(cfg.flatMessageMs) or 700),
    fullMessageMs = math.max(150, tonumber(cfg.fullMessageMs) or 500),
    seed = math.random(1, 2147483000),
    messageMode = messageMode
  }
end

function FarmingLive:tireBounceParty(playerName, durationMinutes, vehicleOverride, syncOptions, fromNetwork)
  if g_currentMission == nil then
    self:endActiveEvent()
    return
  end

  local cfg = FarmingLive.config.tireParty or {}
  local messageMode = flResolveMode((type(syncOptions) == "table" and syncOptions.messageMode) or cfg.messageMode)
  local rootVehicle = vehicleOverride

  if rootVehicle == nil then
    if not g_localPlayer then
      self:endActiveEvent()
      return
    end

    rootVehicle = self:requireCurrentVehicle(playerName, self.tireBounceParty, playerName, durationMinutes)
    if rootVehicle == nil then
      return
    end
  end

  local tireClusters = self:getAllTireEffectClusters(rootVehicle)
  if tireClusters == nil or #tireClusters == 0 then
    self:showWarning((self.config.tireParty and self.config.tireParty.noSupport) or "Für dieses Fahrzeug konnte kein Reifen für die Reifenparty gefunden werden.", 5000, messageMode)
    self:endActiveEvent()
    return
  end

  local tireGroups = flBuildTirePartyGroups(tireClusters)
  if tireGroups == nil or #tireGroups == 0 then
    self:showWarning((self.config.tireParty and self.config.tireParty.noSupport) or "Für dieses Fahrzeug konnten keine gültigen Reifenpaare für die Reifenparty gefunden werden.", 5000, messageMode)
    self:endActiveEvent()
    return
  end

  local options = syncOptions
  if type(options) ~= "table" then
    options = flBuildTirePartySyncOptions(cfg, durationMinutes, messageMode)
  end

  local totalMs = math.max(1000, tonumber(options.durationMs) or (math.max(1, tonumber(durationMinutes) or 1) * 60 * 1000))
  local endTime = (g_time or 0) + totalMs
  local minSwitchMs = math.max(90, tonumber(options.minSwitchMs) or 140)
  local maxSwitchMs = math.max(minSwitchMs, tonumber(options.maxSwitchMs) or 260)
  local flatMessageMs = math.max(150, tonumber(options.flatMessageMs) or 700)
  local fullMessageMs = math.max(150, tonumber(options.fullMessageMs) or 500)
  local rngState = { seed = tonumber(options.seed) or 12345 }

  local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true
  local isServer = g_currentMission:getIsServer()
  if isMp and not isServer and not fromNetwork then
    FarmingLiveTirePartyEvent.sendToServer(rootVehicle, playerName, options)
  end

  local instanceId = tostring(options.instanceId or (g_time or 0))
  local hookKey = "tireBounceParty:" .. tostring(rootVehicle) .. ":" .. instanceId
  local effectKey = "tireBounceParty:" .. tostring(rootVehicle) .. ":" .. instanceId
  local enhancedVehicleState = nil
  local shouldApplyPhysics = flShouldApplyTirePhysics(rootVehicle)
  local skipMessages = options.skipMessages == true

  local nextSwitch = g_time or 0
  local isFlat = false
  local activeGroup = nil
  local lastGroupKey = nil
  local driftDirection = 1

  local pullStrength = 0.0
  local wobbleStrength = 0.0
  local forwardClamp = 1.0
  local pulseMs = 20
  local wobbleMs = 10

  local function clearAll()
    for _, entry in ipairs(tireClusters) do
      FarmingLive:clearTireEffect(rootVehicle, string.format("%s:%d", effectKey, entry.index))
    end
  end

  local function cleanupCompat()
    if shouldApplyPhysics then
      FarmingLive:detachVehiclePhysicsHook(rootVehicle, hookKey)
      flRestoreEnhancedVehicleSnap(rootVehicle, enhancedVehicleState)
    end
  end

  local function applyGroup(group, amount)
    clearAll()

    if group == nil then
      return
    end

    for _, entry in ipairs(group.entries or {}) do
      FarmingLive:setTireEffectAmount(rootVehicle, string.format("%s:%d", effectKey, entry.index), entry.index, amount)
    end
  end

  local function randomizeFlatState(group)
    local key = group ~= nil and group.key or "front"

    if key == "front" then
      pullStrength = flSeedRandomFloat(rngState, 0.10, 0.16)
      wobbleStrength = flSeedRandomFloat(rngState, 0.10, 0.16)
      forwardClamp = flSeedRandomFloat(rngState, 0.40, 0.48)
      pulseMs = flSeedRandomInt(rngState, 90, 170)
      wobbleMs = flSeedRandomInt(rngState, 35, 60)
      driftDirection = (flSeedRandomInt(rngState, 0, 1) == 0) and -1 or 1
    elseif key == "rear" then
      pullStrength = flSeedRandomFloat(rngState, 0.05, 0.10)
      wobbleStrength = flSeedRandomFloat(rngState, 0.12, 0.18)
      forwardClamp = flSeedRandomFloat(rngState, 0.46, 0.54)
      pulseMs = flSeedRandomInt(rngState, 100, 180)
      wobbleMs = flSeedRandomInt(rngState, 40, 65)
      driftDirection = (flSeedRandomInt(rngState, 0, 1) == 0) and -1 or 1
    elseif key == "left" then
      pullStrength = flSeedRandomFloat(rngState, 0.11, 0.17)
      wobbleStrength = flSeedRandomFloat(rngState, 0.08, 0.13)
      forwardClamp = flSeedRandomFloat(rngState, 0.42, 0.50)
      pulseMs = flSeedRandomInt(rngState, 90, 170)
      wobbleMs = flSeedRandomInt(rngState, 35, 60)
      driftDirection = -1
    elseif key == "right" then
      pullStrength = flSeedRandomFloat(rngState, 0.11, 0.17)
      wobbleStrength = flSeedRandomFloat(rngState, 0.08, 0.13)
      forwardClamp = flSeedRandomFloat(rngState, 0.42, 0.50)
      pulseMs = flSeedRandomInt(rngState, 90, 170)
      wobbleMs = flSeedRandomInt(rngState, 35, 60)
      driftDirection = 1
    else
      pullStrength = flSeedRandomFloat(rngState, 0.08, 0.14)
      wobbleStrength = flSeedRandomFloat(rngState, 0.08, 0.14)
      forwardClamp = flSeedRandomFloat(rngState, 0.44, 0.52)
      pulseMs = flSeedRandomInt(rngState, 90, 170)
      wobbleMs = flSeedRandomInt(rngState, 35, 60)
      driftDirection = (flSeedRandomInt(rngState, 0, 1) == 0) and -1 or 1
    end
  end

  local function hookFn(selfVeh, axisForward, axisSide, doHandbrake, dt)
    local newAxisForward = axisForward
    local newAxisSide = axisSide

    if isFlat and activeGroup ~= nil then
      local now = g_time or 0
      local wobble = math.sin(now / wobbleMs) * wobbleStrength
      local sideExtra = driftDirection * pullStrength

      if activeGroup.key == "rear" then
        sideExtra = sideExtra * 0.65
        wobble = wobble * 1.20
      elseif activeGroup.key == "front" then
        sideExtra = sideExtra * 0.95
      end

      newAxisSide = math.max(-1, math.min(1, (axisSide or 0) + sideExtra + wobble))

      if newAxisForward ~= nil and newAxisForward > 0 then
        newAxisForward = math.min(newAxisForward, forwardClamp)
      end

      local pulseBrake = (now % pulseMs) <= math.floor(pulseMs * 0.24)

      if selfVeh.spec_drivable ~= nil then
        selfVeh.spec_drivable.steeringInput = newAxisSide
      end

      return newAxisForward, newAxisSide, doHandbrake or pulseBrake, dt
    end

    return newAxisForward, newAxisSide, doHandbrake, dt
  end

  if shouldApplyPhysics then
    enhancedVehicleState = flDisableEnhancedVehicleSnap(rootVehicle)
    FarmingLive:attachVehiclePhysicsHook(rootVehicle, hookKey, hookFn)
  end

  if not skipMessages then
    local minutes = math.max(1, math.floor((totalMs + 59999) / 60000))
    FarmingLive:showFormattedWarning(FarmingLive.config.tireParty.start, 5000, playerName, minutes, FarmingLive:messageMode(messageMode))
  end

  local watcher = {}

  function watcher:update(dt)
    local now = g_time or 0

    if now >= endTime then
      clearAll()
      cleanupCompat()
      if not skipMessages then
        FarmingLive:showFormattedWarning(FarmingLive.config.tireParty.done, 5000, playerName, FarmingLive:messageMode(messageMode))
      end
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if not FarmingLive:isLiveEntity(rootVehicle) then
      clearAll()
      cleanupCompat()
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if now >= nextSwitch then
      isFlat = not isFlat

      if isFlat then
        activeGroup = flPickNextGroupSeeded(tireGroups, lastGroupKey, rngState)
        if activeGroup ~= nil then
          lastGroupKey = activeGroup.key
        end

        randomizeFlatState(activeGroup)
        applyGroup(activeGroup, 1)
        if not skipMessages then
          FarmingLive:showFormattedWarning(FarmingLive.config.tireParty.flat, flatMessageMs, playerName, FarmingLive:messageMode(messageMode))
        end
      else
        activeGroup = nil
        applyGroup(nil, 0)
        if not skipMessages then
          FarmingLive:showFormattedWarning(FarmingLive.config.tireParty.full, fullMessageMs, playerName, FarmingLive:messageMode(messageMode))
        end
      end

      nextSwitch = now + flSeedRandomInt(rngState, minSwitchMs, maxSwitchMs)
    end

    if shouldApplyPhysics then
      flKeepEnhancedVehicleSnapDisabled(rootVehicle, enhancedVehicleState)
      FarmingLive:attachVehiclePhysicsHook(rootVehicle, hookKey, hookFn)
    end
  end

  FarmingLive:addUpdateable(watcher)
end
