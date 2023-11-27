local Component = {}

local function impl_functions(refTable)
	for Index, Function in Component do
		if Index == "new" then
			continue
		end

		refTable[Index] = Function
	end
	return refTable
end

function Component.IsA(self, TYPE)
	return self.isComponent and TYPE == "Component"
end

function Component:AddSystem(...)
	if not self.isComponent then
		return Component.new(...)
	end

	for _, System in { ... } do
		if typeof(System) ~= "table" then
			warn("Passed invalid system type.")
			continue
		end

		table.insert(self.Systems, ...)
	end
end

function Component:Feed(Entity)
	self.Entity = Entity

	for _, System in self.Systems do
		System.init(Entity)
	end
end

function Component:onSignal()
	for _, System in self.Systems do
		if System.OnSignal then
			System.OnSignal(self.Entity)
		end
	end
end

function Component:Clone()
	local clone = {}

	for Index, Value in self do
		clone[Index] = Value
	end

	return clone
end

function Component.new(Name, ...)
	local self = impl_functions({})

	self.Name = Name
	self.isComponent = true

	self.Systems = {}
	self:AddSystem(...)

	return self
end

function Component:Destroy()
	self.isComponent = nil
	for _, System in self.Systems do
		System.Destroy(self.Entity)
	end
	self.Systems = nil
end

return Component
