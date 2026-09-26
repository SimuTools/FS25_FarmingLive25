function FarmingLive:cameraFun(playerName, durationInMinutes)
  print("[FarmingLive] cameraFun gestartet für:", playerName)
  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local vehicle = getVeh()
  if not vehicle or not (vehicle.spec_motorized and vehicle.spec_motorized.motor) then
    FarmingLive:queueOrRunVehicleAction(playerName, FarmingLive.cameraFun, playerName, durationInMinutes)
    FarmingLive:restoreHeadtracking()
    FarmingLive:endActiveEvent()
    return
  end

  local warningDelay   = 10 * 1000
  local randomMinutes  = math.max(1, math.random(1, durationInMinutes or 1))
  local randomDuration = randomMinutes * 60 * 1000
  local tStart         = (g_time or 0) + warningDelay
  local tEnd           = tStart + randomDuration

  local zoomMin    = tonumber(FarmingLive.config.cameraFun.ZoomMin) or 0
  local zoomMax    = tonumber(FarmingLive.config.cameraFun.ZoomMax) or zoomMin
  local randomZoom = math.random(math.min(zoomMin, zoomMax), math.max(zoomMin, zoomMax))
  local useZoom    = (tostring(FarmingLive.config.cameraFun.UseZoom) == "True")

  local blocked        = false
  local lockedVehicle  = nil  

  local function lockCam(v)
    if not v or not v.rootVehicle then return end
    local cam = v.rootVehicle:getActiveCamera()
    if not cam then return end
    FarmingLive:setHeadtrackingEnabled(false)
    cam.isRotatable = false
    if useZoom then
      cam.zoom = cam.isInside and (randomZoom / 2) or randomZoom
    end
    lockedVehicle = v
  end

  local function unlockCam(v)
    if not v or not v.rootVehicle then return end
    local cam = v.rootVehicle:getActiveCamera()
    if cam then cam.isRotatable = true end
    FarmingLive:restoreHeadtracking()
    if lockedVehicle == v then lockedVehicle = nil end
  end

  local updater = {}
  function updater:update(dt)
    local now = g_time or 0
    local currentVeh = getVeh()
    if now < tStart then
      local sec = math.ceil((tStart - now) / 1000)
      FarmingLive:showThrottledWarning(
        "cameraFunWarnMessage",
        FarmingLive:formatMessage(FarmingLive.config.cameraFun.WarnMessage, playerName, sec),
        1000, 1000
      )
      return
    end

    if now < tEnd then
      if not blocked then
        blocked = true
        FarmingLive:showThrottledWarning(
          "cameraFunBlockMessage",
          FarmingLive:formatMessage(FarmingLive.config.cameraFun.cameraBlocked, playerName, randomMinutes),
          7000, 7000
        )
        if currentVeh then lockCam(currentVeh) end
      else
        if currentVeh ~= lockedVehicle then
          if lockedVehicle then unlockCam(lockedVehicle) end
          if currentVeh then lockCam(currentVeh) end
        else
          if currentVeh and useZoom then
            local cam = currentVeh.rootVehicle and currentVeh.rootVehicle:getActiveCamera()
            if cam then cam.zoom = cam.isInside and (randomZoom / 2) or randomZoom end
          end
        end
      end
      return
    end

    if lockedVehicle then unlockCam(lockedVehicle) end
    if currentVeh and currentVeh ~= lockedVehicle then unlockCam(currentVeh) end

    FarmingLive:showThrottledWarning(
      "cameraFunUnblockMessage",
      FarmingLive:formatMessage(FarmingLive.config.cameraFun.cameraUnblocked, playerName),
      7000, 7000
    )

    g_currentMission:removeUpdateable(self)
    FarmingLive:endActiveEvent()
  end

  g_currentMission:addUpdateable(updater)
end
