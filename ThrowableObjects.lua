-- -------------------------------------------------------------------------------
-- +------------------------------------------------------------------------------+
-- ¦                    THROWABLE CLIENT SCRIPT                                   ¦
-- ¦                    100% PRECISE AIMING - FIXED HEIGHT                        ¦
-- +-----------------???------------------------------------------------------------+
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game: GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for remotes
local ThrowableRemotes = ReplicatedStorage:WaitForChild("ThrowableRemotes", 15)
if not ThrowableRemotes then
	warn("ThrowableRemotes not found!  Throwable system disabled.")
	return
end

local PickupThrowableEvent = ThrowableRemotes: WaitForChild("PickupThrowable")
local ThrowObjectEvent = ThrowableRemotes: WaitForChild("ThrowObject")
local DropObjectEvent = ThrowableRemotes: WaitForChild("DropObject")

-- State variables
local isHolding = false
local holdStartTime = 0
local currentHeldObject = nil
local currentObjectType = nil

-- Power thresholds
local THROW_POWER = {
	LIGHT = {
		MAX_HOLD_TIME = 0.3,
		COLOR = Color3.fromRGB(100, 255, 100),
		NAME = "Light Throw",
	},
	MEDIUM = {
		MAX_HOLD_TIME = 0.8,
		COLOR = Color3.fromRGB(255, 255, 100),
		NAME = "Medium Throw",
	},
	STRONG = {
		MAX_HOLD_TIME = math.huge,
		COLOR = Color3.fromRGB(255, 100, 100),
		NAME = "Strong Throw",
	},
}

-- -------------------------------------------------------------------------------
-- PRECISE AIM - USE CAMERA DIRECTION DIRECTLY (EXACT CENTER OF SCREEN)
-- -------------------------------------------------------------------------------

local function GetPreciseAimDirection()
	-- Simply use the camera's look direction - this is EXACTLY where the dot points
	return camera.CFrame.LookVector
end

-- -------------------------------------------------------------------------------
-- UI CREATION
-- -------------------------------------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThrowableUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- -------------------------------------------------------------------------------
-- CENTER DOT (ALWAYS VISIBLE)
-- -------------------------------------------------------------------------------

local dotShadow = Instance.new("Frame")
dotShadow.Name = "DotShadow"
dotShadow.Size = UDim2.new(0, 6, 0, 6)
dotShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dotShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dotShadow.BackgroundColor3 = Color3.new(0, 0, 0)
dotShadow.BackgroundTransparency = 0.5
dotShadow.BorderSizePixel = 0
dotShadow.ZIndex = 1
dotShadow.Parent = screenGui

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(1, 0)
shadowCorner.Parent = dotShadow

local centerDot = Instance.new("Frame")
centerDot.Name = "CenterDot"
centerDot.Size = UDim2.new(0, 4, 0, 4)
centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
centerDot.BackgroundColor3 = Color3.new(1, 1, 1)
centerDot.BorderSizePixel = 0
centerDot.ZIndex = 2
centerDot.Parent = screenGui

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = centerDot

-- -------------------------------------------------------------------------------
-- HELD OBJECT INDICATOR
-- -------------------------------------------------------------------------------

local heldFrame = Instance.new("Frame")
heldFrame.Name = "HeldObjectFrame"
heldFrame.Size = UDim2.new(0, 220, 0, 55)
heldFrame.Position = UDim2.new(0.5, -110, 0, 80)
heldFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
heldFrame.BackgroundTransparency = 0.2
heldFrame.BorderSizePixel = 0
heldFrame.Visible = false
heldFrame.Parent = screenGui

local heldCorner = Instance.new("UICorner")
heldCorner.CornerRadius = UDim.new(0, 10)
heldCorner.Parent = heldFrame

local heldStroke = Instance.new("UIStroke")
heldStroke.Color = Color3.fromRGB(80, 80, 90)
heldStroke.Thickness = 2
heldStroke.Parent = heldFrame

local heldIcon = Instance.new("TextLabel")
heldIcon.Name = "HeldIcon"
heldIcon.Size = UDim2.new(0, 40, 0, 40)
heldIcon.Position = UDim2.new(0, 8, 0.5, -20)
heldIcon.BackgroundTransparency = 1
heldIcon.Text = "??"
heldIcon.TextScaled = true
heldIcon.Font = Enum.Font.GothamBold
heldIcon.Parent = heldFrame

