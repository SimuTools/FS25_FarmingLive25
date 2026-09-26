function FarmingLive:fadeScreenForDuration(durationSeconds, playerName)
    print("[FarmingLive] fadeScreenForDuration gestartet für: " .. tostring(playerName))
    local delayMS = math.random(10, 7000)

    if playerName then
        local warnText = FarmingLive:formatMessage(
            FarmingLive.config.fadeScreen.warningMessage,
            playerName,
            math.ceil(delayMS / 1000),
            nil
        )
        FarmingLive:showThrottledWarning("FadeScreen", warnText, 5000, 5000)
    end

    local fadeOutStartTime = g_time + delayMS

    local fadeOutUpdater = {}
    fadeOutUpdater.update = function(self, dt)
        if g_time >= fadeOutStartTime then

            g_currentMission:fadeScreen(1, 1000)
            g_currentMission:removeUpdateable(self)

            local blackStart = g_time + 1000                           
            local blackEnd   = g_time + 1000 + (durationSeconds * 1000) 

            if math.random() < 0.30 then
                print("[FarmingLive] FadeScreen: starte Random-Steer während Blackscreen")

                local function getVeh()
                  return FarmingLive:getCurrentVehicleOrLast()
                end

                local hookedVeh = nil
                local orig = { steer = nil }
                local inSegment = false
                local currentDir = 0
                local nextSwitchTime = blackStart
                local segmentEndTime = blackStart

                local function detach()
                    if hookedVeh and orig.steer then
                        hookedVeh.setSteeringInput = orig.steer
                        if hookedVeh.spec_drivable then
                            hookedVeh.spec_drivable.steeringInput = 0
                        end
                    end
                    hookedVeh, orig.steer = nil, nil
                end

                local function attachTo(v)
                    if not v or not v.spec_drivable then return false end
                    if hookedVeh == v then return true end
                    detach()
                    orig.steer = v.setSteeringInput
                    v.setSteeringInput = function(selfVeh, value)
                        if inSegment then
                            return orig.steer(selfVeh, currentDir)
                        end
                        return orig.steer(selfVeh, value)
                    end
                    hookedVeh = v
                    return true
                end

                local steerJammer = {}
                function steerJammer:update(dt2)
                    local now = g_time or 0

       
                    if now >= blackEnd then
                        detach()
                        g_currentMission:removeUpdateable(self)
                        return
                    end

              
                    if now < blackStart then return end

               
                    local cur = getVeh()
                    if cur ~= hookedVeh then
                        attachTo(cur)
                    end
                    if not hookedVeh then return end

                 
                    if inSegment then
                        if now >= segmentEndTime then
                            inSegment = false
                            currentDir = 0
                            nextSwitchTime = now + math.random(100, 800) 
                            if hookedVeh.spec_drivable then
                                hookedVeh.spec_drivable.steeringInput = 0
                            end
                        else
                       
                            if orig.steer then
                                orig.steer(hookedVeh, currentDir)
                            end
                            if hookedVeh.spec_drivable then
                                hookedVeh.spec_drivable.steeringInput = currentDir
                            end
                        end
                    else
                        if now >= nextSwitchTime then
                            inSegment  = true
                            local dir  = (math.random() > 0.5) and 1 or -1
                            local str  = math.random() -- 0..1
                            currentDir = dir * str
                            segmentEndTime = now + math.random(300, 1500) 
                        end
                    end
                end

            
                attachTo(getVeh())
                g_currentMission:addUpdateable(steerJammer)
            end

            local fadeInTime = g_time + 1000 + (durationSeconds * 1000)

            local fadeInUpdater = {}
            fadeInUpdater.update = function(self2, dt2)
                if g_time >= fadeInTime then
                    g_currentMission:fadeScreen(-1, 1000)
                    g_currentMission:removeUpdateable(self2)
                    FarmingLive:endActiveEvent()
                end
            end

            g_currentMission:addUpdateable(fadeInUpdater)
        end
    end

    g_currentMission:addUpdateable(fadeOutUpdater)
end
