--------------------------------------------------------------------------------------------------------
-- Prologue Comments:
-- Name of Code Artifact: Camera Script
-- Brief Description: This script controls the camera's behavior, including dynamic Field of View (FOV), camera bobbing,
--                     and follows the player's character with smooth rotation.
-- Programmer's Name: Abinav Krishnan
-- Date Created: 2/13/25
-- Preconditions: The script assumes that the player's character is present in the game.
--                The script requires the Camera to be attached to the local player's character.
-- Acceptable Input: The script expects a valid player character and proper camera settings.
-- Unacceptable Input: Invalid camera settings, non-existent player character or humanoid root.
-- Postconditions: The camera follows the player's character and responds to movement and rotations.
-- Return Values: None directly from the script, as it controls the Camera's behavior and character's movement.
-- Error/Exception Conditions: Errors could arise if the player or character components do not exist.
-- Side Effects: Changes the Field of View dynamically based on character movement. Modifies the Camera's position and rotation.
-- Invariants: The camera's Field of View and positioning should remain relative to the player's movement and rotation.
-- Known Faults: The script doesn't have specific error handling for missing or corrupted character components.
--------------------------------------------------------------------------------------------------------

-- Wait until the player's character is fully loaded in the game
repeat
	wait()
until game.Players.LocalPlayer.Character

-- Set the initial Field of View of the Camera
workspace.CurrentCamera.FieldOfView = 35

--------------------------------------------------------------------------------------------------------

-- Declare local variables
local Player = game.Players.LocalPlayer
local Character = Player.Character
local Humanoid = Character:WaitForChild("Humanoid")
Player:GetMouse().Icon = "rbxassetid://11917309340"  -- Set the mouse icon to a custom asset

-- Character body parts and camera components
local Head = Character:WaitForChild("Head")
local Torso = Character:WaitForChild("Torso")
local Root = Character:WaitForChild("HumanoidRootPart")
local Neck  = Torso:WaitForChild("Neck")

-- Set up Mouse and Camera variables
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera
script.Parent = Camera -- Attach the script to the Camera

-- Declare additional variables for controlling camera behavior
local Subject
local LOCK
local BodyPosition
local BodyGyro

-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Constants for camera behavior and movement
local defFov = 50
local divisor = 2
local Turn = 0
local lastVelocity = Root.AssemblyLinearVelocity.Magnitude / divisor

-- Linear interpolation function to calculate smooth transitions
local function Lerp(a, b, t)
	return a + (b - a) * t
end

-- Initial neck orientation variables for camera movement
local Origin = Neck.C0
local Horizontal = 1.0
local Vertical = 0.6
local Speed = 0.5

-- Set Neck properties for smooth camera movement
Neck.MaxVelocity = 1 / 3
Mouse.TargetFilter = Camera

--------------------------------------------------------------------------------------------------------

-- Main Update function that runs continuously to adjust the camera's behavior
function Update()

	-- Dynamic Field of View (FOV) logic based on the player's velocity
	local currentVelocity = Root.AssemblyLinearVelocity.Magnitude
	Camera.FieldOfView = defFov + Lerp(lastVelocity, currentVelocity / divisor, 0.1)
	lastVelocity = Camera.FieldOfView - defFov

	-- Camera bobbing logic when the player is moving
	if Humanoid.MoveDirection.Magnitude > 0 then
		local CT = tick()
		local BobbleX = math.cos(CT * 5) * 0.25
		local BobbleY = math.abs(math.sin(CT * 5)) * 0.25
		local Bobble = Vector3.new(BobbleX, BobbleY, 0)
		Humanoid.CameraOffset = Humanoid.CameraOffset:lerp(Bobble, 0.1)
	else
		Humanoid.CameraOffset = Humanoid.CameraOffset * 0.75
	end
	
	-- Check if the "Subject" part exists, if not, create it
	if not script:FindFirstChild("Subject") then
		Subject = Instance.new("Part", script)
		Subject.Name = "Subject"
		Subject.CanCollide = false
		Subject.Transparency = 1
		Subject.Anchored = false
		Subject.CanCollide = false
		Subject.CanQuery = false
		Subject.CanTouch = false
		Subject.Size = Vector3.new()
		Subject.Position = Root.Position

		-- Set up physics-based movement for the "Subject"
		BodyPosition = Instance.new("BodyPosition", Subject)
		BodyPosition.P = 10000
		BodyPosition.D = 500
		BodyGyro = Instance.new("BodyGyro", Subject)
		BodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
		BodyGyro.D = 500
	end
	
	-- Calculate the intensity of rotation based on root velocity
	local Intensity = Subject.RotVelocity.Y * 2
	if Intensity > 45 then
		Intensity = 45
	end
	if Intensity < -45 then
		Intensity = -45
	end

	-- Apply rotation and camera position adjustments
	Intensity = math.rad(Intensity)
	BodyPosition.Position = Torso.Position + Vector3.new(0, 2, 0)
	BodyGyro.CFrame = Root.CFrame * CFrame.Angles(0, 0, Intensity)

	-- Set the Camera to follow the "Subject" part
	Camera.CameraSubject = Subject
	Camera.CameraType = Enum.CameraType.Follow
	Camera.CFrame = Camera.CFrame * CFrame.new(3, 2, 0)  -- Adjust Camera position with respect to the Subject
end

-- Connect the Update function to the RenderStepped event to update every frame
game:GetService("RunService").RenderStepped:Connect(Update)

-- Destroy the camera script when the humanoid dies (player's character)
Humanoid.Died:Connect(function()
	script.Parent:Destroy()
end)
