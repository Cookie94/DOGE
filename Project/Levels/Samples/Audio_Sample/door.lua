----------------------------------------------------------------------------------------------------
--
-- All or portions of this file Copyright (c) Amazon.com, Inc. or its affiliates or
-- its licensors.
--
-- For complete copyright and license terms please see the LICENSE at the root of this
-- distribution (the "License"). All use of this software is governed by the License,
-- or, if provided, by the license below or the license accompanying this file. Do not
-- remove or modify any license notices. This file is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--
--
----------------------------------------------------------------------------------------------------
local door = 
{
    Properties = 
    {
        SwingSpeed = {default = 60.0, description = "Door swing speed", suffix = " degrees/second"},
    },
	EventCallbacks = 
	{
		Open = {},
		Close = {},
		Toggle = {},
		Swing = {},
		SwingOpen = {},
		SwingClosed = {},
	},
	Handlers =
	{
	},
}

function door:OnActivate()
	-- Attach to input event buses
	self.Handlers.Open = InputEventNotificationBus.Connect(self.EventCallbacks.Open, InputEventNotificationId("Open"));
	self.EventCallbacks.Open.root = self;

	self.Handlers.Close = InputEventNotificationBus.Connect(self.EventCallbacks.Close, InputEventNotificationId("Close"));
	self.EventCallbacks.Close.root = self;

	self.Handlers.Toggle = InputEventNotificationBus.Connect(self.EventCallbacks.Toggle, InputEventNotificationId("Toggle"));
	self.EventCallbacks.Toggle.root = self;

	self.Handlers.Swing = InputEventNotificationBus.Connect(self.EventCallbacks.Swing, InputEventNotificationId("Swing"));
	self.EventCallbacks.Swing.root = self;

	self.Handlers.SwingOpen = InputEventNotificationBus.Connect(self.EventCallbacks.SwingOpen, InputEventNotificationId("Swing Open"));
	self.EventCallbacks.SwingOpen.root = self;

	self.Handlers.SwingClosed = InputEventNotificationBus.Connect(self.EventCallbacks.SwingClosed, InputEventNotificationId("Swing Closed"));
	self.EventCallbacks.SwingClosed.root = self;

	-- Setup door state
	self.opened = Math.DegToRad(90.0); -- Door opened angle
	self.closed = 0.0;
	self.target = self.closed;
	self.current = self.closed;
	self.baseSpeed = Math.DegToRad(self.Properties.SwingSpeed);
	self.speed = 0;
	self.swinging = false;
	
	-- Initialize the audio triggers
	self.KnobSound = "Play_door_open";
	self.CreakSound = "Play_door_creak";
	self.CreakSoundStop = "Stop_door_creak";
	self.CreakVolume = "CreakVolume";
	self.CreakPitch = "CreakPitch";
	self.SlamSound = "Play_door_shut";
end

function door:ConnectToTickBus()
-- When the door needs to open or close, connect to the tickbus
	self.TickBusHandler = TickBus.Connect(self);
end

function door:TryOpenDoorSound()
-- Check if the door is first being opened to play a door knob open sound
	if self.current <= self.closed then
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.KnobSound);
	end
end

function door:CanSwing(inputValue)
-- Check to see if the door can swing open or closed
	if inputValue > 0 and self.current < self.opened then
		return true;
	elseif inputValue < 0 and self.current > self.closed then
		return true;
	end
	return false;
end

function door.EventCallbacks.Open:OnPressed(inputValue)
-- Triggers on "Open" event from door.inputbindings

	-- Set target to opened
	if self.root.current < self.root.opened then
		self.root.target = self.root.opened;
		self.root.speed = self.root.baseSpeed;
		
		self.root:TryOpenDoorSound();
 		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
		
		self.root:ConnectToTickBus();
	end
end

function door.EventCallbacks.Close:OnPressed(inputValue)
-- Triggers on "Close" event from door.inputbindings

	-- Set target to closed
	if self.root.current > self.root.closed then
		self.root.target = self.root.closed;
		self.root.speed = -self.root.baseSpeed;
	
 		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
		
		self.root:ConnectToTickBus();
	end
end	

function door.EventCallbacks.Toggle:OnPressed(inputValue)
-- Triggers on "Toggle" event from door.inputbindings

	-- Set target to open if target is closed or closed if target is open
	if self.root.target == self.root.opened then
		self.root.target = self.root.closed;
		self.root.speed = -self.root.baseSpeed;
	elseif self.root.target == self.root.closed then 
		self.root.target = self.root.opened; 
		self.root.speed = self.root.baseSpeed;
	end
	
	self.root:TryOpenDoorSound();
 	AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
	AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
	
	self.root:ConnectToTickBus();
