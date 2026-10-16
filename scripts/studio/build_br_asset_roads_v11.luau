-- FL-016 V11: continuous terrain asphalt replaces segmented road slabs.
-- Surface markings are thin, route-aligned strips; old geometry and terrain stay backed up.
local DRAFT = workspace:WaitForChild("BR_Peninsula_Draft")
local TERRAIN = workspace.Terrain
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local WORKSHOP = ServerStorage:WaitForChild("BR_TerrainWorkshop")
local ROAD_NETWORK = DRAFT:WaitForChild("Road_Network")
local SOURCE_TERRAIN = WORKSHOP:WaitForChild("TerrainBeforeRoadAssetsV7")
local TERRAIN_BACKUP_NAME = "TerrainBeforeRoadRepairV11"
local GEOMETRY_BACKUP_NAME = "RoadAssets_BrokenV10"
local RESOLUTION, TILE_SIZE = 4, 64
local X_MIN, X_MAX, Y_MIN, Y_MAX, Z_MIN, Z_MAX = -1472, 1472, -80, 832, -1408, 2048
local SAMPLE_SPACING, SAMPLE_SPACING_XZ, MAX_GRADE = 10, 8, 0.18
local STRIPE_SEGMENT_LENGTH = 24
local ACTION = "apply"

assert(not RunService:IsRunning(), "Run only in Studio Edit")
assert(SOURCE_TERRAIN:IsA("TerrainRegion"), "Clean terrain rollback is missing")
assert(not WORKSHOP:FindFirstChild(TERRAIN_BACKUP_NAME), "V11 rollback already exists")
assert(not WORKSHOP:FindFirstChild(GEOMETRY_BACKUP_NAME), "V10 geometry backup already exists")

local function catmullRom(a,b,c,d,t)
	local t2,t3=t*t,t*t*t
	return Vector2.new(
		0.5*((2*b.X)+(-a.X+c.X)*t+(2*a.X-5*b.X+4*c.X-d.X)*t2+(-a.X+3*b.X-3*c.X+d.X)*t3),
		0.5*((2*b.Y)+(-a.Y+c.Y)*t+(2*a.Y-5*b.Y+4*c.Y-d.Y)*t2+(-a.Y+3*b.Y-3*c.Y+d.Y)*t3)
	)
end

local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances={TERRAIN}
rayParams.IgnoreWater=false

