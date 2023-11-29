local RunService = game:GetService("RunService")
local Horizon = {}

local Utils = script.Utils

local Signal = require(Utils.Signal)
local InternalEnums = require(Utils.InternalEnums)

local function impl_functions(refTable)
	for Index, Function in Horizon do
		if Index == "new" then
			continue
		end
		refTable[Index] = Function
	end
	return refTable
end

function Horizon:setLoops()
	assert(Horizon.World, "World is not valid.")

	self = if self == Horizon then Horizon.World else self

	self.Loops = {}

	for LoopName, Loop in InternalEnums.Loop do
		if LoopName == "BeforeRender" and RunService:IsServer() then
			continue
		end

		self.Loops[LoopName] = Loop:Connect(function(...)
			for ID, Entity in self.Entities do
				for _, LoopInfo in Entity.Loops do
					if LoopInfo[1] ~= LoopName then
						continue
					end

					LoopInfo[2](ID, ...)
				end
			end
		end)
	end
end

function Horizon.new() -- creates a new world
	assert(not Horizon.World, "World has already been created.")

	local World = impl_functions({})

	World.Sequence = 0
	World.Entities = {}

	World.EntityAdded = Signal.new()
	World.EntityRemoved = Signal.new()

	Horizon.World = World

	World.EntityRemoved:Connect(function(Entity)
		World:RemoveEntity(World:FindID(Entity))
	end)
	World:setLoops()

	return World
end

function Horizon:AddEntity(Entity)
	assert(Horizon.World, "World is not valid.")
	assert(typeof(Entity) == "table" and Entity:IsA("Entity"), "Entity is not valid.")

	self = if self == Horizon then Horizon.World else self

	Entity.onRemove = self.EntityRemoved

	self.Sequence = self.Sequence + 1
	self.Entities[self.Sequence] = Entity
	self.EntityAdded:Trigger(self.Sequence, Entity)

	return Entity
end

function Horizon:RemoveEntity(ID)
	assert(Horizon.World, "World is not valid.")

	self = if self == Horizon then Horizon.World else self

	local entity = self.Entities[ID]
	if entity.State == InternalEnums.State.Active then
		entity:Destroy()
	end
	self.Entities[ID] = nil
end

function Horizon:GetEntityFromInstance(instance)
	assert(typeof(instance) == "Instance", "Instance is not valid.")
	assert(Horizon.World, "World is not valid.")

	self = if self == Horizon then Horizon.World else self

	for ID, entity in self.Entities do
		if entity.Instance == instance then
			return { ID, entity }
		end
	end
	return false
end

function Horizon:FindID(Entity)
	assert(Horizon.World, "World is not valid.")

	self = if self == Horizon then Horizon.World else self

	for ID, entity in self.Entities do
		if Entity == entity then
			return ID
		end
	end
	return false
end

local function Query(with, ...)
	assert(Horizon.World, "World is not valid.")

	local Components = { ... }
	local results = {}

	local _entities = {}

	for ID, Entity in Horizon.World.Entities do
		if Entity:hasComponents(table.unpack(Components)) == with then
			table.insert(_entities, { ID, Entity })
		end
	end
	local onAdded = Horizon.World.EntityAdded:Connect(function(ID, Entity)
		if Entity:hasComponents(table.unpack(Components)) == with then
			table.insert(_entities, { ID, Entity })
		end
	end)
	local onRemove = Horizon.World.EntityRemoved:Connect(function(Entity)
		local ID = Horizon:FindID(Entity)
		local isPresent = table.find(_entities, { ID, Entity })
		if isPresent then
			table.remove(_entities, isPresent)
		end
	end)

	results.Terminate = function(_)
		results.Terminate = nil

		onAdded:Destroy()
		onRemove:Destroy()

		return results.Get()
	end
	results.Get = function(isIter)
		return if isIter
			then {
				iter = function(Function)
					for _, Result in _entities do
						Function(Result[1], Result[2])
					end
				end,
			}
			else _entities
	end

	return results
end

function Horizon:QueryWith(...)
	return Query(true, ...)
end

function Horizon:QueryWithout(...)
	return Query(false, ...)
end

Horizon.Enums = InternalEnums

return Horizon
