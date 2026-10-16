-- Manual Studio Edit pass for the BR Peninsula draft (FL-016).
-- V10 replaces the crossed/overlapping V9 road pieces with wider, aligned
-- asphalt surfaces and longitudinal lane markings. All prior data is backed up.
local DRAFT = workspace:WaitForChild("BR_Peninsula_Draft")
local TERRAIN = workspace.Terrain
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local WORKSHOP = ServerStorage:WaitForChild("BR_TerrainWorkshop")
local SOURCE = WORKSHOP:WaitForChild("RoadAssetQuarantine"):WaitForChild("Wessel_Realistic_Road_Pack_QUARANTINE")
local ROAD_NETWORK = DRAFT:WaitForChild("Road_Network")
local ROAD_ASSET_ID = "16088161488"
local TERRAIN_BEFORE_ROAD = "TerrainBeforeRoadAssetsV7"
local TERRAIN_REPAIR_BACKUP = "TerrainBeforeRoadRepairV10"
local FAILED_GEOMETRY_BACKUP = "RoadAssets_BrokenV9"
local REGION_MIN = Vector3int16.new(-1472 / 4, -80 / 4, -1408 / 4)
local REGION_MAX = Vector3int16.new(1472 / 4, 832 / 4, 2048 / 4)
local REGION_ORIGIN = REGION_MIN
local SCALE = 1.12
local SAMPLE_SPACING = 10
local SEGMENT_LENGTH = 24
local MAX_GRADE = 0.18
local FOUNDATION_WIDTH_MARGIN = 10

assert(not game:GetService("RunService"):IsRunning(), "Run only in Studio Edit")
assert(not WORKSHOP:FindFirstChild(TERRAIN_REPAIR_BACKUP), "V10 rollback already exists; inspect it before retrying")
local originalTerrain = WORKSHOP:FindFirstChild(TERRAIN_BEFORE_ROAD)
assert(originalTerrain and originalTerrain:IsA("TerrainRegion"), "Missing TerrainBeforeRoadAssetsV7 rollback")

local prototypePart
for _, child in ipairs(SOURCE:GetChildren()) do
	if child:IsA("BasePart") and child.Size.X >= 20 and child.Size.Z >= 20 then
		prototypePart = child
		break
	end
end
assert(prototypePart, "Road surface module is missing from the quarantined asset")

local function catmullRom(a, b, c, d, t)
	local t2, t3 = t * t, t * t * t
	return Vector2.new(
		0.5 * ((2 * b.X) + (-a.X + c.X) * t + (2 * a.X - 5 * b.X + 4 * c.X - d.X) * t2 + (-a.X + 3 * b.X - 3 * c.X + d.X) * t3),
		0.5 * ((2 * b.Y) + (-a.Y + c.Y) * t + (2 * a.Y - 5 * b.Y + 4 * c.Y - d.Y) * t2 + (-a.Y + 3 * b.Y - 3 * c.Y + d.Y) * t3)
	)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { TERRAIN }
rayParams.IgnoreWater = false

