FarmingLiveDriveDirBlockEvent = {}
local mt = Class(FarmingLiveDriveDirBlockEvent, Event)
InitEventClass(FarmingLiveDriveDirBlockEvent, "FarmingLiveDriveDirBlockEvent")

function FarmingLiveDriveDirBlockEvent.emptyNew()
    return Event.new(mt)
end

-- Konstruktor: vehicle, duration, playerName
function FarmingLiveDriveDirBlockEvent.new(vehicle, duration, playerName)
    local self = FarmingLiveDriveDirBlockEvent.emptyNew()
    self.vehicle    = vehicle
    self.duration   = duration
    self.playerName = playerName
    return self
end

function FarmingLiveDriveDirBlockEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, NetworkUtil.getObjectId(self.vehicle))
    streamWriteInt32(streamId, self.duration)
    streamWriteString(streamId, self.playerName)
end

function FarmingLiveDriveDirBlockEvent:readStream(streamId, connection)
    local objectId = streamReadInt32(streamId)
    self.vehicle    = NetworkUtil.getObject(objectId)
    self.duration   = streamReadInt32(streamId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

function FarmingLiveDriveDirBlockEvent:run(connection)
    -- nur auf Server/Host physisch blocken, ohne UI
    if not g_currentMission:getIsServer() then return end
    if not (self.vehicle and self.vehicle.spec_motorized) then return end

    local motor   = self.vehicle.spec_motorized.motor
    local blockMs = self.duration
    local start   = g_time

    -- 1) Motor stoppen
    motor.vehicle:stopMotor(true)

    -- 2) Override startMotor
    local origStart = motor.vehicle.startMotor
    motor.vehicle.startMotor = function() return false end

    -- 3) Nach Ablauf wiederherstellen
    local unblock = {}
    function unblock:update(dt)
        if g_time >= start + blockMs then
            motor.vehicle.startMotor = origStart
            g_currentMission:removeUpdateable(self)
        end
    end
    g_currentMission:addUpdateable(unblock)
end

function FarmingLiveDriveDirBlockEvent.sendToServer(vehicle, duration, playerName)
    if g_client then
        local ev = FarmingLiveDriveDirBlockEvent.new(vehicle, duration, playerName)
        g_client:getServerConnection():sendEvent(ev)
    end
end
