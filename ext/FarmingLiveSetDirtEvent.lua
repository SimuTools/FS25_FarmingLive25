FarmingLiveSetDirtEvent = {}
local FarmingLiveSetDirtEvent_mt = Class(FarmingLiveSetDirtEvent, Event)

InitEventClass(FarmingLiveSetDirtEvent, "FarmingLiveSetDirtEvent")

function FarmingLiveSetDirtEvent.emptyNew()
    return Event.new(FarmingLiveSetDirtEvent_mt)
end

function FarmingLiveSetDirtEvent.new(vehicle, dirtAmount)
    local self = FarmingLiveSetDirtEvent.emptyNew()
    self.vehicle = vehicle
    self.dirtAmount = tonumber(dirtAmount) or 0
    return self
end

function FarmingLiveSetDirtEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteFloat32(streamId, self.dirtAmount)
end

function FarmingLiveSetDirtEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.dirtAmount = streamReadFloat32(streamId)
    self:run(connection)
end

function FarmingLiveSetDirtEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle.setDirtAmount ~= nil then
        self.vehicle:setDirtAmount(self.dirtAmount)
    elseif self.vehicle ~= nil and self.vehicle.addDirtAmount ~= nil and self.vehicle.getDirtAmount ~= nil then
        local currentDirt = self.vehicle:getDirtAmount()
        self.vehicle:addDirtAmount(self.dirtAmount - currentDirt)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetDirtEvent.new(self.vehicle, self.dirtAmount), nil, connection, self.vehicle)
    end
end

function FarmingLiveSetDirtEvent.sendToServer(vehicle, dirtAmount)
    if g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetDirtEvent.new(vehicle, dirtAmount), nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(FarmingLiveSetDirtEvent.new(vehicle, dirtAmount))
    end
end
