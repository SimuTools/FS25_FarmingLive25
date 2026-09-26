function FarmingLive:lockInteriorCamera(playerName, durationMinutes)
  print("[FarmingLive] lockInteriorCamera gestartet für: " .. tostring(playerName))
  if not g_localPlayer then self:endActiveEvent(); return end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local function findInsideIndex(v)
    local spec = v and v.spec_enterable
    if not spec or type(spec.cameras) ~= "table" then return nil end
    for idx, cam in ipairs(spec.cameras) do
      if cam.isInside then return idx end
    end
    return nil
  end

  local durationMS = math.max(1, tonumber(durationMinutes) or 1) * 60 * 1000
  local startTime  = g_time or 0
  local endTime    = startTime + durationMS

  local warnedOnce     = false
  local lockedVehicle  = nil
  local insideIdxCache = {}   

  local function primeVehicle(v)
    if not v then return false end
    local idx = insideIdxCache[v]
    if not idx then
      idx = findInsideIndex(v)
      if not idx then return false end
      insideIdxCache[v] = idx
    end

    if not warnedOnce then
      warnedOnce = true
      FarmingLive:showWarning(
        FarmingLive:formatMessage(FarmingLive.config.lockInteriorCamera.IntoriorCamWarnMessage, playerName, durationMinutes),
        5000
      )
	  
    end

    local spec = v.spec_enterable
    if spec and spec.isEntered then
      v:setActiveCameraIndex(idx)
      lockedVehicle = v
      return true
    end
    return false
  end

  primeVehicle(getVeh())

  local watcher = {}
  function watcher:update(dt)
    local now = g_time or 0

    if now >= endTime then
      FarmingLive:showWarning(
        FarmingLive:formatMessage(FarmingLive.config.lockInteriorCamera.IntoriorCamUnblockMessage, playerName),
        5000
      )
      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] lockInteriorCamera beendet")
      return
    end

    local cur = getVeh()
    if cur ~= lockedVehicle then
      primeVehicle(cur)
    end

    if cur then
      local spec = cur.spec_enterable
      local idx  = insideIdxCache[cur]
      if spec and spec.isEntered and idx then
        local cams = spec.cameras
        local needSet = true
        if type(cur.getActiveCameraIndex) == "function" then
          local activeIdx = cur:getActiveCameraIndex()
          if activeIdx == idx then
            needSet = false
          end
        elseif cams and cams[idx] and cams[idx].isActive then
          needSet = false
        end

        if needSet then
          FarmingLive:showThrottledWarning(
          "lockCamCountdown",
          FarmingLive:formatMessage(FarmingLive.config.lockInteriorCamera.IntoriorCamBlockMessage, math.max(0, math.ceil((endTime - now)/1000))), 
          1000, 1000
        )
          -- FarmingLive:showWarning(
            -- FarmingLive:formatMessage(FarmingLive.config.lockInteriorCamera.IntoriorCamBlockMessage, math.max(0, math.ceil((endTime - now)/1000))),
            -- 1000
          -- )
          cur:setActiveCameraIndex(idx)
        end
      end
    end
  end

  g_currentMission:addUpdateable(watcher)
end