local heldText = Instance.new("TextLabel")
heldText.Name = "HeldText"
heldText.Size = UDim2.new(1, -55, 0, 25)
heldText.Position = UDim2.new(0, 50, 0, 5)
heldText.BackgroundTransparency = 1
heldText.Text = "Holding:  Brick"
heldText.TextColor3 = Color3.new(1, 1, 1)
heldText.TextScaled = true
heldText.TextXAlignment = Enum.TextXAlignment.Left
heldText.Font = Enum.Font.GothamBold
heldText.Parent = heldFrame

local instructionText = Instance.new("TextLabel")
instructionText.Name = "InstructionText"
instructionText.Size = UDim2.new(1, -55, 0, 18)
instructionText.Position = UDim2.new(0, 50, 0, 30)
instructionText.BackgroundTransparency = 1
instructionText.Text = "[Hold LMB] Throw  •  [Q] Drop"
instructionText.TextColor3 = Color3.fromRGB(150, 150, 160)
instructionText.TextScaled = true
instructionText.TextXAlignment = Enum.TextXAlignment.Left
instructionText.Font = Enum.Font.Gotham
instructionText.Parent = heldFrame

-- -------------------------------------------------------------------------------
-- POWER METER
-- -------------------------------------------------------------------------------

local powerFrame = Instance.new("Frame")
powerFrame.Name = "PowerFrame"
powerFrame.Size = UDim2.new(0, 280, 0, 35)
powerFrame.Position = UDim2.new(0.5, -140, 0.5, 60)
powerFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
powerFrame.BackgroundTransparency = 0.1
powerFrame.BorderSizePixel = 0
powerFrame.Visible = false
powerFrame.Parent = screenGui

local powerCorner = Instance.new("UICorner")
powerCorner.CornerRadius = UDim.new(0, 8)
powerCorner.Parent = powerFrame

local powerStroke = Instance.new("UIStroke")
powerStroke.Color = Color3.fromRGB(60, 60, 70)
powerStroke.Thickness = 2
powerStroke.Parent = powerFrame

local powerBarBG = Instance.new("Frame")
powerBarBG.Name = "PowerBarBG"
powerBarBG.Size = UDim2.new(1, -10, 0, 12)
powerBarBG.Position = UDim2.new(0, 5, 0, 5)
powerBarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
powerBarBG.BorderSizePixel = 0
powerBarBG.Parent = powerFrame

local powerBarBGCorner = Instance.new("UICorner")
powerBarBGCorner.CornerRadius = UDim.new(0, 4)
powerBarBGCorner.Parent = powerBarBG

local powerBar = Instance.new("Frame")
powerBar.Name = "PowerBar"
powerBar.Size = UDim2.new(0, 0, 1, 0)
powerBar.Position = UDim2.new(0, 0, 0, 0)
powerBar.BackgroundColor3 = THROW_POWER.LIGHT.COLOR
powerBar.BorderSizePixel = 0
powerBar.Parent = powerBarBG

local powerBarCorner = Instance.new("UICorner")
powerBarCorner.CornerRadius = UDim.new(0, 4)
powerBarCorner.Parent = powerBar

local powerLabel = Instance.new("TextLabel")
powerLabel.Name = "PowerLabel"
powerLabel.Size = UDim2.new(1, 0, 0, 15)
powerLabel.Position = UDim2.new(0, 0, 0, 17)
powerLabel.BackgroundTransparency = 1
powerLabel.Text = "Light Throw"
powerLabel.TextColor3 = Color3.new(1, 1, 1)
powerLabel.TextScaled = true
powerLabel.Font = Enum.Font.GothamBlack
powerLabel.TextStrokeTransparency = 0.7
powerLabel.Parent = powerFrame

local markerLight = Instance.new("Frame")
markerLight.Size = UDim2.new(0, 2, 1, 4)
markerLight.Position = UDim2.new(0.33, 0, 0, -2)
markerLight.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
markerLight.BorderSizePixel = 0
markerLight.Parent = powerBarBG

local markerMedium = Instance.new("Frame")
markerMedium.Size = UDim2.new(0, 2, 1, 4)
markerMedium.Position = UDim2.new(0.66, 0, 0, -2)
markerMedium.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
markerMedium.BorderSizePixel = 0
markerMedium.Parent = powerBarBG

