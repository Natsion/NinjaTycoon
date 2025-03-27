
local Model = script.Parent
local GameName = Model:GetAttribute("GameName") or "Plinko"
local ActiveDistance = 8

local StatName = Model:GetAttribute("LeaderstatsName")
local BallPrice = Model:GetAttribute("BallPrice")

local BaseBall = Model.BallStorage:FindFirstChild("Ball")
BaseBall.Parent = nil

local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Player") -- I recommend also making Players their own dedicated collision group to prevent them from messing with the balls.
PhysicsService:RegisterCollisionGroup("PlinkoBall")

PhysicsService:CollisionGroupSetCollidable("Player","Player", false)
PhysicsService:CollisionGroupSetCollidable("Player","PlinkoBall", false)
PhysicsService:CollisionGroupSetCollidable("PlinkoBall","PlinkoBall", false)

local TweenService = game:GetService("TweenService")
local SpitterLight = Model.Spitter.Head.Attachment.SpotLight
local Flash = TweenService:Create(SpitterLight, TweenInfo.new(.5), {Brightness=0})
Flash:Play()

local BallQueue = {}

function Run(Player, BallMultiplier)
	local Expended = false
	spawn(function() Flash:Cancel() SpitterLight.Brightness=16 Flash:Play() end)
	local Ball = BaseBall:Clone()
	Ball.CollisionGroup = "PlinkoBall"
	Ball.Position = Ball.Position + Ball.CFrame.LookVector*(math.random(-10000,10000)*.0001)
	if Player~=nil then Ball:SetAttribute("Owner", Player.Name) end
	--Ball.Position += Vector3.new(math.random(-10,10),0,math.random(-10,10))*.01
	Ball.Parent = Model.BallStorage
	Ball.Anchored = false
	Ball:CanSetNetworkOwnership(false)
	Ball:SetNetworkOwner(nil)
	--Ball:ApplyAngularImpulse(Vector3.new(math.random(-90,90),math.random(-90,90),math.random(-90,09)))
	local CanNoise=true
	Ball.Touched:Connect(function(Hit)
		if Expended then return end
		if Hit.Parent == Model.Multipliers then
			Expended = true
			if Player~=nil then
				local Multiplier = tonumber(Hit.Name)
				Player.leaderstats[StatName].Value += math.floor(BallPrice*Multiplier)
			end
			Ball:SetAttribute("Owner", "")
			Ball.CanTouch = false
			--Ball.CanCollide = false
			Ball.CanQuery = false
			--Ball.Anchored = true
			Ball.CastShadow = false
			Ball.CFrame = Ball.CFrame
			Ball.Color = Hit.Color
			Ball.Highlight.FillColor = Hit.Color
			Ball.Highlight.OutlineColor = Hit.Color
			Ball.Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Ball.Material = Enum.Material.Neon
			TweenService:Create(Ball, TweenInfo.new(.5), {Size=Vector3.zero}):Play()
		end
		if Hit.Name == "Pin" and CanNoise then
			CanNoise=false
			Ball.Ping.PlaybackSpeed = 1 + (math.random(-10,10)*.001)
			Ball.Ping:Play()
			task.wait(.1)
			CanNoise=true
		end
	end)
	delay(10,function()
		if Player~=nil and not Expended then
			print(Player.Name.."'s ball refunded at original price, failed to fall in time")
			Player.leaderstats[StatName].Value += BallPrice
		end
		Ball:Destroy()
	end)
end

function FindInQueue(Player)
	for i,v in pairs (BallQueue) do
		if v.Plr == Player then
			return true
		end
	end
	return false
end

function FindActive(Player)
	for i,v in pairs (Model.BallStorage:GetChildren()) do
		if v:GetAttribute("Owner") == Player.Name then
			return true
		end
	end
	return false
end

-- This makes prices easier to read
function Comma(Number)
	local F = Number
	while true do F,K = string.gsub(F, "^(-?%d+)(%d%d%d)", '%1,%2') if (K==0) then break end end
	return F
end

for _,PromptModel in pairs (Model.Prompts:GetChildren()) do
	local Prompt = PromptModel:WaitForChild("ActivationPart"):WaitForChild("BallProx")
	local Count = PromptModel:GetAttribute("BallCount")
	local TotalCost = BallPrice * Count
	Prompt.MaxActivationDistance = ActiveDistance
	Prompt.ObjectText = GameName.." ["..Count.."]"
	Prompt.ActionText = "$"..Comma(TotalCost)
	PromptModel:SetAttribute("Bet", TotalCost)
	Prompt.Triggered:Connect(function(Player)
		if Player.leaderstats[StatName].Value >= TotalCost then
			Run(Player, 1)

		else
			print(Player.Name.." can't afford this")
		end
	end)
end
