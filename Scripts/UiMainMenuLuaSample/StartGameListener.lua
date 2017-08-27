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

local StartGameListener = 
{
    Properties =
    {
    },
}

function StartGameListener:OnActivate()
    -- Listen for a start game event
    self.startGameEventId = GameplayNotificationId()	
    self.startGameEventId.actionNameCrc = Crc32("StartGame")
    self.startGameEventId.channel = UiCanvasRefBus.Event.GetCanvas(self.entityId)
    self.startGameHandler = GameplayNotificationBus.Connect(self, self.startGameEventId)	
end

function StartGameListener:OnEventBegin(value)
    if (GameplayNotificationBus.GetCurrentBusId() == self.startGameEventId) then
        -- Unload the main menu canvas
        UiCanvasAssetRefBus.Event.UnloadCanvas(self.entityId)
    end
end

function StartGameListener:OnDeactivate()
    self.startGameHandler:Disconnect()
end

return StartGameListener
