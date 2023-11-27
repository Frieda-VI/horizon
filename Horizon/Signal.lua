local Signal = {}

local function impl_functions(refTable)
	for Index, Function in Signal do
		if Index == "new" then
			continue
		end

		refTable[Index] = Function
	end
	return refTable
end

local Connection = {}

function Connection.new(signal, Function)
	local self = {}

	self.Signal = signal
	self.Function = Function

	function self.Disconnect()
		table.remove(self.Signal.Connections, table.find(self.Signal.Connections, self))

		self.Signal = nil
		self.Function = nil
		self.Disconnect = nil
	end

	table.insert(self.Signal.Connections, self)

	return self
end

function Signal:Connect(Function)
	assert(self.isActive, "Signal is not active.")

	return Connection.new(self, Function)
end

function Signal:Trigger(...)
	assert(self.isActive, "Signal is not active.")

	for pos, connection in self.Connections do
		if not connection or not connection.Function then
			table.remove(self.Connections, pos)
		end

		connection.Function(...)
	end
end

function Signal:Destroy()
	self.isActive = nil

	for pos, connection in self.Connections do
		connection:Disconnect()
		table.remove(self.Connections, pos)
	end

	self.Connections = nil
end

function Signal.new()
	local self = impl_functions({})

	self.Connections = {}

	self.isActive = true

	return self
end

return Signal
