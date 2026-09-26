function FarmingLive:triggerHonkForDuration(playerName, duration)
print("[FarmingLive] triggerHonkForDuration wurde gestartet für: " .. tostring(playerName))        
   local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle == nil then
        self:queueOrRunVehicleAction(playerName, self.triggerHonkForDuration, playerName, duration)
		FarmingLive:endActiveEvent()
        return
    end

    local spec = vehicle.spec_honk

   
    if spec == nil then
        print("[FarmingLive - triggerHonk] Vehicle has no honk specification.")
		FarmingLive:endActiveEvent()
        return
    end
    
    local honkDuration = 3000 
    local pauseDuration = 500  
    local honkUpdateable = {}
    local totalTime = 0  
    local honking = false 

	FarmingLive:showWarning(FarmingLive:formatMessage(FarmingLive.config.triggerHonk.warnmessage, playerName, nil, nil), 7000)

    honkUpdateable.update = function(self, dt)
        totalTime = totalTime + dt 
        
        if totalTime < duration then
            if honking then
 
                if totalTime % (honkDuration + pauseDuration) < honkDuration then
                    vehicle:playHonk(true) 
                else
                    vehicle:playHonk(false) 
                end
            else
  
                if totalTime % (honkDuration + pauseDuration) >= honkDuration then
                    vehicle:playHonk(false) 
                end
            end

           
            if totalTime % (honkDuration + pauseDuration) < honkDuration then
                honking = true
            else
                honking = false
            end
        else
            vehicle:playHonk(false) 
            g_currentMission:removeUpdateable(self)  
            print(string.format("[FarmingLive - triggerHonk] Honk stopped after %d seconds for player: %s", totalTime / 1000, playerName))
			FarmingLive:endActiveEvent()
	   end
    end

  
    g_currentMission:addUpdateable(honkUpdateable)

    print(string.format("[FarmingLive - triggerHonk] Honking for %d seconds for player: %s", duration / 1000, playerName))
end
