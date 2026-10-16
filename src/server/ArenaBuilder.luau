--!strict
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local ARENA_NAME = "FrontlineArena"
local ARENA_VERSION = 5
local GROUND_SIZE = Vector3.new(280, 2, 220)
local ISLAND_NAME = "BR_Peninsula_Draft"
local ISLAND_SPAWN_FOLDER = "SpawnPoints"

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	material: Enum.Material,
	color: Color3,
	canCollide: boolean,
	role: string
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = canCollide
	part.CanTouch = false
	part.CanQuery = true
	part.Material = material
	part.Color = color
	part:SetAttribute("ArenaRole", role)
	part.Parent = parent
	return part
end

local function makeFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function makeSpawn(parent: Instance, name: string, position: Vector3, color: Color3): SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = position
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.CanTouch = false
	spawn.CanQuery = true
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.Material = Enum.Material.Concrete
	spawn.Color = color
	spawn.Transparency = 0.65
	spawn:SetAttribute("ArenaRole", "EntrySpawn")
	spawn.Parent = parent
	return spawn
end

local function ensureIslandSpawns(): Folder?
	local island = Workspace:FindFirstChild(ISLAND_NAME)
	if not island then return nil end
	assert(island:IsA("Folder"), ISLAND_NAME .. " precisa ser Folder")

	local spawnFolder = island:FindFirstChild(ISLAND_SPAWN_FOLDER)
	if not spawnFolder then
		spawnFolder = makeFolder(island, ISLAND_SPAWN_FOLDER)
	end
	assert(spawnFolder:IsA("Folder"), ISLAND_SPAWN_FOLDER .. " precisa ser Folder")

	local spawnSpecs = {
		{ name = "Spawn_WestEntry", x = -784, z = 448, color = Color3.fromRGB(64, 150, 225) },
		{ name = "Spawn_EastEntry", x = 851, z = 437, color = Color3.fromRGB(225, 105, 74) },
	}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { Workspace.Terrain }
	rayParams.IgnoreWater = true

	for _, spec in spawnSpecs do
		local hit = Workspace:Raycast(Vector3.new(spec.x, 500, spec.z), Vector3.new(0, -900, 0), rayParams)
		assert(hit and hit.Material == Enum.Material.Grass, "ponto de equipe fora do gramado da ilha: " .. spec.name)

		local spawn = spawnFolder:FindFirstChild(spec.name)
		if spawn and not spawn:IsA("SpawnLocation") then
			spawn:Destroy()
			spawn = nil
		end
		if not spawn then
			spawn = makeSpawn(spawnFolder, spec.name, Vector3.zero, spec.color)
		end
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Position = Vector3.new(spec.x, hit.Position.Y + spawn.Size.Y / 2 + 0.5, spec.z)
		spawn.Anchored = true
		spawn.CanCollide = true
		spawn.CanTouch = false
		spawn.Enabled = true
		spawn.Neutral = true
		spawn.AllowTeamChangeOnTouch = false
		spawn.Duration = 0
		spawn.Color = spec.color
		spawn:SetAttribute("MapRegion", ISLAND_NAME)
		spawn:SetAttribute("TerrainMaterial", hit.Material.Name)
	end

	local oldNeutralSpawn = Workspace:FindFirstChild("SpawnLocation")
	if oldNeutralSpawn and oldNeutralSpawn:IsA("SpawnLocation") then
		oldNeutralSpawn:Destroy()
	end
	return spawnFolder
end

local function makePavement(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	alongX: boolean,
	color: Color3
)
	local length = if alongX then size.X else size.Z
	local segmentLength = 20
	local segmentCount = math.ceil(length / segmentLength)

	for index = 1, segmentCount do
		local currentLength = math.min(segmentLength, length - (index - 1) * segmentLength)
		local offset = -length / 2 + (index - 1) * segmentLength + currentLength / 2
		local segmentSize = if alongX then Vector3.new(currentLength, size.Y, size.Z) else Vector3.new(size.X, size.Y, currentLength)
		local segmentPosition = position
			+ (if alongX then Vector3.new(offset, 0, 0) else Vector3.new(0, 0, offset))
		local segment = makePart(
			parent,
			("%s_%02d"):format(name, index),
			segmentSize,
			segmentPosition,
			Enum.Material.Asphalt,
			color,
			false,
			"PavementModule"
		)
	end
