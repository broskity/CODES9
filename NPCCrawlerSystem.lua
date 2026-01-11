--[[
    +------------------------------------------------------------------------------+
    ¦                         NPC CRAWLER ENTITY SYSTEM                             ¦
    ¦                    VERSIÓN 3 - ENHANCED SPIDER AESTHETICS                     ¦
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnCrawlerEvent = ReplicatedStorage:WaitForChild("SpawnCrawlerEvent", 10)

-- ------------------------------------??------------------------------------------
-- CONFIGURACIÓN DEL CRAWLER
-- -------------------------------------------------------------------------------
local CRAWLER_CONFIG = {
	SPEED = 24,
	DAMAGE = 25,
	ATTACK_COOLDOWN = 0.5,
	ATTACK_RANGE = 6,
	DETECTION_RANGE = 250,
	LIFETIME = 50,
	REWARD_SURVIVAL = 20,

	-- APPEARANCE - Enhanced color palette
	BODY_PRIMARY = Color3.fromRGB(18, 18, 22),
	BODY_SECONDARY = Color3.fromRGB(28, 28, 35),
	BODY_ACCENT = Color3.fromRGB(38, 38, 48),
	CHITIN_COLOR = Color3.fromRGB(12, 12, 15),
	EYE_COLOR = Color3.fromRGB(0, 255, 120),
	EYE_GLOW = Color3.fromRGB(80, 255, 160),
	EYE_INNER = Color3.fromRGB(200, 255, 220),
	LEG_PRIMARY = Color3.fromRGB(15, 15, 18),
	LEG_SECONDARY = Color3.fromRGB(22, 22, 28),
	JOINT_COLOR = Color3.fromRGB(35, 35, 42),
	FANG_COLOR = Color3.fromRGB(45, 45, 40),
	VENOM_COLOR = Color3.fromRGB(100, 255, 150),

	-- BODY DIMENSIONS - Properly proportioned
	ABDOMEN_SIZE = Vector3.new(2.4, 1.6, 3.0),
	THORAX_SIZE = Vector3.new(1.6, 1.2, 1.4),
	HEAD_SIZE = Vector3.new(1.2, 0.9, 1.0),

	-- LEG DIMENSIONS
	LEG_UPPER_LENGTH = 1.6,
	LEG_LOWER_LENGTH = 2.0,
	LEG_THICKNESS = 0.12,

	-- ANIMATION
	WALK_SPEED = 14,
	LEG_SWING_ANGLE = 35,
	BODY_BOB = 0.12,
	BREATH_SPEED = 0.8,

	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

local function IsInLobby(x)
	return x >= CRAWLER_CONFIG.LOBBY_START_X and x <= CRAWLER_CONFIG.LOBBY_END_X
end

-- -------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-- -------------------------------------------------------------------------???-----

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

local function CreateBallPart(name, diameter, color, material, parent)
	local part = CreatePart(name, Vector3.new(diameter, diameter, diameter), color, material, 0, parent)
	part.Shape = Enum.PartType.Ball
	return part
end

-- -------------------------------------------------------------------------------
-- CREATE CRAWLER NPC
-- -------------------------------------------------------------------------------

local function CreateCrawlerNPC(spawnPosition, triggerPlayer, side, zDir)
	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "CrawlerEntity"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "CrawlerNPC"
	npcModel.Parent = npcFolder

	local groundY = 0.5
	local baseHeight = 1.4

	-- ---------------------------------------------------------------------------
	-- ABDOMEN (Back section - largest part)
	-- ---------------------------------------------------------------------------

	local abdomen = CreatePart(
		"Abdomen",
		CRAWLER_CONFIG.ABDOMEN_SIZE,
		CRAWLER_CONFIG.BODY_PRIMARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	abdomen.CanCollide = true
	CreateMesh(abdomen, Enum.MeshType.Sphere, Vector3.new(1, 0.85, 1.1))

	-- Abdomen pattern/markings
	local abdomenMarkings = {}
	for i = 1, 3 do
		local marking = CreatePart(
			"AbdomenMarking" ..i,
			Vector3.new(0.8 - i * 0.15, 0.05, 0.4),
			CRAWLER_CONFIG.BODY_ACCENT,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		table.insert(abdomenMarkings, {part = marking, zOffset = 0.3 + i * 0.5})
	end

	-- Spinnerets (back of abdomen)
	local spinneretLeft = CreatePart(
		"SpinneretLeft",
		Vector3.new(0.15, 0.15, 0.3),
		CRAWLER_CONFIG.CHITIN_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(spinneretLeft, Enum.MeshType.Sphere, Vector3.new(1, 1, 1.5))

	local spinneretRight = CreatePart(
		"SpinneretRight",
		Vector3.new(0.15, 0.15, 0.3),
		CRAWLER_CONFIG.CHITIN_COLOR,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(spinneretRight, Enum.MeshType.Sphere, Vector3.new(1, 1, 1.5))

	-- ---------------------------------------------------------------------------
	-- PEDICEL (Narrow connection between abdomen and thorax)
	-- ---------------------------------------------------------------------------

	local pedicel = CreatePart(
		"Pedicel",
		Vector3.new(0.5, 0.4, 0.4),
		CRAWLER_CONFIG.BODY_SECONDARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(pedicel, Enum.MeshType.Sphere)

	-- ---------------------------------------------------------------------------
	-- THORAX (Middle section - leg attachments)
	-- ---------------------------------------------------------------------------

	local thorax = CreatePart(
		"Thorax",
		CRAWLER_CONFIG.THORAX_SIZE,
		CRAWLER_CONFIG.BODY_SECONDARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(thorax, Enum.MeshType.Sphere, Vector3.new(1, 0.9, 1))

	-- Thorax carapace ridge
	local carapaceRidge = CreatePart(
		"CarapaceRidge",
		Vector3.new(0.3, 0.15, 1.2),
		CRAWLER_CONFIG.BODY_ACCENT,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)

	-- ---------------------------------------------------------------------------
	-- HEAD (Cephalothorax front)
	-- ---------------------------------------------------------------------------

	local head = CreatePart(
		"Head",
		CRAWLER_CONFIG.HEAD_SIZE,
		CRAWLER_CONFIG.BODY_PRIMARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(head, Enum.MeshType.Sphere, Vector3.new(1, 0.95, 1.1))

	-- Head front plate
	local headPlate = CreatePart(
		"HeadPlate",
		Vector3.new(0.9, 0.6, 0.3),
		CRAWLER_CONFIG.BODY_SECONDARY,
		Enum.Material.SmoothPlastic,
		0,
		npcModel
	)
	CreateMesh(headPlate, Enum.MeshType.Sphere, Vector3.new(1, 1, 0.5))

	-- ---------------------------------------------------------------------------
	-- EYES - 8 eyes arranged realistically
	-- ---------------------------------------------------------------------------

	local eyes = {}
	local eyeConfig = {
		-- Anterior Median Eyes (AME) - Main large eyes, front center
		{x = -0.18, y = 0.15, z = -0.48, size = 0.20, brightness = 5, isPrimary = true},
		{x = 0.18, y = 0.15, z = -0.48, size = 0.20, brightness = 5, isPrimary = true},
		-- Anterior Lateral Eyes (ALE) - Medium, outer front
		{x = -0.40, y = 0.20, z = -0.38, size = 0.14, brightness = 3.5, isPrimary = false},
		{x = 0.40, y = 0.20, z = -0.38, size = 0.14, brightness = 3.5, isPrimary = false},
		-- Posterior Median Eyes (PME) - Small, top center
		{x = -0.12, y = 0.35, z = -0.30, size = 0.09, brightness = 2.5, isPrimary = false},
		{x = 0.12, y = 0.35, z = -0.30, size = 0.09, brightness = 2.5, isPrimary = false},
		-- Posterior Lateral Eyes (PLE) - Small, top outer
		{x = -0.35, y = 0.32, z = -0.22, size = 0.08, brightness = 2, isPrimary = false},
		{x = 0.35, y = 0.32, z = -0.22, size = 0.08, brightness = 2, isPrimary = false},
	}

	for i, cfg in ipairs(eyeConfig) do
		-- Eye socket (dark recess)
		local socket = CreatePart(
			"EyeSocket" ..i,
			Vector3.new(cfg.size * 1.3, cfg.size * 1.3, cfg.size * 0.5),
			CRAWLER_CONFIG.CHITIN_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(socket, Enum.MeshType.Sphere)

		-- Eye lens (glowing)
		local lens = CreateBallPart(
			"EyeLens" ..i,
			cfg.size,
			CRAWLER_CONFIG.EYE_COLOR,
			Enum.Material.Neon,
			npcModel
		)

		-- Eye highlight (inner bright spot)
		local highlight = CreateBallPart(
			"EyeHighlight" ..i,
			cfg.size * 0.35,
			CRAWLER_CONFIG.EYE_INNER,
			Enum.Material.Neon,
			npcModel
		)

		-- Point light for glow
		local light = Instance.new("PointLight")
		light.Brightness = cfg.brightness
		light.Color = CRAWLER_CONFIG.EYE_GLOW
		light.Range = 4 + cfg.size * 15
		light.Shadows = cfg.isPrimary
		light.Parent = lens

		table.insert(eyes, {
			socket = socket,
			lens = lens,
			highlight = highlight,
			light = light,
			config = cfg,
			baseBrightness = cfg.brightness
		})
	end

	-- ---------------------------------------------------------------------------
	-- CHELICERAE (Fangs)
	-- ---------------------------------------------------------------------------

	local chelicerae = {}
	for i = 1, 2 do
		local side = i == 1 and -1 or 1

		-- Chelicera base
		local base = CreatePart(
			"CheliceraBase" ..i,
			Vector3.new(0.25, 0.35, 0.3),
			CRAWLER_CONFIG.BODY_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(base, Enum.MeshType.Sphere, Vector3.new(1, 1.2, 1))

		-- Fang
		local fang = CreatePart(
			"Fang" ..i,
			Vector3.new(0.08, 0.4, 0.08),
			CRAWLER_CONFIG.FANG_COLOR,
			Enum.Material.Metal,
			0,
			npcModel
		)
		CreateMesh(fang, Enum.MeshType.Cylinder)

		-- Fang tip (venom)
		local fangTip = CreatePart(
			"FangTip" ..i,
			Vector3.new(0.05, 0.08, 0.05),
			CRAWLER_CONFIG.VENOM_COLOR,
			Enum.Material.Neon,
			0,
			npcModel
		)
		CreateMesh(fangTip, Enum.MeshType.Sphere)

		table.insert(chelicerae, {
			base = base,
			fang = fang,
			tip = fangTip,
			side = side
		})
	end

	-- ---------------------------------------------------------------------------
	-- PEDIPALPS (Small arm-like appendages near mouth)
	-- ---------------------------------------------------------------------------

	local pedipalps = {}
	for i = 1, 2 do
		local side = i == 1 and -1 or 1

		local palpBase = CreatePart(
			"PedipalpBase" ..i,
			Vector3.new(0.12, 0.25, 0.12),
			CRAWLER_CONFIG.LEG_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)

		local palpTip = CreatePart(
			"PedipalpTip" ..i,
			Vector3.new(0.15, 0.2, 0.12),
			CRAWLER_CONFIG.LEG_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			npcModel
		)
		CreateMesh(palpTip, Enum.MeshType.Sphere)

		table.insert(pedipalps, {
			base = palpBase,
			tip = palpTip,
			side = side
		})
	end

	-- ---------------------------------------------------------------------------
	-- LEGS - 8 legs with proper segments (Coxa, Trochanter, Femur, Patella, Tibia, Metatarsus, Tarsus)
	-- ---------------------------------------------------------------------------

	local legs = {}
	local legAttachments = {
		-- Left side (front to back)
		{xOff = -0.65, zOff = -0.35, side = -1, index = 1, length = 1.0},
		{xOff = -0.70, zOff = 0.05, side = -1, index = 2, length = 1.1},
		{xOff = -0.70, zOff = 0.45, side = -1, index = 3, length = 1.1},
		{xOff = -0.60, zOff = 0.80, side = -1, index = 4, length = 0.95},
		-- Right side (front to back)
		{xOff = 0.65, zOff = -0.35, side = 1, index = 5, length = 1.0},
		{xOff = 0.70, zOff = 0.05, side = 1, index = 6, length = 1.1},
		{xOff = 0.70, zOff = 0.45, side = 1, index = 7, length = 1.1},
		{xOff = 0.60, zOff = 0.80, side = 1, index = 8, length = 0.95},
	}

	for _, attach in ipairs(legAttachments) do
		local legFolder = Instance.new("Folder")
		legFolder.Name = "Leg" ..attach.index
		legFolder.Parent = npcModel

		local lengthMult = attach.length

		-- Coxa (hip joint)
		local coxa = CreatePart(
			"Coxa",
			Vector3.new(0.2, 0.2, 0.2),
			CRAWLER_CONFIG.JOINT_COLOR,
			Enum.Material.SmoothPlastic,
			0,
			legFolder
		)
		CreateMesh(coxa, Enum.MeshType.Sphere)

		-- Femur (upper leg - thickest segment)
		local femur = CreatePart(
			"Femur",
			Vector3.new(CRAWLER_CONFIG.LEG_THICKNESS * 1.2, CRAWLER_CONFIG.LEG_UPPER_LENGTH * lengthMult, CRAWLER_CONFIG.LEG_THICKNESS * 1.2),
			CRAWLER_CONFIG.LEG_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			legFolder
		)
		CreateMesh(femur, Enum.MeshType.Cylinder)

		-- Patella (knee joint)
		local patella = CreatePart(
			"Patella",
			Vector3.new(0.18, 0.18, 0.18),
			CRAWLER_CONFIG.JOINT_COLOR,
			Enum.Material.Metal,
			0,
			legFolder
		)
		CreateMesh(patella, Enum.MeshType.Sphere)

		-- Tibia (lower leg)
		local tibia = CreatePart(
			"Tibia",
			Vector3.new(CRAWLER_CONFIG.LEG_THICKNESS, CRAWLER_CONFIG.LEG_LOWER_LENGTH * lengthMult * 0.6, CRAWLER_CONFIG.LEG_THICKNESS),
			CRAWLER_CONFIG.LEG_SECONDARY,
			Enum.Material.SmoothPlastic,
			0,
			legFolder
		)
		CreateMesh(tibia, Enum.MeshType.Cylinder)

		-- Metatarsus (lower-lower leg)
		local metatarsus = CreatePart(
			"Metatarsus",
			Vector3.new(CRAWLER_CONFIG.LEG_THICKNESS * 0.8, CRAWLER_CONFIG.LEG_LOWER_LENGTH * lengthMult * 0.5, CRAWLER_CONFIG.LEG_THICKNESS * 0.8),
			CRAWLER_CONFIG.LEG_PRIMARY,
			Enum.Material.SmoothPlastic,
			0,
			legFolder
		)
		CreateMesh(metatarsus, Enum.MeshType.Cylinder)

		-- Tarsus (foot)
		local tarsus = CreatePart(
			"Tarsus",
			Vector3.new(0.1, 0.25, 0.1),
			CRAWLER_CONFIG.CHITIN_COLOR,
			Enum.Material.Metal,
			0,
			legFolder
		)
		CreateMesh(tarsus, Enum.MeshType.Cylinder)

		-- Claw
		local claw = CreatePart(
			"Claw",
			Vector3.new(0.06, 0.12, 0.06),
			CRAWLER_CONFIG.CHITIN_COLOR,
			Enum.Material.Metal,
			0,
			legFolder
		)
		CreateMesh(claw, Enum.MeshType.Wedge)

		table.insert(legs, {
			folder = legFolder,
			coxa = coxa,
			femur = femur,
			patella = patella,
			tibia = tibia,
			metatarsus = metatarsus,
			tarsus = tarsus,
			claw = claw,
			xOff = attach.xOff,
			zOff = attach.zOff,
			side = attach.side,
			index = attach.index,
			lengthMult = lengthMult
		})
	end

	-- ---------------------------------------------------------------------------
	-- PARTICLE EFFECTS
	-- ---------------------------------------------------------------------------

	-- Subtle green aura
	local auraEmitter = Instance.new("ParticleEmitter")
	auraEmitter.Texture = "rbxassetid://243098098"
	auraEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CRAWLER_CONFIG.EYE_COLOR),
		ColorSequenceKeypoint.new(1, CRAWLER_CONFIG.EYE_GLOW)
	})
	auraEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1.2)
	})
	auraEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(0.5, 0.92),
		NumberSequenceKeypoint.new(1, 1)
	})
	auraEmitter.Lifetime = NumberRange.new(0.4, 0.8)
	auraEmitter.Rate = 6
	auraEmitter.Speed = NumberRange.new(0.3, 1)
	auraEmitter.SpreadAngle = Vector2.new(360, 360)
	auraEmitter.RotSpeed = NumberRange.new(-20, 20)
	auraEmitter.Parent = thorax

	-- Venom drip from fangs (occasional)
	local venomDrip = Instance.new("ParticleEmitter")
	venomDrip.Texture = "rbxassetid://243098098"
	venomDrip.Color = ColorSequence.new(CRAWLER_CONFIG.VENOM_COLOR)
	venomDrip.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.02)
	})
	venomDrip.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	venomDrip.Lifetime = NumberRange.new(0.3, 0.5)
	venomDrip.Rate = 2
	venomDrip.Speed = NumberRange.new(1, 2)
	venomDrip.SpreadAngle = Vector2.new(10, 10)
	venomDrip.Acceleration = Vector3.new(0, -10, 0)
	venomDrip.Parent = chelicerae[1].tip

	-- ---------------------------------------------------------------------------
	-- ANIMATION STATE
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local npcRotation = zDir > 0 and 0 or math.pi
	local walkTime = 0
	local breathTime = 0
	local isWalking = false
	local isAttacking = false
	local currentHeight = baseHeight

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
				walkTime = walkTime + deltaTime * CRAWLER_CONFIG.WALK_SPEED
			end
			breathTime = breathTime + deltaTime * CRAWLER_CONFIG.BREATH_SPEED
		end

		-- Calculate body motion
		local walkBob = isWalking and math.sin(walkTime * 2) * CRAWLER_CONFIG.BODY_BOB or 0
		local breathScale = 1 + math.sin(breathTime * math.pi) * 0.015
		local sway = isWalking and math.sin(walkTime) * 0.03 or 0

		local baseY = groundY + currentHeight + walkBob
		local baseCFrame = CFrame.new(x + sway, baseY, z) * CFrame.Angles(0, npcRotation, 0)

		-- Body tilt when walking
		local tiltAngle = isWalking and math.sin(walkTime * 2) * math.rad(3) or 0
		baseCFrame = baseCFrame * CFrame.Angles(0, 0, tiltAngle)

		-- -----------------------------------------------------------------------
		-- POSITION BODY PARTS (Back to Front, no overlaps)
		-- -----------------------------------------------------------------------

		-- Abdomen (back)
		local abdomenZ = 1.2
		abdomen.CFrame = baseCFrame * CFrame.new(0, 0.1, abdomenZ) 
			* CFrame.Angles(math.rad(5), 0, 0)

		-- Abdomen markings
		for i, marking in ipairs(abdomenMarkings) do
			marking.part.CFrame = abdomen.CFrame * CFrame.new(0, 0.75, -marking.zOffset + 0.5)
		end

		-- Spinnerets
		spinneretLeft.CFrame = abdomen.CFrame * CFrame.new(-0.25, -0.4, 1.3)
		spinneretRight.CFrame = abdomen.CFrame * CFrame.new(0.25, -0.4, 1.3)

		-- Pedicel (connector)
		local pedicelZ = 0.1
		pedicel.CFrame = baseCFrame * CFrame.new(0, -0.1, pedicelZ)

		-- Thorax (middle - leg attachment point)
		local thoraxZ = -0.5
		thorax.CFrame = baseCFrame * CFrame.new(0, 0.05, thoraxZ)

		-- Carapace ridge
		carapaceRidge.CFrame = thorax.CFrame * CFrame.new(0, 0.55, 0)

		-- Head (front)
		local headBob = isWalking and math.sin(walkTime * 2.5) * 0.04 or 0
		local headTilt = math.sin(breathTime * 0.5) * math.rad(2)
		local headZ = -1.3
		head.CFrame = baseCFrame * CFrame.new(0, 0.1 + headBob, headZ) 
			* CFrame.Angles(math.rad(-8) + headTilt, 0, 0)

		-- Head plate
		headPlate.CFrame = head.CFrame * CFrame.new(0, -0.1, -0.35)

		-- -----------------------------------------------------------------------
		-- EYES (on head, properly positioned)
		-- -----------------------------------------------------------------------

		for _, eyeData in ipairs(eyes) do
			local cfg = eyeData.config

			-- Eye look direction (subtle movement)
			local lookX = math.sin(breathTime * 0.3) * 0.01
			local lookY = math.cos(breathTime * 0.4) * 0.008

			eyeData.socket.CFrame = head.CFrame * CFrame.new(cfg.x, cfg.y, cfg.z)
			eyeData.lens.CFrame = head.CFrame * CFrame.new(cfg.x + lookX, cfg.y + lookY, cfg.z - 0.03)
			eyeData.highlight.CFrame = head.CFrame * CFrame.new(cfg.x + lookX + 0.02, cfg.y + lookY + 0.03, cfg.z - 0.06)

			-- Eye pulse effect
			if eyeData.light then
				local pulse = 1 + math.sin(breathTime * 3 + cfg.x * 10) * 0.15
				eyeData.light.Brightness = eyeData.baseBrightness * pulse

				-- Random flicker
				if math.random() < 0.01 then
					eyeData.light.Brightness = eyeData.baseBrightness * 1.8
				end
			end
		end

		-- -----------------------------------------------------------------------
		-- CHELICERAE (Fangs - under head)
		-- -----------------------------------------------------------------------

		local fangOpenAngle = isAttacking and math.rad(50) or (math.sin(breathTime * 2) * math.rad(5) + math.rad(15))

		for _, chel in ipairs(chelicerae) do
			local baseX = chel.side * 0.22
			chel.base.CFrame = head.CFrame * CFrame.new(baseX, -0.35, -0.3) 
				* CFrame.Angles(math.rad(20), chel.side * math.rad(10), 0)

			chel.fang.CFrame = chel.base.CFrame * CFrame.new(0, -0.25, -0.05) 
				* CFrame.Angles(fangOpenAngle, 0, chel.side * math.rad(15))

			chel.tip.CFrame = chel.fang.CFrame * CFrame.new(0, -0.2, 0)
		end

		-- -----------------------------------------------------------------------
		-- PEDIPALPS (Small sensory appendages)
		-- -----------------------------------------------------------------------

		local palpWave = math.sin(breathTime * 2) * math.rad(10)

		for _, palp in ipairs(pedipalps) do
			local palpX = palp.side * 0.35
			palp.base.CFrame = head.CFrame * CFrame.new(palpX, -0.2, -0.45) 
				* CFrame.Angles(math.rad(30) + palpWave, palp.side * math.rad(20), 0)

			palp.tip.CFrame = palp.base.CFrame * CFrame.new(0, -0.2, -0.05) 
				* CFrame.Angles(math.rad(15), 0, 0)
		end

		-- -----------------------------------------------------------------------
		-- LEGS (Complex 8-leg animation)
		-- -----------------------------------------------------------------------

		for _, leg in ipairs(legs) do
			-- Leg phase for walking animation (opposite legs move together)
			local legPhase = ((leg.index - 1) % 4) * (math.pi / 2)
			if leg.index > 4 then
				legPhase = legPhase + math.pi -- Offset right side
			end

			local walkSwing = isWalking and math.sin(walkTime + legPhase) * math.rad(CRAWLER_CONFIG.LEG_SWING_ANGLE) or 0
			local walkLift = isWalking and math.max(0, math.sin(walkTime + legPhase)) * 0.15 or 0

			-- Coxa attachment point on thorax
			local coxaAttach = thorax.CFrame * CFrame.new(leg.xOff * 0.8, 0, leg.zOff * 0.7)

			-- Coxa
			leg.coxa.CFrame = coxaAttach

			-- Femur angles outward and forward/back based on walk
			local femurOutward = math.rad(leg.side * 55)
			local femurForward = math.rad(35) + walkSwing * 0.4
			local femurCFrame = coxaAttach 
				* CFrame.Angles(0, femurOutward, 0)
				* CFrame.Angles(femurForward, 0, 0)
				* CFrame.new(0, -CRAWLER_CONFIG.LEG_UPPER_LENGTH * leg.lengthMult * 0.5, 0)

			leg.femur.CFrame = femurCFrame * CFrame.Angles(0, 0, math.rad(90))

			-- Patella (knee) at end of femur
			local patellaPos = femurCFrame * CFrame.new(0, -CRAWLER_CONFIG.LEG_UPPER_LENGTH * leg.lengthMult * 0.5, 0)
			leg.patella.CFrame = CFrame.new(patellaPos.Position)

			-- Tibia angles down more steeply
			local tibiaAngle = math.rad(-60) - walkSwing * 0.3
			local tibiaCFrame = patellaPos 
				* CFrame.Angles(tibiaAngle, 0, 0)
				* CFrame.new(0, -CRAWLER_CONFIG.LEG_LOWER_LENGTH * leg.lengthMult * 0.3, 0)

			leg.tibia.CFrame = tibiaCFrame * CFrame.Angles(0, 0, math.rad(90))

			-- Metatarsus continues down
			local metaPos = tibiaCFrame * CFrame.new(0, -CRAWLER_CONFIG.LEG_LOWER_LENGTH * leg.lengthMult * 0.3, 0)
			local metaAngle = math.rad(-25)
			local metaCFrame = metaPos 
				* CFrame.Angles(metaAngle, 0, 0)
				* CFrame.new(0, -CRAWLER_CONFIG.LEG_LOWER_LENGTH * leg.lengthMult * 0.25, 0)

			leg.metatarsus.CFrame = metaCFrame * CFrame.Angles(0, 0, math.rad(90))

			-- Tarsus (foot)
			local tarsusPos = metaCFrame * CFrame.new(0, -CRAWLER_CONFIG.LEG_LOWER_LENGTH * leg.lengthMult * 0.25, 0)
			local footY = groundY + 0.1 + walkLift
			local tarsusTarget = Vector3.new(tarsusPos.Position.X, footY, tarsusPos.Position.Z)

			leg.tarsus.CFrame = CFrame.new(tarsusTarget) * CFrame.Angles(math.rad(-70), npcRotation, 0)

			-- Claw
			leg.claw.CFrame = leg.tarsus.CFrame * CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(20), 0, 0)
		end
	end

	-- Initial position
	UpdateNPCPosition(npcX, npcZ, npcRotation, false, 0)

	-- ---------------------------------------------------------------------------
	-- SOUNDS
	-- ---------------------------------------------------------------------------

	local spawnSound = Instance.new("Sound")
	spawnSound.SoundId = "rbxassetid://9114221735"
	spawnSound.Volume = 0.8
	spawnSound.PlaybackSpeed = 1.5
	spawnSound.Parent = thorax
	spawnSound:Play()

	local skitterSound = Instance.new("Sound")
	skitterSound.SoundId = "rbxassetid://9114488653"
	skitterSound.Volume = 0.2
	skitterSound.Looped = true
	skitterSound.PlaybackSpeed = 1.2
	skitterSound.Parent = thorax
	skitterSound:Play()

	local hissSound = Instance.new("Sound")
	hissSound.SoundId = "rbxassetid://9114221580"
	hissSound.Volume = 0.4
	hissSound.PlaybackSpeed = 1.6
	hissSound.Parent = head

	-- ---------------------------------------------------------------------------
	-- ATTACK ANIMATION
	-- ---------------------------------------------------------------------------

	local function PlayAttackAnimation(targetPos)
		if isAttacking then return end
		isAttacking = true

		-- Eyes flash bright
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.08), {
					Brightness = eyeData.baseBrightness * 3
				}):Play()
			end
			TweenService:Create(eyeData.lens, TweenInfo.new(0.08), {
				Color = CRAWLER_CONFIG.EYE_INNER
			}):Play()
		end

		-- Venom drip increases
		venomDrip.Rate = 15

		-- Hiss
		hissSound:Play()

		-- Lunge forward
		local lungeDir = (targetPos - Vector3.new(npcX, 0, npcZ))
		if lungeDir.Magnitude > 0.1 then
			lungeDir = lungeDir.Unit
		else
			lungeDir = Vector3.new(0, 0, -1)
		end

		local startX, startZ = npcX, npcZ
		local lungeDistance = 2.5
		local endX = npcX + lungeDir.X * lungeDistance
		local endZ = npcZ + lungeDir.Z * lungeDistance

		if not IsInLobby(endX) then
			-- Crouch before lunge
			for i = 1, 4 do
				currentHeight = baseHeight - (0.4 * (i / 4))
				task.wait(0.02)
			end

			-- Fast lunge
			for i = 1, 6 do
				local t = i / 6
				local easeT = t * t -- Ease in
				npcX = startX + (endX - startX) * easeT
				npcZ = startZ + (endZ - startZ) * easeT
				currentHeight = baseHeight - 0.4 + math.sin(t * math.pi) * 0.2
				task.wait(0.015)
			end

			-- Return to normal height
			for i = 1, 4 do
				currentHeight = baseHeight - 0.4 + (0.4 * (i / 4))
				task.wait(0.02)
			end
		end

		currentHeight = baseHeight

		-- Reset eyes
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.2), {
					Brightness = eyeData.baseBrightness
				}):Play()
			end
			TweenService: Create(eyeData.lens, TweenInfo.new(0.2), {
				Color = CRAWLER_CONFIG.EYE_COLOR
			}):Play()
		end

		venomDrip.Rate = 2
		isAttacking = false
	end

	-- ---------------------------------------------------------------------------
	-- DEATH EFFECT
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		auraEmitter.Enabled = false
		venomDrip.Enabled = false
		skitterSound:Stop()

		local deathSound = Instance.new("Sound")
		deathSound.SoundId = "rbxassetid://9114221580"
		deathSound.Volume = 1.0
		deathSound.PlaybackSpeed = 0.8
		deathSound.Parent = thorax
		deathSound: Play()

		-- Eyes fade
		for _, eyeData in ipairs(eyes) do
			if eyeData.light then
				TweenService:Create(eyeData.light, TweenInfo.new(0.3), {
					Brightness = 0
				}):Play()
			end
			TweenService:Create(eyeData.lens, TweenInfo.new(0.4), {
				Color = Color3.fromRGB(30, 30, 30),
				Transparency = 0.5
			}):Play()
		end

		-- Legs curl up (death curl)
		for _, leg in ipairs(legs) do
			-- Curl femur upward
			TweenService:Create(leg.femur, TweenInfo.new(0.4), {
				CFrame = leg.femur.CFrame * CFrame.Angles(math.rad(50), 0, 0)
			}):Play()

			-- Curl tibia
			TweenService:Create(leg.tibia, TweenInfo.new(0.35), {
				CFrame = leg.tibia.CFrame * CFrame.Angles(math.rad(70), 0, 0)
			}):Play()

			-- Curl lower segments
			TweenService:Create(leg.metatarsus, TweenInfo.new(0.3), {
				CFrame = leg.metatarsus.CFrame * CFrame.Angles(math.rad(60), 0, 0)
			}):Play()
		end

		-- Body sinks and fades
		task.wait(0.2)

		for _, part in pairs(npcModel:GetDescendants()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.5), {
					Transparency = 1,
					Position = part.Position + Vector3.new(0, -0.5, 0)
				}):Play()
			end
		end

		task.wait(0.6)
		Debris:AddItem(deathSound, 2)
	end

	-- ---------------------------------------------------------------------------
	-- AI BEHAVIOR LOOP
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0

	local function FindNearestPlayer()
		local nearest, nearestDist = nil, CRAWLER_CONFIG.DETECTION_RANGE
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
		if tick() - lastAttackTime < CRAWLER_CONFIG.ATTACK_COOLDOWN then return end
		if isAttacking then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			coroutine.wrap(function()
				PlayAttackAnimation(hrp.Position)
			end)()

			task.wait(0.18)

			local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
			if dist < CRAWLER_CONFIG.ATTACK_RANGE and hum.Health > 0 then
				local attackSound = Instance.new("Sound")
				attackSound.SoundId = "rbxassetid://5766332557"
				attackSound.Volume = 0.6
				attackSound.PlaybackSpeed = 1.5
				attackSound.Parent = thorax
				attackSound:Play()

				hum:TakeDamage(CRAWLER_CONFIG.DAMAGE)

				-- Venom effect (green tint on player)
				local venomEffect = Instance.new("Part")
				venomEffect.Size = Vector3.new(0.3, 0.3, 0.3)
				venomEffect.Shape = Enum.PartType.Ball
				venomEffect.Color = CRAWLER_CONFIG.VENOM_COLOR
				venomEffect.Material = Enum.Material.Neon
				venomEffect.Transparency = 0.5
				venomEffect.Anchored = true
				venomEffect.CanCollide = false
				venomEffect.Position = hrp.Position
				venomEffect.Parent = workspace

				TweenService:Create(venomEffect, TweenInfo.new(0.3), {
					Size = Vector3.new(2, 2, 2),
					Transparency = 1
				}):Play()

				Debris:AddItem(venomEffect, 0.4)
				Debris:AddItem(attackSound, 1)
			end
		end
	end

	-- Main loop
	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		if not isAlive or not thorax or not thorax.Parent then
			if chaseConnection then chaseConnection:Disconnect() end
			return
		end

		-- -----------------------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------------------------------------
		if npcModel:GetAttribute("Stunned") then
			-- Still animate breathing but don't move or attack
			UpdateNPCPosition(npcX, npcZ, npcRotation, false, dt)
			return
		end
		-- -----------------------------------------------------------------------

		if IsInLobby(npcX) then
			-- ...  resto del código igual
			if chaseConnection then chaseConnection:Disconnect() end
			return
		end

		if IsInLobby(npcX) then
			isAlive = false
			if chaseConnection then chaseConnection: Disconnect() end
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
						local lookAngle = math.atan2(-direction.X, -direction.Z)

						if distance > CRAWLER_CONFIG.ATTACK_RANGE then
							local moveDir = direction.Unit
							local newX = npcX + moveDir.X * CRAWLER_CONFIG.SPEED * dt
							local newZ = npcZ + moveDir.Z * CRAWLER_CONFIG.SPEED * dt

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

	-- Random eye blink
	coroutine.wrap(function()
		while isAlive and #eyes > 0 do
			task.wait(math.random(3, 7))
			if isAlive and not isAttacking then
				-- Blink random pair of eyes
				local pairs = {{1, 2}, {3, 4}, {5, 6}, {7, 8}}
				local pair = pairs[math.random(1, #pairs)]

				for _, idx in ipairs(pair) do
					local eyeData = eyes[idx]
					if eyeData and eyeData.lens and eyeData.lens.Parent then
						eyeData.lens.Transparency = 0.7
					end
				end

				task.wait(0.06)

				for _, idx in ipairs(pair) do
					local eyeData = eyes[idx]
					if eyeData and eyeData.lens and eyeData.lens.Parent then
						eyeData.lens.Transparency = 0
					end
				end
			end
		end
	end)()

	-- Random hiss sounds
	coroutine.wrap(function()
		while isAlive and head and head.Parent do
			task.wait(math.random(8, 15))
			if isAlive and head and head.Parent and not isAttacking then
				local randomHiss = Instance.new("Sound")
				randomHiss.SoundId = "rbxassetid://9114221580"
				randomHiss.Volume = 0.2
				randomHiss.PlaybackSpeed = 1.4 + math.random() * 0.4
				randomHiss.Parent = head
				randomHiss:Play()
				Debris:AddItem(randomHiss, 2)
			end
		end
	end)()

	-- Lifetime
	coroutine.wrap(function()
		task.wait(CRAWLER_CONFIG.LIFETIME)
		if npcFolder and npcFolder.Parent and isAlive then
			isAlive = false
			PlayDeathEffect()
			task.wait(0.7)
			if npcFolder then npcFolder:Destroy() end
		end
	end)()

	-- Cleanup
	npcFolder.AncestryChanged:Connect(function()
		if not npcFolder.Parent then
			isAlive = false
			skitterSound:Stop()
			if chaseConnection then chaseConnection: Disconnect() end
		end
	end)

	return npcFolder
end

-- -------------------------------------------------------------------------------
-- EVENT LISTENER
-- -------------------------------------------------------------------------------

if SpawnCrawlerEvent then
	SpawnCrawlerEvent.Event:Connect(function(position, player, side, zDir)
		task.wait(0.3)
		CreateCrawlerNPC(position, player, side, zDir)
	end)
end

print("=== NPC CRAWLER SYSTEM V3 - Enhanced Spider Aesthetics Ready ===")