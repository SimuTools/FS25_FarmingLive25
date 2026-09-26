function FarmingLive:disableTabForVehicles(durationInMinutes, playerName)
print("[FarmingLive] disableTabForVehicles wurde gestartet für: " .. tostring(playerName))  
 local nonTabbableVehicles = {}


    for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
        if vehicle.setIsTabbable then
            vehicle:setIsTabbable(false)
            table.insert(nonTabbableVehicles, vehicle)
        end
    end

    local startTime   = g_time
    local restoreTime = durationInMinutes * 60 * 1000

   
    local tabCheckUpdateable = {}
    function tabCheckUpdateable:update(dt)

        local remainingMs = (startTime + restoreTime) - g_time
        if remainingMs > 0 and Input.isKeyPressed(Input.KEY_tab) then
            local remainingMins = math.ceil(remainingMs / 60000)
            local warn = FarmingLive:formatMessage(
                FarmingLive.config.blockTab.trytab,
                playerName,
                remainingMins
            )
            FarmingLive:showWarning(warn, 7000)
        end
    end
    g_currentMission:addUpdateable(tabCheckUpdateable)


    local restoreTabbableUpdateable = {}
    function restoreTabbableUpdateable:update(dt)
        if g_time >= startTime + restoreTime then
   
            for _, vehicle in ipairs(nonTabbableVehicles) do
                if vehicle.setIsTabbable then
                    vehicle:setIsTabbable(true)
                end
            end

  
            g_currentMission:removeUpdateable(self)
    
            g_currentMission:removeUpdateable(tabCheckUpdateable)
	FarmingLive:endActiveEvent()
	print("[FarmingLive] Event Beendet")
    
            local msg = FarmingLive:formatMessage(
                FarmingLive.config.blockTab.unblockmessage,
                playerName
            )
            FarmingLive:showWarning(msg, 7000)
            print("[FarmingLive - disableTab] Alle Fahrzeuge sind nun wieder tabbar.")
        end
    end
    g_currentMission:addUpdateable(restoreTabbableUpdateable)


    local blockMsg = FarmingLive:formatMessage(
        FarmingLive.config.blockTab.blockmessage,
        playerName,
        durationInMinutes
    )
    FarmingLive:showWarning(blockMsg, 7000)
end
