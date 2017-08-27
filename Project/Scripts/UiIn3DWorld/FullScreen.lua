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

local FullScreen = 
{
	Properties = 
	{
		AnimatedCanvaseRefs = { default = { EntityId() } },
		LevelConfigCanvasRef = {default = EntityId()},
		FlyCamera = {default = EntityId()},
	},
}

function FullScreen:OnActivate()
	self.canvas = UiCanvasAssetRefBus.Event.LoadCanvas(self.entityId)
	self.canvasNotificationBusHandler = UiCanvasNotificationBus.Connect(self, self.canvas)
	
	-- Listen for fly cam state changes
	self.flyCamEventId = GameplayNotificationId()	
	self.flyCamEventId.actionNameCrc = Crc32("FlyCamChanged")
	self.flyCamEventId.channel = UiCanvasRefBus.Event.GetCanvas(self.entityId)
	self.flyCamHandler = GameplayNotificationBus.Connect(self, self.flyCamEventId)
end

function FullScreen:OnDeactivate()
	self.canvasNotificationBusHandler:Disconnect()
	self.flyCamHandler:Disconnect()
end

function FullScreen:OnAction(entityId, actionName)
	if (actionName == "Pause") then
		for i = 0, #self.Properties.AnimatedCanvaseRefs do
			-- Pause canvas's sequence
			local canvas = UiCanvasRefBus.Event.GetCanvas(self.Properties.AnimatedCanvaseRefs[i])
			UiAnimationBus.Event.PauseSequence(canvas, "Seq1")
			
			-- Update canvas's animation checkbox
			local checkbox = UiCanvasBus.Event.FindElementByName(canvas, "AnimateCheckBox")
			UiCheckboxBus.Event.SetState(checkbox, false)
		end
	elseif (actionName == "Resume") then
		for i = 0, #self.Properties.AnimatedCanvaseRefs do
			-- Resume canvas's sequence
			local canvas = UiCanvasRefBus.Event.GetCanvas(self.Properties.AnimatedCanvaseRefs[i])
			UiAnimationBus.Event.ResumeSequence(canvas, "Seq1")
			
			-- Update canvas's animation checkbox
			local checkbox = UiCanvasBus.Event.FindElementByName(canvas, "AnimateCheckBox")
			UiCheckboxBus.Event.SetState(checkbox, true)			
		end	
	elseif (actionName == "ChangedFlyCam") then
		-- Get the checkbox state
		local isChecked = UiCheckboxBus.Event.GetState(entityId)
		
		-- Update fly cam state
		self:UpdateFlyCamState(isChecked)
	end	
end

function FullScreen:OnEventBegin(value)
	if (GameplayNotificationBus.GetCurrentBusId() == self.flyCamEventId) then
		-- Update fly cam state
		self:UpdateFlyCamState(value)
		
		-- Update fly cam checkbox
		local flyCamCheckbox = UiCanvasBus.Event.FindElementByName(self.canvas, "FlyCamCheckBox")
		UiCheckboxBus.Event.SetState(flyCamCheckbox, value)
	end
end

function FullScreen:UpdateFlyCamState(isChecked)
		-- Set fly cam enabled state
		FlyCameraInputBus.Event.SetIsEnabled(self.Properties.FlyCamera, isChecked)
		
		-- Update the mouse cursor
		LyShineLua.ShowMouseCursor(not isChecked)
		
		-- Update the crosshairs
		local crossHairs = UiCanvasBus.Event.FindElementByName(self.canvas, "CrossHair")
		UiElementBus.Event.SetIsEnabled(crossHairs, isChecked)
		
		-- Update the level config canvas's fly cam checkbox
		local levelConfigCanvas = UiCanvasRefBus.Event.GetCanvas(self.Properties.LevelConfigCanvasRef)
		local flyCamCheckbox = UiCanvasBus.Event.FindElementByName(levelConfigCanvas, "FlyCamCheckBox")
		UiCheckboxBus.Event.SetState(flyCamCheckbox, isChecked)
end

return FullScreen