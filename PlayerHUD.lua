--[[
    +------------------------------------------------------------------------------+
    ¦                 ULTIMATE PLAYER HUD V11 (BOOST TIMER DISPLAY)                 ¦
    ¦         Shows remaining boost time, prevents stacking                         ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- -------------------------------------------------------------------------------
-- WAIT FOR CHARACTER SAFELY
-- -------------------------------------------------------------------------------

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 10)

-- -------------------------------------------------------------------------------
-- WAIT FOR REMOTE EVENTS
-- -------------------------------------------------------------------------------

local function WaitForRemote(parent, name, timeout)
	local remote = parent:WaitForChild(name, timeout or 10)
	if not remote then
		warn("[HUD] Could not find remote: " ..name)
	end
	return remote
end

local CurrencyRemotes = ReplicatedStorage:WaitForChild("CurrencyRemotes", 15)

local UpdateCurrencyEvent, SyncDataEvent, UseItemEvent, DoorOpenedEvent, SurvivedDoorEvent, BoostUpdateEvent

if CurrencyRemotes then
	UpdateCurrencyEvent = WaitForRemote(CurrencyRemotes, "UpdateCurrency")
	SyncDataEvent = WaitForRemote(CurrencyRemotes, "SyncData")
	UseItemEvent = WaitForRemote(CurrencyRemotes, "UseItem")
	DoorOpenedEvent = WaitForRemote(CurrencyRemotes, "DoorOpened")
	SurvivedDoorEvent = WaitForRemote(CurrencyRemotes, "SurvivedDoor")
	BoostUpdateEvent = WaitForRemote(CurrencyRemotes, "BoostUpdate") -- NEW
else
	warn("[HUD] CurrencyRemotes folder not found!")
end

-- -------------------------------------------------------------------------------
-- CONFIGURATION
-- -------------------------------------------------------------------------------
local CONFIG = {
	WALK_SPEED = 16,
	RUN_SPEED = 30,
	MAX_STAMINA = 100,
	STAMINA_DRAIN = 25,
	STAMINA_REGEN = 15,
	REGEN_DELAY = 1.5,
	JUMP_COST = 5,
	CRITICAL_HEALTH_PCT = 0.25,
	LOW_STAMINA_PCT = 0.2,
	COLOR_HEALTH_OK = Color3.fromRGB(80, 255, 120),
	COLOR_HEALTH_LOW = Color3.fromRGB(255, 40, 40),
	COLOR_HEALTH_REGEN = Color3.fromRGB(150, 255, 180),
	COLOR_HEALTH_HEAL = Color3.fromRGB(100, 255, 200),
	COLOR_STAMINA_OK = Color3.fromRGB(80, 220, 255),
	COLOR_STAMINA_LOW = Color3.fromRGB(255, 150, 50),
	COLOR_STAMINA_BOOST = Color3.fromRGB(100, 255, 255),
	COLOR_SPEED_BOOST = Color3.fromRGB(255, 200, 100),
	COLOR_USD = Color3.fromRGB(100, 255, 100),
	BLOOD_IMAGE_ID = "rbxassetid://6000224965",
	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

-- -------------------------------------------------------------------------------
-- STATE VARIABLES
-- -------------------------------------------------------------------------------

local currentStamina = CONFIG.MAX_STAMINA
local isTryingToSprint = false
local canSprint = true
local lastSprintTime = 0

-- BOOST TRACKING (synced from server)
local staminaBoostActive = false
local staminaBoostEndTime = 0
local speedBoostActive = false
local speedBoostEndTime = 0

local playerUSD = 0
local playerInventory = {}

local isInLobby = false
local previousHealth = 100
local isRegenerating = false
local justHealed = false
local healFlashEndTime = 0

local ui = {
	healthFill = nil,
	staminaFill = nil,
	healthContainer = nil,
	bloodOverlay = nil,
	sprintIcon = nil,
	usdLabel = nil,
	inventoryFrame = nil,
	notificationFrame = nil,
	lobbyIndicator = nil,
	-- NEW:  Boost indicators
	boostContainer = nil,
	staminaBoostIndicator = nil,
	staminaBoostTimer = nil,
	speedBoostIndicator = nil,
	speedBoostTimer = nil,
}

local hudReady = false

-- -------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-- -------------------------------------------------------------------------------

local function CheckIfPlayerInLobby()
	if not character or not character.Parent then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	return hrp.Position.X >= CONFIG.LOBBY_START_X and hrp.Position.X <= CONFIG.LOBBY_END_X
end

local function FormatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	if mins > 0 then
		return string.format("%d:%02d", mins, secs)
	else
		return string.format("%ds", secs)
	end
end

-- -------------------------------------------------------------------------------
-- ITEMS CONFIG
-- -------------------------------------------------------------------------------

local ITEMS = {
	{id = "bandage", name = "Bandage", icon = "??", type = "heal", value = 20},
	{id = "medkit", name = "Med Kit", icon = "??", type = "heal", value = 50},
	{id = "adrenaline", name = "Adrenaline", icon = "??", type = "heal", value = 100},
	{id = "energy_drink", name = "Energy Drink", icon = "??", type = "stamina_boost", duration = 30},
	{id = "super_energy", name = "Super Energy", icon = "?", type = "stamina_boost", duration = 60},
	{id = "ultra_boost", name = "Ultra Boost", icon = "??", type = "stamina_boost", duration = 120},
	{id = "speed_pill", name = "Speed Pill", icon = "??", type = "speed_boost", value = 1.5, duration = 20},
	{id = "turbo_boots", name = "Turbo Boots", icon = "??", type = "speed_boost", value = 2.0, duration = 15},
}

local function GetItemById(itemId)
	for _, item in ipairs(ITEMS) do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

-- -------------------------------------------------------------------------------
-- NOTIFICATIONS
-- -------------------------------------------------------------------------------

local function ShowNotification(text, color, duration)
	if not ui.notificationFrame then return end

	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(1, 0, 0, 30)
	notif.Position = UDim2.new(0, 0, 1, 0)
	notif.BackgroundTransparency = 0.3
	notif.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	notif.BorderSizePixel = 0
	notif.Text = text
	notif.TextColor3 = color or Color3.new(1, 1, 1)
	notif.TextScaled = true
	notif.Font = Enum.Font.GothamBold
	notif.Parent = ui.notificationFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = notif

	TweenService:Create(notif, TweenInfo.new(0.3), {
		Position = UDim2.new(0, 0, 0, -#ui.notificationFrame:GetChildren() * 35)
	}):Play()

	task.delay(duration or 3, function()
		TweenService:Create(notif, TweenInfo.new(0.5), {
			Position = UDim2.new(1, 50, 0, notif.Position.Y.Offset),
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()
		task.wait(0.6)
		if notif and notif.Parent then
			notif:Destroy()
		end
	end)
end

-- ----??--------------------------------------------------------------------------
-- CREATE HUD
-- -------------------------------------------------------------------------------

local function CreateHUD()
	local playerGui = player:WaitForChild("PlayerGui")

	if playerGui:FindFirstChild("UltimateHUD") then
		playerGui.UltimateHUD:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "UltimateHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- BLOOD EFFECT
	local blood = Instance.new("ImageLabel")
	blood.Name = "BloodOverlay"
	blood.Size = UDim2.new(1, 0, 1, 0)
	blood.BackgroundTransparency = 1
	blood.Image = CONFIG.BLOOD_IMAGE_ID
	blood.ImageColor3 = Color3.new(0.6, 0, 0)
	blood.ImageTransparency = 1
	blood.ScaleType = Enum.ScaleType.Stretch
	blood.ZIndex = 0
	blood.Parent = gui
	ui.bloodOverlay = blood

	-- MAIN CONTAINER
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "StatsContainer"
	mainFrame.Size = UDim2.new(0, 240, 0, 100)
	mainFrame.Position = UDim2.new(0, 25, 1, -125)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = gui

	local function CreateBar(name, posY, height, color, labelText)
		local bg = Instance.new("Frame")
		bg.Name = name .."BG"
		bg.Size = UDim2.new(1, 0, 0, height)
		bg.Position = UDim2.new(0, 0, 0, posY)
		bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		bg.BorderSizePixel = 0
		bg.Parent = mainFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = bg

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = bg

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(1, 0, 1, 0)
		fill.BackgroundColor3 = color
		fill.BorderSizePixel = 0
		fill.Parent = bg

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 4)
		fillCorner.Parent = fill

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0, 50, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = labelText
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 10
		label.TextTransparency = 0.4
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 2
		label.Parent = bg

		return fill, bg
	end

	local hFill, hCont = CreateBar("Health", 0, 16, CONFIG.COLOR_HEALTH_OK, "HP")
	ui.healthFill = hFill
	ui.healthContainer = hCont

	local sFill, sCont = CreateBar("Stamina", 22, 8, CONFIG.COLOR_STAMINA_OK, "STM")
	ui.staminaFill = sFill

	-- USD Display
	local usdFrame = Instance.new("Frame")
	usdFrame.Name = "USDFrame"
	usdFrame.Size = UDim2.new(1, 0, 0, 24)
	usdFrame.Position = UDim2.new(0, 0, 0, 38)
	usdFrame.BackgroundColor3 = Color3.fromRGB(20, 35, 20)
	usdFrame.BorderSizePixel = 0
	usdFrame.Parent = mainFrame

	local usdCorner = Instance.new("UICorner")
	usdCorner.CornerRadius = UDim.new(0, 4)
	usdCorner.Parent = usdFrame

	local usdLabel = Instance.new("TextLabel")
	usdLabel.Name = "USDLabel"
	usdLabel.Size = UDim2.new(1, -10, 1, 0)
	usdLabel.Position = UDim2.new(0, 5, 0, 0)
	usdLabel.BackgroundTransparency = 1
	usdLabel.Text = "?? $0 USD"
	usdLabel.TextColor3 = CONFIG.COLOR_USD
	usdLabel.TextScaled = true
	usdLabel.Font = Enum.Font.GothamBold
	usdLabel.TextXAlignment = Enum.TextXAlignment.Left
	usdLabel.Parent = usdFrame
	ui.usdLabel = usdLabel

	-- ---------------------------------------------------------------------------
	-- BOOST INDICATORS (NEW!)
	-- ---------------------------------------------------------------------------

	local boostContainer = Instance.new("Frame")
	boostContainer.Name = "BoostContainer"
	boostContainer.Size = UDim2.new(0, 240, 0, 50)
	boostContainer.Position = UDim2.new(0, 0, 0, 68)
	boostContainer.BackgroundTransparency = 1
	boostContainer.Parent = mainFrame
	ui.boostContainer = boostContainer

	local boostLayout = Instance.new("UIListLayout")
	boostLayout.FillDirection = Enum.FillDirection.Vertical
	boostLayout.Padding = UDim.new(0, 4)
	boostLayout.Parent = boostContainer

	-- Stamina Boost Indicator
	local staminaBoostFrame = Instance.new("Frame")
	staminaBoostFrame.Name = "StaminaBoostIndicator"
	staminaBoostFrame.Size = UDim2.new(1, 0, 0, 22)
	staminaBoostFrame.BackgroundColor3 = Color3.fromRGB(20, 50, 55)
	staminaBoostFrame.BorderSizePixel = 0
	staminaBoostFrame.Visible = false
	staminaBoostFrame.Parent = boostContainer
	ui.staminaBoostIndicator = staminaBoostFrame

	local staminaBoostCorner = Instance.new("UICorner")
	staminaBoostCorner.CornerRadius = UDim.new(0, 4)
	staminaBoostCorner.Parent = staminaBoostFrame

	local staminaBoostStroke = Instance.new("UIStroke")
	staminaBoostStroke.Color = CONFIG.COLOR_STAMINA_BOOST
	staminaBoostStroke.Thickness = 1
	staminaBoostStroke.Transparency = 0.5
	staminaBoostStroke.Parent = staminaBoostFrame

	local staminaBoostIcon = Instance.new("TextLabel")
	staminaBoostIcon.Size = UDim2.new(0, 22, 1, 0)
	staminaBoostIcon.Position = UDim2.new(0, 2, 0, 0)
	staminaBoostIcon.BackgroundTransparency = 1
	staminaBoostIcon.Text = "?"
	staminaBoostIcon.TextScaled = true
	staminaBoostIcon.Parent = staminaBoostFrame

	local staminaBoostLabel = Instance.new("TextLabel")
	staminaBoostLabel.Size = UDim2.new(0, 100, 1, 0)
	staminaBoostLabel.Position = UDim2.new(0, 26, 0, 0)
	staminaBoostLabel.BackgroundTransparency = 1
	staminaBoostLabel.Text = "NO STAMINA COST"
	staminaBoostLabel.TextColor3 = CONFIG.COLOR_STAMINA_BOOST
	staminaBoostLabel.TextScaled = true
	staminaBoostLabel.Font = Enum.Font.GothamBold
	staminaBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
	staminaBoostLabel.Parent = staminaBoostFrame

	local staminaBoostTimer = Instance.new("TextLabel")
	staminaBoostTimer.Name = "Timer"
	staminaBoostTimer.Size = UDim2.new(0, 50, 1, 0)
	staminaBoostTimer.Position = UDim2.new(1, -55, 0, 0)
	staminaBoostTimer.BackgroundTransparency = 1
	staminaBoostTimer.Text = "0s"
	staminaBoostTimer.TextColor3 = Color3.new(1, 1, 1)
	staminaBoostTimer.TextScaled = true
	staminaBoostTimer.Font = Enum.Font.GothamBold
	staminaBoostTimer.TextXAlignment = Enum.TextXAlignment.Right
	staminaBoostTimer.Parent = staminaBoostFrame
	ui.staminaBoostTimer = staminaBoostTimer

	-- Speed Boost Indicator
	local speedBoostFrame = Instance.new("Frame")
	speedBoostFrame.Name = "SpeedBoostIndicator"
	speedBoostFrame.Size = UDim2.new(1, 0, 0, 22)
	speedBoostFrame.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
	speedBoostFrame.BorderSizePixel = 0
	speedBoostFrame.Visible = false
	speedBoostFrame.Parent = boostContainer
	ui.speedBoostIndicator = speedBoostFrame

	local speedBoostCorner = Instance.new("UICorner")
	speedBoostCorner.CornerRadius = UDim.new(0, 4)
	speedBoostCorner.Parent = speedBoostFrame

	local speedBoostStroke = Instance.new("UIStroke")
	speedBoostStroke.Color = CONFIG.COLOR_SPEED_BOOST
	speedBoostStroke.Thickness = 1
	speedBoostStroke.Transparency = 0.5
	speedBoostStroke.Parent = speedBoostFrame

	local speedBoostIcon = Instance.new("TextLabel")
	speedBoostIcon.Size = UDim2.new(0, 22, 1, 0)
	speedBoostIcon.Position = UDim2.new(0, 2, 0, 0)
	speedBoostIcon.BackgroundTransparency = 1
	speedBoostIcon.Text = "??"
	speedBoostIcon.TextScaled = true
	speedBoostIcon.Parent = speedBoostFrame

	local speedBoostLabel = Instance.new("TextLabel")
	speedBoostLabel.Size = UDim2.new(0, 100, 1, 0)
	speedBoostLabel.Position = UDim2.new(0, 26, 0, 0)
	speedBoostLabel.BackgroundTransparency = 1
	speedBoostLabel.Text = "SPEED BOOST"
	speedBoostLabel.TextColor3 = CONFIG.COLOR_SPEED_BOOST
	speedBoostLabel.TextScaled = true
	speedBoostLabel.Font = Enum.Font.GothamBold
	speedBoostLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedBoostLabel.Parent = speedBoostFrame

	local speedBoostTimer = Instance.new("TextLabel")
	speedBoostTimer.Name = "Timer"
	speedBoostTimer.Size = UDim2.new(0, 50, 1, 0)
	speedBoostTimer.Position = UDim2.new(1, -55, 0, 0)
	speedBoostTimer.BackgroundTransparency = 1
	speedBoostTimer.Text = "0s"
	speedBoostTimer.TextColor3 = Color3.new(1, 1, 1)
	speedBoostTimer.TextScaled = true
	speedBoostTimer.Font = Enum.Font.GothamBold
	speedBoostTimer.TextXAlignment = Enum.TextXAlignment.Right
	speedBoostTimer.Parent = speedBoostFrame
	ui.speedBoostTimer = speedBoostTimer

	-- LOBBY INDICATOR (moved below boosts)
	local lobbyFrame = Instance.new("Frame")
	lobbyFrame.Name = "LobbyIndicator"
	lobbyFrame.Size = UDim2.new(1, 0, 0, 20)
	lobbyFrame.BackgroundColor3 = Color3.fromRGB(30, 80, 50)
	lobbyFrame.BorderSizePixel = 0
	lobbyFrame.Visible = false
	lobbyFrame.Parent = boostContainer
	ui.lobbyIndicator = lobbyFrame

	local lobbyCorner = Instance.new("UICorner")
	lobbyCorner.CornerRadius = UDim.new(0, 4)
	lobbyCorner.Parent = lobbyFrame

	local lobbyLabel = Instance.new("TextLabel")
	lobbyLabel.Name = "LobbyLabel"
	lobbyLabel.Size = UDim2.new(1, -10, 1, 0)
	lobbyLabel.Position = UDim2.new(0, 5, 0, 0)
	lobbyLabel.BackgroundTransparency = 1
	lobbyLabel.Text = "?? SAFE ZONE - Regenerating"
	lobbyLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
	lobbyLabel.TextScaled = true
	lobbyLabel.Font = Enum.Font.GothamBold
	lobbyLabel.TextXAlignment = Enum.TextXAlignment.Left
	lobbyLabel.Parent = lobbyFrame

	-- Quick Inventory (Hotbar)
	local invFrame = Instance.new("Frame")
	invFrame.Name = "InventoryHotbar"
	invFrame.Size = UDim2.new(0, 340, 0, 55)
	invFrame.Position = UDim2.new(0.5, -170, 1, -65)
	invFrame.BackgroundTransparency = 1
	invFrame.Parent = gui
	ui.inventoryFrame = invFrame

	local invLayout = Instance.new("UIListLayout")
	invLayout.FillDirection = Enum.FillDirection.Horizontal
	invLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	invLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	invLayout.Padding = UDim.new(0, 5)
	invLayout.SortOrder = Enum.SortOrder.LayoutOrder
	invLayout.Parent = invFrame

	-- Notifications
	local notifFrame = Instance.new("Frame")
	notifFrame.Name = "Notifications"
	notifFrame.Size = UDim2.new(0, 300, 0, 150)
	notifFrame.Position = UDim2.new(0.5, -150, 0, 50)
	notifFrame.BackgroundTransparency = 1
	notifFrame.Parent = gui
	ui.notificationFrame = notifFrame

	-- Mobile sprint button
	if UserInputService.TouchEnabled then
		local btn = Instance.new("ImageButton")
		btn.Name = "MobileSprint"
		btn.Size = UDim2.new(0, 60, 0, 60)
		btn.Position = UDim2.new(1, -80, 1, -200)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		btn.BackgroundTransparency = 0.5
		btn.Image = "rbxassetid://14703440150"
		btn.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = btn

		btn.MouseButton1Down:Connect(function() isTryingToSprint = true end)
		btn.MouseButton1Up:Connect(function() isTryingToSprint = false end)

		ui.sprintIcon = btn
	end

	hudReady = true
	print("? [HUD] V11 Created Successfully")
end

-- -------------------------------------------------------------------------------
-- UPDATE INVENTORY UI
-- -------------------------------------------------------------------------------

local function UpdateInventoryUI()
	if not ui.inventoryFrame then return end

	for _, child in pairs(ui.inventoryFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for slotIndex, slotData in ipairs(playerInventory) do
		if slotIndex > 6 then break end

		local itemId = slotData.itemId
		local quantity = slotData.quantity

		if quantity > 0 then
			local item = GetItemById(itemId)
			if item then
				local slot = Instance.new("Frame")
				slot.Name = "Slot_" ..slotIndex
				slot.Size = UDim2.new(0, 52, 0, 52)
				slot.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
				slot.BorderSizePixel = 0
				slot.LayoutOrder = slotIndex
				slot.Parent = ui.inventoryFrame

				local slotCorner = Instance.new("UICorner")
				slotCorner.CornerRadius = UDim.new(0, 8)
				slotCorner.Parent = slot

				local slotStroke = Instance.new("UIStroke")
				slotStroke.Color = Color3.fromRGB(80, 80, 90)
				slotStroke.Thickness = 2
				slotStroke.Parent = slot

				local icon = Instance.new("TextLabel")
				icon.Name = "Icon"
				icon.Size = UDim2.new(1, 0, 0.65, 0)
				icon.Position = UDim2.new(0, 0, 0.05, 0)
				icon.BackgroundTransparency = 1
				icon.Text = item.icon
				icon.TextScaled = true
				icon.Parent = slot

				local qty = Instance.new("TextLabel")
				qty.Name = "Quantity"
				qty.Size = UDim2.new(1, -4, 0.3, 0)
				qty.Position = UDim2.new(0, 2, 0.68, 0)
				qty.BackgroundTransparency = 1
				qty.Text = "x" ..quantity
				qty.TextColor3 = Color3.new(1, 1, 1)
				qty.TextScaled = true
				qty.Font = Enum.Font.GothamBold
				qty.Parent = slot

				local keyLabel = Instance.new("TextLabel")
				keyLabel.Name = "KeyLabel"
				keyLabel.Size = UDim2.new(0, 16, 0, 16)
				keyLabel.Position = UDim2.new(0, 2, 0, 2)
				keyLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
				keyLabel.Text = tostring(slotIndex)
				keyLabel.TextColor3 = Color3.new(1, 1, 1)
				keyLabel.TextScaled = true
				keyLabel.Font = Enum.Font.GothamBold
				keyLabel.Parent = slot

				local keyCorner = Instance.new("UICorner")
				keyCorner.CornerRadius = UDim.new(0, 4)
				keyCorner.Parent = keyLabel

				local btn = Instance.new("TextButton")
				btn.Name = "UseButton"
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = slot

				local capturedItemId = itemId

				btn.MouseButton1Click:Connect(function()
					if UseItemEvent then
						UseItemEvent: FireServer(capturedItemId)
					end
				end)

				btn.MouseEnter:Connect(function()
					TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
					TweenService:Create(slotStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(120, 120, 140)}):Play()
				end)

				btn.MouseLeave:Connect(function()
					TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
					TweenService:Create(slotStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(80, 80, 90)}):Play()
				end)
			end
		end
	end
end

-- -------------------------------------------------------------------------------
-- UPDATE BOOST INDICATORS
-- ---------------------------------------???---------------------------------------

local function UpdateBoostIndicators()
	if not ui.staminaBoostIndicator or not ui.speedBoostIndicator then return end

	local now = tick()

	-- Stamina Boost
	local staminaRemaining = staminaBoostEndTime - now
	if staminaRemaining > 0 then
		staminaBoostActive = true
		ui.staminaBoostIndicator.Visible = true
		ui.staminaBoostTimer.Text = FormatTime(staminaRemaining)

		-- Pulse effect when low time
		if staminaRemaining <= 5 then
			local pulse = (math.sin(now * 8) + 1) / 2
			ui.staminaBoostIndicator.BackgroundColor3 = Color3.fromRGB(20, 50, 55):Lerp(Color3.fromRGB(60, 30, 30), pulse)
		else
			ui.staminaBoostIndicator.BackgroundColor3 = Color3.fromRGB(20, 50, 55)
		end
	else
		if staminaBoostActive then
			staminaBoostActive = false
			ShowNotification("? Stamina boost ended", Color3.fromRGB(150, 150, 150), 2)
		end
		ui.staminaBoostIndicator.Visible = false
	end

	-- Speed Boost
	local speedRemaining = speedBoostEndTime - now
	if speedRemaining > 0 then
		speedBoostActive = true
		ui.speedBoostIndicator.Visible = true
		ui.speedBoostTimer.Text = FormatTime(speedRemaining)

		-- Pulse effect when low time
		if speedRemaining <= 5 then
			local pulse = (math.sin(now * 8) + 1) / 2
			ui.speedBoostIndicator.BackgroundColor3 = Color3.fromRGB(50, 40, 20):Lerp(Color3.fromRGB(60, 30, 30), pulse)
		else
			ui.speedBoostIndicator.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
		end
	else
		if speedBoostActive then
			speedBoostActive = false
			ShowNotification("?? Speed boost ended", Color3.fromRGB(150, 150, 150), 2)
		end
		ui.speedBoostIndicator.Visible = false
	end
end

-- -------------------------------------------------------------------------------
-- APPLY CLIENT-SIDE ITEM EFFECTS
-- -------------------------------------------------------------------------------

local function ApplyClientItemEffect(item)
	if not item then return end

	if item.type == "heal" then
		justHealed = true
		healFlashEndTime = tick() + 1.5
		ShowNotification("?? +" ..item.value .."% HP", Color3.fromRGB(100, 255, 100), 2)

	elseif item.type == "stamina_boost" then
		-- Server controls the timing, we just set the end time
		staminaBoostEndTime = tick() + item.duration
		staminaBoostActive = true
		currentStamina = CONFIG.MAX_STAMINA
		ShowNotification("? No stamina cost for " ..item.duration .."s", Color3.fromRGB(100, 255, 255), 3)

	elseif item.type == "speed_boost" then
		-- Server controls the timing, we just set the end time
		speedBoostEndTime = tick() + item.duration
		speedBoostActive = true
		ShowNotification("?? +" ..math.floor((item.value - 1) * 100) .."% speed for " ..item.duration .."s", Color3.fromRGB(255, 200, 100), 3)
	end
end

-- -------------------------------------------------------------------------------
-- UPDATE LOBBY STATUS
-- -------------------------------------------------------------------------------

local function UpdateLobbyStatus()
	if not humanoid or humanoid.Health <= 0 then return end

	local wasInLobby = isInLobby
	isInLobby = CheckIfPlayerInLobby()

	local currentHealth = humanoid.Health
	local needsHealing = currentHealth < humanoid.MaxHealth

	local healthIncreased = currentHealth > previousHealth + 0.1
	isRegenerating = healthIncreased and isInLobby and not justHealed

	previousHealth = currentHealth

	if ui.lobbyIndicator then
		ui.lobbyIndicator.Visible = isInLobby and needsHealing
	end

	if isInLobby and not wasInLobby then
		if needsHealing then
			ShowNotification("?? Entered Safe Zone - Health will regenerate", Color3.fromRGB(100, 255, 150), 3)
		else
			ShowNotification("?? Entered Safe Zone", Color3.fromRGB(100, 255, 150), 2)
		end
	elseif not isInLobby and wasInLobby then
		ShowNotification("?? Left Safe Zone - Use items to heal", Color3.fromRGB(255, 200, 100), 3)
	end
end

-- -------------------------------------------------------------------------------
-- SPRINT AND STAMINA LOGIC
-- -------------------------------------------------------------------------------

local function UpdateStamina(dt)
	if not humanoid or humanoid.Health <= 0 then return end

	-- Check heal flash expiration
	if justHealed and tick() >= healFlashEndTime then
		justHealed = false
	end

	local isMoving = humanoid.MoveDirection.Magnitude > 0.1
	local currentSpeed = humanoid.WalkSpeed
	local isSpeedBoosted = currentSpeed > CONFIG.RUN_SPEED

	if isTryingToSprint and isMoving and canSprint then
		-- Only drain stamina if NO stamina boost active
		if not staminaBoostActive then
			currentStamina = math.clamp(currentStamina - (CONFIG.STAMINA_DRAIN * dt), 0, CONFIG.MAX_STAMINA)
		end

		if not isSpeedBoosted then
			humanoid.WalkSpeed = CONFIG.RUN_SPEED
		end

		lastSprintTime = tick()

		if currentStamina <= 0 and not staminaBoostActive then
			canSprint = false
			if not isSpeedBoosted then
				humanoid.WalkSpeed = CONFIG.WALK_SPEED
			end
		end
	else
		if not isSpeedBoosted and not isTryingToSprint then
			humanoid.WalkSpeed = CONFIG.WALK_SPEED
		end

		if tick() - lastSprintTime > CONFIG.REGEN_DELAY then
			currentStamina = math.clamp(currentStamina + (CONFIG.STAMINA_REGEN * dt), 0, CONFIG.MAX_STAMINA)
		end

		if not canSprint and currentStamina > (CONFIG.MAX_STAMINA * 0.15) then
			canSprint = true
		end
	end
end

-- -------------------------------------------------------------------------------
-- VISUAL UPDATE
-- -------------------------------------------------------------------------------

local function UpdateVisuals()
	if not hudReady or not humanoid or not ui.healthFill then return end

	local healthPct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)

	TweenService:Create(ui.healthFill, TweenInfo.new(0.1), {
		Size = UDim2.new(healthPct, 0, 1, 0)
	}):Play()

	local damagePct = 1 - healthPct
	local bloodAlpha = healthPct < 0.9 and math.clamp(damagePct ^ 1.5, 0, 0.9) or 0

	if ui.bloodOverlay then
		TweenService:Create(ui.bloodOverlay, TweenInfo.new(0.3), {ImageTransparency = 1 - bloodAlpha}):Play()
	end

	if healthPct <= CONFIG.CRITICAL_HEALTH_PCT then
		local pulse = (math.sin(tick() * 10) + 1) / 2
		ui.healthFill.BackgroundColor3 = CONFIG.COLOR_HEALTH_LOW: Lerp(Color3.new(1, 1, 1), pulse * 0.5)
	elseif justHealed then
		local pulse = (math.sin(tick() * 8) + 1) / 2
		ui.healthFill.BackgroundColor3 = CONFIG.COLOR_HEALTH_HEAL:Lerp(Color3.new(1, 1, 1), pulse * 0.4)
	elseif isRegenerating then
		local pulse = (math.sin(tick() * 3) + 1) / 2
		ui.healthFill.BackgroundColor3 = CONFIG.COLOR_HEALTH_OK:Lerp(CONFIG.COLOR_HEALTH_REGEN, pulse * 0.3)
	else
		ui.healthFill.BackgroundColor3 = CONFIG.COLOR_HEALTH_OK
	end

	if ui.staminaFill then
		local staminaPct = currentStamina / CONFIG.MAX_STAMINA

		TweenService:Create(ui.staminaFill, TweenInfo.new(0.1), {
			Size = UDim2.new(staminaPct, 0, 1, 0)
		}):Play()

		if staminaBoostActive then
			local pulse = (math.sin(tick() * 5) + 1) / 2
			ui.staminaFill.BackgroundColor3 = CONFIG.COLOR_STAMINA_BOOST:Lerp(Color3.new(1, 1, 1), pulse * 0.3)
		elseif staminaPct <= CONFIG.LOW_STAMINA_PCT or not canSprint then
			local pulse = (math.sin(tick() * 15) + 1) / 2
			local baseColor = canSprint and CONFIG.COLOR_STAMINA_LOW or Color3.fromRGB(150, 50, 50)
			ui.staminaFill.BackgroundColor3 = baseColor: Lerp(Color3.new(1, 1, 1), pulse * 0.3)
		else
			ui.staminaFill.BackgroundColor3 = CONFIG.COLOR_STAMINA_OK
		end
	end

	if ui.usdLabel then
		ui.usdLabel.Text = "?? $" ..playerUSD .." USD"
	end

	-- Update boost indicators every frame
	UpdateBoostIndicators()
end

-- -------------------------------------------------------------------------------
-- CONTROLS
-- -------------------------------------------------------------------------------

local function SetupInputs()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isTryingToSprint = true
		end

		local keyNumber = nil
		if input.KeyCode == Enum.KeyCode.One then keyNumber = 1
		elseif input.KeyCode == Enum.KeyCode.Two then keyNumber = 2
		elseif input.KeyCode == Enum.KeyCode.Three then keyNumber = 3
		elseif input.KeyCode == Enum.KeyCode.Four then keyNumber = 4
		elseif input.KeyCode == Enum.KeyCode.Five then keyNumber = 5
		elseif input.KeyCode == Enum.KeyCode.Six then keyNumber = 6
		end

		if keyNumber and UseItemEvent then
			local slotData = playerInventory[keyNumber]
			if slotData and slotData.quantity > 0 then
				UseItemEvent: FireServer(slotData.itemId)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			isTryingToSprint = false
		end
	end)

	ContextActionService: BindAction("SprintAction", function(name, state, input)
		isTryingToSprint = (state == Enum.UserInputState.Begin)
	end, false, Enum.KeyCode.ButtonL3, Enum.KeyCode.ButtonB)
end

-- -------------------------------------------------------------------------------
-- SERVER EVENTS
-- -------------------------------------------------------------------------------

if UpdateCurrencyEvent then
	UpdateCurrencyEvent.OnClientEvent:Connect(function(newAmount, change, reason)
		playerUSD = newAmount

		local color = change >= 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		local sign = change >= 0 and "+" or ""
		ShowNotification(sign .."$" ..change .." USD - " ..reason, color, 3)
	end)
end

if SyncDataEvent then
	SyncDataEvent.OnClientEvent:Connect(function(data, status, extra)
		if data then
			playerUSD = data.usd or 0
			playerInventory = data.inventory or {}
			UpdateInventoryUI()
		end

		if status == "PURCHASE_SUCCESS" then
			local item = GetItemById(extra)
			if item then
				ShowNotification("?? Bought " ..item.icon .." " ..item.name, Color3.fromRGB(100, 255, 150), 2)
			end
		elseif status == "NO_MONEY" then
			ShowNotification("? Not enough USD", Color3.fromRGB(255, 100, 100), 2)
		elseif status == "FULL_STACK" then
			ShowNotification("? Item stack is full (max 10)", Color3.fromRGB(255, 150, 100), 2)
		elseif status == "INVENTORY_FULL" then
			ShowNotification("? Inventory full (max 6 slots)", Color3.fromRGB(255, 100, 100), 2)
		elseif status == "ITEM_USED" then
			ApplyClientItemEffect(extra)
			UpdateInventoryUI()
		elseif status == "EFFECT_FAILED" then
			ShowNotification("? Cannot use item right now", Color3.fromRGB(255, 100, 100), 2)
		elseif status == "BOOST_ALREADY_ACTIVE" then
			-- NEW: Show remaining time when trying to stack boosts
			local remainingTime = extra and extra.remainingTime or 0
			local itemName = extra and extra.item and extra.item.name or "Boost"
			ShowNotification("? " ..itemName .." already active!  Wait " ..math.ceil(remainingTime) .."s", Color3.fromRGB(255, 200, 100), 3)
		elseif status == "DATA_NOT_LOADED" then
			ShowNotification("? Please wait, loading data...", Color3.fromRGB(255, 200, 100), 2)
		end
	end)
end

-- NEW: Boost update from server
if BoostUpdateEvent then
	BoostUpdateEvent.OnClientEvent:Connect(function(boostData)
		if boostData then
			-- Update end times based on server data
			if boostData.staminaRemaining and boostData.staminaRemaining > 0 then
				staminaBoostEndTime = tick() + boostData.staminaRemaining
			else
				staminaBoostEndTime = 0
			end

			if boostData.speedRemaining and boostData.speedRemaining > 0 then
				speedBoostEndTime = tick() + boostData.speedRemaining
			else
				speedBoostEndTime = 0
			end
		end
	end)
end

if DoorOpenedEvent then
	DoorOpenedEvent.OnClientEvent:Connect(function(reward)
		playerUSD = playerUSD + reward
		ShowNotification("+$" ..reward .." USD - Door opened", Color3.fromRGB(100, 255, 100), 2)
	end)
end

if SurvivedDoorEvent then
	SurvivedDoorEvent.OnClientEvent:Connect(function(reward, npcType)
		playerUSD = playerUSD + reward
		local reason = npcType == "screamer" and "Survived the Screamer!" or "Survived the Shadow!"
		ShowNotification("+$" ..reward .." USD - " ..reason, Color3.fromRGB(100, 255, 200), 3)
	end)
end

-- -------------------------------------------------------------------------------
-- INITIALIZATION
-- -------------------------------------------------------------------------------

CreateHUD()
SetupInputs()
UpdateInventoryUI()

if humanoid then
	previousHealth = humanoid.Health
end

isInLobby = CheckIfPlayerInLobby()

UserInputService.JumpRequest:Connect(function()
	if currentStamina > CONFIG.JUMP_COST and not staminaBoostActive then
		currentStamina = currentStamina - CONFIG.JUMP_COST
		lastSprintTime = tick()
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if character and humanoid and humanoid.Health > 0 then
		UpdateStamina(dt)
		UpdateLobbyStatus()
		UpdateVisuals()
	else
		if ui.bloodOverlay then 
			ui.bloodOverlay.ImageTransparency = 0 
		end
		if ui.lobbyIndicator then
			ui.lobbyIndicator.Visible = false
		end
		if ui.staminaBoostIndicator then
			ui.staminaBoostIndicator.Visible = false
		end
		if ui.speedBoostIndicator then
			ui.speedBoostIndicator.Visible = false
		end
	end
end)

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid", 10)
	currentStamina = CONFIG.MAX_STAMINA
	canSprint = true
	isTryingToSprint = false

	-- Reset boost timers on respawn
	staminaBoostActive = false
	staminaBoostEndTime = 0
	speedBoostActive = false
	speedBoostEndTime = 0

	isInLobby = false
	isRegenerating = false
	justHealed = false

	if humanoid then
		previousHealth = humanoid.Health
	end

	if ui.bloodOverlay then 
		ui.bloodOverlay.ImageTransparency = 1 
	end

	if ui.lobbyIndicator then
		ui.lobbyIndicator.Visible = false
	end

	if ui.staminaBoostIndicator then
		ui.staminaBoostIndicator.Visible = false
	end

	if ui.speedBoostIndicator then
		ui.speedBoostIndicator.Visible = false
	end

	task.wait(0.5)
	isInLobby = CheckIfPlayerInLobby()
	UpdateInventoryUI()
end)

print("? [HUD] V11 Loaded - Boost timers, no stacking")