--[[
    +------------------------------------------------------------------------------+
    ¦                         SHOP UI - STORE INTERFACE                             ¦
    ¦                    V5 - Uses Global Mouse Controller                          ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CurrencyRemotes = ReplicatedStorage:WaitForChild("CurrencyRemotes")
local OpenShopEvent = CurrencyRemotes:WaitForChild("OpenShop")
local PurchaseItemEvent = CurrencyRemotes: WaitForChild("PurchaseItem")
local SyncDataEvent = CurrencyRemotes: WaitForChild("SyncData")

-- -------------------------------------------------------------------------------
-- ITEMS CONFIGURATION (ENGLISH)
-- -------------------------------------------------------------------------------

local ITEMS = {
	{id = "bandage", name = "Bandage", description = "Restores 20% health", price = 15, icon = "??", category = "Healing"},
	{id = "medkit", name = "Med Kit", description = "Restores 50% health", price = 35, icon = "??", category = "Healing"},
	{id = "adrenaline", name = "Adrenaline", description = "Restores 100% health", price = 75, icon = "??", category = "Healing"},
	{id = "energy_drink", name = "Energy Drink", description = "No stamina cost for 30 sec", price = 25, icon = "??", category = "Stamina"},
	{id = "super_energy", name = "Super Energy", description = "No stamina cost for 60 sec", price = 50, icon = "?", category = "Stamina"},
	{id = "ultra_boost", name = "Ultra Boost", description = "No stamina cost for 120 sec", price = 100, icon = "??", category = "Stamina"},
	{id = "speed_pill", name = "Speed Pill", description = "+50% speed for 20 sec", price = 30, icon = "??", category = "Speed"},
	{id = "turbo_boots", name = "Turbo Boots", description = "+100% speed for 15 sec", price = 60, icon = "??", category = "Speed"},
}

local shopGui = nil
local isShopOpen = false
local playerUSD = 0

-- -------------------------------------------------------------------------------
-- MOUSE CONTROL (Uses Global Controller)
-- -------------------------------------------------------------------------------

local function GetMouseController()
	-- Wait for global mouse controller to be available
	local attempts = 0
	while not _G.MouseController and attempts < 50 do
		task.wait(0.1)
		attempts = attempts + 1
	end
	return _G.MouseController
end

local function UnlockMouse()
	local controller = GetMouseController()
	if controller then
		controller:Unlock("shop")
	else
		-- Fallback if controller not available
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		player.CameraMode = Enum.CameraMode.Classic
	end
end

local function LockMouse()
	local controller = GetMouseController()
	if controller then
		controller:ReleaseLock("shop")
	else
		-- Fallback if controller not available
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

-- -------------------------------------------------------------------------------
-- CREATE SHOP UI
-- -------------------------------------------------------------------------------

local function CreateShopUI()
	if playerGui: FindFirstChild("ShopGUI") then
		playerGui.ShopGUI:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopGUI"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	shopGui = gui

	-- Dark background
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = gui

	backdrop.MouseButton1Click:Connect(function()
		CloseShop()
	end)

	-- Main container
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 650, 0, 480)
	mainFrame.Position = UDim2.new(0.5, -325, 0.5, -240)
	mainFrame.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Parent = gui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(100, 110, 130)
	mainStroke.Thickness = 3
	mainStroke.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	local headerFix = Instance.new("Frame")
	headerFix.Size = UDim2.new(1, 0, 0.5, 0)
	headerFix.Position = UDim2.new(0, 0, 0.5, 0)
	headerFix.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.4, 0, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "?? SHOP"
	title.TextColor3 = Color3.fromRGB(255, 230, 120)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- USD Display
	local usdFrame = Instance.new("Frame")
	usdFrame.Name = "USDFrame"
	usdFrame.Size = UDim2.new(0, 150, 0, 40)
	usdFrame.Position = UDim2.new(0.5, -75, 0.5, -20)
	usdFrame.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
	usdFrame.Parent = header

	local usdCorner = Instance.new("UICorner")
	usdCorner.CornerRadius = UDim.new(0, 8)
	usdCorner.Parent = usdFrame

	local usdDisplay = Instance.new("TextLabel")
	usdDisplay.Name = "USDDisplay"
	usdDisplay.Size = UDim2.new(1, -10, 1, 0)
	usdDisplay.Position = UDim2.new(0, 5, 0, 0)
	usdDisplay.BackgroundTransparency = 1
	usdDisplay.Text = "?? $0 USD"
	usdDisplay.TextColor3 = Color3.fromRGB(120, 255, 140)
	usdDisplay.TextScaled = true
	usdDisplay.Font = Enum.Font.GothamBold
	usdDisplay.Parent = usdFrame

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(0, 120, 0, 30)
	instructions.Position = UDim2.new(1, -180, 0.5, -15)
	instructions.BackgroundTransparency = 1
	instructions.Text = "ESC to close"
	instructions.TextColor3 = Color3.fromRGB(180, 180, 200)
	instructions.TextScaled = true
	instructions.Font = Enum.Font.Gotham
	instructions.Parent = header

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 45, 0, 45)
	closeBtn.Position = UDim2.new(1, -55, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
	closeBtn.Text = "?"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 24
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		CloseShop()
	end)

	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(255, 100, 100)}):Play()
	end)

	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
	end)

	-- Items container
	local itemsContainer = Instance.new("ScrollingFrame")
	itemsContainer.Name = "ItemsContainer"
	itemsContainer.Size = UDim2.new(1, -30, 1, -80)
	itemsContainer.Position = UDim2.new(0, 15, 0, 70)
	itemsContainer.BackgroundTransparency = 1
	itemsContainer.BorderSizePixel = 0
	itemsContainer.ScrollBarThickness = 8
	itemsContainer.ScrollBarImageColor3 = Color3.fromRGB(120, 130, 150)
	itemsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemsContainer.Parent = mainFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 195, 0, 130)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemsContainer

	-- Create item cards
	for i, item in ipairs(ITEMS) do
		local card = Instance.new("Frame")
		card.Name = "Item_" ..item.id
		card.BackgroundColor3 = Color3.fromRGB(65, 70, 85)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = itemsContainer

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(95, 100, 115)
		cardStroke.Thickness = 2
		cardStroke.Parent = card

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 45, 0, 45)
		icon.Position = UDim2.new(0, 10, 0, 10)
		icon.BackgroundTransparency = 1
		icon.Text = item.icon
		icon.TextScaled = true
		icon.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -65, 0, 22)
		nameLabel.Position = UDim2.new(0, 58, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(1, -20, 0, 35)
		descLabel.Position = UDim2.new(0, 10, 0, 55)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = item.description
		descLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
		descLabel.TextScaled = true
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = card

		-- Buy button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(1, -20, 0, 32)
		buyBtn.Position = UDim2.new(0, 10, 1, -40)
		buyBtn.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		buyBtn.Text = "?? $" ..item.price .." USD"
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.TextSize = 16
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Parent = card

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 8)
		buyCorner.Parent = buyBtn

		buyBtn.MouseEnter:Connect(function()
			TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 200, 110)}):Play()
			TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(75, 80, 100)}):Play()
		end)

		buyBtn.MouseLeave:Connect(function()
			TweenService:Create(buyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 170, 90)}):Play()
			TweenService:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(65, 70, 85)}):Play()
		end)

		buyBtn.MouseButton1Click:Connect(function()
			TweenService:Create(buyBtn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(120, 230, 150)}):Play()
			PurchaseItemEvent:FireServer(item.id)
			task.wait(0.1)
			TweenService:Create(buyBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 170, 90)}):Play()
		end)

		-- Category badge
		local categoryBadge = Instance.new("TextLabel")
		categoryBadge.Name = "Category"
		categoryBadge.Size = UDim2.new(0, 70, 0, 18)
		categoryBadge.Position = UDim2.new(1, -75, 0, 32)
		categoryBadge.BackgroundColor3 = Color3.fromRGB(85, 95, 125)
		categoryBadge.Text = item.category
		categoryBadge.TextColor3 = Color3.fromRGB(220, 225, 240)
		categoryBadge.TextScaled = true
		categoryBadge.Font = Enum.Font.GothamBold
		categoryBadge.Parent = card

		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 5)
		catCorner.Parent = categoryBadge
	end

	return gui
