local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Horizon = require(ReplicatedStorage:WaitForChild("Horizon"))
local _World = Horizon.new()

local Bees = require(script.Bees)
local _Flowers = require(script.Flowers)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MakePollen = Remotes:WaitForChild("MakePollen")

local PlayerBees = {}

local function MakeLeaderboard(Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = Player

	local Pollen = Instance.new("IntValue")
	Pollen.Name = "Pollen"
	Pollen.Parent = leaderstats
end

Players.PlayerAdded:Connect(function(Player)
	MakeLeaderboard(Player)
	PlayerBees[Player] = Bees.new(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
	local Bee = PlayerBees[Player]
	if Bee then
		Bee:Destroy()
	end
end)

MakePollen.OnServerEvent:Connect(function(Player, Model)
	if not Model or not Model:GetAttribute("isFlower") or not Model:FindFirstChild("Center") then
		return
	end

	local entity = Horizon:GetEntityFromInstance(Model)
	local Bee = PlayerBees[Player]
	if not entity or not Bee then
		return
	end

	local Pollen = Bee.Systems.Bee:MoveTo(entity[2], Model.Center.Position, Player)
end)
