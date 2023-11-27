local Entity = {}

local Maid = require(script.Parent.Maid)
local COMPONENT = require(script.Parent.Component)
local SIGNAL = require(script.Parent.Signal)

local function impl_functions(refTable)
	for Index, Function in Entity do
		if Index == "new" then
			continue
		end

		refTable[Index] = Function
	end
	return refTable
end

function Entity.IsA(self, TYPE)
	return self.isEntity and TYPE == "Entity"
end

function Entity:AddComponent(...)
	assert(self.State == "Active", "Fail to add component on denatured entity.")

	for _, component in { ... } do
		if not COMPONENT.IsA(component, "Component") then
			warn("Argument passed is not a valid Component")
			continue
		end
		local Component = component:Clone()

		self.Components[Component.Name] = Component
		Component:Feed(self)
		self.Maid:Add(Component)
	end
end

function Entity:AddSignal(...)
	assert(self.State == "Active", "Failed to add signal.")

	for _, signal in { ... } do
		local Signal = SIGNAL.new()

		self.Signals[signal] = Signal
		self.Maid:Add(Signal)
	end

	for _, Component in self.Components do
		Component:onSignal()
	end

	return self
end

function Entity:GetSignal(Name)
	assert(self.State == "Active" and self.Signals[Name], "Failed to retrieve signal.")

	return self.Signals[Name]
end

function Entity:RemoveComponent(...)
	assert(self.State == "Active", "Failed to remove component on denatured entity.")

	for _, component in { ... } do
		if not COMPONENT.IsA(component, "Component") then
			warn("Argument passed is not a valid Component")
			continue
		end
		local Component = self.Components[component.Name]
		if not Component then
			warn("Failure to remove component")
			continue
		end

		task.defer(Component.Destroy, Component)
		self.Components[component.Name] = nil
	end
end

function Entity:Loop(deltaTime)
	if self.State ~= "Active" then
		return
	end

	for _, Component in self.Components do
		for _, System in Component.Systems do
			System.Loop(self, deltaTime)
		end
	end
end

function Entity:Denature()
	self.State = "Denatured"

	self.Components = nil
	self.Signals = nil

	if self.Maid.State == "Active" then
		self.Maid:Cleanup(true)
	end
	self.Maid = nil

	self.Instance = nil
end

function Entity:AddDestrutor(Function)
	self.Maid:AddDestrutor(Function(self))
	return self
end

function Entity.new(instance, ...)
	local self = impl_functions({})

	self.Instance = instance
	self.Maid = Maid:BindTo(instance)

	self.Components = {}
	self.Signals = {}

	self.State = "Active"
	self.isEntity = true

	self:AddComponent(...)

	return self
end

return Entity
