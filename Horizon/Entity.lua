local Entity = {}

local Utils = script.Parent.Utils

local Maid = require(Utils.Maid)
local InternalEnums = require(Utils.InternalEnums)

local ActiveState = InternalEnums.State.Active
local DeadState = InternalEnums.State.Dead

local function impl_functions(refTable)
	for Index, Function in Entity do
		if Index == "new" then
			continue
		end
		refTable[Index] = Function
	end
	return refTable
end

function Entity:IsA(type)
	return type == "Entity" and self.State == ActiveState
end

function Entity:hasComponents(...)
	local has = true
	for _, Component in { ... } do
		local Name = if typeof(Component) == "string" then Component else Component.Name
		if not self.Components[Name] then
			return false
		end
	end
	return has
end

function Entity:AddComponent(Component)
	assert(Entity.State ~= DeadState, "Entity is not active.")
	assert(Component:IsA("Component"), "Not a valid component.")

	self.Components[Component.Name] = Component:Clone()
end

function Entity:GetComponent(Component)
	local Name = if typeof(Component) == "string" then Component else Component.Name
	return self.Components[Name]
end

function Entity:RemoveComponent(Component)
	assert(Entity.State == DeadState, "Entity is not active.")
	assert(typeof(Component) == "table" or type(Component) == "string", "Component is not valid.")

	local Name = if typeof(Component) == "string" then Component else Component.Name

	self.Components:Denature()
	self.Components[Name] = nil
end

function Entity:AddSystem(System)
	assert(System:IsA("System"), "System is not valid.")

	local Component = System.Component
	self.Systems[Component] = {}
	for Index, Function in System.Functions do
		assert(typeof(Function) == "function", "Function is not valid.")

		self.Systems[Component][Index] = function(_, ...)
			return Function(self, self:GetComponent(Component), ...)
		end
	end

	return self
end

function Entity.new(instance, ...)
	assert(typeof(instance) == "Instance", "Not a valid instance.")

	local self = impl_functions({})

	self.Instance = instance
	self.Components = {}

	self.LoopSequence = 0
	self.Loops = {}

	self.Systems = {}

	self.State = ActiveState

	for _, Component in { ... } do
		self:AddComponent(Component)
	end

	return self
end

function Entity:SetLoop(LoopType, Function)
	assert(LoopType and InternalEnums.Loop[LoopType], "Loop type is not valid.")

	local Sequence = self.LoopSequence + 1
	self.LoopSequence = Sequence
	self.Loops[Sequence] = {
		LoopType,
		function(ID, ...)
			local isTerminate = Function(ID, ..., Sequence)
			if isTerminate == InternalEnums.TerminateLoop then
				self:RemoveLoop(Sequence)
			end
		end,
	}

	return self
end

function Entity:RemoveLoop(ID)
	local Loop = self.Loops[ID]

	Loop[1] = nil
	Loop[2] = nil

	self.Loops[ID] = nil
end

function Entity:AutoPilot()
	local Components = {}
	for _, component in self.Components do
		table.insert(Components, component)
	end

	self.Maid = Maid
		--
		:BindTo(self.Instance)
		:Add(table.unpack(Components))
		:afterDestroy(function()
			if self.State == ActiveState then
				self:Destroy()
			end
		end)

	return self
end

function Entity:AddMaid()
	assert(self.Maid, "Maid has already been added!")

	self.Maid = Maid.new()
	return self.Maid
end

function Entity:Clone(instance)
	return Entity.new(instance or self.Instance:Clone(), table.unpack(self.Components))
end

function Entity:Destroy()
	self.State = DeadState

	if self.Maid and self.Maid.State == ActiveState then
		self.Maid:Cleanup()
	end
	if self.onRemove then
		self.onRemove:Trigger(self)
	end

	table.clear(self)
end

return Entity
