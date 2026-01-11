--[[
    +------------------------------------------------------------------------------+
    ¦                        NPC SCREAMER ENTITY SYSTEM                             ¦
    ¦                    VERSIÓN 3 - ENHANCED TITAN HORROR                          ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnScreamerEvent = ReplicatedStorage:WaitForChild("SpawnScreamerEvent", 10)

-- -------------------------------------------------------------------------------
-- CONFIGURACIÓN DEL SCREAMER
-- -------------------------------------------------------------------------------
local SCREAMER_CONFIG = {
	SPEED = 20,
	DAMAGE = 65,
	ATTACK_COOLDOWN = 1.2,
	ATTACK_RANGE = 12,
	DETECTION_RANGE = 300,
	LIFETIME = 45,

	-- APPEARANCE - Enhanced dark colors
	BODY_PRIMARY = Color3.fromRGB(15, 15, 20),
	BODY_SECONDARY = Color3.fromRGB(25, 25, 32),
	BODY_ACCENT = Color3.fromRGB(35, 30, 40),
	FLESH_COLOR = Color3.fromRGB(45, 25, 30),
	BONE_COLOR = Color3.fromRGB(180, 170, 160),
	EYE_COLOR = Color3.fromRGB(255, 20, 20),
	EYE_RAGE_COLOR = Color3.fromRGB(255, 255, 50),
	EYE_INNER = Color3.fromRGB(255, 150, 100),
	MOUTH_COLOR = Color3.fromRGB(120, 20, 30),
	MOUTH_INSIDE = Color3.fromRGB(40, 5, 10),
	TEETH_COLOR = Color3.fromRGB(200, 190, 170),
	CLAW_COLOR = Color3.fromRGB(30, 5, 10),
	CLAW_TIP = Color3.fromRGB(60, 10, 15),
	VEIN_COLOR = Color3.fromRGB(80, 20, 30),
	AURA_COLOR = Color3.fromRGB(20, 0, 5),
	RAGE_COLOR = Color3.fromRGB(255, 50, 0),

	-- DIMENSIONS - Properly proportioned titan
	TOTAL_HEIGHT = 12,
	TORSO_SIZE = Vector3.new(4.5, 6.0, 2.8),
	CHEST_SIZE = Vector3.new(5.0, 3.5, 3.2),
	ABDOMEN_SIZE = Vector3.new(3.8, 2.5, 2.4),
	HEAD_SIZE = Vector3.new(2.8, 3.2, 2.6),
	NECK_SIZE = Vector3.new(1.2, 1.5, 1.2),

	-- ARM DIMENSIONS
	SHOULDER_SIZE = Vector3.new(1.8, 1.5, 1.5),
	UPPER_ARM_SIZE = Vector3.new(1.4, 4.5, 1.4),
	LOWER_ARM_SIZE = Vector3.new(1.2, 4.0, 1.2),
	HAND_SIZE = Vector3.new(2.0, 2.5, 0.8),
	CLAW_LENGTH = 1.8,

	-- LEG DIMENSIONS
	HIP_SIZE = Vector3.new(1.5, 1.2, 1.5),
	UPPER_LEG_SIZE = Vector3.new(1.8, 4.0, 1.8),
	LOWER_LEG_SIZE = Vector3.new(1.4, 3.5, 1.4),
	FOOT_SIZE = Vector3.new(2.0, 0.8, 3.0),

	-- ANIMATION
	WALK_SPEED = 6,
	LEG_SWING = 25,
	ARM_SWAY = 15,
	BREATH_SPEED = 0.8,
	TWITCH_CHANCE = 0.08,

	-- ATTACK TIMINGS
	ATTACK_WINDUP = 0.25,
	ATTACK_SWING = 0.12,
	ATTACK_RECOVERY = 0.3,
	DOUBLE_SWIPE_DELAY = 0.18,

	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

local function IsInLobby(x)
	return x >= SCREAMER_CONFIG.LOBBY_START_X and x <= SCREAMER_CONFIG.LOBBY_END_X
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
-- CREATE SCREAMER NPC
-- -------------------------------------------------------------------------------

local function CreateScreamerNPC(spawnPosition, triggerPlayer, side, zDir, doorFrameInfo)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "ScreamerEntity"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "ScreamerNPC"
	npcModel.Parent = npcFolder

	local groundY = 0.5
	local HEIGHT = SCREAMER_CONFIG.TOTAL_HEIGHT

	-- ---------------------------------------------------------------------------
	-- PELVIS / HIP CORE (Base of body)
	-- ---------------------------------------------------------------------------

	local pelvis = CreatePart(
		"Pelvis",
		Vector3.new(3.5, 1.8, 2.2),
		SCREAMER_CONFIG.BODY_PRIMARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(pelvis, Enum.MeshType.Sphere, Vector3.new(1, 0.8, 1))

	-- ---------------------------------------------------------------------------
	-- ABDOMEN (Lower torso)
	-- ---------------------------------------------------------------------------

	local abdomen = CreatePart(
		"Abdomen",
		SCREAMER_CONFIG.ABDOMEN_SIZE,
		SCREAMER_CONFIG.BODY_SECONDARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(abdomen, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 0.9))

	-- Spine bumps (visible through skin)
	local spineBumps = {}
	for i = 1, 4 do
		local bump = CreatePart(
			"SpineBump" ..i,
			Vector3.new(0.4, 0.3, 0.4),
			SCREAMER_CONFIG.BONE_COLOR,
			Enum.Material.SmoothPlastic,
			0.3,
			npcModel
		)
		CreateMesh(bump, Enum.MeshType.Sphere)
		table.insert(spineBumps, bump)
	end

	-- ---------------------------------------------------------------------------
	-- CHEST (Upper torso - largest section)
	-- ---------------------------------------------------------------------------

	local chest = CreatePart(
		"Chest",
		SCREAMER_CONFIG.CHEST_SIZE,
		SCREAMER_CONFIG.BODY_PRIMARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	chest.CanCollide = true
	CreateMesh(chest, Enum.MeshType.Sphere, Vector3.new(1, 1.1, 0.85))

	-- Rib cage details
	local ribs = {}
	for i = 1, 6 do
		local side = i <= 3 and -1 or 1
		local ribIndex = i <= 3 and i or (i - 3)

		local rib = CreatePart(
			"Rib" ..i,
			Vector3.new(0.2, 0.15, 1.2 - ribIndex * 0.15),
			SCREAMER_CONFIG.BONE_COLOR,
			Enum.Material.SmoothPlastic,
			0.4,
			npcModel
		)
		CreateMesh(rib, Enum.MeshType.Sphere, Vector3.new(1, 1, 2))

		table.insert(ribs, {part = rib, side = side, index = ribIndex})
	end

	-- Pectoral muscles
	local pectorals = {}
	for i = 1, 2 do
		local pec = CreatePart(
			"Pectoral" ..i,
			Vector3.new(1.8, 1.2, 0.8),
			SCREAMER_CONFIG.FLESH_COLOR,
			Enum.Material.Slate,
			0.1,
			npcModel
		)
		CreateMesh(pec, Enum.MeshType.Sphere, Vector3.new(1, 0.8, 0.6))
		table.insert(pectorals, {part = pec, side = i == 1 and -1 or 1})
	end

	-- ---------------------------------------------------------------------------
	-- NECK (Thick muscular neck)
	-- ---------------------------------------------------------------------------

	local neck = CreatePart(
		"Neck",
		SCREAMER_CONFIG.NECK_SIZE,
		SCREAMER_CONFIG.BODY_SECONDARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(neck, Enum.MeshType.Cylinder)

	-- Neck tendons
	local tendons = {}
	for i = 1, 4 do
		local tendon = CreatePart(
			"Tendon" ..i,
			Vector3.new(0.15, 1.8, 0.15),
			SCREAMER_CONFIG.FLESH_COLOR,
			Enum.Material.Slate,
			0.2,
			npcModel
		)
		CreateMesh(tendon, Enum.MeshType.Cylinder)
		table.insert(tendons, {part = tendon, angle = (i / 4) * math.pi * 2})
	end

	-- ---------------------------------------------------------------------------
	-- HEAD (Elongated horror head)
	-- ---------------------------------------------------------------------------

	local headMain = CreatePart(
		"HeadMain",
		SCREAMER_CONFIG.HEAD_SIZE,
		SCREAMER_CONFIG.BODY_PRIMARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(headMain, Enum.MeshType.Sphere, Vector3.new(1, 1.15, 1))
	

	-- Skull ridges
	local skullRidges = {}
	for i = 1, 3 do
		local ridge = CreatePart(
			"SkullRidge" ..i,
			Vector3.new(0.3, 0.2, 1.5 - i * 0.2),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(ridge, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1))
		table.insert(skullRidges, ridge)
	end

	-- Brow ridge
	local browRidge = CreatePart(
		"BrowRidge",
		Vector3.new(2.2, 0.4, 0.6),
		SCREAMER_CONFIG.BODY_ACCENT,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(browRidge, Enum.MeshType.Sphere, Vector3.new(1, 0.6, 0.8))

	-- ---------------------------------------------------------------------------
	-- EYES (Sunken glowing eyes)
	-- ---------------------------------------------------------------------------

	local eyes = {}
	for i = 1, 2 do
		local eyeSide = i == 1 and -1 or 1

		-- Eye socket (deep recess)
		local eyeSocket = CreatePart(
			"EyeSocket" ..i,
			Vector3.new(0.7, 0.6, 0.4),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(eyeSocket, Enum.MeshType.Sphere)

		-- Eye void (darkness inside socket)
		local eyeVoid = CreatePart(
			"EyeVoid" ..i,
			Vector3.new(0.55, 0.45, 0.25),
			Color3.new(0, 0, 0),
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(eyeVoid, Enum.MeshType.Sphere)

		-- Eye glow (main)
		local eyeGlow = CreatePart(
			"EyeGlow" ..i,
			Vector3.new(0.45, 0.5, 0.15),
			SCREAMER_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyeGlow, Enum.MeshType.Sphere)

		-- Eye pupil (slit)
		local eyePupil = CreatePart(
			"EyePupil" ..i,
			Vector3.new(0.08, 0.35, 0.08),
			SCREAMER_CONFIG.EYE_INNER,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(eyePupil, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.5))

		local eyeLight = CreateGlow(eyeGlow, SCREAMER_CONFIG.EYE_COLOR, 6, 20, true)

		-- Eye vein details
		local eyeVeins = {}
		for v = 1, 3 do
			local vein = CreatePart(
				"EyeVein" ..i .."_" ..v,
				Vector3.new(0.05, 0.3, 0.05),
				SCREAMER_CONFIG.VEIN_COLOR,
				Enum.Material.SmoothPlastic,
				0.3,
				npcModel
			)
			table.insert(eyeVeins, vein)
		end

		table.insert(eyes, {
			socket = eyeSocket,
			void = eyeVoid,
			glow = eyeGlow,
			pupil = eyePupil,
			light = eyeLight,
			veins = eyeVeins,
			side = eyeSide,
			baseBrightness = 6
		})
	end

	-- ---------------------------------------------------------------------------
	-- MOUTH (Massive gaping maw)
	-- ---------------------------------------------------------------------------

	-- Upper jaw
	local upperJaw = CreatePart(
		"UpperJaw",
		Vector3.new(2.0, 0.8, 1.2),
		SCREAMER_CONFIG.BODY_PRIMARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(upperJaw, Enum.MeshType.Sphere, Vector3.new(1, 0.6, 1))

	-- Lower jaw (moves)
	local lowerJaw = CreatePart(
		"LowerJaw",
		Vector3.new(1.8, 0.7, 1.0),
		SCREAMER_CONFIG.BODY_PRIMARY,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(lowerJaw, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1))

	-- Mouth interior (dark void)
	local mouthInterior = CreatePart(
		"MouthInterior",
		Vector3.new(1.6, 1.0, 0.8),
		SCREAMER_CONFIG.MOUTH_INSIDE,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(mouthInterior, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.6))

	-- Throat glow (when screaming)
	local throatGlow = CreatePart(
		"ThroatGlow",
		Vector3.new(0.8, 0.8, 0.5),
		SCREAMER_CONFIG.MOUTH_COLOR,
		Enum.Material.Neon,
		0.8,
		npcModel
	)
	CreateMesh(throatGlow, Enum.MeshType.Sphere)
	local throatLight = CreateGlow(throatGlow, SCREAMER_CONFIG.MOUTH_COLOR, 0, 15, false)

	-- Lips
	local upperLip = CreatePart(
		"UpperLip",
		Vector3.new(2.1, 0.25, 0.4),
		SCREAMER_CONFIG.MOUTH_COLOR,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(upperLip, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1))

	local lowerLip = CreatePart(
		"LowerLip",
		Vector3.new(1.9, 0.2, 0.35),
		SCREAMER_CONFIG.MOUTH_COLOR,
		Enum.Material.Slate,
		0,
		npcModel
	)
	CreateMesh(lowerLip, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1))

	-- Teeth
	local teeth = {}
	for i = 1, 12 do
		local isUpper = i <= 6
		local toothIndex = isUpper and i or (i - 6)
		local toothSize = (toothIndex == 1 or toothIndex == 6) and 0.5 or 0.35

		local tooth = CreatePart(
			"Tooth" ..i,
			Vector3.new(0.15, toothSize, 0.12),
			SCREAMER_CONFIG.TEETH_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(tooth, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		table.insert(teeth, {
			part = tooth,
			isUpper = isUpper,
			index = toothIndex,
			baseSize = toothSize
		})
	end

	-- ---------------------------------------------------------------------------
	-- SHOULDERS (Massive shoulder structures)
	-- ---------------------------------------------------------------------------

	local shoulders = {}
	for i = 1, 2 do
		local shoulderSide = i == 1 and -1 or 1

		local shoulderMain = CreatePart(
			"ShoulderMain" ..i,
			SCREAMER_CONFIG.SHOULDER_SIZE,
			SCREAMER_CONFIG.BODY_PRIMARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(shoulderMain, Enum.MeshType.Sphere)

		local shoulderArmor = CreatePart(
			"ShoulderArmor" ..i,
			Vector3.new(2.0, 1.0, 1.8),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(shoulderArmor, Enum.MeshType.Sphere, Vector3.new(1, 0.6, 1))

		table.insert(shoulders, {
			main = shoulderMain,
			armor = shoulderArmor,
			side = shoulderSide
		})
	end

	-- ---------------------------------------------------------------------------
	-- ARMS (Long monstrous arms with claws)
	-- ---------------------------------------------------------------------------

	local arms = {}
	for i = 1, 2 do
		local armSide = i == 1 and -1 or 1

		-- Upper arm
		local upperArm = CreatePart(
			"UpperArm" ..i,
			SCREAMER_CONFIG.UPPER_ARM_SIZE,
			SCREAMER_CONFIG.BODY_SECONDARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(upperArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Elbow joint
		local elbow = CreatePart(
			"Elbow" ..i,
			Vector3.new(0.8, 0.8, 0.8),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(elbow, Enum.MeshType.Sphere)

		-- Lower arm
		local lowerArm = CreatePart(
			"LowerArm" ..i,
			SCREAMER_CONFIG.LOWER_ARM_SIZE,
			SCREAMER_CONFIG.BODY_SECONDARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(lowerArm, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Wrist
		local wrist = CreatePart(
			"Wrist" ..i,
			Vector3.new(0.6, 0.5, 0.6),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(wrist, Enum.MeshType.Sphere)

		-- Hand
		local hand = CreatePart(
			"Hand" ..i,
			SCREAMER_CONFIG.HAND_SIZE,
			SCREAMER_CONFIG.BODY_PRIMARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(hand, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 0.5))

		-- Palm detail
		local palm = CreatePart(
			"Palm" ..i,
			Vector3.new(1.5, 1.8, 0.3),
			SCREAMER_CONFIG.FLESH_COLOR,
			Enum.Material.Slate,
			0.1,
			npcModel
		)

		-- Claws (5 per hand)
		local claws = {}
		for c = 1, 5 do
			-- Finger base
			local fingerBase = CreatePart(
				"FingerBase" ..i .."_" ..c,
				Vector3.new(0.25, 0.6, 0.25),
				SCREAMER_CONFIG.BODY_SECONDARY,
				Enum.Material.Slate,
				0,
				npcModel
			)
			CreateMesh(fingerBase, Enum.MeshType.Sphere, Vector3.new(1, 1.5, 1))

			-- Claw
			local claw = CreatePart(
				"Claw" ..i .."_" ..c,
				Vector3.new(0.15, SCREAMER_CONFIG.CLAW_LENGTH, 0.15),
				SCREAMER_CONFIG.CLAW_COLOR,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(claw, Enum.MeshType.Sphere, Vector3.new(1, 3, 1))

			-- Claw tip
			local clawTip = CreatePart(
				"ClawTip" ..i .."_" ..c,
				Vector3.new(0.08, 0.3, 0.08),
				SCREAMER_CONFIG.CLAW_TIP,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(clawTip, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

			local clawGlow = CreateGlow(claw, SCREAMER_CONFIG.RAGE_COLOR, 0, 4, false)

			table.insert(claws, {
				fingerBase = fingerBase,
				claw = claw,
				tip = clawTip,
				glow = clawGlow,
				index = c
			})
		end

		table.insert(arms, {
			upper = upperArm,
			elbow = elbow,
			lower = lowerArm,
			wrist = wrist,
			hand = hand,
			palm = palm,
			claws = claws,
			side = armSide,
			attackAngle = 0
		})
	end

	-- ---------------------------------------------------------------------------
	-- LEGS (Powerful digitigrade legs)
	-- ---------------------------------------------------------------------------

	local legs = {}
	for i = 1, 2 do
		local legSide = i == 1 and -1 or 1

		-- Hip joint
		local hip = CreatePart(
			"Hip" ..i,
			SCREAMER_CONFIG.HIP_SIZE,
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(hip, Enum.MeshType.Sphere)

		-- Upper leg (thigh)
		local upperLeg = CreatePart(
			"UpperLeg" ..i,
			SCREAMER_CONFIG.UPPER_LEG_SIZE,
			SCREAMER_CONFIG.BODY_SECONDARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(upperLeg, Enum.MeshType.Sphere, Vector3.new(1, 1.8, 1))

		-- Knee
		local knee = CreatePart(
			"Knee" ..i,
			Vector3.new(1.0, 1.0, 1.0),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(knee, Enum.MeshType.Sphere)

		-- Lower leg (shin)
		local lowerLeg = CreatePart(
			"LowerLeg" ..i,
			SCREAMER_CONFIG.LOWER_LEG_SIZE,
			SCREAMER_CONFIG.BODY_SECONDARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(lowerLeg, Enum.MeshType.Sphere, Vector3.new(1, 2, 1))

		-- Ankle
		local ankle = CreatePart(
			"Ankle" ..i,
			Vector3.new(0.7, 0.6, 0.7),
			SCREAMER_CONFIG.BODY_ACCENT,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(ankle, Enum.MeshType.Sphere)

		-- Foot
		local foot = CreatePart(
			"Foot" ..i,
			SCREAMER_CONFIG.FOOT_SIZE,
			SCREAMER_CONFIG.BODY_PRIMARY,
			Enum.Material.Slate,
			0,
			npcModel
		)
		CreateMesh(foot, Enum.MeshType.Sphere, Vector3.new(1, 0.5, 1.5))

		-- Toe claws
		local toeClaws = {}
		for t = 1, 3 do
			local toeClaw = CreatePart(
				"ToeClaw" ..i .."_" ..t,
				Vector3.new(0.12, 0.6, 0.12),
				SCREAMER_CONFIG.CLAW_COLOR,
				Enum.Material.Metal,
				0,
				npcModel
			)
			CreateMesh(toeClaw, Enum.MeshType.Sphere, Vector3.new(1, 2.5, 1))
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
	-- PARTICLE EFFECTS
	-- ---------------------------------------------------------------------------

	-- Dark aura
	local auraEmitter = Instance.new("ParticleEmitter")
	auraEmitter.Texture = "rbxassetid://243098098"
	auraEmitter.Color = ColorSequence.new(SCREAMER_CONFIG.AURA_COLOR)
	auraEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 5),
		NumberSequenceKeypoint.new(1, 8)
	})
	auraEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	auraEmitter.Lifetime = NumberRange.new(1, 2)
	auraEmitter.Rate = 15
	auraEmitter.Speed = NumberRange.new(1, 3)
	auraEmitter.SpreadAngle = Vector2.new(360, 360)
	auraEmitter.RotSpeed = NumberRange.new(-20, 20)
	auraEmitter.Parent = chest

	-- Rage aura (during attack)
	local rageAura = Instance.new("ParticleEmitter")
	rageAura.Texture = "rbxassetid://243098098"
	rageAura.Color = ColorSequence.new(SCREAMER_CONFIG.RAGE_COLOR)
	rageAura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 4),
		NumberSequenceKeypoint.new(1, 6)
	})
	rageAura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	rageAura.Lifetime = NumberRange.new(0.2, 0.5)
	rageAura.Rate = 60
	rageAura.Speed = NumberRange.new(5, 15)
	rageAura.SpreadAngle = Vector2.new(360, 360)
	rageAura.Enabled = false
	rageAura.Parent = chest

	-- Breath smoke
	local breathSmoke = Instance.new("ParticleEmitter")
	breathSmoke.Texture = "rbxassetid://243098098"
	breathSmoke.Color = ColorSequence.new(Color3.fromRGB(40, 40, 50))
	breathSmoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1.5)
	})
	breathSmoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	breathSmoke.Lifetime = NumberRange.new(0.5, 1)
	breathSmoke.Rate = 5
	breathSmoke.Speed = NumberRange.new(2, 4)
	breathSmoke.SpreadAngle = Vector2.new(20, 20)
	breathSmoke.Parent = lowerJaw

	-- ---------------------------------------------------------------------------
	-- ANIMATION STATE
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local npcRotation = zDir > 0 and 0 or math.pi
	local walkTime = 0
	local breathTime = 0
	local armSwayTime = 0
	local isWalking = false
	local mouthOpen = 0
	local twitchOffset = Vector3.new(0, 0, 0)

	-- Attack state
	local isAttacking = false
	local attackPhase = "none"
	local bodyLean = 0
	local headTilt = 0

	-- ---------------------------------------------------------------------------
	-- UPDATE POSITION - Complete animation system
	-- ---------------------------------------------------------------------------

	local function UpdateNPCPosition(x, z, rotY, walking, deltaTime, mouthOpenAmount)
		npcX = x
		npcZ = z
		npcRotation = rotY or npcRotation
		isWalking = walking or false
		mouthOpen = mouthOpenAmount or mouthOpen

		if deltaTime then
			if isWalking then
				walkTime = walkTime + deltaTime * SCREAMER_CONFIG.WALK_SPEED
			end
			breathTime = breathTime + deltaTime * SCREAMER_CONFIG.BREATH_SPEED
			armSwayTime = armSwayTime + deltaTime * 4

			-- Random twitch
			if math.random() < SCREAMER_CONFIG.TWITCH_CHANCE then
				twitchOffset = Vector3.new(
					(math.random() - 0.5) * 0.3,
					(math.random() - 0.5) * 0.2,
					(math.random() - 0.5) * 0.3
				)
			else
				twitchOffset = twitchOffset * 0.85
			end
		end

		-- Base calculations
		local breathScale = 1 + math.sin(breathTime * math.pi * 2) * 0.02
		local walkBob = isWalking and math.sin(walkTime * 2) * 0.2 or 0
		local walkSway = isWalking and math.sin(walkTime) * 0.03 or 0

		-- Height references
		local legHeight = SCREAMER_CONFIG.UPPER_LEG_SIZE.Y + SCREAMER_CONFIG.LOWER_LEG_SIZE.Y * 0.8
		local baseY = groundY + legHeight
		local pelvisY = baseY
		local abdomenY = pelvisY + 1.5
		local chestY = abdomenY + 2.5
		local neckY = chestY + 2.2
		local headY = neckY + 2.0

		local baseCFrame = CFrame.new(x + twitchOffset.X, 0, z + twitchOffset.Z) 
			* CFrame.Angles(walkSway + bodyLean, npcRotation, walkSway * 0.5)

		-- -----------------------------------------------------------------------
		-- PELVIS
		-- -----------------------------------------------------------------------

		pelvis.CFrame = baseCFrame * CFrame.new(0, pelvisY + walkBob, 0)

		-- -----------------------------------------------------------------------
		-- ABDOMEN
		-- -----------------------------------------------------------------------

		abdomen.CFrame = baseCFrame * CFrame.new(0, abdomenY + walkBob, 0)

		-- Spine bumps
		for i, bump in ipairs(spineBumps) do
			local bumpY = abdomenY - 0.5 + (i - 1) * 0.5
			bump.CFrame = baseCFrame * CFrame.new(0, bumpY + walkBob, 1.0)
		end

		-- -----------------------------------------------------------------------
		-- CHEST
		-- -----------------------------------------------------------------------

		local chestBreath = breathScale
		chest.CFrame = baseCFrame * CFrame.new(0, chestY + walkBob, 0)
		chest.Size = SCREAMER_CONFIG.CHEST_SIZE * Vector3.new(chestBreath, 1, chestBreath)

		-- Ribs
		for _, ribData in ipairs(ribs) do
			local ribX = ribData.side * 1.8
			local ribY = chestY + 0.8 - ribData.index * 0.6
			ribData.part.CFrame = baseCFrame * CFrame.new(ribX, ribY + walkBob, -0.8)
				* CFrame.Angles(0, ribData.side * math.rad(30), ribData.side * math.rad(20))
		end

		-- Pectorals
		for _, pecData in ipairs(pectorals) do
			local pecX = pecData.side * 1.2
			pecData.part.CFrame = baseCFrame * CFrame.new(pecX, chestY + 0.5 + walkBob, -1.2)
		end

		-- -----------------------------------------------------------------------
		-- NECK & TENDONS
		-- -----------------------------------------------------------------------

		local neckTilt = headTilt * 0.5
		neck.CFrame = baseCFrame * CFrame.new(0, neckY + walkBob, -0.3)
			* CFrame.Angles(math.rad(90) + neckTilt, 0, 0)

		for _, tendonData in ipairs(tendons) do
			local tX = math.cos(tendonData.angle) * 0.5
			local tZ = math.sin(tendonData.angle) * 0.5
			tendonData.part.CFrame = baseCFrame * CFrame.new(tX, neckY + walkBob, tZ - 0.3)
				* CFrame.Angles(math.rad(90) + neckTilt, 0, 0)
		end

		-- -----------------------------------------------------------------------
		-- HEAD
		-- -----------------------------------------------------------------------

		local headBob = math.sin(walkTime * 0.8) * 0.08
		local headCFrame = baseCFrame * CFrame.new(twitchOffset.X * 0.5, headY + walkBob + headBob, -0.5)
			* CFrame.Angles(headTilt + twitchOffset.Y, twitchOffset.Z, 0)

		headMain.CFrame = headCFrame

		-- Skull ridges
		for i, ridge in ipairs(skullRidges) do
			ridge.CFrame = headCFrame * CFrame.new(0, 1.2 - i * 0.3, -0.2 + i * 0.15)
		end

		-- Brow ridge
		browRidge.CFrame = headCFrame * CFrame.new(0, 0.6, -1.0)

		-- -----------------------------------------------------------------------
		-- EYES
		-- -----------------------------------------------------------------------

		for _, eyeData in ipairs(eyes) do
			local eyeX = eyeData.side * 0.7
			local eyeY = 0.4

			eyeData.socket.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -1.1)
			eyeData.void.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -1.15)
			eyeData.glow.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -1.22)
			eyeData.pupil.CFrame = headCFrame * CFrame.new(eyeX, eyeY, -1.28)

			-- Eye veins
			for v, vein in ipairs(eyeData.veins) do
				local vAngle = (v / 3) * math.pi * 0.6 - math.pi * 0.3
				local vX = eyeX + math.cos(vAngle) * 0.25 * eyeData.side
				local vY = eyeY + math.sin(vAngle) * 0.2
				vein.CFrame = headCFrame * CFrame.new(vX, vY, -1.1)
					* CFrame.Angles(0, 0, vAngle * eyeData.side)
			end

			-- Eye flicker
			if eyeData.light then
				local flicker = eyeData.baseBrightness + math.sin(breathTime * 8) * 1
				if math.random() < 0.02 then
					flicker = flicker + math.random() * 4
				end
				eyeData.light.Brightness = flicker
			end
		end

		-- -----------------------------------------------------------------------
		-- MOUTH
		-- -----------------------------------------------------------------------

		local jawDrop = mouthOpen * 1.2
		local mouthZ = -1.2

		upperJaw.CFrame = headCFrame * CFrame.new(0, -0.2, mouthZ)
		lowerJaw.CFrame = headCFrame * CFrame.new(0, -0.5 - jawDrop, mouthZ + 0.1)
			* CFrame.Angles(mouthOpen * 0.6, 0, 0)

		mouthInterior.CFrame = headCFrame * CFrame.new(0, -0.4 - jawDrop * 0.5, mouthZ + 0.3)
		mouthInterior.Size = Vector3.new(1.6, 0.8 + jawDrop, 0.8)

		throatGlow.CFrame = headCFrame * CFrame.new(0, -0.5 - jawDrop * 0.3, mouthZ + 0.6)
		throatGlow.Transparency = 1 - mouthOpen * 0.7
		throatLight.Brightness = mouthOpen * 8

		upperLip.CFrame = headCFrame * CFrame.new(0, -0.1, mouthZ - 0.3)
		lowerLip.CFrame = headCFrame * CFrame.new(0, -0.7 - jawDrop, mouthZ - 0.2)
			* CFrame.Angles(mouthOpen * 0.3, 0, 0)

		-- Teeth
		for _, toothData in ipairs(teeth) do
			local toothX = (toothData.index - 3.5) * 0.28
			local toothY, toothZ, toothRot

			if toothData.isUpper then
				toothY = -0.15
				toothZ = mouthZ - 0.25
				toothRot = math.rad(180)
			else
				toothY = -0.65 - jawDrop
				toothZ = mouthZ - 0.15
				toothRot = 0
			end

			toothData.part.CFrame = headCFrame * CFrame.new(toothX, toothY, toothZ)
				* CFrame.Angles(toothRot, 0, 0)
			toothData.part.Size = Vector3.new(0.15, toothData.baseSize + mouthOpen * 0.15, 0.12)
		end

		-- -----------------------------------------------------------------------
		-- SHOULDERS
		-- -----------------------------------------------------------------------

		local shoulderY = chestY + 1.2
		for _, shoulderData in ipairs(shoulders) do
			local shoulderX = shoulderData.side * 2.8
			shoulderData.main.CFrame = baseCFrame * CFrame.new(shoulderX, shoulderY + walkBob, 0)
			shoulderData.armor.CFrame = baseCFrame * CFrame.new(shoulderX * 1.1, shoulderY + 0.4 + walkBob, 0)
		end

		-- -----------------------------------------------------------------------
		-- ARMS
		-- -----------------------------------------------------------------------

		local clawsGlowing = isAttacking and attackPhase == "swing"

		for _, armData in ipairs(arms) do
			local armSway = math.sin(armSwayTime + armData.side) * math.rad(SCREAMER_CONFIG.ARM_SWAY)
			local shoulderX = armData.side * 2.8

			-- Shoulder position
			local shoulderPos = baseCFrame * CFrame.new(shoulderX, shoulderY + walkBob, 0)

			-- Upper arm
			local upperAngle = math.rad(20) + armSway + armData.attackAngle * 0.4
			local upperOutward = armData.side * math.rad(25)
			local upperCFrame = shoulderPos
				* CFrame.Angles(upperAngle, upperOutward, armData.side * math.rad(10))
				* CFrame.new(0, -SCREAMER_CONFIG.UPPER_ARM_SIZE.Y * 0.5, 0)

			armData.upper.CFrame = upperCFrame

			-- Elbow
			local elbowPos = upperCFrame * CFrame.new(0, -SCREAMER_CONFIG.UPPER_ARM_SIZE.Y * 0.5, 0)
			armData.elbow.CFrame = CFrame.new(elbowPos.Position)

			-- Lower arm
			local lowerAngle = math.rad(15) + armSway * 0.5 + armData.attackAngle * 0.6
			local lowerCFrame = elbowPos
				* CFrame.Angles(lowerAngle, 0, 0)
				* CFrame.new(0, -SCREAMER_CONFIG.LOWER_ARM_SIZE.Y * 0.5, 0)

			armData.lower.CFrame = lowerCFrame

			-- Wrist
			local wristPos = lowerCFrame * CFrame.new(0, -SCREAMER_CONFIG.LOWER_ARM_SIZE.Y * 0.5, 0)
			armData.wrist.CFrame = CFrame.new(wristPos.Position)

			-- Hand
			local handAngle = math.rad(-10) + armData.attackAngle * 0.2
			local handCFrame = wristPos
				* CFrame.Angles(handAngle, 0, armData.side * math.rad(5))
				* CFrame.new(0, -SCREAMER_CONFIG.HAND_SIZE.Y * 0.5, 0)

			armData.hand.CFrame = handCFrame
			armData.palm.CFrame = handCFrame * CFrame.new(0, 0, -0.2)

			-- Claws
			for _, clawData in ipairs(armData.claws) do
				local clawIndex = clawData.index
				local clawX = (clawIndex - 3) * 0.35
				local clawSpread = (clawIndex - 3) * math.rad(12)
				local clawCurl = math.rad(30) + math.sin(armSwayTime + clawIndex) * math.rad(5)

				-- Finger base
				local fingerCFrame = handCFrame
					* CFrame.new(clawX, -SCREAMER_CONFIG.HAND_SIZE.Y * 0.4, 0)
					* CFrame.Angles(clawCurl, clawSpread, 0)

				clawData.fingerBase.CFrame = fingerCFrame

				-- Claw
				local clawCFrame = fingerCFrame
					* CFrame.new(0, -0.5, 0)
					* CFrame.Angles(math.rad(20), 0, 0)

				clawData.claw.CFrame = clawCFrame * CFrame.new(0, -SCREAMER_CONFIG.CLAW_LENGTH * 0.5, 0)
				clawData.tip.CFrame = clawCFrame * CFrame.new(0, -SCREAMER_CONFIG.CLAW_LENGTH - 0.1, 0)

				-- Claw glow during attack
				if clawData.glow then
					clawData.glow.Brightness = clawsGlowing and 3 or 0
				end
			end
		end

		-- -----------------------------------------------------------------------
		-- LEGS
		-- -----------------------------------------------------------------------

		for _, legData in ipairs(legs) do
			local legPhase = legData.side == -1 and 0 or math.pi
			local legSwing = isWalking and math.sin(walkTime + legPhase) * math.rad(SCREAMER_CONFIG.LEG_SWING) or 0

			local hipX = legData.side * 1.2

			-- Hip
			legData.hip.CFrame = baseCFrame * CFrame.new(hipX, pelvisY - 0.5 + walkBob, 0)

			-- Upper leg
			local upperLegCFrame = baseCFrame
				* CFrame.new(hipX, pelvisY - 0.8 + walkBob, 0)
				* CFrame.Angles(legSwing, 0, legData.side * math.rad(5))
				* CFrame.new(0, -SCREAMER_CONFIG.UPPER_LEG_SIZE.Y * 0.5, 0)

			legData.upper.CFrame = upperLegCFrame

			-- Knee
			local kneePos = upperLegCFrame * CFrame.new(0, -SCREAMER_CONFIG.UPPER_LEG_SIZE.Y * 0.5, 0)
			legData.knee.CFrame = CFrame.new(kneePos.Position)

			-- Lower leg
			local lowerLegAngle = math.rad(-10) - legSwing * 0.5
			local lowerLegCFrame = kneePos
				* CFrame.Angles(lowerLegAngle, 0, 0)
				* CFrame.new(0, -SCREAMER_CONFIG.LOWER_LEG_SIZE.Y * 0.5, 0)

			legData.lower.CFrame = lowerLegCFrame

			-- Ankle
			local anklePos = lowerLegCFrame * CFrame.new(0, -SCREAMER_CONFIG.LOWER_LEG_SIZE.Y * 0.5, 0)
			legData.ankle.CFrame = CFrame.new(anklePos.Position)

			-- Foot
			local footCFrame = anklePos
				* CFrame.Angles(math.rad(60) + legSwing * 0.3, 0, 0)
				* CFrame.new(0, -0.3, 0.8)

			legData.foot.CFrame = footCFrame

			-- Toe claws
			for t, toeClaw in ipairs(legData.toeClaws) do
				local toeX = (t - 2) * 0.5
				toeClaw.CFrame = footCFrame
					* CFrame.new(toeX, -0.2, 1.2)
					* CFrame.Angles(math.rad(-30), 0, 0)
			end
		end
	end

	-- Initial position
	UpdateNPCPosition(npcX, spawnPosition.Z - zDir * 5, npcRotation, false, 0, 0)

	-- ---------------------------------------------------------------------------
	-- SOUNDS
	-- ---------------------------------------------------------------------------

	local ambientGrowl = Instance.new("Sound")
	ambientGrowl.SoundId = "rbxassetid://9114221580"
	ambientGrowl.Volume = 0.3
	ambientGrowl.Looped = true
	ambientGrowl.PlaybackSpeed = 0.3
	ambientGrowl.Parent = chest
	ambientGrowl:Play()

	-- ---------------------------------------------------------------------------
	-- BRUTAL ATTACK ANIMATION
	-- ---------------------------------------------------------------------------

	local function PlayBrutalAttackAnimation(targetPosition)
		if isAttacking then return end
		isAttacking = true
		rageAura.Enabled = true

		-- Store original colors
		local originalEyeColor = SCREAMER_CONFIG.EYE_COLOR

		-- Change eyes to rage color
		for _, eyeData in ipairs(eyes) do
			TweenService:Create(eyeData.glow, TweenInfo.new(0.1), {
				Color = SCREAMER_CONFIG.EYE_RAGE_COLOR
			}):Play()
			if eyeData.light then
				TweenService: Create(eyeData.light, TweenInfo.new(0.1), {
					Color = SCREAMER_CONFIG.EYE_RAGE_COLOR,
					Brightness = 12
				}):Play()
			end
		end

		-- -----------------------------------------------------------------------
		-- FIRST SWIPE - RIGHT ARM
		-- -----------------------------------------------------------------------

		attackPhase = "windup"

		-- Windup
		local windupSteps = 10
		for i = 1, windupSteps do
			local t = i / windupSteps
			arms[2].attackAngle = math.rad(-90) * t
			bodyLean = math.rad(15) * t
			headTilt = math.rad(-12) * t
			mouthOpen = 0.4 * t
			task.wait(SCREAMER_CONFIG.ATTACK_WINDUP / windupSteps)
		end

		-- Roar
		local roarSound = Instance.new("Sound")
		roarSound.SoundId = "rbxassetid://9114221735"
		roarSound.Volume = 2.5
		roarSound.PlaybackSpeed = 0.7
		roarSound.Parent = headMain
		roarSound:Play()

		attackPhase = "swing"

		-- Swing
		local swingSteps = 6
		for i = 1, swingSteps do
			local t = i / swingSteps
			arms[2].attackAngle = math.rad(-90) + math.rad(200) * t
			bodyLean = math.rad(15) - math.rad(30) * t
			headTilt = math.rad(-12) + math.rad(20) * t
			mouthOpen = 0.4 + 0.6 * t
			task.wait(SCREAMER_CONFIG.ATTACK_SWING / swingSteps)
		end

		-- Slash effect
		local slashEffect = CreatePart(
			"SlashEffect",
			Vector3.new(0.1, 0.1, 0.1),
			SCREAMER_CONFIG.RAGE_COLOR,
			Enum.Material.Neon,
			1,
			workspace
		)
		slashEffect.Position = arms[2].hand.Position

		local slashParticles = Instance.new("ParticleEmitter")
		slashParticles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		slashParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.3, 3),
			NumberSequenceKeypoint.new(1, 0)
		})
		slashParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1)
		})
		slashParticles.Lifetime = NumberRange.new(0.15, 0.3)
		slashParticles.Rate = 300
		slashParticles.Speed = NumberRange.new(25, 50)
		slashParticles.SpreadAngle = Vector2.new(40, 40)
		slashParticles.Parent = slashEffect

		Debris:AddItem(slashEffect, 0.4)
		task.wait(0.05)
		slashParticles.Enabled = false

		-- Brief pause
		task.wait(SCREAMER_CONFIG.DOUBLE_SWIPE_DELAY)

		-- -----------------------------------------------------------------------
		-- SECOND SWIPE - LEFT ARM
		-- -----------------------------------------------------------------------

		attackPhase = "windup"

		for i = 1, windupSteps do
			local t = i / windupSteps
			arms[1].attackAngle = math.rad(-90) * t
			arms[2].attackAngle = math.rad(110) * (1 - t * 0.5)
			bodyLean = math.rad(-15) - math.rad(10) * t
			headTilt = math.rad(8) - math.rad(18) * t
			task.wait(SCREAMER_CONFIG.ATTACK_WINDUP / windupSteps * 0.7)
		end

		attackPhase = "swing"

		for i = 1, swingSteps do
			local t = i / swingSteps
			arms[1].attackAngle = math.rad(-90) + math.rad(200) * t
			bodyLean = math.rad(-25) + math.rad(35) * t
			headTilt = math.rad(-10) + math.rad(18) * t
			task.wait(SCREAMER_CONFIG.ATTACK_SWING / swingSteps)
		end

		-- Second slash effect
		local slashEffect2 = CreatePart(
			"SlashEffect2",
			Vector3.new(0.1, 0.1, 0.1),
			SCREAMER_CONFIG.RAGE_COLOR,
			Enum.Material.Neon,
			1,
			workspace
		)
		slashEffect2.Position = arms[1].hand.Position

		local slashParticles2 = Instance.new("ParticleEmitter")
		slashParticles2.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		slashParticles2.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.3, 3),
			NumberSequenceKeypoint.new(1, 0)
		})
		slashParticles2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1)
		})
		slashParticles2.Lifetime = NumberRange.new(0.15, 0.3)
		slashParticles2.Rate = 300
		slashParticles2.Speed = NumberRange.new(25, 50)
		slashParticles2.SpreadAngle = Vector2.new(40, 40)
		slashParticles2.Parent = slashEffect2

		Debris: AddItem(slashEffect2, 0.4)
		task.wait(0.05)
		slashParticles2.Enabled = false

		-- -----------------------------------------------------------------------
		-- RECOVERY
		-- -----------------------------------------------------------------------

		attackPhase = "recovery"

		local recoverySteps = 12
		for i = 1, recoverySteps do
			local t = i / recoverySteps
			arms[1].attackAngle = math.rad(110) * (1 - t)
			arms[2].attackAngle = math.rad(55) * (1 - t)
			bodyLean = math.rad(10) * (1 - t)
			headTilt = math.rad(8) * (1 - t)
			mouthOpen = 1 * (1 - t)
			task.wait(SCREAMER_CONFIG.ATTACK_RECOVERY / recoverySteps)
		end

		-- Reset all values
		arms[1].attackAngle = 0
		arms[2].attackAngle = 0
		bodyLean = 0
		headTilt = 0
		mouthOpen = 0
		attackPhase = "none"

		-- Reset eye colors
		for _, eyeData in ipairs(eyes) do
			TweenService:Create(eyeData.glow, TweenInfo.new(0.2), {
				Color = SCREAMER_CONFIG.EYE_COLOR
			}):Play()
			if eyeData.light then
				TweenService: Create(eyeData.light, TweenInfo.new(0.2), {
					Color = SCREAMER_CONFIG.EYE_COLOR,
					Brightness = eyeData.baseBrightness
				}):Play()
			end
		end

		rageAura.Enabled = false
		isAttacking = false

		Debris:AddItem(roarSound, 3)
	end

	-- ---------------------------------------------------------------------------
	-- DOOR SCREAM ANIMATION
	-- ---------------------------------------------------------------------------

	local function PlayDoorScreamAnimation()
		local doorFaceZ = doorFrameInfo and doorFrameInfo.faceZ or spawnPosition.Z
		local startZ = doorFaceZ - zDir * 6

		-- Approach door
		for t = 0, 1, 0.04 do
			local currentZ = startZ + (doorFaceZ - startZ) * t
			UpdateNPCPosition(npcX, currentZ, npcRotation, true, 0.02, t * 0.3)
			task.wait(0.015)
		end

		-- Scream at door
		local screamSound = Instance.new("Sound")
		screamSound.SoundId = "rbxassetid://9114221735"
		screamSound.Volume = 3
		screamSound.PlaybackSpeed = 0.5
		screamSound.Parent = headMain
		screamSound:Play()

		-- Intense screaming with shake
		local screamStart = tick()
		while tick() - screamStart < 1.5 do
			local shake = (math.random() - 0.5) * 0.4
			UpdateNPCPosition(npcX + shake, doorFaceZ + zDir * 2, npcRotation, false, 0.02, 1)

			-- Flicker eyes intensely
			for _, eyeData in ipairs(eyes) do
				if eyeData.light then
					eyeData.light.Brightness = math.random(8, 18)
				end
			end

			task.wait(0.01)
		end

		-- Reset eye brightness
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				eyeData.light.Brightness = eyeData.baseBrightness
			end
		end

		Debris:AddItem(screamSound, 4)
	end

	-- ---------------------------------------------------------------------------
	-- DEATH EFFECT
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		auraEmitter.Enabled = false
		rageAura.Enabled = false
		breathSmoke.Enabled = false
		ambientGrowl: Stop()

		-- Death roar
		local deathSound = Instance.new("Sound")
		deathSound.SoundId = "rbxassetid://9114221735"
		deathSound.Volume = 2.5
		deathSound.PlaybackSpeed = 0.35
		deathSound.Parent = chest
		deathSound:Play()

		-- Eyes fade
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.5), {
					Brightness = 0
				}):Play()
			end
			TweenService:Create(eyeData.glow, TweenInfo.new(0.5), {
				Color = Color3.fromRGB(30, 10, 10)
			}):Play()
		end

		-- Throat glow fades
		TweenService:Create(throatLight, TweenInfo.new(0.3), {
			Brightness = 0
		}):Play()

		-- Death particles
		local deathParticles = Instance.new("ParticleEmitter")
		deathParticles.Color = ColorSequence.new(Color3.fromRGB(30, 5, 5))
		deathParticles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 4),
			NumberSequenceKeypoint.new(0.5, 8),
			NumberSequenceKeypoint.new(1, 0)
		})
		deathParticles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1)
		})
		deathParticles.Lifetime = NumberRange.new(0.8, 1.5)
		deathParticles.Rate = 100
		deathParticles.Speed = NumberRange.new(8, 20)
		deathParticles.SpreadAngle = Vector2.new(180, 180)
		deathParticles.Parent = chest

		-- Collapse animation
		task.wait(0.2)

		-- All parts fade and sink
		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1,
					Position = part.Position + Vector3.new(0, -2, 0)
				}):Play()
			end
		end

		task.wait(1)
		deathParticles.Enabled = false
		Debris:AddItem(deathSound, 3)
	end

	-- Start entrance animation
	coroutine.wrap(function()
		PlayDoorScreamAnimation()
	end)()

	-- ---------------------------------------------------------------------------
	-- CHASE AND ATTACK AI
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0
	local hasFinishedEntrance = false

	coroutine.wrap(function()
		task.wait(2.0)
		hasFinishedEntrance = true
	end)()

	local function AttackPlayer(player)
		if tick() - lastAttackTime < SCREAMER_CONFIG.ATTACK_COOLDOWN then return end
		if isAttacking then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			-- Play attack animation
			coroutine.wrap(function()
				PlayBrutalAttackAnimation(hrp.Position)
			end)()

			-- Wait for first swing
			task.wait(SCREAMER_CONFIG.ATTACK_WINDUP + SCREAMER_CONFIG.ATTACK_SWING * 0.5)

			-- First hit
			local attackSound = Instance.new("Sound")
			attackSound.SoundId = "rbxassetid://5766332557"
			attackSound.Volume = 1.4
			attackSound.PlaybackSpeed = 0.75
			attackSound.Parent = chest
			attackSound:Play()

			local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < SCREAMER_CONFIG.ATTACK_RANGE + 3 and hum.Health > 0 then
				hum: TakeDamage(SCREAMER_CONFIG.DAMAGE * 0.6)

				-- Hit effect
				local hitEffect = CreatePart(
					"HitEffect",
					Vector3.new(1, 1, 1),
					SCREAMER_CONFIG.RAGE_COLOR,
					Enum.Material.Neon,
					0.2,
					workspace
				)
				hitEffect.Shape = Enum.PartType.Ball
				hitEffect.Position = hrp.Position

				TweenService:Create(hitEffect, TweenInfo.new(0.3), {
					Size = Vector3.new(6, 6, 6),
					Transparency = 1
				}):Play()

				-- Blood effect
				local bloodBurst = Instance.new("ParticleEmitter")
				bloodBurst.Color = ColorSequence.new(Color3.fromRGB(150, 0, 0))
				bloodBurst.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.4),
					NumberSequenceKeypoint.new(1, 0)
				})
				bloodBurst.Transparency = NumberSequence.new(0)
				bloodBurst.Lifetime = NumberRange.new(0.2, 0.5)
				bloodBurst.Rate = 150
				bloodBurst.Speed = NumberRange.new(12, 25)
				bloodBurst.SpreadAngle = Vector2.new(180, 180)
				bloodBurst.Parent = hitEffect

				task.wait(0.08)
				bloodBurst.Enabled = false
				Debris:AddItem(hitEffect, 0.5)
			end

			-- Wait for second swing
			task.wait(SCREAMER_CONFIG.DOUBLE_SWIPE_DELAY + SCREAMER_CONFIG.ATTACK_WINDUP * 0.7 + SCREAMER_CONFIG.ATTACK_SWING * 0.5)

			-- Second hit
			dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < SCREAMER_CONFIG.ATTACK_RANGE + 3 and hum.Health > 0 then
				hum:TakeDamage(SCREAMER_CONFIG.DAMAGE * 0.4)

				-- Knockback
				local pushDir = (hrp.Position - Vector3.new(npcX, hrp.Position.Y, npcZ)).Unit
				hrp.AssemblyLinearVelocity = pushDir * 80 + Vector3.new(0, 50, 0)

				-- Second hit effect
				local hitEffect2 = CreatePart(
					"HitEffect2",
					Vector3.new(1, 1, 1),
					Color3.fromRGB(255, 150, 0),
					Enum.Material.Neon,
					0.2,
					workspace
				)
				hitEffect2.Shape = Enum.PartType.Ball
				hitEffect2.Position = hrp.Position

				TweenService:Create(hitEffect2, TweenInfo.new(0.4), {
					Size = Vector3.new(8, 8, 8),
					Transparency = 1
				}):Play()

				Debris:AddItem(hitEffect2, 0.5)
			end

			Debris:AddItem(attackSound, 2)
		end
	end

	-- Main chase loop
	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		-- SCREAMER usa "chest" como parte principal, NO "thorax"
		if not isAlive or not chest or not chest.Parent then
			if chaseConnection then chaseConnection:Disconnect() end
			return
		end

		-- ----------------???------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------------------------------------
		if npcModel: GetAttribute("Stunned") then
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt, 0)
			return
		end
		-- -----------------------------------------------------------------------

		if not hasFinishedEntrance then return end

		-- Check if in lobby (death zone)
		if IsInLobby(npcX) then
			isAlive = false
			if chaseConnection then chaseConnection:Disconnect() end
			PlayDeathEffect()
			task.wait(1.2)
			if npcFolder and npcFolder.Parent then
				npcFolder:Destroy()
			end
			return
		end

		-- Find nearest player
		local nearestPlayer, nearestDist = nil, SCREAMER_CONFIG.DETECTION_RANGE
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
					if dist < nearestDist and not IsInLobby(hrp.Position.X) then
						nearestDist = dist
						nearestPlayer = player
					end
				end
			end
		end

		if nearestPlayer then
			local char = nearestPlayer.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")

			if hrp then
				local direction = Vector3.new(hrp.Position. X - npcX, 0, hrp.Position.Z - npcZ)

				if direction. Magnitude > 0.5 then
					local lookAngle = math.atan2(-direction.X, -direction.Z)

					if nearestDist > SCREAMER_CONFIG. ATTACK_RANGE then
						local moveDir = direction. Unit
						local newX = npcX + moveDir.X * SCREAMER_CONFIG.SPEED * dt
						local newZ = npcZ + moveDir.Z * SCREAMER_CONFIG.SPEED * dt

						if not IsInLobby(newX) then
							UpdateNPCPosition(newX, newZ, lookAngle, true, dt, 0.3)
						else
							UpdateNPCPosition(npcX, npcZ, lookAngle, false, dt, 0.3)
						end
					else
						UpdateNPCPosition(npcX, npcZ, lookAngle, false, dt, 0.5)
						AttackPlayer(nearestPlayer)
					end
				else
					UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt, 0)
				end
			else
				UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt, 0)
			end
		else
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt, 0)
		end
	end)
	-- Random growl sounds
	coroutine.wrap(function()
		while isAlive and chest and chest.Parent do
			task.wait(math.random(5, 12))
			if isAlive and chest and chest.Parent and not isAttacking then
				local growl = Instance.new("Sound")
				growl.SoundId = "rbxassetid://9114221580"
				growl.Volume = 0.5
				growl.PlaybackSpeed = 0.4 + math.random() * 0.3
				growl.Parent = chest
				growl:Play()
				Debris:AddItem(growl, 4)
			end
		end
	end)()

	-- Lifetime
	coroutine.wrap(function()
		task.wait(SCREAMER_CONFIG.LIFETIME)
		if npcFolder and npcFolder.Parent and isAlive then
			isAlive = false
			PlayDeathEffect()
			task.wait(1.2)
			if npcFolder then npcFolder:Destroy() end
		end
	end)()

	-- Cleanup on destroy
	npcFolder.AncestryChanged:Connect(function()
		if not npcFolder.Parent then
			isAlive = false
			ambientGrowl:Stop()
			if chaseConnection then chaseConnection: Disconnect() end
		end
	end)

	return npcFolder
end

-- -------------------------------------------------------------------------------
-- EVENT LISTENER
-- ---------------------------------------------------------------??---------------

if SpawnScreamerEvent then
	SpawnScreamerEvent.Event:Connect(CreateScreamerNPC)
end

print("=== NPC SCREAMER SYSTEM V3 - Enhanced Titan Horror Ready ===")