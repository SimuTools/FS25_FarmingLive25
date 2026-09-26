-- FarmingLiveAttachmentDropEvent.lua

FarmingLiveAttachmentDropEvent = {}
local FarmingLiveAttachmentDropEvent_mt = Class(FarmingLiveAttachmentDropEvent, Event)

InitEventClass(FarmingLiveAttachmentDropEvent, "FarmingLiveAttachmentDropEvent")

-- Leerer Konstruktor für Netzwerklesung
function FarmingLiveAttachmentDropEvent:emptyNew()
    local self = Event.new(FarmingLiveAttachmentDropEvent_mt)
    return self
end

-- „Richtiger" Konstruktor (wird auf dem Client aufgerufen)
-- vehicle: Vehicle-Objekt, playerName: String
function FarmingLiveAttachmentDropEvent:new(vehicle, playerName)
    local self = FarmingLiveAttachmentDropEvent:emptyNew()
    self.vehicle = vehicle
    self.playerName = playerName
    return self
end

-- Schreiben ins Stream (Client → Server)
function FarmingLiveAttachmentDropEvent:writeStream(streamId, connection)
    streamWriteVehicle(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName or "")
end

-- Lesen aus dem Stream (Server empfängt)
function FarmingLiveAttachmentDropEvent:readStream(streamId, connection)
    self.vehicle = streamReadVehicle(streamId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

-- Sobald das Event beim SERVER ankommt:
function FarmingLiveAttachmentDropEvent:run(connection)
    if connection:getIsServer() then
        if FarmingLive and FarmingLive.detachRandomImplement then
            print(string.format(
                "[DEBUG - Server] FarmingLiveAttachmentDropEvent: Zufälliges Abkuppeln angefordert für '%s' von '%s'.",
                (self.vehicle and self.vehicle:getFullName()) or "nil",
                self.playerName or "nil"
            ))
            FarmingLive:detachRandomImplement(self.vehicle, self.playerName)
        else
            print("[ERROR] FarmingLiveAttachmentDropEvent: Funktion 'detachRandomImplement' fehlt.")
        end
    end
    -- Auf dem Client passiert nichts weiter
end

-- Helper, den CLIENT aufrufen muss, um das Event zum SERVER zu schicken
function FarmingLiveAttachmentDropEvent.sendToServer(vehicle, playerName)
    if not g_client or not g_client:getServerConnection() then
        print("[FarmingLive - ERROR] Keine Server-Verbindung verfügbar.")
        return
    end

    local event = FarmingLiveAttachmentDropEvent:new(vehicle, playerName)
    g_client:getServerConnection():sendEvent(event)
    print(string.format(
        "[DEBUG] FarmingLiveAttachmentDropEvent.sendToServer → Fahrzeug='%s', Spieler='%s'",
        (vehicle and vehicle:getFullName()) or "nil",
        playerName or "nil"
    ))
end
