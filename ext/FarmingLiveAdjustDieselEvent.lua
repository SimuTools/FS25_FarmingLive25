-- FarmingLiveAdjustDieselEvent.lua
FarmingLiveAdjustDieselEvent = {}
local FarmingLiveAdjustDieselEvent_mt = Class(FarmingLiveAdjustDieselEvent, Event)

InitEventClass(FarmingLiveAdjustDieselEvent, "FarmingLiveAdjustDieselEvent")

--- Leerer Konstruktor (für das Netzwerk)
function FarmingLiveAdjustDieselEvent:emptyNew()
    local self = Event.new(FarmingLiveAdjustDieselEvent_mt)
    return self
end

--- Wird vom Client aufgerufen, um das Event zu erstellen
-- @param vehicle Objekt des Fahrzeugs (Network‐repräsentation)
-- @param playerName Name des Spielers, der das Event ausgelöst hat
-- @param adjustment Wert, um den der Füllstand geändert wurde
function FarmingLiveAdjustDieselEvent:new(vehicle, playerName, adjustment)
    local self = FarmingLiveAdjustDieselEvent:emptyNew()
    self.vehicle = vehicle      -- NetworkNodeObject
    self.playerName = playerName
    self.adjustment = adjustment
    return self
end

--- Schreiben ins Stream (Client → Server)
function FarmingLiveAdjustDieselEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName or "")
    streamWriteInt32(streamId, self.adjustment or 0)
end

--- Lesen vom Stream (Server empfängt)
function FarmingLiveAdjustDieselEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.adjustment = streamReadInt32(streamId)
    self:run(connection)
end

--- Sobald das Event auf dem Server ankommt, wird hier der Diesel‐Füllstand angepasst
function FarmingLiveAdjustDieselEvent:run(connection)
    if connection:getIsServer() then
        if self.vehicle ~= nil and self.vehicle.spec_fillUnit then
            -- Die Logik hier nur als Beispiel; tatsächliche Anpassung läuft in main.lua
            local fillUnits = self.vehicle.spec_fillUnit.fillUnits
            local dieselFillType = g_fillTypeManager:getFillTypeIndexByName("DIESEL")
            for _, fillUnit in pairs(fillUnits) do
                if fillUnit.fillType == dieselFillType then
                    local current = fillUnit.fillLevel or 0
                    local newLevel = math.max(0, math.min(fillUnit.capacity or current, current + self.adjustment))
                    fillUnit.fillLevel = newLevel
                    FarmingLive:showWarning(
                        string.format("%s hat deinen Diesel um %d angepasst (neuer Stand: %.0f)", 
                            self.playerName, self.adjustment, newLevel),
                        5000
                    )
                    break
                end
            end
        else
            print("[FarmingLiveAdjustDieselEvent] Error: Kein gültiges Fahrzeug oder keine FillUnits.")
        end
    end
    -- Clients müssen nach dem Senden nichts weiter tun
end

--- Vom Client aufgerufen, um das Event zum Server zu schicken
-- @param vehicle Objekt des Fahrzeugs (ließ an derselben Stelle wie im Client)
-- @param playerName Name des Spielers
-- @param adjustment Wert, um den der Diesel geändert wurde
function FarmingLiveAdjustDieselEvent.sendToServer(vehicle, playerName, adjustment)
    if g_client == nil or g_client:getServerConnection() == nil then
        print("[FarmingLiveAdjustDieselEvent] Keine Serververbindung.")
        return
    end
    local event = FarmingLiveAdjustDieselEvent:new(vehicle, playerName, adjustment)
    g_client:getServerConnection():sendEvent(event)
end
