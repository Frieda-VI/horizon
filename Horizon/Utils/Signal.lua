local Signal = {}

local Utils = script.Parent
local InternalEnums = require(Utils.InternalEnums)

local ActiveState = InternalEnums.State.Active
local DeadState = InternalEnums.State.Dead

function newConnection(Connections, Function)
	local self = {}

	self.Function = Function
	self.SpawnTrigger = function(_, ...)
		task.spawn(Function, ...)
	end
	self.Trigger = function(_, ...)
		Function(...)
	end

	self.Destroy = function(_, ID)
		ID = ID or table.find(Connections, self)
		Connections[ID] = nil

		table.clear(self)
	end
	self.State = ActiveState

	table.insert(Connections, self)

	return self
end

function Signal:Connect(Function)
	assert(typeof(Function) == "function", "Not a valid function.")
	return newConnection(self.Connections, Function)
end

local function Trigger(self, SpawnTrigger, ...)
	if self.State == DeadState then
		return
	end

	for _, Connection in self.Connections do
		if Connection.State == DeadState then
			continue
		end

		if SpawnTrigger then
			Connection:SpawnTrigger(...)
		else
			Connection:Trigger(...)
		end
	end
end

function Signal:Trigger(...)
	Trigger(self, false, ...)
end

function Signal:SpawnTrigger(...)
	Trigger(self, true, ...)
end

local function impl_functions(ref_table)
	for Index, Function in Signal do
		if Index == "new" then
			continue
		end
		ref_table[Index] = Function
	end
	return ref_table
end

function Signal.new()
	local self = impl_functions({})

	self.Connections = {}
	self.State = ActiveState

	return self
end

function Signal:Destroy()
	self.State = DeadState

	for ID, Connection in self.Connections do
		Connection:Destroy(ID)
	end

	table.clear(self)
end

return Signal
