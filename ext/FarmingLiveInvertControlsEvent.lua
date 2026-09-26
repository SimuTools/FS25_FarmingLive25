FarmingLiveInvertControlsEvent = {}
local FarmingLiveInvertControlsEvent_mt = Class(FarmingLiveInvertControlsEvent, Event)

InitEventClass(FarmingLiveInvertControlsEvent, "FarmingLiveInvertControlsEvent")

function FarmingLiveInvertControlsEvent.emptyNew()
    return Event.new(FarmingLiveInvertControlsEvent_mt)
end

function FarmingLiveInvertControlsEvent.new(vehicle, playerName, options)
    local self = FarmingLiveInvertControlsEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = tostring(playerName or "")
    self.options = options or {}
    return self
end

function FarmingLiveInvertControlsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteInt32(streamId, math.floor(tonumber(self.options.instanceId) or 0))
    streamWriteInt32(streamId, math.floor(tonumber(self.options.durationMs) or 0))
    streamWriteString(streamId, tostring(self.options.messageMode or ""))
end

function FarmingLiveInvertControlsEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.options = {
        instanceId = streamReadInt32(streamId),
        durationMs = streamReadInt32(streamId),
        messageMode = streamReadString(streamId),
        skipMessages = true
    }
    self:run(connection)
end

function FarmingLiveInvertControlsEvent:run(connection)
    if self.vehicle ~= nil and FarmingLive ~= nil and FarmingLive.invertControls ~= nil then
        FarmingLive:invertControls(self.playerName, nil, nil, self.vehicle, self.options, true)
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveInvertControlsEvent.new(self.vehicle, self.playerName, self.options), nil, connection, self.vehicle)
    end
end

function FarmingLiveInvertControlsEvent.sendToServer(vehicle, playerName, options)
    local event = FarmingLiveInvertControlsEvent.new(vehicle, playerName, options)
    if g_server ~= nil then
        g_server:broadcastEvent(event, nil, nil, vehicle)
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(event)
    end
end
