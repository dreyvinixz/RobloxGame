--!strict
-- FL-024: send small, normalized control intent; the server owns vehicle motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local actionEvent = remotes:WaitForChild(NetProtocol.VehicleActionEvent) :: RemoteEvent
local inputEvent = remotes:WaitForChild(NetProtocol.VehicleInputEvent) :: RemoteEvent
local stateEvent = remotes:WaitForChild(NetProtocol.VehicleStateEvent) :: RemoteEvent

local drivingVehicle: Model?
local throttle = 0
local steering = 0
local lastSendAt = 0
local savedCameraSubject: Instance?
local savedCameraType: Enum.CameraType?
local savedFieldOfView: number?
local heldKeys: { [Enum.KeyCode]: boolean } = {}

local function updateIntent()
	throttle = (if heldKeys[Enum.KeyCode.W] then 1 else 0)
		- (if heldKeys[Enum.KeyCode.S] then 1 else 0)
	steering = (if heldKeys[Enum.KeyCode.D] then 1 else 0)
		- (if heldKeys[Enum.KeyCode.A] then 1 else 0)
end

local function restoreCamera()
	local camera = workspace.CurrentCamera
	if not camera then return end
	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	elseif savedCameraSubject then
		camera.CameraSubject = savedCameraSubject
	end
	if savedFieldOfView then camera.FieldOfView = savedFieldOfView end
	savedCameraSubject = nil
	savedCameraType = nil
	savedFieldOfView = nil
end

local function stopDriving()
	drivingVehicle = nil
	table.clear(heldKeys)
	throttle = 0
	steering = 0
	restoreCamera()
end

stateEvent.OnClientEvent:Connect(function(state: any, model: any)
	if state == "Enter" and typeof(model) == "Instance" and model:IsA("Model") and model.PrimaryPart then
		local camera = workspace.CurrentCamera
		if not camera then return end
		savedCameraSubject = camera.CameraSubject
		savedCameraType = camera.CameraType
		savedFieldOfView = camera.FieldOfView
		drivingVehicle = model
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = model.PrimaryPart
	elseif state == "Exit" then
		stopDriving()
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	if not drivingVehicle then return end
	if input.KeyCode == Enum.KeyCode.E then
		actionEvent:FireServer("Exit")
		return
	end
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S
		or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
		heldKeys[input.KeyCode] = true
		updateIntent()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if heldKeys[input.KeyCode] then
		heldKeys[input.KeyCode] = nil
		updateIntent()
	end
end)

UserInputService.WindowFocusReleased:Connect(function()
	table.clear(heldKeys)
	updateIntent()
end)

player.CharacterAdded:Connect(function()
	if drivingVehicle then
		stopDriving()
	end
end)

RunService.Heartbeat:Connect(function()
	if not drivingVehicle then return end
	local now = os.clock()
	if now - lastSendAt < Config.Vehicle.InputInterval then return end
	lastSendAt = now
	inputEvent:FireServer(throttle, steering)
end)

print("[Frontline][FL-024] controles prontos | WASD dirige, E sai")
