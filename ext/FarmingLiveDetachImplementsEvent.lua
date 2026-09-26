-- FarmingLiveDetachImplementsEvent.lua

FarmingLiveDetachImplementsEvent = {}
local FarmingLiveDetachImplementsEvent_mt = Class(FarmingLiveDetachImplementsEvent, Event)

InitEventClass(FarmingLiveDetachImplementsEvent, "FarmingLiveDetachImplementsEvent")

-- Leerer Konstruktor für Netzwerklesung
function FarmingLiveDetachImplementsEvent:emptyNew()
    local self = Event.new(FarmingLiveDetachImplementsEvent_mt)
    return self
end

-- „Richtiger“ Konstruktor (wird auf dem Client aufgerufen)
-- vehicle: Vehicle-Objekt, playerName: String
function FarmingLiveDetachImplementsEvent:new(vehicle, playerName)
    local self = FarmingLiveDetachImplementsEvent:emptyNew()
    self.vehicle = vehicle
    self.playerName = playerName
    return self
end

-- Schreiben ins Stream (Client → Server)
function FarmingLiveDetachImplementsEvent:writeStream(streamId, connection)
    -- FS25: vehicle mit streamWriteVehicle übertragen
    streamWriteVehicle(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName or "")
end

-- Lesen aus dem Stream (Server empfängt)
function FarmingLiveDetachImplementsEvent:readStream(streamId, connection)
    -- korrespondierende Lese­methoden
    self.vehicle = streamReadVehicle(streamId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

-- Sobald das Event beim SERVER ankommt:
function FarmingLiveDetachImplementsEvent:run(connection)
    if connection:getIsServer() then
        if FarmingLive and FarmingLive.detachAllImplements then
            print(string.format(
                "[DEBUG - Server] FarmingLiveDetachImplementsEvent: Abkuppeln angefordert für '%s' von '%s'.",
                (self.vehicle and self.vehicle:getFullName()) or "nil",
                self.playerName or "nil"
            ))
            FarmingLive:detachAllImplements(self.vehicle, self.playerName)
        else
            print("[ERROR] FarmingLiveDetachImplementsEvent: Funktion 'detachAllImplements' fehlt.")
        end
    end
    -- Auf dem Client passiert nichts weiter
end

-- Helper, den CLIENT aufrufen muss, um das Event zum SERVER zu schicken
function FarmingLiveDetachImplementsEvent.sendToServer(vehicle, playerName)
    if not g_client or not g_client:getServerConnection() then
        print("[FarmingLive - ERROR] Keine Server-Verbindung verfügbar.")
        return
    end

    local event = FarmingLiveDetachImplementsEvent:new(vehicle, playerName)
    g_client:getServerConnection():sendEvent(event)
    print(string.format(
        "[DEBUG] FarmingLiveDetachImplementsEvent.sendToServer → Fahrzeug='%s', Spieler='%s'",
        (vehicle and vehicle:getFullName()) or "nil",
        playerName or "nil"
    ))
end
