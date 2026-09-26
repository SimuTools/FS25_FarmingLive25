FarmingLiveSetTimeEvent = {}
local FarmingLiveSetTimeEvent_mt = Class(FarmingLiveSetTimeEvent, Event)

InitEventClass(FarmingLiveSetTimeEvent, "FarmingLiveSetTimeEvent")

function FarmingLiveSetTimeEvent.emptyNew()
    return Event.new(FarmingLiveSetTimeEvent_mt)
end

function FarmingLiveSetTimeEvent.new(dayTime)
    local self = FarmingLiveSetTimeEvent.emptyNew()
    self.dayTime = math.max(0, tonumber(dayTime) or 0)
    return self
end

function FarmingLiveSetTimeEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, math.floor(self.dayTime))
end

function FarmingLiveSetTimeEvent:readStream(streamId, connection)
    self.dayTime = streamReadInt32(streamId)
    self:run(connection)
end

function FarmingLiveSetTimeEvent:run(connection)
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        g_currentMission.environment.dayTime = self.dayTime
    end

    if connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetTimeEvent.new(self.dayTime), nil, connection)
    end
end

function FarmingLiveSetTimeEvent.sendToServer(dayTime)
    if g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetTimeEvent.new(dayTime))
    elseif g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(FarmingLiveSetTimeEvent.new(dayTime))
    end
end
