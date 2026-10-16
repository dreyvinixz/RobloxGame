-- Manual Studio Edit pass for FL-016. Uses road surface and marking modules from
-- Creator Store asset 16088161488. Keep its original visual children on clones.
local DRAFT = workspace:WaitForChild("BR_Peninsula_Draft")
local TERRAIN = workspace.Terrain
local SOURCE = game:GetService("ServerStorage"):WaitForChild("BR_TerrainWorkshop")
	:WaitForChild("RoadAssetQuarantine"):WaitForChild("Wessel_Realistic_Road_Pack_QUARANTINE")
local SCALE = 1.12
local MODULE_LENGTH = 30
local STEP = 26
local ROAD_TOP_CLEARANCE = 0.65
local MAX_GRADE = 0.16
local MAX_VERTICAL_STEP = STEP * MAX_GRADE
-- Use the pack's standard straight asphalt marking across route segments.
-- Intersection, crosswalk, and corner tiles need explicit network-node placement.
local ROAD_MARKING_TEXTURE = "rbxassetid://2091416637"

local routes = DRAFT:WaitForChild("Road_Network")
local folder = DRAFT:FindFirstChild("Road_Assets_V7")
assert(not folder, "Road_Assets_V7 already exists; remove it intentionally before rebuilding")
local WORKSHOP = SOURCE.Parent.Parent
local roadSnapshot = WORKSHOP:FindFirstChild("TerrainBeforeRoadAssetsV7")
assert(not roadSnapshot, "Road foundation rollback already exists; inspect before rebuilding")

local prototypes = {}
for _, child in ipairs(SOURCE:GetChildren()) do
	if child:IsA("BasePart") and child.Size.X >= 20 and child.Size.Z >= 20 then
		local hasStandardStraightMarking = false
		for _, visual in ipairs(child:GetChildren()) do
			if (visual:IsA("Texture") or visual:IsA("Decal")) and visual.Face == Enum.NormalId.Top
				and visual.Texture == ROAD_MARKING_TEXTURE then
				hasStandardStraightMarking = true
				break
			end
		end
		if hasStandardStraightMarking then
			local prototype = child:Clone()
			prototype.Material = Enum.Material.Asphalt
			prototype.Color = Color3.fromRGB(40, 42, 44)
			prototype.Transparency = 0
			prototype.Anchored = true
			prototype.CanCollide = true
			prototype.CanTouch = false
			prototype.CanQuery = true
			table.insert(prototypes, prototype)
		end
	end
end
assert(#prototypes == 1, "The standard straight road marking was not found exactly once in the quarantined source asset")

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { TERRAIN }
params.IgnoreWater = false

local function terrainAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 1100, z), Vector3.new(0, -1500, 0), params)
	if not hit then return nil end
	return hit.Position.Y, hit.Material
end

