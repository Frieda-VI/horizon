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

function Component:IsA(type)
	return type == "Component"
end

local function deep_copy(t)
	local new_t = table.clone(t)
	for i, v in new_t do
		if v ~= "table" then
			continue
		end

		if typeof(v.IsA) == "function" and (v:IsA("Entity") or v:IsA("Component") or v:IsA("System")) then
			new_t[i] = v --> shallow copy
		else
			new_t[i] = deep_copy(v)
		end
	end

	return new_t
end

function Component:getData()
	return self.Data
end

function Component:setData(Function)
	local data = deep_copy(self.Data)
	self.Data = table.freeze(Function(data) or {})
end

function Component:hardSetData(Data) --> not recommended
	self.Data = table.freeze(Data)
end

function Component.new(Name, Data)
	local self = impl_functions({})

	self.Name = Name
	self.Data = table.freeze(Data)

	return self
end

function Component:Clone()
	return Component.new(self.Name, deep_copy(self.Data))
end

function Component:Denature()
	table.clear(self)
end

return Component
