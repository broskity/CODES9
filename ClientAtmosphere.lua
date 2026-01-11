--[[
    +------------------------------------------------------------------------------+
    ¦                    INFINITE STREET - CLIENT ATMOSPHERE V2                     ¦
    ¦                   Visual Effects + Mouse Control System                       ¦
    +------------------------------------------------------------------------------+
]]

-- -------------------------------------------------------------------------------
-- SERVICES
-- -------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- -------------------------------------------------------------------------------
-- VARIABLES
-- -------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character: WaitForChild("HumanoidRootPart")

-- -------------------------------------------------------------------------------
-- MOUSE CONTROL SYSTEM (GLOBAL)
-- -------------------------------------------------------------------------------

local MouseController = {
	isLocked = true,
	lockReasons = {}, -- Track what's requesting mouse unlock
}

-- Lock the mouse (hide it, center it)
function MouseController:Lock()
	self.isLocked = true
	self.lockReasons = {}

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	player.CameraMode = Enum.CameraMode.LockFirstPerson

	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
	end
end

-- Unlock the mouse (show it, free movement)
function MouseController:Unlock(reason)
	reason = reason or "unknown"
	self.lockReasons[reason] = true
	self.isLocked = false

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	player.CameraMode = Enum.CameraMode.Classic

	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Scriptable
	end
end

-- Release a lock reason and re-lock if no more reasons
function MouseController:ReleaseLock(reason)
	reason = reason or "unknown"
	self.lockReasons[reason] = nil

	-- Check if any reasons still need mouse unlocked
	local hasReasons = false
	for _, _ in pairs(self.lockReasons) do
		hasReasons = true
		break
	end

	if not hasReasons then
		self: Lock()
	end
end

-- Check if mouse is currently locked
function MouseController:IsLocked()
	return self.isLocked
end

-- Make it globally accessible
_G.MouseController = MouseController

-- -------------------------------------------------------------------------------
-- FIRST PERSON CAMERA SETUP
-- ------------------------??------------------------------------------------------

local function SetupFirstPersonCamera()
	-- Lock mouse immediately
	MouseController:Lock()

	-- Continuously enforce first person when mouse should be locked
	RunService.RenderStepped:Connect(function()
		if MouseController: IsLocked() then
			if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
				player.CameraMode = Enum.CameraMode.LockFirstPerson
			end
			if UserInputService.MouseIconEnabled then
				UserInputService.MouseIconEnabled = false
			end
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end
	end)
end

-- -------------------------------------------------------------------------------
-- CAMERA EFFECTS (SWAY AND BREATHING)
-- -------------------------------------------------------------------------------

local function SetupCameraEffects()
	local breathingSpeed = 1.5
	local breathingIntensity = 0.002
	local swaySpeed = 0.8
	local swayIntensity = 0.001

	local walkBobSpeed = 8
	local walkBobIntensity = 0.015

	local timeElapsed = 0

	RunService.RenderStepped:Connect(function(deltaTime)
		timeElapsed = timeElapsed + deltaTime

		if camera and humanoid then
			local isWalking = humanoid.MoveDirection.Magnitude > 0
			local isRunning = humanoid.WalkSpeed > 16 and isWalking

			local breathingOffset = CFrame.Angles(
				math.sin(timeElapsed * breathingSpeed) * breathingIntensity,
				0,
				math.sin(timeElapsed * breathingSpeed * 0.7) * breathingIntensity * 0.5
			)

			local swayOffset = CFrame.Angles(
				math.sin(timeElapsed * swaySpeed) * swayIntensity,
				math.cos(timeElapsed * swaySpeed * 0.6) * swayIntensity,
				math.sin(timeElapsed * swaySpeed * 0.4) * swayIntensity * 0.5
			)

			local walkOffset = CFrame.new()
			if isWalking then
				local bobMultiplier = isRunning and 1.5 or 1
				walkOffset = CFrame.new(
					math.sin(timeElapsed * walkBobSpeed) * walkBobIntensity * 0.5 * bobMultiplier,
					math.abs(math.sin(timeElapsed * walkBobSpeed)) * walkBobIntensity * bobMultiplier,
					0
				) * CFrame.Angles(
					math.sin(timeElapsed * walkBobSpeed) * walkBobIntensity * 0.3 * bobMultiplier,
					math.sin(timeElapsed * walkBobSpeed * 0.5) * walkBobIntensity * 0.2 * bobMultiplier,
					math.sin(timeElapsed * walkBobSpeed) * walkBobIntensity * 0.1 * bobMultiplier
				)
			end
		end
	end)
end

-- -------------------------------------------------------------------------------
-- AMBIENT SOUNDS
-- -------------------------------------------------------------------------------

