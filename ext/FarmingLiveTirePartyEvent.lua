FarmingLiveTirePartyEvent = {}
local FarmingLiveTirePartyEvent_mt = Class(FarmingLiveTirePartyEvent, Event)

InitEventClass(FarmingLiveTirePartyEvent, "FarmingLiveTirePartyEvent")

function FarmingLiveTirePartyEvent.emptyNew()
    return Event.new(FarmingLiveTirePartyEvent_mt)
end

function FarmingLiveTirePartyEvent.new(vehicle, playerName, options)
    local self = FarmingLiveTirePartyEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = tostring(playerName or "")
    self.options = options or {}
    return self
end

function FarmingLiveTirePartyEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.instanceId) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.durationMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.minSwitchMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.maxSwitchMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.flatMessageMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.fullMessageMs) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.seed) or 0))
    streamWriteString(streamId, tostring(self.options.messageMode or ""))
end

function FarmingLiveTirePartyEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.options = {
        instanceId = streamReadInt32(streamId),
        durationMs = streamReadInt32(streamId),
        minSwitchMs = streamReadInt32(streamId),
        maxSwitchMs = streamReadInt32(streamId),
        flatMessageMs = streamReadInt32(streamId),
        fullMessageMs = streamReadInt32(streamId),
        seed = streamReadInt32(streamId),
        messageMode = streamReadString(streamId),
        skipMessages = true
    }
    self:run(connection)
end

function FarmingLiveTirePartyEvent:run(connection)
    if self.vehicle ~= nil and FarmingLive ~= nil and FarmingLive.tireBounceParty ~= nil then
        FarmingLive:tireBounceParty(self.playerName, nil, self.vehicle, self.options, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveTirePartyEvent.new(self.vehicle, self.playerName, self.options), nil, connection, self.vehicle)
    end
end

function FarmingLiveTirePartyEvent.sendToServer(vehicle, playerName, options)
    local event = FarmingLiveTirePartyEvent.new(vehicle, playerName, options)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
