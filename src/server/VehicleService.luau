--!strict
-- FL-024: a free, procedural, anchored chassis moved in bounded server steps.
-- The client sends only normalized intent; it never supplies a position or CFrame.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local vehicleConfig = Config.Vehicle

local VehicleService = {}
local started = false
local vehicle: Model?
local seat: VehicleSeat?
local driver: Player?
local throttle = 0
local steering = 0
local speed = 0
local lastInputAt = 0
local lastPacketAt: { [Player]: number } = {}
local lastActionAt: { [Player]: number } = {}
local remotes: Folder
local actionEvent: RemoteEvent
local inputEvent: RemoteEvent
local stateEvent: RemoteEvent

local function getOrCreateRemote(folder: Folder, name: string): RemoteEvent
	local existing = folder:FindFirstChild(name)
	if existing then
		assert(existing:IsA("RemoteEvent"), name .. " precisa ser RemoteEvent")
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

local function makePart(
	parent: Model,
	name: string,
	size: Vector3,
	localCFrame: CFrame,
	pivot: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = pivot * localCFrame
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Material = material
	part.Color = color
	if shape then part.Shape = shape end
	part.Parent = parent
	return part
end

local function createVehicle(arena: Model): (Model, VehicleSeat)
	local model = Instance.new("Model")
	model.Name = "FL024_ProceduralScout"
	model:SetAttribute("ArenaRole", "ServerDrivenVehicle")
	model:SetAttribute("AssetSource", "Procedural primitives; no external assets")
	model:SetAttribute("DriverUserId", 0)
	model:SetAttribute("Speed", 0)
	local pivot = CFrame.new(0, 1.15, -8)
	local chassis = makePart(
		model,
		"Chassis",
		Vector3.new(5.4, 0.8, 8.2),
		CFrame.new(0, 0, 0),
		pivot,
		Color3.fromRGB(67, 83, 70),
		Enum.Material.Metal
	)
	model.PrimaryPart = chassis
	makePart(model, "Cabin", Vector3.new(4.1, 1.7, 3.2), CFrame.new(0, 1.15, 0.55), pivot, Color3.fromRGB(76, 96, 81), Enum.Material.Metal)
	makePart(model, "Hood", Vector3.new(4.8, 0.55, 2.5), CFrame.new(0, 0.68, -2.7), pivot, Color3.fromRGB(61, 75, 65), Enum.Material.Metal)
	makePart(model, "Windshield", Vector3.new(3.6, 1.0, 0.12), CFrame.new(0, 1.48, -0.87), pivot, Color3.fromRGB(90, 145, 158), Enum.Material.Glass)
	for _, x in { -2.55, 2.55 } do
		for _, z in { -2.75, 2.75 } do
			makePart(
				model,
				("Wheel_%s_%s"):format(if x < 0 then "L" else "R", if z < 0 then "F" else "B"),
				Vector3.new(0.72, 1.35, 1.35),
				CFrame.new(x, -0.15, z) * CFrame.Angles(0, 0, math.rad(90)),
				pivot,
				Color3.fromRGB(31, 34, 32),
				Enum.Material.Rubber,
				Enum.PartType.Cylinder
			)
		end
	end
	local vehicleSeat = Instance.new("VehicleSeat")
	vehicleSeat.Name = "DriverSeat"
	vehicleSeat.Size = Vector3.new(1.8, 0.45, 1.8)
	vehicleSeat.CFrame = pivot * CFrame.new(0, 1.45, 0.72)
	vehicleSeat.Anchored = true
	vehicleSeat.CanCollide = true
	vehicleSeat.CanTouch = false
	vehicleSeat.CanQuery = true
	vehicleSeat.Color = Color3.fromRGB(47, 52, 48)
	vehicleSeat.Material = Enum.Material.Metal
	vehicleSeat.Parent = model
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterVehiclePrompt"
	prompt.ActionText = "Dirigir"
	prompt.ObjectText = "Veículo de teste"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = vehicleConfig.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = vehicleSeat
	model.Parent = arena
	return model, vehicleSeat
end

local function getDriverCharacter(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function clearDriver(player: Player?)
	if not player then return end
	if vehicle then vehicle:SetAttribute("DriverUserId", 0) end
	if seat and seat.Occupant then seat.Occupant.Sit = false end
	if driver == player then
		driver = nil
		throttle = 0
		steering = 0
		speed = 0
		if vehicle then vehicle:SetAttribute("Speed", 0) end
		stateEvent:FireClient(player, "Exit")
	end
end

local function handleAction(player: Player, action: any, ...: any)
	if select("#", ...) > 0 or (action ~= "Enter" and action ~= "Exit") then return end
	local now = os.clock()
	if now - (lastActionAt[player] or -math.huge) < 0.35 then return end
	lastActionAt[player] = now
	local currentVehicle = vehicle
	local currentSeat = seat
	if not currentVehicle or not currentSeat or player.Parent ~= Players then return end
	if action == "Exit" then
		if driver ~= player or currentSeat.Occupant ~= (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) then return end
		local _, humanoid, root = getDriverCharacter(player)
		if not humanoid or not root then clearDriver(player); return end
		humanoid.Sit = false
		root.CFrame = currentSeat.CFrame * CFrame.new(3, 1.2, 0)
		clearDriver(player)
		return
	end
	if driver then return end
	local character, humanoid, root = getDriverCharacter(player)
	if not character or not humanoid or not root or humanoid.Health <= 0 then return end
	if (root.Position - currentSeat.Position).Magnitude > vehicleConfig.InteractionDistance then return end
	currentSeat:Sit(humanoid)
	if currentSeat.Occupant ~= humanoid then return end
	driver = player
	lastInputAt = now
	currentVehicle:SetAttribute("DriverUserId", player.UserId)
	stateEvent:FireClient(player, "Enter", currentVehicle)
end

local function finiteNumber(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function handleInput(player: Player, nextThrottle: any, nextSteering: any, ...: any)
	if select("#", ...) > 0 or player ~= driver then return end
	local now = os.clock()
	if now - (lastPacketAt[player] or -math.huge) < vehicleConfig.InputInterval * 0.8 then return end
	lastPacketAt[player] = now
	if not finiteNumber(nextThrottle) or not finiteNumber(nextSteering) then return end
	local currentSeat = seat
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not currentSeat or currentSeat.Occupant ~= humanoid then clearDriver(player); return end
	throttle = math.clamp(nextThrottle, -1, 1)
	steering = math.clamp(nextSteering, -1, 1)
	lastInputAt = now
end

local function hasObstacle(currentVehicle: Model, currentSeat: VehicleSeat, direction: Vector3, distance: number): boolean
	if distance <= 0 then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local currentDriver = driver
	params.FilterDescendantsInstances = if currentDriver and currentDriver.Character
		then { currentVehicle, currentDriver.Character }
		else { currentVehicle }
	local primaryPart = currentVehicle.PrimaryPart
	if not primaryPart then return true end
	local origin = primaryPart.Position + Vector3.new(0, 0.45, 0)
	local castLength = distance + 2.4
	for _, offsetX in { -1.7, 0, 1.7 } do
		local rayOrigin = origin + currentSeat.CFrame.RightVector * offsetX
		local result = Workspace:Raycast(rayOrigin, direction * castLength, params)
		if result and result.Distance < castLength then return true end
	end
	return false
end

local function stepVehicle(dt: number)
	local currentVehicle = vehicle
	local currentSeat = seat
	if not currentVehicle or not currentSeat then return end
	local currentDriver = driver
	if not currentDriver or not currentSeat.Occupant then
		speed = 0
		return
	end
	if os.clock() - lastInputAt > vehicleConfig.InputTimeout then
		throttle = 0
		steering = 0
	end
	dt = math.clamp(dt, 0, 0.1)
	local targetSpeed = throttle * vehicleConfig.MaxSpeed
	local maxSpeedDelta = vehicleConfig.Acceleration * dt
	speed += math.clamp(targetSpeed - speed, -maxSpeedDelta, maxSpeedDelta)
	local pivot = currentVehicle:GetPivot()
	local turnScale = math.clamp(math.abs(speed) / 8, 0, 1)
	local reverseFactor = if speed < 0 then -1 else 1
	local turn = math.rad(vehicleConfig.TurnRateDegrees) * steering * turnScale * reverseFactor * dt
	local nextPivot = pivot * CFrame.new(0, 0, -speed * dt) * CFrame.Angles(0, turn, 0)
	local position = nextPivot.Position
	if math.abs(position.X) > vehicleConfig.BoundaryX or math.abs(position.Z) > vehicleConfig.BoundaryZ then
		speed = 0
		throttle = 0
		return
	end
	local displacement = nextPivot.Position - pivot.Position
	if hasObstacle(currentVehicle, currentSeat, displacement.Unit, displacement.Magnitude) then
		speed = 0
		return
	end
	currentVehicle:PivotTo(nextPivot)
	currentVehicle:SetAttribute("Speed", math.round(speed * 10) / 10)
end

function VehicleService.Start(arena: Model)
	if started then return end
	started = true
	local existingFolder = ReplicatedStorage:FindFirstChild(NetProtocol.RemoteFolderName)
	assert(existingFolder and existingFolder:IsA("Folder"), "ReplicatedStorage.Remotes ausente")
	remotes = existingFolder
	actionEvent = getOrCreateRemote(remotes, NetProtocol.VehicleActionEvent)
	inputEvent = getOrCreateRemote(remotes, NetProtocol.VehicleInputEvent)
	stateEvent = getOrCreateRemote(remotes, NetProtocol.VehicleStateEvent)
	vehicle, seat = createVehicle(arena)
	local prompt = seat:FindFirstChildOfClass("ProximityPrompt")
	assert(prompt, "Prompt de entrada do veículo ausente")
	prompt.Triggered:Connect(function(player)
		handleAction(player, "Enter")
	end)
	actionEvent.OnServerEvent:Connect(handleAction)
	inputEvent.OnServerEvent:Connect(handleInput)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if driver and seat and seat.Occupant ~= (driver.Character and driver.Character:FindFirstChildOfClass("Humanoid")) then
			clearDriver(driver)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if driver == player then clearDriver(player) end
		lastPacketAt[player] = nil
		lastActionAt[player] = nil
	end)
	RunService.Heartbeat:Connect(stepVehicle)
	print("[Frontline][FL-024] veículo procedural ativo | velocidade máxima=" .. vehicleConfig.MaxSpeed .. " studs/s")
end

return table.freeze(VehicleService)
