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

local CanvasRefOnProxy = 
{
	Properties = 
	{
		CanvasRef = {default = EntityId()},
		Delay = 0,
		ListenForRefChanges = true,
	},
}

function CanvasRefOnProxy:OnActivate()
	if (self.Properties.Delay == 0) then
		self:InitCanvasRef()
	else
		self.tickBusHandler = TickBus.Connect(self);
		self.tickTime = 0
	end
end

function CanvasRefOnProxy:OnTick(deltaTime, timePoint)
	self.tickTime = self.tickTime + deltaTime
	if (self.tickTime >= self.Properties.Delay) then
		self.tickBusHandler:Disconnect()

		self:InitCanvasRef()
	end
end

function CanvasRefOnProxy:OnDeactivate()
	if (self.canvasRefHandler ~= nil) then
		self.canvasRefHandler:Disconnect()
	end
	
	if (self.tickBusHandler ~= nil) then
		self.tickBusHandler:Disconnect()
	end
end

function CanvasRefOnProxy:OnCanvasRefChanged(canvasRef, canvas)
	self:SetCanvasRefOnEntity(canvasRef)
end

function CanvasRefOnProxy:InitCanvasRef()
	self:SetCanvasRefOnEntity(self.Properties.CanvasRef)
	
	if (self.Properties.ListenForRefChanges) then
		self.canvasRefHandler = UiCanvasRefNotificationBus.Connect(self, self.Properties.CanvasRef)
	end
end

function CanvasRefOnProxy:SetCanvasRefOnEntity(canvasRef)
	UiCanvasProxyRefBus.Event.SetCanvasRefEntity(self.entityId, canvasRef)
end

return CanvasRefOnProxy