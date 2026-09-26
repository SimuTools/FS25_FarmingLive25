local function flGetTabbableVehicles()
  local vehicles = {}
  local allVehicles = {}

  if g_currentMission and g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.getVehicles then
    allVehicles = g_currentMission.vehicleSystem:getVehicles() or {}
  elseif g_currentMission and g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles then
    allVehicles = g_currentMission.vehicleSystem.vehicles
  elseif g_currentMission and g_currentMission.vehicles then
    allVehicles = g_currentMission.vehicles
  end

  for _, vehicle in pairs(allVehicles) do
    if vehicle ~= nil and vehicle.getIsTabbable and vehicle:getIsTabbable() then
      table.insert(vehicles, vehicle)
    end
  end

  return vehicles
end

local function flResolveMode(mode)
  local normalized = tostring(mode or ""):gsub("^%s+", ""):gsub("%s+$", "")
  normalized = normalized:lower()
  if normalized == "" or normalized == "default" or normalized == "global" or normalized == "inherit" then
    return nil
  end
  return mode
end

function FarmingLive:driveThat(playerName, lockMinutes)
  if not g_localPlayer or not g_currentMission then
    self:endActiveEvent()
    return
  end

  local player = self:getLocalMissionPlayer()
  if player == nil then
    self:endActiveEvent()
    return
  end

  local cfg = FarmingLive.config.driveThat or {}
  local messageMode = flResolveMode(cfg.messageMode)

  local currentVehicle = self:requireCurrentVehicle(playerName, self.driveThat, playerName, lockMinutes)
  if currentVehicle == nil then
    return
  end

  local tabbable = flGetTabbableVehicles()
  if #tabbable < 2 then
    self:showFormattedWarning(FarmingLive.config.driveThat.tooFewVehicles, 5000, playerName, self:messageMode(messageMode))
    self:endActiveEvent()
    return
  end

  local candidates = {}
  for _, vehicle in ipairs(tabbable) do
    if vehicle ~= currentVehicle then
      table.insert(candidates, vehicle)
    end
  end

  if #candidates == 0 then
    self:showFormattedWarning(FarmingLive.config.driveThat.tooFewVehicles, 5000, playerName, self:messageMode(messageMode))
    self:endActiveEvent()
    return
  end

  local targetVehicle = candidates[math.random(1, #candidates)]
  local targetName = (targetVehicle.getName and targetVehicle:getName()) or ("#" .. tostring(targetVehicle.id or "?"))
  local minutes = math.max(1, tonumber(lockMinutes) or 1)
  local enterTimeoutMs = math.max(500, tonumber(cfg.enterTimeoutMs) or 2500)
  local enterRetryMs = math.max(150, tonumber(cfg.enterRetryMs) or 500)
  local recoveryRetryMs = math.max(250, tonumber(cfg.recoveryRetryMs) or 1000)
  local enterDeadline = (g_time or 0) + enterTimeoutMs
  local lockEndTime = nil
  local entryBlock = nil
  local exitBlock = nil
  local lastRecoveryTry = 0

  self:showFormattedWarning(FarmingLive.config.driveThat.start, 5000, playerName, minutes, nil, targetName, self:messageMode(messageMode))
  player:requestToEnterVehicle(targetVehicle)

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0

    if lockEndTime == nil then
      if player:getCurrentVehicle() ~= targetVehicle then
        if now >= enterDeadline then
          FarmingLive:showFormattedWarning(FarmingLive.config.driveThat.failed, 5000, nil, nil, nil, targetName, FarmingLive:messageMode(messageMode))
          FarmingLive:removeUpdateable(self)
          FarmingLive:endActiveEvent()
          return
        end

        if now - lastRecoveryTry >= enterRetryMs then
          lastRecoveryTry = now
          player:requestToEnterVehicle(targetVehicle)
        end
        return
      end

      lockEndTime = now + (minutes * 60 * 1000)

      exitBlock = FarmingLive:blockVehicleExit(targetVehicle, function()
        local remaining = math.max(1, math.ceil((lockEndTime - (g_time or 0)) / 1000))
        FarmingLive:showFormattedWarning(FarmingLive.config.driveThat.tryExit, 1800, playerName, remaining, nil, targetName, FarmingLive:messageMode(messageMode))
        return false
      end)

      entryBlock = FarmingLive:blockVehicleEntry(
        player,
        function(target)
          return target ~= targetVehicle
        end,
        function(_, target, ...)
          local remaining = math.max(1, math.ceil((lockEndTime - (g_time or 0)) / 1000))
          FarmingLive:showFormattedWarning(FarmingLive.config.driveThat.trySwitch, 1800, playerName, remaining, nil, targetName, FarmingLive:messageMode(messageMode))
          return false
        end
      )

      FarmingLive:showFormattedWarning(FarmingLive.config.driveThat.locked, 5000, playerName, minutes, nil, targetName, FarmingLive:messageMode(messageMode))
      return
    end

    if now >= lockEndTime then
      FarmingLive:restoreVehicleEntryBlock(entryBlock)
      FarmingLive:restoreVehicleExitBlock(exitBlock)
      FarmingLive:showFormattedWarning(FarmingLive.config.driveThat.done, 5000, playerName, nil, nil, targetName, FarmingLive:messageMode(messageMode))
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if targetVehicle == nil or not FarmingLive:isLiveEntity(targetVehicle) then
      FarmingLive:restoreVehicleEntryBlock(entryBlock)
      FarmingLive:restoreVehicleExitBlock(exitBlock)
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if (player:getCurrentVehicle() ~= targetVehicle) and now - lastRecoveryTry >= recoveryRetryMs then
      lastRecoveryTry = now
      player:requestToEnterVehicle(targetVehicle)
    end
  end

  self:addUpdateable(watcher)
end
