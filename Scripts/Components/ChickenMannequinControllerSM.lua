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

local ChickenMannequinControllerSM =
{
    Properties =
    {
        MoveSpeed = { default = 3.0, description = "How fast the chicken moves.", suffix = " m/s" },
        RotationSpeed = { default = 360.0, description = "How fast (in degrees per second) the chicken can turn.", suffix = " deg/sec"},
        CameraFollowDistance = {default = 5.0, description = "Distance (in meters) from which camera follows character."},
        CameraFollowHeight = {default = 1.0, description = "Height (in meters) from which camera follows character."},
        CameraLerpSpeed = {default = 5.0, description = "Coefficient for how tightly camera follows character."},
        Camera = {default = EntityId()},
        InitialState = "Idle",
        DebugStateMachine = false,
    },

    InputValues =
    {
        NavForwardBack = 0.0,
        NavLeftRight = 0.0,
    },

    --------------------------------------------------
    -- Chicken State Machine Definition
    -- States:
    --      Idle
    --      Fidget
    --      Jump
    --      Navigation
    --      NavigationForage
    -- Transitions:
    --      Idle<->Fidget
    --      Idle<->Navigation
    --      Idle<->Jump
    --      Navigation<->Jump
    --      Navigation<->NavigationForage
    --      NavigationForage<->Jump
    --      NavigationForage->Idle
    --------------------------------------------------
    States =
    {

        -- Idle is the base state. All other states should transition back to idle
        -- when complete.
        Idle =
        {
            OnEnter = function(sm)
                -- Trigger idle animation as "persistent". Even if the state isn't running, this guarantees we never t-pose.
                sm.UserData.Fragments.Idle  = sm:EnsureFragmentPlaying(sm.UserData.Fragments.Idle, 1, "Idle", "", true);

                -- Start fidgeting after a bit.
                sm.UserData.timeIdle = 0.0;
                sm.UserData.timeUntilFidget = math.random(3, 5);
            end,

            OnUpdate = function(sm, deltaTime)
                -- Count down to fidget.
                sm.UserData.timeIdle = sm.UserData.timeIdle + deltaTime;

                sm.UserData:UpdateCamera(deltaTime);
            end,

            Transitions =
            {
                -- Transition to Jump state when the "Jump" input/gameplay event fires.
                -- The StateMachine internally handles monitoring for the input.
                Jump =
                {
                    InputEvent = "Jump",
                },

                -- Transition to Fidget when the countdown elapses.
                Fidget =
                {
                    Evaluate = function(sm)
                        return sm.UserData.timeIdle > sm.UserData.timeUntilFidget;
                    end
                },

                -- Transition to navigation if we start moving.
                Navigation =
                {
                    Evaluate = function(sm)
                        return sm.UserData:IsMoving();
                    end
                },
            },
        },

        -- Fidget is basically an idle decoration. If we idle for long enough, fidget, and return to idle.
        Fidget =
        {
            OnEnter = function(sm)
                sm.UserData.Fragments.Fidget = sm:EnsureFragmentPlaying(sm.UserData.Fragments.Fidget, 2, "Fidget", "", false);
            end,

            Transitions =
            {
                -- Back to Idle as soon as the fidget anim finishes.
                Idle =
                {
                    Evaluate = function(sm)
                        local status = MannequinRequestsBus.Event.GetRequestStatus(sm.EntityId, sm.UserData.Fragments.Fidget);
                        if (status == 1 or status == 2) then -- Still playing
                            return false;
                        end
                        return true;
                    end
                },
            },
        },

        -- Navigation is the movement state; currently a simple walk.
        Navigation =
        {
            OnEnter = function(sm)
                sm.UserData.Fragments.Nav = sm:EnsureFragmentPlaying(sm.UserData.Fragments.Nav, 2, "Nav", "", false);
            end,

            OnExit = function(sm)
                sm.UserData.Fragments.Nav = sm:EnsureFragmentStopped(sm.UserData.Fragments.Nav);
                CryCharacterPhysicsRequestBus.Event.RequestVelocity(sm.UserData.entityId, Vector3(0,0,0), 0);
            end,

            -- Update movement logic while in navigation state.
            OnUpdate = function(sm, deltaTime)
                sm.UserData:UpdateMovement(deltaTime);
                sm.UserData:UpdateCamera(deltaTime);
            end,

            Transitions =
            {
                -- Transition to idle as soon as we stop moving.
                Idle =
                {
                    Evaluate = function(sm)
                        return not sm.UserData:IsMoving();
                    end
                },

                Jump =
                {
                    InputEvent = "Jump",
                },

                NavigationForage =
                {
                    Evaluate = function(sm)
                        return sm.UserData:WantsToForage();
                    end
                }
            },
        },

        NavigationForage =
        {
            OnEnter = function(sm)
                MannequinRequestsBus.Event.SetTag(sm.EntityId, "Foraging");
                sm.UserData.Fragments.Nav = sm:EnsureFragmentPlaying(sm.UserData.Fragments.Nav, 2, "Nav", "", false);
            end,

            OnExit = function(sm)
                MannequinRequestsBus.Event.ClearTag(sm.EntityId, "Foraging");
                sm.UserData.Fragments.Nav = sm:EnsureFragmentStopped(sm.UserData.Fragments.Nav);
                CryCharacterPhysicsRequestBus.Event.RequestVelocity(sm.EntityId, Vector3(0,0,0), 0);
            end,

            -- Update movement logic while in navigation state.
            OnUpdate = function(sm, deltaTime)
                sm.UserData:UpdateMovement(deltaTime);
                sm.UserData:UpdateCamera(deltaTime);
            end,

            Transitions =
            {
                -- Transition to idle as soon as we stop moving.
                Idle =
                {
                    Evaluate = function(sm)
                        return not sm.UserData:IsMoving();
                    end
                },

                Jump =
                {
                    InputEvent = "Jump",
                },

                Navigation =
                {
                    Evaluate = function(sm)
                        return not sm.UserData:WantsToForage();
                    end
                },
            },
        },

        -- Jump simple plays a jump fragment and exits once complete.
        Jump =
        {
            OnEnter = function(sm)
                sm.UserData.Fragments.Jump = sm:EnsureFragmentPlaying(sm.UserData.Fragments.Jump, 3, "Jump", "", false);
            end,

            Transitions =
            {
                -- Transition back to idle once the jump is done playing.
                Idle =
                {
                    Evaluate = function(sm)
                        local status = MannequinRequestsBus.Event.GetRequestStatus(sm.EntityId, sm.UserData.Fragments.Jump);
                        if (status == 1 or status == 2) then -- Still playing
                            return false;
                        end
                        return true;
                    end
                },
            },
        },
    },
}

