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

local LevelConfig = 
{
	Properties = 
	{
		FullScreenCanvasRef = {default = EntityId()},
	},
}

function LevelConfig:OnActivate()
	self.canvas = UiCanvasAssetRefBus.Event.LoadCanvas(self.entityId)
	self.canvasNotificationBusHandler = UiCanvasNotificationBus.Connect(self, self.canvas)
end

function LevelConfig:OnDeactivate()
	self.canvasNotificationBusHandler:Disconnect()
end

function LevelConfig:OnAction(entityId, actionName)
	if (actionName == "ChangedFlyCam") then
		-- Get the checkbox state
		local isChecked = UiCheckboxBus.Event.GetState(entityId)
		
		-- Send an event that the fly cam state has changed
		local fullScreenCanvas = UiCanvasRefBus.Event.GetCanvas(self.Properties.FullScreenCanvasRef)
		GameplayNotificationBus.Event.OnEventBegin(GameplayNotificationId(fullScreenCanvas, "FlyCamChanged"), isChecked)
	elseif (actionName == "ChangedScreenNavigation") then
		-- Get the checkbox state
		local isChecked = UiCheckboxBus.Event.GetState(entityId)
		
		-- Update full screen canvas navigation
		local fullScreenCanvas = UiCanvasRefBus.Event.GetCanvas(self.Properties.FullScreenCanvasRef)
		UiCanvasBus.Event.SetIsNavigationSupported(fullScreenCanvas, isChecked)	
	elseif (actionName == "Changed3DNavigation") then
		-- Get the checkbox state
		local isChecked = UiCheckboxBus.Event.GetState(entityId)
		
		-- Update this canvas navigation
		UiCanvasBus.Event.SetIsNavigationSupported(self.canvas, isChecked)
	end
end

return LevelConfig