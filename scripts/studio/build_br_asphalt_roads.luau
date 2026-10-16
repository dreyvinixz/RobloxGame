-- Manual Studio Edit operation for the BR Peninsula draft (FL-016).
-- Builds vehicle-scale asphalt lanes and flush shoulders in Roblox Terrain.
-- Run in Edit mode. Set ACTION="restore" to revert TerrainBeforeRoadNetworkV5.
local ACTION = "apply"
local Terrain = workspace.Terrain
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local DRAFT = workspace:WaitForChild("BR_Peninsula_Draft")
local WORKSHOP = ServerStorage:WaitForChild("BR_TerrainWorkshop")
local SNAPSHOT_NAME = "TerrainBeforeRoadNetworkV5"
local RESOLUTION = 4
local TILE_SIZE = 64
local X_MIN, X_MAX, Z_MIN, Z_MAX = -960, 960, -960, 1536
local Y_MIN, Y_MAX = -64, 384
local SHOULDER_WIDTH = 0

local zones = {
	{key="01_Beach_Sea_Level", label="Praia (nível do mar)", center=Vector3.new(0,3,-900), size=Vector3.new(1420,24,180), color=Color3.fromRGB(235,215,165)},
	{key="02_South_Dunes", label="Dunas de areia", center=Vector3.new(0,16,-735), size=Vector3.new(1050,50,300), color=Color3.fromRGB(231,190,105)},
	{key="03_South_Coastal_Route", label="Estrada costeira", center=Vector3.new(0,20,-520), size=Vector3.new(1500,48,120), color=Color3.fromRGB(65,70,74)},
	{key="04_City_Center", label="Cidade", center=Vector3.new(20,40,240), size=Vector3.new(620,100,520), color=Color3.fromRGB(30,130,220)},
	{key="05_Military_West", label="Zona militar", center=Vector3.new(-510,76,80), size=Vector3.new(440,130,400), color=Color3.fromRGB(190,65,65)},
	{key="06_Industrial_East", label="Zona industrial", center=Vector3.new(500,42,470), size=Vector3.new(420,100,360), color=Color3.fromRGB(160,65,195)},
	{key="07_Port_Southeast", label="Porto", center=Vector3.new(700,18,30), size=Vector3.new(360,70,440), color=Color3.fromRGB(205,125,35)},
	{key="08_Mountain_Backdrop", label="Montanhas (fundo)", center=Vector3.new(0,210,1240), size=Vector3.new(1900,420,560), color=Color3.fromRGB(130,135,140)},
	{key="09_Natural_Ridge", label="Vegetação / área natural", center=Vector3.new(390,72,720), size=Vector3.new(650,160,360), color=Color3.fromRGB(100,145,65)},
	{key="10_Rivers_Lakes", label="Rios / lagoas", center=Vector3.new(0,0,0), size=Vector3.new(0,0,0), color=Color3.fromRGB(40,145,190)},
}

-- North is +Z. These winding routes follow the reference's west military area,
-- central city, east industry/port and the broad south coast.
local roads = {
	{name="01_North_Entry", role="Main", width=60, points={{-80,1040},{-150,900},{-80,770},{80,650},{130,520},{60,400},{40,300}}},
	{name="02_West_Military_Access", role="Main", width=56, points={{-180,780},{-330,650},{-470,500},{-490,350},{-390,250},{-230,210},{-70,250}}},
	{name="03_Military_Perimeter", role="Secondary", width=46, points={{-350,300},{-520,280},{-665,170},{-690,20},{-570,-100},{-410,-90},{-300,30},{-230,210}}},
	{name="04_City_North_Boulevard", role="Main", width=54, points={{-300,410},{-170,370},{-20,380},{140,365},{300,320},{430,365},{530,450}}},
	{name="05_City_Central_Avenue", role="Main", width=54, points={{100,500},{80,350},{15,210},{70,70},{170,-70}}},
	{name="06_City_West_Street", role="Secondary", width=42, points={{-220,390},{-180,250},{-190,100},{-130,-30}}},
	{name="07_City_East_Street", role="Secondary", width=42, points={{250,360},{250,220},{300,80},{260,-40}}},
	{name="08_Industry_Port_Link", role="Main", width=56, points={{300,320},{420,390},{555,360},{675,260},{770,120},{720,-30}}},
	{name="09_Industrial_Service_Loop", role="Secondary", width=46, points={{340,560},{470,590},{610,520},{700,410},{670,300},{555,290},{470,380}}},
	{name="10_South_Coastal_Arc", role="Main", width=54, points={{720,-30},{650,-190},{500,-350},{320,-500},{100,-565},{-140,-570},{-370,-520},{-570,-420},{-690,-260},{-660,-100}}},
	{name="11_City_To_South_Coast", role="Secondary", width=44, points={{170,-70},{210,-220},{150,-370},{100,-565}}},
}

