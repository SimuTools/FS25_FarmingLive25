FarmingLiveForbidSteerEvent = {}
local FarmingLiveForbidSteerEvent_mt = Class(FarmingLiveForbidSteerEvent, Event)

InitEventClass(FarmingLiveForbidSteerEvent, "FarmingLiveForbidSteerEvent")

function FarmingLiveForbidSteerEvent.emptyNew()
    return Event.new(FarmingLiveForbidSteerEvent_mt)
end

function FarmingLiveForbidSteerEvent.new(vehicle, playerName, options)
    local self = FarmingLiveForbidSteerEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = tostring(playerName or "")
    self.options = options or {}
    return self
end

function FarmingLiveForbidSteerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.instanceId) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.durationMs) or 0))
    streamWriteBool(streamId, self.options.forbidLeft == true)
    streamWriteString(streamId, tostring(self.options.messageMode or ""))
end

function FarmingLiveForbidSteerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.options = {
        instanceId = streamReadInt32(streamId),
        durationMs = streamReadInt32(streamId),
        forbidLeft = streamReadBool(streamId),
        messageMode = streamReadString(streamId),
        skipMessages = true
    }
    self:run(connection)
end

function FarmingLiveForbidSteerEvent:run(connection)
    if self.vehicle ~= nil and FarmingLive ~= nil and FarmingLive.forbidSteeringDirection ~= nil then
        FarmingLive:forbidSteeringDirection(self.playerName, nil, nil, self.vehicle, self.options, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveForbidSteerEvent.new(self.vehicle, self.playerName, self.options), nil, connection, self.vehicle)
    end
end

function FarmingLiveForbidSteerEvent.sendToServer(vehicle, playerName, options)
    local event = FarmingLiveForbidSteerEvent.new(vehicle, playerName, options)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
