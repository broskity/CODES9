--[[
    +------------------------------------------------------------------------------+
    �                        NPC WATCHER ENTITY SYSTEM                              �
    �                    VERSI�N 5.0 - HOLOGRAPHIC FLOATING IRIS                    �
    �              IRIS Y PUPILA FLOTANTES FUERA DEL OJO F�SICO                     �
    +------------------------------------------------------------------------------+
]]

local Players = game:GetService("Players")
local RunService = game: GetService("RunService")
local TweenService = game: GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SpawnWatcherEvent = ReplicatedStorage:WaitForChild("SpawnWatcherEvent", 10)

-- -------------------------------------------------------------------------------
-- CONFIGURACI�N DEL WATCHER
-- -------------------------------------------------------------------------------
local WATCHER_CONFIG = {
	-- STATS DE COMBATE
	SPEED = 8,
	DAMAGE = 45,
	ATTACK_COOLDOWN = 3.0,
	ATTACK_RANGE = 28,
	DETECTION_RANGE = 400,
	LIFETIME = 65,
	REWARD_SURVIVAL = 35,

	-- STUN TIMES (Head vs Body differentiation)
	STUN_TIMES = {
		-- Stun en el cuerpo (tiempos cortos)
		BODY_CHARGE_1 = 0.2,  -- Carga baja
		BODY_CHARGE_2 = 0.5,  -- Carga media
		BODY_CHARGE_3 = 1.0,  -- Carga alta
		
		-- Stun en la cabeza (tiempos largos, fáciles de modificar)
		HEAD_CHARGE_1 = 1.5,  -- Carga baja
		HEAD_CHARGE_2 = 2.5,  -- Carga media
		HEAD_CHARGE_3 = 4.0,  -- Carga alta
	},

	-- CONFIGURACI�N DEL RAYO
	BEAM_CHARGE_TIME = 1.5,
	BEAM_DURATION = 0.8,
	PARALYZE_DURATION = 2.0,
	BEAM_WIDTH = 0.8,

	-- TAMA�O DEL OJO
	EYE_SIZE = 5.0,

	-- COLORES DEL OJO F�SICO (NO BRILLA)
	SCLERA_COLOR = Color3.fromRGB(235, 230, 215),
	SCLERA_INFECTED = Color3.fromRGB(180, 160, 140),
	VEIN_COLOR = Color3.fromRGB(120, 20, 30),
	VEIN_PULSE = Color3.fromRGB(200, 50, 50),

	-- COLORES DEL IRIS HOLOGR�FICO FLOTANTE (BRILLA)
	IRIS_OUTER_COLOR = Color3.fromRGB(180, 30, 0),
	IRIS_MAIN_COLOR = Color3.fromRGB(255, 80, 0),
	IRIS_INNER_COLOR = Color3.fromRGB(255, 150, 50),
	IRIS_GLOW_COLOR = Color3.fromRGB(255, 200, 100),

	-- COLORES DE LA PUPILA HOLOGR�FICA (BRILLA)
	PUPIL_CORE_COLOR = Color3.fromRGB(0, 0, 0),
	PUPIL_RING_COLOR = Color3.fromRGB(255, 100, 0),

	-- COLORES DE ATAQUE
	BEAM_COLOR = Color3.fromRGB(255, 60, 0),
	BEAM_CORE = Color3.fromRGB(255, 255, 200),
	CHARGE_COLOR = Color3.fromRGB(255, 150, 50),

	-- COLORES DE AMBIENTE
	AURA_COLOR = Color3.fromRGB(60, 0, 0),
	PARTICLE_COLOR = Color3.fromRGB(150, 30, 30),
	SHADOW_COLOR = Color3.fromRGB(20, 0, 30),

	-- ANIMACI�N
	FLOAT_SPEED = 1.2,
	FLOAT_AMPLITUDE = 0.8,
	PULSE_SPEED = 2.5,
	TENTACLE_WAVE_SPEED = 3,

	-- IRIS FLOTANTE - DISTANCIA FUERA DEL OJO
	IRIS_FLOAT_DISTANCE = 0.6, -- ~20cm fuera del ojo
	IRIS_SIZE = 2.2,
	PUPIL_SIZE = 0.8,
	IRIS_TRACK_SPEED = 8, -- Velocidad de seguimiento al jugador

	-- SAFE ZONE
	LOBBY_START_X = -75,
	LOBBY_END_X = 75,
}

-- -------------------------------------------------------------------------------
-- SONIDOS
-- -------------------------------------------------------------------------------
local WATCHER_SOUNDS = {
	SPAWN = { id = "rbxassetid://9114221735", volume = 1.5, pitch = 0.5 },
	AMBIENT_HUM = { id = "rbxassetid://9112854440", volume = 0.4, pitch = 0.4 },
	HEARTBEAT = { id = "rbxassetid://9113652855", volume = 0.6, pitch = 0.8 },
	WHISPER = { id = "rbxassetid://9114221580", volume = 0.3, pitch = 0.6 },
	CHARGE = { id = "rbxassetid://9114221890", volume = 1.0, pitch = 0.6 },
	BEAM_FIRE = { id = "rbxassetid://5766332557", volume = 1.5, pitch = 0.5 },
	BEAM_HIT = { id = "rbxassetid://9114221735", volume = 1.2, pitch = 0.7 },
	DEATH = { id = "rbxassetid://9114221580", volume = 2.0, pitch = 0.3 },
	BLINK = { id = "rbxassetid://9113652855", volume = 0.4, pitch = 1.2 },
}

-- -------------------------------------------------------------------------------
-- FUNCIONES AUXILIARES
-- -------------------------------------------------------------------------------

local function IsInLobby(x)
	return x >= WATCHER_CONFIG.LOBBY_START_X and x <= WATCHER_CONFIG.LOBBY_END_X
end

