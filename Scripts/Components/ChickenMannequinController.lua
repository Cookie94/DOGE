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

local ChickenMannequinController =
{
    Properties =
    {
        MoveSpeed = { default = 3.0, description = "How fast the chicken moves.", suffix = " m/s" },
        RotationSpeed = { default = 360.0, description = "How fast (in degrees per second) the chicken can turn.", suffix = " deg/sec"},
        CameraFollowDistance = {default = 5.0, description = "Distance (in meters) from which camera follows character."},
        CameraFollowHeight = {default = 1.0, description = "Height (in meters) from which camera follows character."},
        CameraLerpSpeed = {default = 5.0, description = "Coefficient for how tightly camera follows character."},
        Camera = {default = EntityId()},
    },

    InputActions =
    {
        Jump = {},
        NavForwardBack = {},
        NavLeftRight = {},
    },
}

function ChickenMannequinController:OnActivate()

    self.InputValues = {};

    -- For per-frame update event.
    self.tickBusHandler = TickBus.Connect(self);

    -- Bind input/gameplay events to event handlers.
    self:BindInputEvent("Jump", self.InputActions.Jump);
    self:BindInputEvent("NavForwardBack", self.InputActions.NavForwardBack);
    self:BindInputEvent("NavLeftRight", self.InputActions.NavLeftRight);

    -- Queue persistent Idle fragment.
    self.idleRequest = MannequinRequestsBus.Event.QueueFragment(self.entityId, 1, "Idle", "", true);
end

function ChickenMannequinController:OnTick(deltaTime, timePoint)

    local moveLocal = Vector3(self.InputValues.NavLeftRight or 0.0, self.InputValues.NavForwardBack or 0.0, 0);

    if (moveLocal:GetLengthSq() > 0.01) then
	
		local tm = TransformBus.Event.GetWorldTM(self.entityId);

        -- Apply camera-relative movement on XY plane.
        -- This isn't 100% ideal math, but good enough for this example.
        local cameraOrientation = TransformBus.Event.GetWorldTM(self.Properties.Camera);
        cameraOrientation:SetTranslation(Vector3(0,0,0));
        local moveMag = moveLocal:GetLength();
        if (moveMag > 1.0) then
            moveMag = 1.0
        end

        local moveWorld = cameraOrientation * moveLocal;
        moveWorld.z = 0;
        moveWorld:NormalizeSafe();
        moveWorld = moveWorld * moveMag;

        -- Align to movement direction.
        local facing = tm:GetColumn(1):GetNormalized();
        local desiredFacing = moveWorld;
        local dot = facing:Dot(desiredFacing);
        if (dot > 1.0) then
            dot = 1.0;
        end
        if (dot < -1.0) then
            dot = -1.0;
        end
        local angleDelta = Math.ArcCos(dot);
        local rotationRate = self.Properties.RotationSpeed;
        local thisFrame = angleDelta * rotationRate * deltaTime;
        if (angleDelta > FloatEpsilon) then
            if (thisFrame > angleDelta) then
                thisFrame = angleDelta;
            end
            local side = Math.Sign(facing:Cross(desiredFacing).z);
            if (side < 0.0) then
                thisFrame = -thisFrame;
            end
            local rotationTm = Transform.CreateRotationZ(thisFrame);
            tm = tm * rotationTm;
            tm:Orthogonalize();
            TransformBus.Event.SetWorldTM(self.entityId,tm);
        end

        -- Request movement from character physics.
        local vel = (tm:GetColumn(1) * moveMag * self.Properties.MoveSpeed);
        CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId, vel, 0);

        -- Make sure the nav fragment is playing.
        self.navRequest = self:EnsureFragmentPlaying(self.navRequest, 2, "Nav", "", false);
    else

        CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId, Vector3(0,0,0), 0);

        -- Make sure the nav fragment is not playing.
        self.navRequest = self:EnsureFragmentStopped(self.navRequest);
    end

    self:UpdateCamera(deltaTime);
end

function ChickenMannequinController:UpdateCamera(deltaTime)

    -- Movement is camera relative, so camera just follows from a fixed distance.
    local characterTm = TransformBus.Event.GetWorldTM(self.entityId);
    local followFrom = characterTm:GetTranslation() - Vector3(0, self.Properties.CameraFollowDistance, 0);
    followFrom.z = followFrom.z + self.Properties.CameraFollowHeight;

    local cameraTm = TransformBus.Event.GetWorldTM(self.Properties.Camera);
    local lerpPct = self.Properties.CameraLerpSpeed * deltaTime;
    if (lerpPct > 1.0) then
        lerpPct = 1.0;
    end
    cameraTm:SetTranslation(cameraTm:GetTranslation():Lerp(followFrom, lerpPct));

    TransformBus.Event.SetWorldTM(self.Properties.Camera, cameraTm);

end

function ChickenMannequinController:OnDeactivate()
    for k, v in pairs(self.InputActions) do
        v = {};
    end

    self.tickBusHandler:Disconnect();
end

function ChickenMannequinController:EnsureFragmentPlaying(requestId, priority, fragmentName, fragmentTags, isPersistent)
    if (requestId) then
        local status = MannequinRequestsBus.Event.GetRequestStatus(self.entityId, requestId);
        if (status == 1 or status == 2) then
            return requestId;
        end
		self:EnsureFragmentStopped(requestId);
    end

    return MannequinRequestsBus.Event.QueueFragment(self.entityId, priority, fragmentName, fragmentTags, isPersistent);
end

function ChickenMannequinController:EnsureFragmentStopped(requestId)
    if (requestId) then
        MannequinRequestsBus.Event.StopRequest(self.entityId, requestId);
    end
    return nil;
end

function ChickenMannequinController.InputActions.Jump:OnEventBegin(value)
    self.Component.jumpRequest = self.Component:EnsureFragmentPlaying(self.Component.jumpRequest, 3, "Jump", "", false);
end

function ChickenMannequinController.InputActions.NavForwardBack:OnEventBegin(value)
    self.Component.InputValues.NavForwardBack = value;
end

function ChickenMannequinController.InputActions.NavForwardBack:OnEventEnd()
    self.Component.InputValues.NavForwardBack = 0.0;
end

function ChickenMannequinController.InputActions.NavLeftRight:OnEventBegin(value)
    self.Component.InputValues.NavLeftRight = value;
end

function ChickenMannequinController.InputActions.NavLeftRight:OnEventEnd()
    self.Component.InputValues.NavLeftRight = 0.0;
end

function ChickenMannequinController:BindInputEvent(eventName, inputHandlerTable)
    inputHandlerTable.Listener = GameplayNotificationBus.Connect(inputHandlerTable, GameplayNotificationId(self.entityId, eventName));
    inputHandlerTable.Component = self;
end

return ChickenMannequinController;
