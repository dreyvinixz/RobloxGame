-- FL-016 V15: level asphalt road decks on a narrow asphalt subgrade. Only
-- terrain above each deck is cut, leaving surrounding elevation and road support.
local DRAFT=workspace:WaitForChild("BR_Peninsula_Draft")
local TERRAIN=workspace.Terrain
local HttpService=game:GetService("HttpService")
local ServerStorage=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local WORKSHOP=ServerStorage:WaitForChild("BR_TerrainWorkshop")
local QUARANTINE=WORKSHOP:WaitForChild("RoadAssetQuarantine"):WaitForChild("Wessel_Realistic_Road_Pack_QUARANTINE")
local NETWORK=DRAFT:WaitForChild("Road_Network")
local CLEAN_TERRAIN=WORKSHOP:WaitForChild("TerrainBeforeRoadAssetsV7")
local TERRAIN_BACKUP="TerrainBeforeRoadRepairV15"
local V14_GEOMETRY_BACKUP="RoadAssets_BrokenV14"
local V10_GEOMETRY_BACKUP="RoadAssets_BrokenV10"
local ROAD_ASSET_ID="16088161488"
local REGION_MIN=Vector3int16.new(-1472/4,-80/4,-1408/4)
local REGION_MAX=Vector3int16.new(1472/4,832/4,2048/4)
local REGION_ORIGIN=REGION_MIN
local STEP=8
local SAMPLE=8
local SCALE=1.12
local MAX_GRADE=0.12

assert(not RunService:IsRunning(),"Run only in Studio Edit")
assert(CLEAN_TERRAIN:IsA("TerrainRegion"),"Clean terrain rollback is missing")
assert(not WORKSHOP:FindFirstChild(TERRAIN_BACKUP),"V15 rollback already exists")
assert(not WORKSHOP:FindFirstChild(V14_GEOMETRY_BACKUP),"V14 geometry backup already exists")

local prototype
for _,child in ipairs(QUARANTINE:GetChildren()) do
	if child:IsA("BasePart") and child.Size.X>=20 and child.Size.Z>=20 then prototype=child;break end
end
assert(prototype,"Quarantined road surface module is missing")

local function catmull(a,b,c,d,t)
	local t2,t3=t*t,t*t*t
	return Vector2.new(
		0.5*((2*b.X)+(-a.X+c.X)*t+(2*a.X-5*b.X+4*c.X-d.X)*t2+(-a.X+3*b.X-3*c.X+d.X)*t3),
		0.5*((2*b.Y)+(-a.Y+c.Y)*t+(2*a.Y-5*b.Y+4*c.Y-d.Y)*t2+(-a.Y+3*b.Y-3*c.Y+d.Y)*t3)
	)
end

local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances={TERRAIN}
ray.IgnoreWater=false

