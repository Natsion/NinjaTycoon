--------------------------------------------------------------------------------------------------------
-- Prologue Comments:
-- Name of Code Artifact: Player Movement and Jumping Script
-- Brief Description: This script handles player movement, including running, walking, jumping, and wall jumping.
--                     It also manages animations related to these actions such as sprinting, boosting, and landing.
-- Programmer's Name: Abinav Krishnan
-- Date Created: 2/13/25
-- Preconditions: The player character and Humanoid should be fully loaded into the game before this script runs.
-- Acceptable Input: Key press input for jump (spacebar) and player movement (via the Humanoid object).
-- Unacceptable Input: Invalid player state or missing components (e.g., Humanoid, HumanoidRootPart).
-- Postconditions: The script controls player movement, animations, and interactions with the environment like wall jumping.
-- Return Values: None directly from the script, as it handles movement and animation logic.
-- Error/Exception Conditions: Errors may occur if the player character components are not properly loaded or if there is no space to jump.
-- Side Effects: Alters Humanoid properties like WalkSpeed and JumpPower, plays animations during movement and jump states.
-- Invariants: The script continually checks and adjusts the player’s movement and animations during gameplay.
-- Known Faults: No specific error handling for missing or incomplete character components.
--------------------------------------------------------------------------------------------------------

-- Wait until the player's character is fully loaded in the game
repeat wait() until game.Players.LocalPlayer.Character

-- Declare player and character components
local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

-- Services used in the script
local UserInputService = game:GetService("UserInputService")

-- Variables for movement control and jump states
local Boosts = 0  -- Tracks the number of jumps the player has made
local canDoubleJump = true  -- Boolean to control double jump availability
local isRunning = false  -- Flag to check if the player is currently running
local MaxSpeed = 30  -- Maximum running speed

-- Animation and effect modules: Loading the animations used in the script
local Animations = {
	["Jump"] = Humanoid:LoadAnimation(script.Animations.Jump),
	["Land"] = Humanoid:LoadAnimation(script.Animations.Land),
	["Sprint"] = Humanoid:LoadAnimation(script.Animations.Sprint),
	["Boost1"] = Humanoid:LoadAnimation(script.Animations.Boost1),
	["Boost2"] = Humanoid:LoadAnimation(script.Animations.Boost2)
}

-- Function to stop all animations
local function StopAnimations()
	for i, v in Animations do
		v:Stop()
	end
end

-- Set the priority for each animation to Action, which is suitable for movement-related animations
for i, v in pairs(Animations) do
	v.Priority = Enum.AnimationPriority.Action
end

--------------------------------------------------------------------------------------------------------

-- Helper function for linear interpolation (used for smooth transitions)
function lerp(a, b, t)
	return a + (b - a) * t
end

-- Control which boost animation is used based on the side of the jump
local Boost = Animations.Boost2
local Side = false

-- Switch the side of the boost animation for alternating boosts
function switchSide()
	Side = not Side
	if Side then
		Boost = Animations.Boost1
	else
		Boost = Animations.Boost2
	end
end

--------------------------------------------------------------------------------------------------------

-- Handle walking and running movement, adjusting speed based on direction and velocity
Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	-- If the player is moving and not running already
	if Humanoid.MoveDirection.Magnitude ~= 0 and not isRunning and Humanoid.WalkSpeed ~= 0 then
		isRunning = true
		-- Coroutine to manage smooth transition of walking speed
		coroutine.wrap(function()
			while task.wait(0.02) and isRunning and Humanoid.WalkSpeed ~= 0 do
				local VelocityMagnitude = (Root.Velocity * Vector3.new(1, 0, 1)).Magnitude
				-- Adjust maximum speed based on velocity and direction
				if Root.CFrame.LookVector:Dot((Root.Velocity * Vector3.new(1, 0, 1)).Unit) > 0.3 then
					MaxSpeed = 30
				elseif Root.CFrame.LookVector:Dot((Root.Velocity * Vector3.new(1, 0, 1)).Unit) < 0.3 and
					Root.CFrame.LookVector:Dot((Root.Velocity * Vector3.new(1, 0, 1)).Unit) > -0.2 then
					MaxSpeed = 30
				elseif Root.CFrame.LookVector:Dot((Root.Velocity * Vector3.new(1, 0, 1)).Unit) < -0.2 then
					MaxSpeed = 30
				end

				-- Smoothly adjust walking speed based on the player's current speed
				if VelocityMagnitude > Humanoid.WalkSpeed then
					if VelocityMagnitude > MaxSpeed then
						Humanoid.WalkSpeed = lerp(Humanoid.WalkSpeed, MaxSpeed, 0.5)
					else
						Humanoid.WalkSpeed = lerp(Humanoid.WalkSpeed, VelocityMagnitude, 0.25)
					end
				end
				Humanoid.WalkSpeed = lerp(Humanoid.WalkSpeed, MaxSpeed, 0.3)

				-- Play the sprinting animation if the player is moving and the ground is not air
				if Animations.Sprint.IsPlaying == false and Humanoid.FloorMaterial ~= Enum.Material.Air then
					Animations.Sprint:Play(0.3)
				end

				-- Stop sprint animation if the player is in the air
				if Humanoid.FloorMaterial == Enum.Material.Air then
					if Animations.Sprint.IsPlaying == true then
						Animations.Sprint:Stop(0.1)
					end
				end
			end
		end)()
	elseif Humanoid.MoveDirection.Magnitude == 0 and isRunning == true then
		-- If player stops moving, reduce speed and stop the running animation
		Humanoid.WalkSpeed = 10
		isRunning = false
		if Animations.Sprint.IsPlaying then
			Animations.Sprint:Stop()
		end
	end
end)

--------------------------------------------------------------------------------------------------------

-- Handle spacebar input for jump actions and wall jumps
UserInputService.InputBegan:Connect(function(key, gp)
	-- When the spacebar is pressed and jump conditions are met
	if key.KeyCode == Enum.KeyCode.Space and not gp and Boosts < 2 then
		if Root and Humanoid then
			-- Wall Jump logic if the player is in freefall
			if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				local Length = 5
				local Ray = Ray.new(Root.Position, Root.CFrame.LookVector * Length)
				local Wall, HitPosition, Normal, Material = workspace:FindPartOnRay(Ray, Character)

				-- Perform a wall jump if a wall is detected
				if Wall then
					StopAnimations()
					Humanoid.JumpPower = 60
					Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true)
					Boosts = Boosts + 1
					Boost:Play(0, 1, 3)
					canDoubleJump = true
					switchSide()
				else
					-- Normal jump if no wall is detected
					if canDoubleJump then
						canDoubleJump = false
						Humanoid.JumpPower = 35
						Humanoid:ChangeState(Enum.HumanoidStateType.Jumping, true)
						Animations.Boost1:Stop(); Animations.Boost2:Stop()

						-- Play the jump animation
						if not Boost.IsPlaying then
							StopAnimations()
							Animations.Jump:Play(0.1)
						end

						-- Reset jump state and power after landing
						Humanoid.StateChanged:Connect(function(_, newState)
							if newState == Enum.HumanoidStateType.Landed then
								Boosts = 0; Humanoid.JumpPower = 30
								canDoubleJump = true
								StopAnimations()
							end
						end)
					end
				end
			end
		end
	end
end)
