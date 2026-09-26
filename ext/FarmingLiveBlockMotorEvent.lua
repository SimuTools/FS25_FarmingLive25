FarmingLiveBlockMotorEvent = {}
local mt = Class(FarmingLiveBlockMotorEvent, Event)
InitEventClass(FarmingLiveBlockMotorEvent, "FarmingLiveBlockMotorEvent")

function FarmingLiveBlockMotorEvent.emptyNew()
    return Event.new(mt)
end

function FarmingLiveBlockMotorEvent.new(vehicle, duration)
    local self = FarmingLiveBlockMotorEvent.emptyNew()
    self.vehicle  = vehicle
    self.duration = duration
    return self
end

function FarmingLiveBlockMotorEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle))
    streamWriteInt32(streamId, self.duration)
end

function FarmingLiveBlockMotorEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId)
    self.vehicle  = NetworkUtil.getObject(id)
    self.duration = streamReadInt32(streamId)
    self:run(connection)
end

function FarmingLiveBlockMotorEvent:run(connection)
    -- nur auf Server/Host ausführen
    if not g_currentMission:getIsServer() then return end
    if not self.vehicle or not self.vehicle.spec_motorized then return end

    local motor      = self.vehicle.spec_motorized.motor
    local blockMS    = self.duration
    local blockStart = g_time

    -- 1) Motor sofort stoppen
    motor.vehicle:stopMotor(true)

    -- 2) Override startMotor
    local origStart = motor.vehicle.startMotor
    motor.vehicle.startMotor = function() return false end

    -- 3) Unblock-Timer auf Server (rein physisch)
    local unblock = {}
    function unblock:update(dt)
        if g_time >= blockStart + blockMS then
            motor.vehicle.startMotor = origStart
            g_currentMission:removeUpdateable(self)
        end
    end
    g_currentMission:addUpdateable(unblock)
end

function FarmingLiveBlockMotorEvent.sendToServer(vehicle, duration)
    if g_client then
        local ev = FarmingLiveBlockMotorEvent.new(vehicle, duration)
        g_client:getServerConnection():sendEvent(ev)
    end
end
