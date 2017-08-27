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

local PauseSeqWithCheckBox = 
{
	Properties = 
	{
		SequenceName = "",
	},
}

function PauseSeqWithCheckBox:OnActivate()
	self.checkboxHandler = UiCheckboxNotificationBus.Connect(self, self.entityId)

	self.tickBusHandler = TickBus.Connect(self);
end

function PauseSeqWithCheckBox:OnTick(deltaTime, timePoint)
	self.tickBusHandler:Disconnect()	
		
	self.canvas = UiElementBus.Event.GetCanvas(self.entityId)

	-- Initialize checkbox and start the sequence
	UiCheckboxBus.Event.SetState(self.entityId, true)
	UiAnimationBus.Event.StartSequence(self.canvas, self.Properties.SequenceName)
end

function PauseSeqWithCheckBox:OnDeactivate()
	self.checkboxHandler:Disconnect()
end

function PauseSeqWithCheckBox:OnCheckboxStateChange(isChecked)
	if (isChecked) then
		UiAnimationBus.Event.ResumeSequence(self.canvas, self.Properties.SequenceName)
	else
		UiAnimationBus.Event.PauseSequence(self.canvas, self.Properties.SequenceName)
	end
end

return PauseSeqWithCheckBox