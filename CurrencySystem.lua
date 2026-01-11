--[[
    +------------------------------------------------------------------------------+
    ¦                     CURRENCY SYSTEM V6 - NO STACKING BOOSTS                   ¦
    ¦           Items ordered by purchase, persist on death, no boost stacking      ¦
    +-------------------------------------------------------???----------------------+
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- DataStore with retry logic
local PlayerDataStore = nil
local DATA_STORE_RETRIES = 3
local DATA_STORE_RETRY_DELAY = 1

local function InitDataStore()
	local success, result = pcall(function()
		return DataStoreService:GetDataStore("InfiniteStreetData_V2")
	end)

	if success then
		PlayerDataStore = result
		print("? [CurrencySystem] DataStore initialized successfully")
	else
		warn("? [CurrencySystem] Failed to initialize DataStore:  " ..tostring(result))
	end
end

InitDataStore()

-- Wait for remotes with error handling
local CurrencyRemotes = ReplicatedStorage:WaitForChild("CurrencyRemotes", 30)
if not CurrencyRemotes then
	error("[CurrencySystem] CurrencyRemotes folder not found!")
end

local function SafeWaitForChild(parent, name, timeout)
	local child = parent: WaitForChild(name, timeout or 10)
	if not child then
		warn("[CurrencySystem] Remote not found: " ..name)
	end
	return child
end

local UpdateCurrencyEvent = SafeWaitForChild(CurrencyRemotes, "UpdateCurrency")
local SyncDataEvent = SafeWaitForChild(CurrencyRemotes, "SyncData")
local DoorOpenedEvent = SafeWaitForChild(CurrencyRemotes, "DoorOpened")
local SurvivedDoorEvent = SafeWaitForChild(CurrencyRemotes, "SurvivedDoor")
local PlayerDiedEvent = SafeWaitForChild(CurrencyRemotes, "PlayerDied")

-- Create remotes if they don't exist
local function GetOrCreateRemote(name)
	local remote = CurrencyRemotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = CurrencyRemotes
	end
	return remote
end

local PurchaseItemEvent = GetOrCreateRemote("PurchaseItem")
local UseItemEvent = GetOrCreateRemote("UseItem")
local BoostUpdateEvent = GetOrCreateRemote("BoostUpdate") -- NEW: For syncing boost timers

-- -------------------------------------------------------------------------------
-- CONFIGURATION
-- -------------------------------------------------------------------------------

local DEATH_PENALTY_PERCENT = 0.20
local MAX_STACK = 10
local MAX_SLOTS = 6

local ITEMS = {
	{id = "bandage", name = "Bandage", price = 15, type = "heal", value = 20, icon = "??"},
	{id = "medkit", name = "Med Kit", price = 35, type = "heal", value = 50, icon = "??"},
	{id = "adrenaline", name = "Adrenaline", price = 75, type = "heal", value = 100, icon = "??"},
	{id = "energy_drink", name = "Energy Drink", price = 25, type = "stamina_boost", duration = 30, icon = "??"},
	{id = "super_energy", name = "Super Energy", price = 50, type = "stamina_boost", duration = 60, icon = "?"},
	{id = "ultra_boost", name = "Ultra Boost", price = 100, type = "stamina_boost", duration = 120, icon = "??"},
	{id = "speed_pill", name = "Speed Pill", price = 30, type = "speed_boost", value = 1.5, duration = 20, icon = "??"},
	{id = "turbo_boots", name = "Turbo Boots", price = 60, type = "speed_boost", value = 2.0, duration = 15, icon = "??"},
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
-- PLAYER DATA
-- -------------------------------------------------------------------------------

local playerData = {}
local playerBoosts = {} -- Track active boosts with END TIMES
local dataLoaded = {}

local function GetDefaultData()
	return {
		usd = 0,
		inventory = {},
		totalEarned = 0,
		deaths = 0,
		version = 2,
	}
end

-- -------------------------------------------------------------------------------
-- DATA MIGRATION
-- -------------------------------------------------------------------------------

local function MigrateData(data)
	if not data then return GetDefaultData() end

	if data.version and data.version >= 2 then
		return data
	end

	local newData = {
		usd = data.usd or 0,
		inventory = {},
		totalEarned = data.totalEarned or 0,
		deaths = data.deaths or 0,
		version = 2,
	}

	if data.inventory and type(data.inventory) == "table" then
		local isOldFormat = false
		for key, value in pairs(data.inventory) do
			if type(key) == "string" and type(value) == "number" then
				isOldFormat = true
				break
			end
		end

		if isOldFormat then
			for itemId, quantity in pairs(data.inventory) do
				if quantity > 0 then
					table.insert(newData.inventory, {
						itemId = itemId,
						quantity = quantity
					})
				end
			end
			print("[CurrencySystem] Migrated inventory from V1 to V2 format")
		else
			newData.inventory = data.inventory
		end
	end

	return newData
end

-- -------------------------------------------------------------------------------
-- BOOST MANAGEMENT - NO STACKING! 
-- -------------------------------------------------------------------------------

local function GetPlayerBoosts(player)
	if not playerBoosts[player.UserId] then
		playerBoosts[player.UserId] = {
			staminaBoostEndTime = 0,
			speedBoostEndTime = 0,
			speedMultiplier = 1,
		}
	end
	return playerBoosts[player.UserId]
end

local function IsStaminaBoostActive(player)
	local boosts = GetPlayerBoosts(player)
	return tick() < boosts.staminaBoostEndTime
end

local function IsSpeedBoostActive(player)
	local boosts = GetPlayerBoosts(player)
	return tick() < boosts.speedBoostEndTime
end

local function GetStaminaBoostRemaining(player)
	local boosts = GetPlayerBoosts(player)
	local remaining = boosts.staminaBoostEndTime - tick()
	return remaining > 0 and remaining or 0
end

local function GetSpeedBoostRemaining(player)
	local boosts = GetPlayerBoosts(player)
	local remaining = boosts.speedBoostEndTime - tick()
	return remaining > 0 and remaining or 0
end

-- Send boost update to client
local function SyncBoostsToClient(player)
	if not player or not player.Parent then return end
	if not BoostUpdateEvent then return end

	local boosts = GetPlayerBoosts(player)
	BoostUpdateEvent:FireClient(player, {
		staminaRemaining = GetStaminaBoostRemaining(player),
		speedRemaining = GetSpeedBoostRemaining(player),
		speedMultiplier = boosts.speedMultiplier,
	})
end

-- -------------------------------------------------------------------------------
-- DATASTORE FUNCTIONS
-- -------------------------------------------------------------------------------

local function LoadPlayerData(player)
	if not player or not player.Parent then return GetDefaultData() end

	local key = "Player_" ..player.UserId
	local data = nil

	if not PlayerDataStore then
		warn("[CurrencySystem] DataStore not available, using default data for " ..player.Name)
		playerData[player.UserId] = GetDefaultData()
		dataLoaded[player.UserId] = true
		return playerData[player.UserId]
	end

	for attempt = 1, DATA_STORE_RETRIES do
		local success, result = pcall(function()
			return PlayerDataStore:GetAsync(key)
		end)

		if success then
			data = result
			break
		else
			warn("[CurrencySystem] Load attempt " ..attempt .." failed for " ..player.Name ..": " ..tostring(result))
			if attempt < DATA_STORE_RETRIES then
				task.wait(DATA_STORE_RETRY_DELAY)
			end
		end
	end

	if data then
		data = MigrateData(data)
		playerData[player.UserId] = data
		print("? [CurrencySystem] Loaded data for " ..player.Name ..": $" ..data.usd .." USD, " ..#data.inventory .." item slots")
	else
		playerData[player.UserId] = GetDefaultData()
		print("?? [CurrencySystem] Created new data for " ..player.Name)
	end

	dataLoaded[player.UserId] = true
	return playerData[player.UserId]
end

local function SavePlayerData(player)
	if not player then return false end

	local data = playerData[player.UserId]
	if not data then return false end

	if not PlayerDataStore then
		warn("[CurrencySystem] DataStore not available, cannot save for " ..player.Name)
		return false
	end

	local key = "Player_" ..player.UserId

	for attempt = 1, DATA_STORE_RETRIES do
		local success, err = pcall(function()
			PlayerDataStore:SetAsync(key, data)
		end)

		if success then
			print("?? [CurrencySystem] Saved data for " ..player.Name ..": $" ..data.usd .." USD")
			return true
		else
			warn("[CurrencySystem] Save attempt " ..attempt .." failed for " ..player.Name ..": " ..tostring(err))
			if attempt < DATA_STORE_RETRIES then
				task.wait(DATA_STORE_RETRY_DELAY)
			end
		end
	end

	return false
end

-- -------------------------------------------------------------------------------
-- CURRENCY FUNCTIONS
-- -------------------------------------------------------------------------------

local function SyncPlayer(player)
	if not player or not player.Parent then return end

	local data = playerData[player.UserId]
	if data and SyncDataEvent then
		SyncDataEvent:FireClient(player, data)
	end
end

local function AddMoney(player, amount, reason)
	if not player or not player.Parent then return end

	local data = playerData[player.UserId]
	if not data then return end

	data.usd = data.usd + amount
	data.totalEarned = data.totalEarned + amount

	if UpdateCurrencyEvent then
		UpdateCurrencyEvent:FireClient(player, data.usd, amount, reason or "Reward")
	end
	SyncPlayer(player)
end

local function RemoveMoney(player, amount, reason)
	if not player or not player.Parent then return false end

	local data = playerData[player.UserId]
	if not data then return false end

	if data.usd >= amount then
		data.usd = data.usd - amount
		if UpdateCurrencyEvent then
			UpdateCurrencyEvent:FireClient(player, data.usd, -amount, reason or "Purchase")
		end
		SyncPlayer(player)
		return true
	end
	return false
end

-- -------------------------------------------------------------------------------
-- INVENTORY FUNCTIONS
-- -------------------------------------------------------------------------------

local function FindItemSlot(inventory, itemId)
	for i, slot in ipairs(inventory) do
		if slot.itemId == itemId then
			return i
		end
	end
	return nil
end

local function AddItemToInventory(player, itemId)
	local data = playerData[player.UserId]
	if not data then return false, "NO_DATA" end

	local item = GetItemById(itemId)
	if not item then return false, "INVALID_ITEM" end

	local existingSlot = FindItemSlot(data.inventory, itemId)

	if existingSlot then
		if data.inventory[existingSlot].quantity >= MAX_STACK then
			return false, "FULL_STACK"
		end
		data.inventory[existingSlot].quantity = data.inventory[existingSlot].quantity + 1
		return true, existingSlot
	else
		if #data.inventory >= MAX_SLOTS then
			return false, "INVENTORY_FULL"
		end

		table.insert(data.inventory, {
			itemId = itemId,
			quantity = 1
		})
		return true, #data.inventory
	end
end

local function RemoveItemFromInventory(player, itemId)
	local data = playerData[player.UserId]
	if not data then return false end

	local slotIndex = FindItemSlot(data.inventory, itemId)
	if not slotIndex then return false end

	data.inventory[slotIndex].quantity = data.inventory[slotIndex].quantity - 1

	if data.inventory[slotIndex].quantity <= 0 then
		table.remove(data.inventory, slotIndex)
	end

	return true
end

-- -------------------------------------------------------------------------------
-- APPLY ITEM EFFECTS - WITH BOOST STACKING PREVENTION
-- -------------------------------------------------------------------------------

local function ApplyItemEffect(player, item)
	if not player or not player.Parent then return false, "NO_PLAYER" end
	if not item then return false, "NO_ITEM" end

	local character = player.Character
	if not character then return false, "NO_CHARACTER" end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false, "DEAD" end

	local boosts = GetPlayerBoosts(player)

	-- HEALING
	if item.type == "heal" then
		local healAmount = humanoid.MaxHealth * (item.value / 100)
		local oldHealth = humanoid.Health
		humanoid.Health = math.min(humanoid.Health + healAmount, humanoid.MaxHealth)
		local actualHeal = humanoid.Health - oldHealth

		print("?? [CurrencySystem] " ..player.Name .." healed for " ..math.floor(actualHeal) .." HP using " ..item.name)
		return true, "HEALED"

		-- STAMINA BOOST - NO STACKING! 
	elseif item.type == "stamina_boost" then
		-- Check if already has active stamina boost
		if IsStaminaBoostActive(player) then
			local remaining = math.ceil(GetStaminaBoostRemaining(player))
			print("? [CurrencySystem] " ..player.Name .." tried to use stamina boost but already has one active (" ..remaining .."s remaining)")
			return false, "BOOST_ACTIVE", remaining
		end

		-- Apply new stamina boost
		boosts.staminaBoostEndTime = tick() + item.duration

		print("? [CurrencySystem] " ..player.Name .." activated stamina boost for " ..item.duration .."s")

		-- Sync to client
		SyncBoostsToClient(player)

		-- Schedule end notification
		task.delay(item.duration, function()
			if player and player.Parent then
				SyncBoostsToClient(player)
			end
		end)

		return true, "STAMINA_BOOST"

		-- SPEED BOOST - NO STACKING!
	elseif item.type == "speed_boost" then
		-- Check if already has active speed boost
		if IsSpeedBoostActive(player) then
			local remaining = math.ceil(GetSpeedBoostRemaining(player))
			print("?? [CurrencySystem] " ..player.Name .." tried to use speed boost but already has one active (" ..remaining .."s remaining)")
			return false, "BOOST_ACTIVE", remaining
		end

		local originalSpeed = 16
		local boostedSpeed = originalSpeed * item.value

		-- Apply speed boost
		humanoid.WalkSpeed = boostedSpeed
		boosts.speedBoostEndTime = tick() + item.duration
		boosts.speedMultiplier = item.value

		print("?? [CurrencySystem] " ..player.Name .." activated speed boost (" ..item.value .."x) for " ..item.duration .."s")

		-- Sync to client
		SyncBoostsToClient(player)

		-- Schedule speed reset
		task.delay(item.duration, function()
			if player and player.Parent then
				local char = player.Character
				if char then
					local hum = char:FindFirstChild("Humanoid")
					if hum and tick() >= boosts.speedBoostEndTime then
						hum.WalkSpeed = originalSpeed
						boosts.speedMultiplier = 1
						SyncBoostsToClient(player)
						print("?? [CurrencySystem] " ..player.Name .."'s speed boost ended")
					end
				end
			end
		end)

		return true, "SPEED_BOOST"
	end

	return false, "UNKNOWN_TYPE"
end

-- -------------------------------------??-----------------------------------------
-- EVENT HANDLERS
-- -------------------------------------------------------------------------------

local function OnDoorOpened(player, reward)
	AddMoney(player, reward, "Door opened")
end

local function OnSurvived(player, reward, npcType)
	local reason = npcType == "screamer" and "Survived the Screamer!" or "Survived the Shadow!"
	AddMoney(player, reward, reason)
end

local function OnPlayerDied(player)
	if not player or not player.Parent then return end

	local data = playerData[player.UserId]
	if not data then return end

	data.deaths = data.deaths + 1

	local penalty = math.floor(data.usd * DEATH_PENALTY_PERCENT)
	if penalty > 0 then
		data.usd = data.usd - penalty
		if UpdateCurrencyEvent then
			UpdateCurrencyEvent:FireClient(player, data.usd, -penalty, "Death penalty (20% money)")
		end
	end

	-- Clear active boosts on death
	playerBoosts[player.UserId] = {
		staminaBoostEndTime = 0,
		speedBoostEndTime = 0,
		speedMultiplier = 1,
	}

	SyncPlayer(player)
	SyncBoostsToClient(player)

	task.spawn(function()
		SavePlayerData(player)
	end)

	print("?? [CurrencySystem] " ..player.Name .." died.Lost $" ..penalty .." but kept " ..#data.inventory .." item slots")
end

if PlayerDiedEvent then
	PlayerDiedEvent.OnServerEvent:Connect(function(player)
		OnPlayerDied(player)
	end)
end

-- Purchase item
if PurchaseItemEvent then
	PurchaseItemEvent.OnServerEvent:Connect(function(player, itemId)
		if not player or not player.Parent then return end
		if not dataLoaded[player.UserId] then
			if SyncDataEvent then
				SyncDataEvent:FireClient(player, nil, "DATA_NOT_LOADED")
			end
			return
		end

		local item = GetItemById(itemId)
		if not item then return end

		local data = playerData[player.UserId]
		if not data then return end

		if data.usd < item.price then
			if SyncDataEvent then
				SyncDataEvent:FireClient(player, data, "NO_MONEY")
			end
			return
		end

		local success, status = AddItemToInventory(player, itemId)
		if not success then
			if SyncDataEvent then
				SyncDataEvent:FireClient(player, data, status)
			end
			return
		end

		data.usd = data.usd - item.price
		if UpdateCurrencyEvent then
			UpdateCurrencyEvent:FireClient(player, data.usd, -item.price, "Bought " ..item.name)
		end
		if SyncDataEvent then
			SyncDataEvent:FireClient(player, data, "PURCHASE_SUCCESS", itemId)
		end

		print("?? [CurrencySystem] " ..player.Name .." bought " ..item.name .." (Slot " ..status ..")")
	end)
end

-- Use item
if UseItemEvent then
	UseItemEvent.OnServerEvent:Connect(function(player, itemId)
		if not player or not player.Parent then return end
		if not dataLoaded[player.UserId] then return end

		local data = playerData[player.UserId]
		if not data then return end

		local slotIndex = FindItemSlot(data.inventory, itemId)
		if not slotIndex then return end

		if data.inventory[slotIndex].quantity <= 0 then return end

		local item = GetItemById(itemId)
		if not item then return end

		-- Apply the effect
		local effectApplied, status, extraData = ApplyItemEffect(player, item)

		if effectApplied then
			RemoveItemFromInventory(player, itemId)
			if SyncDataEvent then
				SyncDataEvent:FireClient(player, data, "ITEM_USED", item)
			end
		else
			-- Send specific error to client
			if status == "BOOST_ACTIVE" then
				if SyncDataEvent then
					SyncDataEvent:FireClient(player, data, "BOOST_ALREADY_ACTIVE", {
						item = item,
						remainingTime = extraData
					})
				end
			else
				if SyncDataEvent then
					SyncDataEvent: FireClient(player, data, "EFFECT_FAILED", item)
				end
			end
		end
	end)
end

-- -------------------------------------------------------------------------------
-- PLAYER CONNECTIONS
-- -------------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		LoadPlayerData(player)
		playerBoosts[player.UserId] = {
			staminaBoostEndTime = 0,
			speedBoostEndTime = 0,
			speedMultiplier = 1,
		}

		task.wait(1)
		if player and player.Parent then
			SyncPlayer(player)
			SyncBoostsToClient(player)
		end
	end)

	player.CharacterAdded:Connect(function(char)
		-- Reset boosts on respawn
		playerBoosts[player.UserId] = {
			staminaBoostEndTime = 0,
			speedBoostEndTime = 0,
			speedMultiplier = 1,
		}

		local humanoid = char:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				OnPlayerDied(player)
			end)
		end

		task.wait(0.5)
		if player and player.Parent then
			SyncPlayer(player)
			SyncBoostsToClient(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	SavePlayerData(player)
	playerData[player.UserId] = nil
	playerBoosts[player.UserId] = nil
	dataLoaded[player.UserId] = nil
end)

-- Auto-save every 60 seconds
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in pairs(Players:GetPlayers()) do
			if dataLoaded[player.UserId] then
				task.spawn(function()
					SavePlayerData(player)
				end)
			end
		end
	end
end)

-- Save all on shutdown
game: BindToClose(function()
	print("[CurrencySystem] Server shutting down, saving all player data...")

	for _, player in pairs(Players:GetPlayers()) do
		if dataLoaded[player.UserId] then
			task.spawn(function()
				SavePlayerData(player)
			end)
		end
	end

	task.wait(3)
	print("[CurrencySystem] Shutdown save complete")
end)

-- Export functions for MainServer
_G.CurrencySystem = {
	AddMoney = AddMoney,
	RemoveMoney = RemoveMoney,
	OnDoorOpened = OnDoorOpened,
	OnSurvived = OnSurvived,
}

print("? [CurrencySystem] V6 Loaded - No boost stacking, ordered inventory")