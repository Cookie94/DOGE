local Options = 
{
    Properties = 
    {
        CancelButton = {default = EntityId()},
        SaveButton = {default = EntityId()},
        UserTextInput = {default = EntityId()},
        UserDisplayName = {default = EntityId()},
        Sliders = {EntityId(), EntityId(), EntityId()},
        Checkboxes = {EntityId(), EntityId(), EntityId(), EntityId()},
        CheckedColor = {default = Color(154/244, 199/255, 214/255)},
        UncheckedColor = {default = Color(110/255, 112/255, 113/255)},
    },
}

function Options:OnActivate()
    -- Initialize event handlers
    self.tickBusHandler = TickBus.Connect(self);

    self.cancelButtonHandler = UiButtonNotificationBus.Connect(self, self.Properties.CancelButton)
    self.saveButtonHandler = UiButtonNotificationBus.Connect(self, self.Properties.SaveButton)
    self.textInputHandler = UiTextInputNotificationBus.Connect(self, self.Properties.UserTextInput)
    self.sliderHandlers = {}
    for i = 0, #self.Properties.Sliders do
      self.sliderHandlers[i] = UiSliderNotificationBus.Connect(self, self.Properties.Sliders[i])
    end	
    self.checkboxHandlers = {}
    for i = 0, #self.Properties.Checkboxes do
      self.checkboxHandlers[i] = UiCheckboxNotificationBus.Connect(self, self.Properties.Checkboxes[i])
    end
    
    self.animationHandler = nil
end

function Options:OnTick(deltaTime, timePoint)
    self.tickBusHandler:Disconnect()

    -- Get the canvas entityId
    -- This is done after the OnActivate when the canvas is fully initialized
    self.canvasEntityId = UiElementBus.Event.GetCanvas(self.entityId)

    -- Initialize user name
    UiTextBus.Event.SetText(self.Properties.UserDisplayName, "")	

    -- Initialize slider text
    self.sliderTexts = {}
    self.sliderTextsPrefix = {}
    for i = 0, #self.Properties.Sliders do
        self.sliderTexts[i] = UiElementBus.Event.FindChildByName(self.Properties.Sliders[i], "Text")
        self.sliderTextsPrefix[i] = UiTextBus.Event.GetText(self.sliderTexts[i])
        self:SetSliderText(self.Properties.Sliders[i])
    end
    
    -- Initialize checkbox text color
    for i = 0, #self.Properties.Checkboxes do
        self:SetCheckboxTextColor(self.Properties.Checkboxes[i])
    end

    -- Start the show animation
    UiAnimationBus.Event.StartSequence(self.canvasEntityId, "Show")
end

function Options:OnButtonClick()
    if (UiAnimationBus.Event.IsSequencePlaying(self.canvasEntityId, "Hide")) then
        return
    end

    local saved = false
    if (UiButtonNotificationBus.GetCurrentBusId() == self.Properties.SaveButton) then
        saved = true
    end

    -- Send an event that the options screen is closing
    GameplayNotificationBus.Event.OnEventBegin(GameplayNotificationId(self.canvasEntityId, "OptionsClosed"), saved)
    
    -- Start the hide animation
    self.animationHandler = UiAnimationNotificationBus.Connect(self, self.canvasEntityId)
    UiAnimationBus.Event.StartSequence(self.canvasEntityId, "Hide")
end

function Options:OnSliderValueChanging(value)
    local slider = UiSliderNotificationBus.GetCurrentBusId()
    self:SetSliderText(slider)
end

function Options:OnSliderValueChanged(value)
    local slider = UiSliderNotificationBus.GetCurrentBusId()
    self:SetSliderText(slider)
end

function Options:OnCheckboxStateChange(checked)
    local checkbox = UiCheckboxNotificationBus.GetCurrentBusId()
    self:SetCheckboxTextColor(checkbox)
end

function Options:OnTextInputEndEdit(text)
    UiTextBus.Event.SetText(self.Properties.UserDisplayName, text)
end

function Options:OnUiAnimationEvent(eventType, sequenceName)
    if (eventType == eUiAnimationEvent_Stopped) then
        if (sequenceName == "Hide") then
            -- Unload this canvas
            UiCanvasManagerBus.Broadcast.UnloadCanvas(self.canvasEntityId)
        end
    end
end

function Options:OnDeactivate()
    self.cancelButtonHandler:Disconnect()
    self.saveButtonHandler:Disconnect()
    self.textInputHandler:Disconnect()
    for i = 0, #self.sliderHandlers do
      self.sliderHandlers[i]:Disconnect()
    end	
    for i = 0, #self.checkboxHandlers do
      self.checkboxHandlers[i]:Disconnect()
    end	
    self.tickBusHandler:Disconnect()
    if (self.animationHandler ~= nil) then
        self.animationHandler:Disconnect()
    end
end

function Options:SetSliderText(slider)
    -- Display the slider value
    local index = self:GetSliderIndex(slider)
    local value = UiSliderBus.Event.GetValue(slider)
    local valueText = tostring(value).format("%d", value)
    local text = self.sliderTextsPrefix[index] .. " (" .. valueText .. "%)"
    UiTextBus.Event.SetText(self.sliderTexts[index], text)
end

function Options:SetCheckboxTextColor(checkbox)
    -- Set checkbox text color based on state
    local checked = UiCheckboxBus.Event.GetState(checkbox)
    local text = UiElementBus.Event.FindChildByName(checkbox, "Text")
    
    local color = nil
    if (checked == true) then
        color = self.Properties.CheckedColor
    else
        color = self.Properties.UncheckedColor
    end	
    
    UiTextBus.Event.SetColor(text, color)
end

function Options:GetSliderIndex(slider)
    local index = 0
    for i = 0, #self.Properties.Sliders do
        if (self.Properties.Sliders[i] == slider) then
            index = i
            break
        end
    end
    
    return index
end

return Options