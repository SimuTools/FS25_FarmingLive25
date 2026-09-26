function FarmingLive:randomCameraEvent(playerName)
  print("[FarmingLive] randomCameraEvent gestartet")
  if not g_localPlayer then self:endActiveEvent(); return end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local warnDelayMS = 1000
  local tStart = (g_time or 0) + warnDelayMS
  local didAction = false

  local updater = {}
  function updater:update(dt)
    local now = g_time or 0

    if not didAction and now < tStart then
      self._rcWarnTick = (self._rcWarnTick or 0) + dt
      if self._rcWarnTick >= 500 then
        self._rcWarnTick = 0
        local sec = math.ceil((tStart - now) / 1000)
        FarmingLive:showThrottledWarning(
          "randomCamWarn",
          FarmingLive:formatMessage("@RANDOMCAM_WARN", playerName, sec), 
          1000, 1000
        )
      end
      return
    end

    if not didAction then
      didAction = true
      local vehicle = getVeh()
      if not vehicle then
        print("[FarmingLive] randomCameraEvent: kein aktuelles/letztes Vehicle gefunden.")
        g_currentMission:removeUpdateable(self)
        FarmingLive:endActiveEvent()
        FarmingLive:restoreHeadtracking()
        return
      end

      local spec = vehicle.spec_enterable
      if not spec or type(spec.cameras) ~= "table" or #spec.cameras < 1 then
        g_currentMission:removeUpdateable(self)
        FarmingLive:endActiveEvent()
        FarmingLive:restoreHeadtracking()
        return
      end

      local currNode = g_localPlayer:getCurrentCameraNode()
      local activeIdx = 1
      for i, cam in ipairs(spec.cameras) do
        if (cam.cameraNode or cam.rootNode) == currNode then
          activeIdx = i
          break
        end
      end

      if #spec.cameras >= 2 and math.random() < 0.5 then
        local nextIdx = (activeIdx % #spec.cameras) + 1
        vehicle:setActiveCameraIndex(nextIdx)

        local formattedText = FarmingLive:formatMessage(
          "@RANDOMCAM_SWITCHCAM",              -- %p=%Spieler, %d=Index, %s=Max
          playerName, nextIdx, #spec.cameras
        )
        FarmingLive:showWarning(formattedText, 5000)
      else
        FarmingLive:setHeadtrackingEnabled(false)

        local camDef = spec.cameras[activeIdx]
        if camDef then
          camDef.origRotY = camDef.origRotY or (camDef.rotY or 0)
          local baseYaw = camDef.origRotY
          local delta   = (math.random() * 2 - 1) * math.pi
          camDef.rotY   = baseYaw + delta

          FarmingLive:showWarning(
            FarmingLive:formatMessage("@RANDOMCAM_ROTATE", playerName, math.deg(delta)), -- %p, %d(oder %s) je nach Text
            5000
          )
        end

        local restoreTick = {}
        function restoreTick:update(dt2)
          FarmingLive:restoreHeadtracking()
          g_currentMission:removeUpdateable(self)
        end
        g_currentMission:addUpdateable(restoreTick)
      end

      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] randomCameraEvent beendet")
    end
  end

  g_currentMission:addUpdateable(updater)
end
