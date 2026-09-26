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

local function flFindNextTabVehicle(currentVehicle)
  local tabbable = flGetTabbableVehicles()
  if #tabbable < 2 then
    return nil, #tabbable
  end

  local index = 0
  for i, vehicle in ipairs(tabbable) do
    if vehicle == currentVehicle then
      index = i
      break
    end
  end

  local nextIndex = (index % #tabbable) + 1
  return tabbable[nextIndex], #tabbable
end

function FarmingLive:randomTabTrap(playerName, lockMinutes, switchCount, minSwitchDelayMs, maxSwitchDelayMs)
  if not g_localPlayer or not g_currentMission then
    self:endActiveEvent()
    return
  end

  local player = self:getLocalMissionPlayer()
  if not player then
    self:endActiveEvent()
    return
  end

  local currentVehicle = self:requireCurrentVehicle(playerName, self.randomTabTrap, playerName, lockMinutes, switchCount, minSwitchDelayMs, maxSwitchDelayMs)
  if currentVehicle == nil then
    return
  end

  local totalTabbable = #flGetTabbableVehicles()
  if totalTabbable < 2 then
    self:showFormattedWarning(FarmingLive.config.tabTrap.tooFewVehicles, 5000, playerName)
    self:endActiveEvent()
    return
  end

  local totalSwitches = math.max(2, tonumber(switchCount) or 3)
  local minDelay = math.max(120, tonumber(minSwitchDelayMs) or 450)
  local maxDelay = math.max(minDelay, tonumber(maxSwitchDelayMs) or 1100)
  local minutes = math.max(1, tonumber(lockMinutes) or 1)

  self:showFormattedWarning(FarmingLive.config.tabTrap.start, 5000, playerName, totalSwitches, minutes)

  local switchIndex = 0
  local nextSwitchTime = (g_time or 0) + math.random(minDelay, maxDelay)
  local lockEndTime = nil
  local lockedVehicle = nil
  local lastRecoveryTry = 0
  local entryBlock = nil
  local exitBlock = nil

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0

    if lockEndTime == nil then
      if now >= nextSwitchTime then
        local current = player:getCurrentVehicle() or currentVehicle
        local nextVehicle, tabbableCount = flFindNextTabVehicle(current)

        if nextVehicle == nil then
          FarmingLive:showFormattedWarning(FarmingLive.config.tabTrap.tooFewVehicles, 5000, playerName)
          FarmingLive:removeUpdateable(self)
          FarmingLive:endActiveEvent()
          return
        end

        player:requestToEnterVehicle(nextVehicle)
        currentVehicle = nextVehicle
        switchIndex = switchIndex + 1

        FarmingLive:showThrottledFormattedWarning("tabTrapSwitch", FarmingLive.config.tabTrap.switch, 1200, 350, playerName, switchIndex, tabbableCount)

        if switchIndex >= totalSwitches then
          lockedVehicle = player:getCurrentVehicle() or nextVehicle or currentVehicle
          lockEndTime = now + (minutes * 60 * 1000)

          exitBlock = FarmingLive:blockVehicleExit(lockedVehicle, function()
            local remaining = math.max(1, math.ceil((lockEndTime - (g_time or 0)) / 1000))
            FarmingLive:showThrottledFormattedWarning("tabTrapExit", FarmingLive.config.tabTrap.tryExit, 1800, 2500, playerName, remaining)
            return false
          end)

          entryBlock = FarmingLive:blockVehicleEntry(
            player,
            function(target)
              return target ~= lockedVehicle
            end,
            function(_, target, ...)
              local remaining = math.max(1, math.ceil((lockEndTime - (g_time or 0)) / 1000))
              FarmingLive:showThrottledFormattedWarning("tabTrapEnter", FarmingLive.config.tabTrap.trySwitch, 1800, 2500, playerName, remaining)
              return false
            end
          )

          FarmingLive:showFormattedWarning(FarmingLive.config.tabTrap.locked, 5000, playerName, minutes)
        else
          nextSwitchTime = now + math.random(minDelay, maxDelay)
        end
      end

      return
    end

    if now >= lockEndTime then
      FarmingLive:restoreVehicleEntryBlock(entryBlock)
      FarmingLive:restoreVehicleExitBlock(exitBlock)
      FarmingLive:showFormattedWarning(FarmingLive.config.tabTrap.done, 5000, playerName)
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if lockedVehicle == nil or not FarmingLive:isLiveEntity(lockedVehicle) then
      FarmingLive:restoreVehicleEntryBlock(entryBlock)
      FarmingLive:restoreVehicleExitBlock(exitBlock)
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      return
    end

    if (player:getCurrentVehicle() ~= lockedVehicle) and now - lastRecoveryTry >= 1000 then
      lastRecoveryTry = now
      player:requestToEnterVehicle(lockedVehicle)
    end
  end

  self:addUpdateable(watcher)
end
