-- Manual Studio Edit tool for FL-016. Not mapped by Rojo or executed at runtime.
-- Load this file as a function body returning Sculpt, then call prepare(),
-- generate(zStart, zEnd) in 32-stud aligned batches, and finish().
-- V6 keeps the previous TerrainRegion in ServerStorage for rollback.
local Sculpt = {}
local terrain = workspace.Terrain
local storage = game:GetService("ServerStorage")
-- V6 uses the layout grid at full scale. V5 compressed every region to 80%.
local SCALE = 1.0
local HEIGHT_SCALE = 1.15
local X_MIN, X_MAX = -1280, 1280
local Z_MIN, Z_MAX = -1280, 1792
local Y_MIN, Y_MAX = -80, 768
local RES = 4

-- One continuous, broad peninsula: curved south beach, open lowland center,
-- broken coastal headlands, and a northern shelf for the mountain range.
local coast = {
	{-760, -900}, {-900, -760}, {-930, -450}, {-840, -180},
	{-890, 80}, {-810, 360}, {-780, 650}, {-620, 900},
	{-820, 1120}, {-970, 1370}, {-1020, 1640}, {-600, 1690},
	{-180, 1630}, {260, 1700}, {680, 1660}, {1000, 1510},
	{960, 1290}, {850, 1160}, {930, 880}, {860, 610},
	{920, 340}, {840, 80}, {900, -180}, {790, -440},
	{650, -700}, {430, -880}, {140, -960}, {-160, -950},
	{-430, -930}, {-650, -920},
}
local shore = {
	{-650, -920}, {-430, -930}, {-160, -950}, {140, -960},
	{430, -880}, {650, -700},
}
local dunePeaks = {
	{-500, -790, 120, 78, 8}, {-300, -815, 145, 88, 12},
	{-70, -820, 150, 92, 14}, {180, -790, 145, 90, 11},
	{420, -720, 125, 82, 9}, {-390, -625, 100, 70, 5},
	{40, -630, 115, 76, 6}, {330, -630, 105, 72, 6},
}

-- Asset pads stay level inside their placement footprint, with a broad,
-- natural transition outside it. The river is deliberately routed between
-- the two city pads so building pivots remain level and clear of the banks.
local flatPads = {
	{ -510, 80, 250, 210, 84 }, -- military compound
	{ -165, 260, 155, 190, 45 }, -- west city district
	{ 205, 285, 155, 185, 47 }, -- east city district
	{ 500, 470, 205, 170, 53 }, -- industrial quarter
	{ 700, 30, 155, 160, 20 }, -- port logistics yard
	{ -700, 400, 85, 75, 96 }, -- west team staging pad
	{ 760, 390, 85, 75, 76 }, -- east team staging pad
	{ 0, -860, 220, 70, 4 }, -- beach asset footprint
	{ 0, -735, 260, 85, 14 }, -- dune asset footprint
	{ 390, 720, 95, 65, 100 }, -- natural ridge asset footprint
	{ 0, 1100, 80, 65, 210 }, -- mountain observation footprint
}

local riverPoints = {
	{ -215, 1120, 150 }, { -270, 900, 126 }, { -190, 710, 103 },
	{ -90, 545, 82 }, { -45, 395, 65 }, { 25, 265, 50 },
	{ 135, 150, 37 }, { 300, 75, 23 }, { 500, 90, 12 },
	{ 690, 135, 4 }, { 870, 170, 0 },
}

