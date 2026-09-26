FarmingLiveClearFuelEvent = {}
FarmingLiveClearFuelEvent_mt = Class(FarmingLiveClearFuelEvent, Event)

InitEventClass(FarmingLiveClearFuelEvent, "FarmingLiveClearFuelEvent")

function FarmingLiveClearFuelEvent.new(vehicle, playerName)
    local self = FarmingLiveClearFuelEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = playerName or "Unknown"
    return self
end

function FarmingLiveClearFuelEvent.emptyNew()
    local self = Event.new(FarmingLiveClearFuelEvent_mt)
    return self
end

function FarmingLiveClearFuelEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self:run(connection)
end

function FarmingLiveClearFuelEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
end

function FarmingLiveClearFuelEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(FarmingLiveClearFuelEvent.new(self.vehicle, self.playerName), nil, connection, self.vehicle)
    end

    if self.vehicle then
        -- Nur Diesel und DEF leeren
        if self.vehicle.emptyAllFillUnits then
            self.vehicle:emptyAllFillUnits(true) -- Diese Methode leert den gesamten Füllstand

            -- Debugging-Output
            local vehicleName = self.vehicle:getFullName()

            print(string.format("Fuel cleared for vehicle %d by player %s", NetworkUtil.getObjectId(self.vehicle), self.playerName))
        else
            print("[ERROR] Fahrzeug kann den Treibstoff nicht leeren.")
        end
    else
        print("[ERROR] Kein Fahrzeug gefunden, um den Treibstoff zu leeren.")
    end
end

function FarmingLiveClearFuelEvent.sendToServer(vehicle, playerName)
    if g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveClearFuelEvent.new(vehicle, playerName), nil, nil, vehicle)
    else
        g_client:getServerConnection():sendEvent(FarmingLiveClearFuelEvent.new(vehicle, playerName))
    end
end