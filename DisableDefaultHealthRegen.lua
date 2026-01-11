--[[
    +------------------------------------------------------------------------------+
    ¦              DISABLE DEFAULT HEALTH REGENERATION - SERVER                     ¦
    ¦                    Must be in ServerScriptService                             ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")

-- Configuration
local LOBBY_START_X = -75
local LOBBY_END_X = 75
local HEALTH_REGEN_RATE = 5 -- HP per second in lobby
local REGEN_DELAY_AFTER_DAMAGE = 2 -- seconds

-- Player data for tracking damage
local playerHealthData = {}

local function IsInLobby(character)
	if not character then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local x = hrp.Position.X
	return x >= LOBBY_START_X and x <= LOBBY_END_X
end

local function SetupCharacter(player, character)
	-- Wait for humanoid
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end

	-- CRITICAL: Remove the default Health script
	local healthScript = character:FindFirstChild("Health")
	if healthScript then
		healthScript:Destroy()
		print("[HealthSystem] Destroyed default Health script for " ..player.Name)
	end

	-- Also check for any script that might regenerate health
	for _, child in pairs(character:GetChildren()) do
		if child:IsA("Script") and child.Name == "Health" then
			child: Destroy()
			print("[HealthSystem] Destroyed additional Health script for " ..player.Name)
		end
	end

	-- Initialize player health tracking
	playerHealthData[player.UserId] = {
		lastHealth = humanoid.Health,
		lastDamageTime = 0,
		lastRegenTime = tick()
	}

	-- Monitor for the Health script being re-added
	character.ChildAdded:Connect(function(child)
		if child.Name == "Health" and child:IsA("Script") then
			child:Destroy()
			print("[HealthSystem] Blocked Health script re-add for " ..player.Name)
		end
	end)

	-- Track damage
	humanoid.HealthChanged:Connect(function(newHealth)
		local data = playerHealthData[player.UserId]
		if not data then return end

		-- If health decreased, it's damage
		if newHealth < data.lastHealth then
			data.lastDamageTime = tick()
		end

		data.lastHealth = newHealth
	end)

	print("[HealthSystem] Setup complete for " ..player.Name)
end

local function OnPlayerAdded(player)
	-- Setup current character
	if player.Character then
		SetupCharacter(player, player.Character)
	end

	-- Setup future characters
	player.CharacterAdded:Connect(function(character)
		-- Small delay to ensure character is fully loaded
		task.wait(0.1)
		SetupCharacter(player, character)
	end)
end

local function OnPlayerRemoving(player)
	playerHealthData[player.UserId] = nil
end

-- Connect events
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- Setup existing players
for _, player in pairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end

-- Main regeneration loop - SERVER CONTROLLED
game:GetService("RunService").Heartbeat:Connect(function(dt)
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local data = playerHealthData[player.UserId]
		if not data then continue end

		-- Check if player is in lobby
		local inLobby = IsInLobby(character)

		-- Check if enough time has passed since last damage
		local timeSinceDamage = tick() - data.lastDamageTime
		local canRegen = timeSinceDamage >= REGEN_DELAY_AFTER_DAMAGE

		-- Only regenerate if IN LOBBY and can regen
		if inLobby and canRegen and humanoid.Health < humanoid.MaxHealth then
			local regenAmount = HEALTH_REGEN_RATE * dt
			humanoid.Health = math.min(humanoid.Health + regenAmount, humanoid.MaxHealth)
			data.lastHealth = humanoid.Health -- Update to prevent false damage detection
		end
	end
end)

print("? [HealthSystem] Server-side health regeneration control ACTIVE")
print("   - Default regen:  DISABLED")
print("   - Lobby regen: ENABLED (X: " ..LOBBY_START_X .." to " ..LOBBY_END_X ..")")