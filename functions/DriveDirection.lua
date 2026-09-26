function FarmingLive:applyShortDirectionBlock(vehicleArg, motorArg, playerName, blockDur, cfg)
  print("[FarmingLive] applyShortDirectionBlock gestartet für: " .. tostring(playerName))

  local function getVeh()
    return FarmingLive:getCurrentVehicleOrLast()
  end

  local durationMs = tonumber(blockDur) or 3000
  local startTime  = g_time or 0
  local endTime    = startTime + durationMs
  local sec = math.ceil(durationMs / 1000)
  FarmingLive:showWarning(
    string.format("[FarmingLive - DriveDir/Apply] Motor blockiert in falscher Richtung für %d Sekunden!", sec),
    5000
  )

  local hookedVeh, hookedMotor = nil, nil
  local orig = { steer=nil, accel=nil, brake=nil, startMotor=nil }

  local function attachTo(v)
    if not v or not v.spec_drivable or not v.spec_motorized or not v.spec_motorized.motor then
      return false
    end
    if hookedVeh == v then return true end
    if hookedVeh then
      if orig.startMotor then hookedMotor.vehicle.startMotor = orig.startMotor end
      if orig.steer     then hookedVeh.setSteeringInput     = orig.steer     end
      if orig.accel     then hookedVeh.setAccelerationInput = orig.accel     end
      if orig.brake     then hookedVeh.setBrakeInput        = orig.brake     end
      if hookedVeh.spec_drivable then hookedVeh.spec_drivable.brakeInput = 0 end
      hookedVeh, hookedMotor = nil, nil
      orig.steer, orig.accel, orig.brake, orig.startMotor = nil, nil, nil, nil
    end

    local motor = v.spec_motorized.motor
    motor.vehicle:stopMotor(true)
    if v.spec_drivable then v.spec_drivable.brakeInput = 1 end
    orig.steer      = v.setSteeringInput
    orig.accel      = v.setAccelerationInput
    orig.brake      = v.setBrakeInput
    orig.startMotor = motor.vehicle.startMotor
    v.setSteeringInput     = function() end
    v.setAccelerationInput = function() end
    v.setBrakeInput        = function(selfVeh)
      if selfVeh.spec_drivable then selfVeh.spec_drivable.brakeInput = 1 end
    end
    motor.vehicle.startMotor = function() return false end

    hookedVeh, hookedMotor = v, motor
    if g_currentMission.missionDynamicInfo.isMultiplayer then
      FarmingLiveDriveDirBlockEvent.sendToServer(v, durationMs, playerName)
    end

    return true
  end

  local function detachCurrent()
    if hookedVeh then
      if orig.startMotor then hookedMotor.vehicle.startMotor = orig.startMotor end
      if orig.steer     then hookedVeh.setSteeringInput     = orig.steer     end
      if orig.accel     then hookedVeh.setAccelerationInput = orig.accel     end
      if orig.brake     then hookedVeh.setBrakeInput        = orig.brake     end
      if hookedVeh.spec_drivable then hookedVeh.spec_drivable.brakeInput = 0 end
    end
    hookedVeh, hookedMotor = nil, nil
    orig.steer, orig.accel, orig.brake, orig.startMotor = nil, nil, nil, nil
  end

  local v0 = getVeh() or vehicleArg
  if not attachTo(v0) then
    print("[FarmingLive] applyShortDirectionBlock: kein drivable Vehicle gefunden.")
  end

  local elapsedBlock = 0
  local updater = {}
  function updater:update(dt)
    local now = g_time or 0
    elapsedBlock = elapsedBlock + dt

    -- Ende?
    if now >= endTime then
      detachCurrent()
      local doneMsg = FarmingLive:formatMessage(FarmingLive.config.drivingEnforce.DriveDirResetmessage, playerName)
      FarmingLive:showWarning(doneMsg, 5000)
      g_currentMission:removeUpdateable(self)
      FarmingLive:endActiveEvent()
      print("[FarmingLive] Event Beendet")
      return
    end

    local remaining = math.max(0, endTime - now)
    local remSec = math.ceil(remaining / 1000)
    local warn = FarmingLive:formatMessage(cfg.BlockWarn, playerName, remSec)
    FarmingLive:showThrottledWarning("drvDirBlock", warn, 1000, 1000)
    local cur = getVeh()
    if cur ~= hookedVeh then
      attachTo(cur)
    end
  end

  g_currentMission:addUpdateable(updater)
end
