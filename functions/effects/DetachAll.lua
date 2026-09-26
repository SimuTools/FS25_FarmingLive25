function FarmingLive:detachAllImplements(vehicle, playerName)
    local rootVehicle = vehicle
    if rootVehicle == nil and g_localPlayer ~= nil then
        rootVehicle = g_localPlayer:getCurrentVehicle()
    end

    if rootVehicle == nil then
        print("[FarmingLive] detachAllImplements: Kein Fahrzeug gefunden.")
        return false
    end

    local detachedCount = 0
    local foundCount = 0

    local function getAttachedList(baseVehicle)
        if baseVehicle == nil then
            return nil
        end

        if baseVehicle.getAttachedImplements ~= nil then
            local list = baseVehicle:getAttachedImplements()
            if list ~= nil then
                return list
            end
        end

        -- Fallback, falls die Methode auf diesem Fahrzeugtyp fehlt: Spec direkt lesen
        if baseVehicle.spec_attacherJoints ~= nil then
            return baseVehicle.spec_attacherJoints.attachedImplements
        end

        return nil
    end

    local function detachOne(baseVehicle, object)
        if baseVehicle.detachImplementByObject ~= nil then
            baseVehicle:detachImplementByObject(object)
            return true
        end

        if baseVehicle.getImplementIndexByObject ~= nil and baseVehicle.detachImplement ~= nil then
            local implementIndex = baseVehicle:getImplementIndexByObject(object)
            if implementIndex ~= nil then
                baseVehicle:detachImplement(implementIndex)
                return true
            end
            print("[FarmingLive] getImplementIndexByObject lieferte keinen Index für das Anbaugerät.")
            return false
        end

        if baseVehicle.detachImplement ~= nil then
            baseVehicle:detachImplement(object)
            return true
        end

        print("[FarmingLive] Kein bekannter Detach-Aufruf auf diesem Fahrzeugtyp verfügbar.")
        return false
    end

    local function detachRecursive(baseVehicle)
        local attached = getAttachedList(baseVehicle)
        if attached == nil then
            return
        end

        for i = #attached, 1, -1 do
            local data = attached[i]
            if data ~= nil and data.object ~= nil then
                foundCount = foundCount + 1
                detachRecursive(data.object)

                if detachOne(baseVehicle, data.object) then
                    detachedCount = detachedCount + 1
                end
            end
        end
    end

    detachRecursive(rootVehicle)

    print(string.format("[FarmingLive] %s: %d/%d Anbaugerät(e) abgekoppelt.", tostring(playerName or "Unbekannt"), detachedCount, foundCount))
    return detachedCount > 0
end

function FarmingLive:detachAllImplementsFromVehicle(playerName)
    local vehicle = g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() or nil
    if vehicle == nil then
        FarmingLive:endActiveEvent()
        return
    end

    local ctx = self:getNetworkContext()
    if ctx.isMP and g_client ~= nil then
        FarmingLiveDetachImplementsEvent.sendToServer(vehicle, playerName)
    else
        self:detachAllImplements(vehicle, playerName)
    end

    FarmingLive:endActiveEvent()
end
