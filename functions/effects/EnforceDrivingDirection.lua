function FarmingLive:enforceDrivingDirection(playerName, durationInMinutes)
  print("[FarmingLive] enforceDrivingDirection gestartet für: " .. tostring(playerName))

  local cfg = FarmingLive.config.drivingEnforce or {
    DriveDirWarnmessage  = FarmingLive.config.drivingEnforce.DriveDirWarnmessage,
    DriveDirResetmessage = FarmingLive.config.drivingEnforce.DriveDirResetmessage,
    BlockWarn            = FarmingLive.config.drivingEnforce.BlockWarn,
  }

  if not g_localPlayer then self:endActiveEvent(); return end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local v0 = getVeh()
  if not (v0 and v0.spec_motorized) then
    self:queueOrRunVehicleAction(playerName, self.enforceDrivingDirection, playerName, durationInMinutes)
    self:endActiveEvent()
    return
  end

  local totalWatch  = (tonumber(durationInMinutes) or 1) * 60 * 1000
  local introDur    = 5 * 1000
  local warnDur     = 3 * 1000
  local blockDur    = 30 * 1000
  local mustForward = math.random() > 0.5
  local dirText     = mustForward and FarmingLive.config.drivingEnforce.DriveDirForward
                                 or FarmingLive.config.drivingEnforce.DriveDirBackward
  local introMsg = FarmingLive:formatMessage(cfg.DriveDirWarnmessage, playerName, dirText, durationInMinutes)
  FarmingLive:showWarning(introMsg, introDur)

  local elapsedWatch = 0
  local wrongTimer   = 0
  local counting     = false
  local watchedVeh   = v0  

  local monitor = {}
  function monitor:update(dt)
    local nowVeh = getVeh()

    if nowVeh ~= watchedVeh then
      counting, wrongTimer = false, 0
      watchedVeh = nowVeh
    end

    elapsedWatch = elapsedWatch + dt
    if elapsedWatch >= totalWatch then
      FarmingLive:showWarning(
        FarmingLive:formatMessage(cfg.DriveDirResetmessage, playerName),
        5000
      )
      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] enforceDrivingDirection beendet (Zeit abgelaufen)")
      return
    end

    local veh = nowVeh
    if not (veh and veh.spec_motorized and veh.spec_drivable) then
      counting, wrongTimer = false, 0
      return
    end

    local motor = veh.spec_motorized.motor
    local speed = math.floor(math.max(0, veh:getLastSpeed() * veh.spec_motorized.speedDisplayScale))

    if speed > 0 then
      local isFwd = motor.vehicle:getIsDrivingForward()
      local isBwd = motor.vehicle:getIsDrivingBackward()
      local wrong = (mustForward and isBwd) or ((not mustForward) and isFwd)

      if wrong then
        if not counting then counting, wrongTimer = true, 0 end
        wrongTimer = wrongTimer + dt

        if wrongTimer >= warnDur then
          g_currentMission:removeUpdateable(self)
          FarmingLive:applyShortDirectionBlock(veh, motor, playerName, blockDur, cfg)
          print("[FarmingLive] enforceDrivingDirection -> applyShortDirectionBlock ausgelöst")
          return
        else
          local rem = math.ceil((warnDur - wrongTimer) / 1000)
          local warn = FarmingLive:formatMessage(cfg.BlockWarn, playerName, rem)
          FarmingLive:showThrottledWarning("drvDirWarn", warn, 1000, 1000)
        end
      else
        counting, wrongTimer = false, 0
      end
    else
      counting, wrongTimer = false, 0
    end
  end

  g_currentMission:addUpdateable(monitor)
end
