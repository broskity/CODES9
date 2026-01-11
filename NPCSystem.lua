--[[
    +-??----------------------------------------------------------------------------+
    ¦                         NPC SHADOW ENTITY SYSTEM                              ¦
    ¦                    VERSIÓN 3 - ENHANCED DARK WRAITH                           ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnNPCEvent = ReplicatedStorage:WaitForChild("SpawnNPCEvent", 10)

-- -------------------------------------------------------------------------------
-- CONFIGURACIÓN DEL SHADOW
-- -------------------------------------------------------------------------------
local SHADOW_CONFIG = {
	SPEED = 18,
	DAMAGE = 20,
	ATTACK_COOLDOWN = 0.8,
	ATTACK_RANGE = 5,
	DETECTION_RANGE = 200,
	LIFETIME = 45,

	-- APPEARANCE - Dark ethereal colors
	BODY_PRIMARY = Color3.fromRGB(5, 5, 10),
	BODY_SECONDARY = Color3.fromRGB(10, 10, 18),
	BODY_ACCENT = Color3.fromRGB(15, 15, 25),
	BODY_HIGHLIGHT = Color3.fromRGB(25, 25, 40),
	VOID_COLOR = Color3.fromRGB(0, 0, 3),
	EYE_COLOR = Color3.fromRGB(255, 255, 255),
	EYE_GLOW = Color3.fromRGB(220, 230, 255),
	EYE_ATTACK = Color3.fromRGB(255, 80, 80),
	CLAW_COLOR = Color3.fromRGB(20, 20, 30),
	CLAW_TIP = Color3.fromRGB(40, 35, 50),
	WISP_COLOR = Color3.fromRGB(30, 30, 50),
	AURA_COLOR = Color3.fromRGB(5, 5, 15),

	-- DIMENSIONS - Slender humanoid
	TOTAL_HEIGHT = 6.5,
	TORSO_SIZE = Vector3.new(1.8, 2.4, 0.9),
	CHEST_SIZE = Vector3.new(2.0, 1.4, 1.0),
	ABDOMEN_SIZE = Vector3.new(1.5, 1.0, 0.8),
	HEAD_SIZE = Vector3.new(1.4, 1.6, 1.3),
	NECK_SIZE = Vector3.new(0.5, 0.6, 0.5),

	-- ARM DIMENSIONS
	SHOULDER_SIZE = Vector3.new(0.6, 0.5, 0.5),
	UPPER_ARM_SIZE = Vector3.new(0.4, 1.8, 0.4),
	LOWER_ARM_SIZE = Vector3.new(0.35, 1.6, 0.35),
	HAND_SIZE = Vector3.new(0.5, 0.7, 0.2),
	CLAW_LENGTH = 0.5,

	-- LEG DIMENSIONS
	HIP_SIZE = Vector3.new(0.5, 0.4, 0.5),
	UPPER_LEG_SIZE = Vector3.new(0.5, 1.8, 0.5),
	LOWER_LEG_SIZE = Vector3.new(0.4, 1.6, 0.4),
	FOOT_SIZE = Vector3.new(0.5, 0.25, 0.8),

	-- ANIMATION
	WALK_SPEED = 8,
	LEG_SWING = 35,
	ARM_SWING = 25,
	BREATH_SPEED = 1.2,
	FLICKER_CHANCE = 0.03,

	-- ATTACK TIMINGS
	ATTACK_WINDUP = 0.15,
	ATTACK_SWING = 0.1,
	ATTACK_RECOVERY = 0.2,

	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

local function IsInLobby(x)
	return x >= SHADOW_CONFIG.LOBBY_START_X and x <= SHADOW_CONFIG.LOBBY_END_X
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
	part.CastShadow = true
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
-- CREATE SHADOW NPC
-- -------------------------------------------------------------------------------

local function CreateShadowNPC(spawnPosition, triggerPlayer, side, zDir)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "ShadowEntity"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "ShadowNPC"
	npcModel.Parent = npcFolder

	local groundY = 0.5
	local HEIGHT = SHADOW_CONFIG.TOTAL_HEIGHT

	-- ---------------------------------------------------------------------------
	-- PELVIS (Base connection)
	-- ---------------------------------------------------------------------------

	local pelvis = CreatePart(
		"Pelvis",
		Vector3.new(1.4, 0.8, 0.8),
		SHADOW_CONFIG.BODY_PRIMARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(pelvis, Enum.MeshType.Sphere, Vector3.new(1, 0.7, 0.9))

	-- ---------------------------------------------------------------------------
	-- ABDOMEN (Lower torso)
	-- ---------------------------------------------------------------------------

	local abdomen = CreatePart(
		"Abdomen",
		SHADOW_CONFIG.ABDOMEN_SIZE,
		SHADOW_CONFIG.BODY_SECONDARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(abdomen, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 0.9))

	-- ---------------------------------------------------------------------------
	-- CHEST (Upper torso)
	-- ---------------------------------------------------------------------------

	local chest = CreatePart(
		"Chest",
		SHADOW_CONFIG.CHEST_SIZE,
		SHADOW_CONFIG.BODY_PRIMARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	chest.CanCollide = true
	CreateMesh(chest, Enum.MeshType.Sphere, Vector3.new(1, 1.1, 0.85))

	-- Chest void core (darker center)
	local chestCore = CreatePart(
		"ChestCore",
		Vector3.new(0.8, 0.6, 0.3),
		SHADOW_CONFIG.VOID_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(chestCore, Enum.MeshType.Sphere)

	-- Shoulder ridge details
	local shoulderRidges = {}
	for i = 1, 2 do
		local ridgeSide = i == 1 and -1 or 1
		local ridge = CreatePart(
			"ShoulderRidge" ..i,
			Vector3.new(0.3, 0.15, 0.6),
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(ridge, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1))
		table.insert(shoulderRidges, {part = ridge, side = ridgeSide})
	end

	-- ---------------------------------------------------------------------------
	-- NECK
	-- ---------------------------------------------------------------------------

	local neck = CreatePart(
		"Neck",
		SHADOW_CONFIG.NECK_SIZE,
		SHADOW_CONFIG.BODY_SECONDARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(neck, Enum.MeshType.Cylinder)

	-- ---------------------------------------------------------------------------
	-- HEAD (Smooth featureless with glowing eyes)
	-- ---------------------------------------------------------------------------

	local headMain = CreatePart(
		"HeadMain",
		SHADOW_CONFIG.HEAD_SIZE,
		SHADOW_CONFIG.BODY_PRIMARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(headMain, Enum.MeshType.Sphere, Vector3.new(1, 1.1, 1))

	-- Face void (darker face area)
	local faceVoid = CreatePart(
		"FaceVoid",
		Vector3.new(1.0, 0.9, 0.4),
		SHADOW_CONFIG.VOID_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(faceVoid, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.5))

	-- Head wisps (ethereal tendrils from head)
	local headWisps = {}
	for i = 1, 4 do
		local wisp = CreatePart(
			"HeadWisp" ..i,
			Vector3.new(0.1, 0.6 + math.random() * 0.3, 0.1),
			SHADOW_CONFIG.WISP_COLOR,
			Enum.Material.SmoothPlastic,
			0.3,
			npcModel
		)
		CreateMesh(wisp, Enum.MeshType.Sphere, Vector3.new(1, 3, 1))
		table.insert(headWisps, {
			part = wisp,
			angle = (i / 4) * math.pi * 2,
			length = 0.6 + math.random() * 0.3
		})
	end

	-- ---------------------------------------------------------------------------
	-- EYES (Piercing white eyes)
	-- ---------------------------------------------------------------------------

	local eyes = {}
	for i = 1, 2 do
		local eyeSide = i == 1 and -1 or 1

		-- Eye socket (slight recess)
		local eyeSocket = CreatePart(
			"EyeSocket" ..i,
			Vector3.new(0.32, 0.28, 0.15),
			SHADOW_CONFIG.VOID_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(eyeSocket, Enum.MeshType.Sphere)

		-- Eye glow (main)
		local eyeGlow = CreatePart(
			"EyeGlow" ..i,
			Vector3.new(0.22, 0.4, 0.1),
			SHADOW_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeGlow, Enum.MeshType.Sphere)

		-- Eye inner (brighter center)
		local eyeInner = CreatePart(
			"EyeInner" ..i,
			Vector3.new(0.1, 0.2, 0.05),
			SHADOW_CONFIG.EYE_GLOW,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeInner, Enum.MeshType.Sphere)

		local eyeLight = CreateGlow(eyeGlow, SHADOW_CONFIG.EYE_COLOR, 3, 10, true)

		-- Eye trail (subtle wisp behind eye)
		local eyeTrail = CreatePart(
			"EyeTrail" ..i,
			Vector3.new(0.12, 0.2, 0.25),
			SHADOW_CONFIG.EYE_GLOW,
			Enum.Material.Neon,
			0.5,
			npcModel
		)
		CreateMesh(eyeTrail, Enum.MeshType.Sphere, Vector3.new(1, 1, 2))

		table.insert(eyes, {
			socket = eyeSocket,
			glow = eyeGlow,
			inner = eyeInner,
			trail = eyeTrail,
			light = eyeLight,
			side = eyeSide,
			baseBrightness = 3
		})
	end

	-- ----------------??----------------------------------------------------------
	-- SHOULDERS
	-- ----------------------------------??----------------------------------------

	local shoulders = {}
	for i = 1, 2 do
		local shoulderSide = i == 1 and -1 or 1

		local shoulderMain = CreatePart(
			"ShoulderMain" ..i,
			SHADOW_CONFIG.SHOULDER_SIZE,
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(shoulderMain, Enum.MeshType.Sphere)

		table.insert(shoulders, {
			main = shoulderMain,
			side = shoulderSide
		})
	end

	-- ---------------------------------------------------------------------------
	-- ARMS (Slender with clawed hands)
	-- ---------------------------------------------------------------------------

	local arms = {}
	for i = 1, 2 do
		local armSide = i == 1 and -1 or 1

		-- Upper arm
		local upperArm = CreatePart(
			"UpperArm" ..i,
			SHADOW_CONFIG.UPPER_ARM_SIZE,
			SHADOW_CONFIG.BODY_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(upperArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Elbow
		local elbow = CreatePart(
			"Elbow" ..i,
			Vector3.new(0.3, 0.3, 0.3),
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(elbow, Enum.MeshType.Sphere)

		-- Lower arm
		local lowerArm = CreatePart(
			"LowerArm" ..i,
			SHADOW_CONFIG.LOWER_ARM_SIZE,
			SHADOW_CONFIG.BODY_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(lowerArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Wrist
		local wrist = CreatePart(
			"Wrist" ..i,
			Vector3.new(0.25, 0.2, 0.25),
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(wrist, Enum.MeshType.Sphere)

		-- Hand
		local hand = CreatePart(
			"Hand" ..i,
			SHADOW_CONFIG.HAND_SIZE,
			SHADOW_CONFIG.BODY_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(hand, Enum.MeshType.Sphere, Vector3.new(1, 1.3, 0.5))

		-- Claws (4 per hand)
		local claws = {}
		for c = 1, 4 do
			-- Finger
			local finger = CreatePart(
				"Finger" ..i .."_" ..c,
				Vector3.new(0.08, 0.35, 0.08),
				SHADOW_CONFIG.BODY_SECONDARY,
				Enum.Material.SmoothPlastic,
				0,
				npcModel
			)
			CreateMesh(finger, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

			-- Claw
			local claw = CreatePart(
				"Claw" ..i .."_" ..c,
				Vector3.new(0.06, SHADOW_CONFIG.CLAW_LENGTH, 0.06),
				SHADOW_CONFIG.CLAW_COLOR,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(claw, Enum.MeshType.Sphere, Vector3.new(1, 2.5, 1))

			-- Claw tip
			local clawTip = CreatePart(
				"ClawTip" ..i .."_" ..c,
				Vector3.new(0.04, 0.15, 0.04),
				SHADOW_CONFIG.CLAW_TIP,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(clawTip, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

			table.insert(claws, {
				finger = finger,
				claw = claw,
				tip = clawTip,
				index = c
			})
		end

		table.insert(arms, {
			upper = upperArm,
			elbow = elbow,
			lower = lowerArm,
			wrist = wrist,
			hand = hand,
			claws = claws,
			side = armSide,
			attackAngle = 0
		})
	end

	-- ---------------------------------------------------------------------------
	-- LEGS (Slender digitigrade-style)
	-- ------------------------------------------???--------------------------------

	local legs = {}
	for i = 1, 2 do
		local legSide = i == 1 and -1 or 1

		-- Hip
		local hip = CreatePart(
			"Hip" ..i,
			SHADOW_CONFIG.HIP_SIZE,
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(hip, Enum.MeshType.Sphere)

		-- Upper leg
		local upperLeg = CreatePart(
			"UpperLeg" ..i,
			SHADOW_CONFIG.UPPER_LEG_SIZE,
			SHADOW_CONFIG.BODY_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(upperLeg, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Knee
		local knee = CreatePart(
			"Knee" ..i,
			Vector3.new(0.35, 0.35, 0.35),
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(knee, Enum.MeshType.Sphere)

		-- Lower leg
		local lowerLeg = CreatePart(
			"LowerLeg" ..i,
			SHADOW_CONFIG.LOWER_LEG_SIZE,
			SHADOW_CONFIG.BODY_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(lowerLeg, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Ankle
		local ankle = CreatePart(
			"Ankle" ..i,
			Vector3.new(0.28, 0.22, 0.28),
			SHADOW_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(ankle, Enum.MeshType.Sphere)

		-- Foot
		local foot = CreatePart(
			"Foot" ..i,
			SHADOW_CONFIG.FOOT_SIZE,
			SHADOW_CONFIG.BODY_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(foot, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1.5))

		-- Toe claws
		local toeClaws = {}
		for t = 1, 3 do
			local toeClaw = CreatePart(
				"ToeClaw" ..i .."_" ..t,
				Vector3.new(0.05, 0.25, 0.05),
				SHADOW_CONFIG.CLAW_COLOR,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(toeClaw, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))
			table.insert(toeClaws, toeClaw)
		end

		table.insert(legs, {
			hip = hip,
			upper = upperLeg,
			knee = knee,
			lower = lowerLeg,
			ankle = ankle,
			foot = foot,
			toeClaws = toeClaws,
			side = legSide
		})
	end

	-- ---------------------------------------------------------------------------
	-- SHADOW WISPS (Ethereal tendrils from body)
	-- ---------------------??-----------------------------------------------------

	local bodyWisps = {}
	local wispPositions = {
		{yOffset = 0, zOffset = 0.5, length = 0.8},
		{yOffset = -0.3, zOffset = 0.4, length = 0.6},
		{yOffset = 0.2, zOffset = 0.45, length = 0.7},
	}

	for i, wispData in ipairs(wispPositions) do
		local wisp = CreatePart(
			"BodyWisp" ..i,
			Vector3.new(0.15, wispData.length, 0.15),
			SHADOW_CONFIG.WISP_COLOR,
			Enum.Material.SmoothPlastic,
			0.4,
			npcModel
		)
		CreateMesh(wisp, Enum.MeshType.Sphere, Vector3.new(1, 3, 1))

		table.insert(bodyWisps, {
			part = wisp,
			yOffset = wispData.yOffset,
			zOffset = wispData.zOffset,
			length = wispData.length
		})
	end

	-- ---------------------------------------------------------------------------
	-- PARTICLE EFFECTS
	-- ---------------------------------------------------------------------------

	-- Shadow aura
	local shadowAura = Instance.new("ParticleEmitter")
	shadowAura.Texture = "rbxassetid://243098098"
	shadowAura.Color = ColorSequence.new(SHADOW_CONFIG.AURA_COLOR)
	shadowAura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 2.5)
	})
	shadowAura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	shadowAura.Lifetime = NumberRange.new(0.4, 0.8)
	shadowAura.Rate = 12
	shadowAura.Speed = NumberRange.new(0.5, 1.5)
	shadowAura.SpreadAngle = Vector2.new(360, 360)
	shadowAura.RotSpeed = NumberRange.new(-20, 20)
	shadowAura.Parent = chest

	-- Ground shadow effect
	local groundShadow = Instance.new("ParticleEmitter")
	groundShadow.Texture = "rbxassetid://243098098"
	groundShadow.Color = ColorSequence.new(Color3.new(0, 0, 0))
	groundShadow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 2)
	})
	groundShadow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	groundShadow.Lifetime = NumberRange.new(0.3, 0.5)
	groundShadow.Rate = 8
	groundShadow.Speed = NumberRange.new(0.1, 0.3)
	groundShadow.SpreadAngle = Vector2.new(180, 0)
	groundShadow.EmissionDirection = Enum.NormalId.Bottom
	groundShadow.Parent = pelvis

	-- Eye trail particles
	for _, eyeData in ipairs(eyes) do
		local eyeTrailEmitter = Instance.new("ParticleEmitter")
		eyeTrailEmitter.Texture = "rbxassetid://243098098"
		eyeTrailEmitter.Color = ColorSequence.new(SHADOW_CONFIG.EYE_GLOW)
		eyeTrailEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 0)
		})
		eyeTrailEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		eyeTrailEmitter.Lifetime = NumberRange.new(0.15, 0.3)
		eyeTrailEmitter.Rate = 10
		eyeTrailEmitter.Speed = NumberRange.new(0.3, 0.8)
		eyeTrailEmitter.Parent = eyeData.glow
	end

	-- ---------------------------------------------------------------------------
	-- ANIMATION STATE
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local npcRotation = zDir > 0 and 0 or math.pi
	local walkTime = 0
	local breathTime = 0
	local wispTime = 0
	local isWalking = false

	-- Attack state
	local isAttacking = false
	local attackPhase = "none"
	local attackingArm = "right"
	local bodyLean = 0
	local headTilt = 0

	-- Flicker state
	local flickerAlpha = 1

	-- ---------------------------------------------------------------------------
	-- UPDATE POSITION - Complete animation system
	-- ---------------------------------------------------------------------------

	local function UpdateNPCPosition(x, z, rotY, walking, deltaTime)
		npcX = x
		npcZ = z
		npcRotation = rotY or npcRotation
		isWalking = walking or false

		if deltaTime then
			if isWalking then
				walkTime = walkTime + deltaTime * SHADOW_CONFIG.WALK_SPEED
			end
			breathTime = breathTime + deltaTime * SHADOW_CONFIG.BREATH_SPEED
			wispTime = wispTime + deltaTime * 2

			-- Random flicker
			if math.random() < SHADOW_CONFIG.FLICKER_CHANCE then
				flickerAlpha = 0.3 + math.random() * 0.4
			else
				flickerAlpha = flickerAlpha + (1 - flickerAlpha) * 0.15
			end
		end

		-- Base calculations
		local breathScale = 1 + math.sin(breathTime * math.pi * 2) * 0.015
		local walkBob = isWalking and math.sin(walkTime * 2) * 0.08 or 0
		local walkSway = isWalking and math.sin(walkTime) * 0.02 or 0

		-- Height references
		local legHeight = SHADOW_CONFIG.UPPER_LEG_SIZE.Y + SHADOW_CONFIG.LOWER_LEG_SIZE.Y * 0.7
		local baseY = groundY + legHeight
		local pelvisY = baseY
		local abdomenY = pelvisY + 0.7
		local chestY = abdomenY + 1.0
		local neckY = chestY + 0.9
		local headY = neckY + 1.0

		local baseCFrame = CFrame.new(x, 0, z) 
			* CFrame.Angles(walkSway + bodyLean, npcRotation, walkSway * 0.5)

		-- Apply flicker transparency
		local flickerTrans = (1 - flickerAlpha) * 0.3

		-- -----------------------------------------------------------------------
		-- PELVIS
		-- -----------------------------------------------------------------------

		pelvis.CFrame = baseCFrame * CFrame.new(0, pelvisY + walkBob, 0)
		pelvis.Transparency = flickerTrans

		-- -----------------------------------------------------------------------
		-- ABDOMEN
		-- -----------------------------------------------------------------------

		abdomen.CFrame = baseCFrame * CFrame.new(0, abdomenY + walkBob, 0)
		abdomen.Transparency = flickerTrans

		-- -----------------------------------------------------------------------
		-- CHEST
		-- -----------------------------------------------------------------------

		chest.CFrame = baseCFrame * CFrame.new(0, chestY + walkBob, 0)
		chest.Size = SHADOW_CONFIG.CHEST_SIZE * Vector3.new(breathScale, 1, breathScale)
		chest.Transparency = flickerTrans

		chestCore.CFrame = baseCFrame * CFrame.new(0, chestY + walkBob, -0.3)

		-- Shoulder ridges
		for _, ridgeData in ipairs(shoulderRidges) do
			local ridgeX = ridgeData.side * 0.85
			ridgeData.part.CFrame = baseCFrame * CFrame.new(ridgeX, chestY + 0.5 + walkBob, 0)
		end

		-- -----------------------------------------------------------------------
		-- NECK
		-- -----------------------------------------------------------------------

		local neckTilt = headTilt * 0.5
		neck.CFrame = baseCFrame * CFrame.new(0, neckY + walkBob, 0)
			* CFrame.Angles(math.rad(90) + neckTilt, 0, 0)

		-- -----------------------------------------------------------------------
		-- HEAD
		-- -----------------------------------------------------------------------

		local headBob = math.sin(walkTime * 0.8) * 0.04
		local headCFrame = baseCFrame * CFrame.new(0, headY + walkBob + headBob, 0)
			* CFrame.Angles(headTilt, 0, 0)

		headMain.CFrame = headCFrame
		headMain.Transparency = flickerTrans

		faceVoid.CFrame = headCFrame * CFrame.new(0, -0.1, -0.55)

		-- Head wisps
		for _, wispData in ipairs(headWisps) do
			local wispAngle = wispData.angle + wispTime * 0.5
			local wispX = math.cos(wispAngle) * 0.5
			local wispZ = math.sin(wispAngle) * 0.4
			local wispWave = math.sin(wispTime * 2 + wispData.angle) * 0.1

			wispData.part.CFrame = headCFrame
				* CFrame.new(wispX + wispWave, 0.6, wispZ)
				* CFrame.Angles(wispWave, wispAngle, 0)
		end

		-- -----------------------------------------------------------------------
		-- EYES
		-- -----------------------------------------------------------------------

		for _, eyeData in ipairs(eyes) do
			local eyeX = eyeData.side * 0.3
			local eyeY = 0.15

			eyeData.socket.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -0.62)
			eyeData.glow.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -0.68)
			eyeData.inner.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -0.72)
			eyeData.trail.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -0.5)

			-- Eye flicker
			if eyeData.light then
				local flicker = eyeData.baseBrightness * flickerAlpha
				if math.random() < 0.02 then
					flicker = flicker + math.random() * 2
				end
				eyeData.light.Brightness = flicker
			end
		end

		-- -----------------------------------------------------------------------
		-- SHOULDERS
		-- -----------------------------------------------------------------------

		local shoulderY = chestY + 0.4
		for _, shoulderData in ipairs(shoulders) do
			local shoulderX = shoulderData.side * 1.1
			shoulderData.main.CFrame = baseCFrame * CFrame.new(shoulderX, shoulderY + walkBob, 0)
		end

		-- -----------------------------------------------------------------------
		-- ARMS
		-- -----------------------------------------------------------------------

		for _, armData in ipairs(arms) do
			local armSwing = isWalking and math.sin(walkTime + (armData.side == 1 and 0 or math.pi)) * math.rad(SHADOW_CONFIG.ARM_SWING) or 0

			-- Apply attack angle
			local attackAngle = 0
			if isAttacking and ((attackingArm == "right" and armData.side == 1) or (attackingArm == "left" and armData.side == -1)) then
				attackAngle = armData.attackAngle
			end

			local shoulderX = armData.side * 1.1

			-- Shoulder position
			local shoulderPos = baseCFrame * CFrame.new(shoulderX, shoulderY + walkBob, 0)

			-- Upper arm
			local upperAngle = math.rad(10) + armSwing + attackAngle * 0.4
			local upperOutward = armData.side * math.rad(8)
			local upperCFrame = shoulderPos
				* CFrame.Angles(upperAngle, upperOutward, armData.side * math.rad(5))
				* CFrame.new(0, -SHADOW_CONFIG.UPPER_ARM_SIZE.Y * 0.5, 0)

			armData.upper.CFrame = upperCFrame
			armData.upper.Transparency = flickerTrans

			-- Elbow
			local elbowPos = upperCFrame * CFrame.new(0, -SHADOW_CONFIG.UPPER_ARM_SIZE.Y * 0.5, 0)
			armData.elbow.CFrame = CFrame.new(elbowPos.Position)

			-- Lower arm
			local lowerAngle = math.rad(5) + armSwing * 0.3 + attackAngle * 0.6
			local lowerCFrame = elbowPos
				* CFrame.Angles(lowerAngle, 0, 0)
				* CFrame.new(0, -SHADOW_CONFIG.LOWER_ARM_SIZE.Y * 0.5, 0)

			armData.lower.CFrame = lowerCFrame
			armData.lower.Transparency = flickerTrans

			-- Wrist
			local wristPos = lowerCFrame * CFrame.new(0, -SHADOW_CONFIG.LOWER_ARM_SIZE.Y * 0.5, 0)
			armData.wrist.CFrame = CFrame.new(wristPos.Position)

			-- Hand
			local handAngle = math.rad(-5) + attackAngle * 0.2
			local handCFrame = wristPos
				* CFrame.Angles(handAngle, 0, armData.side * math.rad(3))
				* CFrame.new(0, -SHADOW_CONFIG.HAND_SIZE.Y * 0.4, 0)

			armData.hand.CFrame = handCFrame
			armData.hand.Transparency = flickerTrans

			-- Claws
			for _, clawData in ipairs(armData.claws) do
				local clawIndex = clawData.index
				local clawX = (clawIndex - 2.5) * 0.12
				local clawSpread = (clawIndex - 2.5) * math.rad(10)
				local clawCurl = math.rad(25)

				-- Finger
				local fingerCFrame = handCFrame
					* CFrame.new(clawX, -SHADOW_CONFIG.HAND_SIZE.Y * 0.3, 0)
					* CFrame.Angles(clawCurl, clawSpread, 0)

				clawData.finger.CFrame = fingerCFrame

				-- Claw
				local clawCFrame = fingerCFrame
					* CFrame.new(0, -0.2, 0)
					* CFrame.Angles(math.rad(15), 0, 0)

				clawData.claw.CFrame = clawCFrame * CFrame.new(0, -SHADOW_CONFIG.CLAW_LENGTH * 0.5, 0)
				clawData.tip.CFrame = clawCFrame * CFrame.new(0, -SHADOW_CONFIG.CLAW_LENGTH - 0.05, 0)
			end
		end

		-- -----------------------------------------------------------------------
		-- LEGS
		-- -----------------------------------------------------------------------

		for _, legData in ipairs(legs) do
			local legPhase = legData.side == -1 and 0 or math.pi
			local legSwing = isWalking and math.sin(walkTime + legPhase) * math.rad(SHADOW_CONFIG.LEG_SWING) or 0

			local hipX = legData.side * 0.5

			-- Hip
			legData.hip.CFrame = baseCFrame * CFrame.new(hipX, pelvisY - 0.3 + walkBob, 0)

			-- Upper leg
			local upperLegCFrame = baseCFrame
				* CFrame.new(hipX, pelvisY - 0.5 + walkBob, 0)
				* CFrame.Angles(legSwing, 0, legData.side * math.rad(3))
				* CFrame.new(0, -SHADOW_CONFIG.UPPER_LEG_SIZE.Y * 0.5, 0)

			legData.upper.CFrame = upperLegCFrame
			legData.upper.Transparency = flickerTrans

			-- Knee
			local kneePos = upperLegCFrame * CFrame.new(0, -SHADOW_CONFIG.UPPER_LEG_SIZE.Y * 0.5, 0)
			legData.knee.CFrame = CFrame.new(kneePos.Position)

			-- Lower leg
			local lowerLegAngle = math.rad(-5) - legSwing * 0.4
			local lowerLegCFrame = kneePos
				* CFrame.Angles(lowerLegAngle, 0, 0)
				* CFrame.new(0, -SHADOW_CONFIG.LOWER_LEG_SIZE.Y * 0.5, 0)

			legData.lower.CFrame = lowerLegCFrame
			legData.lower.Transparency = flickerTrans

			-- Ankle
			local anklePos = lowerLegCFrame * CFrame.new(0, -SHADOW_CONFIG.LOWER_LEG_SIZE.Y * 0.5, 0)
			legData.ankle.CFrame = CFrame.new(anklePos.Position)

			-- Foot
			local footCFrame = anklePos
				* CFrame.Angles(math.rad(70) + legSwing * 0.2, 0, 0)
				* CFrame.new(0, -0.1, 0.3)

			legData.foot.CFrame = footCFrame

			-- Toe claws
			for t, toeClaw in ipairs(legData.toeClaws) do
				local toeX = (t - 2) * 0.15
				toeClaw.CFrame = footCFrame
					* CFrame.new(toeX, -0.1, 0.35)
					* CFrame.Angles(math.rad(-20), 0, 0)
			end
		end

		-- -----------------------------------------------------------------------
		-- BODY WISPS
		-- -----------------------------------------------------------------------

		for i, wispData in ipairs(bodyWisps) do
			local wispWave = math.sin(wispTime * 1.5 + i) * 0.1
			wispData.part.CFrame = baseCFrame
				* CFrame.new(wispWave, chestY + wispData.yOffset + walkBob, wispData.zOffset)
				* CFrame.Angles(wispWave * 0.5, 0, wispWave)
		end
	end

	-- Initial position
	UpdateNPCPosition(npcX, npcZ, npcRotation, false, 0)

	-- ---------------------------------------------------------------------------
	-- SOUNDS
	-- ---------------------------------------------------------------------------

	-- Spawn sound
	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = "rbxassetid://9114221735"
	spawnSound.Volume = 1
	spawnSound.Parent = chest
	spawnSound:Play()

	-- Spawn smoke effect
	local smokeEffect = CreatePart(
		"SpawnSmoke",
		Vector3.new(1, 1, 1),
		Color3.new(0, 0, 0),
		Enum.Material.SmoothPlastic,
		1,
		workspace
	)
	smokeEffect.Position = Vector3.new(npcX, groundY + 1, npcZ)

	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.new(0, 0, 0))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 4)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Lifetime = NumberRange.new(0.5, 1)
	smoke.Rate = 40
	smoke.Speed = NumberRange.new(2, 4)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Parent = smokeEffect

	Debris:AddItem(smokeEffect, 1.5)
	task.delay(0.5, function()
		smoke.Enabled = false
	end)

	-- ---------------------------------------------------------------------------
	-- ATTACK ANIMATION
	-- ---------------------------------------------------------------------------

	local function PlayAttackAnimation(targetPosition)
		if isAttacking then return end
		isAttacking = true

		-- Alternate arms
		attackingArm = attackingArm == "right" and "left" or "right"
		local armIndex = attackingArm == "right" and 2 or 1

		attackPhase = "windup"

		-- WINDUP
		local windupSteps = 8
		for i = 1, windupSteps do
			local t = i / windupSteps
			arms[armIndex].attackAngle = math.rad(-70) * t
			headTilt = math.rad(-12) * t
			bodyLean = math.rad(12) * t
			task.wait(SHADOW_CONFIG.ATTACK_WINDUP / windupSteps)
		end

		-- Eye flash
		for _, eyeData in ipairs(eyes) do
			TweenService:Create(eyeData.glow, TweenInfo.new(0.08), {
				Color = SHADOW_CONFIG.EYE_ATTACK
			}):Play()
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.08), {
					Color = SHADOW_CONFIG.EYE_ATTACK,
					Brightness = 8
				}):Play()
			end
		end

		attackPhase = "swing"

		-- SWING
		local swingSteps = 5
		for i = 1, swingSteps do
			local t = i / swingSteps
			arms[armIndex].attackAngle = math.rad(-70) + math.rad(160) * t
			headTilt = math.rad(-12) + math.rad(20) * t
			bodyLean = math.rad(12) - math.rad(22) * t
			task.wait(SHADOW_CONFIG.ATTACK_SWING / swingSteps)
		end

		-- Slash effect
		local slashEffect = CreatePart(
			"SlashEffect",
			Vector3.new(0.1, 0.1, 0.1),
			SHADOW_CONFIG.EYE_ATTACK,
			Enum.Material.Neon,
			1,
			workspace
		)
		slashEffect.Position = arms[armIndex].hand.Position

		local slashParticles = Instance.new("ParticleEmitter")
		slashParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 50, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
		})
		slashParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.3, 1.5),
			NumberSequenceKeypoint.new(1, 0)
		})
		slashParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		slashParticles.Lifetime = NumberRange.new(0.15, 0.3)
		slashParticles.Rate = 150
		slashParticles.Speed = NumberRange.new(12, 25)
		slashParticles.SpreadAngle = Vector2.new(35, 35)
		slashParticles.Parent = slashEffect

		Debris:AddItem(slashEffect, 0.4)
		task.wait(0.05)
		slashParticles.Enabled = false

		attackPhase = "recovery"

		-- RECOVERY
		local recoverySteps = 10
		for i = 1, recoverySteps do
			local t = i / recoverySteps
			arms[armIndex].attackAngle = math.rad(90) * (1 - t)
			headTilt = math.rad(8) * (1 - t)
			bodyLean = math.rad(-10) * (1 - t)
			task.wait(SHADOW_CONFIG.ATTACK_RECOVERY / recoverySteps)
		end

		-- Reset eyes
		for _, eyeData in ipairs(eyes) do
			TweenService:Create(eyeData.glow, TweenInfo.new(0.15), {
				Color = SHADOW_CONFIG.EYE_COLOR
			}):Play()
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.15), {
					Color = SHADOW_CONFIG.EYE_COLOR,
					Brightness = eyeData.baseBrightness
				}):Play()
			end
		end

		arms[armIndex].attackAngle = 0
		headTilt = 0
		bodyLean = 0
		attackPhase = "none"
		isAttacking = false
	end

	-- ---------------------------------------------------------------------------
	-- DEATH EFFECT
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		shadowAura.Enabled = false
		groundShadow.Enabled = false

		-- Death sound
		local deathSound = Instance.new("Sound")
		deathSound.SoundId = "rbxassetid://9114221580"
		deathSound.Volume = 1.5
		deathSound.PlaybackSpeed = 0.5
		deathSound.Parent = chest
		deathSound:Play()

		-- Eyes fade
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.3), {
					Brightness = 0
				}):Play()
			end
		end

		-- Death particles
		local deathParticles = Instance.new("ParticleEmitter")
		deathParticles.Color = ColorSequence.new(Color3.new(0, 0, 0))
		deathParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 3),
			NumberSequenceKeypoint.new(1, 0)
		})
		deathParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		deathParticles.Lifetime = NumberRange.new(0.5, 1)
		deathParticles.Rate = 60
		deathParticles.Speed = NumberRange.new(4, 10)
		deathParticles.SpreadAngle = Vector2.new(180, 180)
		deathParticles.Parent = chest

		-- All parts fade
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.5), {
					Transparency = 1
				}):Play()
			end
		end

		task.wait(0.6)
		deathParticles.Enabled = false
		Debris:AddItem(deathSound, 2)
	end

	-- ---------------------------------------------------------------------------
	-- AI BEHAVIOR LOOP
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0

	local function FindNearestPlayer()
		local nearest, nearestDist = nil, SHADOW_CONFIG. DETECTION_RANGE
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if hrp and hum and hum. Health > 0 then
					local dist = (hrp. Position - Vector3.new(npcX, 0, npcZ)).Magnitude
					if dist < nearestDist and not IsInLobby(hrp. Position. X) then
						nearestDist = dist
						nearest = player
					end
				end
			end
		end
		return nearest, nearestDist
	end

	local function AttackPlayer(player)
		if tick() - lastAttackTime < SHADOW_CONFIG. ATTACK_COOLDOWN then return end
		if isAttacking then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char: FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			coroutine.wrap(function()
				PlayAttackAnimation(hrp. Position)
			end)()

			task.wait(SHADOW_CONFIG. ATTACK_WINDUP + SHADOW_CONFIG. ATTACK_SWING * 0.5)

			local attackSound = Instance.new("Sound")
			attackSound.SoundId = "rbxassetid://5766332557"
			attackSound. Volume = 0.8
			attackSound. PlaybackSpeed = 1.3
			attackSound. Parent = chest
			attackSound:Play()

			local dist = (hrp. Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < SHADOW_CONFIG. ATTACK_RANGE + 2 and hum.Health > 0 then
				hum: TakeDamage(SHADOW_CONFIG.DAMAGE)

				local hitEffect = CreatePart(
					"HitEffect",
					Vector3.new(0.5, 0.5, 0.5),
					Color3.fromRGB(255, 50, 50),
					Enum.Material. Neon,
					0.3,
					workspace
				)
				hitEffect.Shape = Enum. PartType.Ball
				hitEffect.Position = hrp.Position

				TweenService:Create(hitEffect, TweenInfo.new(0.25), {
					Size = Vector3.new(3, 3, 3),
					Transparency = 1
				}):Play()

				local bloodEffect = Instance.new("ParticleEmitter")
				bloodEffect. Color = ColorSequence.new(Color3.fromRGB(139, 0, 0))
				bloodEffect.Size = NumberSequence. new({
					NumberSequenceKeypoint.new(0, 0.3),
					NumberSequenceKeypoint.new(1, 0)
				})
				bloodEffect.Transparency = NumberSequence.new(0)
				bloodEffect. Lifetime = NumberRange.new(0.2, 0.4)
				bloodEffect.Rate = 60
				bloodEffect. Speed = NumberRange. new(5, 12)
				bloodEffect.SpreadAngle = Vector2.new(180, 180)
				bloodEffect.Parent = hitEffect

				task. wait(0.08)
				bloodEffect. Enabled = false
				Debris:AddItem(hitEffect, 0.4)
			end

			Debris:AddItem(attackSound, 1)
		end
	end

	-- Main chase loop
	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		-- SHADOW usa "chest" como parte principal, no "thorax"
		if not isAlive or not chest or not chest.Parent then
			if chaseConnection then chaseConnection: Disconnect() end
			return
		end

		-- -----------------------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------------------------------------
		if npcModel: GetAttribute("Stunned") then
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
			return
		end
		-- -----------------------------------------------------------------------

		-- Check if in lobby
		if IsInLobby(npcX) then
			isAlive = false
			if chaseConnection then chaseConnection:Disconnect() end
			PlayDeathEffect()
			task.wait(0.7)
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
					local direction = Vector3.new(hrp.Position.X - npcX, 0, hrp.Position.Z - npcZ)

					if direction.Magnitude > 0.5 then
						local lookAngle = math. atan2(-direction.X, -direction.Z)

						if distance > SHADOW_CONFIG. ATTACK_RANGE then
							local moveDir = direction.Unit
							local newX = npcX + moveDir.X * SHADOW_CONFIG. SPEED * dt
							local newZ = npcZ + moveDir.Z * SHADOW_CONFIG.SPEED * dt

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

	-- Ambient sounds
	coroutine.wrap(function()
		while isAlive and chest and chest.Parent do
			task.wait(math.random(4, 10))
			if isAlive and chest and chest.Parent and not isAttacking then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://9114221580"
				sound.Volume = 0.3
				sound.PlaybackSpeed = 0.6 + math.random() * 0.3
				sound.Parent = chest
				sound:Play()
				Debris:AddItem(sound, 3)
			end
		end
	end)()

	-- Eye blink
	coroutine.wrap(function()
		while isAlive and #eyes > 0 do
			task.wait(math.random(2, 5))
			if isAlive and not isAttacking then
				for _, eyeData in ipairs(eyes) do
					if eyeData.glow and eyeData.glow.Parent then
						local originalTrans = eyeData.glow.Transparency
						eyeData.glow.Transparency = 1
						eyeData.inner.Transparency = 1
						task.wait(0.08)
						if eyeData.glow and eyeData.glow.Parent then
							eyeData.glow.Transparency = originalTrans
							eyeData.inner.Transparency = originalTrans
						end
					end
				end
			end
		end
	end)()

	-- Random flicker effect
	coroutine.wrap(function()
		while isAlive and chest and chest.Parent do
			task.wait(math.random(3, 8))
			if isAlive and not isAttacking then
				-- Intense flicker burst
				for _ = 1, 3 do
					flickerAlpha = 0.2 + math.random() * 0.3
					task.wait(0.03)
				end
				flickerAlpha = 1
			end
		end
	end)()

	-- Lifetime
	coroutine.wrap(function()
		task.wait(SHADOW_CONFIG.LIFETIME)
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
			if chaseConnection then chaseConnection: Disconnect() end
		end
	end)

	return npcFolder
end

-- ------------??------------------------------------------------------------------
-- EVENT LISTENER
-- -------------------------------------------------------------------------------

if SpawnNPCEvent then
	SpawnNPCEvent.Event:Connect(function(position, player, side, zDir)
		task.wait(0.3)
		CreateShadowNPC(position, player, side, zDir)
	end)
end

print("=== NPC SHADOW SYSTEM V3 - Enhanced Dark Wraith Ready ===")