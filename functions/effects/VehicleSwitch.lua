function FarmingLive:cycleVehicle(playerName)
  print("[FarmingLive] cycleVehicle wurde gestartet")
  if not g_currentMission or not g_localPlayer then
    FarmingLive:endActiveEvent()
    return
  end

  local allV = (g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles) or {}
  local tabbable = {}
  for _, veh in ipairs(allV) do
    if veh.getIsTabbable and veh:getIsTabbable() then
      table.insert(tabbable, veh)
    end
  end

  if #tabbable < 2 then
    FarmingLive:showFormattedWarning("@CYCLE_TOOFEW", 5000, playerName)
    FarmingLive:endActiveEvent()
    return
  end

  local player = FarmingLive:getLocalMissionPlayer()
  if not player then
    FarmingLive:endActiveEvent()
    return
  end

  local current = player:getCurrentVehicle()
  local idx = 0
  for i, veh in ipairs(tabbable) do
    if veh == current then
      idx = i
      break
    end
  end

  local nextIndex = (idx % #tabbable) + 1
  local nextVeh = tabbable[nextIndex]

  player:requestToEnterVehicle(nextVeh)

  FarmingLive:showFormattedWarning("@CYCLE_SWITCHED", 5000, playerName, nextIndex, #tabbable)

  print(string.format(
    "[FarmingLive] cycleVehicle: %s wechselt zu %s (Index %d/%d)",
    tostring(playerName),
    (nextVeh.getName and nextVeh.getName(nextVeh)) or tostring(nextVeh),
    nextIndex, #tabbable
  ))
  FarmingLive:endActiveEvent()
  print("[FarmingLive] Event Beendet")
end

function FarmingLive:lockOutCurrentVehicle(playerName, minMin, maxMin)
  print("[FarmingLive] lockOutCurrentVehicle wurde gestartet")
  if not g_localPlayer or not g_currentMission then
    FarmingLive:endActiveEvent()
    return
  end

  local lockedVeh = self:requireCurrentVehicle(playerName, self.lockOutCurrentVehicle, playerName, minMin, maxMin)
  if not lockedVeh then
    return
  end

  local player = self:getLocalMissionPlayer()
  if not player then
    self:endActiveEvent()
    return
  end

  self:leaveVehicle(lockedVeh)

  math.randomseed(g_currentMission.time or os.time())
  local durationMin = math.random(minMin, maxMin)
  local durationMs = durationMin * 60 * 1000
  local startTime = g_time
  local vehName = (lockedVeh.getName and lockedVeh:getName()) or ("#" .. tostring(lockedVeh.id or "?"))

  local entryBlock = self:blockVehicleEntry(
    player,
    function(target)
      return target == lockedVeh
    end,
    function(_, target, ...)
      local remSec = math.max(0, math.ceil((startTime + durationMs - g_time) / 1000))
      FarmingLive:showFormattedWarning("@LOCKOUT_TRYENTER", 3000, playerName, remSec, vehName)
      return false
    end
  )

  self:showFormattedWarning("@LOCKOUT_BANNED", 5000, playerName, durationMin, vehName)

  local watcher = {}
  function watcher:update(dt)
    if g_time >= startTime + durationMs then
      FarmingLive:restoreVehicleEntryBlock(entryBlock)
      FarmingLive:showFormattedWarning("@LOCKOUT_FREED", 5000, playerName, nil, vehName)
      FarmingLive:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] Event Beendet")
    end
  end
  self:addUpdateable(watcher)
end
