
local tweenService = game:GetService("TweenService")
local info = TweenInfo.new()

local function tweenModel(model, CF)
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = model:GetPrimaryPartCFrame()

	CFrameValue:GetPropertyChangedSignal("Value"):Connect(function()
		model:SetPrimaryPartCFrame(CFrameValue.Value)
	end)

	local tween = tweenService:Create(CFrameValue, info, {Value = CF})
	tween:Play()

	tween.Completed:Connect(function()
		CFrameValue:Destroy()
	end)
end

local function CheckIfFinishedLevel(Level)
	return #workspace.Buttons[tostring(Level)]:GetChildren() == 0
end

local CurrentLevel = 1

-- Load initial level buttons
if game.ServerStorage.Buttons:FindFirstChild(tostring(CurrentLevel)) then
	game.ServerStorage.Buttons[tostring(CurrentLevel)]:Clone().Parent = workspace.Buttons
end

local function SetupLevel(Level)
	local buttonFolder = workspace.Buttons:FindFirstChild(tostring(Level))
	if not buttonFolder then return end

	for _, button in pairs(buttonFolder:GetChildren()) do
		local Connection
		Connection = button.Button.Touched:Connect(function(hit)
			if hit.Parent:FindFirstChild("Humanoid") then
				Connection:Disconnect()

				local Object = game.ServerStorage.Levels[Level]:FindFirstChild(button.Name)
				if Object then
					Object = Object:Clone()

					local Size = Object:GetExtentsSize().Y
					local Goal = Object:GetPivot()

					Object:PivotTo(Object:GetPivot() - Vector3.new(0, Size * 2, 0))
					Object.Parent = workspace
					task.wait()
					tweenModel(Object, Goal)

					Object:PivotTo(Goal)
				end

				button:Destroy()

				-- Check if level is completed
				if CheckIfFinishedLevel(Level) then
					CurrentLevel += 1
					if game.ServerStorage.Buttons:FindFirstChild(tostring(CurrentLevel)) then
						game.ServerStorage.Buttons[tostring(CurrentLevel)]:Clone().Parent = workspace.Buttons
						SetupLevel(CurrentLevel)
					end
				end
			end
		end)
	end
end

-- Initialize first level
SetupLevel(CurrentLevel)

game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		local randomUserId = math.random(9999999, 999999999)
		local desc
		local success, response = pcall(function()
			desc = game.Players:GetHumanoidDescriptionFromUserId(Player.UserId)
		end)

		if not success then
			desc = game.Players:GetHumanoidDescriptionFromUserId(randomUserId)
		end
		Character.Humanoid:ApplyDescription(desc)

		for i,v in pairs(Character:GetDescendants()) do
			if v:IsA("BasePart") then
				if v == Character.Head 
					or v == Character.Torso
					or v == Character["Left Arm"]
					or v == Character["Left Leg"]
					or v == Character["Right Arm"]
					or v == Character["Right Leg"]
					or v == Character.HumanoidRootPart
				then else
					v.CanCollide = false
					v.CanTouch = false
					v.CanQuery = false
					v.Massless = true
				end
			end
		end
	end)
end)