local function sampleRoute(route)
	local raw = HttpService:JSONDecode(route:GetAttribute("WaypointsXZ"))
	local anchors = {}
	for _, point in ipairs(raw) do anchors[#anchors + 1] = Vector2.new(point[1] * SCALE, point[2] * SCALE) end
	local samples = {}
	for index = 1, #anchors - 1 do
		local a = anchors[math.max(1, index - 1)]
		local b, c = anchors[index], anchors[index + 1]
		local d = anchors[math.min(#anchors, index + 2)]
		local length = (c - b).Magnitude
		local steps = math.max(2, math.ceil(length / SAMPLE_SPACING))
		for step = 0, steps - 1 do samples[#samples + 1] = catmullRom(a, b, c, d, step / steps) end
	end
	samples[#samples + 1] = anchors[#anchors]
	local profile, distance = {}, 0
	for index, point in ipairs(samples) do
		if index > 1 then distance += (point - samples[index - 1]).Magnitude end
		local hit = workspace:Raycast(Vector3.new(point.X, 1100, point.Y), Vector3.new(0, -1500, 0), rayParams)
		profile[index] = { x = point.X, z = point.Y, distance = distance, y = hit and hit.Position.Y or nil, water = hit and hit.Material == Enum.Material.Water or false }
	end
	local smoothed = {}
	for index, point in ipairs(profile) do
		if point.y then
			local total, count = 0, 0
			for j = math.max(1, index - 2), math.min(#profile, index + 2) do
				if profile[j].y and not profile[j].water then total += profile[j].y; count += 1 end
			end
			smoothed[index] = count > 0 and total / count or point.y
		end
	end
	local previousY
	for index, point in ipairs(profile) do
		point.y = smoothed[index]
		if point.y and not point.water then
			if previousY then
				local ds = point.distance - profile[index - 1].distance
				point.y = math.clamp(point.y, previousY - ds * MAX_GRADE, previousY + ds * MAX_GRADE)
			end
			previousY = point.y
		else
			previousY = nil
		end
	end
	profile.length = distance
	return profile
end

local function pointAt(profile, distance)
	distance = math.clamp(distance, 0, profile.length)
	for index = 1, #profile - 1 do
		local a, b = profile[index], profile[index + 1]
		if distance <= b.distance or index == #profile - 1 then
			local span = b.distance - a.distance
			local t = span > 0 and math.clamp((distance - a.distance) / span, 0, 1) or 0
			local valid = a.y and b.y and not a.water and not b.water
			return { position = Vector3.new(a.x + (b.x - a.x) * t, valid and (a.y + (b.y - a.y) * t) or 0, a.z + (b.z - a.z) * t), valid = valid }
		end
	end
	local last = profile[#profile]
	return { position = Vector3.new(last.x, last.y or 0, last.z), valid = last.y ~= nil and not last.water }
end

local function makeStripe(parent, name, color, x, width, length, frame)
	local stripe = Instance.new("Part")
	stripe.Name = name
	stripe.Size = Vector3.new(width, 0.12, length + 0.25)
	stripe.CFrame = frame * CFrame.new(x, 4.065, 0)
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Color = color
	stripe.Anchored = true
	stripe.CanCollide = false
	stripe.CanTouch = false
	stripe.CanQuery = false
	stripe.CastShadow = false
	stripe.Parent = parent
	return stripe
end

-- Keep a full rollback, then restore the clean terrain base from before V7.
local repairSnapshot = TERRAIN:CopyRegion(Region3int16.new(REGION_MIN, REGION_MAX))
repairSnapshot.Name = TERRAIN_REPAIR_BACKUP
repairSnapshot.Parent = WORKSHOP
local brokenRoads = DRAFT:FindFirstChild("Road_Assets_V9")
if brokenRoads then
	assert(not WORKSHOP:FindFirstChild(FAILED_GEOMETRY_BACKUP), "Broken V9 geometry backup already exists")
	brokenRoads.Name = FAILED_GEOMETRY_BACKUP
	brokenRoads.Parent = WORKSHOP
end
TERRAIN:PasteRegion(originalTerrain, REGION_ORIGIN, true)

local roadFolder = Instance.new("Folder")
roadFolder.Name = "Road_Assets_V10"
roadFolder:SetAttribute("SourceAssetId", ROAD_ASSET_ID)
roadFolder:SetAttribute("AssetGateStatus", "QUARANTINED visual draft")
roadFolder:SetAttribute("SurfaceMarking", "Aligned longitudinal center and edge stripes")
roadFolder:SetAttribute("RoadWidthMode", "two-vehicle lanes with asphalt shoulders")
roadFolder.Parent = DRAFT

local totalSegments, skippedWater, routeCount = 0, 0, 0
for _, route in ipairs(ROAD_NETWORK:GetChildren()) do
	if route:IsA("Folder") and route:GetAttribute("WaypointsXZ") then
		local profile = sampleRoute(route)
		local width = math.clamp(math.max(48, (route:GetAttribute("WidthStuds") or 34) * 1.2), 48, 60)
		local routeModel = Instance.new("Model")
		routeModel.Name = route.Name .. "_AssetRoad"
		routeModel:SetAttribute("WidthStuds", width)
		local moduleFolder = Instance.new("Folder")
		moduleFolder.Name = "ConnectedSegments"
		moduleFolder.Parent = routeModel
		local routeSegments, routeWater = 0, 0
		local segmentIndex = 0
		for startDistance = 0, profile.length - 0.5, SEGMENT_LENGTH do
			local endDistance = math.min(startDistance + SEGMENT_LENGTH, profile.length)
			local a, b = pointAt(profile, startDistance), pointAt(profile, endDistance)
			if a.valid and b.valid then
				local segmentVector = b.position - a.position
				local length = segmentVector.Magnitude
				if length > 0.5 then
					local center = (a.position + b.position) * 0.5
					local segmentFrame = CFrame.lookAt(center, b.position, Vector3.yAxis)
					local foundationWidth = width + FOUNDATION_WIDTH_MARGIN
					-- Cut high terrain, lay a gray Asphalt subgrade, then place the asset surface.
					TERRAIN:FillBlock(segmentFrame * CFrame.new(0, 12, 0), Vector3.new(foundationWidth, 24, length + 1), Enum.Material.Air)
					TERRAIN:FillBlock(segmentFrame * CFrame.new(0, -4, 0), Vector3.new(foundationWidth, 8, length + 1), Enum.Material.Asphalt)
					local module = prototypePart:Clone()
					for _, visual in ipairs(module:GetChildren()) do
						if visual:IsA("Texture") or visual:IsA("Decal") then visual:Destroy() end
					end
					module.Name = ("Segment_%03d"):format(segmentIndex + 1)
					module.Size = Vector3.new(width, 4, length + 0.25)
					module.CFrame = segmentFrame * CFrame.new(0, 2, 0)
					module.Material = Enum.Material.Asphalt
					module.Color = Color3.fromRGB(46, 48, 51)
					module.Anchored = true
					module.CanCollide = true
					module.CanTouch = false
					module.CanQuery = true
					module:SetAttribute("SourceAssetId", ROAD_ASSET_ID)
					module:SetAttribute("RouteName", route.Name)
					module:SetAttribute("SegmentStart", startDistance)
					module:SetAttribute("SegmentEnd", endDistance)
					module.Parent = moduleFolder
					makeStripe(module, "CenterLine_Yellow", Color3.fromRGB(255, 190, 43), 0, 0.45, length, segmentFrame)
					makeStripe(module, "EdgeLine_Left", Color3.fromRGB(238, 238, 232), -(width / 2 - 2.5), 0.4, length, segmentFrame)
					makeStripe(module, "EdgeLine_Right", Color3.fromRGB(238, 238, 232), width / 2 - 2.5, 0.4, length, segmentFrame)
					segmentIndex += 1
					routeSegments += 1
					totalSegments += 1
				else
					routeWater += 1
				end
			else
				routeWater += 1
			end
			if segmentIndex > 0 and segmentIndex % 16 == 0 then task.wait() end
		end
		routeModel:SetAttribute("SegmentCount", routeSegments)
		routeModel:SetAttribute("SkippedWaterSegments", routeWater)
		routeModel.Parent = roadFolder
		route:SetAttribute("PlacedAssetSegmentsV10", routeSegments)
		route:SetAttribute("SkippedWaterSegmentsV10", routeWater)
		skippedWater += routeWater
		routeCount += 1
	end
end

roadFolder:SetAttribute("Applied", true)
roadFolder:SetAttribute("RouteCount", routeCount)
roadFolder:SetAttribute("SegmentCount", totalSegments)
roadFolder:SetAttribute("SkippedWaterSegments", skippedWater)
DRAFT:SetAttribute("RoadNetworkV10Applied", true)
local network = DRAFT:FindFirstChild("Road_Network")
if network then
	network:SetAttribute("Status", "V10: connected wider asphalt asset surfaces; longitudinal lane lines; river crossings skipped")
	network:SetAttribute("AssetId", ROAD_ASSET_ID)
	network:SetAttribute("PlacedAssetSegmentsV10", totalSegments)
	network:SetAttribute("SkippedWaterSegmentsV10", skippedWater)
end
return { status = "Built", routes = routeCount, segments = totalSegments, skippedWater = skippedWater, widthStuds = "48-60", backups = repairSnapshot:GetFullName() .. "; " .. FAILED_GEOMETRY_BACKUP }
