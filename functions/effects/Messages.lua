local function flCollectPipeMessages(raw)
    local messages = {}
    for part in string.gmatch(tostring(raw or ""), "([^|]+)") do
        local trimmed = tostring(part):gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            table.insert(messages, trimmed)
        end
    end
    return messages
end

local function flResolveConfiguredMode(mode)
    local normalized = tostring(mode or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if normalized == "" or normalized == "default" or normalized == "global" or normalized == "inherit" then
        return nil
    end
    return mode
end

local function flShowConfiguredMessage(message, duration, mode)
    if message == nil or message == "" then
        return
    end
    FarmingLive:showWarning(message, duration, flResolveConfiguredMode(mode))
end

function FarmingLive:showHi(playerName)
    local messages = flCollectPipeMessages(FarmingLive.config.showHi.warningMessage)
    local choice = messages[math.random(1, math.max(1, #messages))] or tostring(FarmingLive.config.showHi.warningMessage or "")
    local formatted = FarmingLive:formatMessage(choice, playerName)
    flShowConfiguredMessage(formatted, FarmingLive.config.showHi.duration, FarmingLive.config.showHi.messageMode)
end

function FarmingLive:showUser(playerName)
    local messages = {
        FarmingLive.config.showUser.warningMessage,
        FarmingLive.config.showUser.warningMessage2,
        FarmingLive.config.showUser.warningMessage3,
        FarmingLive.config.showUser.warningMessage4,
        FarmingLive.config.showUser.warningMessage5
    }

    local randomIndex = math.random(1, #messages)
    local randomMessage = messages[randomIndex]
    local formatted = FarmingLive:formatMessage(randomMessage, playerName, nil, nil)

    flShowConfiguredMessage(formatted, FarmingLive.config.showUser.duration, FarmingLive.config.showUser.messageMode)
end

function FarmingLive:showSimu(playerName)
    local messages = {
"Mein Schöpfer hat mich gesandt, um dich zu begrüßen – halte dich bereit für eine Portion blinkende Aufmerksamkeit!",
"Im Namen meines Schöpfers heiße ich dich willkommen – möge dein Display in freudigem Glanz erstrahlen!",
"Laut Weisung meines Schöpfers empfange ich dich mit blinkender Begeisterung – willkommen!",
"Auf Geheiß meines Schöpfers zünde ich das Licht der Begrüßung – möge dein Besuch erhellend sein!",
"Mein Schöpfer begrüßt dich mit blinkender Erleuchtung – tritt ein in die Welt des Wahnsinns!",
"Durch den Willen meines Schöpfers beginnt dein Besuch mit flackernder Freude – willkommen an Bord!"
    }

    local randomIndex = math.random(1, #messages)
    local randomMessage = messages[randomIndex]
    local formatted = FarmingLive:formatMessage(randomMessage, playerName, nil, nil)

    flShowConfiguredMessage(formatted, FarmingLive.config.showSimu.duration, FarmingLive.config.showSimu.messageMode)
end
