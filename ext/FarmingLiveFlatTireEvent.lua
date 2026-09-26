FarmingLiveFlatTireEvent = {}
local FarmingLiveFlatTireEvent_mt = Class(FarmingLiveFlatTireEvent, Event)

InitEventClass(FarmingLiveFlatTireEvent, "FarmingLiveFlatTireEvent")

function FarmingLiveFlatTireEvent.emptyNew()
    return Event.new(FarmingLiveFlatTireEvent_mt)
end

function FarmingLiveFlatTireEvent.new(vehicle, playerName, options)
    local self = FarmingLiveFlatTireEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = tostring(playerName or "")
    self.options = options or {}
    return self
end

function FarmingLiveFlatTireEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.instanceId) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.durationMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.clusterIndex) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.driftDirection) or 0))
    streamWriteFloat32(streamId, tonumber(self.options.basePull) or 0)
    streamWriteFloat32(streamId, tonumber(self.options.wobbleStrength) or 0)
    streamWriteFloat32(streamId, tonumber(self.options.forwardClamp) or 0)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.brakePulseMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.wobbleMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.tickIntervalMs) or 0))
    streamWriteString(streamId, tostring(self.options.messageMode or ""))
end

function FarmingLiveFlatTireEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.options = {
        instanceId = streamReadInt32(streamId),
        durationMs = streamReadInt32(streamId),
        clusterIndex = streamReadInt32(streamId),
        driftDirection = streamReadInt32(streamId),
        basePull = streamReadFloat32(streamId),
        wobbleStrength = streamReadFloat32(streamId),
        forwardClamp = streamReadFloat32(streamId),
        brakePulseMs = streamReadInt32(streamId),
        wobbleMs = streamReadInt32(streamId),
        tickIntervalMs = streamReadInt32(streamId),
        messageMode = streamReadString(streamId),
        skipMessages = true
    }
    self:run(connection)
end

function FarmingLiveFlatTireEvent:run(connection)
    if self.vehicle ~= nil and FarmingLive ~= nil and FarmingLive.flatTireChaos ~= nil then
        FarmingLive:flatTireChaos(self.playerName, nil, self.vehicle, self.options, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveFlatTireEvent.new(self.vehicle, self.playerName, self.options), nil, connection, self.vehicle)
    end
end

function FarmingLiveFlatTireEvent.sendToServer(vehicle, playerName, options)
    local event = FarmingLiveFlatTireEvent.new(vehicle, playerName, options)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
