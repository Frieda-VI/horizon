local System = {}

function System.new(Component)
	assert(Component, "Component is not valid.")

	local self = {}

	self.Component = if typeof(Component) == "string" then Component else Component.Name
	self.Functions = {}

	self.IsA = function(_, type)
		return type == "System"
	end
	self.Seal = function() --> Avoidable
		table.freeze(self.Functions)
	end

	return self, self.Functions
end

return System
