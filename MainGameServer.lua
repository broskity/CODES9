--[[
    +------------------------------------------------------------------------------+
    �                    INFINITE STREET - MAIN SERVER SCRIPT                       �
    �                    VERSION 27 - 6 NPCs + CUSTOM EYE ANIMATIONS                �
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game: GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- -------------------------------------------------------------------------------
-- REMOTE EVENTS AND BINDABLES
-- -------------------------------------------------------------------------------

local EventsFolder = ReplicatedStorage:FindFirstChild("Events") or Instance.new("Folder")
EventsFolder.Name = "Events"
EventsFolder.Parent = ReplicatedStorage

-- Create all NPC spawn events
local function CreateBindableEvent(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

-- 6 NPC SPAWN EVENTS
local SpawnNPCEvent = CreateBindableEvent("SpawnNPCEvent")           -- Shadow
local SpawnScreamerEvent = CreateBindableEvent("SpawnScreamerEvent") -- Screamer
local SpawnCrawlerEvent = CreateBindableEvent("SpawnCrawlerEvent")   -- Crawler
local SpawnPhantomEvent = CreateBindableEvent("SpawnPhantomEvent")   -- Phantom
local SpawnWatcherEvent = CreateBindableEvent("SpawnWatcherEvent")   -- Watcher
local SpawnHarvesterEvent = CreateBindableEvent("SpawnHarvesterEvent") -- Harvester

local CurrencyRemotes = ReplicatedStorage:FindFirstChild("CurrencyRemotes") or Instance.new("Folder")
CurrencyRemotes.Name = "CurrencyRemotes"
CurrencyRemotes.Parent = ReplicatedStorage

local function GetOrCreateRemote(name)
	local existing = CurrencyRemotes: FindFirstChild(name)
	if existing then return existing end
	local new = Instance.new("RemoteEvent")
	new.Name = name
	new.Parent = CurrencyRemotes
	return new
end

local UpdateCurrencyEvent = GetOrCreateRemote("UpdateCurrency")
local DoorOpenedEvent = GetOrCreateRemote("DoorOpened")
local SurvivedDoorEvent = GetOrCreateRemote("SurvivedDoor")
local PlayerDiedEvent = GetOrCreateRemote("PlayerDied")
local OpenShopEvent = GetOrCreateRemote("OpenShop")
local SyncDataEvent = GetOrCreateRemote("SyncData")
local PurchaseItemEvent = GetOrCreateRemote("PurchaseItem")
local UseItemEvent = GetOrCreateRemote("UseItem")
local BoostUpdateEvent = GetOrCreateRemote("BoostUpdate")
local DoorLockedEvent = GetOrCreateRemote("DoorLocked") -- New event for locked door message

-- -------------------------------------------------------------------------------
-- NPC CONFIGURATION - ALL 6 NPCs WITH FULL STATS
-- -------------------------------------------------------------------------------

local NPC_STATS = {
	-- ---------------------------------------------------------------------------
	-- SHADOW - Common, basic enemy (Most common)
	-- ---------------------------------------------------------------------------
	SHADOW = {
		NAME = "Shadow",
		SPAWN_EVENT = SpawnNPCEvent,
		RARITY = "Common",
		SPAWN_WEIGHT = 2,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 15,
		SURVIVAL_TIME = 45,

		SPEED = 18,
		DAMAGE = 20,
		ATTACK_COOLDOWN = 0.8,
		ATTACK_RANGE = 5,
		DETECTION_RANGE = 200,
		LIFETIME = 45,

		USES_LARGE_DOOR = false,
		EYE_COLOR = Color3.new(1, 1, 1),
		EYE_TYPE = "STANDARD",
		DESCRIPTION = "A dark humanoid figure with glowing white eyes",
		DANGER_LEVEL = 1,
	},

	-- ---------------------------------------------------------------------------
	-- CRAWLER - Uncommon, fast spider-like creature (8 eyes)
	-- ---------------------------------------------------------------------------
	CRAWLER = {
		NAME = "Crawler",
		SPAWN_EVENT = SpawnCrawlerEvent,
		RARITY = "Uncommon",
		SPAWN_WEIGHT = 2,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 20,
		SURVIVAL_TIME = 50,

		SPEED = 24,
		DAMAGE = 25,
		ATTACK_COOLDOWN = 0.5,
		ATTACK_RANGE = 6,
		DETECTION_RANGE = 250,
		LIFETIME = 50,

		USES_LARGE_DOOR = false,
		EYE_COLOR = Color3.fromRGB(0, 255, 150),
		EYE_TYPE = "CRAWLER_8EYES",
		DESCRIPTION = "An 8-legged spider-like creature with multiple green eyes",
		DANGER_LEVEL = 2,
	},

	-- ---------------------------------------------------------------------------
	-- PHANTOM - Uncommon, teleporting ghost (Cyan ghostly eyes)
	-- -------------------------------------------------------??-------------------
	PHANTOM = {
		NAME = "Phantom",
		SPAWN_EVENT = SpawnPhantomEvent,
		RARITY = "Uncommon",
		SPAWN_WEIGHT = 2,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 25,
		SURVIVAL_TIME = 55,

		SPEED = 14,
		DAMAGE = 35,
		ATTACK_COOLDOWN = 1.5,
		ATTACK_RANGE = 8,
		DETECTION_RANGE = 280,
		LIFETIME = 55,

		USES_LARGE_DOOR = false,
		EYE_COLOR = Color3.fromRGB(0, 200, 200), -- Cyan/teal color from image
		EYE_TYPE = "PHANTOM_GLOW",
		TELEPORT_COOLDOWN = 5,
		FREEZE_DURATION = 1.5,
		DESCRIPTION = "A floating ethereal ghost that can teleport and freeze players",
		DANGER_LEVEL = 3,
	},

	-- ---------------------------------------------------------------------------
	-- SCREAMER - Rare, giant aggressive monster
	-- ----------------------------------------???----------------------------------
	SCREAMER = {
		NAME = "Screamer",
		SPAWN_EVENT = SpawnScreamerEvent,
		RARITY = "Rare",
		SPAWN_WEIGHT = 90,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 30,
		SURVIVAL_TIME = 45,

		SPEED = 20,
		DAMAGE = 65,
		ATTACK_COOLDOWN = 1.2,
		ATTACK_RANGE = 12,
		DETECTION_RANGE = 300,
		LIFETIME = 45,

		USES_LARGE_DOOR = true,
		EYE_COLOR = Color3.fromRGB(255, 0, 0),
		EYE_TYPE = "STANDARD",
		DESCRIPTION = "A massive humanoid with a screaming mouth and brutal double-swipe attacks",
		DANGER_LEVEL = 4,
	},

	-- ---------------------------------------------------------------------------
	-- WATCHER - Rare, ranged eye monster (Single large white eye)
	-- ---------------------------------------------------------------------------
	WATCHER = {
		NAME = "Watcher",
		SPAWN_EVENT = SpawnWatcherEvent,
		RARITY = "Rare",
		SPAWN_WEIGHT = 2,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 35,
		SURVIVAL_TIME = 60,

		SPEED = 10,
		DAMAGE = 40,
		ATTACK_COOLDOWN = 2.5,
		ATTACK_RANGE = 25,
		DETECTION_RANGE = 350,
		LIFETIME = 60,

		USES_LARGE_DOOR = true,
		EYE_COLOR = Color3.fromRGB(255, 255, 255),
		EYE_TYPE = "WATCHER_SINGLE",
		BEAM_CHARGE_TIME = 1.0,
		PARALYZE_DURATION = 1.5,
		DESCRIPTION = "A giant floating eyeball with tentacles that shoots paralyzing beams",
		DANGER_LEVEL = 4,
	},

	-- ---------------------------------------------------------------------------
	-- HARVESTER - Legendary, grim reaper boss (Red eyes + blue center light)
	-- ---------------------------------------------------------------------------
	HARVESTER = {
		NAME = "Harvester",
		SPAWN_EVENT = SpawnHarvesterEvent,
		RARITY = "Legendary",
		SPAWN_WEIGHT = 2,

		REWARD_DOOR_OPEN = 5,
		REWARD_SURVIVAL = 40,
		SURVIVAL_TIME = 65,

		SPEED = 12,
		DAMAGE = 55,
		ATTACK_COOLDOWN = 1.8,
		ATTACK_RANGE = 10,
		DETECTION_RANGE = 320,
		LIFETIME = 65,

		USES_LARGE_DOOR = true,
		EYE_COLOR = Color3.fromRGB(255, 150, 150), -- Pinkish-red from image
		EYE_TYPE = "HARVESTER_REAPER",
		TELEPORT_BEHIND_CHANCE = 0.2,
		SOUL_DRAIN_PERCENT = 0.1,
		DESCRIPTION = "A grim reaper with a massive scythe that can teleport behind you",
		DANGER_LEVEL = 5,
	},
}

-- Calculate total weight for probability
local TOTAL_NPC_WEIGHT = 0
for _, npcData in pairs(NPC_STATS) do
	TOTAL_NPC_WEIGHT = TOTAL_NPC_WEIGHT + npcData.SPAWN_WEIGHT
end

-- -------------------------------------------------------------------------------
-- DOOR OUTCOME CONFIGURATION - 70% OPEN / 30% NOTHING
-- -------------------------------------------------------------------------------

local DOOR_CONFIG = {
	OPEN_CHANCE = 70,
	NOTHING_CHANCE = 30,
}

-- -------------------------------------------------------------------------------
-- DOOR & NPC SOUND CONFIGURATION (WITH VOLUME CONTROL)
-- -------------------------------------------------------------------------------

local DOOR_SOUNDS = {
	KNOCK = {
		id = "rbxassetid://75890067861325",
		volume = 0.9,
		duration = 1,
	},
	OPEN = {
		id = "rbxassetid://125335848390963",
		volume = 0.9,
		duration = 1.5,
	},
	CLOSE = {
		id = "rbxassetid://111817951216044",
		volume = 0.8,
		duration = 1.0,
	},
}

local NPC_SOUNDS = {
	SHADOW = {
		id = "rbxassetid://138943631473339",
		volume = 0.1,
		duration = 3.6,
	},
	SCREAMER = {
		id = "rbxassetid://101616656965701",
		volume = 0.7,
		duration = 3.6,
	},
	CRAWLER = {
		id = "rbxassetid://107648717902572",
		volume = 0.5,
		duration = 3.0,
	},
	PHANTOM = {
		id = "rbxassetid://84942852431417",
		volume = 0.6,
		duration = 2.0,
	},
	WATCHER = {
		id = "rbxassetid://116711110416425",
		volume = 0.7,
		duration = 2.0,
	},
	HARVESTER = {
		id = "rbxassetid://131322398837604",
		volume = 0.8,
		duration = 3.0,
	},
}

local DOOR_MASTER_VOLUME = 1.0
local NPC_MASTER_VOLUME = 1.0

local KNOCK_CONFIG = {
	TOTAL_DURATION = 1,
	NUM_KNOCKS = 3,
	VIBRATION_INTENSITY = 0.15,
	VIBRATION_DURATION = 0.08,
}

-- -------------------------------------------------------------------------------
-- ANIMATION TIMING CONFIG - Synchronized for all NPCs
-- -------------------------------------------------------------------------------

local ANIMATION_TIMING = {
	EYES_FADE_IN = 0.5,
	EYES_VISIBLE_DURATION = 2.0,
	BLINK_COUNT = 2,
	BLINK_OFF_TIME = 0.08,
	BLINK_ON_TIME = 0.17,
	BLINK_PAUSE = 0.4,
	EYES_FADE_OUT = 0.2,
}

local function CreateDoorSound(soundConfig, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = soundConfig.id
	sound.Volume = soundConfig.volume * DOOR_MASTER_VOLUME
	sound.RollOffMaxDistance = 50
	sound.RollOffMinDistance = 5
	sound.Parent = parent
	return sound
end

local function CreateNPCSound(soundConfig, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = soundConfig.id
	sound.Volume = soundConfig.volume * NPC_MASTER_VOLUME
	sound.RollOffMaxDistance = 60
	sound.RollOffMinDistance = 5
	sound.Parent = parent
	return sound
end

-- -------------------------------------------------------------------------------
-- GENERAL CONFIGURATION
-- -------------------------------------------------------------------------------

local CONFIG = {
	LOBBY_LENGTH = 150,
	LOBBY_START_X = -75,
	LOBBY_END_X = 75,

	STREET_WIDTH = 50,
	STREET_SEGMENT_LENGTH = 100,
	SIDEWALK_WIDTH = 10,
	GENERATION_DISTANCE = 300,
	CLEANUP_DISTANCE = 500,

	BUILDING_WIDTH = 25,
	BUILDING_MIN_HEIGHT = 30,
	BUILDING_MAX_HEIGHT = 70,
	BUILDING_DEPTH = 15,

	DOOR_CHANCE = 0.25,
	DOOR_WIDTH = 5,
	DOOR_HEIGHT = 8,

	HOLE_WIDTH_NORMAL = 7,
	HOLE_HEIGHT_NORMAL = 10,
	HOLE_WIDTH_LARGE = 10,
	HOLE_HEIGHT_LARGE = 12,

	SIGN_WIDTH = 8,
	SIGN_HEIGHT = 3,

	COLORS = {
		STREET = Color3.fromRGB(45, 45, 50),
		SIDEWALK = Color3.fromRGB(75, 75, 80),
		BUILDING_1 = Color3.fromRGB(60, 55, 65),
		BUILDING_2 = Color3.fromRGB(70, 65, 75),
		BUILDING_3 = Color3.fromRGB(55, 60, 70),
		BUILDING_4 = Color3.fromRGB(75, 70, 80),
		BUILDING_TRIM = Color3.fromRGB(40, 38, 45),
		DOOR = Color3.fromRGB(110, 75, 40),
		DOOR_FRAME = Color3.fromRGB(150, 100, 55),
		DOOR_LIGHT = Color3.fromRGB(255, 200, 150),
		SIGN_BG = Color3.fromRGB(15, 13, 20),
		SIGN_TEXT = Color3.fromRGB(210, 190, 170),
		SIGN_BORDER = Color3.fromRGB(110, 90, 70),
		WINDOW_DARK = Color3.fromRGB(10, 10, 20),
		WINDOW_LIT = Color3.fromRGB(255, 200, 100),
		STREET_LINES = Color3.fromRGB(180, 180, 120),
		LAMP_POST = Color3.fromRGB(45, 45, 50),
		LAMP_LIGHT = Color3.fromRGB(255, 220, 180),
		VOID = Color3.fromRGB(0, 0, 0),
		LOBBY_FLOOR = Color3.fromRGB(70, 70, 75),
		LOBBY_ACCENT = Color3.fromRGB(80, 120, 180),
		SAFE_ZONE = Color3.fromRGB(50, 150, 100),
	},

	DOOR_NAMES = {
		"The Void", "No Return", "Shadows", "Oblivion", "Eternal Fog",
		"Whispers", "The Nothing", "Specters", "Abyss", "Twilight",
		"Silence", "Ghosts", "Darkness", "The End", "Mist",
		"Secrets", "Mystery", "Hidden", "Perdition", "Eternal",
		"Dark Caf�", "Fog Hotel", "Eclipse Bar", "Midnight Club",
		"Closed Shop", "Office 404", "Empty Studio", "Warehouse X",
		"Room 13", "Suite Omega", "Clinic", "Dead Archive",
		"???  ", "ERROR", "NULL", "VOID", "2:  47 AM", "For Rent", "5: 05",
		"3: 33", "CLOSED", "Nothing", "Gone", "Lost", "Forgotten",
		"Nightmare", "Dream", "Echo", "Static", "Glitch",
	},

	LAMP_SPACING = 40,
	LAMP_HEIGHT = 18,
}

-- Global variables
local streetSegments = {}
local generatedSegments = {}
local worldFolder = Instance.new("Folder")
worldFolder.Name = "InfiniteStreetWorld"
worldFolder.Parent = workspace

local lobbyFolder = Instance.new("Folder")
lobbyFolder.Name = "LobbyArea"
lobbyFolder.Parent = workspace

local buildingColors = {CONFIG.COLORS.BUILDING_1, CONFIG.COLORS.BUILDING_2, CONFIG.COLORS.BUILDING_3, CONFIG.COLORS.BUILDING_4}
local doorsBeingUsed = {}
local playerDoorSurvival = {}

_G.IsInSafeZone = function(position)
	return position.X >= CONFIG.LOBBY_START_X and position.X <= CONFIG.LOBBY_END_X
end

_G.SafeZoneBounds = {
	minX = CONFIG.LOBBY_START_X,
	maxX = CONFIG.LOBBY_END_X
}

-- -------------------------------------------------------------------------------
-- TRUE RANDOM GENERATOR
-- ---------------------------------------------------??---------------------------

local randomGenerator = Random.new()

local function TrueRandom(min, max)
	return randomGenerator: NextInteger(min, max)
end

local function TrueRandomFloat()
	return randomGenerator:NextNumber()
end

local function SeededRandom(seed, min, max)
	local x = math.sin(seed * 12.9898 + seed * 78.233) * 43758.5453
	local normalized = x - math.floor(x)
	return math.floor(min + normalized * (max - min + 1))
end

local function SeededRandomFloat(seed)
	local x = math.sin(seed * 12.9898 + seed * 78.233) * 43758.5453
	return x - math.floor(x)
end

-- -------------------------------------------------------------------------------
-- NEW DOOR OUTCOME SYSTEM - 70% OPEN / 30% NOTHING
-- -------------------------------------------------------------------------------

local function GetDoorOutcome()
	local roll = TrueRandomFloat() * 100

	if roll < DOOR_CONFIG.NOTHING_CHANCE then
		return "nothing", nil
	end

	local npcRoll = TrueRandomFloat() * TOTAL_NPC_WEIGHT
	local accumulated = 0

	for npcType, npcData in pairs(NPC_STATS) do
		accumulated = accumulated + npcData.SPAWN_WEIGHT
		if npcRoll <= accumulated then
			return "npc", npcType
		end
	end

	return "npc", "SHADOW"
end

local function GetRandomDoorName()
	return CONFIG.DOOR_NAMES[TrueRandom(1, #CONFIG.DOOR_NAMES)]
end

-- -------------------------------------------------------------------------------
-- UTILITIES
-- -------------------------------------------------------------------------------

local function LerpColor(c1, c2, t)
	return Color3.new(c1.R + (c2.R - c1.R) * t, c1.G + (c2.G - c1.G) * t, c1.B + (c2.B - c1.B) * t)
end

local function MakePart(name, size, position, color, material, parent, canCollide, castShadow, transparency)
	local part = Instance.new("Part")
	part.Name = name or "Part"
	part.Size = size or Vector3.new(1, 1, 1)
	part.Position = position or Vector3.new(0, 0, 0)
	part.Color = color or Color3.new(1, 1, 1)
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CastShadow = castShadow ~= false
	part.Transparency = transparency or 0
	part.Parent = parent or workspace
	return part
end

-- -------------------------------------------------------------------------------
-- DOOR VIBRATION ANIMATION
-- -----------------------------------------------------???-------------------------

local function VibrateDoorPart(doorPart, originalCFrame, zDir)
	if not doorPart or not doorPart.Parent then return end

	local intensity = KNOCK_CONFIG.VIBRATION_INTENSITY
	local duration = KNOCK_CONFIG.VIBRATION_DURATION

	local shakeCFrame = originalCFrame * CFrame.new(0, 0, zDir * intensity)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenForward = TweenService:Create(doorPart, tweenInfo, {CFrame = shakeCFrame})
	tweenForward:Play()
	tweenForward.Completed:Wait()

	local tweenBack = TweenService:Create(doorPart, tweenInfo, {CFrame = originalCFrame})
	tweenBack: Play()
	tweenBack.Completed:Wait()
end

local function PlayKnockVibration(doorPart, zDir)
	if not doorPart or not doorPart.Parent then return end

	local originalCFrame = doorPart.CFrame
	local knockInterval = KNOCK_CONFIG.TOTAL_DURATION / KNOCK_CONFIG.NUM_KNOCKS

	for i = 1, KNOCK_CONFIG.NUM_KNOCKS do
		task.spawn(function()
			task.wait((i - 1) * knockInterval)
			VibrateDoorPart(doorPart, originalCFrame, zDir)
		end)
	end
end

-- -------------------------------------------------------------------------------
-- LIGHTING
-- -------------------------------------------------------------------------------

local function SetupAtmosphere()
	Lighting.Brightness = 0.8
	Lighting.Ambient = Color3.fromRGB(40, 40, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(55, 50, 65)
	Lighting.ClockTime = 4.5
	Lighting.GeographicLatitude = 45
	Lighting.FogColor = Color3.fromRGB(20, 18, 30)
	Lighting.FogEnd = 500
	Lighting.FogStart = 80
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3

	local atm = Lighting: FindFirstChild("Atmosphere") or Instance.new("Atmosphere")
	atm.Name = "Atmosphere"
	atm.Density = 0.35
	atm.Offset = 0.1
	atm.Color = Color3.fromRGB(50, 45, 65)
	atm.Decay = Color3.fromRGB(40, 35, 55)
	atm.Glare = 0.1
	atm.Haze = 5
	atm.Parent = Lighting

	local bloom = Lighting:FindFirstChild("BloomEffect") or Instance.new("BloomEffect")
	bloom.Name = "BloomEffect"
	bloom.Intensity = 0.5
	bloom.Size = 40
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local cc = Lighting:FindFirstChild("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Name = "ColorCorrectionEffect"
	cc.Brightness = 0.05
	cc.Contrast = 0.15
	cc.Saturation = -0.2
	cc.TintColor = Color3.fromRGB(220, 210, 230)
	cc.Parent = Lighting

	local sky = Lighting:FindFirstChild("Sky") or Instance.new("Sky")
	sky.Name = "Sky"
	sky.StarCount = 1500
	sky.MoonAngularSize = 14
	sky.SunAngularSize = 0
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
end

-- -------------------------------------------------------------------------------
-- WINDOWS
-- -------------------------------------------------------------------------------

local function CreateWindows(centerX, centerY, faceZ, width, height, zDir, parent, doorCenterX, holeWidth)
	local winW, winH = 2.5, 3.5
	local gapH, gapV = 5.5, 6
	local startY = 6
	local hw = holeWidth or CONFIG.HOLE_WIDTH_NORMAL

	local cols = math.floor((width - 6) / gapH)
	local rows = math.floor((height - startY - 4) / gapV)

	for row = 1, rows do
		for col = 1, cols do
			local offX = -width/2 + 4 + (col - 0.5) * gapH
			local offY = -height/2 + startY + (row - 0.5) * gapV
			local winX = centerX + offX
			local winY = centerY + offY

			local nearDoor = doorCenterX and math.abs(winX - doorCenterX) < (hw/2 + 1)
			if nearDoor and row <= 2 then
				continue
			end

			local lit = SeededRandomFloat(winX * 100 + winY) < 0.08

			MakePart("WinFrame", Vector3.new(winW + 0.4, winH + 0.4, 0.15),
				Vector3.new(winX, winY, faceZ + zDir * 0.08),
				CONFIG.COLORS.BUILDING_TRIM, Enum.Material.Concrete, parent, false, false)

			local win = MakePart("Window", Vector3.new(winW, winH, 0.08),
				Vector3.new(winX, winY, faceZ + zDir * 0.15),
				lit and CONFIG.COLORS.WINDOW_LIT or CONFIG.COLORS.WINDOW_DARK,
				lit and Enum.Material.Neon or Enum.Material.Glass,
				parent, false, false, lit and 0 or 0.85)

			if lit then
				local light = Instance.new("PointLight")
				light.Brightness = 0.4
				light.Color = CONFIG.COLORS.WINDOW_LIT
				light.Range = 12
				light.Shadows = false
				light.Parent = win
			end
		end
	end
end

-- -------------------------------------------------------------------------------
-- DOOR SYSTEM WITH VOID - 6 NPC SYSTEM + CUSTOM EYE ANIMATIONS
-- -------------------------------------------------------------------------------

local function CreateDoorWithVoid(doorX, faceZ, backZ, zDir, side, parent, buildingColor)
	local doorFolder = Instance.new("Folder")
	doorFolder.Name = "DoorSystem"
	doorFolder.Parent = parent

	local outcome, npcType = GetDoorOutcome()
	local npcData = npcType and NPC_STATS[npcType] or nil

	local floorY = 0.5
	local doorCenterY = floorY + CONFIG.DOOR_HEIGHT / 2

	local holeW, holeH
	if npcData and npcData.USES_LARGE_DOOR then
		holeW = CONFIG.HOLE_WIDTH_LARGE
		holeH = CONFIG.HOLE_HEIGHT_LARGE
	else
		holeW = CONFIG.HOLE_WIDTH_NORMAL
		holeH = CONFIG.HOLE_HEIGHT_NORMAL
	end

	local voidDepth = math.abs(backZ - faceZ)
	local voidCenterZ = (faceZ + backZ) / 2

	MakePart("VoidBack", Vector3.new(holeW, holeH, 1),
		Vector3.new(doorX, floorY + holeH/2 - 0.5, backZ + zDir * 0.5),
		CONFIG.COLORS.VOID, Enum.Material.SmoothPlastic, doorFolder, true, false)

	MakePart("VoidLeft", Vector3.new(0.3, holeH, voidDepth),
		Vector3.new(doorX - holeW/2 + 0.15, floorY + holeH/2 - 0.5, voidCenterZ),
		CONFIG.COLORS.VOID, Enum.Material.SmoothPlastic, doorFolder, true, false)

	MakePart("VoidRight", Vector3.new(0.3, holeH, voidDepth),
		Vector3.new(doorX + holeW/2 - 0.15, floorY + holeH/2 - 0.5, voidCenterZ),
		CONFIG.COLORS.VOID, Enum.Material.SmoothPlastic, doorFolder, true, false)

	MakePart("VoidTop", Vector3.new(holeW, 0.3, voidDepth),
		Vector3.new(doorX, floorY + holeH - 0.65, voidCenterZ),
		CONFIG.COLORS.VOID, Enum.Material.SmoothPlastic, doorFolder, true, false)

	MakePart("VoidFloor", Vector3.new(holeW, 0.3, voidDepth),
		Vector3.new(doorX, floorY - 0.35, voidCenterZ),
		CONFIG.COLORS.VOID, Enum.Material.SmoothPlastic, doorFolder, true, false)

	local frameT = 0.4
	local frameZ = faceZ + zDir * 0.05

	MakePart("FrameTop", Vector3.new(CONFIG.DOOR_WIDTH + frameT*2, frameT, 0.4),
		Vector3.new(doorX, floorY + CONFIG.DOOR_HEIGHT + frameT/2, frameZ),
		CONFIG.COLORS.DOOR_FRAME, Enum.Material.Wood, doorFolder, false)

	MakePart("FrameLeft", Vector3.new(frameT, CONFIG.DOOR_HEIGHT, 0.4),
		Vector3.new(doorX - CONFIG.DOOR_WIDTH/2 - frameT/2, doorCenterY, frameZ),
		CONFIG.COLORS.DOOR_FRAME, Enum.Material.Wood, doorFolder, false)

	MakePart("FrameRight", Vector3.new(frameT, CONFIG.DOOR_HEIGHT, 0.4),
		Vector3.new(doorX + CONFIG.DOOR_WIDTH/2 + frameT/2, doorCenterY, frameZ),
		CONFIG.COLORS.DOOR_FRAME, Enum.Material.Wood, doorFolder, false)

	local totalFrameW = CONFIG.DOOR_WIDTH + frameT * 2
	local sideGap = (holeW - totalFrameW) / 2

	if sideGap > 0.05 then
		MakePart("CoverL", Vector3.new(sideGap, holeH, 0.25),
			Vector3.new(doorX - totalFrameW/2 - sideGap/2, floorY + holeH/2 - 0.5, faceZ),
			buildingColor, Enum.Material.Concrete, doorFolder, false, false)

		MakePart("CoverR", Vector3.new(sideGap, holeH, 0.25),
			Vector3.new(doorX + totalFrameW/2 + sideGap/2, floorY + holeH/2 - 0.5, faceZ),
			buildingColor, Enum.Material.Concrete, doorFolder, false, false)
	end

	local topGap = holeH - CONFIG.DOOR_HEIGHT - frameT
	if topGap > 0.05 then
		MakePart("CoverT", Vector3.new(holeW, topGap, 0.25),
			Vector3.new(doorX, floorY + CONFIG.DOOR_HEIGHT + frameT + topGap/2, faceZ),
			buildingColor, Enum.Material.Concrete, doorFolder, false, false)
	end

	local doorModel = Instance.new("Model")
	doorModel.Name = "DoorModel"
	doorModel.Parent = doorFolder

	local hingeX = doorX - CONFIG.DOOR_WIDTH / 2
	local doorZ = faceZ + zDir * 0.1
	local doorThick = 0.25

	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(CONFIG.DOOR_WIDTH, CONFIG.DOOR_HEIGHT, doorThick)
	door.Position = Vector3.new(doorX, doorCenterY, doorZ)
	door.Color = CONFIG.COLORS.DOOR
	door.Material = Enum.Material.Wood
	door.Anchored = true
	door.CanCollide = true
	door.Parent = doorModel

	local panelColor = LerpColor(CONFIG.COLORS.DOOR, Color3.fromRGB(80, 50, 30), 0.15)
	local panels = {}

	for py = 1, 2 do
		for px = 1, 2 do
			local pw = CONFIG.DOOR_WIDTH/2 - 0.5
			local ph = CONFIG.DOOR_HEIGHT/2 - 0.8
			local ox = (px - 1.5) * (CONFIG.DOOR_WIDTH/2 - 0.15)
			local oy = (py - 1.5) * (CONFIG.DOOR_HEIGHT/2 - 0.25)

			local panel = Instance.new("Part")
			panel.Name = "Panel"
			panel.Size = Vector3.new(pw, ph, 0.08)
			panel.Position = door.Position + Vector3.new(ox, oy, zDir * (doorThick/2 + 0.04))
			panel.Color = panelColor
			panel.Material = Enum.Material.Wood
			panel.Anchored = true
			panel.CanCollide = false
			panel.Parent = doorModel
			table.insert(panels, {part = panel, offset = Vector3.new(ox, oy, zDir * (doorThick/2 + 0.04))})
		end
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.15, 0.7, 0.15)
	handle.Position = door.Position + Vector3.new(CONFIG.DOOR_WIDTH/2 - 0.5, -0.15, zDir * (doorThick/2 + 0.08))
	handle.Color = Color3.fromRGB(190, 170, 90)
	handle.Material = Enum.Material.Metal
	handle.Anchored = true
	handle.CanCollide = false
	handle.Parent = doorModel
	local handleOffset = Vector3.new(CONFIG.DOOR_WIDTH/2 - 0.5, -0.15, zDir * (doorThick/2 + 0.08))

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 10
	click.Parent = door

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Knock"
	prompt.ObjectText = "Door"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	local doorLight = MakePart("DoorLight", Vector3.new(0.6, 0.3, 0.3),
		Vector3.new(doorX, floorY + CONFIG.DOOR_HEIGHT + 1, faceZ + zDir * 0.5),
		CONFIG.COLORS.DOOR_LIGHT, Enum.Material.Neon, doorFolder, false, false, 0.1)
	local dl = Instance.new("PointLight")
	dl.Brightness = 0.7
	dl.Color = CONFIG.COLORS.DOOR_LIGHT
	dl.Range = 10
	dl.Shadows = false
	dl.Parent = doorLight

	local signZ = faceZ + zDir * 1.2
	local signBG = MakePart("SignBG", Vector3.new(CONFIG.SIGN_WIDTH, CONFIG.SIGN_HEIGHT, 0.12),
		Vector3.new(doorX, floorY + CONFIG.DOOR_HEIGHT + CONFIG.SIGN_HEIGHT/2 + 2, signZ),
		CONFIG.COLORS.SIGN_BG, Enum.Material.SmoothPlastic, doorFolder, false)

	MakePart("SignBorderT", Vector3.new(CONFIG.SIGN_WIDTH + 0.2, 0.08, 0.2),
		signBG.Position + Vector3.new(0, CONFIG.SIGN_HEIGHT/2 + 0.04, 0),
		CONFIG.COLORS.SIGN_BORDER, Enum.Material.Metal, doorFolder, false)

	MakePart("SignBorderB", Vector3.new(CONFIG.SIGN_WIDTH + 0.2, 0.08, 0.2),
		signBG.Position + Vector3.new(0, -CONFIG.SIGN_HEIGHT/2 - 0.04, 0),
		CONFIG.COLORS.SIGN_BORDER, Enum.Material.Metal, doorFolder, false)

	local doorName = GetRandomDoorName()
	for _, f in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = f
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 45
		gui.Parent = signBG

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Text = doorName
		txt.TextColor3 = CONFIG.COLORS.SIGN_TEXT
		txt.TextScaled = true
		txt.Font = Enum.Font.Antique
		txt.Parent = gui
	end

	local signL = Instance.new("PointLight")
	signL.Brightness = 0.25
	signL.Color = Color3.fromRGB(200, 180, 150)
	signL.Range = 5
	signL.Parent = signBG

	-- ---------------------------------------------------------------------------
	-- CUSTOM EYE CREATION BASED ON NPC TYPE
	-- ---------------------------------------------------------------------------

	local eyeY = floorY + CONFIG.DOOR_HEIGHT/2 + 1.5
	local eyeZ = voidCenterZ
	local eyeParts = {}
	local eyeLights = {}

	local eyeType = npcData and npcData.EYE_TYPE or "STANDARD"
	local eyeColor = npcData and npcData.EYE_COLOR or Color3.new(1, 1, 1)

	if eyeType == "STANDARD" then
		-- SHADOW and SCREAMER - Two standard oval eyes
		local eyeGap = 0.4

		local leftEye = MakePart("LeftEye", Vector3.new(0.15, 0.35, 0.06),
			Vector3.new(doorX - eyeGap/2, eyeY, eyeZ),
			eyeColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local rightEye = MakePart("RightEye", Vector3.new(0.15, 0.35, 0.06),
			Vector3.new(doorX + eyeGap/2, eyeY, eyeZ),
			eyeColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local leftEyeLight = Instance.new("PointLight")
		leftEyeLight.Brightness = 0
		leftEyeLight.Color = eyeColor
		leftEyeLight.Range = 5
		leftEyeLight.Parent = leftEye

		local rightEyeLight = Instance.new("PointLight")
		rightEyeLight.Brightness = 0
		rightEyeLight.Color = eyeColor
		rightEyeLight.Range = 5
		rightEyeLight.Parent = rightEye

		table.insert(eyeParts, leftEye)
		table.insert(eyeParts, rightEye)
		table.insert(eyeLights, leftEyeLight)
		table.insert(eyeLights, rightEyeLight)

	elseif eyeType == "CRAWLER_8EYES" then
		-- CRAWLER - 8 green eyes (2 big on top, 6 smaller below)
		local greenColor = Color3.fromRGB(0, 255, 150)

		-- Top 2 large eyes
		local bigEyeSize = Vector3.new(0.25, 0.4, 0.06)
		local bigEyeGap = 0.5

		local topLeftEye = MakePart("TopLeftEye", bigEyeSize,
			Vector3.new(doorX - bigEyeGap/2, eyeY + 0.3, eyeZ),
			greenColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local topRightEye = MakePart("TopRightEye", bigEyeSize,
			Vector3.new(doorX + bigEyeGap/2, eyeY + 0.3, eyeZ),
			greenColor, Enum.Material.Neon, doorFolder, false, false, 1)

		table.insert(eyeParts, topLeftEye)
		table.insert(eyeParts, topRightEye)

		local topLeftLight = Instance.new("PointLight")
		topLeftLight.Brightness = 0
		topLeftLight.Color = greenColor
		topLeftLight.Range = 6
		topLeftLight.Parent = topLeftEye
		table.insert(eyeLights, topLeftLight)

		local topRightLight = Instance.new("PointLight")
		topRightLight.Brightness = 0
		topRightLight.Color = greenColor
		topRightLight.Range = 6
		topRightLight.Parent = topRightEye
		table.insert(eyeLights, topRightLight)

		-- Bottom 6 smaller eyes (3 on each side)
		local smallEyeSize = Vector3.new(0.12, 0.2, 0.05)
		local smallEyePositions = {
			{x = -0.6, y = 0},
			{x = -0.35, y = -0.25},
			{x = -0.15, y = -0.4},
			{x = 0.15, y = -0.4},
			{x = 0.35, y = -0.25},
			{x = 0.6, y = 0},
		}

		for i, pos in ipairs(smallEyePositions) do
			local smallEye = MakePart("SmallEye" ..i, smallEyeSize,
				Vector3.new(doorX + pos.x, eyeY + pos.y, eyeZ),
				greenColor, Enum.Material.Neon, doorFolder, false, false, 1)

			local smallLight = Instance.new("PointLight")
			smallLight.Brightness = 0
			smallLight.Color = greenColor
			smallLight.Range = 3
			smallLight.Parent = smallEye

			table.insert(eyeParts, smallEye)
			table.insert(eyeLights, smallLight)
		end

	elseif eyeType == "PHANTOM_GLOW" then
		-- PHANTOM - Cyan/teal ghostly glowing eyes (from image 1)
		local phantomColor = Color3.fromRGB(0, 200, 200) -- Cyan/teal
		local eyeGap = 0.5

		local leftEye = MakePart("LeftEye", Vector3.new(0.25, 0.35, 0.08),
			Vector3.new(doorX - eyeGap/2, eyeY, eyeZ),
			phantomColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local rightEye = MakePart("RightEye", Vector3.new(0.25, 0.35, 0.08),
			Vector3.new(doorX + eyeGap/2, eyeY, eyeZ),
			phantomColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local leftEyeLight = Instance.new("PointLight")
		leftEyeLight.Brightness = 0
		leftEyeLight.Color = phantomColor
		leftEyeLight.Range = 8
		leftEyeLight.Parent = leftEye

		local rightEyeLight = Instance.new("PointLight")
		rightEyeLight.Brightness = 0
		rightEyeLight.Color = phantomColor
		rightEyeLight.Range = 8
		rightEyeLight.Parent = rightEye

		table.insert(eyeParts, leftEye)
		table.insert(eyeParts, rightEye)
		table.insert(eyeLights, leftEyeLight)
		table.insert(eyeLights, rightEyeLight)

	elseif eyeType == "WATCHER_SINGLE" then
		-- WATCHER - Single LARGE bright white circular eye
		local watcherColor = Color3.fromRGB(255, 255, 255)

		-- Main large eye circle (using a flat cylinder facing forward)
		local singleEye = MakePart("SingleEye", Vector3.new(1.5, 1.5, 0.08),
			Vector3.new(doorX, eyeY, eyeZ),
			watcherColor, Enum.Material.Neon, doorFolder, false, false, 1)

		-- Inner glow ring
		local innerGlow = MakePart("InnerGlow", Vector3.new(1.2, 1.2, 0.06),
			Vector3.new(doorX, eyeY, eyeZ + 0.02),
			watcherColor, Enum.Material.Neon, doorFolder, false, false, 1)

		-- Center pupil (slightly different shade)
		local pupil = MakePart("Pupil", Vector3.new(0.5, 0.5, 0.04),
			Vector3.new(doorX, eyeY, eyeZ + 0.04),
			Color3.fromRGB(200, 230, 255), Enum.Material.Neon, doorFolder, false, false, 1)

		local eyeLight = Instance.new("PointLight")
		eyeLight.Brightness = 0
		eyeLight.Color = watcherColor
		eyeLight.Range = 20
		eyeLight.Parent = singleEye

		local innerLight = Instance.new("PointLight")
		innerLight.Brightness = 0
		innerLight.Color = watcherColor
		innerLight.Range = 15
		innerLight.Parent = innerGlow

		table.insert(eyeParts, singleEye)
		table.insert(eyeParts, innerGlow)
		table.insert(eyeParts, pupil)
		table.insert(eyeLights, eyeLight)
		table.insert(eyeLights, innerLight)

	elseif eyeType == "HARVESTER_REAPER" then
		-- HARVESTER - Two pinkish-red eyes + skull mouth (3 vertical rectangles)
		local redEyeColor = Color3.fromRGB(255, 150, 150)
		local skullMouthColor = Color3.fromRGB(180, 200, 255)

		local eyeGap = 0.6

		-- Red eyes
		local leftEye = MakePart("LeftEye", Vector3.new(0.2, 0.3, 0.06),
			Vector3.new(doorX - eyeGap/2, eyeY + 0.3, eyeZ),
			redEyeColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local rightEye = MakePart("RightEye", Vector3.new(0.2, 0.3, 0.06),
			Vector3.new(doorX + eyeGap/2, eyeY + 0.3, eyeZ),
			redEyeColor, Enum.Material.Neon, doorFolder, false, false, 1)

		local leftEyeLight = Instance.new("PointLight")
		leftEyeLight.Brightness = 0
		leftEyeLight.Color = redEyeColor
		leftEyeLight.Range = 6
		leftEyeLight.Parent = leftEye

		local rightEyeLight = Instance.new("PointLight")
		rightEyeLight.Brightness = 0
		rightEyeLight.Color = redEyeColor
		rightEyeLight.Range = 6
		rightEyeLight.Parent = rightEye

		table.insert(eyeParts, leftEye)
		table.insert(eyeParts, rightEye)
		table.insert(eyeLights, leftEyeLight)
		table.insert(eyeLights, rightEyeLight)

		-- SKULL MOUTH - 3 vertical rectangles (same size, closer to eyes)
		local mouthY = eyeY - 0.4  -- M�s arriba (antes era -0.9)
		local toothWidth = 0.12
		local toothHeight = 0.4
		local toothGap = 0.1
		local numTeeth = 3
		local totalWidth = numTeeth * toothWidth + (numTeeth - 1) * toothGap
		local startX = doorX - totalWidth / 2 + toothWidth / 2

		for i = 1, numTeeth do
			local toothX = startX + (i - 1) * (toothWidth + toothGap)

			local tooth = MakePart("Tooth" ..i, Vector3.new(toothWidth, toothHeight, 0.06),
				Vector3.new(toothX, mouthY, eyeZ),
				skullMouthColor, Enum.Material.Neon, doorFolder, false, false, 1)

			local toothLight = Instance.new("PointLight")
			toothLight.Brightness = 0
			toothLight.Color = skullMouthColor
			toothLight.Range = 4
			toothLight.Parent = tooth

			table.insert(eyeParts, tooth)
			table.insert(eyeLights, toothLight)
		end
	end

	-- ---------------------------------------------------------------------------
	-- EYE ANIMATION FUNCTIONS (SYNCHRONIZED TIMING)
	-- ---------------------------------------------------------------------------

	local function FadeInEyes()
		for _, eyePart in ipairs(eyeParts) do
			TweenService:Create(eyePart, TweenInfo.new(ANIMATION_TIMING.EYES_FADE_IN), {Transparency = 0}):Play()
		end
		for _, light in ipairs(eyeLights) do
			TweenService:Create(light, TweenInfo.new(ANIMATION_TIMING.EYES_FADE_IN), {Brightness = 4}):Play()
		end
		task.wait(ANIMATION_TIMING.EYES_FADE_IN)
	end

	local function FadeOutEyes()
		for _, eyePart in ipairs(eyeParts) do
			TweenService:Create(eyePart, TweenInfo.new(ANIMATION_TIMING.EYES_FADE_OUT), {Transparency = 1}):Play()
		end
		for _, light in ipairs(eyeLights) do
			TweenService:Create(light, TweenInfo.new(ANIMATION_TIMING.EYES_FADE_OUT), {Brightness = 0}):Play()
		end
		task.wait(ANIMATION_TIMING.EYES_FADE_OUT)
	end

	local function BlinkEyes()
		for _ = 1, ANIMATION_TIMING.BLINK_COUNT do
			-- Eyes off
			for _, eyePart in ipairs(eyeParts) do
				eyePart.Transparency = 1
			end
			for _, light in ipairs(eyeLights) do
				light.Brightness = 0
			end
			task.wait(ANIMATION_TIMING.BLINK_OFF_TIME)

			-- Eyes on
			for _, eyePart in ipairs(eyeParts) do
				eyePart.Transparency = 0
			end
			for _, light in ipairs(eyeLights) do
				light.Brightness = 4
			end
			task.wait(ANIMATION_TIMING.BLINK_ON_TIME)
		end
		task.wait(ANIMATION_TIMING.BLINK_PAUSE)
	end

	local function SetAngle(deg)
		local rad = math.rad(deg)
		local pivot = Vector3.new(hingeX, doorCenterY, doorZ)
		local offset = Vector3.new(CONFIG.DOOR_WIDTH/2, 0, 0)
		local cf = CFrame.new(pivot) * CFrame.Angles(0, rad, 0) * CFrame.new(offset)
		door.CFrame = cf
		for _, p in ipairs(panels) do
			p.part.CFrame = cf * CFrame.new(p.offset)
		end
		handle.CFrame = cf * CFrame.new(handleOffset)
	end

	local function OnInteract(player)
		local id = tostring(door: GetFullName())
		if doorsBeingUsed[id] then return end
		doorsBeingUsed[id] = true

		local char = player.Character
		if not char then doorsBeingUsed[id] = nil return end

		local hum = char:FindFirstChild("Humanoid")
		if not hum then doorsBeingUsed[id] = nil return end

		local origSpeed = hum.WalkSpeed
		local origJump = hum.JumpPower
		hum.WalkSpeed = 0
		hum.JumpPower = 0

		-- ALWAYS reward 5 when door opens
		if outcome == "npc" and npcData then
			DoorOpenedEvent:FireClient(player, 5)
			if _G.CurrencySystem and _G.CurrencySystem.OnDoorOpened then
				_G.CurrencySystem.OnDoorOpened(player, 5)
			end
		end

		-- PHASE 1: KNOCK
		local knockSound = CreateDoorSound(DOOR_SOUNDS.KNOCK, door)
		knockSound: Play()
		PlayKnockVibration(door, zDir)
		task.wait(DOOR_SOUNDS.KNOCK.duration + 0.2)
		knockSound: Destroy()

		-- PHASE 2-5: DOOR SEQUENCE (only if NPC spawns)
		if outcome == "npc" and npcData then
			local openSound = CreateDoorSound(DOOR_SOUNDS.OPEN, door)
			openSound:Play()

			local openAng = zDir * -80
			local openDuration = DOOR_SOUNDS.OPEN.duration
			local steps = 45
			local stepTime = openDuration / steps

			for i = 1, steps do
				local progress = i / steps
				local easedProgress = 1 - math.pow(1 - progress, 3)
				local currentAngle = openAng * easedProgress
				SetAngle(currentAngle)
				task.wait(stepTime)
			end
			SetAngle(openAng)
			task.wait(0.3)

			-- NPC Sound
			local npcSoundConfig = NPC_SOUNDS[npcType] or NPC_SOUNDS.SHADOW
			local npcSound = CreateNPCSound(npcSoundConfig, door)
			npcSound:Play()

			-- Eyes animation (synchronized for all NPC types)
			FadeInEyes()
			task.wait(ANIMATION_TIMING.EYES_VISIBLE_DURATION)
			BlinkEyes()
			FadeOutEyes()

			-- SPAWN NPC
			local spawnPos = Vector3.new(doorX, 0, faceZ - zDir * 1.2)
			local doorFrameInfo = {
				faceZ = faceZ,
				holeWidth = holeW,
				holeHeight = holeH
			}

			local survivalKey = player.UserId .."_" ..tick()
			playerDoorSurvival[survivalKey] = {
				player = player,
				startTime = tick(),
				reward = npcData.REWARD_SURVIVAL,
				npcType = npcType,
				survivalTime = npcData.SURVIVAL_TIME
			}

			coroutine.wrap(function()
				task.wait(npcData.SURVIVAL_TIME)
				local data = playerDoorSurvival[survivalKey]
				if data and data.player and data.player.Parent then
					local pChar = data.player.Character
					if pChar then
						local pHum = pChar:FindFirstChild("Humanoid")
						if pHum and pHum.Health > 0 then
							SurvivedDoorEvent:FireClient(data.player, data.reward, data.npcType)
							if _G.CurrencySystem and _G.CurrencySystem.OnSurvived then
								_G.CurrencySystem.OnSurvived(data.player, data.reward, data.npcType)
							end
						end
					end
				end
				playerDoorSurvival[survivalKey] = nil
			end)()

			if npcData.SPAWN_EVENT then
				npcData.SPAWN_EVENT:Fire(spawnPos, player, side, zDir, doorFrameInfo)
			end

			task.wait(0.5)

			-- Close door
			local closeDuration = 0.4
			local closeSteps = 20
			local closeStepTime = closeDuration / closeSteps

			for i = 1, closeSteps do
				local progress = i / closeSteps
				local easedProgress = progress * progress
				local currentAngle = openAng * (1 - easedProgress)
				SetAngle(currentAngle)
				task.wait(closeStepTime)
			end
			SetAngle(0)

			local closeSound = CreateDoorSound(DOOR_SOUNDS.CLOSE, door)
			closeSound:Play()

			Debris:AddItem(openSound, 3)
			Debris:AddItem(closeSound, 2)
			Debris:AddItem(npcSound, 5)
		else
			-- DOOR STAYS LOCKED - Send suspenseful message
			task.wait(1)
			DoorLockedEvent: FireClient(player, "The door remains closed...")

			local amb = Instance.new("Sound")
			amb.SoundId = "rbxassetid://9114221580"
			amb.Volume = 0.1 * DOOR_MASTER_VOLUME
			amb.Parent = door
			amb: Play()
			Debris:AddItem(amb, 3)
		end

		hum.WalkSpeed = origSpeed
		hum.JumpPower = origJump
		task.wait(4)
		doorsBeingUsed[id] = nil
	end

	click.MouseClick:Connect(OnInteract)
	prompt.Triggered:Connect(OnInteract)

	return holeW, holeH
end

-- -------------------------------------------------------------------------------
-- BUILDING
-- -------------------------------------------------------------------------------

local function CreateBuilding(buildingIndex, xCenter, faceZ, backZ, zDir, width, side, parent)
	local folder = Instance.new("Folder")
	folder.Name = "Building_" ..buildingIndex
	folder.Parent = parent

	local heightSeed = xCenter * 100 + (side == "left" and 1 or 2)
	local height = SeededRandom(heightSeed, CONFIG.BUILDING_MIN_HEIGHT, CONFIG.BUILDING_MAX_HEIGHT)

	local colorIndex = SeededRandom(xCenter * 50, 1, #buildingColors)
	local color = buildingColors[colorIndex]
	color = LerpColor(color, Color3.new(1, 1, 1), SeededRandomFloat(xCenter * 33) * 0.08)

	local depth = math.abs(backZ - faceZ)
	local zCenter = (faceZ + backZ) / 2
	local floorY = 0.5

	local doorX = nil
	local holeW, holeH

	local isInLobby = xCenter >= CONFIG.LOBBY_START_X and xCenter <= CONFIG.LOBBY_END_X

	local hasDoor = not isInLobby and TrueRandomFloat() < CONFIG.DOOR_CHANCE

	if hasDoor then
		doorX = xCenter
		holeW = CONFIG.HOLE_WIDTH_NORMAL
		holeH = CONFIG.HOLE_HEIGHT_NORMAL

		local leftW = (width - holeW) / 2
		if leftW > 0.5 then
			MakePart("Left", Vector3.new(leftW, height, depth),
				Vector3.new(xCenter - holeW/2 - leftW/2, height/2, zCenter),
				color, Enum.Material.Concrete, folder)
		end

		local rightW = (width - holeW) / 2
		if rightW > 0.5 then
			MakePart("Right", Vector3.new(rightW, height, depth),
				Vector3.new(xCenter + holeW/2 + rightW/2, height/2, zCenter),
				color, Enum.Material.Concrete, folder)
		end

		local topH = height - holeH - floorY + 0.5
		if topH > 0.5 then
			MakePart("Top", Vector3.new(holeW, topH, depth),
				Vector3.new(xCenter, floorY + holeH + topH/2 - 0.5, zCenter),
				color, Enum.Material.Concrete, folder)
		end

		CreateDoorWithVoid(xCenter, faceZ, backZ, zDir, side, folder, color)
	else
		holeW = CONFIG.HOLE_WIDTH_NORMAL
		holeH = CONFIG.HOLE_HEIGHT_NORMAL

		MakePart("Body", Vector3.new(width, height, depth),
			Vector3.new(xCenter, height/2, zCenter),
			color, Enum.Material.Concrete, folder)
	end

	MakePart("Cornice", Vector3.new(width + 0.4, 1, depth + 0.2),
		Vector3.new(xCenter, height + 0.5, zCenter),
		LerpColor(color, CONFIG.COLORS.BUILDING_TRIM, 0.25),
		Enum.Material.Concrete, folder)

	MakePart("Base", Vector3.new(width + 0.15, 1.2, depth + 0.15),
		Vector3.new(xCenter, 0.6, zCenter),
		LerpColor(color, Color3.new(0, 0, 0), 0.1),
		Enum.Material.Slate, folder)

	CreateWindows(xCenter, height/2, faceZ, width, height, zDir, folder, doorX, holeW)

	if SeededRandomFloat(xCenter * 77) > 0.55 then
		local rh = SeededRandom(xCenter * 88, 2, 4)
		MakePart("Roof", Vector3.new(width * 0.35, rh, depth * 0.35),
			Vector3.new(xCenter, height + 1 + rh/2, zCenter),
			CONFIG.COLORS.BUILDING_TRIM, Enum.Material.Concrete, folder)
	end
end

-- -------------------------------------------------------------------------------
-- LAMP POSTS
-- -----------------------??-------------------------------------------------------

local function CreateLamp(x, side, parent)
	local folder = Instance.new("Folder")
	folder.Name = "Lamp"
	folder.Parent = parent

	local zOff = side == "left" and -(CONFIG.STREET_WIDTH/2 + 1.5) or (CONFIG.STREET_WIDTH/2 + 1.5)
	local zDir = side == "left" and 1 or -1

	MakePart("Post", Vector3.new(0.4, CONFIG.LAMP_HEIGHT, 0.4),
		Vector3.new(x, CONFIG.LAMP_HEIGHT/2, zOff),
		CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, folder)

	MakePart("Base", Vector3.new(1.2, 0.6, 1.2),
		Vector3.new(x, 0.3, zOff),
		CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, folder)

	local armL = 4
	MakePart("Arm", Vector3.new(0.3, 0.3, armL),
		Vector3.new(x, CONFIG.LAMP_HEIGHT - 0.4, zOff + zDir * armL/2),
		CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, folder)

	local bulb = MakePart("Bulb", Vector3.new(1.8, 2.2, 1.8),
		Vector3.new(x, CONFIG.LAMP_HEIGHT - 1.5, zOff + zDir * armL),
		CONFIG.COLORS.LAMP_LIGHT, Enum.Material.Neon, folder, false, false, 0.1)

	local light = Instance.new("PointLight")
	light.Brightness = 1.8
	light.Color = CONFIG.COLORS.LAMP_LIGHT
	light.Range = 45
	light.Shadows = true
	light.Parent = bulb

	MakePart("Top", Vector3.new(2.2, 0.35, 2.2),
		bulb.Position + Vector3.new(0, 1.3, 0),
		CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, folder)
end

-- -------------------------------------------------------------------------------
-- LOBBY / SAFE ZONE (COMPLETE)
-- -------------------------------------------------------------------------------

local function CreateLobby()
	local shopFolder = Instance.new("Folder")
	shopFolder.Name = "ShopArea"
	shopFolder.Parent = lobbyFolder

	local totalWidth = CONFIG.STREET_WIDTH + CONFIG.SIDEWALK_WIDTH * 2 + CONFIG.BUILDING_DEPTH * 2 + 10
	local lobbyFloorY = 0.02
	local streetEdge = CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH

	local lobbyFloor = MakePart("LobbyFloor", 
		Vector3.new(CONFIG.LOBBY_LENGTH, 1, totalWidth),
		Vector3.new(0, lobbyFloorY, 0),
		CONFIG.COLORS.LOBBY_FLOOR, Enum.Material.Concrete, lobbyFolder)

	MakePart("LeftCover",
		Vector3.new(CONFIG.LOBBY_LENGTH, 1, CONFIG.BUILDING_DEPTH + 5),
		Vector3.new(0, lobbyFloorY, -(streetEdge + CONFIG.BUILDING_DEPTH/2)),
		CONFIG.COLORS.LOBBY_FLOOR, Enum.Material.Concrete, lobbyFolder)

	MakePart("RightCover",
		Vector3.new(CONFIG.LOBBY_LENGTH, 1, CONFIG.BUILDING_DEPTH + 5),
		Vector3.new(0, lobbyFloorY, streetEdge + CONFIG.BUILDING_DEPTH/2),
		CONFIG.COLORS.LOBBY_FLOOR, Enum.Material.Concrete, lobbyFolder)

	MakePart("LobbyEdgeTrimLeft",
		Vector3.new(0.5, 0.2, totalWidth + 20),
		Vector3.new(CONFIG.LOBBY_START_X, 0.6, 0),
		Color3.fromRGB(50, 55, 60), Enum.Material.Metal, lobbyFolder)

	MakePart("LobbyEdgeTrimRight",
		Vector3.new(0.5, 0.2, totalWidth + 20),
		Vector3.new(CONFIG.LOBBY_END_X, 0.6, 0),
		Color3.fromRGB(50, 55, 60), Enum.Material.Metal, lobbyFolder)

	-- TRANSITIONS LEFT
	local transitionLength = 30
	local transitionY = -0.02
	local transitionGap = 0.5
	local leftTransitionX = CONFIG.LOBBY_START_X - transitionLength/2 - transitionGap

	MakePart("TransitionStreetLeft",
		Vector3.new(transitionLength, 1, CONFIG.STREET_WIDTH),
		Vector3.new(leftTransitionX, transitionY, 0),
		CONFIG.COLORS.STREET, Enum.Material.Asphalt, lobbyFolder)

	MakePart("TransitionSidewalkLeftL",
		Vector3.new(transitionLength, 1, CONFIG.SIDEWALK_WIDTH),
		Vector3.new(leftTransitionX, 0.23, -(CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH/2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionSidewalkLeftR",
		Vector3.new(transitionLength, 1, CONFIG.SIDEWALK_WIDTH),
		Vector3.new(leftTransitionX, 0.23, (CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH/2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionCurbLeftL",
		Vector3.new(transitionLength, 0.5, 0.4),
		Vector3.new(leftTransitionX, 0.73, -(CONFIG.STREET_WIDTH/2 + 0.2)),
		LerpColor(CONFIG.COLORS.SIDEWALK, Color3.new(0.15, 0.15, 0.15), 0.2),
		Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionCurbLeftR",
		Vector3.new(transitionLength, 0.5, 0.4),
		Vector3.new(leftTransitionX, 0.73, (CONFIG.STREET_WIDTH/2 + 0.2)),
		LerpColor(CONFIG.COLORS.SIDEWALK, Color3.new(0.15, 0.15, 0.15), 0.2),
		Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionBuildingFloorLeftL",
		Vector3.new(transitionLength, 1, CONFIG.BUILDING_DEPTH + 10),
		Vector3.new(leftTransitionX, transitionY, -(streetEdge + CONFIG.BUILDING_DEPTH/2 + 2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionBuildingFloorLeftR",
		Vector3.new(transitionLength, 1, CONFIG.BUILDING_DEPTH + 10),
		Vector3.new(leftTransitionX, transitionY, (streetEdge + CONFIG.BUILDING_DEPTH/2 + 2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("CornerFillLeftFront",
		Vector3.new(10, 1, CONFIG.STREET_WIDTH + CONFIG.SIDEWALK_WIDTH * 2 + 20),
		Vector3.new(CONFIG.LOBBY_START_X - transitionLength - 5 - transitionGap, transitionY, 0),
		CONFIG.COLORS.STREET, Enum.Material.Asphalt, lobbyFolder)

	-- TRANSITIONS RIGHT
	local rightTransitionX = CONFIG.LOBBY_END_X + transitionLength/2 + transitionGap

	MakePart("TransitionStreetRight",
		Vector3.new(transitionLength, 1, CONFIG.STREET_WIDTH),
		Vector3.new(rightTransitionX, transitionY, 0),
		CONFIG.COLORS.STREET, Enum.Material.Asphalt, lobbyFolder)

	MakePart("TransitionSidewalkRightL",
		Vector3.new(transitionLength, 1, CONFIG.SIDEWALK_WIDTH),
		Vector3.new(rightTransitionX, 0.23, -(CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH/2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionSidewalkRightR",
		Vector3.new(transitionLength, 1, CONFIG.SIDEWALK_WIDTH),
		Vector3.new(rightTransitionX, 0.23, (CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH/2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionCurbRightL",
		Vector3.new(transitionLength, 0.5, 0.4),
		Vector3.new(rightTransitionX, 0.73, -(CONFIG.STREET_WIDTH/2 + 0.2)),
		LerpColor(CONFIG.COLORS.SIDEWALK, Color3.new(0.15, 0.15, 0.15), 0.2),
		Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionCurbRightR",
		Vector3.new(transitionLength, 0.5, 0.4),
		Vector3.new(rightTransitionX, 0.73, (CONFIG.STREET_WIDTH/2 + 0.2)),
		LerpColor(CONFIG.COLORS.SIDEWALK, Color3.new(0.15, 0.15, 0.15), 0.2),
		Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionBuildingFloorRightL",
		Vector3.new(transitionLength, 1, CONFIG.BUILDING_DEPTH + 10),
		Vector3.new(rightTransitionX, transitionY, -(streetEdge + CONFIG.BUILDING_DEPTH/2 + 2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("TransitionBuildingFloorRightR",
		Vector3.new(transitionLength, 1, CONFIG.BUILDING_DEPTH + 10),
		Vector3.new(rightTransitionX, transitionY, (streetEdge + CONFIG.BUILDING_DEPTH/2 + 2)),
		CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, lobbyFolder)

	MakePart("CornerFillRightFront",
		Vector3.new(10, 1, CONFIG.STREET_WIDTH + CONFIG.SIDEWALK_WIDTH * 2 + 20),
		Vector3.new(CONFIG.LOBBY_END_X + transitionLength + 5 + transitionGap, transitionY, 0),
		CONFIG.COLORS.STREET, Enum.Material.Asphalt, lobbyFolder)

	-- CEILING
	local ceilingHeight = 20

	local lobbyCeiling = MakePart("LobbyCeiling",
		Vector3.new(CONFIG.LOBBY_LENGTH + 10, 1, totalWidth),
		Vector3.new(0, ceilingHeight, 0),
		Color3.fromRGB(35, 35, 45), Enum.Material.Concrete, lobbyFolder)

	-- CEILING BEAMS - Solo en los bordes
	for x = -60, 60, 30 do
		if x == -60 or x == 60 then
			MakePart("CeilingBeamX" ..x, Vector3.new(2, 1.5, totalWidth),
				Vector3.new(x, ceilingHeight - 0.75, 0),
				Color3.fromRGB(45, 45, 55), Enum.Material.Concrete, lobbyFolder)
		end
	end

	for z = -30, 30, 30 do
		if z ~= 0 then
			MakePart("CeilingBeamZ" ..z, Vector3.new(CONFIG.LOBBY_LENGTH + 10, 1.5, 2),
				Vector3.new(0, ceilingHeight - 0.75, z),
				Color3.fromRGB(45, 45, 55), Enum.Material.Concrete, lobbyFolder)
		end
	end

	-- FLOOR LINES
	for i = -2, 2 do
		MakePart("LobbyLine" ..i, Vector3.new(CONFIG.LOBBY_LENGTH - 20, 0.05, 0.4),
			Vector3.new(0, 0.55, i * 10),
			CONFIG.COLORS.LOBBY_ACCENT, Enum.Material.Neon, lobbyFolder, false, false, 0.6)
	end

	-- SAFE ZONE INDICATORS
	MakePart("SafeIndicatorL",
		Vector3.new(1, 0.15, totalWidth),
		Vector3.new(CONFIG.LOBBY_START_X, 0.6, 0),
		CONFIG.COLORS.SAFE_ZONE, Enum.Material.Neon, lobbyFolder, false, false, 0.4)

	MakePart("SafeIndicatorR",
		Vector3.new(1, 0.15, totalWidth),
		Vector3.new(CONFIG.LOBBY_END_X, 0.6, 0),
		CONFIG.COLORS.SAFE_ZONE, Enum.Material.Neon, lobbyFolder, false, false, 0.4)

	-- CEILING LIGHTS
	for x = -45, 45, 30 do
		for z = -20, 20, 20 do
			local lightFixture = MakePart("LightFixture", Vector3.new(4, 0.5, 4),
				Vector3.new(x, ceilingHeight - 0.75, z),
				Color3.fromRGB(60, 60, 70), Enum.Material.Metal, lobbyFolder)

			local lightPanel = MakePart("LightPanel", Vector3.new(3, 0.1, 3),
				Vector3.new(x, ceilingHeight - 1, z),
				Color3.fromRGB(255, 245, 220), Enum.Material.Neon, lobbyFolder, false, false, 0.4)

			local light = Instance.new("PointLight")
			light.Brightness = 1.2
			light.Color = Color3.fromRGB(255, 245, 220)
			light.Range = 35
			light.Shadows = false
			light.Parent = lightPanel
		end
	end

	-- LOBBY LAMPS
	for i = -2, 2 do
		if i ~= 0 then
			local lobbyLamp = MakePart("LobbyLamp" ..i, Vector3.new(0.4, 10, 0.4),
				Vector3.new(i * 30, 5, 0),
				CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, lobbyFolder)

			MakePart("LampBase" ..i, Vector3.new(1.2, 0.4, 1.2),
				Vector3.new(i * 30, 0.7, 0),
				CONFIG.COLORS.LAMP_POST, Enum.Material.Metal, lobbyFolder)

			local lampBulb = MakePart("LampBulb" ..i, Vector3.new(1.8, 1.5, 1.8),
				Vector3.new(i * 30, 10.5, 0),
				Color3.fromRGB(255, 240, 200), Enum.Material.Neon, lobbyFolder, false, false, 0.3)

			local light = Instance.new("PointLight")
			light.Brightness = 1.5
			light.Color = Color3.fromRGB(255, 240, 200)
			light.Range = 30
			light.Shadows = false
			light.Parent = lampBulb
		end
	end

	-- ---------------------------------------------------------------------------
	-- STREET ENTRANCE SIGNS - "THE STREET" EN CADA ORILLA
	-- ---------------------------------------------------------------------------

	local function CreateStreetSign(xPosition, arrowDir)
		local signFolder = Instance.new("Folder")
		signFolder.Name = "StreetSign_" ..(xPosition < 0 and "Left" or "Right")
		signFolder.Parent = lobbyFolder

		MakePart("SignChainL", Vector3.new(0.1, 3, 0.1),
			Vector3.new(xPosition - 5, ceilingHeight - 2.5, 0),
			Color3.fromRGB(60, 55, 50), Enum.Material.Metal, signFolder)

		MakePart("SignChainR", Vector3.new(0.1, 3, 0.1),
			Vector3.new(xPosition + 5, ceilingHeight - 2.5, 0),
			Color3.fromRGB(60, 55, 50), Enum.Material.Metal, signFolder)

		local streetSign = MakePart("StreetSign", Vector3.new(14, 2.5, 0.4),
			Vector3.new(xPosition, ceilingHeight - 5, 0),
			Color3.fromRGB(25, 25, 35), Enum.Material.SmoothPlastic, signFolder)

		MakePart("SignFrameTop", Vector3.new(14.5, 0.2, 0.5),
			Vector3.new(xPosition, ceilingHeight - 3.65, 0),
			Color3.fromRGB(180, 150, 50), Enum.Material.Metal, signFolder)

		MakePart("SignFrameBottom", Vector3.new(14.5, 0.2, 0.5),
			Vector3.new(xPosition, ceilingHeight - 6.35, 0),
			Color3.fromRGB(180, 150, 50), Enum.Material.Metal, signFolder)

		MakePart("SignFrameLeft", Vector3.new(0.2, 2.9, 0.5),
			Vector3.new(xPosition - 7.15, ceilingHeight - 5, 0),
			Color3.fromRGB(180, 150, 50), Enum.Material.Metal, signFolder)

		MakePart("SignFrameRight", Vector3.new(0.2, 2.9, 0.5),
			Vector3.new(xPosition + 7.15, ceilingHeight - 5, 0),
			Color3.fromRGB(180, 150, 50), Enum.Material.Metal, signFolder)

		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local signGui = Instance.new("SurfaceGui")
			signGui.Face = face
			signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			signGui.PixelsPerStud = 40
			signGui.Parent = streetSign

			local signText = Instance.new("TextLabel")
			signText.Size = UDim2.new(1, 0, 1, 0)
			signText.BackgroundTransparency = 1
			signText.Text = "THE STREET"
			signText.TextColor3 = Color3.fromRGB(255, 200, 100)
			signText.TextScaled = true
			signText.Font = Enum.Font.GothamBlack
			signText.Parent = signGui
		end

		local signLight = MakePart("SignLight", Vector3.new(12, 0.15, 0.15),
			Vector3.new(xPosition, ceilingHeight - 3.8, 0.25),
			Color3.fromRGB(255, 220, 150), Enum.Material.Neon, signFolder, false, false, 0.5)

		local sLight = Instance.new("PointLight")
		sLight.Brightness = 0.8
		sLight.Color = Color3.fromRGB(255, 220, 150)
		sLight.Range = 12
		sLight.Shadows = false
		sLight.Parent = signLight

		local arrowSign = MakePart("ArrowSign", Vector3.new(2.5, 1.8, 0.3),
			Vector3.new(xPosition, ceilingHeight - 8.5, 0),
			Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, signFolder)

		MakePart("ArrowFrame", Vector3.new(2.7, 2, 0.25),
			Vector3.new(xPosition, ceilingHeight - 8.5, -0.05),
			Color3.fromRGB(100, 40, 40), Enum.Material.Metal, signFolder)

		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local arrowGui = Instance.new("SurfaceGui")
			arrowGui.Face = face
			arrowGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			arrowGui.PixelsPerStud = 50
			arrowGui.Parent = arrowSign

			local arrowText = Instance.new("TextLabel")
			arrowText.Size = UDim2.new(1, 0, 1, 0)
			arrowText.BackgroundTransparency = 1
			arrowText.Text = arrowDir
			arrowText.TextColor3 = Color3.fromRGB(255, 80, 80)
			arrowText.TextScaled = true
			arrowText.Font = Enum.Font.GothamBlack
			arrowText.Parent = arrowGui
		end

		local arrowGlow = MakePart("ArrowGlow", Vector3.new(2, 0.1, 0.1),
			Vector3.new(xPosition, ceilingHeight - 9.5, 0.2),
			Color3.fromRGB(255, 80, 80), Enum.Material.Neon, signFolder, false, false, 0.3)

		local arrowLight = Instance.new("PointLight")
		arrowLight.Brightness = 0.6
		arrowLight.Color = Color3.fromRGB(255, 80, 80)
		arrowLight.Range = 10
		arrowLight.Parent = arrowGlow

		return signFolder
	end

	CreateStreetSign(CONFIG.LOBBY_START_X + 8, "?")
	CreateStreetSign(CONFIG.LOBBY_END_X - 8, "?")

	-- ---------------------------------------------------------------------------
	-- SHOP (COMPLETE)
	-- ---------------------------------------------------------------------------

	local wallZ = -(CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH - 2)
	local shopX = 0

	local shopBackWall = MakePart("ShopBackWall", Vector3.new(16, 12, 0.5),
		Vector3.new(shopX, 6, wallZ),
		Color3.fromRGB(35, 30, 40), Enum.Material.Brick, shopFolder)

	local shopLeftWall = MakePart("ShopLeftWall", Vector3.new(0.5, 12, 10),
		Vector3.new(shopX - 8, 6, wallZ + 5),
		Color3.fromRGB(40, 35, 45), Enum.Material.Brick, shopFolder)

	local shopRightWall = MakePart("ShopRightWall", Vector3.new(0.5, 12, 10),
		Vector3.new(shopX + 8, 6, wallZ + 5),
		Color3.fromRGB(40, 35, 45), Enum.Material.Brick, shopFolder)

	local shopFloor = MakePart("ShopFloor", Vector3.new(16, 0.3, 10),
		Vector3.new(shopX, 0.65, wallZ + 5),
		Color3.fromRGB(45, 40, 50), Enum.Material.Marble, shopFolder)

	local floorBorderFront = MakePart("FloorBorderFront", Vector3.new(16, 0.1, 0.3),
		Vector3.new(shopX, 0.85, wallZ + 10),
		Color3.fromRGB(120, 100, 70), Enum.Material.Metal, shopFolder)

	local floorBorderLeft = MakePart("FloorBorderLeft", Vector3.new(0.3, 0.1, 10),
		Vector3.new(shopX - 7.85, 0.85, wallZ + 5),
		Color3.fromRGB(120, 100, 70), Enum.Material.Metal, shopFolder)

	local floorBorderRight = MakePart("FloorBorderRight", Vector3.new(0.3, 0.1, 10),
		Vector3.new(shopX + 7.85, 0.85, wallZ + 5),
		Color3.fromRGB(120, 100, 70), Enum.Material.Metal, shopFolder)

	local shopCounterBase = MakePart("ShopCounterBase", Vector3.new(12, 3.2, 2),
		Vector3.new(shopX, 2.1, wallZ + 7),
		Color3.fromRGB(70, 50, 35), Enum.Material.Wood, shopFolder)

	local shopCounterTop = MakePart("CounterTop", Vector3.new(12.5, 0.25, 2.5),
		Vector3.new(shopX, 3.85, wallZ + 7),
		Color3.fromRGB(50, 35, 25), Enum.Material.Wood, shopFolder)

	local counterFrontPanel = MakePart("CounterFrontPanel", Vector3.new(11, 2.5, 0.1),
		Vector3.new(shopX, 1.75, wallZ + 8.05),
		Color3.fromRGB(55, 40, 30), Enum.Material.Wood, shopFolder)

	local counterTrimTop = MakePart("CounterTrimTop", Vector3.new(12.5, 0.15, 0.2),
		Vector3.new(shopX, 3.1, wallZ + 8),
		Color3.fromRGB(100, 80, 50), Enum.Material.Metal, shopFolder)

	local counterTrimBottom = MakePart("CounterTrimBottom", Vector3.new(12.5, 0.1, 0.15),
		Vector3.new(shopX, 0.55, wallZ + 8),
		Color3.fromRGB(100, 80, 50), Enum.Material.Metal, shopFolder)

	local shopRoof = MakePart("ShopRoof", Vector3.new(18, 0.6, 12),
		Vector3.new(shopX, 12, wallZ + 5),
		Color3.fromRGB(30, 25, 35), Enum.Material.Slate, shopFolder)

	for beamX = -6, 6, 6 do
		local roofBeam = MakePart("RoofBeam", Vector3.new(0.4, 0.8, 12),
			Vector3.new(shopX + beamX, 11.5, wallZ + 5),
			Color3.fromRGB(50, 35, 25), Enum.Material.Wood, shopFolder)
	end

	for _, xOff in pairs({-8, 8}) do
		local pillar = MakePart("Pillar", Vector3.new(0.8, 12, 0.8),
			Vector3.new(shopX + xOff, 6, wallZ + 10),
			Color3.fromRGB(45, 40, 50), Enum.Material.Concrete, shopFolder)

		local pillarBase = MakePart("PillarBase", Vector3.new(1.2, 0.5, 1.2),
			Vector3.new(shopX + xOff, 0.75, wallZ + 10),
			Color3.fromRGB(60, 50, 55), Enum.Material.Concrete, shopFolder)

		local pillarCapital = MakePart("PillarCapital", Vector3.new(1.1, 0.4, 1.1),
			Vector3.new(shopX + xOff, 11.7, wallZ + 10),
			Color3.fromRGB(60, 50, 55), Enum.Material.Concrete, shopFolder)
	end

	local shopSignBack = MakePart("ShopSignBack", Vector3.new(11, 3, 0.4),
		Vector3.new(shopX, 9.5, wallZ + 10.5),
		Color3.fromRGB(20, 15, 25), Enum.Material.SmoothPlastic, shopFolder)

	local shopSignFrame = MakePart("ShopSignFrame", Vector3.new(11.4, 3.4, 0.3),
		Vector3.new(shopX, 9.5, wallZ + 10.3),
		Color3.fromRGB(100, 80, 50), Enum.Material.Metal, shopFolder)

	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = face
		signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		signGui.PixelsPerStud = 50
		signGui.Parent = shopSignBack

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = "?? SHOP"
		signText.TextColor3 = Color3.fromRGB(255, 200, 100)
		signText.TextScaled = true
		signText.Font = Enum.Font.GothamBlack
		signText.Parent = signGui
	end

	local signLightLeft = MakePart("SignLightLeft", Vector3.new(0.3, 0.3, 0.3),
		Vector3.new(shopX - 5.3, 9.5, wallZ + 10.7),
		Color3.fromRGB(255, 220, 150), Enum.Material.Neon, shopFolder, false, false, 0.3)

	local sll = Instance.new("PointLight")
	sll.Brightness = 0.4
	sll.Color = Color3.fromRGB(255, 220, 150)
	sll.Range = 6
	sll.Shadows = false
	sll.Parent = signLightLeft

	local signLightRight = MakePart("SignLightRight", Vector3.new(0.3, 0.3, 0.3),
		Vector3.new(shopX + 5.3, 9.5, wallZ + 10.7),
		Color3.fromRGB(255, 220, 150), Enum.Material.Neon, shopFolder, false, false, 0.3)

	local slr = Instance.new("PointLight")
	slr.Brightness = 0.4
	slr.Color = Color3.fromRGB(255, 220, 150)
	slr.Range = 6
	slr.Shadows = false
	slr.Parent = signLightRight

	-- LANTERNS
	for lx = -4, 4, 4 do
		local lanternChain = MakePart("LanternChain", Vector3.new(0.05, 1.5, 0.05),
			Vector3.new(shopX + lx, 11, wallZ + 5),
			Color3.fromRGB(60, 50, 40), Enum.Material.Metal, shopFolder)

		local lanternFrame = MakePart("LanternFrame", Vector3.new(0.8, 1.2, 0.8),
			Vector3.new(shopX + lx, 10, wallZ + 5),
			Color3.fromRGB(50, 40, 35), Enum.Material.Metal, shopFolder)

		local lanternGlass = MakePart("LanternGlass", Vector3.new(0.5, 0.8, 0.5),
			Vector3.new(shopX + lx, 10, wallZ + 5),
			Color3.fromRGB(255, 200, 120), Enum.Material.Glass, shopFolder, false, false, 0.4)

		local lanternLight = Instance.new("PointLight")
		lanternLight.Brightness = 0.8
		lanternLight.Color = Color3.fromRGB(255, 200, 120)
		lanternLight.Range = 15
		lanternLight.Shadows = false
		lanternLight.Parent = lanternGlass
	end

	-- SHELVES WITH BOTTLES
	for shelfY = 4, 8, 2 do
		local shelf = MakePart("Shelf", Vector3.new(10, 0.2, 1),
			Vector3.new(shopX, shelfY, wallZ + 0.7),
			Color3.fromRGB(60, 45, 35), Enum.Material.Wood, shopFolder)

		for bx = -4, 4, 4 do
			local bracket = MakePart("ShelfBracket", Vector3.new(0.15, 0.5, 0.8),
				Vector3.new(shopX + bx, shelfY - 0.3, wallZ + 0.5),
				Color3.fromRGB(80, 65, 50), Enum.Material.Metal, shopFolder)
		end

		for itemX = -3, 3, 2 do
			local bottleHeight = 0.4 + math.random() * 0.4
			local bottleColor = Color3.fromRGB(
				math.random(40, 100),
				math.random(60, 120),
				math.random(80, 140)
			)
			local bottle = MakePart("Bottle", Vector3.new(0.3, bottleHeight, 0.3),
				Vector3.new(shopX + itemX + math.random() * 0.5, shelfY + bottleHeight/2 + 0.1, wallZ + 0.7),
				bottleColor, Enum.Material.Glass, shopFolder, false, false, 0.3)
		end
	end

	-- SHOP TRIGGER
	local shopTrigger = MakePart("ShopTrigger", Vector3.new(14, 5, 12),
		Vector3.new(shopX, 3, wallZ + 6),
		Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, shopFolder, false, false, 1)

	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.Name = "ShopPrompt"
	shopPrompt.ActionText = "Open Shop"
	shopPrompt.ObjectText = "Shop"
	shopPrompt.KeyboardKeyCode = Enum.KeyCode.E
	shopPrompt.HoldDuration = 0
	shopPrompt.MaxActivationDistance = 10
	shopPrompt.RequiresLineOfSight = false
	shopPrompt.Parent = shopTrigger

	shopPrompt.Triggered:Connect(function(player)
		OpenShopEvent:FireClient(player)
	end)

	-- ---------------------------------------------------------------------------
	-- WIZARD (COMPLETE)
	-- ---------------------------------------------------------------------------

	local wizardFolder = Instance.new("Folder")
	wizardFolder.Name = "Wizard"
	wizardFolder.Parent = shopFolder

	local wizardZ = wallZ + 4
	local wizardX = shopX
	local groundY = 0.8

	local robeMain = MakePart("RobeMain", Vector3.new(2.5, 5.5, 1.8),
		Vector3.new(wizardX, groundY + 2.75, wizardZ),
		Color3.fromRGB(50, 35, 80), Enum.Material.Fabric, wizardFolder)

	local robeShoulders = MakePart("RobeShoulders", Vector3.new(2.8, 1.0, 1.6),
		Vector3.new(wizardX, groundY + 5.8, wizardZ),
		Color3.fromRGB(55, 40, 85), Enum.Material.Fabric, wizardFolder)

	local belt = MakePart("Belt", Vector3.new(2.6, 0.35, 1.85),
		Vector3.new(wizardX, groundY + 3.0, wizardZ + 0.01),
		Color3.fromRGB(80, 55, 35), Enum.Material.Leather, wizardFolder)

	local beltBuckle = MakePart("BeltBuckle", Vector3.new(0.45, 0.4, 0.1),
		Vector3.new(wizardX, groundY + 3.0, wizardZ + 0.95),
		Color3.fromRGB(180, 150, 70), Enum.Material.Metal, wizardFolder)

	local robeTrim = MakePart("RobeTrim", Vector3.new(2.6, 0.2, 1.85),
		Vector3.new(wizardX, groundY + 0.1, wizardZ),
		Color3.fromRGB(160, 130, 70), Enum.Material.Fabric, wizardFolder)

	local headWiz = MakePart("Head", Vector3.new(1.4, 1.5, 1.4),
		Vector3.new(wizardX, groundY + 7.0, wizardZ),
		Color3.fromRGB(215, 180, 150), Enum.Material.SmoothPlastic, wizardFolder)

	local eyeLeftWiz = MakePart("EyeLeft", Vector3.new(0.18, 0.12, 0.05),
		Vector3.new(wizardX - 0.28, groundY + 7.1, wizardZ + 0.7),
		Color3.fromRGB(60, 90, 130), Enum.Material.SmoothPlastic, wizardFolder)

	local eyeRightWiz = MakePart("EyeRight", Vector3.new(0.18, 0.12, 0.05),
		Vector3.new(wizardX + 0.28, groundY + 7.1, wizardZ + 0.7),
		Color3.fromRGB(60, 90, 130), Enum.Material.SmoothPlastic, wizardFolder)

	local browLeft = MakePart("BrowLeft", Vector3.new(0.3, 0.1, 0.15),
		Vector3.new(wizardX - 0.28, groundY + 7.3, wizardZ + 0.65),
		Color3.fromRGB(190, 190, 185), Enum.Material.Fabric, wizardFolder)

	local browRight = MakePart("BrowRight", Vector3.new(0.3, 0.1, 0.15),
		Vector3.new(wizardX + 0.28, groundY + 7.3, wizardZ + 0.65),
		Color3.fromRGB(190, 190, 185), Enum.Material.Fabric, wizardFolder)

	local nose = MakePart("Nose", Vector3.new(0.2, 0.35, 0.25),
		Vector3.new(wizardX, groundY + 6.9, wizardZ + 0.75),
		Color3.fromRGB(205, 170, 145), Enum.Material.SmoothPlastic, wizardFolder)

	local earLeftWiz = MakePart("EarLeft", Vector3.new(0.12, 0.35, 0.25),
		Vector3.new(wizardX - 0.72, groundY + 7.0, wizardZ),
		Color3.fromRGB(205, 170, 145), Enum.Material.SmoothPlastic, wizardFolder)

	local earRightWiz = MakePart("EarRight", Vector3.new(0.12, 0.35, 0.25),
		Vector3.new(wizardX + 0.72, groundY + 7.0, wizardZ),
		Color3.fromRGB(205, 170, 145), Enum.Material.SmoothPlastic, wizardFolder)

	local mustache = MakePart("Mustache", Vector3.new(0.7, 0.2, 0.25),
		Vector3.new(wizardX, groundY + 6.55, wizardZ + 0.7),
		Color3.fromRGB(220, 220, 215), Enum.Material.Fabric, wizardFolder)

	local beardUpper = MakePart("BeardUpper", Vector3.new(0.85, 1.0, 0.6),
		Vector3.new(wizardX, groundY + 5.9, wizardZ + 0.7),
		Color3.fromRGB(225, 225, 220), Enum.Material.Fabric, wizardFolder)

	local beardMiddle = MakePart("BeardMiddle", Vector3.new(0.7, 1.3, 0.5),
		Vector3.new(wizardX, groundY + 4.7, wizardZ + 0.75),
		Color3.fromRGB(220, 220, 215), Enum.Material.Fabric, wizardFolder)

	local beardTip = MakePart("BeardTip", Vector3.new(0.4, 0.9, 0.35),
		Vector3.new(wizardX, groundY + 3.5, wizardZ + 0.8),
		Color3.fromRGB(215, 215, 210), Enum.Material.Fabric, wizardFolder)

	local hatBrim = MakePart("HatBrim", Vector3.new(2.0, 0.2, 2.0),
		Vector3.new(wizardX, groundY + 7.75, wizardZ),
		Color3.fromRGB(40, 28, 65), Enum.Material.Fabric, wizardFolder)

	local hatBase = MakePart("HatBase", Vector3.new(1.5, 1.6, 1.5),
		Vector3.new(wizardX, groundY + 8.7, wizardZ),
		Color3.fromRGB(45, 32, 72), Enum.Material.Fabric, wizardFolder)

	local hatMiddle = MakePart("HatMiddle", Vector3.new(1.1, 1.4, 1.1),
		Vector3.new(wizardX + 0.1, groundY + 10.0, wizardZ - 0.1),
		Color3.fromRGB(50, 36, 78), Enum.Material.Fabric, wizardFolder)

	local hatTop = MakePart("HatTop", Vector3.new(0.6, 1.1, 0.6),
		Vector3.new(wizardX + 0.25, groundY + 11.2, wizardZ - 0.15),
		Color3.fromRGB(55, 40, 85), Enum.Material.Fabric, wizardFolder)

	local hatTip = MakePart("HatTip", Vector3.new(0.3, 0.7, 0.3),
		Vector3.new(wizardX + 0.4, groundY + 12.0, wizardZ - 0.2),
		Color3.fromRGB(58, 42, 88), Enum.Material.Fabric, wizardFolder)

	local hatBand = MakePart("HatBand", Vector3.new(1.55, 0.3, 1.55),
		Vector3.new(wizardX, groundY + 8.0, wizardZ),
		Color3.fromRGB(130, 100, 55), Enum.Material.Fabric, wizardFolder)

	local hatStar = MakePart("HatStar", Vector3.new(0.35, 0.35, 0.08),
		Vector3.new(wizardX, groundY + 8.0, wizardZ + 0.8),
		Color3.fromRGB(200, 170, 80), Enum.Material.Metal, wizardFolder)

	local armLeftWiz = MakePart("ArmLeft", Vector3.new(0.55, 2.8, 0.55),
		Vector3.new(wizardX - 1.5, groundY + 4.0, wizardZ + 0.2),
		Color3.fromRGB(50, 35, 80), Enum.Material.Fabric, wizardFolder)

	local handLeftWiz = MakePart("HandLeft", Vector3.new(0.4, 0.45, 0.35),
		Vector3.new(wizardX - 1.5, groundY + 2.5, wizardZ + 0.4),
		Color3.fromRGB(205, 170, 145), Enum.Material.SmoothPlastic, wizardFolder)

	local armRightWiz = MakePart("ArmRight", Vector3.new(0.55, 3.2, 0.55),
		Vector3.new(wizardX + 1.5, groundY + 5.0, wizardZ + 0.1),
		Color3.fromRGB(50, 35, 80), Enum.Material.Fabric, wizardFolder)

	local handRightWiz = MakePart("HandRight", Vector3.new(0.4, 0.45, 0.35),
		Vector3.new(wizardX + 1.7, groundY + 6.8, wizardZ + 0.3),
		Color3.fromRGB(205, 170, 145), Enum.Material.SmoothPlastic, wizardFolder)

	local staffPole = MakePart("StaffPole", Vector3.new(0.25, 7.5, 0.25),
		Vector3.new(wizardX + 2.0, groundY + 3.75, wizardZ + 0.4),
		Color3.fromRGB(65, 45, 30), Enum.Material.Wood, wizardFolder)

	local staffGrip = MakePart("StaffGrip", Vector3.new(0.32, 1.2, 0.32),
		Vector3.new(wizardX + 2.0, groundY + 6.5, wizardZ + 0.4),
		Color3.fromRGB(85, 60, 40), Enum.Material.Leather, wizardFolder)

	local staffHolder = MakePart("StaffHolder", Vector3.new(0.45, 0.45, 0.45),
		Vector3.new(wizardX + 2.0, groundY + 7.7, wizardZ + 0.4),
		Color3.fromRGB(90, 70, 45), Enum.Material.Metal, wizardFolder)

	local staffOrb = MakePart("StaffOrb", Vector3.new(0.6, 0.6, 0.6),
		Vector3.new(wizardX + 2.0, groundY + 8.2, wizardZ + 0.4),
		Color3.fromRGB(80, 150, 200), Enum.Material.SmoothPlastic, wizardFolder)
	staffOrb.Shape = Enum.PartType.Ball

	local staffBottom = MakePart("StaffBottom", Vector3.new(0.32, 0.15, 0.32),
		Vector3.new(wizardX + 2.0, groundY + 0.08, wizardZ + 0.4),
		Color3.fromRGB(90, 70, 45), Enum.Material.Metal, wizardFolder)

	print("? Lobby created with THE STREET signs, Shop, and Wizard")
end

-- -------------------------------------------------------------------------------
-- STREET SEGMENT
-- -------------------------------------------------------------------------------

local function CreateSegment(startX)
	local key = tostring(math.floor(startX / CONFIG.STREET_SEGMENT_LENGTH))
	if generatedSegments[key] then return end
	generatedSegments[key] = true

	local folder = Instance.new("Folder")
	folder.Name = "Segment_" ..key
	folder.Parent = worldFolder

	streetSegments[key] = {folder = folder, startX = startX, endX = startX + CONFIG.STREET_SEGMENT_LENGTH}

	local centerX = startX + CONFIG.STREET_SEGMENT_LENGTH / 2
	local segLen = CONFIG.STREET_SEGMENT_LENGTH

	local segmentEnd = startX + segLen
	local overlapsLobby = not (segmentEnd < CONFIG.LOBBY_START_X or startX > CONFIG.LOBBY_END_X)

	if not overlapsLobby then
		MakePart("Street", Vector3.new(segLen + 0.5, 1, CONFIG.STREET_WIDTH),
			Vector3.new(centerX, 0, 0),
			CONFIG.COLORS.STREET, Enum.Material.Asphalt, folder)

		local lineGap = 10
		for i = 1, math.floor(segLen / lineGap) do
			if i % 2 == 0 then
				MakePart("Line", Vector3.new(5, 0.02, 0.35),
					Vector3.new(startX + (i - 0.5) * lineGap, 0.51, 0),
					CONFIG.COLORS.STREET_LINES, Enum.Material.Neon, folder, false, false, 0.2)
			end
		end

		for s = -1, 1, 2 do
			local swZ = s * (CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH/2)

			MakePart(s == -1 and "SidewalkL" or "SidewalkR",
				Vector3.new(segLen + 0.5, 1, CONFIG.SIDEWALK_WIDTH),
				Vector3.new(centerX, 0.25, swZ),
				CONFIG.COLORS.SIDEWALK, Enum.Material.Concrete, folder)

			MakePart("Curb", Vector3.new(segLen + 0.5, 0.5, 0.4),
				Vector3.new(centerX, 0.75, s * (CONFIG.STREET_WIDTH/2 + 0.2)),
				LerpColor(CONFIG.COLORS.SIDEWALK, Color3.new(0.15, 0.15, 0.15), 0.2),
				Enum.Material.Concrete, folder)
		end

		for i = 1, math.floor(segLen / CONFIG.LAMP_SPACING) do
			local lampX = startX + (i - 0.5) * CONFIG.LAMP_SPACING
			CreateLamp(lampX, (i % 2 == 0) and "left" or "right", folder)
		end
	end

	local bDepth = CONFIG.BUILDING_DEPTH
	local bWidth = CONFIG.BUILDING_WIDTH
	local swEdge = CONFIG.STREET_WIDTH/2 + CONFIG.SIDEWALK_WIDTH

	local numBuildings = math.floor(segLen / bWidth)

	local leftFaceZ = -swEdge
	local leftBackZ = leftFaceZ - bDepth

	for i = 1, numBuildings do
		local xPos = startX + (i - 0.5) * bWidth
		CreateBuilding(i, xPos, leftFaceZ, leftBackZ, 1, bWidth, "left", folder)
	end

	local rightFaceZ = swEdge
	local rightBackZ = rightFaceZ + bDepth

	for i = 1, numBuildings do
		local xPos = startX + (i - 0.5) * bWidth
		CreateBuilding(i, xPos, rightFaceZ, rightBackZ, -1, bWidth, "right", folder)
	end
end

-- ---------------------------------------------------------------------???---------
-- GENERATION AND CLEANUP
-- -------------------------------------------------------------------------------

local function Generate()
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local px = hrp.Position.X
				local s1 = math.floor((px - CONFIG.GENERATION_DISTANCE) / CONFIG.STREET_SEGMENT_LENGTH)
				local s2 = math.floor((px + CONFIG.GENERATION_DISTANCE) / CONFIG.STREET_SEGMENT_LENGTH)
				for s = s1, s2 do
					CreateSegment(s * CONFIG.STREET_SEGMENT_LENGTH)
				end
			end
		end
	end
end

local function Cleanup()
	local minX = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.X < minX then
				minX = hrp.Position.X
			end
		end
	end
	for key, data in pairs(streetSegments) do
		if data.endX < minX - CONFIG.CLEANUP_DISTANCE then
			if data.folder then data.folder:Destroy() end
			streetSegments[key] = nil
			generatedSegments[key] = nil
		end
	end
end

-- ---------------???---------------------------------------------------------------
-- PLAYER SETUP
-- -------------------------------------------------------------------------------

local function SetupPlayer(player)
	local function OnChar(char)
		local hum = char:WaitForChild("Humanoid", 10)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if hum and hrp then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			task.wait(0.5)
			hrp.CFrame = CFrame.new(0, 4, 0)
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			Generate()

			hum.Died:Connect(function()
				PlayerDiedEvent:FireClient(player)
			end)
		end
	end
	if player.Character then OnChar(player.Character) end
	player.CharacterAdded:Connect(OnChar)
end

-- -------------------------------------------------------------------------------
-- INITIALIZATION
-- -------------------------------------------------------------------------------

local function Init()
	print("---------------------------------------------------------------")
	print("       INFINITE STREET V27 - 6 NPCs + CUSTOM EYE ANIMATIONS    ")
	print("---------------------------------------------------------------")
	print("")
	print("Door Outcomes:")
	print("  - Nothing happens:   " ..DOOR_CONFIG.NOTHING_CHANCE .."%")
	print("  - Door opens (NPC):  " ..DOOR_CONFIG.OPEN_CHANCE .."%")
	print("")
	print("NPC Spawn Weights (within " ..DOOR_CONFIG.OPEN_CHANCE .."% open chance):")
	print("  Total Weight: " ..TOTAL_NPC_WEIGHT)
	print("")

	for npcType, npcData in pairs(NPC_STATS) do
		local spawnPercent = (npcData.SPAWN_WEIGHT / TOTAL_NPC_WEIGHT) * DOOR_CONFIG.OPEN_CHANCE
		print(string.format("  %s [%s]:", npcData.NAME, npcData.RARITY))
		print(string.format("    - Weight: %d (%.1f%% total chance)", npcData.SPAWN_WEIGHT, spawnPercent))
		print(string.format("    - Damage: %d | Speed: %d | Range: %d", npcData.DAMAGE, npcData.SPEED, npcData.ATTACK_RANGE))
		print(string.format("    - Rewards: Door $%d | Survive $%d", npcData.REWARD_DOOR_OPEN, npcData.REWARD_SURVIVAL))
		print(string.format("    - Danger Level: %d/5", npcData.DANGER_LEVEL))
		print(string.format("    - Eye Type: %s", npcData.EYE_TYPE))
		print("")
	end

	print("Safe Zone:   X=" ..CONFIG.LOBBY_START_X .." to X=" ..CONFIG.LOBBY_END_X)
	print("---------------------------------------------------------------")

	SetupAtmosphere()
	CreateLobby()

	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(5, 1, 5)
	spawn.Position = Vector3.new(0, 1.5, 0)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Parent = lobbyFolder

	for i = -3, 3 do
		CreateSegment(i * CONFIG.STREET_SEGMENT_LENGTH)
	end

	for _, p in pairs(Players: GetPlayers()) do SetupPlayer(p) end
	Players.PlayerAdded:Connect(SetupPlayer)

	local lastGen = 0
	RunService.Heartbeat:Connect(function()
		local t = tick()
		if t - lastGen > 0.5 then
			lastGen = t
			Generate()
		end
	end)

	coroutine.wrap(function()
		while true do
			task.wait(5)
			Cleanup()
		end
	end)()

	print("---------------------------------------------------------------")
	print("                         READY                                  ")
	print("---------------------------??-----------------------------------")
end
-- -------------------------------------------------------------------------------
-- +------------------------------------------------------------------------------+
-- �            THROWABLE OBJECTS SYSTEM - WITH STUN SYSTEM                       �
-- �                         VERSI�N CORREGIDA                                    �
-- +------------------------------------------------------------------------------+
-- -------------------------------------------------------------------------------

local THROWABLE_CONFIG = {
	-- Spawn settings
	SPAWN_CHANCE = 0.35,
	SPAWN_INTERVAL = 15,
	MAX_PER_SEGMENT = 6,

	-- Lobby bounds (same as CONFIG)
	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
	STREET_WIDTH = 50,

	-- Object types
	OBJECTS = {
		BOTTLE = {
			NAME = "GlassBottle",
			SIZE = Vector3.new(0.3, 0.8, 0.3),
			COLORS = {
				Color3.fromRGB(45, 80, 45),
				Color3.fromRGB(60, 40, 25),
				Color3.fromRGB(70, 100, 120),
				Color3.fromRGB(80, 80, 85),
			},
			MATERIAL = Enum.Material.Glass,
			TRANSPARENCY = 0.3,
			MASS = 0.5,
			BREAK_ON_IMPACT = true,
			BREAK_SOUND = "rbxassetid://282954522",
			PICKUP_TEXT = "Bottle",
		},
		BRICK = {
			NAME = "Brick",
			SIZE = Vector3.new(0.6, 0.3, 0.3),
			COLORS = {
				Color3.fromRGB(140, 70, 50),
				Color3.fromRGB(120, 80, 60),
				Color3.fromRGB(100, 100, 95),
			},
			MATERIAL = Enum.Material.Brick,
			TRANSPARENCY = 0,
			MASS = 1.2,
			BREAK_ON_IMPACT = false,
			HIT_SOUND = "rbxassetid://3932505367",
			PICKUP_TEXT = "Brick",
		},
	},

	-- Throw power levels
	THROW_POWER = {
		LIGHT = {
			MAX_HOLD_TIME = 0.3,
			FORCE = 45,
			UPWARD_ANGLE = 15,
			COLOR_INDICATOR = Color3.fromRGB(100, 255, 100),
			NAME = "Light",
			STUN_MULTIPLIER = 1.0,
		},
		MEDIUM = {
			MAX_HOLD_TIME = 0.8,
			FORCE = 85,
			UPWARD_ANGLE = 25,
			COLOR_INDICATOR = Color3.fromRGB(255, 255, 100),
			NAME = "Medium",
			STUN_MULTIPLIER = 1.5,
		},
		STRONG = {
			MAX_HOLD_TIME = math.huge,
			FORCE = 140,
			UPWARD_ANGLE = 35,
			COLOR_INDICATOR = Color3.fromRGB(255, 100, 100),
			NAME = "Strong",
			STUN_MULTIPLIER = 2.5,
		},
	},

	-- Damage settings
	DAMAGE = {
		BOTTLE_BASE = 5,
		BRICK_BASE = 10,
		FORCE_MULTIPLIER = 0.1,
	},

	-- Timers
	DESPAWN_TIME = 30,
	RESPAWN_TIME = 60,
}

-- -------------------------------------------------------------------------------
-- STUN TIMES PER NPC TYPE - Con diferenciación Head vs Body
-- -------------------------------------------------------------------------------

local NPC_STUN_TIMES = {
	-- Format: ["FolderName"] = { 
	--   HEAD = { CHARGE_1, CHARGE_2, CHARGE_3 },
	--   BODY = { CHARGE_1, CHARGE_2, CHARGE_3 },
	--   LEGACY_BOTTLE, LEGACY_BRICK (for NPCs without head/body differentiation)
	-- }
	
	["ShadowEntity"] = {
		-- Shadow no tiene diferenciación head/body (usar legacy)
		LEGACY_BOTTLE = 10.2,
		LEGACY_BRICK = 10.8,
	},

	["CrawlerEntity"] = {
		-- Crawler EXCLUIDO del sistema de diferenciación head/body
		LEGACY_BOTTLE = 1.5,
		LEGACY_BRICK = 2.2,
	},

	["PhantomEntity"] = {
		-- Phantom con diferenciación head/body
		HEAD = { 1.5, 2.5, 4.0 },  -- HEAD_CHARGE_1, HEAD_CHARGE_2, HEAD_CHARGE_3
		BODY = { 0.2, 0.5, 1.0 },  -- BODY_CHARGE_1, BODY_CHARGE_2, BODY_CHARGE_3
	},

	["ScreamerEntity"] = {
		-- Screamer con diferenciación head/body
		HEAD = { 1.5, 2.5, 4.0 },
		BODY = { 0.2, 0.5, 1.0 },
	},

	["WatcherEntity_HolographicV5"] = {
		-- Watcher con diferenciación head/body
		HEAD = { 1.5, 2.5, 4.0 },
		BODY = { 0.2, 0.5, 1.0 },
	},

	["HarvesterEntity"] = {
		-- Harvester con diferenciación head/body
		HEAD = { 1.5, 2.5, 4.0 },
		BODY = { 0.2, 0.5, 1.0 },
	},

	-- Default para NPCs desconocidos (sin diferenciación)
	["Default"] = {
		LEGACY_BOTTLE = 1.0,
		LEGACY_BRICK = 1.5,
	},
}

-- -------------------------------------------------------------------------------
-- STUN CONFIGURATION - 3 LEVELS
-- -------------------------------------------------------------------------------

local STUN_CONFIG = {
	-- Visual settings
	STAR_COUNT = 5,
	STAR_SIZE = 0.4,
	STAR_COLOR = Color3.fromRGB(255, 255, 100),
	STAR_ROTATION_SPEED = 200,
	STAR_ORBIT_RADIUS = 1.2,
	STAR_HEIGHT_OFFSET = 2.5,

	-- Stun levels (based on throw power)
	LEVELS = {
		LIGHT = {
			STARS = 3,
			FLASH_COLOR = Color3.fromRGB(255, 255, 150),
		},
		MEDIUM = {
			STARS = 5,
			FLASH_COLOR = Color3.fromRGB(255, 200, 100),
		},
		STRONG = {
			STARS = 7,
			FLASH_COLOR = Color3.fromRGB(255, 100, 100),
		},
	},
}

-- -------------------------------------------------------------------------------
-- THROWABLE REMOTE EVENTS
-- -------------------------------------------------------------------------------

local ThrowableRemotes = ReplicatedStorage:FindFirstChild("ThrowableRemotes") or Instance.new("Folder")
ThrowableRemotes.Name = "ThrowableRemotes"
ThrowableRemotes. Parent = ReplicatedStorage

local function GetOrCreateThrowableRemote(name)
	local existing = ThrowableRemotes:FindFirstChild(name)
	if existing then return existing end
	local new = Instance.new("RemoteEvent")
	new.Name = name
	new.Parent = ThrowableRemotes
	return new
end

local PickupThrowableEvent = GetOrCreateThrowableRemote("PickupThrowable")
local ThrowObjectEvent = GetOrCreateThrowableRemote("ThrowObject")
local UpdateThrowPowerEvent = GetOrCreateThrowableRemote("UpdateThrowPower")
local DropObjectEvent = GetOrCreateThrowableRemote("DropObject")

-- Track player held objects
local playerHeldObjects = {}

-- Track spawned throwables for cleanup
local segmentThrowables = {}

-- -------------------------------------------------------------------------------
-- STUN EFFECT SYSTEM - SPINNING STARS (CLEAN VERSION)
-- -------------------------------------------------------------------------------

local function CreateStunEffect(npcModel, stunTime, powerLevel)
	if not npcModel or not npcModel. Parent then return end

	-- Get stun level config
	local levelConfig = STUN_CONFIG. LEVELS[powerLevel] or STUN_CONFIG.LEVELS. LIGHT
	local starCount = levelConfig. STARS

	-- Find the head or main part to attach stars above
	local attachPart = npcModel:FindFirstChild("Head") 
		or npcModel: FindFirstChild("HeadMain")
		or npcModel: FindFirstChild("Chest")
		or npcModel:FindFirstChild("Thorax") 
		or npcModel:FindFirstChild("Abdomen")
		or npcModel:FindFirstChild("Eyeball")
		or npcModel:FindFirstChild("TorsoInner")
		or npcModel:FindFirstChild("CloakLower")
		or npcModel:FindFirstChildWhichIsA("BasePart")

	if not attachPart then return end

	-- Create stun effect folder
	local stunFolder = Instance.new("Folder")
	stunFolder.Name = "StunEffect"
	stunFolder.Parent = npcModel

	-- -----------------------------------------------------------------------
	-- CREATE STARS - CLEAN VERSION (NO GLOW ARTIFACTS)
	-- -----------------------------------------------------------------------
	local stars = {}
	for i = 1, starCount do
		local star = Instance.new("BillboardGui")
		star.Name = "Star" .. i
		star.Size = UDim2.new(0, 50, 0, 50)
		star.StudsOffset = Vector3.new(0, STUN_CONFIG. STAR_HEIGHT_OFFSET, 0)
		star.AlwaysOnTop = true
		star. LightInfluence = 0
		star.Parent = stunFolder

		-- Star emoji - CLEAN, NO BACKGROUND
		local starLabel = Instance.new("TextLabel")
		starLabel.Name = "StarIcon"
		starLabel.Size = UDim2.new(1, 0, 1, 0)
		starLabel.Position = UDim2.new(0, 0, 0, 0)
		starLabel.BackgroundTransparency = 1  -- NO BACKGROUND
		starLabel.Text = "?"
		starLabel.TextScaled = true
		starLabel.TextColor3 = STUN_CONFIG. STAR_COLOR
		starLabel.Font = Enum.Font.GothamBold
		starLabel.TextStrokeTransparency = 1  -- NO STROKE
		starLabel.Parent = star

		-- NO GLOW ImageLabel - removed to fix artifacts

		table.insert(stars, {
			gui = star,
			label = starLabel,
			angle = (i - 1) * (360 / starCount),
			orbitSpeed = STUN_CONFIG. STAR_ROTATION_SPEED + math.random(-20, 20),
		})
	end

	-- -----------------------------------------------------------------------
	-- CENTER TEXT - CLEAN VERSION
	-- -----------------------------------------------------------------------
	local centerIndicator = Instance.new("BillboardGui")
	centerIndicator. Name = "StunIndicator"
	centerIndicator.Size = UDim2.new(0, 100, 0, 30)
	centerIndicator.StudsOffset = Vector3.new(0, STUN_CONFIG. STAR_HEIGHT_OFFSET + 1.2, 0)
	centerIndicator. AlwaysOnTop = true
	centerIndicator.LightInfluence = 0
	centerIndicator.Parent = stunFolder

	local stunText = Instance.new("TextLabel")
	stunText.Size = UDim2.new(1, 0, 1, 0)
	stunText.BackgroundTransparency = 1  -- NO BACKGROUND
	stunText.Text = "?? STUNNED ??"
	stunText. TextScaled = true
	stunText. TextColor3 = levelConfig.FLASH_COLOR
	stunText.Font = Enum.Font.GothamBlack
	stunText.TextStrokeTransparency = 0  -- BLACK STROKE FOR VISIBILITY
	stunText. TextStrokeColor3 = Color3.new(0, 0, 0)
	stunText.Parent = centerIndicator

	-- -----------------------------------------------------------------------
	-- FLASH EFFECT ON NPC (brief color flash)
	-- -----------------------------------------------------------------------
	local originalColors = {}
	for _, part in pairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalColors[part] = part.Color
		end
	end

	-- Flash to stun color
	for part, _ in pairs(originalColors) do
		if part and part.Parent then
			part.Color = levelConfig.FLASH_COLOR
		end
	end

	-- Restore original colors after brief flash
	task.delay(0.15, function()
		for part, color in pairs(originalColors) do
			if part and part.Parent then
				part.Color = color
			end
		end
	end)

	-- -----------------------------------------------------------------------
	-- ANIMATION LOOP FOR SPINNING STARS
	-- -----------------------------------------------------------------------
	local startTime = tick()
	local animationConnection

	animationConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime

		-- Check if stun should end
		if elapsed >= stunTime or not stunFolder or not stunFolder.Parent then
			if animationConnection then
				animationConnection: Disconnect()
			end
			if stunFolder and stunFolder.Parent then
				-- Fade out effect
				for _, starData in ipairs(stars) do
					if starData.gui and starData.gui. Parent then
						TweenService:Create(starData.label, TweenInfo.new(0.3), {
							TextTransparency = 1
						}):Play()
					end
				end
				TweenService:Create(stunText, TweenInfo.new(0.3), {
					TextTransparency = 1
				}):Play()

				task.delay(0.35, function()
					if stunFolder and stunFolder.Parent then
						stunFolder:Destroy()
					end
				end)
			end
			return
		end

		-- Check if attach part still exists
		if not attachPart or not attachPart. Parent then
			if animationConnection then
				animationConnection: Disconnect()
			end
			if stunFolder then stunFolder:Destroy() end
			return
		end

		-- -------------------------------------------------------------------
		-- ANIMATE EACH STAR IN ORBIT
		-- -------------------------------------------------------------------
		for _, starData in ipairs(stars) do
			if starData.gui and starData.gui.Parent then
				-- Calculate orbit position
				local currentAngle = starData.angle + (elapsed * starData.orbitSpeed)
				local radAngle = math.rad(currentAngle)

				local offsetX = math.cos(radAngle) * STUN_CONFIG. STAR_ORBIT_RADIUS
				local offsetZ = math.sin(radAngle) * STUN_CONFIG.STAR_ORBIT_RADIUS
				local offsetY = math.sin(elapsed * 3 + starData.angle) * 0.15  -- Subtle bobbing

				-- Update position
				starData. gui.StudsOffset = Vector3.new(
					offsetX,
					STUN_CONFIG. STAR_HEIGHT_OFFSET + offsetY,
					offsetZ
				)
				starData.gui. Adornee = attachPart

				-- Pulse size effect
				local pulse = 1 + math.sin(elapsed * 5 + starData.angle) * 0.1
				starData.label.Size = UDim2.new(pulse, 0, pulse, 0)
				starData.label. Position = UDim2.new((1 - pulse) / 2, 0, (1 - pulse) / 2, 0)
			end
		end

		-- Update center indicator
		centerIndicator. Adornee = attachPart

		-- Pulse the stunned text
		local textPulse = 1 + math. sin(elapsed * 4) * 0.05
		stunText. TextTransparency = math.sin(elapsed * 6) * 0.15
	end)

	return stunFolder
end

-- -------------------------------------------------------------------------------
-- STUN NPC FUNCTION - Con detección de Head vs Body
-- -------------------------------------------------------------------------------

-- Configuration: Head part name patterns for detection
local HEAD_PART_PATTERNS = {
	"Head", "Skull", "Eye", "Face", "Jaw", 
	"Mouth", "Hood", "Void", "Brow", "Cranium"
}

-- Configuration: Head part names to search for in model
local HEAD_PART_NAMES = {
	"HeadMain", "Head", "Eyeball", "VoidFace", 
	"HoodBack", "SkullMain"
}

local function StunNPC(npcModel, objectType, powerLevel, stunMultiplier, hitPart)
	if not npcModel or not npcModel.Parent then return end

	-- Check if already stunned
	if npcModel:GetAttribute("Stunned") then 
		-- Extend stun time if hit again while stunned
		local currentStunEnd = npcModel:GetAttribute("StunEndTime") or 0
		local bonusTime = 0.5 * stunMultiplier
		local newStunEnd = math.max(currentStunEnd, tick() + bonusTime)
		npcModel:SetAttribute("StunEndTime", newStunEnd)
		print("⏱ Extended stun by " .. string.format("%.1f", bonusTime) .. "s")
		return 
	end

	-- Get NPC folder name to determine stun time
	local npcFolder = npcModel.Parent
	local folderName = "Default"

	if npcFolder and npcFolder:IsA("Folder") then
		folderName = npcFolder.Name
	end

	-- Get stun times for this NPC type
	local npcStunConfig = NPC_STUN_TIMES[folderName]
	if not npcStunConfig then
		npcStunConfig = NPC_STUN_TIMES["Default"]
		warn("⚠️ NPC type '" .. folderName .. "' not found in NPC_STUN_TIMES, using Default")
	end

	local baseStunTime = 1.0
	local hitZone = "UNKNOWN"
	
	-- -----------------------------------------------------------------------
	-- DETECCIÓN HEAD vs BODY (solo para NPCs con configuración HEAD/BODY)
	-- -----------------------------------------------------------------------
	
	if npcStunConfig.HEAD and npcStunConfig.BODY then
		-- Este NPC tiene diferenciación head/body
		local isHeadHit = false
		
		-- Detectar si el golpe fue en la cabeza basado en la parte golpeada o posición Y
		if hitPart then
			local hitPartName = hitPart.Name
			
			-- Verificar si golpeó directamente una parte de la cabeza usando patrones configurados
			for _, pattern in ipairs(HEAD_PART_PATTERNS) do
				if hitPartName:find(pattern) then
					isHeadHit = true
					break
				end
			end
			
			if not isHeadHit then
				-- Si no es una parte clara de cabeza, usar detección por posición Y
				local headPart = nil
				for _, partName in ipairs(HEAD_PART_NAMES) do
					headPart = npcModel:FindFirstChild(partName)
					if headPart then break end
				end
				
				if headPart and hitPart.Position then
					-- Si el impacto está cerca de la altura de la cabeza (dentro de un rango)
					local headY = headPart.Position.Y
					local hitY = hitPart.Position.Y
					local heightDiff = math.abs(hitY - headY)
					
					-- Si el golpe está dentro de 2 studs de la cabeza, contar como head hit
					if heightDiff < 2.5 then
						isHeadHit = true
					end
				end
			end
		end
		
		-- Determinar el índice de carga (1=LIGHT, 2=MEDIUM, 3=STRONG)
		local chargeIndex = 1
		if powerLevel == "MEDIUM" then
			chargeIndex = 2
		elseif powerLevel == "STRONG" then
			chargeIndex = 3
		end
		
		-- Obtener el tiempo base según si fue head o body
		if isHeadHit then
			baseStunTime = npcStunConfig.HEAD[chargeIndex]
			hitZone = "HEAD"
		else
			baseStunTime = npcStunConfig.BODY[chargeIndex]
			hitZone = "BODY"
		end
		
	else
		-- NPC con sistema legacy (Shadow, Crawler, o Default)
		-- Usar LEGACY_BOTTLE o LEGACY_BRICK
		if objectType == "BOTTLE" then
			baseStunTime = npcStunConfig.LEGACY_BOTTLE or 1.0
		else
			baseStunTime = npcStunConfig.LEGACY_BRICK or 1.5
		end
		hitZone = "LEGACY"
	end

	-- Final stun time is already configured per charge level (no multiplier needed)
	local stunDuration = baseStunTime

	-- Debug output
	print("---------------------------------------")
	print("💥 STUN APPLIED!")
	print("   NPC Folder: " .. folderName)
	print("   Object Type: " .. tostring(objectType))
	print("   Power Level: " .. tostring(powerLevel))
	print("   Hit Zone: " .. hitZone)
	print("   Hit Part: " .. (hitPart and hitPart.Name or "N/A"))
	print("   Stun Duration: " .. string.format("%.1f", stunDuration) .. "s")
	print("---------------------------------------")

	-- Mark as stunned
	npcModel:SetAttribute("Stunned", true)
	npcModel:SetAttribute("StunEndTime", tick() + stunDuration)

	-- Create visual stun effect
	CreateStunEffect(npcModel, stunDuration, powerLevel)

	-- Play stun sound
	local stunSound = Instance.new("Sound")
	stunSound.SoundId = "rbxassetid://3932505367"
	stunSound.Volume = 0.7
	stunSound.PlaybackSpeed = 1.2
	stunSound.Parent = npcModel
	stunSound:Play()
	Debris:AddItem(stunSound, 2)

	-- Remove stun after duration
	task.delay(stunDuration, function()
		if npcModel and npcModel.Parent then
			npcModel:SetAttribute("Stunned", false)
			npcModel:SetAttribute("StunEndTime", nil)
			print("✅ " .. folderName .. " stun ended after " .. string.format("%.1f", stunDuration) .. "s")
		end
	end)
end

-- -------------------------------------------------------------------------------
-- THROWABLE OBJECT CREATION
-- -------------------------------------------------------------------------------

local function CreateThrowableObject(objectType, position, parent)
	local config = THROWABLE_CONFIG. OBJECTS[objectType]
	if not config then return nil end

	local throwable = Instance.new("Part")
	throwable.Name = config.NAME
	throwable.Size = config.SIZE
	throwable.Position = position
	throwable.Color = config.COLORS[math.random(1, #config.COLORS)]
	throwable.Material = config.MATERIAL
	throwable.Transparency = config.TRANSPARENCY
	throwable. Anchored = false
	throwable. CanCollide = true
	throwable. Parent = parent

	-- Custom properties via attributes
	throwable:SetAttribute("ObjectType", objectType)
	throwable:SetAttribute("IsThrowable", true)
	throwable:SetAttribute("CanPickup", true)
	throwable:SetAttribute("Mass", config.MASS)
	throwable:SetAttribute("BreakOnImpact", config. BREAK_ON_IMPACT)

	-- Random rotation for variety
	throwable. CFrame = throwable.CFrame * CFrame. Angles(
		math.rad(math.random(-10, 10)),
		math.rad(math.random(0, 360)),
		math.rad(math.random(-10, 10))
	)

	-- Proximity prompt for pickup
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick Up"
	prompt. ObjectText = config. PICKUP_TEXT
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 6
	prompt.RequiresLineOfSight = true
	prompt.Parent = throwable

	-- Click detector as backup
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 8
	click.Parent = throwable

	-- Pickup handler
	local function OnPickup(player)
		if not throwable: GetAttribute("CanPickup") then return end
		if playerHeldObjects[player. UserId] then return end

		local char = player.Character
		if not char then return end

		local humanoid = char: FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		-- Mark as picked up
		throwable:SetAttribute("CanPickup", false)
		prompt. Enabled = false
		click.MaxActivationDistance = 0

		-- Store reference
		playerHeldObjects[player.UserId] = {
			object = throwable,
			objectType = objectType,
			config = config,
		}

		-- Attach to player's hand
		throwable. Anchored = true
		throwable. CanCollide = false
		throwable. Transparency = config.TRANSPARENCY

		-- Weld to right hand
		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		if rightHand then
			local weld = Instance. new("Weld")
			weld.Name = "ThrowableWeld"
			weld.Part0 = rightHand
			weld.Part1 = throwable
			weld. C0 = CFrame.new(0, -0.5, 0)
			weld.Parent = throwable
			throwable. Anchored = false
		end

		-- Notify client
		PickupThrowableEvent:FireClient(player, objectType, config. PICKUP_TEXT)
	end

	prompt. Triggered:Connect(OnPickup)
	click.MouseClick:Connect(OnPickup)

	return throwable
end

-- -------------------------------------------------------------------------------
-- THROW MECHANICS WITH STUN
-- -------------------------------------------------------------------------------

local function CalculateThrowPower(holdTime)
	if holdTime <= THROWABLE_CONFIG. THROW_POWER. LIGHT. MAX_HOLD_TIME then
		return THROWABLE_CONFIG. THROW_POWER.LIGHT, "LIGHT"
	elseif holdTime <= THROWABLE_CONFIG.THROW_POWER.MEDIUM. MAX_HOLD_TIME then
		return THROWABLE_CONFIG.THROW_POWER.MEDIUM, "MEDIUM"
	else
		return THROWABLE_CONFIG. THROW_POWER. STRONG, "STRONG"
	end
end

local function ThrowObject(player, holdTime, aimDirection)
	local heldData = playerHeldObjects[player.UserId]
	if not heldData then return end

	local throwable = heldData.object
	local objectType = heldData.objectType
	local config = heldData.config

	if not throwable or not throwable. Parent then
		playerHeldObjects[player.UserId] = nil
		return
	end

	local character = player.Character
	if not character then return end

	-- Get throw power and level
	local power, powerLevel = CalculateThrowPower(holdTime)

	-- Remove weld
	local weld = throwable:FindFirstChild("ThrowableWeld")
	if weld then weld:Destroy() end

	-- Position throwable in front of camera (at eye level)
	local head = character:FindFirstChild("Head")
	if head then
		local spawnOffset = aimDirection * 2
		throwable.CFrame = CFrame. new(head.Position + spawnOffset)
	end

	-- Enable physics
	throwable. Anchored = false
	throwable. CanCollide = true

	-- Apply velocity directly in aim direction
	local speed = power. FORCE
	throwable.AssemblyLinearVelocity = aimDirection. Unit * speed

	-- Minimal spin for visual effect
	throwable.AssemblyAngularVelocity = Vector3.new(
		math.random(-8, 8),
		math.random(-4, 4),
		math.random(-8, 8)
	)

	-- Clear held object
	playerHeldObjects[player.UserId] = nil

	-- Impact detection
	local impactConnection
	local hasImpacted = false

	impactConnection = throwable.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end
		if hit: IsDescendantOf(character) then return end
		if hasImpacted and config.BREAK_ON_IMPACT then return end

		-- -------------------------------------------------------------------
		-- CHECK FOR NPC HIT
		-- -------------------------------------------------------------------

		local hitModel = hit.Parent
		local isNPC = false
		local npcModel = nil

		if hitModel then
			-- Check if it's directly an NPC model
			if hitModel:FindFirstChild("Thorax") 
				or hitModel:FindFirstChild("Abdomen") 
				or hitModel:FindFirstChild("Head")
				or hitModel:FindFirstChild("HeadMain")
				or hitModel:FindFirstChild("Chest")
				or hitModel: FindFirstChild("Eyeball")
				or hitModel:FindFirstChild("TorsoInner")
				or hitModel:FindFirstChild("CloakLower") then
				isNPC = true
				npcModel = hitModel
				-- Check parent (in case we hit a sub-part)
			elseif hitModel. Parent and hitModel.Parent:IsA("Model") then
				local parentModel = hitModel.Parent
				if parentModel:FindFirstChild("Thorax") 
					or parentModel:FindFirstChild("Abdomen")
					or parentModel:FindFirstChild("Chest")
					or parentModel:FindFirstChild("Eyeball")
					or parentModel:FindFirstChild("TorsoInner")
					or parentModel:FindFirstChild("CloakLower") then
					isNPC = true
					npcModel = parentModel
				end
				-- Check for Model inside Folder structure
			elseif hitModel.Parent and hitModel.Parent:IsA("Folder") then
				for _, child in pairs(hitModel.Parent:GetChildren()) do
					if child:IsA("Model") then
						if child: FindFirstChild("Thorax") 
							or child:FindFirstChild("Abdomen")
							or child: FindFirstChild("Chest")
							or child:FindFirstChild("Eyeball")
							or child: FindFirstChild("TorsoInner")
							or child: FindFirstChild("CloakLower") then
							isNPC = true
							npcModel = child
							break
						end
					end
				end
			end
		end

		-- Check if hit has Humanoid (player or humanoid NPC)
		local hitHumanoid = hit.Parent:FindFirstChild("Humanoid")
		local isPlayer = hitHumanoid and Players: GetPlayerFromCharacter(hit.Parent)

		-- Apply damage to humanoids
		if hitHumanoid then
			local damage = objectType == "BOTTLE" 
				and THROWABLE_CONFIG. DAMAGE. BOTTLE_BASE 
				or THROWABLE_CONFIG. DAMAGE.BRICK_BASE
			damage = damage + (power.FORCE * THROWABLE_CONFIG. DAMAGE.FORCE_MULTIPLIER)
			hitHumanoid:TakeDamage(damage)
		end

		-- -------------------------------------------------------------------
		-- APPLY STUN TO NPC - Con detección de Head vs Body
		-- -------------------------------------------------------------------

		if isNPC and npcModel and not isPlayer then
			-- Pasar: npcModel, objectType ("BOTTLE" o "BRICK"), powerLevel ("LIGHT"/"MEDIUM"/"STRONG"), multiplier, hitPart
			StunNPC(npcModel, objectType, powerLevel, power.STUN_MULTIPLIER, hit)
		end

		-- Break effect for bottles
		if config. BREAK_ON_IMPACT and throwable. AssemblyLinearVelocity. Magnitude > 10 then
			hasImpacted = true

			local breakSound = Instance.new("Sound")
			breakSound.SoundId = config.BREAK_SOUND
			breakSound.Volume = 0.8
			breakSound. Parent = throwable
			breakSound:Play()

			local shardCount = math.random(4, 8)
			for i = 1, shardCount do
				local shard = Instance.new("Part")
				shard.Name = "GlassShard"
				shard.Size = Vector3.new(
					math.random(5, 15) / 100,
					math. random(5, 15) / 100,
					math. random(2, 5) / 100
				)
				shard.Position = throwable.Position + Vector3.new(
					math.random(-5, 5) / 10,
					math. random(0, 5) / 10,
					math.random(-5, 5) / 10
				)
				shard.Color = throwable.Color
				shard.Material = Enum.Material. Glass
				shard. Transparency = 0.4
				shard. CanCollide = true
				shard. Parent = workspace

				shard.AssemblyLinearVelocity = Vector3.new(
					math.random(-15, 15),
					math.random(5, 15),
					math.random(-15, 15)
				)

				Debris:AddItem(shard, 5)
			end

			task.delay(0.1, function()
				if throwable and throwable.Parent then
					throwable: Destroy()
				end
			end)

			if impactConnection then
				impactConnection: Disconnect()
			end
		else
			if config.HIT_SOUND and throwable.AssemblyLinearVelocity. Magnitude > 8 then
				local existingSound = throwable:FindFirstChild("HitSound")
				if not existingSound then
					local hitSound = Instance.new("Sound")
					hitSound.Name = "HitSound"
					hitSound.SoundId = config.HIT_SOUND
					hitSound.Volume = 0.6
					hitSound. Parent = throwable
					hitSound:Play()
					Debris:AddItem(hitSound, 2)
				end
			end
		end
	end)

	-- Re-enable pickup after landing
	task.delay(2, function()
		if throwable and throwable. Parent then
			if not config.BREAK_ON_IMPACT or throwable.AssemblyLinearVelocity.Magnitude < 5 then
				throwable:SetAttribute("CanPickup", true)
				local prompt = throwable:FindFirstChild("ProximityPrompt")
				if prompt then prompt. Enabled = true end
				local click = throwable:FindFirstChild("ClickDetector")
				if click then click. MaxActivationDistance = 8 end
			end
		end

		task.delay(3, function()
			if impactConnection then
				impactConnection: Disconnect()
			end
		end)
	end)

	Debris:AddItem(throwable, THROWABLE_CONFIG. DESPAWN_TIME)
end

local function DropObject(player)
	local heldData = playerHeldObjects[player. UserId]
	if not heldData then return end

	local throwable = heldData.object

	if throwable and throwable. Parent then
		local weld = throwable: FindFirstChild("ThrowableWeld")
		if weld then weld: Destroy() end

		throwable. Anchored = false
		throwable. CanCollide = true

		task.delay(1, function()
			if throwable and throwable.Parent then
				throwable:SetAttribute("CanPickup", true)
				local prompt = throwable:FindFirstChild("ProximityPrompt")
				if prompt then prompt.Enabled = true end
				local click = throwable:FindFirstChild("ClickDetector")
				if click then click. MaxActivationDistance = 8 end
			end
		end)
	end

	playerHeldObjects[player.UserId] = nil
end

-- Connect remote events
ThrowObjectEvent.OnServerEvent:Connect(function(player, holdTime, aimDirection)
	ThrowObject(player, holdTime, aimDirection)
end)

DropObjectEvent.OnServerEvent:Connect(function(player)
	DropObject(player)
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	local heldData = playerHeldObjects[player. UserId]
	if heldData and heldData.object and heldData.object.Parent then
		heldData.object: Destroy()
	end
	playerHeldObjects[player. UserId] = nil
end)

-- -------------------------------------------------------------------------------
-- SPAWN THROWABLES IN STREET SEGMENTS
-- -------------------------------------------------------------------------------

local function SpawnThrowablesInSegment(segmentFolder, startX, segmentLength)
	local key = segmentFolder. Name
	if segmentThrowables[key] then return end
	segmentThrowables[key] = {}

	local segmentEnd = startX + segmentLength
	local overlapsLobby = not (segmentEnd < THROWABLE_CONFIG. LOBBY_START_X or startX > THROWABLE_CONFIG.LOBBY_END_X)
	if overlapsLobby then return end

	local spawnedCount = 0
	local maxSpawns = THROWABLE_CONFIG. MAX_PER_SEGMENT

	for i = 1, math.floor(segmentLength / THROWABLE_CONFIG.SPAWN_INTERVAL) do
		if spawnedCount >= maxSpawns then break end

		if TrueRandomFloat() < THROWABLE_CONFIG. SPAWN_CHANCE then
			local xPos = startX + (i - 0.5) * THROWABLE_CONFIG. SPAWN_INTERVAL + math.random(-5, 5)
			local side = math.random() > 0.5 and 1 or -1
			local zPos = side * (THROWABLE_CONFIG. STREET_WIDTH/2 + math.random(1, 8))
			local yPos = 1

			local objectType = math.random() < 0.6 and "BOTTLE" or "BRICK"

			local position = Vector3.new(xPos, yPos, zPos)
			local throwable = CreateThrowableObject(objectType, position, segmentFolder)

			if throwable then
				table.insert(segmentThrowables[key], throwable)
				spawnedCount = spawnedCount + 1
			end
		end
	end
end

-- -------------------------------------------------------------------------------
-- HOOK INTO SEGMENT CREATION
-- -------------------------------------------------------------------------------

local OriginalCreateSegment = CreateSegment

CreateSegment = function(startX)
	OriginalCreateSegment(startX)

	local key = tostring(math.floor(startX / CONFIG.STREET_SEGMENT_LENGTH))
	local segmentData = streetSegments[key]

	if segmentData and segmentData.folder then
		SpawnThrowablesInSegment(segmentData.folder, startX, CONFIG.STREET_SEGMENT_LENGTH)
	end
end

print("-----------------------------------------------------------")
print("? THROWABLE SYSTEM LOADED - WITH CUSTOM STUN TIMES")
print("   ? Light throw:   1.0x stun duration")
print("   ? Medium throw: 1.5x stun duration")
print("   ? Strong throw:  2.5x stun duration")
print("-----------------------------------------------------------")

-- -------------------------------------------------------------------------------
-- END OF THROWABLE + STUN SYSTEM
-- -------------------------------------------------------------------------------
Init()