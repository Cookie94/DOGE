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
-- Lua Spawner Control Example 
local SpawnerSample =
{
    Properties =
    {
        NormalSpawner = { default = false, description = "Enable use of the untranslated Spawn() function" },
        RandomSpawner = { default = true, description = "Enable use of the SpawnRelative() function" },
        RandomSpawnRate = { default = 5, min = 0, max = 10, description = "How Quickly The Spawner Creates Spheres.", suffix = " spheres/s" },
        SpawnCount = { default = 20, min = 5, max = 20, step = 5, description = "Total Number of Spheres to Spawn.", suffix = " spheres"},
        RandomSpawnArea = {default = 4, min = 0, max = 10, step = 0.1, description = "Size of the spawn area.", suffix = " m"}
    }
}

function SpawnerSample:OnActivate()
    -- Register our tick bus handler
    Debug.Assert( self.tickBusHandler == nil )
    self.tickBusHandler = TickBus.Connect(self)
    
    -- Create a handler to receive notification from the spawner attached to this entity.
    if self.spawnerNotiBusHandler == nil then
        self.spawnerNotiBusHandler = SpawnerComponentNotificationBus.Connect(self, self.entityId)
    end

    -- Used to track regular spawn times
    self.timer = 0
    self.spawnTimer = 1

    -- Used to track randomly translated spawn times
    self.randomSpawnTimer = 0
    self.randomSpawnTime = 1 / self.Properties.RandomSpawnRate
    self.count = 0
    self.spawnLength = self.Properties.RandomSpawnArea * 100
end

function SpawnerSample:SpawnSlice()
    -- Use the SpawnerComponentRequestBus to send a Spawn Event to the entity this script is attached to.
    -- If the entity has a spawner component and it has a valid dynamic slice in it's Slice field, the
    -- Slice will be instantiated at the location of the spawner.
    SpawnerComponentRequestBus.Event.Spawn(self.entityId)
    self.count = self.count + 1
end 

function SpawnerSample:SpawnRandomlyOffsetSlice()
    -- Use the SpawnerComponentRequestBus to send a SpwanRelative event to the entity this script is attached to.
    -- If the entity has a spwaner component and it has a valid dynamic slice in it's slice field, the
    -- slice will be intantiated randomly in a cubic volume around the spawner. Use the properties editor to change
    -- its size.

    -- Pick a random offset to spawn the entity at
    local randomTransform = Transform.CreateTranslation( Vector3( math.random(-self.spawnLength, self.spawnLength)/100,
                                                                  math.random(-self.spawnLength, self.spawnLength)/100,
                                                                  math.random(-self.spawnLength, self.spawnLength)/100) )

    SpawnerComponentRequestBus.Event.SpawnRelative(self.entityId, randomTransform)
    self.count = self.count + 1
end

function SpawnerSample:OnTick(deltaTime, timePoint)
    -- Normal Spawner Timer
    if self.count < self.Properties.SpawnCount then
        if self.Properties.NormalSpawner then
            self.timer = self.timer + deltaTime
            if self.timer >= self.spawnTimer then
                self:SpawnSlice()
                self.timer = 0
            end
        end

        -- Random Relative Spawner Timer
        if self.Properties.RandomSpawner then
            self.randomSpawnTimer = self.randomSpawnTimer + deltaTime
            if self.randomSpawnTimer > self.randomSpawnTime then
                self:SpawnRandomlyOffsetSlice()
                self.randomSpawnTimer = 0;
            end
        end
    end
end

function SpawnerSample:OnDeactivate()
    -- Disconnect our tick notification bus handler
    Debug.Assert( self.tickBusHandler ~= nil )
    self.tickBusHandler:Disconnect()
    self.tickBusHandler = nil

    -- Disconnect our spawner notificaton 
    if self.spawnerNotiBusHandler ~= nil then
        self.spawnerNotiBusHandler:Disconnect()
        self.spawnerNotiBusHandler = nil
    end
end

----------------------------------------------------------
-- SPAWNER NOTIFICATION BUS HANDLER FUNCTIONS
-- These functions will be automatically called
-- by the engine when a SpawnerComponentNotificationBus
-- handler has been created for the entity this
-- script is attached to.
----------------------------------------------------------

-- This handler is called when we start spawning a slice.
function SpawnerSample:OnSpawnBegin(sliceTicket)
    -- Do something so we know if/when this is being called
    Debug.Log("Slice Spawn Begin")
end

-- This handler is called when we're finished spawning a slice.
function SpawnerSample:OnSpawnEnd(sliceTicket)
    -- Do something so we know if/when this is being called
    Debug.Log("Slice Spawn End")
end

-- This handler is called whenever an entity is spawned.
function SpawnerSample:OnEntitySpawned(sliceTicket,entityId)
    -- Let's give our spawned entity a bit of upward velocity, just so we can see that this is indeed working.
    PhysicsComponentRequestBus.Event.SetVelocity(entityId, Vector3(0, 0, 3))
end

return SpawnerSample