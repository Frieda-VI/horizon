local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local HorizonModel = ReplicatedStorage:WaitForChild("Horizon")
local Horizon = require(HorizonModel)

local Entity = require(HorizonModel:WaitForChild("Entity"))
local Component = require(HorizonModel:WaitForChild("Component"))
local System = require(HorizonModel:WaitForChild("System"))

local FlowersModule = {}

local Assets = ServerStorage:WaitForChild("Assets")
local Flowers = Assets:WaitForChild("Flowers")

local Flower_Component = Component.new("Flower", {
	Pollen = 20,
})

local Flower_System, _FlowerFunctions = System.new(Flower_Component)
function _FlowerFunctions:Collect(FlowerComponent, Amount)
	FlowerComponent:setData(function(previous)
		previous.Pollen = math.max(0, previous.Pollen - Amount)
		if previous.Pollen == 0 then
			self:Destroy()
		else
			self.Instance:SetAttribute("Pollen", previous.Pollen)
		end
		return previous
	end)
end

Flower_System:Seal()

local function random_pos()
	return workspace:Raycast(Vector3.new(math.random(-25, 25), -20, math.random(-25, 25)), Vector3.yAxis * -40).Position
end

function FlowersModule.new(Name)
	local flower_model = Flowers[Name]:Clone()
	flower_model:PivotTo(CFrame.new(random_pos()))
	flower_model:SetAttribute("isFlower", true)
	flower_model:SetAttribute("Pollen", 20)
	flower_model.Parent = workspace.Flowers

	local Flower_Entity =
		Horizon:AddEntity(Entity.new(flower_model, Flower_Component):AddSystem(Flower_System):AutoPilot())

	return Flower_Entity
end

task.spawn(function()
	local Flower_Query = Horizon:QueryWith(Flower_Component)
	local FlowersArray = Flowers:GetChildren()

	while true do
		if #Flower_Query.Get(false) <= 10 then
			local random_flower = math.random(1, #FlowersArray)
			local chosen = FlowersArray[random_flower].Name

			FlowersModule.new(chosen)
		end

		task.wait(6)
	end

	Flower_Query.Terminate()
end)

return FlowersModule