local function pointAt(points, distance)
	local remaining = math.clamp(distance, 0, points.length)
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local dx, dz = b.X - a.X, b.Y - a.Y
		local length = math.sqrt(dx * dx + dz * dz)
		if remaining <= length or index == #points - 1 then
			local t = if length > 0 then math.clamp(remaining / length, 0, 1) else 0
			local direction = Vector3.new(dx, 0, dz).Unit
			return Vector3.new(a.X + dx * t, 0, a.Y + dz * t), direction
		end
		remaining -= length
	end
	return Vector3.new(points[#points].X, 0, points[#points].Y), Vector3.xAxis
end

local function sampleRoute(routeFolder)
	local raw = game:GetService("HttpService"):JSONDecode(routeFolder:GetAttribute("WaypointsXZ"))
	local points, total = {}, 0
	for _, pair in ipairs(raw) do
		points[#points + 1] = Vector2.new(pair[1] * SCALE, pair[2] * SCALE)
	end
	for index = 1, #points - 1 do total += (points[index + 1] - points[index]).Magnitude end
	points.length = total
	return points
end

local function removePrototypes()
	for _, prototype in ipairs(prototypes) do prototype:Destroy() end
end

local function build()
	local terrainSnapshot = TERRAIN:CopyRegion(Region3int16.new(
		Vector3int16.new(-1472 / 4, -80 / 4, -1408 / 4),
		Vector3int16.new(1472 / 4, 832 / 4, 2048 / 4)
	))
	terrainSnapshot.Name = "TerrainBeforeRoadAssetsV7"
	terrainSnapshot.Parent = WORKSHOP
	local roadFolder = Instance.new("Folder")
	roadFolder.Name = "Road_Assets_V7"
	local stagedCount, skippedWater, skippedGrade, routeCount = 0, 0, 0, 0
	local moduleIndex = 0
	for _, route in ipairs(routes:GetChildren()) do
		if route:IsA("Folder") and route:GetAttribute("WaypointsXZ") then
			local points = sampleRoute(route)
			local width = route:GetAttribute("WidthStuds") or 34
			local lanes = if width >= 40 then 2 else 1
			local laneWidth = if lanes == 2 then width / 2 else width
			local routeModel = Instance.new("Model")
			routeModel.Name = route.Name .. "_AssetSurface"
			local routeFolder = Instance.new("Folder")
			routeFolder.Name = "Modules"
			routeFolder.Parent = routeModel
			local routePlaced, routeWater, routeGrade = 0, 0, 0
			local previousRoadY
			for distance = STEP / 2, points.length, STEP do
				local center, horizontal = pointAt(points, distance)
				local before = pointAt(points, distance - STEP / 2)
				local after = pointAt(points, distance + STEP / 2)
				local side = Vector3.yAxis:Cross(horizontal).Unit
				for lane = 1, lanes do
					local laneOffset = if lanes == 2 then (lane == 1 and -laneWidth / 2 or laneWidth / 2) else 0
					local x, z = center.X + side.X * laneOffset, center.Z + side.Z * laneOffset
					local beforeY, beforeMaterial = terrainAt(before.X + side.X * laneOffset, before.Z + side.Z * laneOffset)
					local afterY, afterMaterial = terrainAt(after.X + side.X * laneOffset, after.Z + side.Z * laneOffset)
					local centerY, centerMaterial = terrainAt(x, z)
					local leftY, leftMaterial = terrainAt(x - side.X * laneWidth / 2, z - side.Z * laneWidth / 2)
					local rightY, rightMaterial = terrainAt(x + side.X * laneWidth / 2, z + side.Z * laneWidth / 2)
					if not (beforeY and afterY and centerY and leftY and rightY)
						or beforeMaterial == Enum.Material.Water or afterMaterial == Enum.Material.Water
						or centerMaterial == Enum.Material.Water or leftMaterial == Enum.Material.Water or rightMaterial == Enum.Material.Water then
						routeWater += 1
						previousRoadY = nil
					else
						local roadY = math.max(beforeY, afterY, centerY, leftY, rightY)
						if previousRoadY then roadY = math.clamp(roadY, previousRoadY - MAX_VERTICAL_STEP, previousRoadY + MAX_VERTICAL_STEP) end
						previousRoadY = roadY
						local roadCFrame = CFrame.lookAt(Vector3.new(x, roadY, z), Vector3.new(x + horizontal.X, roadY, z + horizontal.Z))
						-- Grade terrain under each short flat module so it sits level and
						-- cannot bridge a slope as a floating plate.
						TERRAIN:FillBlock(roadCFrame * CFrame.new(0, 12, 0), Vector3.new(laneWidth + 8, 32, MODULE_LENGTH + 4), Enum.Material.Air)
						TERRAIN:FillBlock(roadCFrame * CFrame.new(0, -14, 0), Vector3.new(laneWidth + 8, 28, MODULE_LENGTH + 4), Enum.Material.Ground)
						local position = Vector3.new(x, roadY + ROAD_TOP_CLEARANCE, z)
						local module = prototypes[(moduleIndex % #prototypes) + 1]:Clone()
						module.Name = ("RoadModule_%04d"):format(moduleIndex + 1)
						module.Size = Vector3.new(laneWidth, 0.6, MODULE_LENGTH)
						module.CFrame = CFrame.lookAt(position, position + horizontal)
						module:SetAttribute("SourceAssetId", "16088161488")
						module:SetAttribute("RouteName", route.Name)
						module:SetAttribute("RoadMarkingRestored", true)
						module:SetAttribute("VisualVariant", 1)
						module.Parent = routeFolder
						moduleIndex += 1
						routePlaced += 1
					end
				end
				if math.floor(distance / STEP) % 12 == 0 then task.wait() end
			end
			routeModel:SetAttribute("WidthStuds", width)
			routeModel:SetAttribute("PlacedModules", routePlaced)
			routeModel:SetAttribute("SkippedWaterModules", routeWater)
			routeModel:SetAttribute("SkippedSteepModules", routeGrade)
			routeModel.Parent = roadFolder
			stagedCount += routePlaced
			skippedWater += routeWater
			skippedGrade += routeGrade
			routeCount += 1
		end
	end
	roadFolder.Parent = DRAFT
	removePrototypes()
	DRAFT:SetAttribute("RoadNetworkV7Applied", true)
	DRAFT:SetAttribute("RoadNetworkV7AssetModules", stagedCount)
	DRAFT:SetAttribute("RoadModulesSkippedAtWater", skippedWater)
	DRAFT:SetAttribute("RoadModulesSkippedAtGrade", skippedGrade)
	local network = DRAFT:FindFirstChild("Road_Network")
	if network then
			network:SetAttribute("Status", "Straight Wessel asset road modules on graded Terrain; river gaps remain; asset review pending")
		network:SetAttribute("AssetId", "16088161488")
		network:SetAttribute("PlacedModules", stagedCount)
		network:SetAttribute("SkippedWaterModules", skippedWater)
		network:SetAttribute("SkippedSteepModules", skippedGrade)
	end
	return {status="Built",routes=routeCount,modules=stagedCount,skippedWater=skippedWater,skippedSteep=skippedGrade,assetId="16088161488"}
end

local function rollback()
	local existing = DRAFT:FindFirstChild("Road_Assets_V7")
	if existing then existing:Destroy() end
	DRAFT:SetAttribute("RoadNetworkV7Applied", false)
	DRAFT:SetAttribute("RoadNetworkV7AssetModules", 0)
	return "Road_Assets_V7 removed"
end

return build()
