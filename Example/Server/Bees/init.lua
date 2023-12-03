local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local HorizonModel = ReplicatedStorage:WaitForChild("Horizon")
local Horizon = require(HorizonModel)

local Entity = require(HorizonModel:WaitForChild("Entity"))
local Component = require(HorizonModel:WaitForChild("Component"))
local System = require(HorizonModel:WaitForChild("System"))

local BeesModule = {}

local Assets = ServerStorage:WaitForChild("Assets")
local Bees = Assets:WaitForChild("Bees")

--[[
    Some of the fields have not been implemented and were left
    to the scripter to implement, as an exercise.
]]
local Bee_Component = Component.new("Bee", {
	Name = "Simple",
	Energy = 20,
	EnergyDepletion = 0.5 / 60,
	PollenPerSecond = 1,
	Speed = 18,

	Target = nil,
	Trajectory = Vector3.yAxis * 10,
	Collected = 0,
})

local Bee_System, _BeeFunctions = System.new(Bee_Component)
function _BeeFunctions:MoveTo(BeeComponent, Flower, Position, Player)
	local isTarget = true

	self.Systems.Bee:AwardPollen(Player)
	BeeComponent:setData(function(previous)
		if previous.Target == Flower then
			previous.Target = nil
			previous.Trajectory = Vector3.zero

			isTarget = false
		else
			previous.Target = Flower
			previous.Trajectory = Position

			isTarget = true
		end

		return previous
	end)
	if isTarget then
		self.Instance.AlignPos.Position = Position
		self.Instance.AlignOrient.CFrame = CFrame.lookAt(self.Instance:GetPivot().Position, Position)

		self.Systems.Bee:CollectPollen(Flower, Player)
	end
end

function _BeeFunctions:CollectPollen(BeeComponent, Flower, Player)
	task.spawn(function()
		while true do
			local Data = BeeComponent:getData()
			if Data.Target ~= Flower or Flower.State ~= Horizon.Enums.State.Active then
				self.Systems.Bee:AwardPollen(Player)
				break
			end
			if not self.Systems.Bee:isCompleted() then
				task.wait()
				continue
			end

			Flower.Systems.Flower:Collect(Data.PollenPerSecond)
			BeeComponent:setData(function(previous)
				previous.Collected = (previous.Collected or 0) + previous.PollenPerSecond
				return previous
			end)

			task.wait(1)
		end
	end)
end

function _BeeFunctions:AwardPollen(BeeComponent, Player)
	BeeComponent:setData(function(previous)
		Player.leaderstats.Pollen.Value = Player.leaderstats.Pollen.Value + previous.Collected
		previous.Collected = 0
		return previous
	end)
end

function _BeeFunctions:isCompleted(BeeComponent)
	local Trajectory = BeeComponent:getData().Trajectory
	return (self.Instance:GetPivot().Position - Trajectory).Magnitude <= 1.2
end

Bee_System:Seal() --> Prevents any further modifications

function BeesModule.new(Player)
	local bee_model = Bees.Simple:Clone()
	bee_model.Parent = workspace.Bees
	bee_model:SetAttribute("Player", Player.UserId)

	return Horizon:AddEntity(Entity.new(bee_model, Bee_Component):AddSystem(Bee_System))
end

return BeesModule