local function CreateSound(config, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = config.id
	sound.Volume = config.volume
	sound.PlaybackSpeed = config.pitch
	sound.RollOffMaxDistance = 80
	sound.RollOffMinDistance = 10
	sound.Parent = parent
	return sound
end

local function Lerp(a, b, t)
	return a + (b - a) * t
end

local function LerpColor(c1, c2, t)
	return Color3.new(
		Lerp(c1.R, c2.R, t),
		Lerp(c1.G, c2.G, t),
		Lerp(c1.B, c2.B, t)
	)
end

local function LerpVector3(v1, v2, t)
	return Vector3.new(
		Lerp(v1.X, v2.X, t),
		Lerp(v1.Y, v2.Y, t),
		Lerp(v1.Z, v2.Z, t)
	)
end

-- -------------------------------------------------------------------------------
-- CREAR WATCHER NPC
-- -------------------------------------------------------------------------------

local function CreateWatcherNPC(spawnPosition, triggerPlayer, side, zDir)

	-- ---------------------------------------------------------------------------
	-- ESTRUCTURA DE CARPETAS
	-- ---------------------------------------------------------------------------

	local npcFolder = Instance.new("Folder")
	npcFolder.Name = "WatcherEntity_HolographicV5"
	npcFolder.Parent = workspace

	local npcModel = Instance.new("Model")
	npcModel.Name = "WatcherNPC"
	npcModel.Parent = npcFolder

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = npcFolder

	local groundY = 0.5
	local floatHeight = 5.0

	-- ---------------------------------------------------------------------------
	-- OJO F�SICO - NO BRILLA, ES OPACO Y ORG�NICO
	-- ---------------------------------------------------------------------------

	-- Aura oscura alrededor del ojo
	local auraShell = Instance.new("Part")
	auraShell.Name = "AuraShell"
	auraShell.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 1.5, WATCHER_CONFIG.EYE_SIZE * 1.5, WATCHER_CONFIG.EYE_SIZE * 1.5)
	auraShell.Shape = Enum.PartType.Ball
	auraShell.Color = WATCHER_CONFIG.SHADOW_COLOR
	auraShell.Material = Enum.Material.ForceField
	auraShell.Transparency = 0.9
	auraShell.Anchored = true
	auraShell.CanCollide = false
	auraShell.Parent = npcModel

	-- Part�culas de sombra
	local shadowParticles = Instance.new("ParticleEmitter")
	shadowParticles.Texture = "rbxassetid://243098098"
	shadowParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WATCHER_CONFIG.SHADOW_COLOR),
		ColorSequenceKeypoint.new(1, WATCHER_CONFIG.AURA_COLOR)
	})
	shadowParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	shadowParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})
	shadowParticles.Lifetime = NumberRange.new(1, 2)
	shadowParticles.Rate = 6
	shadowParticles.Speed = NumberRange.new(0.3, 1)
	shadowParticles.SpreadAngle = Vector2.new(360, 360)
	shadowParticles.RotSpeed = NumberRange.new(-60, 60)
	shadowParticles.Parent = auraShell

	-- Globo ocular principal - MATERIAL OPACO, NO NEON
	local eyeball = Instance.new("Part")
	eyeball.Name = "Eyeball"
	eyeball.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE, WATCHER_CONFIG.EYE_SIZE, WATCHER_CONFIG.EYE_SIZE)
	eyeball.Shape = Enum.PartType.Ball
	eyeball.Color = WATCHER_CONFIG.SCLERA_COLOR
	eyeball.Material = Enum.Material.SmoothPlastic -- NO BRILLA
	eyeball.Anchored = true
	eyeball.CanCollide = true
	eyeball.Parent = npcModel

	-- Capa h�meda/brillosa sutil
	local glossLayer = Instance.new("Part")
	glossLayer.Name = "GlossLayer"
	glossLayer.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 1.01, WATCHER_CONFIG.EYE_SIZE * 1.01, WATCHER_CONFIG.EYE_SIZE * 1.01)
	glossLayer.Shape = Enum.PartType.Ball
	glossLayer.Color = Color3.new(1, 1, 1)
	glossLayer.Material = Enum.Material.Glass
	glossLayer.Transparency = 0.97
	glossLayer.Anchored = true
	glossLayer.CanCollide = false
	glossLayer.Parent = npcModel

	-- Marca oscura donde estar�a el iris (en el ojo f�sico)
	local irisSocket = Instance.new("Part")
	irisSocket.Name = "IrisSocket"
	irisSocket.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 0.5, WATCHER_CONFIG.EYE_SIZE * 0.5, 0.1)
	irisSocket.Shape = Enum.PartType.Cylinder
	irisSocket.Color = Color3.fromRGB(40, 20, 20)
	irisSocket.Material = Enum.Material.SmoothPlastic -- NO BRILLA
	irisSocket.Transparency = 0.3
	irisSocket.Anchored = true
	irisSocket.CanCollide = false
	irisSocket.Parent = npcModel

	-- ---------------------------------------------------------------------------
	-- VENAS SANGU�NEAS - PULSANTES
	-- ---------------------------------------------------------------------------

	local veins = {}
	local veinCount = 16

	for i = 1, veinCount do
		local vein = Instance.new("Part")
		vein.Name = "Vein" ..i
		local veinLength = 0.5 + math.random() * 0.7
		local veinThickness = 0.03 + math.random() * 0.04
		vein.Size = Vector3.new(veinThickness, veinThickness, WATCHER_CONFIG.EYE_SIZE * veinLength * 0.45)
		vein.Color = WATCHER_CONFIG.VEIN_COLOR
		vein.Material = Enum.Material.SmoothPlastic
		vein.Transparency = 0.1
		vein.Anchored = true
		vein.CanCollide = false
		vein.Parent = npcModel

		-- Ramificaciones
		local branches = {}
		local branchCount = math.random(1, 3)
		for b = 1, branchCount do
			local branch = Instance.new("Part")
			branch.Name = "VeinBranch" ..i .."_" ..b
			branch.Size = Vector3.new(veinThickness * 0.5, veinThickness * 0.5, WATCHER_CONFIG.EYE_SIZE * 0.12)
			branch.Color = WATCHER_CONFIG.VEIN_COLOR
			branch.Material = Enum.Material.SmoothPlastic
			branch.Transparency = 0.2
			branch.Anchored = true
			branch.CanCollide = false
			branch.Parent = npcModel
			table.insert(branches, {
				part = branch,
				offset = math.random() * 0.7,
				angle = (math.random() - 0.5) * math.pi * 0.5
			})
		end

		table.insert(veins, {
			part = vein,
			branches = branches,
			angle = (i / veinCount) * math.pi * 2 + math.random() * 0.3,
			length = veinLength,
			vertAngle = (math.random() - 0.5) * math.pi * 0.6,
			pulseOffset = math.random() * math.pi * 2,
			thickness = veinThickness
		})
	end

	-- ---------------------------------------------------------------------------
	-- ??? IRIS HOLOGR�FICO FLOTANTE - BRILLA Y SIGUE AL JUGADOR ???
	-- ---------------------------------------------------------------------------

	-- Contenedor invisible para el iris flotante
	local irisAnchor = Instance.new("Part")
	irisAnchor.Name = "IrisAnchor"
	irisAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	irisAnchor.Transparency = 1
	irisAnchor.Anchored = true
	irisAnchor.CanCollide = false
	irisAnchor.Parent = npcModel

	-- Anillo exterior del iris - NEON (BRILLA)
	local irisOuter = Instance.new("Part")
	irisOuter.Name = "IrisOuter"
	irisOuter.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 1.2, WATCHER_CONFIG.IRIS_SIZE * 1.2, 0.08)
	irisOuter.Shape = Enum.PartType.Cylinder
	irisOuter.Color = WATCHER_CONFIG.IRIS_OUTER_COLOR
	irisOuter.Material = Enum.Material.Neon -- �BRILLA! 
	irisOuter.Transparency = 0.1
	irisOuter.Anchored = true
	irisOuter.CanCollide = false
	irisOuter.Parent = npcModel

	-- Iris principal - NEON (BRILLA)
	local irisMain = Instance.new("Part")
	irisMain.Name = "IrisMain"
	irisMain.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE, WATCHER_CONFIG.IRIS_SIZE, 0.12)
	irisMain.Shape = Enum.PartType.Cylinder
	irisMain.Color = WATCHER_CONFIG.IRIS_MAIN_COLOR
	irisMain.Material = Enum.Material.Neon -- �BRILLA!
	irisMain.Transparency = 0
	irisMain.Anchored = true
	irisMain.CanCollide = false
	irisMain.Parent = npcModel

	-- Luz del iris principal
	local irisLight = Instance.new("PointLight")
	irisLight.Name = "IrisLight"
	irisLight.Brightness = 3
	irisLight.Color = WATCHER_CONFIG.IRIS_MAIN_COLOR
	irisLight.Range = 20
	irisLight.Shadows = true
	irisLight.Parent = irisMain

	-- Anillo interior del iris - NEON (BRILLA)
	local irisInner = Instance.new("Part")
	irisInner.Name = "IrisInner"
	irisInner.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 0.7, WATCHER_CONFIG.IRIS_SIZE * 0.7, 0.15)
	irisInner.Shape = Enum.PartType.Cylinder
	irisInner.Color = WATCHER_CONFIG.IRIS_INNER_COLOR
	irisInner.Material = Enum.Material.Neon -- �BRILLA!
	irisInner.Transparency = 0
	irisInner.Anchored = true
	irisInner.CanCollide = false
	irisInner.Parent = npcModel

	-- Resplandor del iris - NEON (BRILLA MUCHO)
	local irisGlow = Instance.new("Part")
	irisGlow.Name = "IrisGlow"
	irisGlow.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 1.5, WATCHER_CONFIG.IRIS_SIZE * 1.5, 0.02)
	irisGlow.Shape = Enum.PartType.Cylinder
	irisGlow.Color = WATCHER_CONFIG.IRIS_GLOW_COLOR
	irisGlow.Material = Enum.Material.Neon
	irisGlow.Transparency = 0.7
	irisGlow.Anchored = true
	irisGlow.CanCollide = false
	irisGlow.Parent = npcModel

	-- ---------------------------------------------------------------------------
	-- ??? PUPILA HOLOGR�FICA FLOTANTE - BRILLA Y SIGUE AL JUGADOR ???
	-- ---------------------------------------------------------------------------

	-- Anillo de la pupila - NEON (BRILLA)
	local pupilRing = Instance.new("Part")
	pupilRing.Name = "PupilRing"
	pupilRing.Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 1.3, WATCHER_CONFIG.PUPIL_SIZE * 1.3, 0.18)
	pupilRing.Shape = Enum.PartType.Cylinder
	pupilRing.Color = WATCHER_CONFIG.PUPIL_RING_COLOR
	pupilRing.Material = Enum.Material.Neon -- �BRILLA!
	pupilRing.Transparency = 0.2
	pupilRing.Anchored = true
	pupilRing.CanCollide = false
	pupilRing.Parent = npcModel

	-- Luz de la pupila
	local pupilLight = Instance.new("PointLight")
	pupilLight.Name = "PupilLight"
	pupilLight.Brightness = 5
	pupilLight.Color = WATCHER_CONFIG.PUPIL_RING_COLOR
	pupilLight.Range = 15
	pupilLight.Shadows = false
	pupilLight.Parent = pupilRing

	-- Pupila central oscura
	local pupilCore = Instance.new("Part")
	pupilCore.Name = "PupilCore"
	pupilCore.Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE, WATCHER_CONFIG.PUPIL_SIZE, 0.2)
	pupilCore.Shape = Enum.PartType.Cylinder
	pupilCore.Color = WATCHER_CONFIG.PUPIL_CORE_COLOR
	pupilCore.Material = Enum.Material.SmoothPlastic -- Negro opaco
	pupilCore.Transparency = 0
	pupilCore.Anchored = true
	pupilCore.CanCollide = false
	pupilCore.Parent = npcModel

	-- Reflejo en la pupila
	local pupilReflection = Instance.new("Part")
	pupilReflection.Name = "PupilReflection"
	pupilReflection.Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 0.25, WATCHER_CONFIG.PUPIL_SIZE * 0.25, 0.22)
	pupilReflection.Shape = Enum.PartType.Cylinder
	pupilReflection.Color = Color3.new(1, 1, 1)
	pupilReflection.Material = Enum.Material.Neon
	pupilReflection.Transparency = 0.5
	pupilReflection.Anchored = true
	pupilReflection.CanCollide = false
	pupilReflection.Parent = npcModel

	-- ---------------------------------------------------------------------------
	-- PART�CULAS HOLOGR�FICAS DEL IRIS
	-- ---------------------------------------------------------------------------

	local irisParticles = Instance.new("ParticleEmitter")
	irisParticles.Name = "IrisHoloParticles"
	irisParticles.Texture = "rbxassetid://243098098"
	irisParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WATCHER_CONFIG.IRIS_GLOW_COLOR),
		ColorSequenceKeypoint.new(0.5, WATCHER_CONFIG.IRIS_MAIN_COLOR),
		ColorSequenceKeypoint.new(1, WATCHER_CONFIG.IRIS_OUTER_COLOR)
	})
	irisParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.15),
		NumberSequenceKeypoint.new(1, 0)
	})
	irisParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	irisParticles.LightEmission = 1
	irisParticles.LightInfluence = 0
	irisParticles.Lifetime = NumberRange.new(0.3, 0.7)
	irisParticles.Rate = 15
	irisParticles.Speed = NumberRange.new(0.2, 0.8)
	irisParticles.SpreadAngle = Vector2.new(360, 360)
	irisParticles.Parent = irisMain

	-- Energ�a flotando entre el ojo y el iris
	local energyBeam = Instance.new("Part")
	energyBeam.Name = "EnergyBeam"
	energyBeam.Size = Vector3.new(0.15, 0.15, WATCHER_CONFIG.IRIS_FLOAT_DISTANCE)
	energyBeam.Color = WATCHER_CONFIG.IRIS_MAIN_COLOR
	energyBeam.Material = Enum.Material.Neon
	energyBeam.Transparency = 0.6
	energyBeam.Anchored = true
	energyBeam.CanCollide = false
	energyBeam.Parent = npcModel

	-- ---------------------------------------------------------------------------
	-- P�RPADOS
	-- ---------------------------------------------------------------------------

	local eyelidTop = Instance.new("Part")
	eyelidTop.Name = "EyelidTop"
	eyelidTop.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 1.1, WATCHER_CONFIG.EYE_SIZE * 0.6, WATCHER_CONFIG.EYE_SIZE * 0.3)
	eyelidTop.Color = WATCHER_CONFIG.SCLERA_INFECTED
	eyelidTop.Material = Enum.Material.SmoothPlastic
	eyelidTop.Anchored = true
	eyelidTop.CanCollide = false
	eyelidTop.Transparency = 1
	eyelidTop.Parent = npcModel

	local eyelidBottom = Instance.new("Part")
	eyelidBottom.Name = "EyelidBottom"
	eyelidBottom.Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 1.1, WATCHER_CONFIG.EYE_SIZE * 0.5, WATCHER_CONFIG.EYE_SIZE * 0.3)
	eyelidBottom.Color = WATCHER_CONFIG.SCLERA_INFECTED
	eyelidBottom.Material = Enum.Material.SmoothPlastic
	eyelidBottom.Anchored = true
	eyelidBottom.CanCollide = false
	eyelidBottom.Transparency = 1
	eyelidBottom.Parent = npcModel

	-- ---------------------------------------------------------------------------
	-- TENT�CULOS
	-- ---------------------------------------------------------------------------

	local tentacles = {}
	local tentacleCount = 8
	local segmentsPerTentacle = 10

	for t = 1, tentacleCount do
		local tentacleFolder = Instance.new("Folder")
		tentacleFolder.Name = "Tentacle" ..t
		tentacleFolder.Parent = npcModel

		local segments = {}
		local baseAngle = (t / tentacleCount) * math.pi * 2
		local tentacleLength = 0.8 + math.random() * 0.4

		for s = 1, segmentsPerTentacle do
			local progress = s / segmentsPerTentacle
			local scale = (1 - progress * 0.7) * tentacleLength

			local segment = Instance.new("Part")
			segment.Name = "Segment" ..s
			segment.Size = Vector3.new(0.3 * scale, 0.6, 0.3 * scale)

			local segmentColor = LerpColor(
				WATCHER_CONFIG.SCLERA_INFECTED,
				WATCHER_CONFIG.VEIN_COLOR,
				progress * 0.8
			)
			segment.Color = segmentColor
			segment.Material = Enum.Material.SmoothPlastic
			segment.Anchored = true
			segment.CanCollide = false
			segment.Parent = tentacleFolder

			table.insert(segments, segment)
		end

		local tip = Instance.new("Part")
		tip.Name = "Tip"
		tip.Size = Vector3.new(0.15, 0.4, 0.15)
		tip.Color = WATCHER_CONFIG.VEIN_COLOR
		tip.Material = Enum.Material.SmoothPlastic
		tip.Anchored = true
		tip.CanCollide = false
		tip.Parent = tentacleFolder

		table.insert(tentacles, {
			folder = tentacleFolder,
			segments = segments,
			tip = tip,
			baseAngle = baseAngle,
			waveOffset = math.random() * math.pi * 2,
			length = tentacleLength,
			swaySpeed = 0.8 + math.random() * 0.4
		})
	end

	-- ---------------------------------------------------------------------------
	-- PART�CULAS DEL OJO
	-- ---------------------------------------------------------------------------

	local horrorParticles = Instance.new("ParticleEmitter")
	horrorParticles.Name = "HorrorParticles"
	horrorParticles.Texture = "rbxassetid://243098098"
	horrorParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WATCHER_CONFIG.PARTICLE_COLOR),
		ColorSequenceKeypoint.new(1, WATCHER_CONFIG.SHADOW_COLOR)
	})
	horrorParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	horrorParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 1)
	})
	horrorParticles.Lifetime = NumberRange.new(1, 2)
	horrorParticles.Rate = 4
	horrorParticles.Speed = NumberRange.new(0.2, 0.8)
	horrorParticles.SpreadAngle = Vector2.new(360, 360)
	horrorParticles.Parent = eyeball

	local dripParticles = Instance.new("ParticleEmitter")
	dripParticles.Name = "BloodDrip"
	dripParticles.Texture = "rbxassetid://243098098"
	dripParticles.Color = ColorSequence.new(WATCHER_CONFIG.VEIN_COLOR)
	dripParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(1, 0.04)
	})
	dripParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.9)
	})
	dripParticles.Lifetime = NumberRange.new(0.8, 1.5)
	dripParticles.Rate = 2
	dripParticles.Speed = NumberRange.new(1, 3)
	dripParticles.SpreadAngle = Vector2.new(5, 5)
	dripParticles.Acceleration = Vector3.new(0, -15, 0)
	dripParticles.EmissionDirection = Enum.NormalId.Bottom
	dripParticles.Parent = eyeball

	-- ---------------------------------------------------------------------------
	-- SONIDOS
	-- ---------------------------------------------------------------------------

	local spawnSound = CreateSound(WATCHER_SOUNDS.SPAWN, eyeball)
	spawnSound: Play()
	Debris:AddItem(spawnSound, 4)

	local humSound = CreateSound(WATCHER_SOUNDS.AMBIENT_HUM, eyeball)
	humSound.Looped = true
	humSound:Play()

	local heartbeatSound = CreateSound(WATCHER_SOUNDS.HEARTBEAT, eyeball)
	heartbeatSound.Looped = true
	heartbeatSound.Volume = 0
	heartbeatSound:Play()

	local whisperSound = CreateSound(WATCHER_SOUNDS.WHISPER, eyeball)
	whisperSound.Looped = true
	whisperSound.Volume = 0
	whisperSound: Play()

	-- ---------------------------------------------------------------------------
	-- ESTADO DE ANIMACI�N
	-- ---------------------------------------------------------------------------

	local npcX = spawnPosition.X
	local npcZ = spawnPosition.Z
	local floatTime = 0
	local pulseTime = 0

	-- Direcci�n actual y objetivo del iris (para seguir al jugador)
	local currentIrisDirection = Vector3.new(0, 0, 1)
	local targetIrisDirection = Vector3.new(0, 0, 1)

	-- Tama�o de pupila din�mico
	local currentPupilScale = 1
	local targetPupilScale = 1

	local isAttacking = false
	local isCharging = false
	local isBlinking = false

	-- ---------------------------------------------------------------------------
	-- ANIMACI�N DE PARPADEO
	-- ---------------------------------------------------------------------------

	local function DoBlink()
		if isBlinking then return end
		isBlinking = true

		local blinkSound = CreateSound(WATCHER_SOUNDS.BLINK, eyeball)
		blinkSound:Play()
		Debris:AddItem(blinkSound, 1)

		-- Ocultar iris y pupila durante parpadeo
		TweenService:Create(irisOuter, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService: Create(irisMain, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(irisInner, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(irisGlow, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(pupilRing, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(pupilCore, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(pupilReflection, TweenInfo.new(0.08), {Transparency = 1}):Play()
		TweenService:Create(energyBeam, TweenInfo.new(0.08), {Transparency = 1}):Play()

		TweenService:Create(eyelidTop, TweenInfo.new(0.08), {Transparency = 0}):Play()
		TweenService: Create(eyelidBottom, TweenInfo.new(0.08), {Transparency = 0}):Play()

		task.wait(0.12)

		TweenService:Create(eyelidTop, TweenInfo.new(0.15), {Transparency = 1}):Play()
		TweenService:Create(eyelidBottom, TweenInfo.new(0.15), {Transparency = 1}):Play()

		-- Mostrar iris y pupila de nuevo
		TweenService:Create(irisOuter, TweenInfo.new(0.15), {Transparency = 0.1}):Play()
		TweenService:Create(irisMain, TweenInfo.new(0.15), {Transparency = 0}):Play()
		TweenService: Create(irisInner, TweenInfo.new(0.15), {Transparency = 0}):Play()
		TweenService: Create(irisGlow, TweenInfo.new(0.15), {Transparency = 0.7}):Play()
		TweenService:Create(pupilRing, TweenInfo.new(0.15), {Transparency = 0.2}):Play()
		TweenService:Create(pupilCore, TweenInfo.new(0.15), {Transparency = 0}):Play()
		TweenService: Create(pupilReflection, TweenInfo.new(0.15), {Transparency = 0.5}):Play()
		TweenService:Create(energyBeam, TweenInfo.new(0.15), {Transparency = 0.6}):Play()

		task.wait(0.2)
		isBlinking = false
	end

	-- ---------------------------------------------------------------???-----------
	-- ACTUALIZAR POSICI�N Y ANIMACI�N
	-- ---------------------------------------------------------------------------

	local function UpdateNPCPosition(x, z, targetPosition, deltaTime)
		npcX = x
		npcZ = z

		if deltaTime then
			floatTime = floatTime + deltaTime * WATCHER_CONFIG.FLOAT_SPEED
			pulseTime = pulseTime + deltaTime * WATCHER_CONFIG.PULSE_SPEED

			-- Interpolar la direcci�n del iris hacia el objetivo
			currentIrisDirection = LerpVector3(
				currentIrisDirection, 
				targetIrisDirection, 
				deltaTime * WATCHER_CONFIG.IRIS_TRACK_SPEED
			).Unit

			-- Interpolar tama�o de pupila
			currentPupilScale = Lerp(currentPupilScale, targetPupilScale, deltaTime * 5)
		end

		-- Posici�n flotante del ojo
		local floatY = groundY + floatHeight 
			+ math.sin(floatTime) * WATCHER_CONFIG.FLOAT_AMPLITUDE
			+ math.sin(floatTime * 1.7) * WATCHER_CONFIG.FLOAT_AMPLITUDE * 0.3

		local wobbleX = math.sin(floatTime * 0.7) * 0.2 + math.sin(floatTime * 1.3) * 0.1
		local wobbleZ = math.cos(floatTime * 0.5) * 0.15 + math.cos(floatTime * 1.1) * 0.08
		local tiltX = math.sin(floatTime * 0.4) * 0.05
		local tiltZ = math.cos(floatTime * 0.6) * 0.05

		local eyePos = Vector3.new(x + wobbleX, floatY, z + wobbleZ)
		local eyeCFrame = CFrame.new(eyePos) * CFrame.Angles(tiltX, 0, tiltZ)

		-- Posicionar el ojo f�sico
		eyeball.CFrame = eyeCFrame
		glossLayer.CFrame = eyeCFrame
		auraShell.CFrame = CFrame.new(eyePos)

		-- Aura pulsante
		local auraPulse = 1 + math.sin(pulseTime) * 0.05
		auraShell.Size = Vector3.new(
			WATCHER_CONFIG.EYE_SIZE * 1.5 * auraPulse,
			WATCHER_CONFIG.EYE_SIZE * 1.5 * auraPulse,
			WATCHER_CONFIG.EYE_SIZE * 1.5 * auraPulse
		)

		-- Actualizar direcci�n objetivo si hay target
		if targetPosition then
			local dirToTarget = (targetPosition - eyePos)
			if dirToTarget.Magnitude > 0.1 then
				targetIrisDirection = dirToTarget.Unit
			end
			targetPupilScale = 1.1 -- Pupila m�s grande cuando mira a alguien
		else
			targetIrisDirection = Vector3.new(0, 0, 1)
			targetPupilScale = 0.9 -- Pupila m�s peque�a en reposo
		end

		-- -----------------------------------------------------------------------
		-- SOCKET DEL IRIS EN EL OJO (marca oscura donde sale el iris)
		-- -----------------------------------------------------------------------

		local eyeRadius = WATCHER_CONFIG.EYE_SIZE * 0.5
		local socketPos = eyePos + currentIrisDirection * eyeRadius * 0.95
		local socketCFrame = CFrame.new(socketPos, socketPos + currentIrisDirection) * CFrame.Angles(0, math.rad(90), 0)
		irisSocket.CFrame = socketCFrame

		-- ------------------------------------??----------------------------------
		-- ??? IRIS HOLOGR�FICO FLOTANTE - SIGUE AL JUGADOR ???
		-- -----------------------------------------------------------------------

		-- Posici�n del iris flotando FUERA del ojo
		local irisFloatPos = eyePos + currentIrisDirection * (eyeRadius + WATCHER_CONFIG.IRIS_FLOAT_DISTANCE)
		local irisCFrame = CFrame.new(irisFloatPos, irisFloatPos + currentIrisDirection) * CFrame.Angles(0, math.rad(90), 0)

		-- Pulsaciones del iris
		local pulse1 = 1 + math.sin(pulseTime * 2) * 0.06
		local pulse2 = 1 + math.sin(pulseTime * 2.5 + 0.5) * 0.08
		local pulse3 = 1 + math.sin(pulseTime * 3 + 1) * 0.1

		-- Posicionar capas del iris (de atr�s hacia adelante)
		local layerOffset = 0.03

		irisGlow.CFrame = irisCFrame * CFrame.new(-layerOffset * 3, 0, 0)
		irisGlow.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 1.5 * pulse1, WATCHER_CONFIG.IRIS_SIZE * 1.5 * pulse1, 0.02)

		irisOuter.CFrame = irisCFrame * CFrame.new(-layerOffset * 2, 0, 0)
		irisOuter.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 1.2 * pulse1, WATCHER_CONFIG.IRIS_SIZE * 1.2 * pulse1, 0.08)

		irisMain.CFrame = irisCFrame * CFrame.new(-layerOffset, 0, 0)
		irisMain.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * pulse2, WATCHER_CONFIG.IRIS_SIZE * pulse2, 0.12)

		irisInner.CFrame = irisCFrame * CFrame.new(0, 0, 0)
		irisInner.Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 0.7 * pulse3, WATCHER_CONFIG.IRIS_SIZE * 0.7 * pulse3, 0.15)

		-- -----------------------------------------------------------------------
		-- ??? PUPILA HOLOGR�FICA FLOTANTE - SIGUE AL JUGADOR ???
		-- -----------------------------------------------------------------------

		-- La pupila est� ligeramente m�s adelante que el iris
		local pupilOffset = layerOffset * 2

		pupilRing.CFrame = irisCFrame * CFrame.new(pupilOffset, 0, 0)
		pupilRing.Size = Vector3.new(
			WATCHER_CONFIG.PUPIL_SIZE * 1.3 * currentPupilScale * pulse2, 
			WATCHER_CONFIG.PUPIL_SIZE * 1.3 * currentPupilScale * pulse2, 
			0.18
		)

		pupilCore.CFrame = irisCFrame * CFrame.new(pupilOffset + layerOffset, 0, 0)
		pupilCore.Size = Vector3.new(
			WATCHER_CONFIG.PUPIL_SIZE * currentPupilScale, 
			WATCHER_CONFIG.PUPIL_SIZE * currentPupilScale, 
			0.2
		)

		-- Reflejo en posici�n ligeramente offset
		local reflectionOffset = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 0.2, WATCHER_CONFIG.PUPIL_SIZE * 0.2, 0)
		pupilReflection.CFrame = irisCFrame * CFrame.new(pupilOffset + layerOffset * 2, 0, 0) * CFrame.new(reflectionOffset)

		-- Anchor para referencia
		irisAnchor.CFrame = irisCFrame

		-- -----------------------------------------------------------------------
		-- RAYO DE ENERG�A ENTRE OJO E IRIS
		-- -----------------------------------------------------------------------

		local beamStart = socketPos
		local beamEnd = irisFloatPos
		local beamCenter = (beamStart + beamEnd) / 2
		local beamLength = (beamEnd - beamStart).Magnitude

		energyBeam.Size = Vector3.new(0.12 + math.sin(pulseTime * 4) * 0.03, 0.12 + math.sin(pulseTime * 4) * 0.03, beamLength)
		energyBeam.CFrame = CFrame.new(beamCenter, beamEnd)

		-- Brillo pulsante de las luces
		irisLight.Brightness = 3 + math.sin(pulseTime * 1.5) * 1
		irisLight.Range = 18 + math.sin(pulseTime * 2) * 4
		pupilLight.Brightness = 5 + math.sin(pulseTime * 2.5) * 2

		-- Colores cambiantes sutiles
		local colorShift = (math.sin(pulseTime * 0.8) + 1) / 2
		irisInner.Color = LerpColor(WATCHER_CONFIG.IRIS_INNER_COLOR, WATCHER_CONFIG.IRIS_GLOW_COLOR, colorShift * 0.4)

		-- -----------------------------------------------------------------------
		-- VENAS PULSANTES
		-- -----------------------------------------------------------------------

		for _, veinData in ipairs(veins) do
			local veinAngle = veinData.angle + floatTime * 0.02
			local radius = WATCHER_CONFIG.EYE_SIZE * 0.48
			local individualPulse = (math.sin(pulseTime * 2 + veinData.pulseOffset) + 1) / 2

			local veinX = math.cos(veinAngle) * math.cos(veinData.vertAngle) * radius
			local veinY = math.sin(veinData.vertAngle) * radius
			local veinZ = math.sin(veinAngle) * math.cos(veinData.vertAngle) * radius

			veinData.part.CFrame = CFrame.new(eyePos + Vector3.new(veinX, veinY, veinZ))
				* CFrame.Angles(veinData.vertAngle, veinAngle, 0)

			veinData.part.Color = LerpColor(WATCHER_CONFIG.VEIN_COLOR, WATCHER_CONFIG.VEIN_PULSE, individualPulse * 0.5)

			local pulseThickness = veinData.thickness * (1 + individualPulse * 0.3)
			veinData.part.Size = Vector3.new(pulseThickness, pulseThickness, veinData.part.Size.Z)

			for _, branch in ipairs(veinData.branches) do
				local branchPos = eyePos + Vector3.new(veinX, veinY, veinZ) * branch.offset
				branch.part.CFrame = CFrame.new(branchPos)
					* CFrame.Angles(veinData.vertAngle + branch.angle, veinAngle, 0)
				branch.part.Color = veinData.part.Color
			end
		end

		-- -----------------------------------------------------------------------
		-- P�RPADOS
		-- -----------------------------------------------------------------------

		eyelidTop.CFrame = CFrame.new(eyePos + Vector3.new(0, WATCHER_CONFIG.EYE_SIZE * 0.35, 0) + currentIrisDirection * WATCHER_CONFIG.EYE_SIZE * 0.2)
		eyelidBottom.CFrame = CFrame.new(eyePos + Vector3.new(0, -WATCHER_CONFIG.EYE_SIZE * 0.3, 0) + currentIrisDirection * WATCHER_CONFIG.EYE_SIZE * 0.2)

		-- -----------------------------------------------------------------------
		-- TENT�CULOS
		-- -----------------------------------------------------------------------

		for _, tentData in ipairs(tentacles) do
			local baseX = eyePos.X + math.cos(tentData.baseAngle) * WATCHER_CONFIG.EYE_SIZE * 0.35
			local baseY = eyePos.Y - WATCHER_CONFIG.EYE_SIZE * 0.45
			local baseZ = eyePos.Z + math.sin(tentData.baseAngle) * WATCHER_CONFIG.EYE_SIZE * 0.35

			for s, segment in ipairs(tentData.segments) do
				local segmentProgress = s / #tentData.segments
				local wavePhase = floatTime * WATCHER_CONFIG.TENTACLE_WAVE_SPEED * tentData.swaySpeed + tentData.waveOffset + s * 0.5

				local swayAmplitude = 0.4 * segmentProgress
				local tentX = baseX + math.sin(wavePhase) * swayAmplitude
				local tentY = baseY - s * 0.55 * tentData.length
				local tentZ = baseZ + math.cos(wavePhase * 0.8) * swayAmplitude * 0.7

				segment.CFrame = CFrame.new(tentX, tentY, tentZ)
					* CFrame.Angles(
						math.sin(wavePhase) * 0.3 * segmentProgress,
						tentData.baseAngle + math.sin(wavePhase * 0.5) * 0.2,
						math.cos(wavePhase * 0.7) * 0.2 * segmentProgress
					)
			end

			local lastSeg = tentData.segments[#tentData.segments]
			if lastSeg and tentData.tip then
				tentData.tip.CFrame = lastSeg.CFrame * CFrame.new(0, -0.5, 0)
			end
		end
	end

	-- Inicializar posici�n
	UpdateNPCPosition(npcX, npcZ, nil, 0)

	-- ---------------------------------------------------------------------------
	-- EFECTOS DE HORROR
	-- ---------------------------------------------------------------------------

	local function UpdateHorrorEffects(nearestDistance)
		if nearestDistance then
			local heartbeatIntensity = math.clamp(1 - (nearestDistance / 30), 0, 1)
			heartbeatSound.Volume = WATCHER_SOUNDS.HEARTBEAT.volume * heartbeatIntensity

			local whisperIntensity = math.clamp(1 - (nearestDistance / 40), 0, 1)
			whisperSound.Volume = WATCHER_SOUNDS.WHISPER.volume * whisperIntensity

			-- Pupila reacciona a la cercan�a
			if nearestDistance < 30 then
				targetPupilScale = 1 + (1 - nearestDistance / 30) * 0.3
			end
		else
			heartbeatSound.Volume = 0
			whisperSound.Volume = 0
		end
	end

	-- ---------------------------------------------------------------------------
	-- ATAQUE - RAYO DEL OJO
	-- ---------------------------------------------------------------------------

	local function PlayAttackAnimation(targetPos)
		if isAttacking or isCharging then return end
		isCharging = true

		DoBlink()
		task.wait(0.3)

		local chargeSound = CreateSound(WATCHER_SOUNDS.CHARGE, eyeball)
		chargeSound:Play()

		-- Pupila se contrae
		TweenService:Create(pupilCore, TweenInfo.new(0.3), {
			Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 0.4, WATCHER_CONFIG.PUPIL_SIZE * 0.4, 0.2)
		}):Play()

		task.wait(0.3)

		-- Pupila se expande
		TweenService:Create(pupilCore, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME - 0.3), {
			Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 1.5, WATCHER_CONFIG.PUPIL_SIZE * 1.5, 0.2)
		}):Play()

		-- Iris se intensifica
		TweenService:Create(irisMain, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
			Color = Color3.fromRGB(255, 200, 100)
		}):Play()

		TweenService:Create(irisInner, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
			Color = Color3.fromRGB(255, 255, 200)
		}):Play()

		TweenService:Create(irisLight, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
			Brightness = 8,
			Range = 35
		}):Play()

		TweenService:Create(pupilLight, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
			Brightness = 10,
			Range = 30
		}):Play()

		TweenService:Create(pupilRing, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
			Color = Color3.fromRGB(255, 255, 150)
		}):Play()

		-- Venas brillan
		for _, veinData in ipairs(veins) do
			TweenService:Create(veinData.part, TweenInfo.new(WATCHER_CONFIG.BEAM_CHARGE_TIME), {
				Color = WATCHER_CONFIG.BEAM_COLOR
			}):Play()
		end

		task.wait(WATCHER_CONFIG.BEAM_CHARGE_TIME)

		isCharging = false
		isAttacking = true

		-- DISPARAR RAYO
		local beamSound = CreateSound(WATCHER_SOUNDS.BEAM_FIRE, eyeball)
		beamSound:Play()

		local beamStart = pupilCore.Position
		local beamDir = (targetPos - beamStart).Unit
		local beamLength = math.min((targetPos - beamStart).Magnitude + 5, WATCHER_CONFIG.ATTACK_RANGE + 10)

		-- Rayo principal
		local beam = Instance.new("Part")
		beam.Name = "EyeBeam"
		beam.Size = Vector3.new(WATCHER_CONFIG.BEAM_WIDTH, WATCHER_CONFIG.BEAM_WIDTH, beamLength)
		beam.Color = WATCHER_CONFIG.BEAM_COLOR
		beam.Material = Enum.Material.Neon
		beam.Transparency = 0
		beam.Anchored = true
		beam.CanCollide = false
		beam.CFrame = CFrame.new(beamStart + beamDir * beamLength / 2, beamStart + beamDir * beamLength)
		beam.Parent = effectsFolder

		-- N�cleo del rayo
		local beamCore = Instance.new("Part")
		beamCore.Name = "BeamCore"
		beamCore.Size = Vector3.new(WATCHER_CONFIG.BEAM_WIDTH * 0.4, WATCHER_CONFIG.BEAM_WIDTH * 0.4, beamLength)
		beamCore.Color = WATCHER_CONFIG.BEAM_CORE
		beamCore.Material = Enum.Material.Neon
		beamCore.Transparency = 0.2
		beamCore.Anchored = true
		beamCore.CanCollide = false
		beamCore.CFrame = beam.CFrame
		beamCore.Parent = effectsFolder

		-- Luz del rayo
		local beamLight = Instance.new("PointLight")
		beamLight.Brightness = 5
		beamLight.Color = WATCHER_CONFIG.BEAM_COLOR
		beamLight.Range = 25
		beamLight.Shadows = false
		beamLight.Parent = beam

		-- Impacto
		local impact = Instance.new("Part")
		impact.Name = "BeamImpact"
		impact.Size = Vector3.new(2, 2, 2)
		impact.Shape = Enum.PartType.Ball
		impact.Color = WATCHER_CONFIG.BEAM_COLOR
		impact.Material = Enum.Material.Neon
		impact.Transparency = 0.3
		impact.Anchored = true
		impact.CanCollide = false
		impact.Position = beamStart + beamDir * beamLength
		impact.Parent = effectsFolder

		TweenService:Create(impact, TweenInfo.new(WATCHER_CONFIG.BEAM_DURATION), {
			Size = Vector3.new(6, 6, 6),
			Transparency = 1
		}):Play()

		task.wait(WATCHER_CONFIG.BEAM_DURATION)

		-- Desvanecer rayo
		TweenService:Create(beam, TweenInfo.new(0.3), {Transparency = 1}):Play()
		TweenService:Create(beamCore, TweenInfo.new(0.3), {Transparency = 1}):Play()
		TweenService:Create(beamLight, TweenInfo.new(0.3), {Brightness = 0}):Play()

		Debris:AddItem(beam, 0.4)
		Debris:AddItem(beamCore, 0.4)
		Debris:AddItem(impact, 0.5)

		-- Resetear visuales
		TweenService:Create(pupilCore, TweenInfo.new(0.5), {
			Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE, WATCHER_CONFIG.PUPIL_SIZE, 0.2)
		}):Play()

		TweenService:Create(irisMain, TweenInfo.new(0.5), {
			Color = WATCHER_CONFIG.IRIS_MAIN_COLOR
		}):Play()

		TweenService:Create(irisInner, TweenInfo.new(0.5), {
			Color = WATCHER_CONFIG.IRIS_INNER_COLOR
		}):Play()

		TweenService: Create(irisLight, TweenInfo.new(0.5), {
			Brightness = 3,
			Range = 20
		}):Play()

		TweenService:Create(pupilLight, TweenInfo.new(0.5), {
			Brightness = 5,
			Range = 15
		}):Play()

		TweenService:Create(pupilRing, TweenInfo.new(0.5), {
			Color = WATCHER_CONFIG.PUPIL_RING_COLOR
		}):Play()

		for _, veinData in ipairs(veins) do
			TweenService:Create(veinData.part, TweenInfo.new(0.5), {
				Color = WATCHER_CONFIG.VEIN_COLOR
			}):Play()
		end

		Debris:AddItem(chargeSound, 3)
		Debris:AddItem(beamSound, 3)

		isAttacking = false
	end

	-- ---------------------------------------------------------------------------
	-- EFECTO DE MUERTE
	-- ---------------------------------------------------------------------------

	local function PlayDeathEffect()
		-- Marcar como muerto inmediatamente para detener el loop de IA
		isAlive = false
		
		-- Desconectar el loop de IA para evitar que siga ejecutándose
		if chaseConnection then
			chaseConnection:Disconnect()
			chaseConnection = nil
		end
		
		-- Desactivar part�culas con verificación de seguridad
		if horrorParticles and horrorParticles.Parent then
			horrorParticles.Enabled = false
		end
		if dripParticles and dripParticles.Parent then
			dripParticles.Enabled = false
		end
		if shadowParticles and shadowParticles.Parent then
			shadowParticles.Enabled = false
		end
		if irisParticles and irisParticles.Parent then
			irisParticles.Enabled = false
		end

		-- Detener sonidos con verificación de seguridad
		if humSound and humSound.Parent then
			humSound:Stop()
		end
		if heartbeatSound and heartbeatSound.Parent then
			heartbeatSound:Stop()
		end
		if whisperSound and whisperSound.Parent then
			whisperSound:Stop()
		end

		-- Crear sonido de muerte solo si el eyeball existe
		local deathSound
		if eyeball and eyeball.Parent then
			deathSound = CreateSound(WATCHER_SOUNDS.DEATH, eyeball)
			deathSound:Play()
		end

		-- El iris explota primero (con verificación de seguridad)
		if irisMain and irisMain.Parent then
			TweenService:Create(irisMain, TweenInfo.new(0.3), {
				Size = Vector3.new(WATCHER_CONFIG.IRIS_SIZE * 2.5, WATCHER_CONFIG.IRIS_SIZE * 2.5, 0.3),
				Color = Color3.new(1, 1, 1)
			}):Play()
		end

		if irisLight and irisLight.Parent then
			TweenService:Create(irisLight, TweenInfo.new(0.3), {
				Brightness = 15,
				Range = 50
			}):Play()
		end

		if pupilCore and pupilCore.Parent then
			TweenService:Create(pupilCore, TweenInfo.new(0.3), {
				Size = Vector3.new(WATCHER_CONFIG.PUPIL_SIZE * 3, WATCHER_CONFIG.PUPIL_SIZE * 3, 0.3),
				Transparency = 0.5
			}):Play()
		end

		if pupilLight and pupilLight.Parent then
			TweenService:Create(pupilLight, TweenInfo.new(0.3), {
				Brightness = 20,
				Range = 40
			}):Play()
		end

		-- El ojo se hincha
		if eyeball and eyeball.Parent then
			TweenService:Create(eyeball, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
				Size = Vector3.new(WATCHER_CONFIG.EYE_SIZE * 1.4, WATCHER_CONFIG.EYE_SIZE * 1.4, WATCHER_CONFIG.EYE_SIZE * 1.4),
				Color = WATCHER_CONFIG.VEIN_COLOR
			}):Play()
		end

		task.wait(0.5)

		local explosionPos = eyeball and eyeball.Parent and eyeball.Position or Vector3.new(0, 0, 0)

		-- Explosi�n de luz
		local burst = Instance.new("Part")
		burst.Size = Vector3.new(2, 2, 2)
		burst.Shape = Enum.PartType.Ball
		burst.Color = WATCHER_CONFIG.IRIS_MAIN_COLOR
		burst.Material = Enum.Material.Neon
		burst.Transparency = 0
		burst.Anchored = true
		burst.CanCollide = false
		burst.Position = explosionPos
		burst.Parent = workspace

		TweenService:Create(burst, TweenInfo.new(0.5, Enum.EasingStyle.Expo), {
			Size = Vector3.new(25, 25, 25),
			Transparency = 1
		}):Play()

		-- Part�culas de gore con verificación
		if eyeball and eyeball.Parent then
			local goreEmitter = Instance.new("ParticleEmitter")
			goreEmitter.Texture = "rbxassetid://243098098"
			goreEmitter.Color = ColorSequence.new(WATCHER_CONFIG.VEIN_COLOR)
			goreEmitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.2)
			})
			goreEmitter.Transparency = NumberSequence.new(0)
			goreEmitter.Lifetime = NumberRange.new(1, 2)
			goreEmitter.Rate = 0
			goreEmitter.Speed = NumberRange.new(20, 40)
			goreEmitter.SpreadAngle = Vector2.new(360, 360)
			goreEmitter.Acceleration = Vector3.new(0, -50, 0)
			goreEmitter.Parent = eyeball
			goreEmitter:Emit(40)
		end

		-- Desvanecer todas las partes con verificación
		if npcModel and npcModel.Parent then
			for _, part in pairs(npcModel:GetDescendants()) do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(0.5), {
						Size = Vector3.new(0.1, 0.1, 0.1),
						Transparency = 1
					}):Play()
				end
			end
		end

		Debris:AddItem(burst, 0.6)
		task.wait(0.8)
		
		-- Limpiar sonido de muerte
		if deathSound then
			Debris:AddItem(deathSound, 2)
		end
		
		-- Garantizar destrucción del NPC
		if npcFolder and npcFolder.Parent then
			npcFolder:Destroy()
		end
	end

	-- ---------------------------------------------------------------------------
	-- BUSCAR JUGADOR M�S CERCANO
	-- ---------------------------------------------???-----------------------------

	local function FindNearestPlayer()
		local nearest, nearestDist = nil, WATCHER_CONFIG.DETECTION_RANGE
		for _, player in pairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local hum = char:FindFirstChild("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local dist = (hrp.Position - Vector3.new(npcX, 0, npcZ)).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = player
					end
				end
			end
		end
		return nearest, nearestDist
	end

	-- ---------------------------------------------------------------------------
	-- ATACAR JUGADOR
	-- ---------------------------------------------------------------------------

	local isAlive = true
	local lastAttackTime = 0
	local lastBlinkTime = 0
	local blinkInterval = 4 + math.random() * 3

	local function AttackPlayer(player)
		if tick() - lastAttackTime < WATCHER_CONFIG.ATTACK_COOLDOWN then return end
		if isAttacking or isCharging then return end
		lastAttackTime = tick()

		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")

		if hum and hum.Health > 0 and hrp then
			local targetPos = hrp.Position

			coroutine.wrap(function()
				PlayAttackAnimation(targetPos)
			end)()

			task.wait(WATCHER_CONFIG.BEAM_CHARGE_TIME + 0.2)

			if not char.Parent or not hrp.Parent then return end
			local dist = (hrp.Position - Vector3.new(npcX, eyeball.Position.Y, npcZ)).Magnitude

			if dist < WATCHER_CONFIG.ATTACK_RANGE + 8 then
				local hitSound = CreateSound(WATCHER_SOUNDS.BEAM_HIT, hrp)
				hitSound:Play()
				Debris:AddItem(hitSound, 2)

				hum: TakeDamage(WATCHER_CONFIG.DAMAGE)

				-- Paralizar jugador
				local originalSpeed = hum.WalkSpeed
				local originalJump = hum.JumpPower
				hum.WalkSpeed = 0
				hum.JumpPower = 0

				local paralyzeEffect = Instance.new("Part")
				paralyzeEffect.Name = "ParalyzeEffect"
				paralyzeEffect.Size = Vector3.new(4, 6, 4)
				paralyzeEffect.Color = WATCHER_CONFIG.BEAM_COLOR
				paralyzeEffect.Material = Enum.Material.ForceField
				paralyzeEffect.Transparency = 0.6
				paralyzeEffect.Anchored = true
				paralyzeEffect.CanCollide = false
				paralyzeEffect.CFrame = hrp.CFrame
				paralyzeEffect.Parent = workspace

				task.delay(WATCHER_CONFIG.PARALYZE_DURATION, function()
					if hum and hum.Parent then
						hum.WalkSpeed = originalSpeed
						hum.JumpPower = originalJump
					end
					if paralyzeEffect and paralyzeEffect.Parent then
						TweenService:Create(paralyzeEffect, TweenInfo.new(0.4), {
							Transparency = 1
						}):Play()
						Debris:AddItem(paralyzeEffect, 0.5)
					end
				end)
			end
		end
	end

	-- ---------------------------------------------------------------------------
	-- LOOP PRINCIPAL DE IA
	-- ---------------------------------------------------------------------------

	local chaseConnection
	chaseConnection = RunService.Heartbeat:Connect(function(dt)
		-- WATCHER usa "eyeball" como parte principal, NO "thorax"
		if not isAlive or not eyeball or not eyeball.Parent then
			if chaseConnection then chaseConnection:Disconnect() end
			return
		end

		-- -----------------------------------------------------------------------
		-- CHECK IF STUNNED - STOP ALL ACTIONS
		-- -----------------------------------------------------------------------
		if npcModel: GetAttribute("Stunned") then
			-- Still animate but don't move or attack
			UpdateNPCPosition(npcX, npcZ, nil, dt)
			return
		end
		-- -----------------------------------------------------------------------

		-- Verificar si est� en el lobby (zona segura)
		if IsInLobby(npcX) then
			PlayDeathEffect()
			return
		end

		-- Parpadeo aleatorio
		if tick() - lastBlinkTime > blinkInterval then
			lastBlinkTime = tick()
			blinkInterval = 3 + math.random() * 4
			if not isCharging and not isAttacking then
				coroutine.wrap(function()
					DoBlink()
				end)()
			end
		end

		-- Buscar jugador
		local target, distance = FindNearestPlayer()
		local lookAtPos = nil

		UpdateHorrorEffects(distance)

		if target then
			local char = target.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					lookAtPos = hrp.Position
					local direction = Vector3.new(hrp.Position.X - npcX, 0, hrp. Position.Z - npcZ)

					if distance > WATCHER_CONFIG. ATTACK_RANGE then
						-- Moverse hacia el jugador
						local moveDir = direction.Unit
						local newX = npcX + moveDir.X * WATCHER_CONFIG. SPEED * dt
						local newZ = npcZ + moveDir.Z * WATCHER_CONFIG. SPEED * dt

						if not IsInLobby(newX) then
							UpdateNPCPosition(newX, newZ, lookAtPos, dt)
						else
							UpdateNPCPosition(npcX, newZ, lookAtPos, dt)
						end
					else
						-- En rango de ataque
						UpdateNPCPosition(npcX, npcZ, lookAtPos, dt)
						AttackPlayer(target)
					end
				else
					UpdateNPCPosition(npcX, npcZ, lookAtPos, dt)
				end
			else
				UpdateNPCPosition(npcX, npcZ, lookAtPos, dt)
			end
		else
			-- Sin objetivo, mirar al frente
			UpdateNPCPosition(npcX, npcZ, nil, dt)
		end
	end)
	-- ---------------------------------------------------------------------------
	-- L�MITE DE TIEMPO DE VIDA
	-- ---------------------------------------------------------------------------

	coroutine.wrap(function()
		task.wait(WATCHER_CONFIG.LIFETIME)
		if npcFolder and npcFolder.Parent and isAlive then
			PlayDeathEffect()
		end
	end)()

	-- ---------------------------------------------------------------------------
	-- LIMPIEZA AL DESTRUIR
	-- ---------------------------------------------------------------------------

	npcFolder.AncestryChanged: Connect(function()
		if not npcFolder.Parent then
			isAlive = false
			humSound:Stop()
			heartbeatSound:Stop()
			whisperSound:Stop()
			if chaseConnection then chaseConnection:Disconnect() end
		end
	end)

	print("??? WATCHER SPAWNED - Holographic Floating Iris V5.0")
	return npcFolder
end

-- -------------------------------------------------------------------------------
-- CONEXI�N DEL EVENTO
-- -------------------------------------------------------------------------------

if SpawnWatcherEvent then
	SpawnWatcherEvent.Event:Connect(function(position, player, side, zDir)
		task.wait(0.5)
		CreateWatcherNPC(position, player, side, zDir)
	end)
	print("---------------------------------------------------------------")
	print("  ??? NPC WATCHER SYSTEM V5.0 - HOLOGRAPHIC FLOATING IRIS ???   ")
	print("     ? Iris y Pupila flotan ~20cm fuera del ojo f�sico ?      ")
	print("     ? Solo el iris y pupila brillan (Material Neon) ?        ")
	print("     ? El ojo f�sico es opaco (SmoothPlastic) ?               ")
	print("     ? Iris y pupila siguen al jugador objetivo ?             ")
	print("--??------------------------------------------------------------")
else
	warn("?? SpawnWatcherEvent not found!  Watcher system inactive.")
end