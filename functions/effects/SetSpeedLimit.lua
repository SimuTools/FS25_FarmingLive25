function FarmingLive:setSpeedLimit(durationMinutes, desiredSpeedLimit, playerName)
  print("[FarmingLive] setSpeedLimit gestartet")
  if not g_localPlayer then FarmingLive:endActiveEvent(); return end

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local minutes = tonumber(durationMinutes) or 1
  local limit   = tonumber(desiredSpeedLimit) or 10


  local initMsg = FarmingLive:formatMessage(
    FarmingLive.config.setSpeed.warningSpeedLimit, playerName, minutes, limit
  )
  FarmingLive:showThrottledWarning("setSpeedWarningStartMSG", initMsg, 3000, 3000)

  local watchMS        = minutes * 60 * 1000
  local graceMS        = 6 * 1000
  local blockMS        = 30 * 1000
  local preCountdownMS = 10 * 1000
  local phase      = "precount"
  local preStart   = g_time or 0
  local t0         = nil
  local graceStart = nil
  local hookedVeh = nil
  local hookedMotor = nil
  local orig = { start=nil, isStarted=nil, isStopped=nil, rpm=nil, sound=nil, smoke=nil }

  local function detachBlock()
    if hookedVeh and hookedMotor then
      if orig.start     then hookedMotor.vehicle.startMotor        = orig.start     end
      if orig.isStarted then hookedMotor.vehicle.getIsMotorStarted = orig.isStarted end
      if orig.isStopped then hookedMotor.vehicle.getIsMotorStopped = orig.isStopped end
      if orig.rpm       then hookedMotor.vehicle.getMotorRpm       = orig.rpm       end
      if orig.sound     then hookedMotor.vehicle.updateSound       = orig.sound     end
      if orig.smoke     then hookedMotor.vehicle.updateSmoke       = orig.smoke     end
      if hookedVeh.spec_drivable then hookedVeh.spec_drivable.brakeInput = 0 end
    end
    hookedVeh, hookedMotor = nil, nil
    orig.start, orig.isStarted, orig.isStopped, orig.rpm, orig.sound, orig.smoke = nil, nil, nil, nil, nil, nil
  end

  local function sendMpBlockEvent(v, ms)
    if not v then return end
    if g_currentMission.missionDynamicInfo.isMultiplayer then
      FarmingLiveSpeedLimitBlockEvent.sendToServer(v, ms, playerName)
    else
      FarmingLiveSpeedLimitBlockEvent.new(v, ms, playerName):run(nil)
    end
  end

  local function attachBlockTo(v, remainingMs)
    if not (v and v.spec_motorized and v.spec_motorized.motor) then return false end
    if hookedVeh == v then return true end

    detachBlock()

    local motor = v.spec_motorized.motor
    motor.vehicle:stopMotor(true)
    if v.spec_drivable then v.spec_drivable.brakeInput = 1 end
    orig.start     = motor.vehicle.startMotor
    orig.isStarted = motor.vehicle.getIsMotorStarted
    orig.isStopped = motor.vehicle.getIsMotorStopped
    orig.rpm       = motor.vehicle.getMotorRpm
    orig.sound     = motor.vehicle.updateSound
    orig.smoke     = motor.vehicle.updateSmoke

    motor.vehicle.startMotor        = function() return false end
    motor.vehicle.getIsMotorStarted = function() return false end
    motor.vehicle.getIsMotorStopped = function() return true  end
    motor.vehicle.getMotorRpm       = function() return 0     end
    motor.vehicle.updateSound       = function() end
    motor.vehicle.updateSmoke       = function() end

    sendMpBlockEvent(v, remainingMs or blockMS)

    hookedVeh, hookedMotor = v, motor
    return true
  end


  local blockStart = nil

  local monitor = {}
  function monitor:update(dt)
    local now = g_time or 0
    if phase == "precount" then
      local elapsed = now - preStart
      if elapsed < preCountdownMS then
        local remaining = math.max(0, math.ceil((preCountdownMS - elapsed) / 1000))
        local countdownMsg = FarmingLive.config.setSpeed.warningCountdown
          and FarmingLive:formatMessage(FarmingLive.config.setSpeed.warningCountdown, remaining, limit)
          or string.format("[FarmingLive - setSpeed] In %d Sekunden beginnt die Geschwindigkeitsprüfung (Limit %d km/h).", remaining, limit)
        FarmingLive:showThrottledWarning("setSpeedPrecountMSG", countdownMsg, 1000, 1000)
        return
      else
        phase = "warn"
        t0 = now
        graceStart = nil
        return
      end
    end

    if phase == "warn" then
      if now >= t0 + watchMS then

        g_currentMission:removeUpdateable(self)
        FarmingLive:endActiveEvent()
        print("[FarmingLive] setSpeedLimit beendet (watch finished)")
        return
      end

      local veh = getVeh()
      if not (veh and veh.spec_motorized) then

        graceStart = nil
        return
      end

      if type(veh.setCruiseControlMaxSpeed) == "function" then
        veh:setCruiseControlMaxSpeed(limit + 2, limit + 2)
      end

      local kmh = math.floor(math.max(0, veh:getLastSpeed() * veh.spec_motorized.speedDisplayScale))
      if kmh == 0 or kmh > limit then
        if not graceStart then graceStart = now end
        local since = now - graceStart
        if since < graceMS then
          local left = math.ceil((graceMS - since) / 1000)
          local msg = (kmh == 0)
            and FarmingLive:formatMessage(FarmingLive.config.setSpeed.warningMotorPause, playerName, left)
            or FarmingLive:formatMessage(FarmingLive.config.setSpeed.warningMotorOverspeed, left, limit, kmh - limit)
          FarmingLive:showThrottledWarning("setSpeedWarningMSG", msg, 1000, 1000)
        else
          phase = "blocked"
          blockStart = now
          attachBlockTo(veh, blockMS)
        end
      else
        graceStart = nil
      end

      return
    end


    if phase == "blocked" then
      local elapsed = now - blockStart
      if elapsed < blockMS then

        local rem = math.ceil((blockMS - elapsed) / 1000)
        local msg = string.format("[FarmingLive - setSpeed] Motor gesperrt – noch %d Sekunden!", rem)
        FarmingLive:showThrottledWarning("setSpeedBlockedMSG", msg, 1000, 1000)


        local cur = getVeh()
        if cur ~= hookedVeh then
          attachBlockTo(cur, blockMS - elapsed)
        end
        return
      else

        detachBlock()
        local doneMsg = string.format("[FarmingLive - setSpeed] %s hat den Motor wieder freigegeben!", playerName)
        FarmingLive:showThrottledWarning("setSpeedDoneMSG", doneMsg, 5000, 5000)
        g_currentMission:removeUpdateable(self)
        FarmingLive:endActiveEvent()
        print("[FarmingLive] setSpeedLimit beendet (block finished)")
        return
      end
    end
  end

  g_currentMission:addUpdateable(monitor)
end
