local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Throw = Humanoid:LoadAnimation(script:WaitForChild("Throw"))
Throw.Priority = Enum.AnimationPriority.Action4

local Point = Character:WaitForChild("Torso"):WaitForChild("Point")
local FastcastEvent = game.ReplicatedStorage.FilteringEnabled.Fastcast

game:GetService("UserInputService").InputBegan:Connect(function(Input, G)
	if G then return end
	if Input.KeyCode == Enum.KeyCode.F then
		Throw:Play()
		FastcastEvent:FireServer("Fire", Point, Mouse.Hit.Position, "Pistol")
		print("Ran")
		--Humanoid:SetAttribute("Attacking", true) 
		--delay(0.1, function() Humanoid:SetAttribute("Attacking", false) end)
	end
end)
