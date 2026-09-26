function FarmingLive:temporarilyIncreaseMass(playerName, additionalMass)
  print("[FarmingLive] temporarilyIncreaseMass gestartet für: " .. tostring(playerName))
  if not g_localPlayer then
    print("[FarmingLive - SetMass] Kein lokaler Spieler gefunden.")
    FarmingLive:endActiveEvent()
    return
  end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local duration  = 30000
  local startTime = g_time or 0
  local addMass   = tonumber(additionalMass) or 0
  if addMass == 0 then
    FarmingLive:endActiveEvent()
    return
  end

  local touched = {} 
  local currentVeh = nil

  local function hasComponents(v)
    return v and type(v.components) == "table" and #v.components > 0
  end

  local function applyTo(v)
    if not hasComponents(v) then return false end

    if not touched[v] then
      local originals = {}
      for _, comp in ipairs(v.components) do
        originals[comp.node] = comp.mass
      end
      touched[v] = { originalMasses = originals, compsRef = v.components }
    end

    local comps    = v.components
    local n        = #comps
    local addPer   = (n > 0) and (addMass / n) or 0
    v.serverMass   = 0

    for _, comp in ipairs(comps) do
      if comp.defaultMass == nil then
        if comp.isDynamic then
          comp.defaultMass = getMass(comp.node)
        else
          comp.defaultMass = 1
        end
      end
      comp.mass = comp.defaultMass + addPer
      v.serverMass = v.serverMass + comp.mass
    end

    for _, comp in ipairs(comps) do
      if v.isServer and comp.isDynamic then
        setMass(comp.node, comp.mass)
        comp.lastMass = comp.mass
      end
    end

    local vehicleName = v:getFullName()
    local msg = FarmingLive:formatMessage(FarmingLive.config.tempMass.message, playerName, nil, vehicleName)
    FarmingLive:showThrottledWarning("setMass", msg, 5000, 5000)

    if FarmingLiveSetMassEvent then
      FarmingLiveSetMassEvent.sendToServer(v, playerName, addMass, (startTime + duration - (g_time or 0)) / 1000)
    end

    currentVeh = v
    return true
  end

  local function restoreVehicle(v)
    local t = v and touched[v]
    if not t or not hasComponents(v) then return end
    v.serverMass = 0
    for _, comp in ipairs(v.components) do
      local orig = t.originalMasses[comp.node]
      comp.mass = orig or comp.defaultMass or comp.mass
      if v.isServer and comp.isDynamic then
        setMass(comp.node, comp.mass)
        comp.lastMass = comp.mass
      end
      v.serverMass = v.serverMass + comp.mass
    end
  end

  local function detachCurrent()
    if currentVeh then
      restoreVehicle(currentVeh)
    end
    currentVeh = nil
  end

  local v0 = getVeh()
  if v0 then
    applyTo(v0)
  else
    print("[FarmingLive - SetMass] Kein aktuelles/letztes Vehicle – warte auf Einstieg.")
  end

  local massUpdateable = {}
  function massUpdateable:update(dt)
    local now = g_time or 0


    if now >= startTime + duration then

      if currentVeh then restoreVehicle(currentVeh) end
      for v, _ in pairs(touched) do
        if v ~= currentVeh then restoreVehicle(v) end
      end
      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print(string.format("[FarmingLive - SetMass] Mass reset for player: %s", tostring(playerName)))
      return
    end

    local cur = getVeh()
    if cur ~= currentVeh then
      detachCurrent()
      if cur then applyTo(cur) end
    end
  end

  g_currentMission:addUpdateable(massUpdateable)
end
