-- FarmingLiveAddMoneyEvent.lua --

FarmingLiveAddMoneyEvent = {}
local FarmingLiveAddMoneyEvent_mt = Class(FarmingLiveAddMoneyEvent, Event)

InitEventClass(FarmingLiveAddMoneyEvent, "FarmingLiveAddMoneyEvent")

-- Leerer Konstruktor (für Netzwerk-Lesen)
function FarmingLiveAddMoneyEvent:emptyNew()
    local self = Event.new(FarmingLiveAddMoneyEvent_mt)
    return self
end

-- Tatsächlicher Konstruktor (CLIENT ruft das auf)
function FarmingLiveAddMoneyEvent:new(amount, farmId)
    local self = FarmingLiveAddMoneyEvent:emptyNew()
    self.amount = tonumber(amount)
    self.farmId = tonumber(farmId)
    return self
end

-- Schreiben ins Stream (Client → Server)
function FarmingLiveAddMoneyEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.amount)
    streamWriteInt32(streamId, self.farmId)
    -- Debug
    print(string.format(
        "[DEBUG] Wrote FarmingLiveAddMoneyEvent → amount=%d, farmId=%d",
        self.amount, self.farmId
    ))
end

-- Lesen aus dem Stream (Server empfängt)
function FarmingLiveAddMoneyEvent:readStream(streamId, connection)
    self.amount = streamReadInt32(streamId)
    self.farmId = streamReadInt32(streamId)
    -- Debug
    print(string.format(
        "[DEBUG] Read FarmingLiveAddMoneyEvent ← amount=%d, farmId=%d",
        self.amount, self.farmId
    ))
    self:run(connection)
end

-- Ausführen, sobald das Event auf dem SERVER ankommt
function FarmingLiveAddMoneyEvent:run(connection)
    if connection:getIsServer() then
        if FarmingLive and FarmingLive.handleAddMoneyRequest then
            print(string.format(
                "[DEBUG - Server] FarmingLiveAddMoneyEvent → farmId=%d, amount=%d",
                self.farmId, self.amount
            ))
            FarmingLive:handleAddMoneyRequest(self.amount, self.farmId)
        else
            print("[ERROR] FarmingLiveAddMoneyEvent: handleAddMoneyRequest fehlt.")
        end
    end
    -- Client tut hier nichts weiter
end

-- Hilfsfunktion, die ein CLIENT aufruft, um das Event zum SERVER zu schicken
function FarmingLiveAddMoneyEvent.sendToServer(amount, farmId)
    if g_client == nil or g_client:getServerConnection() == nil then
        print("[ERROR] FarmingLiveAddMoneyEvent.sendToServer: Keine Server-Verbindung.")
        return
    end

    local event = FarmingLiveAddMoneyEvent:new(amount, farmId)
    g_client:getServerConnection():sendEvent(event)
    print(string.format(
        "[DEBUG] FarmingLiveAddMoneyEvent.sendToServer → amount=%d, farmId=%d",
        amount, farmId
    ))
end
