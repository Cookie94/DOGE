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

local ChickenAnimController =
{
    Properties =
    {
        FlapInterval = { default = 0.5, description = "How often the chicken flaps.", suffix = " sec" },
        MoveSpeed = { default = 3.0, description = "How fast the chicken moves.", suffix = " m/s" },
        IdlePlaybackSpeed = { default = 1.0, description = "Playback speed for the idle animation." },
        FlapPlaybackSpeed = { default = 1.0, description = "Playback speed for the flap/jump animation." },
        FlapBlendTime = { default = 0.2, description = "Blend time for the flap animation." },
        Test1 = { Vector3(1,2,3), Vector3(1,2,3) },
    },
}

function ChickenAnimController:OnActivate()

    self.FlapCountdown = 0.0;

    -- For handling tick events.
    self.tickBusHandler = TickBus.Connect(self);

    -- Start by playing the idle animation.
    -- Layer 0, looping, speed=1, no transition time.
    local animInfo = AnimatedLayer("anim_chicken_idle", 0, true, self.Properties.IdlePlaybackSpeed, 0.0);
    SimpleAnimationComponentRequestBus.Event.StartAnimation(self.entityId, animInfo);

end

function ChickenAnimController:OnTick(deltaTime, timePoint)

    -- Get current transform
    local tm = TransformBus.Event.GetWorldTM(self.entityId);

    -- Play the Flap animation FlapInterval seconds.
    self.FlapCountdown = self.FlapCountdown - deltaTime;
    if (self.FlapCountdown < 0.0) then
        -- Layer 0, non-looping, speed=1, 0.2 transition time.
        -- If the flap were partial body, we could use Layer 1.
        local animInfo = AnimatedLayer("anim_chicken_flapping", 0, false, self.Properties.FlapPlaybackSpeed, self.Properties.FlapBlendTime, true);
        SimpleAnimationComponentRequestBus.Event.StartAnimation(self.entityId, animInfo);
        self.FlapCountdown = self.Properties.FlapInterval;
        --Debug.Log("Played the flap");
    end

    -- Adjust translation forward at the configured movement speed.
    local forward = tm:GetColumn(1);
    local tx = tm:GetTranslation();
    tx = tx + forward * deltaTime * self.Properties.MoveSpeed;
    tm:SetTranslation(tx);

    -- Set our new transform.
    TransformBus.Event.SetWorldTM(self.entityId, tm);

end

function ChickenAnimController:OnDeactivate()
	self.tickBusHandler:Disconnect();
end

return ChickenAnimController;
