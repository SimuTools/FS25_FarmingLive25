function FarmingLive:setRandomTime(playerName, timeOverride, fromNetwork)
print("[FarmingLive] setRandomTime wurde gestartet für: " .. tostring(playerName))
    if not g_currentMission then
        FarmingLive:endActiveEvent()
        return
    end

    local randomTime = tonumber(timeOverride)
    if randomTime == nil then
        randomTime = math.random(0, 86400000)
    end

    local isServer = g_currentMission:getIsServer()
    local isMp = g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer == true

    g_currentMission.environment.dayTime = randomTime

    if isMp and not isServer and not fromNetwork then
        FarmingLiveSetTimeEvent.sendToServer(randomTime)
    end

    local totalMinutes = math.floor(randomTime / (60 * 1000))
    local hours = math.floor(totalMinutes / 60)
    local minutes = totalMinutes % 60
    local formattedTime = string.format("%02d:%02d", hours, minutes)

    FarmingLive:showWarning(FarmingLive:formatMessage(FarmingLive.config.setTime.message, playerName, formattedTime, nil), 7000)
    FarmingLive:endActiveEvent()
end
