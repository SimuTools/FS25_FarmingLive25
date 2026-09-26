FarmingLiveLockDoorEvent = {}
local mt = Class(FarmingLiveLockDoorEvent, Event)
InitEventClass(FarmingLiveLockDoorEvent, "FarmingLiveLockDoorEvent")

function FarmingLiveLockDoorEvent.emptyNew()
    return Event.new(mt)
end

function FarmingLiveLockDoorEvent.new(vehicle, playerName)
    local self = FarmingLiveLockDoorEvent.emptyNew()
    self.vehicle    = vehicle
    self.playerName = playerName
    return self
end

-- Server schreibt: Vehicle (ObjectId) + PlayerName
function FarmingLiveLockDoorEvent:writeStream(streamId, connection)
    -- robuster als Int32 direkt
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.vehicle) or 0)
    streamWriteString(streamId, tostring(self.playerName or ""))
end

-- Client liest und führt aus
function FarmingLiveLockDoorEvent:readStream(streamId, connection)
    local nodeId = NetworkUtil.readNodeObjectId(streamId)
    self.vehicle    = NetworkUtil.getObject(nodeId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

function FarmingLiveLockDoorEvent:run(connection)
    if g_currentMission:getIsServer() then
        -- === SERVER: Physisch stoppen + kurzzeitiges Startverbot, dann Broadcast an andere Clients ===
        if self.vehicle ~= nil and self.vehicle.spec_motorized ~= nil then
            local motor = self.vehicle.spec_motorized.motor

            -- Sofort stoppen & Start verhindern
            motor.vehicle:stopMotor(true)
            local origStart = motor.vehicle.startMotor
            motor.vehicle.startMotor = function() return false end

            -- Nach 5s wieder freigeben
            local start  = g_time
            local blockMs = 5000
            local unblock = {}
            function unblock:update(dt)
                if g_time >= start + blockMs then
                    motor.vehicle.startMotor = origStart
                    g_currentMission:removeUpdateable(self) -- self == unblock (Closure)
                end
            end
            g_currentMission:addUpdateable(unblock)
        end

        -- Nur an **andere** Clients senden (kein Echo an Auslöser):
        -- 2. Arg (noEventSend) = nil/false, 3. Arg = connection (wird NICHT erneut informiert),
        -- 4. Arg = vehicle für Object-Relevanz
        g_server:broadcastEvent(
            FarmingLiveLockDoorEvent.new(self.vehicle, self.playerName),
            nil, connection, self.vehicle
        )
    else
        -- === CLIENT: rein lokaler UI/Control-Lock (KEIN Re-Send!) ===
        if self.vehicle ~= nil then
            -- angepasste Funktion akzeptiert (vehicle, playerName)
            FarmingLive:blockMotorAndLockVehicle(self.vehicle, self.playerName)
        else
            -- Falls Objekt noch nicht synchronisiert ist: defensiv nichts tun
            print("[FarmingLive] LockDoorEvent: vehicle nil (noch nicht synchronisiert?) – überspringe lokalen Lock.")
        end
    end
end

function FarmingLiveLockDoorEvent.sendToServer(vehicle, playerName)
    if g_client then
        local ev = FarmingLiveLockDoorEvent.new(vehicle, playerName)
        g_client:getServerConnection():sendEvent(ev)
    end
end