end

local function makeRuinBuilding(parent: Instance, name: string, center: Vector3, frontSign: number, style: number)
	local building = makeFolder(parent, name)
	local concrete = if style % 2 == 0 then Color3.fromRGB(112, 110, 101) else Color3.fromRGB(126, 119, 105)
	local exposedConcrete = Color3.fromRGB(88, 87, 81)
	local steel = Color3.fromRGB(59, 67, 68)
	local backSign = -frontSign

	makePart(building, "GroundFloor", Vector3.new(42, 0.8, 34), center + Vector3.new(0, 0.4, 0), Enum.Material.Concrete, exposedConcrete, true, "BuildingFloor")
	makePart(building, "UpperFloorSlab", Vector3.new(42, 0.8, 34), center + Vector3.new(0, 12, 0), Enum.Material.Concrete, exposedConcrete, true, "BuildingFloor")

	-- Ruined street-facing ground floor with a wide, usable breach at its center.
	for _, side in { -1, 1 } do
		makePart(building, ("FrontPier_%d"):format(side), Vector3.new(15, 12, 1.4), center + Vector3.new(side * 13.5, 6, frontSign * 17), Enum.Material.Concrete, concrete, true, "BuildingWall")
	end
	makePart(building, "BreachLintel", Vector3.new(12, 3, 1.4), center + Vector3.new(0, 10.5, frontSign * 17), Enum.Material.Concrete, exposedConcrete, true, "BuildingWall")

	-- The rear wall and side returns keep the structure readable while leaving the front breach open.
	makePart(building, "RearWall", Vector3.new(42, 12, 1.4), center + Vector3.new(0, 6, backSign * 17), Enum.Material.Concrete, concrete, true, "BuildingWall")
	for _, side in { -1, 1 } do
		makePart(building, ("SideWall_%d"):format(side), Vector3.new(1.4, 12, 34), center + Vector3.new(side * 20.3, 6, 0), Enum.Material.Concrete, concrete, true, "BuildingWall")
	end

	-- Upper facade panels sit around window openings; dark panes are visual only.
	for _, faceSign in { frontSign, backSign } do
		local faceZ = center.Z + faceSign * 17.05
		for _, x in { -16, 0, 16 } do
			local width = if x == 0 then 6 else 8
			makePart(building, ("UpperPanel_%d_%d"):format(faceSign, x), Vector3.new(width, 12, 1.4), center + Vector3.new(x, 18, faceSign * 17), Enum.Material.Concrete, concrete, true, "BuildingWall")
		end
		for _, x in { -9, 9 } do
			makePart(building, ("WindowSill_%d_%d"):format(faceSign, x), Vector3.new(6, 2, 1.4), center + Vector3.new(x, 15, faceSign * 17), Enum.Material.Concrete, exposedConcrete, true, "BuildingWall")
			makePart(building, ("WindowHeader_%d_%d"):format(faceSign, x), Vector3.new(6, 2, 1.4), center + Vector3.new(x, 21, faceSign * 17), Enum.Material.Concrete, exposedConcrete, true, "BuildingWall")
			local window = makePart(building, ("UpperWindow_%d_%d"):format(faceSign, x), Vector3.new(6, 4, 0.08), Vector3.new(center.X + x, 18, center.Z + faceSign * 17.76), Enum.Material.Glass, Color3.fromRGB(45, 52, 53), false, "Window")
			window.Transparency = 0.32
			window.CanQuery = false
		end
	end

	for _, side in { -1, 1 } do
		makePart(building, ("UpperSide_%d"):format(side), Vector3.new(1.4, 12, 34), center + Vector3.new(side * 20.3, 18, 0), Enum.Material.Concrete, concrete, true, "BuildingWall")
	end

	-- A broken roof leaves a clear silhouette instead of a solid test cube.
	makePart(building, "RemainingRoof", Vector3.new(22, 1, 34), center + Vector3.new(-10, 24, 0), Enum.Material.Metal, steel, true, "BuildingRoof")
	for _, z in { -13, 0, 13 } do
		local beam = makePart(building, ("ExposedRoofBeam_%d"):format(z), Vector3.new(1.2, 0.8, 15), center + Vector3.new(10, 23, z), Enum.Material.Metal, steel, false, "RuinDetail")
		beam.CanQuery = false
	end

	-- Small rubble clusters frame the breach and corners without blocking the combat route.
	for index, xOffset in { -13, 13 } do
		local rubble = makePart(building, ("Rubble_%d"):format(index), Vector3.new(5 + index % 2, 1.2, 3), center + Vector3.new(xOffset, 0.9, frontSign * 13), Enum.Material.Rock, exposedConcrete, false, "Rubble")
		rubble.CFrame *= CFrame.Angles(0, math.rad(index * 13), math.rad(index * 3))
		rubble.CanQuery = false
	end

	local signPlate = makePart(building, "DamagedSign", Vector3.new(8, 1.6, 0.25), center + Vector3.new(0, 10, frontSign * 17.9), Enum.Material.Metal, steel, false, "RuinDetail")
	signPlate.CFrame *= CFrame.Angles(0, 0, math.rad(3 * style))
	signPlate.CanQuery = false
