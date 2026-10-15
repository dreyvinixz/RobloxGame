--!strict
local Workspace = game:GetService("Workspace")

local ARENA_NAME = "GreyboxArena"
local GROUND_SIZE = Vector3.new(280, 2, 220)

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

local function makeSpawn(parent: Instance, name: string, position: Vector3, color: Color3)
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
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = color
	spawn:SetAttribute("ArenaRole", "EntrySpawn")
	spawn.Parent = parent
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

local function makeFacadeModules(parent: Instance, center: Vector3)
	local modules = makeFolder(parent, "FacadeModules")
	local palette = {
		Color3.fromRGB(127, 126, 117),
		Color3.fromRGB(135, 132, 121),
	}

	for _, faceSign in { -1, 1 } do
		for row = 1, 2 do
			for column = 1, 2 do
				local moduleColor = palette[(row + column) % #palette + 1]
				local module = makePart(
					modules,
					("Facade_Z%d_%d_%d"):format(faceSign, row, column),
					Vector3.new(21.04, 12.04, 0.08),
					Vector3.new(center.X - 21 + (column - 0.5) * 21, 6 + (row - 1) * 12, center.Z + faceSign * 17.04),
					Enum.Material.Concrete,
					moduleColor,
					false,
					"FacadeModule"
				)
				module.CanQuery = false
			end
		end

		for _, windowOffset in { -10.5, 10.5 } do
			local window = makePart(
				modules,
				("Window_Z%d_%d"):format(faceSign, windowOffset),
				Vector3.new(6, 4, 0.04),
				Vector3.new(center.X + windowOffset, 14, center.Z + faceSign * 17.1),
				Enum.Material.Glass,
				Color3.fromRGB(74, 82, 84),
				false,
				"FacadeDetail"
			)
			window.Transparency = 0.15
			window.CanQuery = false
		end
	end

	for _, faceSign in { -1, 1 } do
		for row = 1, 2 do
			for column = 1, 2 do
				local module = makePart(
					modules,
					("Facade_X%d_%d_%d"):format(faceSign, row, column),
					Vector3.new(0.08, 12.04, 17.04),
					Vector3.new(center.X + faceSign * 21.04, 6 + (row - 1) * 12, center.Z - 17 + (column - 0.5) * 17),
					Enum.Material.Concrete,
					palette[(row + column) % #palette + 1],
					false,
					"FacadeModule"
				)
				module.CanQuery = false
			end
		end

		for _, windowOffset in { -7, 7 } do
			local window = makePart(
				modules,
				("Window_X%d_%d"):format(faceSign, windowOffset),
				Vector3.new(0.04, 4, 6),
				Vector3.new(center.X + faceSign * 21.1, 14, center.Z + windowOffset),
				Enum.Material.Glass,
				Color3.fromRGB(74, 82, 84),
				false,
				"FacadeDetail"
			)
			window.Transparency = 0.15
			window.CanQuery = false
		end
	end

	local roof = makePart(
		modules,
		"RoofModule",
		Vector3.new(41.8, 0.12, 33.8),
		Vector3.new(center.X, 24.06, center.Z),
		Enum.Material.Metal,
		Color3.fromRGB(91, 94, 92),
		false,
		"FacadeModule"
	)
	roof.CanQuery = false
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

local function buildArena(): Model
	local existing = Workspace:FindFirstChild(ARENA_NAME)
	if existing then
		if existing:IsA("Model") then
			return existing
		end
		error(ARENA_NAME .. " already exists in Workspace and is not a Model")
	end

	local arena = Instance.new("Model")
	arena.Name = ARENA_NAME
	arena:SetAttribute("ArenaSizeX", GROUND_SIZE.X)
	arena:SetAttribute("ArenaSizeZ", GROUND_SIZE.Z)
	arena:SetAttribute("RouteCount", 3)
	arena:SetAttribute("EntryCount", 2)

	local groundwork = makeFolder(arena, "Groundwork")
	makePart(
		groundwork,
		"Ground",
		GROUND_SIZE,
		Vector3.new(0, -1, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(112, 111, 104),
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

	local perimeter = makeFolder(arena, "Perimeter")
	for _, x in { -137.5, 137.5 } do
		local side = if x < 0 then "West" else "East"
		for _, z in { -63, 63 } do
			makePart(
				perimeter,
				("EntryWall_%s_%d"):format(side, z),
				Vector3.new(5, 16, 94),
				Vector3.new(x, 8, z),
				Enum.Material.Concrete,
				Color3.fromRGB(83, 84, 80),
				true,
				"Boundary"
			)
		end
	end

	local structures = makeFolder(arena, "Structures")
	for _, x in { -76, 76 } do
		for _, z in { -66, 66 } do
			local center = Vector3.new(x, 12, z)
			local building = makeFolder(structures, ("Building_%d_%d"):format(x, z))
			makePart(
				building,
				("TestBlock_%d_%d"):format(x, z),
				Vector3.new(42, 24, 34),
				center,
				Enum.Material.Concrete,
				Color3.fromRGB(139, 133, 119),
				true,
				"BuildingCore"
			)
			makeFacadeModules(building, center)
		end
	end

	local entries = makeFolder(arena, "EntryPoints")
	makeSpawn(entries, "Spawn_WestEntry", Vector3.new(-124, 0.5, 0), Color3.fromRGB(64, 150, 225))
	makeSpawn(entries, "Spawn_EastEntry", Vector3.new(124, 0.5, 0), Color3.fromRGB(225, 105, 74))

	local routeMarkers = makeFolder(arena, "RouteMarkers")
	for _, point in {
		{ name = "TestPoint_NorthRoute", position = Vector3.new(0, 0.16, -32) },
		{ name = "TestPoint_Center", position = Vector3.new(0, 0.16, 0) },
		{ name = "TestPoint_SouthRoute", position = Vector3.new(0, 0.16, 32) },
	} do
		local marker = makePart(
			routeMarkers,
			point.name,
			Vector3.new(2, 0.2, 2),
			point.position,
			Enum.Material.Neon,
			Color3.fromRGB(73, 220, 186),
			false,
			"TestPoint"
		)
		marker.CanQuery = false
	end

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

	arena.Parent = Workspace
	return arena
end

return table.freeze({
	Build = buildArena,
})