end

-- -------------------------------------------------------------------------------
-- OPEN/CLOSE SHOP FUNCTIONS
-- -------------------------------------------------------------------------------

local function UpdateShopUSD()
	if shopGui then
		local mainFrame = shopGui:FindFirstChild("MainFrame")
		if mainFrame then
			local header = mainFrame:FindFirstChild("Header")
			if header then
				local usdFrame = header:FindFirstChild("USDFrame")
				if usdFrame then
					local usdDisplay = usdFrame:FindFirstChild("USDDisplay")
					if usdDisplay then
						usdDisplay.Text = "?? $" ..playerUSD .." USD"
					end
				end
			end
		end
	end
end

local function OpenShop()
	if isShopOpen then return end
	isShopOpen = true

	if not shopGui then
		CreateShopUI()
	end

	UpdateShopUSD()
	UnlockMouse() -- Use controller

	shopGui.Enabled = true

	local mainFrame = shopGui:FindFirstChild("MainFrame")
	if mainFrame then
		mainFrame.Position = UDim2.new(0.5, -325, 0.5, -200)
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		mainFrame.BackgroundTransparency = 1

		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 650, 0, 480),
			Position = UDim2.new(0.5, -325, 0.5, -240),
			BackgroundTransparency = 0
		}):Play()
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
end

function CloseShop()
	if not isShopOpen then return end
	isShopOpen = false

	if shopGui then
		local mainFrame = shopGui:FindFirstChild("MainFrame")
		if mainFrame then
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundTransparency = 1
			}):Play()

			task.wait(0.2)
		end

		shopGui.Enabled = false
	end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end
	end

	LockMouse() -- Use controller
end

-- -------------------------------------------------------------------------------
-- EVENTS
-- -------------------------------------------------------------------------------

OpenShopEvent.OnClientEvent:Connect(function()
	OpenShop()
end)

SyncDataEvent.OnClientEvent:Connect(function(data, status, extra)
	if data then
		playerUSD = data.usd or 0
		UpdateShopUSD()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if isShopOpen then
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.E then
			CloseShop()
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	if isShopOpen then
		CloseShop()
	end
end)

-- -------------------------------------------------------------------------------
-- INITIALIZATION
-- -------------------------------------------------------------------------------

CreateShopUI()

print("? [ShopUI] V5 Loaded - Uses Global Mouse Controller")