end

function door.EventCallbacks.Swing:OnPressed(inputValue)
-- Triggers on "Swing" event from door.inputbindings

	-- When you start swinging, initialize some audio
	if not self.root.swinging and self.root:CanSwing(inputValue) then 
		self.root:TryOpenDoorSound();
 		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
		self.root.swinging = true;
		self.root:ConnectToTickBus();
	end

	-- Set target to open if input is positive or closed if target is negative
	if inputValue > 0 then 
		self.root.target = self.root.opened;
	elseif inputValue < 0 then 
		self.root.target = self.root.closed;
	end
	self.root.speed = self.root.baseSpeed * inputValue;
end

function door.EventCallbacks.Swing:OnHeld(inputValue)
-- Triggers on "Swing" event from door.inputbindings being held

	-- Set target to open when input is positive or closed when input is negative
	if inputValue > 0 then
		self.root.target = self.root.opened;
	elseif inputValue < 0 then
		self.root.target = self.root.closed;
	end
	self.root.speed = self.root.baseSpeed * inputValue;
end

function door.EventCallbacks.Swing:OnReleased(floatValue)
-- Triggers when "Swing" event from door.inputbindings is finished
	self.root.speed = 0;
	AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
	self.root.swinging = false;
end

function door.EventCallbacks.SwingOpen:OnPressed(inputValue)
-- Triggers on "Swing Open" event from door.inputbindings being held
	if not self.root.swinging and self.root:CanSwing(inputValue) then 
		self.root:TryOpenDoorSound();
 		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
		self.root.swinging = true;
		self.root:ConnectToTickBus();
	end
	
	self.root.target = self.root.opened;
	self.root.speed = self.root.baseSpeed;
end

function door.EventCallbacks.SwingOpen:OnReleased(floatValue)
-- Triggers when "Swing Open" event from door.inputbindings is finished
	self.root.speed = 0;
	AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
	self.root.swinging = false;
end

function door.EventCallbacks.SwingClosed:OnPressed(inputValue)
-- Triggers on "Swing Closed" event from door.inputbindings being held
	if not self.root.swinging and self.root:CanSwing(-inputValue) then 
 		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSound);
		self.root.swinging = true;
		self.root:ConnectToTickBus();
	end
	
	self.root.target = self.root.closed;
	self.root.speed = -self.root.baseSpeed;
end

function door.EventCallbacks.SwingClosed:OnReleased(floatValue)
-- Triggers when "Swing Open" event from door.inputbindings is finished
	self.root.speed = 0;
	AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.root.entityId, self.root.CreakSoundStop);
	self.root.swinging = false;
end

function door:OnTick(deltaTime, timePoint)
	-- Calculate the current position of the door based on speed over time
	self.current = self.current + self.speed * deltaTime;

	-- When the door has exceeded opened or close, clamp the door position and stop swinging
	if self.current > self.opened then 
		self.current = self.opened; 
		self.speed = 0;
		self.swinging = false;
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.CreakSoundStop);
		
	elseif self.current < self.closed then 
		self.current = self.closed;
		self.speed = 0;
		self.swinging = false;
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.CreakSoundStop);
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.SlamSound);
	end

	-- Change the door creak sound based on the speed and amount opened or closed
	local RtpcMult = 100;
	local RtpcVal = (self.current / self.opened) * RtpcMult;
	AudioRtpcComponentRequestBus.Event.SetRtpcValue(self.entityId, self.CreakVolume, RtpcVal);
	
	RtpcVal = ((self.speed / self.baseSpeed) + 1) * (0.5 * RtpcMult);
	AudioRtpcComponentRequestBus.Event.SetRtpcValue(self.entityId, self.CreakPitch, RtpcVal);

	-- Set the rotation of the door
	local tm = TransformBus.Event.GetWorldTM(self.entityId); 
	local tr = Transform.CreateRotationZ(self.current);
	tr:SetTranslation(tm:GetTranslation());
	TransformBus.Event.SetWorldTM(self.entityId, tr);
		
	if self.speed == 0 then 
		self.TickBusHandler:Disconnect();
	end
end

function door:OnDeactivate()
	self.Handlers.Open:Disconnect();
	self.Handlers.Close:Disconnect();
	self.Handlers.Toggle:Disconnect();
	self.Handlers.Swing:Disconnect();
	self.Handlers.SwingOpen:Disconnect();
	self.Handlers.SwingClosed:Disconnect();
end

return door;