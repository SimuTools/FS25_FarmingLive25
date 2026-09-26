FarmingLiveRandomSteerEvent = {}
local FarmingLiveRandomSteerEvent_mt = Class(FarmingLiveRandomSteerEvent, Event)

InitEventClass(FarmingLiveRandomSteerEvent, "FarmingLiveRandomSteerEvent")

function FarmingLiveRandomSteerEvent.emptyNew()
    return Event.new(FarmingLiveRandomSteerEvent_mt)
end

function FarmingLiveRandomSteerEvent.new(vehicle, playerName, options)
    local self = FarmingLiveRandomSteerEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = tostring(playerName or "")
    self.options = options or {}
    return self
end

function FarmingLiveRandomSteerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.instanceId) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.durationMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.seed) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.setSpeedKmh) or 0))
    streamWriteString(streamId, tostring(self.options.messageMode or ""))
end

function FarmingLiveRandomSteerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.options = {
        instanceId = streamReadInt32(streamId),
        durationMs = streamReadInt32(streamId),
        seed = streamReadInt32(streamId),
        setSpeedKmh = streamReadInt32(streamId),
        messageMode = streamReadString(streamId),
        skipMessages = true
    }
    self:run(connection)
end

function FarmingLiveRandomSteerEvent:run(connection)
    if self.vehicle ~= nil and FarmingLive ~= nil and FarmingLive.randomSteeringInterference ~= nil then
        FarmingLive:randomSteeringInterference(self.playerName, nil, nil, self.vehicle, self.options, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveRandomSteerEvent.new(self.vehicle, self.playerName, self.options), nil, connection, self.vehicle)
    end
end

function FarmingLiveRandomSteerEvent.sendToServer(vehicle, playerName, options)
    local event = FarmingLiveRandomSteerEvent.new(vehicle, playerName, options)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
