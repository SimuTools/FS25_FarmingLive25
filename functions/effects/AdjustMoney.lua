function FarmingLive:adjustMoney(playerName)
print("[FarmingLive] adjustMoney wurde gestartet für: " .. tostring(playerName))
   local randomAmount = math.random(
        FarmingLive.config.adjustMoney.MIN_VALUE,
        FarmingLive.config.adjustMoney.MAX_VALUE
    )

    local farmId = self:getLocalFarmId()
    if not farmId or farmId < 0 then
        print("[FarmingLive] Ungültige farmId – breche adjustMoney ab.")
        self:endActiveEvent()
        return
    end

    local message = (randomAmount >= 0)
        and FarmingLive.config.adjustMoney.positiveMessage
        or FarmingLive.config.adjustMoney.negativeMessage

    if g_currentMission:getIsServer() then
        print(string.format(
            "[FarmingLive - SERVER] Direktes Anpassen → farmId=%d, amount=%d",
            farmId, randomAmount
        ))
        FarmingLive:handleAddMoneyRequest(randomAmount, farmId)
        self:showFormattedWarning(message, 5000, playerName, randomAmount)
        self:endActiveEvent()
        return
    end

    print(string.format(
        "[FarmingLive - CLIENT] Sende AdjustMoneyEvent → farmId=%d, amount=%d",
        farmId, randomAmount
    ))
    if FarmingLiveAddMoneyEvent then
        FarmingLiveAddMoneyEvent.sendToServer(randomAmount, farmId)
    else
        print("[FarmingLive] FarmingLiveAddMoneyEvent nicht geladen.")
    end
    self:showFormattedWarning(message, 5000, playerName, randomAmount)
    self:endActiveEvent()
end

function FarmingLive:handleAddMoneyRequest(amount, farmId)
    if not g_currentMission:getIsServer() then
        return
    end

    if farmId == nil or farmId < 0 then
        print("[FarmingLive] Ungültige farmId in handleAddMoneyRequest – Abbruch.")
        return
    end

    print(string.format(
        "[FarmingLive - SERVER] Passe Geld an → farmId=%d, amount=%d",
        farmId, amount
    ))

    local success = g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, true, true)
end

function Utils:debugTable(table)
    DebugUtil.printTableRecursively(table, "_", 0, 1)
end