end

local function makeWreckedVehicle(parent: Instance, position: Vector3, heading: number)
	local wreck = Instance.new("Model")
	wreck.Name = "BurnedTransportWreck"
	wreck:SetAttribute("ArenaRole", "StaticCover")
	wreck:SetAttribute("AssetSource", "Original procedural scene geometry")
	local origin = CFrame.new(position) * CFrame.Angles(0, math.rad(heading), 0)
	local burntMetal = Color3.fromRGB(48, 51, 48)
	local rust = Color3.fromRGB(92, 67, 49)

	local function part(name: string, size: Vector3, localFrame: CFrame, material: Enum.Material, color: Color3, canCollide: boolean): Part
		local object = makePart(wreck, name, size, (origin * localFrame).Position, material, color, canCollide, "Wreckage")
		object.CFrame = origin * localFrame
		return object
	end

	local chassis = part("TwistedChassis", Vector3.new(7.4, 1.2, 13), CFrame.new(0, 1.15, 0), Enum.Material.Metal, burntMetal, true)
	wreck.PrimaryPart = chassis
	part("BurnedBody", Vector3.new(6.6, 2.1, 10.5), CFrame.new(0, 2.45, 0), Enum.Material.Metal, Color3.fromRGB(60, 58, 51), true)
	part("CollapsedHood", Vector3.new(6.8, 0.8, 3.6), CFrame.new(0, 2.15, -4.2) * CFrame.Angles(0, 0, math.rad(-7)), Enum.Material.Metal, rust, true)
	part("CabinFrame", Vector3.new(5.8, 2.6, 4.2), CFrame.new(0, 3.65, 0.5), Enum.Material.CorrodedMetal, burntMetal, true)
	part("BrokenWindshield", Vector3.new(5.2, 0.08, 1.8), CFrame.new(0, 4.45, -1.15) * CFrame.Angles(math.rad(63), 0, 0), Enum.Material.Glass, Color3.fromRGB(76, 83, 80), false).Transparency = 0.38
	part("DetachedDoor", Vector3.new(0.22, 2.4, 3.2), CFrame.new(3.6, 2.8, 0.3) * CFrame.Angles(0, 0, math.rad(14)), Enum.Material.Metal, rust, false)
	for _, x in { -3.7, 3.7 } do
		for _, z in { -4.2, 4.2 } do
			part(("Tire_%d_%d"):format(x, z), Vector3.new(1.4, 2.8, 2.8), CFrame.new(x, 1.25, z) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Rubber, Color3.fromRGB(28, 29, 27), true).Shape = Enum.PartType.Cylinder
		end
	end
	part("ExposedAxle", Vector3.new(8.2, 0.35, 0.35), CFrame.new(0, 0.95, 4.2), Enum.Material.Metal, rust, false)

	local smoke = Instance.new("Smoke")
	smoke.Name = "CoolingWreckSmoke"
	smoke.Color = Color3.fromRGB(72, 70, 64)
	smoke.Opacity = 0.16
	smoke.RiseVelocity = 2
	smoke.Size = 12
	smoke.Parent = chassis
	wreck.Parent = parent
