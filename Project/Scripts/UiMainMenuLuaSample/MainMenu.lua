local MainMenu = 
{
    Properties =
    {
        Fader = {default = EntityId()},
        Message = {default = EntityId()},
    },
}

function MainMenu:OnActivate()
    self.tickBusHandler = TickBus.Connect(self);

    self.canvasNotificationHandler = nil
    self.faderNotificationHandler = nil
    self.optionsClosedHandler = nil
end

function MainMenu:OnTick(deltaTime, timePoint)
    self.tickBusHandler:Disconnect()

    -- Get the canvas entityId
    -- This is done after the OnActivae when the canvas is fully initialized
    self.canvasEntityId = UiElementBus.Event.GetCanvas(self.entityId)

    -- Listen for action strings broadcast by the canvas
    self.canvasNotificationHandler = UiCanvasNotificationBus.Connect(self, self.canvasEntityId)
    
    -- Hide the message text
    UiFaderBus.Event.SetFadeValue(self.Properties.Message, 0)	
    
    -- Display the mouse cursor
    LyShineLua.ShowMouseCursor(true)	
end

function MainMenu:OnAction(entityId, actionName)
    Debug.Log(tostring(entityId) .. ": " .. actionName)

    -- Don't do anything during a fade
    if UiFaderBus.Event.IsFading(self.Properties.Fader) == true then
        return
    end

    if actionName == "PlayGame" then
        -- Listen for fader events
        self.faderNotificationHandler = UiFaderNotificationBus.Connect(self, self.Properties.Fader)
        
        -- Start the fade
        UiFaderBus.Event.Fade(self.Properties.Fader, 0, 1)
    
        -- Entering "gameplay", so hide the cursor
        LyShineLua.ShowMouseCursor(false)
    elseif actionName == "ShowOptions" then
        -- Load the options canvas
        local optionsCanvasEntityId = UiCanvasManagerBus.Broadcast.LoadCanvas("UI/Canvases/UiMainMenuLuaSample/Options.uicanvas")
        
        -- Listen for an options closed event
        self.optionsClosedEventId = GameplayNotificationId()
        self.optionsClosedEventId.actionNameCrc = Crc32("OptionsClosed")
        self.optionsClosedEventId.channel = optionsCanvasEntityId
        self.optionsClosedHandler = GameplayNotificationBus.Connect(self, self.optionsClosedEventId)
    end
end

function MainMenu:OnEventBegin(value)
    if (GameplayNotificationBus.GetCurrentBusId() == self.optionsClosedEventId) then
        if (value == true) then
            -- Display message
            UiAnimationBus.Event.StartSequence(self.canvasEntityId, "ShowMessage")
        end
        self.optionsClosedHandler:Disconnect()
    end
end

function MainMenu:OnFadeComplete()
    self.faderNotificationHandler:Disconnect()

    -- Send an event to start the game
    GameplayNotificationBus.Event.OnEventBegin(GameplayNotificationId(self.canvasEntityId, "StartGame"), 0)
end

function MainMenu:OnDeactivate()
    if (self.canvasNotificationHandler ~= nil) then
        self.canvasNotificationHandler:Disconnect()
    end
    if (self.faderNotificationHandler ~= nil) then
        self.faderNotificationHandler:Disconnect()
    end
    if (self.optionsClosedHandler ~= nil) then
        self.optionsClosedHandler:Disconnect()
    end
    self.tickBusHandler:Disconnect()
end

return MainMenu
