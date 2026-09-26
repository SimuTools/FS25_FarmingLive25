FarmingLiveEventDialog = {}
local FarmingLiveEventDialog_mt = Class(FarmingLiveEventDialog, YesNoDialog)

local function flDlgDbg(fmt, ...)
    if not (FarmingLive ~= nil and FarmingLive.debugEventMenu) then return end
    print(string.format("[FarmingLive][EventMenu] " .. tostring(fmt), ...))
end

function FarmingLiveEventDialog.new(target, customMt)
    local self = YesNoDialog.new(target, customMt or FarmingLiveEventDialog_mt)
    self.eventNames = {}
    return self
end

function FarmingLiveEventDialog.register(modDir)
    if g_gui == nil then
        flDlgDbg("register aborted: g_gui=nil")
        return false
    end

    local path = Utils.getFilename("gui/FarmingLiveEventDialog.xml", modDir or g_currentModDirectory or "")
    if not fileExists(path) then
        print("[FarmingLive] ERROR Dialog xml missing: " .. tostring(path))
        return false
    end

    local dlg = FarmingLiveEventDialog.new()
    g_gui:loadGui(path, "FarmingLiveEventDialog", dlg)

    FarmingLiveEventDialog.INSTANCE = dlg
    flDlgDbg("dialog registered")
    return true
end

function FarmingLiveEventDialog.show()
    if g_gui == nil then
        return false
    end

    g_gui:showDialog("FarmingLiveEventDialog")

    return true
end

function FarmingLiveEventDialog:onCreate()
    if self.yesButton ~= nil then
        self.yesButton.onClickCallback = self.onClickOk
        self.yesButton.target = self
    end

    if self.noButton ~= nil then
        self.noButton.onClickCallback = self.onClickBack
        self.noButton.target = self
    end
end

function FarmingLiveEventDialog:onOpen()
    FarmingLiveEventDialog:superClass().onOpen(self)

    if g_inputBinding ~= nil and g_inputBinding.setShowMouseCursor ~= nil then
        g_inputBinding:setShowMouseCursor(true)
    end

    if self.dialogTitleElement ~= nil then
        self.dialogTitleElement:setText("FarmingLive")
    end

    if self.yesButton ~= nil then
        self.yesButton:setText(g_i18n:getText("button_ok"))
    end

    if self.noButton ~= nil then
        self.noButton:setText(g_i18n:getText("button_back"))
    end

    self:updateEventList()
end

function FarmingLiveEventDialog:onClose()
    if g_inputBinding ~= nil and g_inputBinding.setShowMouseCursor ~= nil then
        g_inputBinding:setShowMouseCursor(false)
    end

    FarmingLiveEventDialog:superClass().onClose(self)
end

function FarmingLiveEventDialog:getEventLabel(name)
    return FarmingLive:traw("EVENTLABEL_" .. name) or name
end

function FarmingLiveEventDialog:buildSortedEventNames()
    local names = {}

    for name, _ in pairs(FarmingLive.commandHandlers or {}) do
        local meta = (FarmingLive.commandMeta or {})[name] or {}
        local disabled = FarmingLive.disabledCommands and FarmingLive.disabledCommands[name]
        if not disabled and not meta.hiddenFromMenu then
            table.insert(names, name)
        end
    end

    table.sort(names, function(a, b)
        return self:getEventLabel(a) < self:getEventLabel(b)
    end)

    return names
end

function FarmingLiveEventDialog:updateEventList()
    self.eventNames = self:buildSortedEventNames()

    local labels = {}
    for _, name in ipairs(self.eventNames) do
        table.insert(labels, self:getEventLabel(name))
    end

    if #labels == 0 then
        labels = { FarmingLive:traw("EVENTMENU_NO_EVENTS") or "-- keine Events --" }
    end

    if self.eventOptionElement ~= nil then
        self.eventOptionElement:setTexts(labels)
        self.eventOptionElement:setState(1)
    end

    if self.hintTextElement ~= nil then
        self.hintTextElement:setText(FarmingLive:traw("EVENTMENU_HINT") or "Event auswählen und mit OK auslösen.")
    end
end

function FarmingLiveEventDialog:safeClose()
    if FocusManager ~= nil and FocusManager.unsetFocus ~= nil then
        if self.eventOptionElement ~= nil then FocusManager:unsetFocus(self.eventOptionElement) end
        if self.yesButton ~= nil then FocusManager:unsetFocus(self.yesButton) end
        if self.noButton ~= nil then FocusManager:unsetFocus(self.noButton) end
    end

    self:close()
end

function FarmingLiveEventDialog:onClickOk()
    local index = self.eventOptionElement ~= nil and self.eventOptionElement:getState() or nil
    local name = index ~= nil and self.eventNames[index] or nil

    flDlgDbg("onClickOk index=%s name=%s", tostring(index), tostring(name))

    self:safeClose()

    if name ~= nil then
        FarmingLive:dispatchCommand(name, "Player")
    end
end

function FarmingLiveEventDialog:onClickBack()
    self:safeClose()
end
