local Maid = {}

local function impl_functions(refTable)
	for Index, Function in Maid do
		if Index == "new" then
			continue
		end
		refTable[Index] = Function
	end
	return refTable
end

function Maid:BindTo(instance)
	assert(self.State == "Active" or self.State == nil, "Cannot bind to inactive maid!")
	assert(typeof(instance) == "Instance", `Passed invalid type: {typeof(instance)}`)

	if self.State == nil then
		return Maid.new():BindTo(instance)
	end

	self.Instance = instance

	local onParent = instance:GetPropertyChangedSignal("Parent"):Connect(function()
		if not instance or instance.Parent == nil then
			self.Instance = nil
			self:Cleanup()
		end
	end)
	local onDestroy = instance.Destroying:Connect(function()
		self.Instance = nil
		self:Cleanup()
	end)

	table.insert(self.CleanList, onParent)
	table.insert(self.CleanList, onDestroy)

	return self
end

function Maid:Add(...)
	assert(self.State == "Active", "Cannot add to inactive maid")
	assert(#{ ... } > 0, "No arguments passed.")

	local CleanList = { ... }

	for _, instance in CleanList do
		if not instance then
			warn("Invalid connection.")
			continue
		end

		table.insert(self.CleanList, instance)
	end
end

function Maid:AddDestrutor(Function)
	self.Destructor = Function
end

function Maid:Cleanup(Hard)
	self.State = "Cleanup"

	for _, instance in self.CleanList do
		if typeof(instance) == "RBXScriptConnection" or typeof(instance) == "RBXScriptSignal" then
			instance:Disconnect()
		else
			instance:Destroy()
		end
	end
	if self.Instance or self.Instance ~= nil then
		self.Instance:Destroy()
	end

	self.State = "Dead"

	if not Hard and self.Destructor then
		self.Destructor()
		self.Destructor = nil
	end
end

function Maid.new()
	local self = impl_functions({})

	self.Instance = nil
	self.CleanList = {}

	self.Destructor = nil

	self.State = "Active"

	return self
end

return Maid
