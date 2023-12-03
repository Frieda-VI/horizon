local Maid = {}

local Utils = script.Parent
local InternalEnums = require(Utils.InternalEnums)

local ActiveState = InternalEnums.State.Active
local DeadState = InternalEnums.State.Dead

local function impl_functions(refTable)
	for Index, Function in Maid do
		if Index == "new" then
			continue
		end
		refTable[Index] = Function
	end
	return refTable
end

function Maid:BindTo(instance, ...)
	assert(typeof(instance) == "Instance", "Instance is not valid.")

	self = Maid.new()

	self.Instance = instance
	for _, Task in { ... } do
		table.insert(self.Tasks, Task)
	end

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

	table.insert(self.Tasks, onParent)
	table.insert(self.Tasks, onDestroy)

	self.State = ActiveState

	return self
end

function Maid:Add(...)
	for _, Task in { ... } do
		table.insert(self.Tasks, Task)
	end
	return self
end

function Maid:beforeDestroy(Function)
	assert(typeof(Function) == "function", "Function is not valid.")

	table.insert(self.Destructors.before, Function)
	return self
end

function Maid:afterDestroy(Function)
	assert(typeof(Function) == "function", "Function is not valid.")

	table.insert(self.Destructors.after, Function)
	return self
end

function Maid.new()
	local self = impl_functions({})

	self.Instance = nil
	self.Tasks = {}
	self.Destructors = {
		before = {},
		after = {},
	}

	self.State = DeadState

	return self
end

function Maid:Cleanup()
	self.State = DeadState

	for _, fn in self.Destructors.before do
		fn(self)
	end

	for _, Task in self.Tasks do
		if not Task then
			continue
		end

		if typeof(Task) == "RBXScriptConnection" then
			Task:Disconnect()
		elseif typeof(Task) == "table" and Task:IsA("Component") then
			Task:Denature()
		else
			Task:Destroy()
		end
	end
	if self.Instance then
		self.Instance:Destroy()
	end

	for _, fn in self.Destructors.after do
		fn(self)
	end

	table.clear(self)
end

return Maid