--------------------------------------------------
-- Component behavior
--------------------------------------------------

function ChickenMannequinControllerSM:OnActivate()

    self.Properties.RotationSpeed = Math.DegToRad(self.Properties.RotationSpeed);
    self.Fragments = {};

    -- Setup inputs.
    self.navForwardBackEventId = GameplayNotificationId();
    self.navForwardBackEventId.actionNameCrc = Crc32("NavForwardBack");
    self.navForwardBackEventId.channel = self.entityId;

    self.navLeftRightEventId = GameplayNotificationId();
    self.navLeftRightEventId.actionNameCrc = Crc32("NavLeftRight");
    self.navLeftRightEventId.channel = self.entityId;

    self.forageEventId = GameplayNotificationId();
    self.forageEventId.actionNameCrc = Crc32("Forage");
    self.forageEventId.channel = self.entityId;
    
    -- Register input handlers.
    self.navForwardBackHandler = GameplayNotificationBus.Connect(self, self.navForwardBackEventId);
    self.navLeftRightHandler = GameplayNotificationBus.Connect(self, self.navLeftRightEventId);
    self.forageHandler = GameplayNotificationBus.Connect(self, self.forageEventId);

    -- Create and start our state machine.
    self.StateMachine = {}
    setmetatable(self.StateMachine, StateMachine);
    self.StateMachine:Start(self.entityId, self, self.States, self.Properties.InitialState, self.Properties.DebugStateMachine);
end

function ChickenMannequinControllerSM:OnDeactivate()

    self.navForwardBackHandler:Disconnect();
    self.navLeftRightHandler:Disconnect();
    self.forageHandler:Disconnect();

    -- Terminate our state machine.
    self.StateMachine:Stop();
end

function ChickenMannequinControllerSM:IsMoving()
    -- We're moving if any movement keys or analog stick press is active.
    return (self.InputValues.NavForwardBack ~= 0 or self.InputValues.NavLeftRight ~= 0);
end

function ChickenMannequinControllerSM:WantsToForage()
    return (self.isForaging == true);
end

function ChickenMannequinControllerSM:UpdateMovement(deltaTime)

    -- Protect against no specified camera.
    if (not self.Properties.Camera:IsValid()) then
        return
    end

    local moveLocal = Vector3(self.InputValues.NavLeftRight, self.InputValues.NavForwardBack, 0);

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
        CryCharacterPhysicsRequestBus.Event.RequestVelocity(self.entityId,vel,0);

    end

end

function ChickenMannequinControllerSM:UpdateCamera(deltaTime)

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

    TransformBus.Event.SetWorldTM(self.Properties.Camera,cameraTm);

end

function ChickenMannequinControllerSM:OnEventBegin(value)
    if (GameplayNotificationBus.GetCurrentBusId() == self.navForwardBackEventId) then    
        self.InputValues.NavForwardBack = value;
    elseif (GameplayNotificationBus.GetCurrentBusId() == self.navLeftRightEventId) then
        self.InputValues.NavLeftRight = value;
    else
        self.isForaging = true;
    end
end

function ChickenMannequinControllerSM:OnEventEnd(value)
    if (GameplayNotificationBus.GetCurrentBusId() == self.navForwardBackEventId) then
        self.InputValues.NavForwardBack = 0;
    elseif (GameplayNotificationBus.GetCurrentBusId() == self.navLeftRightEventId) then
        self.InputValues.NavLeftRight = 0;
    else
        self.isForaging = false;
    end
