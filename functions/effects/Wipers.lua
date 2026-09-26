function FarmingLive:toggleWipers(playerName, durationMinutes)
  print("[FarmingLive] toggleWipers gestartet für: " .. tostring(playerName))
  if not g_localPlayer then self:endActiveEvent(); return end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local durationMS = (durationMinutes or 1) * 60 * 1000
  local startTime  = g_time or 0
  local endTime    = startTime + durationMS

  local warnedOnce = false
  local touchedVehicles = {} 
  local activeVehicle = nil
  local activeSpec = nil
  local directions = {}

  local function hasWipers(v)
    return v and v.spec_wipers and v.spec_wipers.hasWipers and v.spec_wipers.wipers
  end

  local function attachTo(v)
    activeVehicle = v
    activeSpec    = v.spec_wipers
    directions    = {}
    for _, w in pairs(activeSpec.wipers) do
      if w.animName and w.animDuration then
        directions[w.animName] = 1
      end
    end
    touchedVehicles[v] = true
  end

  local function detachFrom(v)
    if not v or not hasWipers(v) then return end
    if type(v.wiperDeactivate) == "function" then
      v:wiperDeactivate()
    elseif type(v.setWiperState) == "function" then
      v:setWiperState(false)
    end
    for _, w in pairs(v.spec_wipers.wipers) do
      if w.animName then
        v:setAnimationTime(w.animName, 0)
      end
    end
  end

  local function showStartOnce()
    if warnedOnce then return end
    warnedOnce = true
    FarmingLive:showWarning(
      FarmingLive:formatMessage(FarmingLive.config.toggleWipers.TOGWipersWarnmessage, playerName, durationMinutes),
      5000
    )
    if math.random() < 0.5 then
      FarmingLive:lockInteriorCamera(playerName, durationMinutes)
    end
  end

  local v0 = getVeh()
  if not hasWipers(v0) then
    print("[FarmingLive] toggleWipers: aktuelles/letztes Vehicle ohne Wischer – warte auf Wechsel.")
  else
    attachTo(v0)
    showStartOnce()
  end

  local wiperUpdater = {}
  function wiperUpdater:update(dt)
    local now = g_time or 0
    if now >= endTime then
      for v,_ in pairs(touchedVehicles) do
        detachFrom(v)
      end
      FarmingLive:showWarning(
        FarmingLive:formatMessage(FarmingLive.config.toggleWipers.TOGWipersDeaktivatemessage, playerName),
        5000
      )
      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] toggleWipers beendet")
      return
    end
    local cur = getVeh()
    if cur ~= activeVehicle then
      if hasWipers(cur) then
        attachTo(cur)
        showStartOnce()
      else
        activeVehicle, activeSpec = nil, nil
      end
    end

    if not activeVehicle or not activeSpec then return end
    for _, w in pairs(activeSpec.wipers) do
      if w.animName and w.animDuration then
        local anim = w.animName
        local dur  = w.animDuration
        local curT = activeVehicle:getAnimationTime(anim) or 0
        local dir  = directions[anim] or 1
        local nxt  = curT + dir * (dt / dur)
        if nxt >= 1 then
          nxt = 1; directions[anim] = -1
        elseif nxt <= 0 then
          nxt = 0; directions[anim] = 1
        end
        activeVehicle:setAnimationTime(anim, nxt)
      end
    end
    if type(activeVehicle.setWiperState) == "function" then
      activeVehicle:setWiperState(true)
    elseif type(activeVehicle.wiperActivate) == "function" then
      activeVehicle:wiperActivate()
    end
  end

  g_currentMission:addUpdateable(wiperUpdater)
end
