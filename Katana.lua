local Tool = script.Parent
local Sounds = Tool.Handle.Sounds:GetChildren()
local active = false
local cooldown = 0.6
local boxSize = Vector3.new(5, 5, 5)  -- 5x5x5 box size

local function HitObject(hit: Instance, damage: number, enemyHit: Player)
	local bill = Instance.new("BillboardGui")
	bill.MaxDistance = 1000
	bill.Size = UDim2.new(0, 35, 0, 35)
	bill.AlwaysOnTop = true
	bill.LightInfluence = 1
	bill.Adornee = hit

	local txt = Instance.new("TextLabel")
	txt.Text = damage
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.TextScaled = true
	txt.FontFace = Font.new(
		"rbxasset://fonts/families/FredokaOne.json", 
		Enum.FontWeight.Bold
	)
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextStrokeTransparency = 0
	txt.Parent = bill
	bill.Parent = workspace
	game:GetService("Debris"):AddItem(bill, 0.8)
end

local Animations = {}
for i, v in script:GetChildren() do
	Animations[i] = workspace:WaitForChild(script.Parent.Parent.Parent.Name).Humanoid:LoadAnimation(v)
	Animations[i].Priority = Enum.AnimationPriority.Action4
end

local Count = 1

Tool.Activated:Connect(function()
	if active == false then
		Sounds[math.random(1, #Sounds)]:Play()
		active = true

		for i,v in pairs(Animations) do
			v:Stop()
		end
		Animations[Count]:Play()
		if Count == 5 then
			Count = 1
		else
			Count += 1
		end
		active = false
	end
end)

Tool.spine.Touched:Connect(function(hit)
	local character = Tool.Parent
	local humanoid = hit.Parent:FindFirstChild("Humanoid")

	-- Only process if the hit is from the humanoid
	if humanoid then
		if active == true and character:IsA("Model") then
			local damage = math.random(80, 120)
			local player = game.Players:GetPlayerFromCharacter(character)
			local enemy = game.Players:GetPlayerFromCharacter(hit.Parent)

			if enemy and player.Team ~= enemy.Team then
				-- Hit object with damage
				HitObject(hit, damage, enemy)
				hit.Parent.Humanoid.Health -= damage
			elseif not enemy then
				-- Hit object with damage (if it's a non-player character)
				HitObject(hit, damage)
				hit.Parent.Humanoid.Health -= damage
			end
		end
	end
end)

-- Function to deal damage to humanoids in front of the player
local function hitHumanoidsInFront(playerCharacter)
	local headPosition = playerCharacter:WaitForChild("Head").Position
	local lookVector = playerCharacter.PrimaryPart.CFrame.LookVector

	-- Define a Region3 to detect humanoids in front of the player
	local regionStart = headPosition + lookVector * 2  -- Start point is slightly in front of the player
	local regionEnd = regionStart + boxSize  -- Create a box size of 5x5x5

	local parts = workspace:FindPartsInRegion3(Region3.new(regionStart, regionEnd), nil, math.huge)

	-- Iterate through all parts in the region and check for humanoids
	for _, part in ipairs(parts) do
		local parent = part.Parent
		local enemyHumanoid = parent:FindFirstChild("Humanoid")

		if enemyHumanoid then
			local enemyPlayer = game.Players:GetPlayerFromCharacter(parent)
			local damage = math.random(80, 120)

			-- Apply damage to the humanoid
			if enemyPlayer then
				if playerCharacter ~= parent then
					HitObject(part, damage, enemyPlayer)
					enemyHumanoid.Health -= damage
				end
			else
				HitObject(part, damage)
				enemyHumanoid.Health -= damage
			end
		end
	end
end

-- Use the tool's activation to trigger damage to humanoids in front of the player
Tool.Activated:Connect(function()
	local character = Tool.Parent
	if character and character:IsA("Model") then
		hitHumanoidsInFront(character)
	end
end)