end

local function makeForwardDefenses(parent: Instance)
	for _, z in { -93, 93 } do
		local line = makeFolder(parent, ("ForwardLine_%s"):format(if z < 0 then "North" else "South"))
		for _, x in { -48, 48 } do
			makePart(line, ("Earthwork_%d"):format(x), Vector3.new(60, 3.4, 6), Vector3.new(x, 1.7, z), Enum.Material.Ground, Color3.fromRGB(86, 81, 67), true, "FieldFortification")
			for segment = 0, 3 do
				local bag = makePart(line, ("Sandbag_%d_%d"):format(x, segment), Vector3.new(13, 1.4, 2.4), Vector3.new(x - 20 + segment * 13.5, 3.6, z - 2.6), Enum.Material.Sand, Color3.fromRGB(124, 113, 90), true, "FieldFortification")
				bag.CFrame *= CFrame.Angles(0, math.rad((segment % 2 == 0) and -2 or 2), 0)
			end
		end
	end

	local outpost = makeFolder(parent, "ForwardCommandPost")
	local center = Vector3.new(0, 0, -83)
	for _, side in { -1, 1 } do
		makePart(outpost, ("ShelterWall_%d"):format(side), Vector3.new(2, 6, 10), center + Vector3.new(side * 5, 3, 0), Enum.Material.Fabric, Color3.fromRGB(78, 85, 70), false, "FieldStructure")
		makePart(outpost, ("SandbagPosition_%d"):format(side), Vector3.new(13, 2.4, 3), center + Vector3.new(side * 11, 1.2, 7), Enum.Material.Sand, Color3.fromRGB(124, 111, 86), true, "FieldFortification")
	end
	makePart(outpost, "ShelterRoof", Vector3.new(12, 0.5, 12), center + Vector3.new(0, 6.2, 0), Enum.Material.Fabric, Color3.fromRGB(60, 68, 57), false, "FieldStructure")
	makePart(outpost, "RadioMast", Vector3.new(0.35, 18, 0.35), center + Vector3.new(0, 9, -8), Enum.Material.Metal, Color3.fromRGB(58, 62, 60), false, "FieldStructure")
	makePart(outpost, "SupplyCrate_A", Vector3.new(2.2, 2.2, 2.2), center + Vector3.new(-2, 1.1, 4), Enum.Material.WoodPlanks, Color3.fromRGB(89, 83, 67), true, "FieldProp")
	makePart(outpost, "SupplyCrate_B", Vector3.new(2, 2, 2), center + Vector3.new(2, 1, 4.2), Enum.Material.WoodPlanks, Color3.fromRGB(75, 76, 65), true, "FieldProp")
end

local function makeImpactSite(parent: Instance, position: Vector3)
	local crater = makeFolder(parent, "ImpactSite_CentralCrossing")
	local scorch = makePart(crater, "ScorchedRoad", Vector3.new(15, 0.05, 11), position + Vector3.new(0, 0.13, 0), Enum.Material.Asphalt, Color3.fromRGB(40, 41, 39), false, "BattleDamage")
	scorch.Shape = Enum.PartType.Cylinder
	scorch.CanQuery = false
	for index, offset in { Vector3.new(-6, 0.4, -4), Vector3.new(4, 0.25, -5), Vector3.new(6, 0.35, 4), Vector3.new(-4, 0.25, 5) } do
		local rubble = makePart(crater, ("ImpactRubble_%d"):format(index), Vector3.new(3 + index % 2, 0.8, 2.4), position + offset, Enum.Material.Rock, Color3.fromRGB(78, 76, 69), false, "BattleDamage")
		rubble.CFrame *= CFrame.Angles(math.rad(index * 2), math.rad(index * 17), math.rad(index * 3))
		rubble.CanQuery = false
	end
