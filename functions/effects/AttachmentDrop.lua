function FarmingLive:detachRandomImplement(vehicle, playerName)
    local rootVehicle = vehicle
    if rootVehicle == nil and g_localPlayer ~= nil then
        rootVehicle = g_localPlayer:getCurrentVehicle()
    end

    if rootVehicle == nil then
        print("[FarmingLive] detachRandomImplement: Kein Fahrzeug gefunden.")
        return false
    end

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

        if baseVehicle.spec_attacherJoints ~= nil then
            return baseVehicle.spec_attacherJoints.attachedImplements
        end

        return nil
    end

    local candidates = {}

    local function collect(baseVehicle)
        local attached = getAttachedList(baseVehicle)
        if attached == nil then
            return
        end

        for _, data in ipairs(attached) do
            if data ~= nil and data.object ~= nil then
                table.insert(candidates, { parent = baseVehicle, object = data.object })
                collect(data.object)
            end
        end
    end

    collect(rootVehicle)

    if #candidates == 0 then
        print("[FarmingLive] detachRandomImplement: Keine Anbaugeräte gefunden.")
        return false
    end

    local pick = candidates[math.random(#candidates)]
    local parent = pick.parent
    local ok = false

    if parent.detachImplementByObject ~= nil then
        parent:detachImplementByObject(pick.object)
        ok = true
    elseif parent.getImplementIndexByObject ~= nil and parent.detachImplement ~= nil then
        local implementIndex = parent:getImplementIndexByObject(pick.object)
        if implementIndex ~= nil then
            parent:detachImplement(implementIndex)
            ok = true
        else
            print("[FarmingLive] detachRandomImplement fehlgeschlagen: getImplementIndexByObject lieferte keinen Index")
        end
    elseif parent.detachImplement ~= nil then
        parent:detachImplement(pick.object)
        ok = true
    else
        print("[FarmingLive] detachRandomImplement fehlgeschlagen: Kein bekannter Detach-Aufruf auf diesem Fahrzeugtyp verfügbar")
    end

    print(string.format(
        "[FarmingLive] %s hat zufällig '%s' abgekoppelt (%s).",
        tostring(playerName or "Unbekannt"),
        (pick.object.getFullName and pick.object:getFullName()) or "Anbaugerät",
        tostring(ok)
    ))

    return ok
end

function FarmingLive:detachRandomImplementFromVehicle(playerName)
    local vehicle = g_localPlayer ~= nil and g_localPlayer:getCurrentVehicle() or nil
    if vehicle == nil then
        FarmingLive:endActiveEvent()
        return
    end

    local ctx = self:getNetworkContext()
    if ctx.isMP and g_client ~= nil then
        FarmingLiveAttachmentDropEvent.sendToServer(vehicle, playerName)
    else
        self:detachRandomImplement(vehicle, playerName)
    end

    FarmingLive:endActiveEvent()
end
