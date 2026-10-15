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

	makePart(
		arena,
		"Ground",
		GROUND_SIZE,
		Vector3.new(0, -1, 0),
		Enum.Material.Concrete,
		Color3.fromRGB(112, 111, 104),
		true,
		"Ground"
	)

	for _, z in { -32, 0, 32 } do
		makePart(
			arena,
			("Street_EW_%d"):format(z),
			Vector3.new(280, 0.12, 18),
			Vector3.new(0, 0.06, z),
			Enum.Material.Asphalt,
			Color3.fromRGB(55, 57, 59),
			false,
			"Street"
		)
	end

	for _, x in { -42, 42 } do
		makePart(
			arena,
			("Street_NS_%d"):format(x),
			Vector3.new(12, 0.12, 220),
			Vector3.new(x, 0.06, 0),
			Enum.Material.Asphalt,
			Color3.fromRGB(55, 57, 59),
			false,
			"Street"
		)
	end

	for _, x in { -137.5, 137.5 } do
		local side = if x < 0 then "West" else "East"
		for _, z in { -63, 63 } do
			makePart(
				arena,
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

	for _, x in { -76, 76 } do
		for _, z in { -66, 66 } do
			makePart(
				arena,
				("Building_%d_%d"):format(x, z),
				Vector3.new(42, 24, 34),
				Vector3.new(x, 12, z),
				Enum.Material.Concrete,
				Color3.fromRGB(139, 133, 119),
				true,
				"Building"
			)
		end
	end

	makeSpawn(arena, "Spawn_WestEntry", Vector3.new(-124, 0.5, 0), Color3.fromRGB(64, 150, 225))
	makeSpawn(arena, "Spawn_EastEntry", Vector3.new(124, 0.5, 0), Color3.fromRGB(225, 105, 74))

	for _, point in {
		{ name = "TestPoint_NorthRoute", position = Vector3.new(0, 0.16, -32) },
		{ name = "TestPoint_Center", position = Vector3.new(0, 0.16, 0) },
		{ name = "TestPoint_SouthRoute", position = Vector3.new(0, 0.16, 32) },
	} do
		local marker = makePart(
			arena,
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

	for _, cover in {
		{ name = "Cover_NorthWest", position = Vector3.new(-24, 2.5, -32) },
		{ name = "Cover_CenterWest", position = Vector3.new(-24, 2.5, 0) },
		{ name = "Cover_SouthEast", position = Vector3.new(24, 2.5, 32) },
		{ name = "Cover_EntryWest", position = Vector3.new(-104, 2.5, -10) },
		{ name = "Cover_EntryEast", position = Vector3.new(104, 2.5, 10) },
	} do
		makePart(
			arena,
			cover.name,
			Vector3.new(12, 5, 2),
			cover.position,
			Enum.Material.Concrete,
			Color3.fromRGB(104, 101, 92),
			true,
			"Cover"
		)
	end

	arena.Parent = Workspace
	return arena
end

return table.freeze({
	Build = buildArena,
})