end

function ChickenMannequinControllerSM:BindInputEvent(eventName, inputHandlerTable)
    inputHandlerTable.Listener = GameplayNotificationBus.Connect(inputHandlerTable, GameplayNotificationId(self.entityId, eventName));
    inputHandlerTable.Component = self;
end


--------------------------------------------------
-- Generic State Machine Implementation
-- Everything from here on will be moved to a reusable
-- library that scripts can leverage.
--------------------------------------------------

StateMachine =
{
}
StateMachine.__index = StateMachine;

function StateMachine:Start(entityId, userData, statesTable, initialStateName, isDebuggingEnabled)

    self.EntityId = entityId;
    self.UserData = userData;
    self.States = statesTable;
    self.IsDebuggingEnabled = isDebuggingEnabled;

    -- State machine needs to tick to evaluate transitions.
    self.tickBusHandler = TickBus.Connect(self);

    -- Jump to initial state if specified.
    if (initialStateName ~= nil) then
        self:GotoState(initialStateName);
    end
end

function StateMachine:Stop()
    self.tickBusHandler:Disconnect();
    self.tickBusHandler = nil;
end

function StateMachine:Update(deltaTime)

    if (self.CurrentState == nil) then
        return
    end

    -- Check conditions for the current state's outgoing transitions.
    if (self.CurrentState.Transitions ~= nil) then
        for transKey, transTable in pairs(self.CurrentState.Transitions) do
            if (transTable.Evaluate) then
                local result = transTable.Evaluate(self);
                if (result == true) then
                    self:GotoState(transKey);
                    return;
                end
            end
        end
    end

    -- Call current state's update if bound.
    if (self.CurrentState.OnUpdate ~= nil) then
        self.CurrentState.OnUpdate(self, deltaTime);
    end

end

function StateMachine:GotoState(targetStateName)

    if (self.States == nil) then
        return
    end

    for stateKey, stateTable in pairs(self.States) do
        if (tostring(stateKey) == targetStateName) then

            if (self.CurrentState == stateTable) then
                return
            end

            if (self.CurrentState ~= nil) then

                -- Unbind any input events we were monitoring from the previous state.
                if (self.CurrentState.InputListeners ~= nil) then
                    for inputKey, inputTable in pairs(self.CurrentState.InputListeners) do
                        if (inputTable.EventHandler ~= nil) then
                            inputTable.EventHandler:Disconnect();
                        end
                    end
                end
                self.CurrentState.InputListeners = nil;

                -- Invoke previous state's OnExit handler.
                if (self.CurrentState.OnExit ~= nil) then
                    self.CurrentState.OnExit(self);
                end
            end

            -- Invoke new state's OnEnter handler.
            if (stateTable.OnEnter ~= nil) then
                stateTable.OnEnter(self);
            end

            -- Identify any input conditions in the new state's transitions and register event handlers.
            if (stateTable.Transitions ~= nil) then
                for transKey, transTable in pairs(stateTable.Transitions) do
                    stateTable.InputListeners = {};
                end
                for transKey, transTable in pairs(stateTable.Transitions) do
                    if (transTable.InputEvent ~= nil) then
                        local listenerCount = table.getn(stateTable.InputListeners);
                        stateTable.InputListeners[listenerCount+1] = {};
                        local sm = self;
                        stateTable.InputListeners[listenerCount+1].OnEventBegin = function(value)
                            sm:GotoState(tostring(transKey));
                        end
                        local notificationId = GameplayNotificationId();
                        notificationId.actionNameCrc = Crc32(transTable.InputEvent);
                        notificationId.channel = self.EntityId;
                        stateTable.InputListeners[listenerCount+1].EventHandler =
                            GameplayNotificationBus.Connect(stateTable.InputListeners[listenerCount+1], notificationId);
                    end
                end
            end

            if (self.IsDebuggingEnabled) then
                Debug.Log("[StateMachine] Successfully transitioned: " .. targetStateName);
            end

            self.CurrentState = stateTable;

            return
        end
    end

    if (self.IsDebuggingEnabled) then
        Debug.Log("[StateMachine] Failed to find state: " .. targetStateName);
    end
end

function StateMachine:OnTick(deltaTime, timePoint)
    self:Update(deltaTime);
end

function StateMachine:EnsureFragmentPlaying(requestId, priority, fragmentName, fragmentTags, isPersistent)
    if (requestId) then
        local status = MannequinRequestsBus.Event.GetRequestStatus(self.EntityId, requestId);
        if (status == 1 or status == 2) then
            return requestId;
        end
		self:EnsureFragmentStopped(requestId);
    end

    return MannequinRequestsBus.Event.QueueFragment(self.EntityId, priority, fragmentName, fragmentTags, isPersistent);
end

function StateMachine:EnsureFragmentStopped(requestId)
    if (requestId) then
        MannequinRequestsBus.Event.StopRequest(self.EntityId, requestId);
    end
    return nil;
end

return ChickenMannequinControllerSM;