local function addZone(parent, zone, index)
	local folder = parent:FindFirstChild(zone.key) or Instance.new("Folder")
	folder.Name = zone.key
	folder:SetAttribute("MapLabel", zone.label)
	folder:SetAttribute("MapOrder", index)
	folder:SetAttribute("CenterStuds", zone.center)
	folder:SetAttribute("BoundsStuds", zone.size)
	folder:SetAttribute("OverlayColor", zone.color)
	folder.Parent = parent
end

local function setMetadata()
	local folder = DRAFT:FindFirstChild("Reference_Zones") or Instance.new("Folder")
	folder.Name = "Reference_Zones"
	folder.Parent = DRAFT
	for index, zone in ipairs(zones) do addZone(folder, zone, index) end
	local network = DRAFT:FindFirstChild("Road_Network") or Instance.new("Folder")
	network.Name = "Road_Network"
	network.Parent = DRAFT
	network:SetAttribute("Surface", "Roblox Terrain / Enum.Material.Asphalt")
	network:SetAttribute("RoadCount", #roads)
	network:SetAttribute("Status", "Planned")
	for _, road in ipairs(roads) do
		local route = network:FindFirstChild(road.name) or Instance.new("Folder")
		route.Name = road.name
		route:SetAttribute("Role", road.role)
		route:SetAttribute("WidthStuds", road.width)
		route:SetAttribute("WaypointsXZ", HttpService:JSONEncode(road.points))
		route.Parent = network
	end
	return network
end

local function catmullRom(a, b, c, d, t)
	local t2, t3 = t*t, t*t*t
	return Vector2.new(
		0.5*((2*b.X)+(-a.X+c.X)*t+(2*a.X-5*b.X+4*c.X-d.X)*t2+(-a.X+3*b.X-3*c.X+d.X)*t3),
		0.5*((2*b.Y)+(-a.Y+c.Y)*t+(2*a.Y-5*b.Y+4*c.Y-d.Y)*t2+(-a.Y+3*b.Y-3*c.Y+d.Y)*t3)
	)
end

local function sampleRoad(road)
	local anchors = {}
	for _, p in ipairs(road.points) do table.insert(anchors, Vector2.new(p[1],p[2])) end
	local samples = {}
	for i=1,#anchors-1 do
		local a = anchors[math.max(1,i-1)]
		local b,c = anchors[i],anchors[i+1]
		local d = anchors[math.min(#anchors,i+2)]
		local length = (c-b).Magnitude
		local steps = math.max(2, math.ceil(length/8))
		for step=0,steps-1 do table.insert(samples,{position=catmullRom(a,b,c,d,step/steps)}) end
	end
	table.insert(samples,{position=anchors[#anchors]})
	local rayParams=RaycastParams.new()
	rayParams.FilterType=Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances={Terrain}
	rayParams.IgnoreWater=true
	for _,point in ipairs(samples) do
		local hit=workspace:Raycast(Vector3.new(point.position.X,500,point.position.Y),Vector3.new(0,-900,0),rayParams)
		point.height=hit and hit.Position.Y or nil
	end
	-- A short moving average removes small terrain bumps from the road grade.
	local heights={}
	for i,point in ipairs(samples) do
		if point.height then
			local total,count=0,0
			for j=math.max(1,i-2),math.min(#samples,i+2) do
				if samples[j].height then total+=samples[j].height;count+=1 end
			end
			heights[i]=count>0 and total/count or point.height
		end
	end
	for i,point in ipairs(samples) do point.height=heights[i] end
	return samples
end

local function buildRoadTiles()
	local tiles = {}
	local function getTile(tx,tz)
		local key = tx..":"..tz
		if not tiles[key] then tiles[key]={x=tx,z=tz,cells={},count=0} end
		return tiles[key]
	end
	for _,road in ipairs(roads) do
		local radius = road.width/2
		local samples=sampleRoad(road)
		for sampleIndex,point in ipairs(samples) do
			local nextPoint=samples[math.min(sampleIndex+1,#samples)]
			local direction=nextPoint.position-point.position
			local length=direction.Magnitude
			local tangent=length>0 and direction/length or Vector2.new(1,0)
			local cx,cz = math.floor(point.position.X/RESOLUTION),math.floor(point.position.Y/RESOLUTION)
			local reach = math.ceil((radius+SHOULDER_WIDTH+3)/RESOLUTION)
			for dx=-reach,reach do
				for dz=-reach,reach do
					local gx,gz=cx+dx,cz+dz
					local ox,oz=(gx+0.5)*RESOLUTION-point.position.X,(gz+0.5)*RESOLUTION-point.position.Y
					local distanceSquared=ox*ox+oz*oz
					if distanceSquared <= (radius+SHOULDER_WIDTH+2)^2 then
						local worldX,worldZ=gx*RESOLUTION,gz*RESOLUTION
						if worldX>=X_MIN and worldX<X_MAX and worldZ>=Z_MIN and worldZ<Z_MAX then
							local tx,tz=math.floor(worldX/TILE_SIZE),math.floor(worldZ/TILE_SIZE)
							local tile=getTile(tx,tz)
							local lx=math.floor((worldX-tx*TILE_SIZE)/RESOLUTION)+1
							local lz=math.floor((worldZ-tz*TILE_SIZE)/RESOLUTION)+1
							local key=(lx-1)*16+lz
							if point.height then
								local offset=Vector2.new((gx+0.5)*RESOLUTION-point.position.X,(gz+0.5)*RESOLUTION-point.position.Y)
								local t=length>0 and math.clamp(offset:Dot(tangent)/length,0,1) or 0
								local roadY=point.height+((nextPoint.height or point.height)-point.height)*t
								local mat=Enum.Material.Asphalt
								local old=tile.cells[key]
								if not old then tile.count+=1 end
								local choose = not old
								if old then
									if mat==Enum.Material.Asphalt and old.material~=Enum.Material.Asphalt then
										choose=true
									elseif mat==old.material and distanceSquared<old.distanceSquared then
										choose=true
									end
								end
								if choose then tile.cells[key]={height=roadY,material=mat,distanceSquared=distanceSquared} end
							end
						end
					end
				end
			end
		end
	end
	local result={}
	for _,tile in pairs(tiles) do table.insert(result,tile) end
	table.sort(result,function(a,b) if a.x==b.x then return a.z<b.z end return a.x<b.x end)
	return result
end

local function apply()
	assert(not RunService:IsRunning(),"Run only in Studio Edit")
	assert(not DRAFT:GetAttribute("RoadNetworkV4Applied"),"Vehicular road pass already applied; restore first before retrying")
	assert(not WORKSHOP:FindFirstChild(SNAPSHOT_NAME),"Road snapshot already exists; review or restore it before retrying")
	local snapshot=Terrain:CopyRegion(Region3int16.new(Vector3int16.new(X_MIN/4,Y_MIN/4,Z_MIN/4),Vector3int16.new(X_MAX/4,Y_MAX/4,Z_MAX/4)))
	snapshot.Name=SNAPSHOT_NAME
	snapshot.Parent=WORKSHOP
	DRAFT:SetAttribute("PreviousAsphaltMaterialColor",Terrain:GetMaterialColor(Enum.Material.Asphalt))
	Terrain:SetMaterialColor(Enum.Material.Asphalt,Color3.fromRGB(40,42,44))
	local network=setMetadata()
	local tiles=buildRoadTiles()
	local asphaltCells,shoulderCells,skippedWater,gradedCells=0,0,0,0
	for tileIndex,tile in ipairs(tiles) do
		local x0,x1=tile.x*TILE_SIZE,(tile.x+1)*TILE_SIZE
		local z0,z1=tile.z*TILE_SIZE,(tile.z+1)*TILE_SIZE
		local region=Region3.new(Vector3.new(x0,Y_MIN,z0),Vector3.new(x1,Y_MAX,z1))
		local materials,occupancies=Terrain:ReadVoxels(region,RESOLUTION)
		local nx,ny,nz=#materials,#materials[1],#materials[1][1]
		local dirty=false
		for key,roadCell in pairs(tile.cells) do
			local ix=math.floor((key-1)/16)+1
			local iz=(key-1)%16+1
			local topY=math.floor((roadCell.height+2)/RESOLUTION)*RESOLUTION
			local targetIndex=math.floor((topY-Y_MIN)/RESOLUTION)
			if targetIndex>=1 and targetIndex<=ny then
				local surfaceIndex
				for iy=ny,1,-1 do
					if occupancies[ix][iy][iz]>0.05 then surfaceIndex=iy;break end
				end
				if surfaceIndex and materials[ix][surfaceIndex][iz]==Enum.Material.Water then
					skippedWater+=1
				else
					-- Cut high terrain and fill low spots to a smooth 4-stud asphalt bed.
					for iy=targetIndex+1,ny do
						if occupancies[ix][iy][iz]>0 then occupancies[ix][iy][iz]=0;materials[ix][iy][iz]=Enum.Material.Air;dirty=true;gradedCells+=1 end
					end
					materials[ix][targetIndex][iz]=roadCell.material
					occupancies[ix][targetIndex][iz]=1
					dirty=true
					if roadCell.material==Enum.Material.Asphalt then asphaltCells+=1 else shoulderCells+=1 end
				end
			end
		end
		if dirty then Terrain:WriteVoxels(region,RESOLUTION,materials,occupancies) end
		if tileIndex%8==0 then task.wait() end
	end
	network:SetAttribute("Status","Continuous vehicle-scale asphalt lanes; nearest-center grade")
	network:SetAttribute("PaintedSurfaceCells",asphaltCells)
	network:SetAttribute("ShoulderSurfaceCells",shoulderCells)
	network:SetAttribute("RoadWidthScale","main 54-60 studs; secondary 42-46 studs")
	network:SetAttribute("GradedVoxelCells",gradedCells)
	network:SetAttribute("SkippedWaterCells",skippedWater)
	DRAFT:SetAttribute("RoadNetworkV4Applied",true)
	DRAFT:SetAttribute("AsphaltRemoved",false)
	DRAFT:SetAttribute("RoadSurfaceMaterial","Asphalt")
	DRAFT:SetAttribute("RoadSurfaceCells",asphaltCells)
	DRAFT:SetAttribute("RoadShoulderCells",shoulderCells)
	DRAFT:SetAttribute("RoadGradedVoxelCells",gradedCells)
	return {status="Built",routes=#roads,tiles=#tiles,asphaltCells=asphaltCells,shoulderCells=shoulderCells,gradedCells=gradedCells,waterCellsSkipped=skippedWater,snapshot=snapshot:GetFullName()}
end

local function restore()
	assert(not RunService:IsRunning(),"Run only in Studio Edit")
	local snapshot=WORKSHOP:FindFirstChild(SNAPSHOT_NAME)
	assert(snapshot and snapshot:IsA("TerrainRegion"),"Missing road-network TerrainRegion snapshot")
	Terrain:PasteRegion(snapshot,Vector3int16.new(X_MIN/4,Y_MIN/4,Z_MIN/4),true)
	local previousColor=DRAFT:GetAttribute("PreviousAsphaltMaterialColor")
	if previousColor then Terrain:SetMaterialColor(Enum.Material.Asphalt,previousColor) end
	DRAFT:SetAttribute("PreviousAsphaltMaterialColor",nil)
	DRAFT:SetAttribute("RoadNetworkV4Applied",false)
	DRAFT:SetAttribute("AsphaltRemoved",true)
	DRAFT:SetAttribute("RoadSurfaceCells",0)
	DRAFT:SetAttribute("RoadShoulderCells",0)
	DRAFT:SetAttribute("RoadGradedVoxelCells",0)
	local network=DRAFT:FindFirstChild("Road_Network")
	if network then network:SetAttribute("Status","Restored; route plan retained") end
	return {status="Restored",snapshot=snapshot:GetFullName()}
end

if ACTION=="restore" then return restore() end
return apply()
