--[[
    +------------------------------------------------------------------------------+
    ¦                       NPC HARVESTER ENTITY SYSTEM                             ¦
    ¦                    VERSIÓN 3 - ENHANCED AESTHETICS                            ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnHarvesterEvent = ReplicatedStorage:WaitForChild("SpawnHarvesterEvent", 10)

-- -------------------------------------------------------------------------------
-- CONFIGURACIÓN DEL HARVESTER
-- -------------------------------------------------------------------------------
local HARVESTER_CONFIG = {
	SPEED = 12,
	DAMAGE = 55,
	ATTACK_COOLDOWN = 1.8,
	ATTACK_RANGE = 10,
	DETECTION_RANGE = 320,
	LIFETIME = 65,
	REWARD_SURVIVAL = 40,

	TELEPORT_BEHIND_CHANCE = 0.2,

	-- APPEARANCE - Enhanced Colors
	CLOAK_COLOR = Color3.fromRGB(12, 8, 18),
	CLOAK_SECONDARY = Color3.fromRGB(20, 15, 28),
	CLOAK_INNER = Color3.fromRGB(5, 3, 8),
	BONE_COLOR = Color3.fromRGB(215, 205, 195),
	BONE_SHADOW = Color3.fromRGB(160, 150, 140),
	EYE_COLOR = Color3.fromRGB(255, 50, 50),
	EYE_INNER = Color3.fromRGB(255, 150, 100),
	SCYTHE_HANDLE = Color3.fromRGB(55, 40, 30),
	SCYTHE_BLADE = Color3.fromRGB(45, 45, 50),
	SCYTHE_EDGE = Color3.fromRGB(220, 60, 90),
	SOUL_COLOR = Color3.fromRGB(130, 180, 255),
	VOID_COLOR = Color3.fromRGB(2, 1, 3),

	-- DIMENSIONS - Properly scaled
	TOTAL_HEIGHT = 8,
	CLOAK_WIDTH = 3.2,
	SCYTHE_LENGTH = 6.5,

	-- ANIMATION
	HOVER_SPEED = 0.9,
	HOVER_AMPLITUDE = 0.2,
	BREATH_SPEED = 1.2,

	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

local function IsInLobby(x)
	return x >= HARVESTER_CONFIG.LOBBY_START_X and x <= HARVESTER_CONFIG.LOBBY_END_X
end

-- -------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-- -------------------------------------------------------------------------------

local function CreateMesh(parent, meshType, scale)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = meshType or Enum.MeshType.Brick
	if scale then
		mesh.Scale = scale
	end
	mesh.Parent = parent
	return mesh
end

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

-- -------------------------------------------------------------------------------
-- CREATE HARVESTER NPC
-- -------------------------------------------------------------------------------

local function CreateHarvesterNPC(spawnPosition, triggerPlayer, side, zDir)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "HarvesterEntity"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "HarvesterNPC"
	npcModel.Parent = npcFolder

	local groundY = 0.5
	local hoverHeight = 1.0

	-- Reference heights (from bottom to top)
	local HEIGHT = HARVESTER_CONFIG.TOTAL_HEIGHT
	local BASE_Y = 0 -- Ground reference

	-- ---------------------------------------------------------------------------
	-- CLOAK LOWER SECTION (Bottom flowing part)
	-- ---------------------------------------------------------------------------

	local cloakLower = CreatePart(
		"CloakLower",
		Vector3.new(HARVESTER_CONFIG.CLOAK_WIDTH * 1.3, HEIGHT * 0.35, 2.4),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		npcModel
	)
	cloakLower.CanCollide = true
	CreateMesh(cloakLower, Enum.MeshType.Brick, Vector3.new(1, 1, 0.8))

	-- ---------------------------------------------------------------------------
	-- CLOAK MIDDLE SECTION (Torso area)
	-- ---------------------------------------------------------------------------

	local cloakMiddle = CreatePart(
		"CloakMiddle",
		Vector3.new(HARVESTER_CONFIG.CLOAK_WIDTH, HEIGHT * 0.3, 1.8),
		HARVESTER_CONFIG.CLOAK_SECONDARY,
		Enum.Material.Fabric,
		0,
		npcModel
	)

	-- ---------------------------------------------------------------------------
	-- SHOULDERS (Distinct from body)
	-- ---------------------------------------------------------------------------

	local shoulderLeft = CreatePart(
		"ShoulderLeft",
		Vector3.new(0.9, 0.7, 1.2),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		npcModel
	)
	CreateMesh(shoulderLeft, Enum.MeshType.Sphere, Vector3.new(1, 0.8, 1))

	local shoulderRight = CreatePart(
		"ShoulderRight",
		Vector3.new(0.9, 0.7, 1.2),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		npcModel
	)
	CreateMesh(shoulderRight, Enum.MeshType.Sphere, Vector3.new(1, 0.8, 1))

	-- ---------------------------------------------------------------------------
	-- HOOD (Separate from body, properly shaped)
	-- ---------------------------------------------------------------------------

	local hoodBack = CreatePart(
		"HoodBack",
		Vector3.new(2.2, 2.4, 2.0),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		npcModel
	)
	CreateMesh(hoodBack, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.9))

	local hoodTop = CreatePart(
		"HoodTop",
		Vector3.new(1.8, 0.8, 1.6),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		npcModel
	)
	CreateMesh(hoodTop, Enum.MeshType.Sphere, Vector3.new(1, 1, 1))

	-- Hood opening frame (creates depth)
	local hoodRimLeft = CreatePart(
		"HoodRimLeft",
		Vector3.new(0.25, 1.8, 0.8),
		HARVESTER_CONFIG.CLOAK_SECONDARY,
		Enum.Material.Fabric,
		0,
		npcModel
	)

	local hoodRimRight = CreatePart(
		"HoodRimRight",
		Vector3.new(0.25, 1.8, 0.8),
		HARVESTER_CONFIG.CLOAK_SECONDARY,
		Enum.Material.Fabric,
		0,
		npcModel
	)

	local hoodRimTop = CreatePart(
		"HoodRimTop",
		Vector3.new(1.5, 0.25, 0.6),
		HARVESTER_CONFIG.CLOAK_SECONDARY,
		Enum.Material.Fabric,
		0,
		npcModel
	)

	-- ---------------------------------------------------------------------------
	-- VOID INTERIOR (Deep black inside hood)
	-- ---------------------------------------------------------------------------

	local voidInterior = CreatePart(
		"VoidInterior",
		Vector3.new(1.5, 1.7, 1.0),
		HARVESTER_CONFIG.VOID_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(voidInterior, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.5))

	-- ---------------------------------------------------------------------------
	-- SKULL (Partially visible in void)
	-- ---------------------------------------------------------------------------

	local skull = CreatePart(
		"Skull",
		Vector3.new(1.0, 1.2, 0.9),
		HARVESTER_CONFIG.BONE_COLOR,
		Enum.Material.SmoothPlastic,
		0.35,
		npcModel
	)
	CreateMesh(skull, Enum.MeshType.Head, Vector3.new(1.1, 1.15, 1.1))

	-- Cheekbones
	local cheekLeft = CreatePart(
		"CheekLeft",
		Vector3.new(0.35, 0.25, 0.3),
		HARVESTER_CONFIG.BONE_SHADOW,
		Enum.Material.SmoothPlastic,
		0.4,
		npcModel
	)
	CreateMesh(cheekLeft, Enum.MeshType.Sphere)

	local cheekRight = CreatePart(
		"CheekRight",
		Vector3.new(0.35, 0.25, 0.3),
		HARVESTER_CONFIG.BONE_SHADOW,
		Enum.Material.SmoothPlastic,
		0.4,
		npcModel
	)
	CreateMesh(cheekRight, Enum.MeshType.Sphere)

	-- Jaw
	local jaw = CreatePart(
		"Jaw",
		Vector3.new(0.6, 0.3, 0.5),
		HARVESTER_CONFIG.BONE_COLOR,
		Enum.Material.SmoothPlastic,
		0.4,
		npcModel
	)
	CreateMesh(jaw, Enum.MeshType.Head, Vector3.new(1, 0.8, 1))

	-- ---------------------------------------------------------------------------
	-- EYES (Glowing in the void)
	-- ---------------------------------------------------------------------------

	local eyes = {}
	for i = 1, 2 do
		local eyeSocket = CreatePart(
			"EyeSocket" ..i,
			Vector3.new(0.28, 0.32, 0.15),
			HARVESTER_CONFIG.VOID_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(eyeSocket, Enum.MeshType.Sphere)

		local eyeGlow = CreatePart(
			"EyeGlow" ..i,
			Vector3.new(0.18, 0.24, 0.08),
			HARVESTER_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeGlow, Enum.MeshType.Sphere)

		local eyePupil = CreatePart(
			"EyePupil" ..i,
			Vector3.new(0.08, 0.12, 0.04),
			HARVESTER_CONFIG.EYE_INNER,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyePupil, Enum.MeshType.Sphere)

		local eyeLight = Instance.new("PointLight")
		eyeLight.Brightness = 3
		eyeLight.Color = HARVESTER_CONFIG.EYE_COLOR
		eyeLight.Range = 6
		eyeLight.Shadows = true
		eyeLight.Parent = eyeGlow

		table.insert(eyes, {
			socket = eyeSocket,
			glow = eyeGlow,
			pupil = eyePupil,
			light = eyeLight,
			side = i == 1 and -1 or 1
		})
	end

	-- ---------------------------------------------------------------------------
	-- ARMS (Flowing from shoulders)
	-- ---------------------------------------------------------------------------

	local arms = {}
	for i = 1, 2 do
		local armSide = i == 1 and -1 or 1

		local upperArm = CreatePart(
			"UpperArm" ..i,
			Vector3.new(0.45, 1.2, 0.45),
			HARVESTER_CONFIG.CLOAK_COLOR,
			Enum.Material.Fabric,
			0,
			npcModel
		)

		local lowerArm = CreatePart(
			"LowerArm" ..i,
			Vector3.new(0.35, 1.0, 0.35),
			HARVESTER_CONFIG.CLOAK_SECONDARY,
			Enum.Material.Fabric,
			0,
			npcModel
		)

		local hand = CreatePart(
			"Hand" ..i,
			Vector3.new(0.4, 0.55, 0.22),
			HARVESTER_CONFIG.BONE_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)

		-- Fingers
		local fingers = {}
		for f = 1, 4 do
			local finger = CreatePart(
				"Finger" ..i .."_" ..f,
				Vector3.new(0.06, 0.25, 0.06),
				HARVESTER_CONFIG.BONE_COLOR,
				Enum.Material.SmoothPlastic,
				0,
				npcModel
			)
			CreateMesh(finger, Enum.MeshType.Cylinder)
			table.insert(fingers, finger)
		end

		-- Thumb
		local thumb = CreatePart(
			"Thumb" ..i,
			Vector3.new(0.07, 0.18, 0.07),
			HARVESTER_CONFIG.BONE_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(thumb, Enum.MeshType.Cylinder)

		table.insert(arms, {
			upper = upperArm,
			lower = lowerArm,
			hand = hand,
			fingers = fingers,
			thumb = thumb,
			side = armSide
		})
	end

	-- ---------------------------------------------------------------------------
	-- CLOAK TATTERS (Bottom flowing pieces - properly spaced)
	-- ---------------------------------------------------------------------------

	local cloakTatters = {}
	local tatterCount = 8
	for i = 1, tatterCount do
		local tatterHeight = 0.8 + math.random() * 0.6
		local tatterWidth = 0.3 + math.random() * 0.2
		local tatter = CreatePart(
			"Tatter" ..i,
			Vector3.new(tatterWidth, tatterHeight, 0.15),
			HARVESTER_CONFIG.CLOAK_COLOR,
			Enum.Material.Fabric,
			0,
			npcModel
		)

		table.insert(cloakTatters, {
			part = tatter,
			angle = (i / tatterCount) * math.pi * 2,
			height = tatterHeight,
			offset = (i % 2 == 0) and 0.1 or -0.1
		})
	end

	-- ---------------------------------------------------------------------------
	-- SCYTHE (Properly constructed and positioned)
	-- ---------------------------------------------------------------------------

	local scytheFolder = Instance.new("Folder")
	scytheFolder.Name = "Scythe"
	scytheFolder.Parent = npcModel

	-- Handle - Main shaft
	local scytheHandle = CreatePart(
		"Handle",
		Vector3.new(0.18, HARVESTER_CONFIG.SCYTHE_LENGTH, 0.18),
		HARVESTER_CONFIG.SCYTHE_HANDLE,
		Enum.Material.Wood,
		0,
		scytheFolder
	)
	CreateMesh(scytheHandle, Enum.MeshType.Cylinder)

	-- Handle wrapping (decorative)
	local handleWrap1 = CreatePart(
		"HandleWrap1",
		Vector3.new(0.22, 0.15, 0.22),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		scytheFolder
	)

	local handleWrap2 = CreatePart(
		"HandleWrap2",
		Vector3.new(0.22, 0.15, 0.22),
		HARVESTER_CONFIG.CLOAK_COLOR,
		Enum.Material.Fabric,
		0,
		scytheFolder
	)

	-- Handle end cap
	local handleCap = CreatePart(
		"HandleCap",
		Vector3.new(0.25, 0.3, 0.25),
		HARVESTER_CONFIG.SCYTHE_BLADE,
		Enum.Material.Metal,
		0,
		scytheFolder
	)
	CreateMesh(handleCap, Enum.MeshType.Sphere)

	-- Blade collar (where blade meets handle)
	local bladeCollar = CreatePart(
		"BladeCollar",
		Vector3.new(0.4, 0.5, 0.4),
		HARVESTER_CONFIG.SCYTHE_BLADE,
		Enum.Material.Metal,
		0,
		scytheFolder
	)
	CreateMesh(bladeCollar, Enum.MeshType.Cylinder)

	-- Blade spine (back of blade)
	local bladeSpine = CreatePart(
		"BladeSpine",
		Vector3.new(3.2, 0.15, 0.25),
		HARVESTER_CONFIG.SCYTHE_BLADE,
		Enum.Material.Metal,
		0,
		scytheFolder
	)

	-- Main blade
	local blade = CreatePart(
		"Blade",
		Vector3.new(3.0, 0.06, 0.85),
		HARVESTER_CONFIG.SCYTHE_BLADE,
		Enum.Material.Metal,
		0,
		scytheFolder
	)

	-- Blade edge (glowing)
	local bladeEdge = CreatePart(
		"BladeEdge",
		Vector3.new(3.0, 0.025, 0.06),
		HARVESTER_CONFIG.SCYTHE_EDGE,
		Enum.Material.Neon,
		0,
		scytheFolder
	)

	local bladeLight = Instance.new("PointLight")
	bladeLight.Brightness = 2
	bladeLight.Color = HARVESTER_CONFIG.SCYTHE_EDGE
	bladeLight.Range = 10
	bladeLight.Shadows = true
	bladeLight.Parent = bladeEdge

	-- Blade tip
	local bladeTip = CreatePart(
		"BladeTip",
		Vector3.new(0.5, 0.05, 0.4),
		HARVESTER_CONFIG.SCYTHE_BLADE,
		Enum.Material.Metal,
		0,
		scytheFolder
	)

	-- ---------------------------------------------------------------------------
	-- PARTICLE EFFECTS
	-- ---------------------------------------------------------------------------

	-- Dark aura around cloak
	local auraEmitter = Instance.new("ParticleEmitter")
	auraEmitter.Texture = "rbxassetid://243098098"
	auraEmitter.Color = ColorSequence.new(HARVESTER_CONFIG.CLOAK_INNER)
	auraEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 2.5),
		NumberSequenceKeypoint.new(1, 4)
	})
	auraEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	})
	auraEmitter.Lifetime = NumberRange.new(0.8, 1.5)
	auraEmitter.Rate = 12
	auraEmitter.Speed = NumberRange.new(0.5, 1.5)
	auraEmitter.SpreadAngle = Vector2.new(360, 360)
	auraEmitter.RotSpeed = NumberRange.new(-30, 30)
	auraEmitter.Parent = cloakLower

	-- Soul wisps
	local soulEmitter = Instance.new("ParticleEmitter")
	soulEmitter.Texture = "rbxassetid://243098098"
	soulEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, HARVESTER_CONFIG.SOUL_COLOR),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))
	})
	soulEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.3, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	soulEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	soulEmitter.Lifetime = NumberRange.new(1.5, 3)
	soulEmitter.Rate = 3
	soulEmitter.Speed = NumberRange.new(1, 3)
	soulEmitter.SpreadAngle = Vector2.new(180, 180)
	soulEmitter.Acceleration = Vector3.new(0, 1, 0)
	soulEmitter.Parent = voidInterior

	-- Blade trail particles
	local bladeTrail = Instance.new("ParticleEmitter")
	bladeTrail.Texture = "rbxassetid://243098098"
	bladeTrail.Color = ColorSequence.new(HARVESTER_CONFIG.SCYTHE_EDGE)
	bladeTrail.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0)
	})
	bladeTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	bladeTrail.Lifetime = NumberRange.new(0.3, 0.6)
	bladeTrail.Rate = 8
	bladeTrail.Speed = NumberRange.new(0, 0.5)
	bladeTrail.Parent = bladeEdge

	-- ---------------------------------------------------------------------------
	-- ANIMATION STATE
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local npcRotation = zDir > 0 and 0 or math.pi
	local hoverTime = 0
	local breathTime = 0
	local scytheSwingAngle = 0
	local isAttacking = false

	-- ---------------------------------------------------------------------------
	-- UPDATE POSITION - Complete repositioning without overlaps
	-- ---------------------------------------------------------------------------

	local function UpdateNPCPosition(x, z, rotY, deltaTime)
		npcX = x
		npcZ = z
		npcRotation = rotY or npcRotation

		if deltaTime then
			hoverTime = hoverTime + deltaTime * HARVESTER_CONFIG.HOVER_SPEED
			breathTime = breathTime + deltaTime * HARVESTER_CONFIG.BREATH_SPEED
		end

		-- Base position calculations
		local hoverY = groundY + hoverHeight + math.sin(hoverTime * math.pi) * HARVESTER_CONFIG.HOVER_AMPLITUDE
		local swayX = math.sin(hoverTime * 0.7) * 0.08
		local swayZ = math.cos(hoverTime * 0.5) * 0.06
		local breathScale = 1 + math.sin(breathTime * math.pi) * 0.02

		local basePos = Vector3.new(x + swayX, hoverY, z + swayZ)
		local baseCFrame = CFrame.new(basePos) * CFrame.Angles(0, npcRotation, 0)

		-- Height reference points (from base position)
		local cloakLowerY = HEIGHT * 0.18
		local cloakMiddleY = HEIGHT * 0.45
		local shoulderY = HEIGHT * 0.58
		local hoodY = HEIGHT * 0.72
		local skullY = HEIGHT * 0.68

		-- -----------------------------------------------------------------------
		-- CLOAK POSITIONING
		-- -----------------------------------------------------------------------

		cloakLower.CFrame = baseCFrame * CFrame.new(0, cloakLowerY, 0)

		cloakMiddle.CFrame = baseCFrame * CFrame.new(0, cloakMiddleY, 0) 
			* CFrame.Angles(0, 0, 0)

		-- -----------------------------------------------------------------------
		-- SHOULDERS (Separated from body)
		-- -----------------------------------------------------------------------

		local shoulderOffset = 1.4
		shoulderLeft.CFrame = baseCFrame * CFrame.new(-shoulderOffset, shoulderY, -0.1)
		shoulderRight.CFrame = baseCFrame * CFrame.new(shoulderOffset, shoulderY, -0.1)

		-- -----------------------------------------------------------------------
		-- HOOD (Above and separate from shoulders)
		-- -----------------------------------------------------------------------

		local headBob = math.sin(hoverTime * 1.2) * 0.03
		local hoodTilt = math.sin(hoverTime * 0.8) * 0.02

		hoodBack.CFrame = baseCFrame * CFrame.new(0, hoodY + headBob, 0.15) 
			* CFrame.Angles(math.rad(-5) + hoodTilt, 0, 0)

		hoodTop.CFrame = baseCFrame * CFrame.new(0, hoodY + 1.0 + headBob, -0.1)
			* CFrame.Angles(math.rad(-15), 0, 0)

		-- Hood rim (creates frame around opening)
		local rimForward = -1.0
		hoodRimLeft.CFrame = baseCFrame * CFrame.new(-0.85, hoodY + headBob - 0.1, rimForward)
		hoodRimRight.CFrame = baseCFrame * CFrame.new(0.85, hoodY + headBob - 0.1, rimForward)
		hoodRimTop.CFrame = baseCFrame * CFrame.new(0, hoodY + 0.75 + headBob, rimForward - 0.1)

		-- ----???------------------------------------------------------------------
		-- VOID AND SKULL (Inside hood, set back)
		-- -----------------------------------------------------------------------

		voidInterior.CFrame = baseCFrame * CFrame.new(0, skullY + headBob, -0.6)

		skull.CFrame = baseCFrame * CFrame.new(0, skullY + headBob - 0.05, -0.4)
			* CFrame.Angles(math.rad(-3), 0, 0)

		-- Cheekbones
		cheekLeft.CFrame = skull.CFrame * CFrame.new(-0.35, -0.15, -0.35)
		cheekRight.CFrame = skull.CFrame * CFrame.new(0.35, -0.15, -0.35)

		-- Jaw
		jaw.CFrame = skull.CFrame * CFrame.new(0, -0.45, -0.15)
			* CFrame.Angles(math.rad(5), 0, 0)

		-- -----------------------------------------------------------------------
		-- EYES (In front of skull, visible)
		-- -----------------------------------------------------------------------

		for _, eyeData in ipairs(eyes) do
			local eyeX = eyeData.side * 0.22
			local eyeY = 0.18
			local eyeZ = -0.48

			-- Subtle eye movement
			local eyeLookX = math.sin(hoverTime * 0.3) * 0.02
			local eyeLookY = math.cos(hoverTime * 0.4) * 0.01

			eyeData.socket.CFrame = skull.CFrame * CFrame.new(eyeX, eyeY, eyeZ)
			eyeData.glow.CFrame = skull.CFrame * CFrame.new(eyeX + eyeLookX, eyeY + eyeLookY, eyeZ - 0.05)
			eyeData.pupil.CFrame = skull.CFrame * CFrame.new(eyeX + eyeLookX, eyeY + eyeLookY, eyeZ - 0.08)

			-- Eye flicker effect
			if eyeData.light then
				local flicker = 2.5 + math.sin(hoverTime * 8 + eyeData.side) * 0.5
				if math.random() < 0.02 then
					flicker = flicker + math.random() * 2
				end
				eyeData.light.Brightness = flicker
			end
		end

		-- -----------------------------------------------------------------------
		-- ARMS (Flowing from shoulders, holding scythe)
		-- -----------------------------------------------------------------------

		for _, armData in ipairs(arms) do
			local armSwing = math.sin(hoverTime + armData.side * 0.5) * 0.1
			local isRightArm = armData.side == 1

			local upperArmAngle, lowerArmAngle, handAngle

			if isRightArm then
				-- Right arm holds scythe
				upperArmAngle = math.rad(-40) + scytheSwingAngle * 0.3
				lowerArmAngle = math.rad(-30) + scytheSwingAngle * 0.5
				handAngle = math.rad(-20) + scytheSwingAngle * 0.2
			else
				-- Left arm hangs naturally with slight movement
				upperArmAngle = math.rad(15) + armSwing
				lowerArmAngle = math.rad(10) + armSwing * 0.5
				handAngle = math.rad(5)
			end

			local shoulderPos = armData.side == -1 and shoulderLeft.Position or shoulderRight.Position

			-- Upper arm
			local upperArmCFrame = CFrame.new(shoulderPos) 
				* CFrame.Angles(0, npcRotation, 0)
				* CFrame.new(armData.side * 0.3, -0.3, 0)
				* CFrame.Angles(upperArmAngle, armData.side * math.rad(10), armData.side * math.rad(15))

			armData.upper.CFrame = upperArmCFrame * CFrame.new(0, -0.6, 0)

			-- Lower arm
			local lowerArmCFrame = upperArmCFrame 
				* CFrame.new(0, -1.1, 0)
				* CFrame.Angles(lowerArmAngle, 0, 0)

			armData.lower.CFrame = lowerArmCFrame * CFrame.new(0, -0.5, 0)

			-- Hand
			local handCFrame = lowerArmCFrame 
				* CFrame.new(0, -1.0, 0)
				* CFrame.Angles(handAngle, 0, 0)

			armData.hand.CFrame = handCFrame

			-- Fingers
			for f, finger in ipairs(armData.fingers) do
				local fingerOffset = (f - 2.5) * 0.09
				local fingerCurl = math.rad(30) + math.sin(hoverTime + f) * math.rad(5)
				finger.CFrame = handCFrame 
					* CFrame.new(fingerOffset, -0.35, 0)
					* CFrame.Angles(fingerCurl, 0, 0)
			end

			-- Thumb
			armData.thumb.CFrame = handCFrame 
				* CFrame.new(armData.side * 0.18, -0.15, -0.08)
				* CFrame.Angles(math.rad(20), armData.side * math.rad(30), 0)
		end

		-- -----------------------------------------------------------------------
		-- CLOAK TATTERS (Bottom, flowing)
		-- -----------------------------------------------------------------------

		local tatterBaseY = cloakLowerY - HEIGHT * 0.15
		for _, tatterData in ipairs(cloakTatters) do
			local tatterAngle = tatterData.angle + hoverTime * 0.15
			local radius = HARVESTER_CONFIG.CLOAK_WIDTH * 0.5
			local tatterX = math.cos(tatterAngle) * radius
			local tatterZ = math.sin(tatterAngle) * 0.6 + tatterData.offset
			local tatterWave = math.sin(hoverTime * 2 + tatterData.angle * 2) * 0.25
			local tatterSway = math.cos(hoverTime * 1.5 + tatterData.angle) * 0.15

			tatterData.part.CFrame = baseCFrame 
				* CFrame.new(tatterX, tatterBaseY - tatterData.height * 0.5, tatterZ)
				* CFrame.Angles(tatterWave, tatterAngle + tatterSway, tatterSway * 0.5)
		end

		-- -----------------------------------------------------------------------
		-- SCYTHE (Held by right hand, properly angled)
		-- -----------------------------------------------------------------------

		local rightHand = arms[2].hand
		local scytheBaseAngle = math.rad(-55) + scytheSwingAngle

		-- Scythe pivot point (at hand position)
		local scythePivot = rightHand.CFrame 
			* CFrame.new(0, -0.2, 0)
			* CFrame.Angles(scytheBaseAngle, math.rad(5), math.rad(-10))

		-- Handle positioning
		local handleOffset = HARVESTER_CONFIG.SCYTHE_LENGTH * 0.3
		scytheHandle.CFrame = scythePivot * CFrame.new(0, -handleOffset, 0)

		-- Handle wraps
		handleWrap1.CFrame = scythePivot * CFrame.new(0, 0.5, 0)
		handleWrap2.CFrame = scythePivot * CFrame.new(0, -1.0, 0)

		-- Handle cap (bottom)
		handleCap.CFrame = scythePivot * CFrame.new(0, -HARVESTER_CONFIG.SCYTHE_LENGTH * 0.48, 0)

		-- Blade assembly (top of handle)
		local bladeAttach = scythePivot * CFrame.new(0, HARVESTER_CONFIG.SCYTHE_LENGTH * 0.48, 0)

		bladeCollar.CFrame = bladeAttach * CFrame.Angles(0, 0, math.rad(90))

		-- Blade curves outward
		local bladeCurve = CFrame.Angles(0, math.rad(-20), math.rad(5))
		bladeSpine.CFrame = bladeAttach * CFrame.new(-1.5, 0.1, 0.1) * bladeCurve
		blade.CFrame = bladeAttach * CFrame.new(-1.4, 0, 0.35) * bladeCurve
		bladeEdge.CFrame = blade.CFrame * CFrame.new(0, -0.04, 0.42)
		bladeTip.CFrame = bladeAttach * CFrame.new(-2.9, 0, 0.5) * bladeCurve * CFrame.Angles(0, math.rad(-25), 0)
	end

	-- Initial position
	UpdateNPCPosition(npcX, npcZ, npcRotation, 0)

	-- ---------------------------------------------------------------------------
	-- SOUNDS
	-- ---------------------------------------------------------------------------

	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = "rbxassetid://9114221735"
	spawnSound.Volume = 1.3
	spawnSound.PlaybackSpeed = 0.5
	spawnSound.Parent = cloakLower
	spawnSound:Play()

	local whisperSound = Instance.new("Sound")
	whisperSound.SoundId = "rbxassetid://9114221580"
	whisperSound.Volume = 0.2
	whisperSound.Looped = true
	whisperSound.PlaybackSpeed = 0.35
	whisperSound.Parent = cloakLower
	whisperSound:Play()

	-- ---------------------------------------------------------------------------
	-- ATTACK ANIMATION
	-- ---------------------------------------------------------------------------

	local function PlayAttackAnimation()
		if isAttacking then return end
		isAttacking = true

		-- Eyes intensify
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.15), {
					Brightness = 8,
					Range = 12
				}):Play()
			end
			TweenService:Create(eyeData.glow, TweenInfo.new(0.15), {
				Color = Color3.fromRGB(255, 100, 100)
			}):Play()
		end

		-- Blade glow intensifies
		TweenService:Create(bladeEdge, TweenInfo.new(0.15), {
			Color = Color3.fromRGB(255, 120, 160)
		}):Play()
		TweenService:Create(bladeLight, TweenInfo.new(0.15), {
			Brightness = 5,
			Range = 18
		}):Play()
		bladeTrail.Rate = 30

		-- Raise sound
		local raiseSound = Instance.new("Sound")
		raiseSound.SoundId = "rbxassetid://9114221890"
		raiseSound.Volume = 0.7
		raiseSound.PlaybackSpeed = 0.7
		raiseSound.Parent = cloakLower
		raiseSound:Play()

		-- Raise scythe (wind up)
		for i = 1, 15 do
			scytheSwingAngle = math.rad(-100) * (i / 15)
			task.wait(0.02)
		end

		task.wait(0.06)

		-- Swing sound
		local swingSound = Instance.new("Sound")
		swingSound.SoundId = "rbxassetid://5766332557"
		swingSound.Volume = 1.2
		swingSound.PlaybackSpeed = 0.8
		swingSound.Parent = cloakLower
		swingSound:Play()

		-- Swing down (fast)
		for i = 1, 10 do
			scytheSwingAngle = math.rad(-100) + math.rad(150) * (i / 10)
			task.wait(0.015)
		end

		-- Recovery (slow return)
		for i = 10, 0, -1 do
			scytheSwingAngle = math.rad(50) * (i / 10)
			task.wait(0.025)
		end
		scytheSwingAngle = 0

		-- Reset effects
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.3), {
					Brightness = 3,
					Range = 6
				}):Play()
			end
			TweenService:Create(eyeData.glow, TweenInfo.new(0.3), {
				Color = HARVESTER_CONFIG.EYE_COLOR
			}):Play()
		end

		TweenService:Create(bladeEdge, TweenInfo.new(0.3), {
			Color = HARVESTER_CONFIG.SCYTHE_EDGE
		}):Play()
		TweenService:Create(bladeLight, TweenInfo.new(0.3), {
			Brightness = 2,
			Range = 10
		}):Play()
		bladeTrail.Rate = 8

		Debris:AddItem(raiseSound, 2)
		Debris:AddItem(swingSound, 2)

		isAttacking = false
	end

	-- ---------------------------------------------------------------------------
	-- TELEPORT BEHIND PLAYER
	-- ---------------------------------------------------------------------------

	local function TeleportBehindPlayer(targetHrp)
		local behindOffset = targetHrp.CFrame * CFrame.new(0, 0, 4.5)
		local newX = behindOffset.Position.X
		local newZ = behindOffset.Position.Z

		if IsInLobby(newX) then return false end

		-- Gather all parts for fade
		local allParts = {}
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(allParts, {part = part, originalTrans = part.Transparency})
			end
		end

		-- Disable particles
		auraEmitter.Enabled = false
		soulEmitter.Enabled = false
		bladeTrail.Enabled = false

		-- Fade out
		for _, data in ipairs(allParts) do
			TweenService:Create(data.part, TweenInfo.new(0.2), {Transparency = 1}):Play()
		end

		local teleportSound = Instance.new("Sound")
		teleportSound.SoundId = "rbxassetid://9114222045"
		teleportSound.Volume = 0.9
		teleportSound.PlaybackSpeed = 0.7
		teleportSound.Parent = cloakLower
		teleportSound:Play()

		task.wait(0.25)

		-- Update position
		npcX = newX
		npcZ = newZ
		npcRotation = math.atan2(-(targetHrp.Position.X - npcX), -(targetHrp.Position.Z - npcZ))

		-- Fade in
		for _, data in ipairs(allParts) do
			TweenService:Create(data.part, TweenInfo.new(0.2), {Transparency = data.originalTrans}):Play()
		end

		-- Re-enable particles
		task.delay(0.2, function()
			auraEmitter.Enabled = true
			soulEmitter.Enabled = true
			bladeTrail.Enabled = true
		end)

		Debris:AddItem(teleportSound, 2)
		return true
	end

	-- ------------???--------------------------------------------------------------
	-- DEATH EFFECT
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		auraEmitter.Enabled = false
		soulEmitter.Enabled = false
		bladeTrail.Enabled = false
		whisperSound:Stop()

		local deathSound = Instance.new("Sound")
		deathSound.SoundId = "rbxassetid://9114221735"
		deathSound.Volume = 1.5
		deathSound.PlaybackSpeed = 0.3
		deathSound.Parent = cloakLower
		deathSound:Play()

		-- Collapse animation
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				local randomX = (math.random() - 0.5) * 2
				local randomZ = (math.random() - 0.5) * 2
				TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = Vector3.new(
						part.Position.X + randomX,
						groundY - 1,
						part.Position.Z + randomZ
					),
					Transparency = 1
				}):Play()
			end
		end

		-- Soul burst effect
		local soulBurst = Instance.new("Part")
		soulBurst.Size = Vector3.new(2, 2, 2)
		soulBurst.Shape = Enum.PartType.Ball
		soulBurst.Color = HARVESTER_CONFIG.SOUL_COLOR
		soulBurst.Material = Enum.Material.Neon
		soulBurst.Transparency = 0.4
		soulBurst.Anchored = true
		soulBurst.CanCollide = false
		soulBurst.Position = hoodBack.Position
		soulBurst.Parent = workspace

		local burstLight = Instance.new("PointLight")
		burstLight.Brightness = 5
		burstLight.Color = HARVESTER_CONFIG.SOUL_COLOR
		burstLight.Range = 20
		burstLight.Parent = soulBurst

		TweenService:Create(soulBurst, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
			Size = Vector3.new(15, 15, 15),
			Transparency = 1
		}):Play()

		TweenService:Create(burstLight, TweenInfo.new(0.6), {
			Brightness = 0,
			Range = 0
		}):Play()

		Debris:AddItem(soulBurst, 0.7)
		task.wait(0.9)
		Debris:AddItem(deathSound, 2)
	end

	-- ---------------------------------------------------------------------------
	-- AI BEHAVIOR LOOP
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0
	local lastTeleportTime = 0

	local function FindNearestPlayer()
		local nearest, nearestDist = nil, HARVESTER_CONFIG.DETECTION_RANGE
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
					if dist < nearestDist and not IsInLobby(hrp.Position.X) then
						nearestDist = dist
						nearest = player
					end
				end
			end
		end
		return nearest, nearestDist
	end

	local function AttackPlayer(player)
		if tick() - lastAttackTime < HARVESTER_CONFIG.ATTACK_COOLDOWN then return end
		if isAttacking then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			-- Chance to teleport behind
			if math.random() < HARVESTER_CONFIG.TELEPORT_BEHIND_CHANCE and tick() - lastTeleportTime > 6 then
				lastTeleportTime = tick()
				if TeleportBehindPlayer(hrp) then
					task.wait(0.35)
				end
			end

			coroutine.wrap(PlayAttackAnimation)()

			task.wait(0.45)

			-- Check if still in range after swing
			local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < HARVESTER_CONFIG.ATTACK_RANGE + 3 and hum.Health > 0 then
				hum: TakeDamage(HARVESTER_CONFIG.DAMAGE)

				-- Soul drain visual effect
				local soulDrain = Instance.new("Part")
				soulDrain.Size = Vector3.new(0.6, 0.6, 0.6)
				soulDrain.Shape = Enum.PartType.Ball
				soulDrain.Color = HARVESTER_CONFIG.SOUL_COLOR
				soulDrain.Material = Enum.Material.Neon
				soulDrain.Transparency = 0.2
				soulDrain.Anchored = true
				soulDrain.CanCollide = false
				soulDrain.Position = hrp.Position
				soulDrain.Parent = workspace

				local drainLight = Instance.new("PointLight")
				drainLight.Brightness = 3
				drainLight.Color = HARVESTER_CONFIG.SOUL_COLOR
				drainLight.Range = 8
				drainLight.Parent = soulDrain

				-- Soul travels to harvester
				TweenService: Create(soulDrain, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = voidInterior.Position,
					Size = Vector3.new(0.1, 0.1, 0.1),
					Transparency = 1
				}):Play()

				Debris:AddItem(soulDrain, 0.6)
			end
		end
	end

	-- Main chase loop
	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		-- HARVESTER usa "cloakLower" como parte principal, NO "thorax"
		if not isAlive or not cloakLower or not cloakLower.Parent then
			if chaseConnection then chaseConnection:Disconnect() end
			return
		end

		-- -----------------------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------------------------------------
		if npcModel: GetAttribute("Stunned") then
			UpdateNPCPosition(npcX, npcZ, npcRotation, dt)
			return
		end
		-- -----------------------------------------------------------------------

		-- Check if entered lobby (death zone)
		if IsInLobby(npcX) then
			isAlive = false
			if chaseConnection then chaseConnection:Disconnect() end
			PlayDeathEffect()
			task.wait(0.9)
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
					local direction = Vector3.new(hrp.Position. X - npcX, 0, hrp.Position.Z - npcZ)

					if direction. Magnitude > 0.5 then
						local lookAngle = math.atan2(-direction.X, -direction.Z)

						if distance > HARVESTER_CONFIG.ATTACK_RANGE then
							local moveDir = direction. Unit
							local newX = npcX + moveDir.X * HARVESTER_CONFIG.SPEED * dt
							local newZ = npcZ + moveDir.Z * HARVESTER_CONFIG.SPEED * dt

							if not IsInLobby(newX) then
								npcRotation = lookAngle
								UpdateNPCPosition(newX, newZ, lookAngle, dt)
							else
								UpdateNPCPosition(npcX, npcZ, lookAngle, dt)
							end
						else
							UpdateNPCPosition(npcX, npcZ, lookAngle, dt)
							AttackPlayer(target)
						end
					else
						UpdateNPCPosition(npcX, npcZ, npcRotation, dt)
					end
				else
					UpdateNPCPosition(npcX, npcZ, npcRotation, dt)
				end
			else
				UpdateNPCPosition(npcX, npcZ, npcRotation, dt)
			end
		else
			UpdateNPCPosition(npcX, npcZ, npcRotation, dt)
		end
	end)

	-- Random whisper sounds
	coroutine.wrap(function()
		while isAlive and cloakLower and cloakLower.Parent do
			task.wait(math.random(5, 12))
			if isAlive and cloakLower and cloakLower.Parent then
				local whisper = Instance.new("Sound")
				whisper.SoundId = "rbxassetid://9114222045"
				whisper.Volume = 0.3
				whisper.PlaybackSpeed = 0.35 + math.random() * 0.25
				whisper.Parent = cloakLower
				whisper:Play()
				Debris:AddItem(whisper, 4)
			end
		end
	end)()

	-- Lifetime timer
	coroutine.wrap(function()
		task.wait(HARVESTER_CONFIG.LIFETIME)
		if npcFolder and npcFolder.Parent and isAlive then
			isAlive = false
			PlayDeathEffect()
			task.wait(0.9)
			if npcFolder then npcFolder:Destroy() end
		end
	end)()

	-- Cleanup on destroy
	npcFolder.AncestryChanged:Connect(function()
		if not npcFolder.Parent then
			isAlive = false
			whisperSound:Stop()
			if chaseConnection then chaseConnection: Disconnect() end
		end
	end)

	return npcFolder
end

-- -------------------------------------------------------------------------------
-- EVENT LISTENER
-- -------------------------------------------------------------------------------

if SpawnHarvesterEvent then
	SpawnHarvesterEvent.Event:Connect(function(position, player, side, zDir)
		task.wait(0.5)
		CreateHarvesterNPC(position, player, side, zDir)
	end)
end

print("=== NPC HARVESTER SYSTEM V3 - Enhanced Aesthetics Ready ===")