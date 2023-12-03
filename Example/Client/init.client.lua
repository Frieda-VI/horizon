local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MakePollen = Remotes:WaitForChild("MakePollen")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local function isCharacter()
	return if Player.Character
			and Player.Character:FindFirstChild("Humanoid")
			and Player.Character.Humanoid.Health > 0
		then true
		else false
end

UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
	if GameProcessedEvent then
		return
	end

	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		local Target = Mouse.Target
		if
			isCharacter()
			and Target
			and Target:FindFirstAncestorOfClass("Model")
			and Target:FindFirstAncestorOfClass("Model"):GetAttribute("isFlower")
		then
			MakePollen:FireServer(Target:FindFirstAncestorOfClass("Model"))
		end
	end
end)