end

local function makeBattleAtmosphere()
	Lighting.ClockTime = 17.1
	Lighting.Brightness = 1.8
	Lighting.Ambient = Color3.fromRGB(92, 91, 82)
	Lighting.OutdoorAmbient = Color3.fromRGB(121, 116, 101)
	Lighting.ColorShift_Top = Color3.fromRGB(201, 190, 162)
	Lighting.ColorShift_Bottom = Color3.fromRGB(88, 87, 80)

	local atmosphere = Lighting:FindFirstChild("FrontlineDustAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "FrontlineDustAtmosphere"
		atmosphere.Parent = Lighting
	end
	if atmosphere:IsA("Atmosphere") then
		atmosphere.Color = Color3.fromRGB(199, 185, 158)
		atmosphere.Decay = Color3.fromRGB(103, 106, 101)
		atmosphere.Density = 0.24
		atmosphere.Haze = 1.6
		atmosphere.Glare = 0.08
	end

	local grade = Lighting:FindFirstChild("FrontlineBattleGrade")
	if not grade then
		grade = Instance.new("ColorCorrectionEffect")
		grade.Name = "FrontlineBattleGrade"
		grade.Parent = Lighting
	end
	if grade:IsA("ColorCorrectionEffect") then
		grade.Brightness = -0.025
		grade.Contrast = 0.12
		grade.Saturation = -0.18
		grade.TintColor = Color3.fromRGB(224, 215, 193)
	end
end

local function makeDistantBattleSmoke(parent: Instance)
	for index, position in {
		Vector3.new(-94, 3, -101),
		Vector3.new(84, 3, -102),
		Vector3.new(104, 3, 99),
	} do
		local source = makePart(parent, ("SmokeSource_%d"):format(index), Vector3.new(2, 2, 2), position, Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), false, "Atmosphere")
		source.Transparency = 1
		source.CanQuery = false
		local smoke = Instance.new("Smoke")
		smoke.Name = "DistantBattleSmoke"
		smoke.Color = Color3.fromRGB(77, 76, 70)
		smoke.Opacity = 0.24
		smoke.RiseVelocity = 4
		smoke.Size = 24
		smoke.Parent = source
	end
end

local function makeRoadMarkings(parent: Instance)
	for _, z in { -32, 32 } do
		for x = -126, 126, 24 do
			local dash = makePart(parent, ("LaneDash_%d_%d"):format(z, x), Vector3.new(8, 0.04, 0.32), Vector3.new(x, 0.14, z), Enum.Material.SmoothPlastic, Color3.fromRGB(163, 151, 120), false, "RoadMarking")
			dash.CanQuery = false
		end
	end

	for _, x in { -42, 42 } do
		for _, z in { -29, 3 } do
			for stripe = 0, 5 do
				local mark = makePart(parent, ("Crosswalk_%d_%d_%d"):format(x, z, stripe), Vector3.new(0.8, 0.04, 2), Vector3.new(x - 5 + stripe * 2, 0.145, z), Enum.Material.SmoothPlastic, Color3.fromRGB(136, 134, 124), false, "RoadMarking")
				mark.CanQuery = false
			end
		end
	end
end

local function makeRoadsideBarricades(parent: Instance)
	for _, placement in {
		{ name = "Barricade_NorthApproach", position = Vector3.new(-61, 1.6, -17) },
		{ name = "Barricade_CenterEast", position = Vector3.new(57, 1.6, 17) },
		{ name = "Barricade_SouthApproach", position = Vector3.new(7, 1.6, 49) },
		{ name = "Barricade_WestFlank", position = Vector3.new(-96, 1.6, 47) },
	} do
		local barricade = makeFolder(parent, placement.name)
		makePart(barricade, "ConcreteBarrier", Vector3.new(16, 3.2, 3), placement.position, Enum.Material.Concrete, Color3.fromRGB(91, 91, 84), true, "StaticCover")
		for _, side in { -1, 1 } do
			makePart(barricade, ("SandbagStack_%d"):format(side), Vector3.new(5, 1.2, 4), placement.position + Vector3.new(side * 6, 1.8, 0), Enum.Material.Sand, Color3.fromRGB(122, 111, 88), true, "StaticCover")
		end
	end