-- ----------------------------??--------------------------------------------------
-- POWER CALCULATION
-- -------------------------------------------------------------------------------

local function GetCurrentPower(holdTime)
	if holdTime <= THROW_POWER.LIGHT.MAX_HOLD_TIME then
		return THROW_POWER.LIGHT
	elseif holdTime <= THROW_POWER.MEDIUM.MAX_HOLD_TIME then
		return THROW_POWER.MEDIUM
	else
		return THROW_POWER.STRONG
	end
end

local function UpdatePowerMeter(holdTime)
	local power = GetCurrentPower(holdTime)

	local totalProgress
	if holdTime <= THROW_POWER.LIGHT.MAX_HOLD_TIME then
		totalProgress = (holdTime / THROW_POWER.LIGHT.MAX_HOLD_TIME) * 0.33
	elseif holdTime <= THROW_POWER.MEDIUM.MAX_HOLD_TIME then
		totalProgress = 0.33 + ((holdTime - THROW_POWER.LIGHT.MAX_HOLD_TIME) / (THROW_POWER.MEDIUM.MAX_HOLD_TIME - THROW_POWER.LIGHT.MAX_HOLD_TIME)) * 0.33
	else
		local extraTime = math.min(holdTime - THROW_POWER.MEDIUM.MAX_HOLD_TIME, 0.5)
		totalProgress = 0.66 + (extraTime / 0.5) * 0.34
	end

	totalProgress = math.clamp(totalProgress, 0, 1)

	powerBar.Size = UDim2.new(totalProgress, 0, 1, 0)
	powerBar.BackgroundColor3 = power.COLOR
	powerLabel.Text = power.NAME
	heldStroke.Color = power.COLOR
	centerDot.BackgroundColor3 = power.COLOR
end

-- -------------------------------------------------------------------------------
-- INPUT HANDLING
-- -------------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not currentHeldObject then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isHolding = true
		holdStartTime = tick()
		powerFrame.Visible = true
		powerBar.Size = UDim2.new(0, 0, 1, 0)

	elseif input.KeyCode == Enum.KeyCode.Q then
		DropObjectEvent:FireServer()
		currentHeldObject = nil
		currentObjectType = nil
		heldFrame.Visible = false
		powerFrame.Visible = false
		isHolding = false
		centerDot.BackgroundColor3 = Color3.new(1, 1, 1)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if not currentHeldObject then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and isHolding then
		isHolding = false
		local holdTime = tick() - holdStartTime

		-- GET CAMERA LOOK DIRECTION (exactly where dot points)
		local aimDirection = GetPreciseAimDirection()

		-- Send to server
		ThrowObjectEvent:FireServer(holdTime, aimDirection)

		-- Reset UI
		currentHeldObject = nil
		currentObjectType = nil
		heldFrame.Visible = false
		powerFrame.Visible = false
		powerBar.Size = UDim2.new(0, 0, 1, 0)
		heldStroke.Color = Color3.fromRGB(80, 80, 90)
		centerDot.BackgroundColor3 = Color3.new(1, 1, 1)
	end
end)

RunService.RenderStepped:Connect(function()
	if isHolding and currentHeldObject then
		local holdTime = tick() - holdStartTime
		UpdatePowerMeter(holdTime)
	end
end)

-- -------------------------------------------------------------------------------
-- PICKUP EVENT
-- -------------------------------------------------------------------------------

PickupThrowableEvent.OnClientEvent:Connect(function(objectType, objectName)
	currentHeldObject = true
	currentObjectType = objectType

	heldText.Text = "Holding: " ..objectName
	heldIcon.Text = objectType == "BOTTLE" and "??" or "??"

	heldFrame.Visible = true
	heldFrame.Position = UDim2.new(0.5, -110, 0, 40)
	heldFrame.BackgroundTransparency = 1

	TweenService:Create(heldFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -110, 0, 80),
		BackgroundTransparency = 0.2
	}):Play()
end)

-- -------------------------------------------------------------------------------
-- CLEANUP
-- -------------------------------------------------------------------------------

player.CharacterAdded:Connect(function()
	currentHeldObject = nil
	currentObjectType = nil
	isHolding = false
	heldFrame.Visible = false
	powerFrame.Visible = false
	powerBar.Size = UDim2.new(0, 0, 1, 0)
	centerDot.BackgroundColor3 = Color3.new(1, 1, 1)
end)

print("? Throwable Client - PRECISE AIMING READY")