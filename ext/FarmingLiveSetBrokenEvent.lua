FarmingLiveSetBrokenEvent = {}
local FarmingLiveSetBrokenEvent_mt = Class(FarmingLiveSetBrokenEvent, Event)

InitEventClass(FarmingLiveSetBrokenEvent, "FarmingLiveSetBrokenEvent")

function FarmingLiveSetBrokenEvent.emptyNew()
    return Event.new(FarmingLiveSetBrokenEvent_mt)
end

function FarmingLiveSetBrokenEvent.new(vehicle, damageAmount)
    local self = FarmingLiveSetBrokenEvent.emptyNew()
    self.vehicle = vehicle
    self.damageAmount = math.max(0, tonumber(damageAmount) or 0)
    return self
end

function FarmingLiveSetBrokenEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteFloat32(streamId, self.damageAmount)
end

function FarmingLiveSetBrokenEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.damageAmount = streamReadFloat32(streamId)
    self:run(connection)
end

function FarmingLiveSetBrokenEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle.addDamageAmount ~= nil then
        self.vehicle:addDamageAmount(self.damageAmount, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetBrokenEvent.new(self.vehicle, self.damageAmount), nil, connection, self.vehicle)
    end
end

function FarmingLiveSetBrokenEvent.sendToServer(vehicle, damageAmount)
    if g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetBrokenEvent.new(vehicle, damageAmount), nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(FarmingLiveSetBrokenEvent.new(vehicle, damageAmount))
    end
end
