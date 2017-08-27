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

local SpawnAndDestroyTest = 
{
    Properties = 
    {
    },
}

function SpawnAndDestroyTest:OnActivate()
    
    -- Listen for spawn events.
    self.spawnHandler = SpawnerComponentNotificationBus.Connect(self, self.entityId)
    
    -- Listen for tick events.
    self.tickHandler = TickBus.Connect(self, 0)
    
    -- Tell the spawner component to spawn on activate.
    SpawnerComponentRequestBus.Event.Spawn(self.entityId)
end

function SpawnAndDestroyTest:OnDeactivate()
    self.spawnHandler = nil
    self.tickHandler = nil
end

function SpawnAndDestroyTest:OnEntitySpawned(ticket, entityId)
    if (self.entitiesSpawned == nil) then
        self.entitiesSpawned = {}
    end
    
    -- Keep track of every entity spawned.
    table.insert(self.entitiesSpawned, entityId)
end

function SpawnAndDestroyTest:OnTick(deltaTime, timePoint)
    if (self.counter == nil) then
        self.counter = 0
    end
    
    self.counter = self.counter + deltaTime
    
    -- After two seconds, destroy the entire slice.
    if (self.counter > 2.0) then
        GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entitiesSpawned[1])
        self.tickHandler:Disconnect()
    end
end

return SpawnAndDestroyTest