end

local function makeCoverModules(parent: Instance, name: string, position: Vector3)
	local cover = makeFolder(parent, name)
	makePart(
		cover,
		name,
		Vector3.new(12, 5, 2),
		position,
		Enum.Material.Concrete,
		Color3.fromRGB(104, 101, 92),
		true,
		"CoverCore"
	)

	local armor = makeFolder(cover, "ArmorModules")
	for _, faceSign in { -1, 1 } do
		local panel = makePart(
			armor,
			("ArmorPanel_%d"):format(faceSign),
			Vector3.new(11.8, 4.8, 0.06),
			position + Vector3.new(0, 0, faceSign * 1.02),
			Enum.Material.DiamondPlate,
			Color3.fromRGB(89, 94, 91),
			false,
			"CoverDetail"
		)
		panel.CanQuery = false
	end
end

local function isSafeUrbanProp(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BaseScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("Sound") then
			return false
		end
	end
	return true
end

local function addApprovedUrbanProps(parent: Instance)
	local quarantine = ServerStorage:FindFirstChild("FL014_Quarantine")
	local approved = quarantine and quarantine:FindFirstChild("FL014_UrbanProps_Candidate")
	if not approved then
		warn("[Frontline][FL-016] kit urbano aprovado ausente; arena mantém módulos nativos")
		return
	end

	local placements = {
		{ source = "StreetLightPole_01_A", name = "StreetLight_NorthWest", x = -50, z = -93 },
		{ source = "Bus_Stop_01_A", name = "BusStop_EastNorth", x = 112, z = -65 },
		{ source = "FireHydrant_01_A", name = "Hydrant_CenterWest", x = -42, z = -22 },
	}
	local props = makeFolder(parent, "ApprovedUrbanProps")

	for _, placement in placements do
		local source = approved:FindFirstChild(placement.source)
		if not source or not source:IsA("Model") or not isSafeUrbanProp(source) then
			warn("[Frontline][FL-016] prop ausente ou rejeitado na auditoria: " .. placement.source)
			continue
		end

		local model = source:Clone()
		model.Name = placement.name
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
			end
		end

		local bounds, size = model:GetBoundingBox()
		local currentPivot = model:GetPivot()
		local bottomY = bounds.Position.Y - size.Y / 2
		model:PivotTo(currentPivot + Vector3.new(
			placement.x - currentPivot.Position.X,
			-bottomY,
			placement.z - currentPivot.Position.Z
		))
		model.Parent = props
	end
end

local function buildArena(): Model
	ensureIslandSpawns()
	local existing = Workspace:FindFirstChild(ARENA_NAME)
	if existing then
		if existing:IsA("Model") then
			if existing:GetAttribute("ArenaVersion") == ARENA_VERSION then
				local entries = existing:FindFirstChild("EntryPoints")
				if entries then
					for _, entry in entries:GetChildren() do
						if entry:IsA("SpawnLocation") then entry:Destroy() end
					end
				end
				return existing
			end
			existing:Destroy()
		end
		if Workspace:FindFirstChild(ARENA_NAME) then
			error(ARENA_NAME .. " already exists in Workspace and is not a Model")
		end
	end

	local legacyArena = Workspace:FindFirstChild("GreyboxArena")
	if legacyArena and legacyArena:IsA("Model") and legacyArena:GetAttribute("ArenaSizeX") then
		legacyArena:Destroy()
	end

	local arena = Instance.new("Model")
	arena.Name = ARENA_NAME
	arena:SetAttribute("ArenaVersion", ARENA_VERSION)
	arena:SetAttribute("ArenaSizeX", GROUND_SIZE.X)
	arena:SetAttribute("ArenaSizeZ", GROUND_SIZE.Z)
	arena:SetAttribute("RouteCount", 3)
	arena:SetAttribute("EntryCount", 0)

	local groundwork = makeFolder(arena, "Groundwork")
	makePart(
		groundwork,
		"Ground",
		GROUND_SIZE,
		Vector3.new(0, -1, 0),
		Enum.Material.Ground,
		Color3.fromRGB(97, 94, 82),
		true,
		"Ground"
	)

	local pavement = makeFolder(arena, "PavementModules")
	for _, z in { -32, 0, 32 } do
		makePavement(
			pavement,
			("Street_EW_%d"):format(z),
			Vector3.new(280, 0.12, 18),
			Vector3.new(0, 0.06, z),
			true,
			Color3.fromRGB(55, 57, 59)
		)
	end

	for _, x in { -42, 42 } do
		makePavement(
			pavement,
			("Street_NS_%d"):format(x),
			Vector3.new(12, 0.12, 220),
			Vector3.new(x, 0.061, 0),
			false,
			Color3.fromRGB(55, 57, 59)
		)
	end

	local markings = makeFolder(arena, "RoadMarkings")
	makeRoadMarkings(markings)

	local perimeter = makeFolder(arena, "BattlePerimeter")
	for _, x in { -137.5, 137.5 } do
		local side = if x < 0 then "West" else "East"
		for _, z in { -82, -48, 48, 82 } do
			local barrier = makeFolder(perimeter, ("RubbleBarricade_%s_%d"):format(side, z))
			makePart(barrier, "ConcreteBlock", Vector3.new(5, 4.5, 26), Vector3.new(x, 2.25, z), Enum.Material.Concrete, Color3.fromRGB(87, 87, 80), true, "Boundary")
			local cap = makePart(barrier, "BrokenTop", Vector3.new(5.6, 0.6, 10), Vector3.new(x, 4.8, z + (if z < 0 then 3 else -3)), Enum.Material.Rock, Color3.fromRGB(72, 73, 67), false, "RuinDetail")
			cap.CFrame *= CFrame.Angles(0, math.rad(if z < 0 then -4 else 4), math.rad(2))
			cap.CanQuery = false
		end
	end

	local structures = makeFolder(arena, "Structures")
	for _, building in {
		{ name = "Ruin_NorthWest", position = Vector3.new(-76, 0, -66), front = 1, style = 1 },
		{ name = "Ruin_NorthEast", position = Vector3.new(76, 0, -66), front = 1, style = 2 },
		{ name = "Ruin_SouthWest", position = Vector3.new(-76, 0, 66), front = -1, style = 3 },
		{ name = "Ruin_SouthEast", position = Vector3.new(76, 0, 66), front = -1, style = 4 },
	} do
		makeRuinBuilding(structures, building.name, building.position, building.front, building.style)
	end

	local entries = makeFolder(arena, "EntryPoints")

	local coverModules = makeFolder(arena, "CoverModules")
	for _, cover in {
		{ name = "Cover_NorthWest", position = Vector3.new(-24, 2.5, -32) },
		{ name = "Cover_CenterWest", position = Vector3.new(-24, 2.5, 0) },
		{ name = "Cover_SouthEast", position = Vector3.new(24, 2.5, 32) },
		{ name = "Cover_EntryWest", position = Vector3.new(-104, 2.5, -10) },
		{ name = "Cover_EntryEast", position = Vector3.new(104, 2.5, 10) },
	} do
		makeCoverModules(coverModules, cover.name, cover.position)
	end

	local staticCover = makeFolder(arena, "RoadsideCover")
	makeRoadsideBarricades(staticCover)
	makeForwardDefenses(arena)
	makeImpactSite(arena, Vector3.new(0, 0, 0))
	makeWreckedVehicle(arena, Vector3.new(58, 0, -7), 24)
	makeWreckedVehicle(arena, Vector3.new(-103, 0, 29), -71)

	local atmosphere = makeFolder(arena, "BattleAtmosphere")
	makeDistantBattleSmoke(atmosphere)
	makeBattleAtmosphere()

	addApprovedUrbanProps(arena)

	arena.Parent = Workspace
	return arena
end

return table.freeze({
	Build = buildArena,
})
