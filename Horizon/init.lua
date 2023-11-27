local Horizon = {}

local Component = require(script.Component)
local Entity = require(script.Entity)
local Enums = script.Enums
local System = require(script.Enums.System)

local ExecutionMode = require(Enums.ExecutionMode)

local function impl_functions(refTable)
	for Index, Function in Horizon do
		if string.find(Index, "new") or Index == "Components" then
			continue
		end

		refTable[Index] = Function
	end
	return refTable
end

Horizon.Components = {}

function Horizon:Spawn(instance, ...)
	assert(instance, "Entity cannot be created without an instance.")

	local newEntity = Entity
		.new(instance, ...)
		--
		:AddDestrutor(function(newEntity)
			return function()
				local ID = table.find(self.Entities, newEntity)
				self:Despawn(ID)
			end
		end)

	table.insert(self.Entities, newEntity)

	return newEntity
end

function Horizon:Despawn(ID)
	local entity = self.Entities[ID]
	if not entity then
		warn("Failure to despawn entity!")
		return
	end

	if entity.State == "Denatured" then
		entity:Denature()
	end
	table.insert(self.CleanList, entity)
end

function Horizon:Clean()
	for pos, entity in self.CleanList do
		local ID = table.find(self.Entities, entity)
		if ID then
			table.remove(self.Entities, ID)
		end

		table.remove(self.CleanList, pos)
	end
	self.CleanList = {}
end

function Horizon.newSystem()
	return System
end

function Horizon.newComponent(...)
	local component = Component.new(...)
	Horizon.Components[component.Name] = component
	return component
end

function Horizon.GetComponent(Name)
	return Horizon.Components[Name]
end

function Horizon:Loop()
	ExecutionMode.default:Connect(function(deltaTime)
		for _, entity in self.Entities do
			if self.State == "Denatured" then
				continue
			end
			entity:Loop(deltaTime)
		end

		self:Clean()
	end)
end

function Horizon.new()
	local self = impl_functions({})

	self.Components = {}
	self.Entities = {}

	self.CleanList = {}

	return self
end

function Horizon:_query(withComponent, ...)
	local Result = {}

	for id, entity in self.Entities do
		if table.find(self.CleanList, entity) then
			continue
		end

		local isWanted = true
		for _, component in { ... } do
			if
				(withComponent and not entity.Components[component.Name])
				or (not withComponent and entity.Components[component.Name])
			then
				isWanted = false
				break
			end
		end

		if isWanted then
			table.insert(Result, { id, entity })
		end
	end

	return {
		get = function()
			return Result
		end,
		iter = function(Function)
			for _, EntityProp in Result do
				Function(EntityProp[1], EntityProp[2])
			end
		end,
	}
end

function Horizon:QueryWith(...)
	return self:_query(true, ...)
end

function Horizon:QueryWithout(...)
	return self._query(false, ...)
end

return Horizon
