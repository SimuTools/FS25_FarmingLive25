FarmingLiveSpeedLimitBlockEvent = {}
local FarmingLiveSpeedLimitBlockEvent_mt = Class(FarmingLiveSpeedLimitBlockEvent, Event)
InitEventClass(FarmingLiveSpeedLimitBlockEvent, "FarmingLiveSpeedLimitBlockEvent")

function FarmingLiveSpeedLimitBlockEvent.emptyNew()
    return Event.new(FarmingLiveSpeedLimitBlockEvent_mt)
end

function FarmingLiveSpeedLimitBlockEvent.new(vehicle, duration, playerName)
    local self = FarmingLiveSpeedLimitBlockEvent.emptyNew()
    self.vehicle    = vehicle
    self.duration   = duration
    self.playerName = playerName
    return self
end

function FarmingLiveSpeedLimitBlockEvent:writeStream(streamId, connection)
    streamWriteInt32 (streamId, NetworkUtil.getObjectId(self.vehicle))
    streamWriteInt32 (streamId, self.duration)
    streamWriteString(streamId, self.playerName)
end

function FarmingLiveSpeedLimitBlockEvent:readStream(streamId, connection)
    self.vehicle    = NetworkUtil.getObject(streamReadInt32(streamId))
    self.duration   = streamReadInt32(streamId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

function FarmingLiveSpeedLimitBlockEvent:run(connection)
    if not self.vehicle or not self.vehicle.spec_motorized then return end
    local motor = self.vehicle.spec_motorized.motor
    if not motor then return end

    -- sofort Motor stoppen
    motor.vehicle:stopMotor(true)

    -- Start-Funktion deaktivieren
    local origStart = motor.vehicle.startMotor
    motor.vehicle.startMotor = function() return false end

    -- Unblock-Timer (Server + Client, UI nur in main.lua)
    local startTime = g_time
    local dur       = self.duration

    local unblock = {}
    function unblock:update(dt)
        if g_time >= startTime + dur then
            motor.vehicle.startMotor = origStart
            g_currentMission:removeUpdateable(self)
        end
    end

    g_currentMission:addUpdateable(unblock)
end

function FarmingLiveSpeedLimitBlockEvent.sendToServer(vehicle, duration, playerName)
    if g_client then
        local ev = FarmingLiveSpeedLimitBlockEvent.new(vehicle, duration, playerName)
        g_client:getServerConnection():sendEvent(ev)
    end
end
