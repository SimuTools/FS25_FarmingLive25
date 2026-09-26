function FarmingLive:registerEventMenuGui()
    if self._flEventMenuGuiRegistered then
        return
    end

    if FarmingLiveEventDialog == nil or FarmingLiveEventDialog.register == nil then
        print("[FarmingLive] EventMenu: FarmingLiveEventDialog nicht geladen.")
        return
    end

    self._flEventMenuGuiRegistered = FarmingLiveEventDialog.register(self.modDir)
end

function FarmingLive:isEventMenuKeyPressed()
    if Input == nil or Input.isKeyPressed == nil or Input.KEY_0 == nil then
        return false
    end

    return Input.isKeyPressed(Input.KEY_0) == true
end

function FarmingLive:checkEventMenuHotkey()
    local isPressed = self:isEventMenuKeyPressed()

    if isPressed and not self._flEventMenuKeyWasPressed then
        self:onOpenEventMenu()
    end

    self._flEventMenuKeyWasPressed = isPressed
end

function FarmingLive:onOpenEventMenu()
    if g_currentMission == nil or g_currentMission.isPlayerFrozen then
        return
    end

    if g_gui == nil or g_gui:getIsGuiVisible() then
        return
    end

    if not self._flEventMenuGuiRegistered then
        print("[FarmingLive] Event-Menü ist noch nicht bereit.")
        return
    end

    FarmingLiveEventDialog.show()
end
