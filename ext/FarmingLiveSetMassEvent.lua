FarmingLiveSetMassEvent = {}
FarmingLiveSetMassEvent_mt = Class(FarmingLiveSetMassEvent, Event)

InitEventClass(FarmingLiveSetMassEvent, "FarmingLiveSetMassEvent")

-- Create a new empty event
function FarmingLiveSetMassEvent.emptyNew()
    local self = Event.new(FarmingLiveSetMassEvent_mt)
    return self
end

-- Create a new event with parameters
function FarmingLiveSetMassEvent.new(vehicle, playerName, newMass, duration)
    local self = FarmingLiveSetMassEvent.emptyNew()
    self.vehicle = vehicle
    self.playerName = playerName or "Unknown"  -- Default to "Unknown" if nil
    self.newMass = newMass or 0               -- Ensure mass is initialized to a number
    self.duration = duration or 0             -- Ensure duration is initialized to a number
    return self
end

-- Reading data from stream
function FarmingLiveSetMassEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.playerName = streamReadString(streamId)
    self.newMass = streamReadFloat32(streamId)
    self.duration = streamReadFloat32(streamId)
    self:run(connection)
end

-- Writing data to stream
function FarmingLiveSetMassEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteString(streamId, self.playerName)
    streamWriteFloat32(streamId, self.newMass)
    streamWriteFloat32(streamId, self.duration)
end

-- Running the event on the server or client
function FarmingLiveSetMassEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(FarmingLiveSetMassEvent.new(self.vehicle, self.playerName, self.newMass, self.duration), nil, connection, self.vehicle)
    end

    if self.vehicle then
        print(string.format("[DEBUG] Vehicle type: %s", tostring(self.vehicle)))
        
        if self.vehicle.components then
            for _, component in ipairs(self.vehicle.components) do
                if component.isDynamic then
                    component.mass = component.defaultMass + self.newMass
                    setMass(component.node, component.mass)
                end
            end

            print(string.format("Mass of vehicle %d changed by player %s to %.2f for %.2f seconds", 
                NetworkUtil.getObjectId(self.vehicle), self.playerName, self.newMass, self.duration))

            -- Setzen der originalen Masse und Rücksetz-Logik
            local originalMasses = {}
            for _, component in ipairs(self.vehicle.components) do
                originalMasses[component.node] = component.mass
            end

            local updateable = {
                timer = 0,
                duration = self.duration,
                vehicle = self.vehicle,
                update = function(self, dt)
                    self.timer = self.timer + dt
                    if self.timer >= self.duration * 1000 then
                        for _, component in ipairs(self.vehicle.components) do
                            if component.isDynamic then
                                component.mass = component.defaultMass  -- Zurücksetzen der Masse
                                setMass(component.node, component.mass)
                            end
                        end
                        print(string.format("Mass of vehicle %d reset after %.2f seconds", 
                            NetworkUtil.getObjectId(self.vehicle), self.duration))
                        g_currentMission:removeUpdateable(self)
                    end
                end
            }
            g_currentMission:addUpdateable(updateable)
        else
            print("[ERROR] Vehicle components are nil.")
        end
    else
        print("[ERROR] Vehicle is nil in FarmingLiveSetMassEvent:run()")
    end
end

-- Sending the event to the server
function FarmingLiveSetMassEvent.sendToServer(vehicle, playerName, newMass, duration)
    if g_server ~= nil then
        g_server:broadcastEvent(FarmingLiveSetMassEvent.new(vehicle, playerName, newMass, duration), nil, nil, vehicle)
    else
        g_client:getServerConnection():sendEvent(FarmingLiveSetMassEvent.new(vehicle, playerName, newMass, duration))
    end
end