local function sampleRoute(route)
	local raw=HttpService:JSONDecode(route:GetAttribute("WaypointsXZ"))
	local anchors={}
	for _,p in ipairs(raw) do anchors[#anchors+1]=Vector2.new(p[1]*SCALE,p[2]*SCALE) end
	local xy={}
	for i=1,#anchors-1 do
		local a,b,c,d=anchors[math.max(1,i-1)],anchors[i],anchors[i+1],anchors[math.min(#anchors,i+2)]
		local count=math.max(2,math.ceil((c-b).Magnitude/SAMPLE))
		for j=0,count-1 do xy[#xy+1]=catmull(a,b,c,d,j/count) end
	end
	xy[#xy+1]=anchors[#anchors]
	local profile,total={},0
	for i,p in ipairs(xy) do
		if i>1 then total+=(p-xy[i-1]).Magnitude end
		local hit=workspace:Raycast(Vector3.new(p.X,1100,p.Y),Vector3.new(0,-1500,0),ray)
		profile[i]={x=p.X,z=p.Y,d=total,y=hit and hit.Position.Y or nil,water=hit and hit.Material==Enum.Material.Water or false}
	end
	local smooth={}
	for i,p in ipairs(profile) do
		if p.y and not p.water then
			local sum,n=0,0
			for j=math.max(1,i-3),math.min(#profile,i+3) do if profile[j].y and not profile[j].water then sum+=profile[j].y;n+=1 end end
			smooth[i]=n>0 and sum/n or p.y
		end
	end
	local lastY
	for i,p in ipairs(profile) do
		p.y=smooth[i]
		if p.y and not p.water then
			if lastY then local ds=p.d-profile[i-1].d;p.y=math.clamp(p.y,lastY-ds*MAX_GRADE,lastY+ds*MAX_GRADE) end
			lastY=p.y
		else lastY=nil end
	end
	profile.length=total
	return profile
end

local function at(profile,distance)
	distance=math.clamp(distance,0,profile.length)
	for i=1,#profile-1 do
		local a,b=profile[i],profile[i+1]
		if distance<=b.d or i==#profile-1 then
			local t=(distance-a.d)/math.max(b.d-a.d,0.001)
			local valid=a.y and b.y and not a.water and not b.water
			if valid then return {x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t,y=a.y+(b.y-a.y)*t,d=distance,valid=true,bridge=false} end
			local before,after
			for j=i,1,-1 do if profile[j].y and not profile[j].water then before=profile[j];break end end
			for j=i+1,#profile do if profile[j].y and not profile[j].water then after=profile[j];break end end
			if before and after and after.d-before.d<=320 then
				local bridgeT=math.clamp((distance-before.d)/(after.d-before.d),0,1)
				return {x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t,y=before.y+(after.y-before.y)*bridgeT,d=distance,valid=true,bridge=true}
			end
			return {x=a.x+(b.x-a.x)*t,z=a.z+(b.z-a.z)*t,y=nil,d=distance,valid=false,bridge=a.water or b.water}
		end
	end
	local p=profile[#profile]
	return {x=p.x,z=p.z,y=p.y,d=distance,valid=p.y~=nil and not p.water,bridge=false}
end

-- Snapshot the live terrain and preserve V13 before restoring the clean base.
local terrainBackup=TERRAIN:CopyRegion(Region3int16.new(REGION_MIN,REGION_MAX))
terrainBackup.Name=TERRAIN_BACKUP
terrainBackup.Parent=WORKSHOP
local oldGeometry=DRAFT:FindFirstChild("Road_Surface_V14")
assert(oldGeometry,"V14 road surface geometry is missing")
oldGeometry.Name=V14_GEOMETRY_BACKUP
oldGeometry.Parent=WORKSHOP
TERRAIN:PasteRegion(CLEAN_TERRAIN,REGION_ORIGIN,true)

local routes={}
for _,route in ipairs(NETWORK:GetChildren()) do
	if route:IsA("Folder") and route:GetAttribute("WaypointsXZ") then
		local width=math.clamp(math.max(48,(route:GetAttribute("WidthStuds") or 34)*1.2),48,60)
		routes[#routes+1]={instance=route,name=route.Name,profile=sampleRoute(route),width=width}
	end
end

-- Find actual centerline crossings and endpoints close enough to join.
local junctions={}
for i=1,#routes-1 do
	for j=i+1,#routes do
		local a,b=routes[i],routes[j]
		for _,ap in ipairs(a.profile) do
			if ap.y and not ap.water then
				local best,bestDist
				for _,bp in ipairs(b.profile) do
					if bp.y and not bp.water then
						local delta=Vector2.new(ap.x-bp.x,ap.z-bp.z)
						local d=delta.Magnitude
						if d<10 and (not bestDist or d<bestDist) then
							best,bestDist=bp,d
						end
					end
				end
				if best then
					local x,z=(ap.x+best.x)/2,(ap.z+best.z)/2
					local existing
					for _,node in ipairs(junctions) do
						local offset=Vector2.new(node.x-x,node.z-z)
						if offset.Magnitude<32 then existing=node;break end
					end
					if not existing then
						existing={x=x,z=z,y=(ap.y+best.y)/2,halfWidth=math.max(a.width,b.width)/2+1,roads={}}
						junctions[#junctions+1]=existing
					else
						existing.x=(existing.x*2+x)/3
						existing.z=(existing.z*2+z)/3
						existing.y=(existing.y+ap.y+best.y)/3
						existing.halfWidth=math.max(existing.halfWidth,a.width/2+1,b.width/2+1)
					end
					existing.roads[a.name]=existing.roads[a.name] or ap.d
					existing.roads[b.name]=existing.roads[b.name] or best.d
				end
			end
		end
	end
end

-- Blend grades around junction centers so crossing lanes meet at one height.
for _,node in ipairs(junctions) do
	local groundHit=workspace:Raycast(Vector3.new(node.x,1100,node.z),Vector3.new(0,-1500,0),ray)
	if groundHit and groundHit.Material~=Enum.Material.Water then node.y=groundHit.Position.Y end
	for _,route in ipairs(routes) do
		local junctionDistance=node.roads[route.name]
		if junctionDistance then
			for _,p in ipairs(route.profile) do
				local dist=math.abs(p.d-junctionDistance)
				if p.y and dist<node.halfWidth+24 then
					if dist<=node.halfWidth then
						p.y=node.y
					else
						local alpha=1-(dist-node.halfWidth)/24
						p.y=p.y+(node.y-p.y)*alpha*alpha
					end
				end
			end
		end
	end
end

local surfaceFolder=Instance.new("Folder")
surfaceFolder.Name="Road_Surface_V15"
surfaceFolder:SetAttribute("SourceAssetId",ROAD_ASSET_ID)
surfaceFolder:SetAttribute("AssetGateStatus","QUARANTINED visual draft; cloned surface geometry only")
surfaceFolder:SetAttribute("WidthStuds","48-60")
surfaceFolder:SetAttribute("Surface","Flat Asphalt slabs; natural terrain retained outside corridors")
surfaceFolder.Parent=DRAFT

local function createAsphalt(routeFolder,frame,width,length,name)
	local part=prototype:Clone()
	for _,child in ipairs(part:GetChildren()) do if child:IsA("Texture") or child:IsA("Decal") then child:Destroy() end end
	part.Name=name
	part.Size=Vector3.new(width,3,length+0.1)
	part.CFrame=frame*CFrame.new(0,1.5,0)
	part.Material=Enum.Material.Asphalt
	part.Color=Color3.fromRGB(48,50,53)
	part.Anchored=true
	part.CanCollide=true
	part.CanTouch=false
	part.CanQuery=true
	part.Parent=routeFolder
	return part
end

local function stripe(parent,name,color,x,width,length,frame)
	local p=Instance.new("Part")
	p.Name=name;p.Size=Vector3.new(width,0.10,length+0.1)
	p.CFrame=frame*CFrame.new(x,3.06,0)
	p.Material=Enum.Material.SmoothPlastic;p.Color=color
	p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent
end

local segmentCount,markingCount,waterCount,bridgeCount=0,0,0,0
for _,route in ipairs(routes) do
	local routeModel=Instance.new("Model");routeModel.Name=route.name
	local profile,width=route.profile,route.width
	local distance=0
	while distance<profile.length-0.5 do
		local finish=math.min(distance+STEP,profile.length)
		local a,b=at(profile,distance),at(profile,finish)
		local midDistance=(distance+finish)/2
		local insideJunction=false
		for _,node in ipairs(junctions) do
			local junctionDistance=node.roads[route.name]
			if junctionDistance and math.abs(midDistance-junctionDistance)<node.halfWidth then insideJunction=true;break end
		end
		if a.valid and b.valid and not insideJunction then
			local va,vb=Vector3.new(a.x,a.y,a.z),Vector3.new(b.x,b.y,b.z)
			local len=(vb-va).Magnitude
			if len>0.5 then
				local center=(va+vb)/2
				local frame=CFrame.lookAt(center,vb,Vector3.yAxis)
				-- Remove only the terrain intersecting the road deck; adjacent hills remain intact.
				-- Over-water spans use the same deck as a short bridge and preserve the river.
				if not a.bridge and not b.bridge then
					-- Keep a 4-stud Asphalt subgrade beneath the deck; cut only above its top.
					TERRAIN:FillBlock(frame*CFrame.new(0,67.5,0),Vector3.new(width+2,128,len+1),Enum.Material.Air)
					TERRAIN:FillBlock(frame*CFrame.new(0,-2,0),Vector3.new(width-1,4,len+1),Enum.Material.Asphalt)
				else bridgeCount+=1 end
				local roadPart=createAsphalt(routeModel,frame,width,len,("Deck_%04d"):format(segmentCount+1))
				roadPart:SetAttribute("Route",route.name)
				roadPart:SetAttribute("SegmentStart",distance)
				roadPart:SetAttribute("SegmentEnd",finish)
				roadPart:SetAttribute("BridgeDeck",a.bridge or b.bridge)
				stripe(roadPart,"CenterLine_Yellow_L",Color3.fromRGB(255,190,43),-0.65,0.30,len,frame)
				stripe(roadPart,"CenterLine_Yellow_R",Color3.fromRGB(255,190,43),0.65,0.30,len,frame)
				stripe(roadPart,"EdgeLine_Left",Color3.fromRGB(238,238,232),-(width/2-2.5),0.4,len,frame)
				stripe(roadPart,"EdgeLine_Right",Color3.fromRGB(238,238,232),width/2-2.5,0.4,len,frame)
				markingCount+=1
				segmentCount+=1
			end
		else waterCount+=1 end
		distance=finish
		if segmentCount>0 and segmentCount%48==0 then task.wait() end
	end
	routeModel.Parent=surfaceFolder
	route.instance:SetAttribute("RoadSurfaceV15","Flat asset-derived Asphalt deck")
	route.instance:SetAttribute("RoadWidthStudsV15",width)
	if routeModel:GetChildren()[1] then routeModel.PrimaryPart=routeModel:GetChildren()[1] end
end

-- One raised asphalt pad per real crossing; striping pauses through this shared node.
local junctionFolder=Instance.new("Folder");junctionFolder.Name="Junctions";junctionFolder.Parent=surfaceFolder
for index,node in ipairs(junctions) do
	local pad=prototype:Clone()
	for _,child in ipairs(pad:GetChildren()) do if child:IsA("Texture") or child:IsA("Decal") then child:Destroy() end end
	pad.Name=("Junction_%02d"):format(index)
	pad.Size=Vector3.new(node.halfWidth*2,3,node.halfWidth*2)
	pad.CFrame=CFrame.new(node.x,node.y+1.53,node.z)
	pad.Material=Enum.Material.Asphalt;pad.Color=Color3.fromRGB(48,50,53)
	pad.Anchored=true;pad.CanCollide=true;pad.CanTouch=false;pad.CanQuery=true
	pad:SetAttribute("ConnectedRouteCount",(function() local n=0;for _ in pairs(node.roads) do n+=1 end;return n end)())
	pad.Parent=junctionFolder
	TERRAIN:FillBlock(CFrame.new(node.x,node.y+67.5,node.z),Vector3.new(node.halfWidth*2+2,128,node.halfWidth*2+2),Enum.Material.Air)
	TERRAIN:FillBlock(CFrame.new(node.x,node.y-2,node.z),Vector3.new(node.halfWidth*2-1,4,node.halfWidth*2-1),Enum.Material.Asphalt)
end

surfaceFolder:SetAttribute("RouteCount",#routes)
surfaceFolder:SetAttribute("DeckSegmentCount",segmentCount)
surfaceFolder:SetAttribute("JunctionCount",#junctions)
surfaceFolder:SetAttribute("MarkingSegmentCount",markingCount)
surfaceFolder:SetAttribute("WaterGaps",waterCount)
surfaceFolder:SetAttribute("BridgeDeckSegments",bridgeCount)
DRAFT:SetAttribute("RoadNetworkV15Applied",true)
NETWORK:SetAttribute("Status","V15: flat asset-derived Asphalt decks with narrow supported subgrade; natural surroundings retained; single junction pads")
NETWORK:SetAttribute("JunctionCountV15",#junctions)
NETWORK:SetAttribute("DeckSegmentsV15",segmentCount)
NETWORK:SetAttribute("WaterGapsV15",waterCount)
NETWORK:SetAttribute("BridgeDecksV15",bridgeCount)
return {status="Built",routes=#routes,segments=segmentCount,junctions=#junctions,markingSegments=markingCount,bridgeDecks=bridgeCount,waterGaps=waterCount,widthStuds="48-60",terrainBackup=terrainBackup:GetFullName(),savedV14Geometry=V14_GEOMETRY_BACKUP}
