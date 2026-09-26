-- FarmingLiveLaunchVehicleEvent.lua
FarmingLiveLaunchVehicleEvent = {}
FarmingLiveLaunchVehicleEvent_mt = Class(FarmingLiveLaunchVehicleEvent, Event)

InitEventClass(FarmingLiveLaunchVehicleEvent, "FarmingLiveLaunchVehicleEvent")

function FarmingLiveLaunchVehicleEvent:emptyNew()
    local self = Event.new(FarmingLiveLaunchVehicleEvent_mt)
    return self
end

function FarmingLiveLaunchVehicleEvent.sendToServer(vehicle, upImpulse, forwardImpulse, playerName)
    local event = FarmingLiveLaunchVehicleEvent:new(vehicle, upImpulse, forwardImpulse, playerName)
    if g_server == nil then
       
        g_client:getServerConnection():sendEvent(event)
    else
	
        g_currentMission:sendEvent(event)
    end
end


function FarmingLiveLaunchVehicleEvent:new(vehicle, upImpulse, forwardImpulse, playerName)
    local self = FarmingLiveLaunchVehicleEvent:emptyNew()
    self.vehicle        = vehicle
    self.upImpulse      = upImpulse
    self.forwardImpulse = forwardImpulse
    self.playerName     = playerName
    return self
end

function FarmingLiveLaunchVehicleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteFloat32(streamId, self.upImpulse)
    streamWriteFloat32(streamId, self.forwardImpulse)
    streamWriteString(streamId, self.playerName)
end

function FarmingLiveLaunchVehicleEvent:readStream(streamId, connection)
    self.vehicle        = NetworkUtil.readNodeObject(streamId)
    self.upImpulse      = streamReadFloat32(streamId)
    self.forwardImpulse = streamReadFloat32(streamId)
    self.playerName     = streamReadString(streamId)
    self:run(connection)
end

function FarmingLiveLaunchVehicleEvent:run(connection)
    if not g_currentMission:getIsServer() then
        return
    end

    local node = self.vehicle.rootNode
    local vx, vy, vz = getLinearVelocity(node)
    local cx, cy, cz = getWorldTranslation(node)
    local wx, wy, wz = localToWorld(node, 0, 0, 1)
    local dx, dy, dz = wx - cx, wy - cy, wz - cz
    local len = math.sqrt(dx*dx + dy*dy + dz*dz)
    if len > 1e-4 then dx, dy, dz = dx/len, dy/len, dz/len end

    local newVx = vx + dx * self.forwardImpulse
    local newVy = vy + self.upImpulse
    local newVz = vz + dz * self.forwardImpulse
    setLinearVelocity(node, newVx, newVy, newVz)

    -- Warnung an **alle** Clients schicken
    FarmingLive:showWarning(
        FarmingLive:formatMessage(FarmingLive.config.launchVehicle.LaunchVehicleWarnMessage, self.playerName),
        5000
    )
end
