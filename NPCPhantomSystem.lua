--[[
    +------------------------------------------------------------------------------+
    ¦                        NPC PHANTOM ENTITY SYSTEM                              ¦
    ¦                    VERSIÓN 3 - ENHANCED ETHEREAL SPECTER                      ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnPhantomEvent = ReplicatedStorage:WaitForChild("SpawnPhantomEvent", 10)

-- -------------------------------------------------------------------------------
-- CONFIGURACIÓN DEL PHANTOM
-- -------------------------------------------------------------------------------
local PHANTOM_CONFIG = {
	SPEED = 14,
	DAMAGE = 35,
	ATTACK_COOLDOWN = 1.5,
	ATTACK_RANGE = 8,
	DETECTION_RANGE = 280,
	LIFETIME = 55,
	REWARD_SURVIVAL = 25,

	TELEPORT_COOLDOWN = 5,
	TELEPORT_RANGE = 15,

	-- APPEARANCE - Enhanced ethereal colors
	BODY_PRIMARY = Color3.fromRGB(140, 170, 200),
	BODY_SECONDARY = Color3.fromRGB(100, 140, 180),
	BODY_FADE = Color3.fromRGB(80, 120, 160),
	GLOW_PRIMARY = Color3.fromRGB(60, 180, 255),
	GLOW_SECONDARY = Color3.fromRGB(100, 200, 255),
	GLOW_INTENSE = Color3.fromRGB(150, 220, 255),
	EYE_COLOR = Color3.fromRGB(0, 220, 255),
	EYE_INNER = Color3.fromRGB(200, 250, 255),
	VOID_COLOR = Color3.fromRGB(8, 12, 20),
	VOID_DEEP = Color3.fromRGB(3, 5, 10),
	CHAIN_COLOR = Color3.fromRGB(60, 70, 90),
	SOUL_COLOR = Color3.fromRGB(180, 220, 255),

	-- DIMENSIONS
	TOTAL_HEIGHT = 6.5,
	TORSO_WIDTH = 2.2,
	HEAD_SIZE = Vector3.new(1.6, 1.8, 1.4),

	-- ANIMATION
	FLOAT_SPEED = 1.8,
	FLOAT_AMPLITUDE = 0.35,
	SWAY_SPEED = 1.0,
	BREATH_SPEED = 0.6,
	CLOTH_WAVE_SPEED = 2.5,

	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

local function IsInLobby(x)
	return x >= PHANTOM_CONFIG.LOBBY_START_X and x <= PHANTOM_CONFIG.LOBBY_END_X
end

-- -------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-- -------------------------------------------------------------------------------

local function CreatePart(name, size, color, material, transparency, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function CreateMesh(parent, meshType, scale)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = meshType or Enum.MeshType.Brick
	if scale then
		mesh.Scale = scale
	end
	mesh.Parent = parent
	return mesh
end

local function CreateGlow(parent, color, brightness, range, shadows)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness or 2
	light.Range = range or 10
	light.Shadows = shadows or false
	light.Parent = parent
	return light
end

-- -------------------------------------------------------------------------------
-- CREATE PHANTOM NPC
-- -------------------------------------------------------------------------------

local function CreatePhantomNPC(spawnPosition, triggerPlayer, side, zDir)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "PhantomEntity"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "PhantomNPC"
	npcModel.Parent = npcFolder

	local groundY = 0.5
	local floatHeight = 1.8

	-- Height references
	local HEIGHT = PHANTOM_CONFIG.TOTAL_HEIGHT

	-- ---------------------------------------------------------------------------
	-- ETHEREAL CORE (Inner glowing essence)
	-- ---------------------------------------------------------------------------

	local soulCore = CreatePart(
		"SoulCore",
		Vector3.new(0.8, 1.2, 0.5),
		PHANTOM_CONFIG.GLOW_PRIMARY,
		Enum.Material.Neon,
		0.3,
		npcModel
	)
	CreateMesh(soulCore, Enum.MeshType.Sphere)

	local coreLight = CreateGlow(soulCore, PHANTOM_CONFIG.GLOW_PRIMARY, 2, 18, false)

	-- Core pulse ring
	local coreRing = CreatePart(
		"CoreRing",
		Vector3.new(1.5, 1.5, 0.1),
		PHANTOM_CONFIG.GLOW_SECONDARY,
		Enum.Material.Neon,
		0.5,
		npcModel
	)
	CreateMesh(coreRing, Enum.MeshType.Cylinder)

	-- ------------------------------------------------??--------------------------
	-- SPECTRAL TORSO (Layered ethereal body)
	-- ---------------------------------------------------------------------------

	-- Outer torso layer (most transparent)
	local torsoOuter = CreatePart(
		"TorsoOuter",
		Vector3.new(PHANTOM_CONFIG.TORSO_WIDTH * 1.2, HEIGHT * 0.4, 1.0),
		PHANTOM_CONFIG.BODY_FADE,
		Enum.Material.Glass,
		0.6,
		npcModel
	)
	CreateMesh(torsoOuter, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 0.6))

	-- Middle torso layer
	local torsoMiddle = CreatePart(
		"TorsoMiddle",
		Vector3.new(PHANTOM_CONFIG.TORSO_WIDTH, HEIGHT * 0.35, 0.8),
		PHANTOM_CONFIG.BODY_SECONDARY,
		Enum.Material.Glass,
		0.45,
		npcModel
	)
	CreateMesh(torsoMiddle, Enum.MeshType.Sphere, Vector3.new(1, 1.15, 0.7))

	-- Inner torso layer (main body)
	local torsoInner = CreatePart(
		"TorsoInner",
		Vector3.new(PHANTOM_CONFIG.TORSO_WIDTH * 0.8, HEIGHT * 0.3, 0.6),
		PHANTOM_CONFIG.BODY_PRIMARY,
		Enum.Material.Glass,
		0.35,
		npcModel
	)
	torsoInner.CanCollide = true
	CreateMesh(torsoInner, Enum.MeshType.Sphere, Vector3.new(1, 1.1, 0.8))

	-- ---------------------------------------------------------------------------
	-- SHOULDER WISPS (Ethereal shoulder formations)
	-- ---------------------------------------------------------------------------

	local shoulders = {}
	for i = 1, 2 do
		local side = i == 1 and -1 or 1

		local shoulderMain = CreatePart(
			"ShoulderMain" ..i,
			Vector3.new(0.7, 0.5, 0.5),
			PHANTOM_CONFIG.BODY_PRIMARY,
			Enum.Material.Glass,
			0.4,
			npcModel
		)
		CreateMesh(shoulderMain, Enum.MeshType.Sphere)

		local shoulderWisp = CreatePart(
			"ShoulderWisp" ..i,
			Vector3.new(0.5, 0.8, 0.3),
			PHANTOM_CONFIG.BODY_FADE,
			Enum.Material.Glass,
			0.6,
			npcModel
		)
		CreateMesh(shoulderWisp, Enum.MeshType.Sphere, Vector3.new(1, 1.5, 0.8))

		table.insert(shoulders, {
			main = shoulderMain,
			wisp = shoulderWisp,
			side = side
		})
	end

	-- ---------------------------------------------------------------------------
	-- HOOD/COWL (Shrouded head covering)
	-- ---------------------------------------------------------------------------

	local hoodBack = CreatePart(
		"HoodBack",
		Vector3.new(2.0, 2.2, 1.8),
		PHANTOM_CONFIG.BODY_SECONDARY,
		Enum.Material.Glass,
		0.35,
		npcModel
	)
	CreateMesh(hoodBack, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.9))

	local hoodTop = CreatePart(
		"HoodTop",
		Vector3.new(1.6, 0.8, 1.4),
		PHANTOM_CONFIG.BODY_PRIMARY,
		Enum.Material.Glass,
		0.4,
		npcModel
	)
	CreateMesh(hoodTop, Enum.MeshType.Sphere)

	-- Hood rim (creates frame around face)
	local hoodRimLeft = CreatePart(
		"HoodRimLeft",
		Vector3.new(0.2, 1.6, 0.6),
		PHANTOM_CONFIG.BODY_FADE,
		Enum.Material.Glass,
		0.45,
		npcModel
	)

	local hoodRimRight = CreatePart(
		"HoodRimRight",
		Vector3.new(0.2, 1.6, 0.6),
		PHANTOM_CONFIG.BODY_FADE,
		Enum.Material.Glass,
		0.45,
		npcModel
	)

	-- ---------------------------------------------------------------------------
	-- VOID FACE (Deep darkness within hood)
	-- ---------------------------------------------------------------------------

	local voidFace = CreatePart(
		"VoidFace",
		Vector3.new(1.3, 1.5, 0.8),
		PHANTOM_CONFIG.VOID_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(voidFace, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.6))

	local voidDeep = CreatePart(
		"VoidDeep",
		Vector3.new(1.0, 1.2, 0.5),
		PHANTOM_CONFIG.VOID_DEEP,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(voidDeep, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.5))

	-- ---------------------------------------------------------------------------
	-- SPECTRAL EYES (Glowing ethereal eyes)
	-- ---------------------------------------------------------------------------

	local eyes = {}
	for i = 1, 2 do
		local eyeSide = i == 1 and -1 or 1

		-- Eye void socket
		local eyeSocket = CreatePart(
			"EyeSocket" ..i,
			Vector3.new(0.4, 0.35, 0.2),
			PHANTOM_CONFIG.VOID_DEEP,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(eyeSocket, Enum.MeshType.Sphere)

		-- Eye glow (main)
		local eyeGlow = CreatePart(
			"EyeGlow" ..i,
			Vector3.new(0.32, 0.28, 0.12),
			PHANTOM_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeGlow, Enum.MeshType.Sphere)

		-- Eye inner (bright center)
		local eyeInner = CreatePart(
			"EyeInner" ..i,
			Vector3.new(0.15, 0.12, 0.06),
			PHANTOM_CONFIG.EYE_INNER,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeInner, Enum.MeshType.Sphere)

		-- Eye trail (ghostly trail behind eye)
		local eyeTrail = CreatePart(
			"EyeTrail" ..i,
			Vector3.new(0.2, 0.15, 0.4),
			PHANTOM_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			0.4,
			npcModel
		)
		CreateMesh(eyeTrail, Enum.MeshType.Sphere, Vector3.new(1, 1, 2))

		local eyeLight = CreateGlow(eyeGlow, PHANTOM_CONFIG.EYE_COLOR, 3.5, 10, true)

		table.insert(eyes, {
			socket = eyeSocket,
			glow = eyeGlow,
			inner = eyeInner,
			trail = eyeTrail,
			light = eyeLight,
			side = eyeSide,
			baseBrightness = 3.5
		})
	end

	-- ---------------------------------------------------------------------------
	-- SPECTRAL MOUTH (Ghostly wailing mouth)
	-- ---------------------------------------------------------------------------

	local mouthVoid = CreatePart(
		"MouthVoid",
		Vector3.new(0.5, 0.3, 0.15),
		PHANTOM_CONFIG.VOID_DEEP,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(mouthVoid, Enum.MeshType.Sphere, Vector3.new(1, 0.6, 0.5))

	local mouthGlow = CreatePart(
		"MouthGlow",
		Vector3.new(0.35, 0.15, 0.08),
		PHANTOM_CONFIG.GLOW_PRIMARY,
		Enum.Material.Neon,
		0.5,
		npcModel
	)
	CreateMesh(mouthGlow, Enum.MeshType.Sphere)

	-- ---------------------------------------------------------------------------
	-- ETHEREAL ARMS (Ghostly floating arms)
	-- ---------------------------------------------------------------------------

	local arms = {}
	for i = 1, 2 do
		local armSide = i == 1 and -1 or 1

		-- Upper arm (connected to shoulder)
		local upperArm = CreatePart(
			"UpperArm" ..i,
			Vector3.new(0.35, 1.4, 0.3),
			PHANTOM_CONFIG.BODY_PRIMARY,
			Enum.Material.Glass,
			0.45,
			npcModel
		)
		CreateMesh(upperArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Elbow wisp (ethereal joint)
		local elbowWisp = CreatePart(
			"ElbowWisp" ..i,
			Vector3.new(0.3, 0.3, 0.3),
			PHANTOM_CONFIG.GLOW_SECONDARY,
			Enum.Material.Neon,
			0.5,
			npcModel
		)
		CreateMesh(elbowWisp, Enum.MeshType.Sphere)

		-- Lower arm
		local lowerArm = CreatePart(
			"LowerArm" ..i,
			Vector3.new(0.28, 1.2, 0.25),
			PHANTOM_CONFIG.BODY_SECONDARY,
			Enum.Material.Glass,
			0.5,
			npcModel
		)
		CreateMesh(lowerArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Wrist wisp
		local wristWisp = CreatePart(
			"WristWisp" ..i,
			Vector3.new(0.25, 0.25, 0.25),
			PHANTOM_CONFIG.GLOW_SECONDARY,
			Enum.Material.Neon,
			0.55,
			npcModel
		)
		CreateMesh(wristWisp, Enum.MeshType.Sphere)

		-- Spectral hand
		local hand = CreatePart(
			"Hand" ..i,
			Vector3.new(0.4, 0.5, 0.15),
			PHANTOM_CONFIG.GLOW_PRIMARY,
			Enum.Material.Neon,
			0.35,
			npcModel
		)
		CreateMesh(hand, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 0.5))

		local handGlow = CreateGlow(hand, PHANTOM_CONFIG.GLOW_PRIMARY, 1.5, 6, false)

		-- Ghostly fingers
		local fingers = {}
		for f = 1, 4 do
			local finger = CreatePart(
				"Finger" ..i .."_" ..f,
				Vector3.new(0.06, 0.3, 0.06),
				PHANTOM_CONFIG.BODY_FADE,
				Enum.Material.Glass,
				0.55,
				npcModel
			)
			CreateMesh(finger, Enum.MeshType.Sphere, Vector3.new(1, 3, 1))
			table.insert(fingers, finger)
		end

		table.insert(arms, {
			upper = upperArm,
			elbowWisp = elbowWisp,
			lower = lowerArm,
			wristWisp = wristWisp,
			hand = hand,
			handGlow = handGlow,
			fingers = fingers,
			side = armSide
		})
	end

	-- ---------------------------------------------------------------------------
	-- SPECTRAL TAIL (Fading ethereal lower body)
	-- ---------------------------------------------------------------------------

	local tailSegments = {}
	local numTailSegments = 8

	for i = 1, numTailSegments do
		local progress = i / numTailSegments
		local segmentWidth = PHANTOM_CONFIG.TORSO_WIDTH * (1 - progress * 0.7)
		local segmentHeight = 0.4 - progress * 0.15
		local segmentDepth = 0.6 * (1 - progress * 0.5)

		local segment = CreatePart(
			"TailSegment" ..i,
			Vector3.new(segmentWidth, segmentHeight, segmentDepth),
			PHANTOM_CONFIG.BODY_FADE,
			Enum.Material.Glass,
			0.35 + progress * 0.55,
			npcModel
		)
		CreateMesh(segment, Enum.MeshType.Sphere, Vector3.new(1, 0.8, 1))

		table.insert(tailSegments, {
			part = segment,
			index = i,
			progress = progress,
			baseTransparency = 0.35 + progress * 0.55
		})
	end

	-- Tail wisps (ethereal tendrils at the end)
	local tailWisps = {}
	for i = 1, 5 do
		local wisp = CreatePart(
			"TailWisp" ..i,
			Vector3.new(0.15, 0.6 + math.random() * 0.3, 0.15),
			PHANTOM_CONFIG.GLOW_SECONDARY,
			Enum.Material.Neon,
			0.6,
			npcModel
		)
		CreateMesh(wisp, Enum.MeshType.Sphere, Vector3.new(1, 2.5, 1))

		table.insert(tailWisps, {
			part = wisp,
			angle = (i / 5) * math.pi * 2,
			length = 0.6 + math.random() * 0.3
		})
	end

	-- ---------------------------------------------------------------------------
	-- GHOSTLY CHAINS (Spectral chains binding the spirit)
	-- ---------------------------------------------------------------------------

	local chains = {}
	local chainPositions = {
		{yOffset = 0.5, rotation = 0},
		{yOffset = -0.3, rotation = math.rad(45)},
		{yOffset = -1.0, rotation = math.rad(90)},
	}

	for i, chainData in ipairs(chainPositions) do
		local chainRing = CreatePart(
			"ChainRing" ..i,
			Vector3.new(2.5 - i * 0.3, 2.5 - i * 0.3, 0.12),
			PHANTOM_CONFIG.CHAIN_COLOR,
			Enum.Material.Metal,
			0.3,
			npcModel
		)
		CreateMesh(chainRing, Enum.MeshType.Cylinder)

		-- Broken chain links hanging
		local chainLink = CreatePart(
			"ChainLink" ..i,
			Vector3.new(0.15, 0.5, 0.08),
			PHANTOM_CONFIG.CHAIN_COLOR,
			Enum.Material.Metal,
			0.25,
			npcModel
		)

		table.insert(chains, {
			ring = chainRing,
			link = chainLink,
			yOffset = chainData.yOffset,
			rotation = chainData.rotation
		})
	end

	-- ---------------------------------------------------------------------------
	-- PARTICLE EFFECTS
	-- ---------------------------------------------------------------------------

	-- Main ethereal aura
	local auraEmitter = Instance.new("ParticleEmitter")
	auraEmitter.Texture = "rbxassetid://243098098"
	auraEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PHANTOM_CONFIG.GLOW_PRIMARY),
		ColorSequenceKeypoint.new(0.5, PHANTOM_CONFIG.GLOW_SECONDARY),
		ColorSequenceKeypoint.new(1, PHANTOM_CONFIG.BODY_FADE)
	})
	auraEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 1.5),
		NumberSequenceKeypoint.new(1, 2.5)
	})
	auraEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	auraEmitter.Lifetime = NumberRange.new(0.6, 1.2)
	auraEmitter.Rate = 15
	auraEmitter.Speed = NumberRange.new(0.5, 2)
	auraEmitter.SpreadAngle = Vector2.new(360, 360)
	auraEmitter.RotSpeed = NumberRange.new(-30, 30)
	auraEmitter.Parent = torsoInner

	-- Soul wisps floating upward
	local soulWisps = Instance.new("ParticleEmitter")
	soulWisps.Texture = "rbxassetid://243098098"
	soulWisps.Color = ColorSequence.new(PHANTOM_CONFIG.SOUL_COLOR)
	soulWisps.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	soulWisps.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	soulWisps.Lifetime = NumberRange.new(1.5, 2.5)
	soulWisps.Rate = 4
	soulWisps.Speed = NumberRange.new(1, 3)
	soulWisps.SpreadAngle = Vector2.new(30, 30)
	soulWisps.Acceleration = Vector3.new(0, 2, 0)
	soulWisps.Parent = soulCore

	-- Ghostly mist at tail
	local mistEmitter = Instance.new("ParticleEmitter")
	mistEmitter.Texture = "rbxassetid://243098098"
	mistEmitter.Color = ColorSequence.new(PHANTOM_CONFIG.BODY_FADE)
	mistEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 2)
	})
	mistEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	mistEmitter.Lifetime = NumberRange.new(0.4, 0.8)
	mistEmitter.Rate = 10
	mistEmitter.Speed = NumberRange.new(0.5, 1.5)
	mistEmitter.SpreadAngle = Vector2.new(180, 180)
	mistEmitter.Parent = tailSegments[#tailSegments].part

	-- Eye trail particles
	for _, eyeData in ipairs(eyes) do
		local eyeTrailEmitter = Instance.new("ParticleEmitter")
		eyeTrailEmitter.Texture = "rbxassetid://243098098"
		eyeTrailEmitter.Color = ColorSequence.new(PHANTOM_CONFIG.EYE_COLOR)
		eyeTrailEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0)
		})
		eyeTrailEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		eyeTrailEmitter.Lifetime = NumberRange.new(0.2, 0.4)
		eyeTrailEmitter.Rate = 8
		eyeTrailEmitter.Speed = NumberRange.new(0.5, 1)
		eyeTrailEmitter.Parent = eyeData.glow
	end

	-- ---------------------------------------------------------------------------
	-- ANIMATION STATE
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local npcRotation = zDir > 0 and 0 or math.pi
	local floatTime = 0
	local breathTime = 0
	local clothTime = 0
	local isAttacking = false
	local isPhasing = false
	local mouthOpen = 0

	-- ---------------------------------------------------------------------------
	-- UPDATE POSITION - Complete animation system
	-- ---------------------------------------------------------------------------

	local function UpdateNPCPosition(x, z, rotY, moving, deltaTime)
		npcX = x
		npcZ = z
		npcRotation = rotY or npcRotation

		if deltaTime then
			floatTime = floatTime + deltaTime * PHANTOM_CONFIG.FLOAT_SPEED
			breathTime = breathTime + deltaTime * PHANTOM_CONFIG.BREATH_SPEED
			clothTime = clothTime + deltaTime * PHANTOM_CONFIG.CLOTH_WAVE_SPEED
		end

		-- Calculate base motion
		local floatY = groundY + floatHeight + math.sin(floatTime * math.pi) * PHANTOM_CONFIG.FLOAT_AMPLITUDE
		local swayX = math.sin(floatTime * PHANTOM_CONFIG.SWAY_SPEED) * 0.15
		local swayZ = math.cos(floatTime * PHANTOM_CONFIG.SWAY_SPEED * 0.7) * 0.1
		local breathScale = 1 + math.sin(breathTime * math.pi * 2) * 0.03

		local basePos = Vector3.new(x + swayX, floatY, z + swayZ)
		local baseCFrame = CFrame.new(basePos) * CFrame.Angles(0, npcRotation, 0)

		-- Gentle body rotation
		local bodyTilt = math.sin(floatTime * 0.8) * math.rad(3)
		local bodySway = math.sin(floatTime * 0.6) * math.rad(2)
		baseCFrame = baseCFrame * CFrame.Angles(bodyTilt, 0, bodySway)

		-- Height references
		local torsoY = HEIGHT * 0.35
		local headY = HEIGHT * 0.65
		local shoulderY = HEIGHT * 0.5

		-- -----------------------------------------------------------------------
		-- SOUL CORE (Center)
		-- -----------------------------------------------------------------------

		local corePulse = 1 + math.sin(floatTime * 3) * 0.1
		soulCore.CFrame = baseCFrame * CFrame.new(0, torsoY, 0)
		soulCore.Size = Vector3.new(0.8 * corePulse, 1.2 * corePulse, 0.5 * corePulse)

		coreRing.CFrame = soulCore.CFrame * CFrame.Angles(0, floatTime, math.rad(90))
		coreRing.Size = Vector3.new(1.5 * corePulse, 1.5 * corePulse, 0.1)

		coreLight.Brightness = 1.5 + math.sin(floatTime * 4) * 0.5

		-- -----------------------------------------------------------------------
		-- TORSO LAYERS (Centered on core, no overlaps)
		-- -----------------------------------------------------------------------

		torsoOuter.CFrame = baseCFrame * CFrame.new(0, torsoY, 0)
		torsoMiddle.CFrame = baseCFrame * CFrame.new(0, torsoY, 0)
		torsoInner.CFrame = baseCFrame * CFrame.new(0, torsoY, 0)

		-- -----------------------------------------------------------------------
		-- SHOULDERS (Above and to sides of torso)
		-- -----------------------------------------------------------------------

		for _, shoulderData in ipairs(shoulders) do
			local shoulderFloat = math.sin(floatTime * 1.5 + shoulderData.side) * 0.05
			local shoulderX = shoulderData.side * 1.1

			shoulderData.main.CFrame = baseCFrame * CFrame.new(shoulderX, shoulderY + shoulderFloat, 0)
			shoulderData.wisp.CFrame = baseCFrame * CFrame.new(shoulderX * 1.15, shoulderY + 0.3 + shoulderFloat, 0.1)
				* CFrame.Angles(0, 0, shoulderData.side * math.rad(20))
		end

		-- -----------------------------------------------------------------------
		-- HOOD (Above shoulders)
		-- -----------------------------------------------------------------------

		local headBob = math.sin(floatTime * 1.3) * 0.06
		local headTilt = math.sin(floatTime * 0.9) * math.rad(3)

		hoodBack.CFrame = baseCFrame * CFrame.new(0, headY + headBob, 0.15)
			* CFrame.Angles(headTilt, 0, 0)

		hoodTop.CFrame = baseCFrame * CFrame.new(0, headY + 0.85 + headBob, -0.05)
			* CFrame.Angles(math.rad(-10) + headTilt, 0, 0)

		-- Hood rim
		local rimZ = -0.75
		hoodRimLeft.CFrame = baseCFrame * CFrame.new(-0.7, headY + headBob, rimZ)
		hoodRimRight.CFrame = baseCFrame * CFrame.new(0.7, headY + headBob, rimZ)

		-- -----------------------------------------------------------------------
		-- VOID FACE (Inside hood)
		-- -----------------------------------------------------------------------

		voidFace.CFrame = baseCFrame * CFrame.new(0, headY + headBob - 0.1, -0.5)
		voidDeep.CFrame = baseCFrame * CFrame.new(0, headY + headBob - 0.1, -0.35)

		-- -----------------------------------------------------------------------
		-- EYES (In front of void face)
		-- -----------------------------------------------------------------------

		for _, eyeData in ipairs(eyes) do
			local eyeX = eyeData.side * 0.32
			local eyeY = headY + 0.15 + headBob

			-- Subtle eye movement
			local lookX = math.sin(floatTime * 0.4) * 0.02
			local lookY = math.cos(floatTime * 0.5) * 0.015

			eyeData.socket.CFrame = baseCFrame * CFrame.new(eyeX, eyeY, -0.72)
			eyeData.glow.CFrame = baseCFrame * CFrame.new(eyeX + lookX, eyeY + lookY, -0.78)
			eyeData.inner.CFrame = baseCFrame * CFrame.new(eyeX + lookX, eyeY + lookY, -0.82)
			eyeData.trail.CFrame = baseCFrame * CFrame.new(eyeX, eyeY, -0.55)

			-- Eye flicker
			if eyeData.light then
				local flicker = eyeData.baseBrightness + math.sin(floatTime * 5 + eyeData.side * 2) * 0.5
				if math.random() < 0.015 then
					flicker = flicker + math.random() * 2
				end
				eyeData.light.Brightness = flicker
			end
		end

		-- -----------------------------------------------------------------------
		-- MOUTH (Below eyes)
		-- -----------------------------------------------------------------------

		local mouthY = headY - 0.35 + headBob
		local mouthScale = 1 + mouthOpen
		mouthVoid.CFrame = baseCFrame * CFrame.new(0, mouthY, -0.7)
		mouthVoid.Size = Vector3.new(0.5 * mouthScale, 0.3 * mouthScale, 0.15)
		mouthGlow.CFrame = baseCFrame * CFrame.new(0, mouthY, -0.68)
		mouthGlow.Transparency = 0.5 - mouthOpen * 0.3

		-- -----------------------------------------------------------------------
		-- ARMS (From shoulders, flowing down)
		-- -----------------------------------------------------------------------

		for _, armData in ipairs(arms) do
			local armTime = floatTime + armData.side * 0.7
			local armWave = math.sin(armTime) * 0.25
			local armFloat = math.cos(armTime * 0.8) * 0.1

			local shoulderPos = baseCFrame * CFrame.new(armData.side * 1.2, shoulderY, 0)

			-- Upper arm
			local upperAngle = math.rad(-20) + armWave * 0.4
			local upperOutward = armData.side * math.rad(35)
			local upperCFrame = shoulderPos
				* CFrame.Angles(upperAngle, upperOutward, armData.side * math.rad(15))
				* CFrame.new(0, -0.7, 0)

			armData.upper.CFrame = upperCFrame

			-- Elbow
			local elbowPos = upperCFrame * CFrame.new(0, -0.7, 0)
			armData.elbowWisp.CFrame = CFrame.new(elbowPos.Position)

			-- Lower arm
			local lowerAngle = math.rad(-40) + armWave * 0.3
			local lowerCFrame = elbowPos
				* CFrame.Angles(lowerAngle, 0, armData.side * math.rad(10))
				* CFrame.new(0, -0.6, 0)

			armData.lower.CFrame = lowerCFrame

			-- Wrist
			local wristPos = lowerCFrame * CFrame.new(0, -0.6, 0)
			armData.wristWisp.CFrame = CFrame.new(wristPos.Position)

			-- Hand
			local handWave = math.sin(armTime * 1.5) * math.rad(15)
			local handCFrame = wristPos
				* CFrame.Angles(handWave, 0, armData.side * math.rad(5))
				* CFrame.new(0, -0.25, 0)

			armData.hand.CFrame = handCFrame

			-- Fingers
			for f, finger in ipairs(armData.fingers) do
				local fingerAngle = (f - 2.5) * math.rad(12)
				local fingerWave = math.sin(armTime + f * 0.3) * math.rad(10)
				finger.CFrame = handCFrame
					* CFrame.new((f - 2.5) * 0.08, -0.35, 0)
					* CFrame.Angles(math.rad(20) + fingerWave, fingerAngle, 0)
			end
		end

		-- -----------------------------------------------------------------------
		-- TAIL SEGMENTS (Flowing down from torso)
		-- -----------------------------------------------------------------------

		local tailBaseY = torsoY - HEIGHT * 0.15
		for i, segData in ipairs(tailSegments) do
			local segOffset = (i - 1) * 0.35
			local segWave = math.sin(clothTime + i * 0.4) * 0.12 * i
			local segSway = math.cos(clothTime * 0.7 + i * 0.3) * 0.08 * i

			segData.part.CFrame = baseCFrame
				* CFrame.new(segWave, tailBaseY - segOffset, segSway)
				* CFrame.Angles(math.rad(i * 3), segWave * 0.5, 0)
		end

		-- Tail wisps
		local lastTailSeg = tailSegments[#tailSegments].part
		for _, wispData in ipairs(tailWisps) do
			local wispAngle = wispData.angle + clothTime * 0.3
			local wispX = math.cos(wispAngle) * 0.4
			local wispZ = math.sin(wispAngle) * 0.3
			local wispWave = math.sin(clothTime * 2 + wispData.angle) * 0.15

			wispData.part.CFrame = lastTailSeg.CFrame
				* CFrame.new(wispX + wispWave, -wispData.length * 0.5, wispZ)
				* CFrame.Angles(wispWave, wispAngle, 0)
		end

		-- -----------------------------------------------------------------------
		-- CHAINS (Floating around torso)
		-- -----------------------------------------------------------------------

		for i, chainData in ipairs(chains) do
			local chainRotate = floatTime * 0.3 + chainData.rotation
			local chainFloat = math.sin(floatTime * 1.2 + i) * 0.1

			chainData.ring.CFrame = baseCFrame
				* CFrame.new(0, torsoY + chainData.yOffset + chainFloat, 0)
				* CFrame.Angles(math.rad(90), chainRotate, math.sin(floatTime + i) * math.rad(10))

			-- Hanging link
			local linkAngle = math.sin(floatTime * 1.5 + i) * math.rad(20)
			chainData.link.CFrame = chainData.ring.CFrame
				* CFrame.new(1.0 - i * 0.15, 0, 0)
				* CFrame.Angles(0, 0, math.rad(90) + linkAngle)
		end
	end

	-- Initial position
	UpdateNPCPosition(npcX, npcZ, npcRotation, false, 0)

	-- ---------------------------------------------------------------------------
	-- SOUNDS
	-- ---------------------------------------------------------------------------

	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = "rbxassetid://9114221735"
	spawnSound.Volume = 1.0
	spawnSound.PlaybackSpeed = 0.5
	spawnSound.Parent = torsoInner
	spawnSound:Play()

	local whisperSound = Instance.new("Sound")
	whisperSound.SoundId = "rbxassetid://9114221580"
	whisperSound.Volume = 0.12
	whisperSound.Looped = true
	whisperSound.PlaybackSpeed = 0.35
	whisperSound.Parent = torsoInner
	whisperSound:Play()

	local chainSound = Instance.new("Sound")
	chainSound.SoundId = "rbxassetid://9114488653"
	chainSound.Volume = 0.08
	chainSound.Looped = true
	chainSound.PlaybackSpeed = 0.5
	chainSound.Parent = chains[1].ring
	chainSound:Play()

	-- ---------------------------------------------------------------------------
	-- TELEPORT ABILITY (Phase through reality)
	-- ---------------------------------------------------------------------------

	local lastTeleportTime = 0

	local function TeleportToPosition(newX, newZ)
		if IsInLobby(newX) then return false end
		isPhasing = true

		-- Disable particles
		auraEmitter.Enabled = false
		soulWisps.Enabled = false
		mistEmitter.Enabled = false

		-- Gather all parts
		local allParts = {}
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(allParts, {part = part, originalTrans = part.Transparency})
			end
		end

		-- Phase out effect
		for _, data in ipairs(allParts) do
			TweenService:Create(data.part, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Transparency = 1
			}):Play()
		end

		-- Soul collapse
		TweenService:Create(soulCore, TweenInfo.new(0.2), {
			Size = Vector3.new(0.1, 0.1, 0.1)
		}):Play()

		local teleportSound = Instance.new("Sound")
		teleportSound.SoundId = "rbxassetid://9114222045"
		teleportSound.Volume = 0.9
		teleportSound.PlaybackSpeed = 1.0
		teleportSound.Parent = torsoInner
		teleportSound:Play()

		task.wait(0.3)

		-- Update position
		npcX = newX
		npcZ = newZ

		-- Phase in effect
		TweenService:Create(soulCore, TweenInfo.new(0.2), {
			Size = Vector3.new(0.8, 1.2, 0.5)
		}):Play()

		for _, data in ipairs(allParts) do
			TweenService:Create(data.part, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
				Transparency = data.originalTrans
			}):Play()
		end

		-- Re-enable particles
		task.delay(0.25, function()
			auraEmitter.Enabled = true
			soulWisps.Enabled = true
			mistEmitter.Enabled = true
		end)

		Debris:AddItem(teleportSound, 2)
		isPhasing = false
		return true
	end

	-- ---------------------------------------------------------------------------
	-- ATTACK ANIMATION (Spectral wail)
	-- ---------------------------------------------------------------------------

	local function PlayAttackAnimation(targetPos)
		if isAttacking or isPhasing then return end
		isAttacking = true

		-- Open mouth for wail
		mouthOpen = 0.8

		-- Eyes intensify
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.15), {
					Brightness = 10,
					Range = 18
				}):Play()
			end
			TweenService:Create(eyeData.glow, TweenInfo.new(0.15), {
				Color = PHANTOM_CONFIG.EYE_INNER,
				Size = Vector3.new(0.45, 0.4, 0.15)
			}):Play()
		end

		-- Core flares
		TweenService:Create(coreLight, TweenInfo.new(0.15), {
			Brightness = 5,
			Range = 30
		}):Play()
		TweenService:Create(soulCore, TweenInfo.new(0.15), {
			Size = Vector3.new(1.2, 1.6, 0.7)
		}):Play()

		-- Hands glow brighter
		for _, armData in ipairs(arms) do
			TweenService:Create(armData.hand, TweenInfo.new(0.15), {
				Color = PHANTOM_CONFIG.GLOW_INTENSE,
				Transparency = 0.1
			}):Play()
			if armData.handGlow then
				TweenService:Create(armData.handGlow, TweenInfo.new(0.15), {
					Brightness = 4,
					Range = 12
				}):Play()
			end
		end

		-- Wail sound
		local wailSound = Instance.new("Sound")
		wailSound.SoundId = "rbxassetid://9114221890"
		wailSound.Volume = 0.9
		wailSound.PlaybackSpeed = 0.6
		wailSound.Parent = torsoInner
		wailSound:Play()

		-- Shockwave effect
		local shockwave = CreatePart(
			"Shockwave",
			Vector3.new(2, 2, 0.1),
			PHANTOM_CONFIG.GLOW_PRIMARY,
			Enum.Material.Neon,
			0.5,
			workspace
		)
		shockwave.CFrame = CFrame.new(npcX, groundY + floatHeight, npcZ) * CFrame.Angles(math.rad(90), 0, 0)

		TweenService:Create(shockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Size = Vector3.new(20, 20, 0.1),
			Transparency = 1
		}):Play()

		Debris:AddItem(shockwave, 0.6)

		task.wait(0.5)

		-- Reset
		mouthOpen = 0

		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.3), {
					Brightness = eyeData.baseBrightness,
					Range = 10
				}):Play()
			end
			TweenService: Create(eyeData.glow, TweenInfo.new(0.3), {
				Color = PHANTOM_CONFIG.EYE_COLOR,
				Size = Vector3.new(0.32, 0.28, 0.12)
			}):Play()
		end

		TweenService:Create(coreLight, TweenInfo.new(0.3), {
			Brightness = 2,
			Range = 18
		}):Play()
		TweenService:Create(soulCore, TweenInfo.new(0.3), {
			Size = Vector3.new(0.8, 1.2, 0.5)
		}):Play()

		for _, armData in ipairs(arms) do
			TweenService:Create(armData.hand, TweenInfo.new(0.3), {
				Color = PHANTOM_CONFIG.GLOW_PRIMARY,
				Transparency = 0.35
			}):Play()
			if armData.handGlow then
				TweenService:Create(armData.handGlow, TweenInfo.new(0.3), {
					Brightness = 1.5,
					Range = 6
				}):Play()
			end
		end

		Debris:AddItem(wailSound, 3)
		isAttacking = false
	end

	-- ---------------------------------------------------------------------------
	-- DEATH EFFECT (Soul dispersal)
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		auraEmitter.Enabled = false
		soulWisps.Enabled = false
		mistEmitter.Enabled = false
		whisperSound:Stop()
		chainSound:Stop()

		-- Death wail
		local deathSound = Instance.new("Sound")
		deathSound.SoundId = "rbxassetid://9114221580"
		deathSound.Volume = 1.5
		deathSound.PlaybackSpeed = 0.25
		deathSound.Parent = torsoInner
		deathSound:Play()

		-- Eyes fade
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.4), {
					Brightness = 0
				}):Play()
			end
		end

		-- Chain scatter
		for _, chainData in ipairs(chains) do
			local randomDir = Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5).Unit * 5
			TweenService:Create(chainData.ring, TweenInfo.new(0.5), {
				Position = chainData.ring.Position + randomDir,
				Transparency = 1
			}):Play()
			TweenService:Create(chainData.link, TweenInfo.new(0.5), {
				Transparency = 1
			}):Play()
		end

		-- Soul implodes then explodes
		TweenService:Create(soulCore, TweenInfo.new(0.3), {
			Size = Vector3.new(0.2, 0.2, 0.2)
		}):Play()

		task.wait(0.35)

		-- Soul burst
		local soulBurst = CreatePart(
			"SoulBurst",
			Vector3.new(1, 1, 1),
			PHANTOM_CONFIG.GLOW_INTENSE,
			Enum.Material.Neon,
			0.3,
			workspace
		)
		soulBurst.Shape = Enum.PartType.Ball
		soulBurst.Position = soulCore.Position

		local burstLight = CreateGlow(soulBurst, PHANTOM_CONFIG.GLOW_INTENSE, 8, 35, false)

		TweenService:Create(soulBurst, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
			Size = Vector3.new(18, 18, 18),
			Transparency = 1
		}):Play()

		TweenService:Create(burstLight, TweenInfo.new(0.5), {
			Brightness = 0
		}):Play()

		-- All parts fade
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.4), {
					Transparency = 1,
					Size = part.Size * 0.5
				}):Play()
			end
		end

		Debris:AddItem(soulBurst, 0.6)
		task.wait(0.5)
		Debris:AddItem(deathSound, 3)
	end

	-- ---------------------------------------------------------------------------
	-- AI BEHAVIOR LOOP
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0

	local function FindNearestPlayer()
		local nearest, nearestDist = nil, PHANTOM_CONFIG.  DETECTION_RANGE
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local dist = (hrp. Position - Vector3.new(npcX, 0, npcZ)).Magnitude
					if dist < nearestDist and not IsInLobby(hrp.  Position.  X) then
						nearestDist = dist
						nearest = player
					end
				end
			end
		end
		return nearest, nearestDist
	end

	local function AttackPlayer(player)
		if tick() - lastAttackTime < PHANTOM_CONFIG.  ATTACK_COOLDOWN then return end
		if isAttacking or isPhasing then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:  FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			coroutine.wrap(function()
				PlayAttackAnimation(hrp.  Position)
			end)()

			task.wait(0.35)

			local dist = (hrp. Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < PHANTOM_CONFIG.  ATTACK_RANGE + 2 and hum.Health > 0 then
				hum:  TakeDamage(PHANTOM_CONFIG. DAMAGE)

				-- Chill/freeze effect
				local originalSpeed = hum.WalkSpeed
				hum.WalkSpeed = originalSpeed * 0.25

				-- Ice visual effect
				local freezeEffect = CreatePart(
					"FreezeEffect",
					Vector3.new(3.5, 3.5, 3.5),
					PHANTOM_CONFIG.GLOW_SECONDARY,
					Enum.Material.Ice,
					0.5,
					workspace
				)
				freezeEffect.Shape = Enum. PartType.Ball
				freezeEffect. Position = hrp.Position

				TweenService:Create(freezeEffect, TweenInfo.new(1.2), {
					Transparency = 1,
					Size = Vector3.new(6, 6, 6)
				}):Play()

				Debris:AddItem(freezeEffect, 1.3)

				-- Restore speed
				task.delay(2, function()
					if hum and hum.Parent then
						hum.WalkSpeed = originalSpeed
					end
				end)
			end
		end
	end

	-- Main loop
	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		-- PHANTOM usa "torsoInner" como parte principal, NO "thorax"
		if not isAlive or not torsoInner or not torsoInner. Parent then
			if chaseConnection then chaseConnection: Disconnect() end
			return
		end

		-- -----------------------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------??-----------------------------
		if npcModel:  GetAttribute("Stunned") then
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
			return
		end
		-- -----------------------------------------------------------------------

		if isPhasing then
			return
		end

		if IsInLobby(npcX) then
			isAlive = false
			if chaseConnection then chaseConnection:Disconnect() end
			PlayDeathEffect()
			task.wait(0.8)
			if npcFolder and npcFolder.Parent then
				npcFolder:Destroy()
			end
			return
		end

		local target, distance = FindNearestPlayer()

		if target then
			local char = target.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local targetPos = hrp.Position
					local direction = Vector3.new(targetPos.X - npcX, 0, targetPos.Z - npcZ)

					-- Teleport if far
					if distance > 20 and tick() - lastTeleportTime > PHANTOM_CONFIG.  TELEPORT_COOLDOWN then
						local teleportX = targetPos.X + (math.random() - 0.5) * 10
						local teleportZ = targetPos. Z + (math. random() - 0.5) * 10

						if not IsInLobby(teleportX) then
							lastTeleportTime = tick()
							TeleportToPosition(teleportX, teleportZ)
						end
					end

					if direction.Magnitude > 0.5 then
						local lookAngle = math.  atan2(-direction.X, -direction.Z)

						if distance > PHANTOM_CONFIG. ATTACK_RANGE then
							local moveDir = direction.Unit
							local newX = npcX + moveDir.X * PHANTOM_CONFIG.  SPEED * dt
							local newZ = npcZ + moveDir.Z * PHANTOM_CONFIG. SPEED * dt

							if not IsInLobby(newX) then
								UpdateNPCPosition(newX, newZ, lookAngle, true, dt)
							else
								UpdateNPCPosition(npcX, npcZ, lookAngle, false, dt)
							end
						else
							UpdateNPCPosition(npcX, npcZ, lookAngle, false, dt)
							AttackPlayer(target)
						end
					else
						UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
					end
				else
					UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
				end
			else
				UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
			end
		else
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
		end
	end)

	-- Random whisper sounds
	coroutine.wrap(function()
		while isAlive and torsoInner and torsoInner.Parent do
			task.wait(math.random(6, 14))
			if isAlive and torsoInner and torsoInner.Parent and not isAttacking then
				local whisper = Instance.new("Sound")
				whisper.SoundId = "rbxassetid://9114222045"
				whisper.Volume = 0.25
				whisper.PlaybackSpeed = 0.3 + math.random() * 0.3
				whisper.Parent = torsoInner
				whisper: Play()
				Debris:AddItem(whisper, 4)
			end
		end
	end)()

	-- Random eye flicker effect
	coroutine.wrap(function()
		while isAlive and #eyes > 0 do
			task.wait(math.random(4, 8))
			if isAlive and not isAttacking and not isPhasing then
				-- Both eyes flicker together
				for _, eyeData in ipairs(eyes) do
					if eyeData.glow and eyeData.glow.Parent then
						local originalTrans = eyeData.glow.Transparency
						eyeData.glow.Transparency = 0.7
						task.wait(0.05)
						if eyeData.glow and eyeData.glow.Parent then
							eyeData.glow.Transparency = originalTrans
						end
					end
				end
			end
		end
	end)()

	-- Chain rattle sound
	coroutine.wrap(function()
		while isAlive and #chains > 0 do
			task.wait(math.random(8, 16))
			if isAlive and chains[1].ring and chains[1].ring.Parent then
				local rattleSound = Instance.new("Sound")
				rattleSound.SoundId = "rbxassetid://9114488653"
				rattleSound.Volume = 0.15
				rattleSound.PlaybackSpeed = 0.8 + math.random() * 0.4
				rattleSound.Parent = chains[1].ring
				rattleSound:Play()
				Debris:AddItem(rattleSound, 3)
			end
		end
	end)()

	-- Lifetime
	coroutine.wrap(function()
		task.wait(PHANTOM_CONFIG.LIFETIME)
		if npcFolder and npcFolder.Parent and isAlive then
			isAlive = false
			PlayDeathEffect()
			task.wait(0.8)
			if npcFolder then npcFolder:Destroy() end
		end
	end)()

	-- Cleanup on destroy
	npcFolder.AncestryChanged:Connect(function()
		if not npcFolder.Parent then
			isAlive = false
			whisperSound:Stop()
			chainSound:Stop()
			if chaseConnection then chaseConnection: Disconnect() end
		end
	end)

	return npcFolder
end

-- -------------------------------------------------------------------------------
-- EVENT LISTENER
-- -------------------------------------------------------------------------------

if SpawnPhantomEvent then
	SpawnPhantomEvent.Event:Connect(function(position, player, side, zDir)
		task.wait(0.4)
		CreatePhantomNPC(position, player, side, zDir)
	end)
end

print("=== NPC PHANTOM SYSTEM V3 - Enhanced Ethereal Specter Ready ===")