local function sampleRoute(route)
	local raw=HttpService:JSONDecode(route:GetAttribute("WaypointsXZ"))
	local anchors={}
	for _,point in ipairs(raw) do anchors[#anchors+1]=Vector2.new(point[1]*1.12,point[2]*1.12) end
	local points={}
	for i=1,#anchors-1 do
		local a,b,c,d=anchors[math.max(1,i-1)],anchors[i],anchors[i+1],anchors[math.min(#anchors,i+2)]
		local steps=math.max(2,math.ceil((c-b).Magnitude/SAMPLE_SPACING_XZ))
		for step=0,steps-1 do points[#points+1]=catmullRom(a,b,c,d,step/steps) end
	end
	points[#points+1]=anchors[#anchors]
	local profile,total={},0
	for i,p in ipairs(points) do
		if i>1 then total+=(p-points[i-1]).Magnitude end
		local hit=workspace:Raycast(Vector3.new(p.X,1100,p.Y),Vector3.new(0,-1500,0),rayParams)
		profile[i]={x=p.X,z=p.Y,distance=total,y=hit and hit.Position.Y or nil,water=hit and hit.Material==Enum.Material.Water or false}
	end
	local smoothed={}
	for i,p in ipairs(profile) do
		if p.y and not p.water then
			local sum,n=0,0
			for j=math.max(1,i-2),math.min(#profile,i+2) do
				if profile[j].y and not profile[j].water then sum+=profile[j].y;n+=1 end
			end
			smoothed[i]=n>0 and sum/n or p.y
		end
	end
	local lastY
	for i,p in ipairs(profile) do
		p.y=smoothed[i]
		if p.y and not p.water then
			if lastY then local ds=p.distance-profile[i-1].distance;p.y=math.clamp(p.y,lastY-ds*MAX_GRADE,lastY+ds*MAX_GRADE) end
			lastY=p.y
		else lastY=nil end
	end
	profile.length=total
	return profile
end

local function pointAt(profile,distance)
	distance=math.clamp(distance,0,profile.length)
	for i=1,#profile-1 do
		local a,b=profile[i],profile[i+1]
		if distance<=b.distance or i==#profile-1 then
			local span=b.distance-a.distance
			local t=span>0 and math.clamp((distance-a.distance)/span,0,1) or 0
			local valid=a.y and b.y and not a.water and not b.water
			return {x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t,y=valid and (a.y+(b.y-a.y)*t) or nil,water=a.water or b.water,valid=valid}
		end
	end
	local p=profile[#profile]
	return {x=p.x,z=p.z,y=p.y,water=p.water,valid=p.y~=nil and not p.water}
end

local function buildCells()
	local tiles={}
	local function getTile(tx,tz)
		local key=tx..":"..tz
		if not tiles[key] then tiles[key]={x=tx,z=tz,cells={}} end
		return tiles[key]
	end
	local routeProfiles={}
	for _,route in ipairs(ROAD_NETWORK:GetChildren()) do
		if route:IsA("Folder") and route:GetAttribute("WaypointsXZ") then
			local profile=sampleRoute(route)
			routeProfiles[route.Name]={route=route,profile=profile,width=math.clamp(math.max(48,(route:GetAttribute("WidthStuds") or 34)*1.2),48,60)}
			for i,p in ipairs(profile) do
				local nextP=profile[math.min(i+1,#profile)]
				if p.y and not p.water then
					local delta=Vector2.new(nextP.x-p.x,nextP.z-p.z)
					local tangent=delta.Magnitude>0 and delta.Unit or Vector2.new(1,0)
					local radius=routeProfiles[route.Name].width/2+2
					local gx,gz=math.floor(p.x/4),math.floor(p.z/4)
					local reach=math.ceil(radius/4)
					for dx=-reach,reach do for dz=-reach,reach do
						local wx,wz=(gx+dx+0.5)*4,(gz+dz+0.5)*4
						local ox,oz=wx-p.x,wz-p.z
						local d2=ox*ox+oz*oz
						if d2<=radius*radius and wx>=X_MIN and wx<X_MAX and wz>=Z_MIN and wz<Z_MAX then
							local projected=math.clamp(Vector2.new(ox,oz):Dot(tangent)/math.max(delta.Magnitude,1),0,1)
							local grade=p.y+((nextP.y or p.y)-p.y)*projected
							local tx,tz=math.floor(wx/TILE_SIZE),math.floor(wz/TILE_SIZE)
							local tile=getTile(tx,tz)
							local lx=math.floor((wx-tx*TILE_SIZE)/4)+1
							local lz=math.floor((wz-tz*TILE_SIZE)/4)+1
							local key=(lx-1)*16+lz
							local previous=tile.cells[key]
							if not previous or d2<previous.distanceSquared then tile.cells[key]={height=grade,distanceSquared=d2} end
						end
					end end
				end
			end
		end
	end
	local result={}
	for _,tile in pairs(tiles) do result[#result+1]=tile end
	table.sort(result,function(a,b) if a.x==b.x then return a.z<b.z end return a.x<b.x end)
	return result,routeProfiles
end

local function addStripe(parent,name,color,x,width,length,frame,surfaceY)
	local stripe=Instance.new("Part")
	stripe.Name=name
	stripe.Size=Vector3.new(width,0.12,length+0.5)
	stripe.CFrame=frame*CFrame.new(x,surfaceY+0.13,0)
	stripe.Material=Enum.Material.SmoothPlastic
	stripe.Color=color
	stripe.Anchored=true
	stripe.CanCollide=false
	stripe.CanTouch=false
	stripe.CanQuery=false
	stripe.CastShadow=false
	stripe.Parent=parent
end

local snapshot=TERRAIN:CopyRegion(Region3int16.new(Vector3int16.new(X_MIN/4,Y_MIN/4,Z_MIN/4),Vector3int16.new(X_MAX/4,Y_MAX/4,Z_MAX/4)))
snapshot.Name=TERRAIN_BACKUP_NAME
snapshot.Parent=WORKSHOP
local oldFolder=DRAFT:FindFirstChild("Road_Assets_V10")
if oldFolder then oldFolder.Name=GEOMETRY_BACKUP_NAME;oldFolder.Parent=WORKSHOP end
TERRAIN:PasteRegion(SOURCE_TERRAIN,Vector3int16.new(-1472/4,-80/4,-1408/4),true)
TERRAIN:SetMaterialColor(Enum.Material.Asphalt,Color3.fromRGB(48,51,54))

local tiles,routeProfiles=buildCells()
local cellCount,gradedCount=0,0
for tileIndex,tile in ipairs(tiles) do
	local x0,x1=tile.x*TILE_SIZE,(tile.x+1)*TILE_SIZE
	local z0,z1=tile.z*TILE_SIZE,(tile.z+1)*TILE_SIZE
	local region=Region3.new(Vector3.new(x0,Y_MIN,z0),Vector3.new(x1,Y_MAX,z1))
	local materials,occupancies=TERRAIN:ReadVoxels(region,RESOLUTION)
	local ny=#materials[1]
	local dirty=false
	for key,roadCell in pairs(tile.cells) do
		local ix=math.floor((key-1)/16)+1
		local iz=(key-1)%16+1
		local surfaceY=math.floor((roadCell.height+2)/RESOLUTION)*RESOLUTION
		local target=math.floor((surfaceY-Y_MIN)/RESOLUTION)
		if target>=1 and target<=ny then
			local top
			for iy=ny,1,-1 do if occupancies[ix][iy][iz]>0.05 then top=iy;break end end
			if not top or materials[ix][top][iz]~=Enum.Material.Water then
				for iy=target+1,ny do
					if occupancies[ix][iy][iz]>0 then occupancies[ix][iy][iz]=0;materials[ix][iy][iz]=Enum.Material.Air;gradedCount+=1;dirty=true end
				end
				materials[ix][target][iz]=Enum.Material.Asphalt
				occupancies[ix][target][iz]=1
				cellCount+=1;dirty=true
			end
		end
	end
	if dirty then TERRAIN:WriteVoxels(region,RESOLUTION,materials,occupancies) end
	if tileIndex%8==0 then task.wait() end
end

-- Add lane and edge lines by route tangent; unlike the road pack's face textures,
-- each stripe follows local Z (the direction of travel) on every curved segment.
local stripeFolder=Instance.new("Folder")
stripeFolder.Name="Road_Markings_V11"
stripeFolder.Parent=DRAFT
local yellow,white=Color3.fromRGB(255,190,43),Color3.fromRGB(238,238,232)
local segmentCount,waterSegments=0,0
for _,item in pairs(routeProfiles) do
	local profile,width=item.profile,item.width
	local routeFolder=Instance.new("Folder")
	routeFolder.Name=item.route.Name
	routeFolder.Parent=stripeFolder
	for distance=0,profile.length-0.5,STRIPE_SEGMENT_LENGTH do
		local a,b=pointAt(profile,distance),pointAt(profile,math.min(distance+STRIPE_SEGMENT_LENGTH,profile.length))
		if a.valid and b.valid then
			local av,bv=Vector3.new(a.x,a.y,a.z),Vector3.new(b.x,b.y,b.z)
			local length=(bv-av).Magnitude
			if length>1 then
				local mid=(av+bv)*0.5
				local frame=CFrame.lookAt(mid,bv,Vector3.yAxis)
				local surfaceY=math.floor((mid.Y+2)/4)*4-mid.Y
				local model=Instance.new("Model");model.Name=("Mark_%03d"):format(segmentCount+1);model.Parent=routeFolder
				addStripe(model,"CenterLine_Yellow",yellow,0,0.5,length,frame,surfaceY)
				addStripe(model,"EdgeLine_Left",white,-(width/2-2.5),0.4,length,frame,surfaceY)
				addStripe(model,"EdgeLine_Right",white,width/2-2.5,0.4,length,frame,surfaceY)
				segmentCount+=1
			end
		else waterSegments+=1 end
	end
	item.route:SetAttribute("RoadSurfaceV11","Terrain Asphalt")
	item.route:SetAttribute("RoadWidthStudsV11",width)
	item.route:SetAttribute("WaterSegmentsV11",waterSegments)
end

local oldV10=DRAFT:FindFirstChild("Road_Assets_V10")
if oldV10 then oldV10:Destroy() end
stripeFolder:SetAttribute("SegmentCount",segmentCount)
stripeFolder:SetAttribute("SurfaceCellCount",cellCount)
DRAFT:SetAttribute("RoadNetworkV11Applied",true)
DRAFT:SetAttribute("RoadSurfaceMaterial","Asphalt")
ROAD_NETWORK:SetAttribute("Status","V11 continuous voxel asphalt, 48-60 stud corridors, longitudinal stripes; terrain-water sections require bridge pass")
ROAD_NETWORK:SetAttribute("SurfaceCellCountV11",cellCount)
ROAD_NETWORK:SetAttribute("GradedVoxelCountV11",gradedCount)
ROAD_NETWORK:SetAttribute("MarkingSegmentCountV11",segmentCount)
ROAD_NETWORK:SetAttribute("WaterMarkingSegmentsV11",waterSegments)
return {status="Built",routes=#ROAD_NETWORK:GetChildren(),asphaltCells=cellCount,gradedCells=gradedCount,markingSegments=segmentCount,waterSegments=waterSegments,widthStuds="48-60",terrainBackup=snapshot:GetFullName(),oldGeometryBackup=GEOMETRY_BACKUP_NAME}