local function SetupAmbientSounds()
	local ambientSoundGroup = Instance.new("SoundGroup")
	ambientSoundGroup.Name = "AmbientSounds"
	ambientSoundGroup.Volume = 0.5
	ambientSoundGroup.Parent = SoundService

	local windSound = Instance.new("Sound")
	windSound.Name = "WindAmbient"
	windSound.SoundId = "rbxassetid://9112854440"
	windSound.Volume = 0.15
	windSound.Looped = true
	windSound.SoundGroup = ambientSoundGroup
	windSound.Parent = camera
	windSound: Play()

	local distantFootsteps = Instance.new("Sound")
	distantFootsteps.Name = "DistantFootsteps"
	distantFootsteps.SoundId = "rbxassetid://9114488653"
	distantFootsteps.Volume = 0
	distantFootsteps.Looped = false
	distantFootsteps.SoundGroup = ambientSoundGroup
	distantFootsteps.Parent = camera

	local cityAmbient = Instance.new("Sound")
	cityAmbient.Name = "CityAmbient"
	cityAmbient.SoundId = "rbxassetid://9112556027"
	cityAmbient.Volume = 0.08
	cityAmbient.Looped = true
	cityAmbient.SoundGroup = ambientSoundGroup
	cityAmbient.Parent = camera
	cityAmbient:Play()

	local mysteriousSounds = {
		"rbxassetid://9114221580",
		"rbxassetid://9114221735",
		"rbxassetid://9114221890",
		"rbxassetid://9114222045",
	}

	task.spawn(function()
		while true do
			task.wait(math.random(15, 45))

			local randomSound = Instance.new("Sound")
			randomSound.SoundId = mysteriousSounds[math.random(1, #mysteriousSounds)]
			randomSound.Volume = math.random() * 0.1 + 0.02
			randomSound.PlaybackSpeed = 0.8 + math.random() * 0.4
			randomSound.SoundGroup = ambientSoundGroup
			randomSound.Parent = camera
			randomSound:Play()

			randomSound.Ended:Connect(function()
				randomSound:Destroy()
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(math.random(30, 90))

			distantFootsteps.Volume = math.random() * 0.05 + 0.01
			distantFootsteps.PlaybackSpeed = 0.7 + math.random() * 0.3
			distantFootsteps: Play()
		end
	end)
end

-- -------------------------------------------------------------------------------
-- DYNAMIC POST PROCESSING
-- -------------------------------------------------------------------------------

local function SetupDynamicPostProcessing()
	local colorCorrection = Lighting: FindFirstChild("ColorCorrectionEffect")
	local bloom = Lighting:FindFirstChild("BloomEffect")

	local baseBrightness = colorCorrection and colorCorrection.Brightness or -0.05
	local baseContrast = colorCorrection and colorCorrection.Contrast or 0.15

	local timeElapsed = 0
	local pulseSpeed = 0.15
	local pulseIntensity = 0.02

	RunService.RenderStepped:Connect(function(deltaTime)
		timeElapsed = timeElapsed + deltaTime

		if colorCorrection then
			local pulse = math.sin(timeElapsed * pulseSpeed) * pulseIntensity
			colorCorrection.Brightness = baseBrightness + pulse
			colorCorrection.Contrast = baseContrast + math.sin(timeElapsed * pulseSpeed * 0.7) * 0.01
		end

		if bloom then
			bloom.Intensity = 0.15 + math.sin(timeElapsed * pulseSpeed * 0.5) * 0.02
		end
	end)
end

-- -------------------------------------------------------------------------------
-- VIGNETTE EFFECT
-- -------------------------------------------------------------------------------

local function SetupVignetteEffect()
	local playerGui = player:WaitForChild("PlayerGui")

	local vignetteGui = Instance.new("ScreenGui")
	vignetteGui.Name = "VignetteEffect"
	vignetteGui.IgnoreGuiInset = true
	vignetteGui.DisplayOrder = 100
	vignetteGui.ResetOnSpawn = false
	vignetteGui.Parent = playerGui

	local vignetteFrame = Instance.new("Frame")
	vignetteFrame.Name = "Vignette"
	vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
	vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
	vignetteFrame.BackgroundTransparency = 1
	vignetteFrame.BorderSizePixel = 0
	vignetteFrame.Parent = vignetteGui

	local numLayers = 8
	for i = 1, numLayers do
		local layer = Instance.new("Frame")
		layer.Name = "VignetteLayer" ..i
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Position = UDim2.new(0.5, 0, 0.5, 0)

		local sizeMultiplier = 1 + (i / numLayers) * 0.5
		layer.Size = UDim2.new(sizeMultiplier, 0, sizeMultiplier, 0)

		layer.BackgroundColor3 = Color3.new(0, 0, 0)
		layer.BackgroundTransparency = 0.98 - (i / numLayers) * 0.08
		layer.BorderSizePixel = 0
		layer.Parent = vignetteFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = layer
	end

	local edgeDarkness = 0.15
	local edges = {
		{pos = UDim2.new(0, 0, 0, 0), size = UDim2.new(0.15, 0, 1, 0)},
		{pos = UDim2.new(0.85, 0, 0, 0), size = UDim2.new(0.15, 0, 1, 0)},
		{pos = UDim2.new(0, 0, 0, 0), size = UDim2.new(1, 0, 0.1, 0)},
		{pos = UDim2.new(0, 0, 0.9, 0), size = UDim2.new(1, 0, 0.1, 0)},
	}

	for idx, edge in ipairs(edges) do
		local edgeFrame = Instance.new("Frame")
		edgeFrame.Name = "Edge" ..idx
		edgeFrame.Position = edge.pos
		edgeFrame.Size = edge.size
		edgeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		edgeFrame.BackgroundTransparency = 0.92
		edgeFrame.BorderSizePixel = 0
		edgeFrame.Parent = vignetteFrame

		local gradient = Instance.new("UIGradient")
		if idx == 1 then
			gradient.Rotation = 0
		elseif idx == 2 then
			gradient.Rotation = 180
		elseif idx == 3 then
			gradient.Rotation = 90
		else
			gradient.Rotation = 270
		end
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		gradient.Parent = edgeFrame
	end

	local timeElapsed = 0
	RunService.RenderStepped:Connect(function(deltaTime)
		timeElapsed = timeElapsed + deltaTime

		local pulse = math.sin(timeElapsed * 0.3) * 0.02
		for i, layer in ipairs(vignetteFrame:GetChildren()) do
			if layer:IsA("Frame") and layer.Name: match("VignetteLayer") then
				local layerNum = tonumber(layer.Name:match("%d+"))
				if layerNum then
					local baseTransparency = 0.97 - (layerNum / numLayers) * 0.15
					layer.BackgroundTransparency = baseTransparency - pulse
				end
			end
		end
	end)
end

-- -------------------------------------------------------------------------------
-- SCREEN DUST EFFECT
-- -------------------------------------------------------------------------------

local function SetupScreenDustEffect()
	local playerGui = player:WaitForChild("PlayerGui")

	local dustGui = Instance.new("ScreenGui")
	dustGui.Name = "ScreenDust"
	dustGui.IgnoreGuiInset = true
	dustGui.DisplayOrder = 50
	dustGui.ResetOnSpawn = false
	dustGui.Parent = playerGui

	local dustContainer = Instance.new("Frame")
	dustContainer.Name = "DustContainer"
	dustContainer.Size = UDim2.new(1, 0, 1, 0)
	dustContainer.BackgroundTransparency = 1
	dustContainer.Parent = dustGui

	local function CreateDustParticle()
		local particle = Instance.new("Frame")
		particle.Name = "DustParticle"
		particle.Size = UDim2.new(0, math.random(1, 3), 0, math.random(1, 3))
		particle.Position = UDim2.new(math.random(), 0, -0.05, 0)
		particle.BackgroundColor3 = Color3.fromRGB(150, 145, 140)
		particle.BackgroundTransparency = 0.7 + math.random() * 0.25
		particle.BorderSizePixel = 0
		particle.Parent = dustContainer

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		local duration = math.random(8, 15)
		local startX = particle.Position.X.Scale
		local swayAmount = math.random() * 0.1
		local swaySpeed = math.random() * 2 + 1

		local startTime = tick()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			local progress = elapsed / duration

			if progress >= 1 then
				connection:Disconnect()
				particle: Destroy()
				return
			end

			local newY = -0.05 + progress * 1.1
			local sway = math.sin(elapsed * swaySpeed) * swayAmount * (1 - progress)
			local newX = startX + sway

			particle.Position = UDim2.new(newX, 0, newY, 0)
			particle.BackgroundTransparency = 0.7 + math.random() * 0.2 + progress * 0.1
		end)
	end

	task.spawn(function()
		while true do
			task.wait(math.random() * 0.5 + 0.2)
			if #dustContainer:GetChildren() < 20 then
				CreateDustParticle()
			end
		end
	end)
end

-- -------------------------------------------------------------------------------
-- MINIMAL UI
-- -------------------------------------------------------------------------------

local function SetupMinimalUI()
	local playerGui = player: WaitForChild("PlayerGui")

	local mainGui = Instance.new("ScreenGui")
	mainGui.Name = "GameUI"
	mainGui.IgnoreGuiInset = false
	mainGui.DisplayOrder = 10
	mainGui.ResetOnSpawn = false
	mainGui.Parent = playerGui

	local directionIndicator = Instance.new("Frame")
	directionIndicator.Name = "DirectionIndicator"
	directionIndicator.AnchorPoint = Vector2.new(0.5, 0)
	directionIndicator.Position = UDim2.new(0.5, 0, 0.02, 0)
	directionIndicator.Size = UDim2.new(0, 60, 0, 2)
	directionIndicator.BackgroundColor3 = Color3.fromRGB(100, 90, 80)
	directionIndicator.BackgroundTransparency = 0.7
	directionIndicator.BorderSizePixel = 0
	directionIndicator.Parent = mainGui

	local mysteryText = Instance.new("TextLabel")
	mysteryText.Name = "MysteryText"
	mysteryText.AnchorPoint = Vector2.new(0.5, 0.5)
	mysteryText.Position = UDim2.new(0.5, 0, 0.85, 0)
	mysteryText.Size = UDim2.new(0.8, 0, 0, 30)
	mysteryText.BackgroundTransparency = 1
	mysteryText.Text = ""
	mysteryText.TextColor3 = Color3.fromRGB(120, 110, 100)
	mysteryText.TextTransparency = 1
	mysteryText.Font = Enum.Font.Antique
	mysteryText.TextSize = 18
	mysteryText.Parent = mainGui

	local mysteriousMessages = {
		"Where are you going?",
		"There's no turning back...",
		"Someone is watching you.",
		"The road continues...",
		"Did you hear that?",
		"You're not alone.",
		"Keep walking.",
		"How far have you gone?",
		"The doors remain closed.",
		"The silence is deafening.",
		"Something moves in the shadows.",
		"Do you remember how you got here?",
		"The street has no end.",
		"Your footsteps echo.",
		"The windows watch you.",
	}

	task.spawn(function()
		task.wait(30)
		while true do
			task.wait(math.random(45, 120))

			local message = mysteriousMessages[math.random(1, #mysteriousMessages)]
			mysteryText.Text = message

			for i = 1, 20 do
				mysteryText.TextTransparency = 1 - (i / 20) * 0.6
				task.wait(0.05)
			end

			task.wait(4)

			for i = 1, 20 do
				mysteryText.TextTransparency = 0.4 + (i / 20) * 0.6
				task.wait(0.05)
			end

			mysteryText.Text = ""
		end
	end)
end

-- -------------------------------------------------------------------------------
-- TENSION EFFECTS
-- -------------------------------------------------------------------------------

local function SetupTensionEffects()
	local playerGui = player:WaitForChild("PlayerGui")

	local tensionGui = Instance.new("ScreenGui")
	tensionGui.Name = "TensionEffects"
	tensionGui.IgnoreGuiInset = true
	tensionGui.DisplayOrder = 90
	tensionGui.ResetOnSpawn = false
	tensionGui.Parent = playerGui

	local tensionOverlay = Instance.new("Frame")
	tensionOverlay.Name = "TensionOverlay"
	tensionOverlay.Size = UDim2.new(1, 0, 1, 0)
	tensionOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	tensionOverlay.BackgroundTransparency = 1
	tensionOverlay.BorderSizePixel = 0
	tensionOverlay.Parent = tensionGui

	task.spawn(function()
		while true do
			task.wait(math.random(60, 180))

			for i = 1, 30 do
				tensionOverlay.BackgroundTransparency = 1 - (math.sin(i / 30 * math.pi) * 0.15)
				task.wait(0.05)
			end
			tensionOverlay.BackgroundTransparency = 1
		end
	end)
end

-- -------------------------------------------------------------------------------
-- CHARACTER RECONNECTION
-- -------------------------------------------------------------------------------

local function SetupCharacterReconnection()
	player.CharacterAdded:Connect(function(newCharacter)
		character = newCharacter
		humanoid = character:WaitForChild("Humanoid")
		humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		-- Re-lock mouse on respawn
		task.wait(0.5)
		MouseController: Lock()
	end)
end

-- -------------------------------------------------------------------------------
-- INITIALIZATION
-- -------------------------------------------------------------------------------

local function Initialize()
	print("---------------------------------------------------------------")
	print("         INFINITE STREET - Client Effects V2 Initializing       ")
	print("---------------------------------------------------------------")

	repeat task.wait() until camera and humanoid and humanoidRootPart

	-- Setup first person and lock mouse FIRST
	SetupFirstPersonCamera()

	-- Setup effects
	SetupCameraEffects()
	SetupAmbientSounds()
	SetupDynamicPostProcessing()
	SetupVignetteEffect()
	SetupScreenDustEffect()
	SetupMinimalUI()
	SetupTensionEffects()
	SetupCharacterReconnection()

	print("---------------------------------------------------------------")
	print("         Client Effects V2 Ready - Mouse Control Active         ")
	print("---------------------------------------------------------------")
end

Initialize()