local function smooth(a, b, value)
	local t = math.clamp((value - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function gaussian(x, z, cx, cz, rx, rz)
	return math.exp(-(((x - cx) / rx) ^ 2 + ((z - cz) / rz) ^ 2) * 2)
end

local function applyFlatPads(x, z, height)
	for _, pad in ipairs(flatPads) do
		local dx, dz = (x - pad[1]) / pad[3], (z - pad[2]) / pad[4]
		local radius = math.sqrt(dx * dx + dz * dz)
		local weight = 1 - smooth(0.78, 1.34, radius)
		height += (pad[5] - height) * weight
	end
	return height
end

local function riverProfile(x, z)
	local bestDistance, bestLevel = math.huge, 0
	for index = 1, #riverPoints - 1 do
		local a, b = riverPoints[index], riverPoints[index + 1]
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local t = math.clamp(((x - a[1]) * dx + (z - a[2]) * dz) / (dx * dx + dz * dz), 0, 1)
		local ox, oz = x - (a[1] + dx * t), z - (a[2] + dz * t)
		local distance = math.sqrt(ox * ox + oz * oz)
		if distance < bestDistance then
			bestDistance = distance
			bestLevel = a[3] + (b[3] - a[3]) * t
		end
	end
	local width = 34 + math.noise(x / 95, z / 95, 57) * 5
	return bestDistance, bestLevel, width
end

local function coastDistance(x, z)
	local inside, distanceSq = false, math.huge
	local previous = coast[#coast]
	for _, current in ipairs(coast) do
		local ax, az, bx, bz = previous[1], previous[2], current[1], current[2]
		if (az > z) ~= (bz > z) and x < (bx - ax) * (z - az) / (bz - az) + ax then
			inside = not inside
		end
		local dx, dz = bx - ax, bz - az
		local t = math.clamp(((x - ax) * dx + (z - az) * dz) / (dx * dx + dz * dz), 0, 1)
		local px, pz = x - (ax + t * dx), z - (az + t * dz)
		distanceSq = math.min(distanceSq, px * px + pz * pz)
		previous = current
	end
	return math.sqrt(distanceSq) * (inside and 1 or -1)
end

local function beachShore(x)
	for i = 1, #shore - 1 do
		local a, b = shore[i], shore[i + 1]
		if x >= a[1] and x <= b[1] then
			local t = (x - a[1]) / (b[1] - a[1])
			return a[2] + t * (b[2] - a[2])
		end
	end
	if x < shore[1][1] then return shore[1][2] end
	return shore[#shore][2]
end

local function surface(worldX, worldZ)
	local x, z = worldX / SCALE, worldZ / SCALE
	local signed = coastDistance(x, z)
	-- Break up coastline segments without adding little pits to buildable areas.
	local edgeNoise = math.noise(x / 62, z / 62, 17) * 13 + math.noise(x / 24, z / 24, 5) * 4
	local d = signed + edgeNoise
	local lowNoise = math.noise(x / 320, z / 320, 8) * 21 + math.noise(x / 135, z / 135, 3) * 9
	local highland = math.max(
		78 * gaussian(x, z, -650, 420, 350, 360),
		96 * gaussian(x, z, -210, 720, 390, 360),
		82 * gaussian(x, z, 300, 570, 360, 340),
		68 * gaussian(x, z, 690, 240, 280, 300)
	)
	local h = 24 + lowNoise + highland
	local militaryMask = gaussian(x, z, -510, 60, 310, 330)
	h += (76 + lowNoise * 0.25 - h) * militaryMask * 0.93
	local cityMask = gaussian(x, z, 20, 245, 390, 410)
	h += (38 + lowNoise * 0.4 - h) * cityMask * 0.8
	local portMask = gaussian(x, z, 675, 90, 220, 410)
	h += (12 + lowNoise * 0.12 - h) * portMask * 0.97
	local industryMask = gaussian(x, z, 470, 520, 260, 270)
	h += (37 + lowNoise * 0.3 - h) * industryMask * 0.8
	-- Several broken ridges frame the city and give the roads visible altitude changes.
	h += 82 * gaussian(x, z, 610, -160, 190, 300)
	h += 104 * gaussian(x, z, 650, 260, 185, 260)
	h += 112 * gaussian(x, z, 500, 620, 220, 250)
	h += 128 * gaussian(x, z, -760, 600, 175, 250)
	h += 112 * gaussian(x, z, -620, 870, 190, 235)
	h += 106 * gaussian(x, z, 320, 850, 180, 255)
	local brokenRidge = math.max(
		gaussian(x, z, -730, 720, 190, 470),
		gaussian(x, z, 420, 740, 210, 430)
	)
	local ridgeNoise = 1 - math.abs(math.noise(x / 92, z / 150, 61) * 2)
	h += math.max(0, ridgeNoise - 0.35) * 74 * brokenRidge
	-- Rocky headlands frame the crescent beach.
	h += 38 * gaussian(x, z, -790, -770, 180, 180)
	h += 36 * gaussian(x, z, 760, -580, 150, 190)
	local north = smooth(760, 1120, z)
	if north > 0 then
		local ridgeBase = 168 * gaussian(x, z, 0, 1370, 1250, 430)
		local mountain = math.max(
			218 * gaussian(x, z, -900, 1370, 240, 300),
			282 * gaussian(x, z, -630, 1490, 235, 330),
			206 * gaussian(x, z, -350, 1320, 235, 290),
			318 * gaussian(x, z, -80, 1480, 235, 330),
			220 * gaussian(x, z, 220, 1310, 245, 300),
			326 * gaussian(x, z, 500, 1480, 245, 340),
			238 * gaussian(x, z, 790, 1370, 250, 310),
			208 * gaussian(x, z, 980, 1480, 240, 330)
		)
		local ridged = 1 - math.abs(math.noise(x / 140, z / 205, 12) * 2)
		local rough = (ridged - 0.52) * 82 + math.noise(x / 72, z / 86, 9) * 28
		local mountainFloor = 54 + ridgeBase + mountain + rough
		h = h * (1 - north) + mountainFloor * north
	end
	-- Broad saddles keep several routes open through the foothills.
	local valley = 48 * gaussian(x, z, -280, 920, 120, 390)
	h = math.max(9, h - valley)
	local landH = -9 + (h + 9) * smooth(-10, 86, d)
	local oceanH = -9 - (64 / HEIGHT_SCALE - 9) * smooth(0, 200, -d)
	local finalH = d >= -10 and landH or oceanH
	local mat = Enum.Material.Grass
	if d < 62 or (north > 0.5 and h > 170) then
		mat = Enum.Material.Rock
	end
	-- Recessed bay with a shallow beach. Individual overlapping dune mounds
	-- replace the old continuous bands; inland sand blends into grassy slopes.
	local beachMask = smooth(-760, -640, x) * (1 - smooth(640, 760, x))
	local u = z - beachShore(x)
	if beachMask > 0 and u > -140 and u < 520 then
		local sandH = 0.8 + math.max(0, u) * 0.026
		if u < 0 then sandH = u * 0.14 end
		for _, dune in ipairs(dunePeaks) do
			sandH += dune[5] * gaussian(x, z, dune[1], dune[2], dune[3], dune[4])
		end
		sandH += math.noise(x / 85, z / 85, 31) * 1.4 * smooth(25, 110, u)
		local inlandBlend = smooth(210, 370, u)
		local desired = sandH * (1 - inlandBlend) + landH * inlandBlend
		finalH += (desired - finalH) * beachMask
		if beachMask > 0.45 and u < 300 then mat = Enum.Material.Sand end
	end
	if finalH < -1 and d > -140 then mat = Enum.Material.Sand end
	finalH *= HEIGHT_SCALE
	finalH = applyFlatPads(x, z, finalH)
	local riverDistance, riverLevel, riverWidth = riverProfile(x, z)
	local inRiver = riverDistance < riverWidth + 10 and d > 0
	if inRiver then
		local bank = 1 - smooth(riverWidth + 10, riverWidth + 105, riverDistance)
		local channel = 1 - smooth(riverWidth - 7, riverWidth + 7, riverDistance)
		local waterY = math.min(riverLevel * HEIGHT_SCALE, finalH - 5)
		finalH -= bank * 19
		finalH += (waterY - 12 - finalH) * channel
		mat = if channel > 0.25 then Enum.Material.Rock else mat
		return finalH, mat, if riverDistance < riverWidth then waterY else nil
	end
	return finalH, mat, nil
end

local function workshop()
	local folder = storage:FindFirstChild("BR_TerrainWorkshop")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "BR_TerrainWorkshop"
		folder.Parent = storage
	end
	return folder
end

function Sculpt.prepare()
	assert(not game:GetService("RunService"):IsRunning(), "Run only in Studio Edit")
	local work = workshop()
	assert(not work:GetAttribute("PreparedIslandV6"), "Island V6 already prepared; generate the remaining ranges instead")
	assert(not work:FindFirstChild("TerrainBeforeIslandV6"), "V6 rollback snapshot already exists; review or restore it before preparing again")
	local backup = terrain:CopyRegion(Region3int16.new(
		Vector3int16.new(X_MIN / 4, Y_MIN / 4, Z_MIN / 4),
		Vector3int16.new(X_MAX / 4, Y_MAX / 4, Z_MAX / 4)
	))
	backup.Name = "TerrainBeforeIslandV6"
	backup.Parent = work
	local draft = workspace:FindFirstChild("BR_Peninsula_Draft")
	assert(draft, "Missing BR_Peninsula_Draft")
	local moved = work:GetAttribute("HeldModels") or 0
	for z = Z_MIN, Z_MAX - 1, 128 do
		local depth = math.min(128, Z_MAX-z)
		terrain:FillBlock(CFrame.new(0, (Y_MIN + Y_MAX) / 2, z + depth/2), Vector3.new(X_MAX - X_MIN, Y_MAX - Y_MIN, depth), Enum.Material.Air)
		task.wait()
	end
	for z = Z_MIN - 1024, Z_MAX + 1024, 512 do
		terrain:FillBlock(CFrame.new(0, -32, z + 256), Vector3.new(X_MAX - X_MIN + 2048, 64, 512), Enum.Material.Water)
		task.wait()
	end
	terrain.WaterColor = Color3.fromRGB(23, 91, 116)
	terrain.WaterTransparency = 0.2
	terrain.WaterReflectance = 0.2
	terrain.WaterWaveSize = 0.18
	terrain.WaterWaveSpeed = 8
	-- Decoration exists in the API reference but is unavailable in some builds.
	pcall(function() terrain.Decoration = true end)
	for name, color in pairs({Grass=Color3.fromRGB(93,110,62),Sand=Color3.fromRGB(204,184,143),Rock=Color3.fromRGB(100,102,95),Ground=Color3.fromRGB(111,99,75)}) do
		terrain:SetMaterialColor(Enum.Material[name], color)
	end
	local atmosphere = game.Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0.16
	end
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		for _, child in ipairs(baseplate:GetChildren()) do
			if child:IsA("Texture") or child:IsA("Decal") then
				child.Transparency = 1
			end
		end
	end
	draft:SetAttribute("Status", "Terrain V6 only; sculpt in progress")
	draft:SetAttribute("AssetsPlacedCount", 0)
	draft:SetAttribute("AssetsPlaced", false)
	draft:SetAttribute("TerrainShapeVersion", 6)
	draft:SetAttribute("RoadNetworkV4Applied", false)
	draft:SetAttribute("RoadNetworkV6Applied", false)
	draft:SetAttribute("RoadSurfaceCells", 0)
	draft:SetAttribute("RoadShoulderCells", 0)
	draft:SetAttribute("RoadGradedVoxelCells", 0)
	work:SetAttribute("HeldModels", moved)
	work:SetAttribute("PreparedIslandV6", true)
	return {heldModels=moved, backup=backup:GetFullName(), seaLevel=0, bounds={X_MIN,X_MAX,Z_MIN,Z_MAX}}
end

function Sculpt.prepareRefinement(snapshotName)
	assert(not game:GetService("RunService"):IsRunning(), "Run only in Studio Edit")
	local work = workshop()
	assert(work:GetAttribute("PreparedIslandV6"), "V6 must be generated before refinement")
	snapshotName = snapshotName or "TerrainBeforeIslandV6Refinement"
	assert(type(snapshotName) == "string" and snapshotName:match("^TerrainBefore[%w_]+$"), "Invalid snapshot name")
	assert(not work:FindFirstChild(snapshotName), "Snapshot already exists: " .. snapshotName)
	local backup = terrain:CopyRegion(Region3int16.new(
		Vector3int16.new(X_MIN / 4, Y_MIN / 4, Z_MIN / 4),
		Vector3int16.new(X_MAX / 4, Y_MAX / 4, Z_MAX / 4)
	))
	backup.Name = snapshotName
	backup.Parent = work
	for z = Z_MIN, Z_MAX - 1, 128 do
		local depth = math.min(128, Z_MAX-z)
		terrain:FillBlock(CFrame.new(0, (Y_MIN + Y_MAX) / 2, z + depth/2), Vector3.new(X_MAX - X_MIN, Y_MAX - Y_MIN, depth), Enum.Material.Air)
		task.wait()
	end
	for z = Z_MIN - 1024, Z_MAX + 1024, 512 do
		terrain:FillBlock(CFrame.new(0, -32, z + 256), Vector3.new(X_MAX - X_MIN + 2048, 64, 512), Enum.Material.Water)
		task.wait()
	end
	work:SetAttribute("LastGeneratedZ", nil)
	work:SetAttribute("PreparedIslandV6", true)
	local draft = workspace:FindFirstChild("BR_Peninsula_Draft")
	if draft then
		draft:SetAttribute("RoadNetworkV6Applied", false)
		draft:SetAttribute("RoadNetworkV4Applied", false)
		draft:SetAttribute("RoadSurfaceCells", 0)
		draft:SetAttribute("RoadShoulderCells", 0)
		draft:SetAttribute("RoadGradedVoxelCells", 0)
	end
	return {backup=backup:GetFullName(), bounds={X_MIN,X_MAX,Z_MIN,Z_MAX}}
end

function Sculpt.generate(zStart, zEnd)
	local work = workshop()
	assert(work:GetAttribute("PreparedIslandV6"), "Call prepare first")
	assert(zStart >= Z_MIN and zEnd <= Z_MAX and zStart < zEnd and (zStart-Z_MIN)%32==0 and (zEnd-Z_MIN)%32==0, "Invalid range")
	local count, highest = 0, -math.huge
	local nx, nz = (X_MAX - X_MIN) / RES, 8
	for z0 = zStart, zEnd - 32, 32 do
		local columns, maxHeight = table.create(nx), 0
		for ix=1,nx do
			columns[ix] = table.create(nz)
			for iz=1,nz do
				local x,z = X_MIN+(ix-0.5)*RES,z0+(iz-0.5)*RES
				local h,mat,riverWater = surface(x,z)
				if mat==Enum.Material.Grass then
					local hx=surface(x+8,z)
					local hz=surface(x,z+8)
					if (math.abs(hx-h)+math.abs(hz-h))/8>0.52 then mat=Enum.Material.Rock end
				end
				columns[ix][iz] = {h,mat,riverWater}
				maxHeight = math.max(maxHeight,h)
			end
		end
		-- Always overwrite the complete reserved height so later sculpt passes
		-- can lower peaks without leaving old floating voxels above them.
		local top = Y_MAX
		local ny = (top - Y_MIN) / RES
		local materials,occupancies = table.create(nx),table.create(nx)
		for ix=1,nx do
			materials[ix],occupancies[ix] = table.create(ny),table.create(ny)
			for iy=1,ny do
				local mrow,orow = table.create(nz),table.create(nz)
				local bottom = Y_MIN+(iy-1)*RES
				for iz=1,nz do
					local column = columns[ix][iz]
					local h,mat,riverWater = column[1],column[2],column[3]
					local amount = math.clamp((h-bottom)/RES,0,1)
					if amount>0 then
						mrow[iz] = (bottom < h-10 and mat ~= Enum.Material.Sand) and Enum.Material.Rock or mat
						orow[iz] = amount
					elseif riverWater and bottom < riverWater then
						mrow[iz],orow[iz] = Enum.Material.Water,1
					elseif bottom<0 then
						mrow[iz],orow[iz] = Enum.Material.Water,1
					else
						mrow[iz],orow[iz] = Enum.Material.Air,0
					end
				end
				materials[ix][iy],occupancies[ix][iy] = mrow,orow
			end
		end
		terrain:WriteVoxels(Region3.new(Vector3.new(X_MIN,Y_MIN,z0),Vector3.new(X_MAX,top,z0+32)),RES,materials,occupancies)
		count += nx*nz
		highest = math.max(highest,maxHeight)
		work:SetAttribute("LastGeneratedZ", z0+32)
		task.wait()
	end
	return {from=zStart,to=zEnd,columns=count,highest=highest}
end

function Sculpt.finish()
	local draft = workspace.BR_Peninsula_Draft
	draft:SetAttribute("Status", "Terrain V6 visual draft; owner review pending")
	draft:SetAttribute("TerrainShapeVersion", 6)
	draft:SetAttribute("TerrainHeightProfile", "full-scale peninsula, broad multi-ridge mountain wall, exposed rock outcrops, separated buildable plateaus, and a navigable river through the city to the port")
	draft:SetAttribute("RiverRoute", "north foothills -> west city -> central city -> east logistics -> east coast")
	draft:SetAttribute("RiverWidthStuds", 68)
	draft:SetAttribute("BuildableFlatPads", "military, west city, east city, industry, port, west staging, east staging")
	draft:SetAttribute("AsphaltRemoved", true)
	draft:SetAttribute("SeaLevel", 0)
	draft:SetAttribute("TerrainBoundsMin", Vector3.new(X_MIN,Y_MIN,Z_MIN))
	draft:SetAttribute("TerrainBoundsMax", Vector3.new(X_MAX,Y_MAX,Z_MAX))
	local zones = draft:FindFirstChild("Terrain_Zones") or Instance.new("Folder")
	zones.Name="Terrain_Zones";zones.Parent=draft
	for _,zone in ipairs({
		{"01_Praia_NivelMar",Vector3.new(0,3,-660)},
		{"02_Dunas",Vector3.new(-80,12,-480)},
		{"03_Corredor_Costeiro_SemPavimento",Vector3.new(0,18,-340)},
		{"04_Terreno_Porto",Vector3.new(540,12,70)},
		{"05_Terreno_Industria",Vector3.new(376,35,416)},
		{"06_Vale_Cidade",Vector3.new(16,40,196)},
		{"07_Plato_Militar",Vector3.new(-408,65,48)},
		{"08_Morros_Montanhas_Norte",Vector3.new(0,180,1200)},
	}) do
		local folder=zones:FindFirstChild(zone[1]) or Instance.new("Folder")
		folder.Name=zone[1];folder:SetAttribute("ViewTarget",zone[2]);folder.Parent=zones
	end
	local pads = draft:FindFirstChild("Buildable_Pads") or Instance.new("Folder")
	pads.Name = "Buildable_Pads"
	pads:SetAttribute("FlatInteriorRatio", 0.78)
	pads:SetAttribute("TerrainShapeVersion", 6)
	pads.Parent = draft
	for _, pad in ipairs({
		{"Beach_Asset_Pad", 0, -860, 343, 109, 4},
		{"Dunes_Asset_Pad", 0, -735, 406, 132, 14},
		{"Military_Compound_Pad", -510, 80, 390, 328, 84},
		{"City_West_Pad", -165, 260, 242, 296, 45},
		{"City_East_Pad", 205, 285, 242, 288, 47},
		{"Industrial_Yard_Pad", 500, 470, 320, 265, 53},
		{"Port_Logistics_Pad", 700, 30, 242, 250, 20},
		{"Natural_Ridge_Pad", 390, 720, 148, 101, 100},
		{"Mountain_Observation_Pad", 0, 1100, 124, 101, 210},
		{"Blue_Staging_Pad", -700, 400, 132, 117, 96},
		{"Orange_Staging_Pad", 760, 390, 132, 117, 76},
	}) do
		local marker = pads:FindFirstChild(pad[1]) or Instance.new("Folder")
		marker.Name = pad[1]
		marker:SetAttribute("CenterStuds", Vector3.new(pad[2], pad[6], pad[3]))
		marker:SetAttribute("FlatBoundsStuds", Vector3.new(pad[4], 0, pad[5]))
		marker:SetAttribute("TargetHeightStuds", pad[6])
		marker:SetAttribute("PlacementSurface", "Roblox Terrain; flat inner footprint")
		marker.Parent = pads
	end
	local camera=workspace.CurrentCamera
	camera.FieldOfView=50
	camera.CFrame=CFrame.lookAt(Vector3.new(0,820,-1500),Vector3.new(0,80,300))
	camera.Focus=CFrame.new(0,80,300)
	workshop():SetAttribute("Status", "Terrain V6 refined; flat asset pads reserved; assets held; roads must be rebuilt")
	return {status=draft:GetAttribute("Status"),held=workshop():GetAttribute("HeldModels"),seaLevel=0}
end

function Sculpt.snapshotCurrent(name)
	assert(not game:GetService("RunService"):IsRunning(), "Run only in Studio Edit")
	assert(type(name) == "string" and name:match("^TerrainBefore[%w_]+$"), "Use a TerrainBefore... snapshot name")
	local work = workshop()
	assert(not work:FindFirstChild(name), "Snapshot already exists: " .. name)
	local backup = terrain:CopyRegion(Region3int16.new(
		Vector3int16.new(X_MIN / 4, Y_MIN / 4, Z_MIN / 4),
		Vector3int16.new(X_MAX / 4, Y_MAX / 4, Z_MAX / 4)
	))
	backup.Name = name
	backup.Parent = work
	return {backup=backup:GetFullName(), bounds={X_MIN,X_MAX,Z_MIN,Z_MAX}}
end

function Sculpt.restorePrevious(snapshotName)
	assert(not game:GetService("RunService"):IsRunning(), "Run only in Studio Edit")
	local work = workshop()
	snapshotName = snapshotName or "TerrainBeforeIslandV6"
	local backup = work:FindFirstChild(snapshotName)
	assert(backup and backup:IsA("TerrainRegion"), "Missing " .. snapshotName .. " snapshot")
	local origin = if snapshotName == "TerrainBeforeIslandV6" then Vector3int16.new(X_MIN / 4, Y_MIN / 4, Z_MIN / 4) else Vector3int16.new(-960 / 4, -64 / 4, -960 / 4)
	terrain:PasteRegion(backup, origin, true)
	local restoredV6 = snapshotName == "TerrainBeforeIslandV6Refinement"
		or snapshotName == "TerrainBeforeRoadNetworkV6"
		or snapshotName == "TerrainBeforeRoadNetworkV6Refinement"
	work:SetAttribute("PreparedIslandV6", restoredV6)
	work:SetAttribute("PreparedReferencePass", false)
	work:SetAttribute("Status", "Previous terrain restored from " .. snapshotName)
	local draft = workspace:FindFirstChild("BR_Peninsula_Draft")
	if draft then
		local version = if snapshotName == "TerrainBeforeReferencePass" then 3
			elseif snapshotName == "TerrainBeforeMountainWideningV4" then 4
			elseif restoredV6 then 6
			else 5
		draft:SetAttribute("TerrainShapeVersion", version)
		draft:SetAttribute("Status", "Terrain V" .. version .. " restored; owner review pending")
		local minBounds = if version == 6 then Vector3.new(X_MIN,Y_MIN,Z_MIN) else Vector3.new(-960,-64,-960)
		local maxBounds = if version == 6 then Vector3.new(X_MAX,Y_MAX,Z_MAX) else Vector3.new(960,384,1536)
		draft:SetAttribute("TerrainBoundsMin", minBounds)
		draft:SetAttribute("TerrainBoundsMax", maxBounds)
	end
	return {status=work:GetAttribute("Status"), restored=backup.Name}
end

return Sculpt
