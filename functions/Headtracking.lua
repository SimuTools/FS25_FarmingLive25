function FarmingLive:setHeadtrackingEnabled(enabled)
    if g_gameSettings == nil or g_gameSettings.getValue == nil or g_gameSettings.setValue == nil then
        print("[FarmingLive] setHeadtrackingEnabled: g_gameSettings nicht verfügbar")
        return
    end

    if not FarmingLive._hasSavedHeadSetting then
        FarmingLive._origHeadSetting     = g_gameSettings:getValue("isHeadTrackingEnabled")
        FarmingLive._hasSavedHeadSetting = true
        print(string.format(
            "[FarmingLive] Ursprungs-Headtracking-Einstellung gemerkt: %s",
            tostring(FarmingLive._origHeadSetting)
        ))
    end

    g_gameSettings:setValue("isHeadTrackingEnabled", enabled, false)
    print(string.format(
        "[FarmingLive] Headtracking gesetzt auf: %s",
        tostring(enabled)
    ))
end

function FarmingLive:restoreHeadtracking()
    if not FarmingLive._hasSavedHeadSetting or
       g_gameSettings == nil or g_gameSettings.setValue == nil then
        return
    end

    g_gameSettings:setValue("isHeadTrackingEnabled", FarmingLive._origHeadSetting, true)
    print(string.format(
        "[FarmingLive] Ursprungs-Headtracking-Einstellung wiederhergestellt: %s",
        tostring(FarmingLive._origHeadSetting)
    ))

    FarmingLive._hasSavedHeadSetting = false
    FarmingLive._origHeadSetting     = nil
end
