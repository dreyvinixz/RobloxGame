--!strict
-- FL-011: alvo de teste reproduzível, recriado pelo servidor com a tecla T.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))

local TARGET_NAME = "TrainingDummy"
local TARGET_HEALTH = 100
local TARGET_BASE = Vector3.new(0, 0, 32)
local RESET_COOLDOWN = 1

local TrainingTargetService = {}
local started = false
local targetModel: Model?
local lastResetAt: {[Player]: number} = {}

local function makePart(parent: Model, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent
	return part
end

local function createTarget(): Model
	local model = Instance.new("Model")
	model.Name = TARGET_NAME
	model:SetAttribute("ArenaRole", "TrainingTarget")

	local torsoColor = Color3.fromRGB(194, 139, 73)
	local limbColor = Color3.fromRGB(70, 80, 91)
	local torso = makePart(model, "Torso", Vector3.new(2, 2.6, 1.1), TARGET_BASE + Vector3.new(0, 3.5, 0), torsoColor)
	local head = makePart(model, "Head", Vector3.new(1.5, 1.5, 1.5), TARGET_BASE + Vector3.new(0, 5.65, 0), Color3.fromRGB(204, 172, 140))
	makePart(model, "LeftArm", Vector3.new(0.75, 2.4, 0.8), TARGET_BASE + Vector3.new(-1.35, 3.55, 0), limbColor)
	makePart(model, "RightArm", Vector3.new(0.75, 2.4, 0.8), TARGET_BASE + Vector3.new(1.35, 3.55, 0), limbColor)
	makePart(model, "LeftLeg", Vector3.new(0.85, 2.3, 0.9), TARGET_BASE + Vector3.new(-0.5, 1.25, 0), limbColor)
	makePart(model, "RightLeg", Vector3.new(0.85, 2.3, 0.9), TARGET_BASE + Vector3.new(0.5, 1.25, 0), limbColor)
	model.PrimaryPart = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.MaxHealth = TARGET_HEALTH
	humanoid.Health = TARGET_HEALTH
	humanoid.DisplayName = "Dummy de teste"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TargetHealthBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(220, 42)
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.Name = "HealthLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(22, 26, 31)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.TextColor3 = Color3.fromRGB(245, 245, 245)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = string.format("DUMMY  %d / %d HP", TARGET_HEALTH, TARGET_HEALTH)
	label.Parent = billboard

	humanoid.HealthChanged:Connect(function(health)
		if health > 0 then
			label.Text = string.format("DUMMY  %d / %d HP", math.ceil(health), TARGET_HEALTH)
			label.TextColor3 = Color3.fromRGB(245, 245, 245)
		end
	end)
	humanoid.Died:Connect(function()
		label.Text = "ALVO ELIMINADO  |  T PARA REINICIAR"
		label.TextColor3 = Color3.fromRGB(255, 115, 100)
		print("[Frontline][FL-011] TrainingDummy eliminado; pressione T para reiniciar")
	end)

	model.Parent = Workspace
	print(string.format("[Frontline][FL-011] TrainingDummy pronto | HP=%d | posição=%s", TARGET_HEALTH, tostring(TARGET_BASE)))
	return model
end

local function getOrCreateResetEvent(): RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
	local existing = remotes:FindFirstChild(NetProtocol.ResetTrainingTargetEvent)
	if existing then
		assert(existing:IsA("RemoteEvent"), "ResetTrainingTarget precisa ser RemoteEvent")
		return existing
	end
	local event = Instance.new("RemoteEvent")
	event.Name = NetProtocol.ResetTrainingTargetEvent
	event.Parent = remotes
	return event
end

function TrainingTargetService.Start()
	if started then return end
	started = true
	assert(Workspace:FindFirstChild("GreyboxArena"), "Construa a GreyboxArena antes do TrainingTarget")
	targetModel = createTarget()

	local resetEvent = getOrCreateResetEvent()
	resetEvent.OnServerEvent:Connect(function(player: Player, ...: any)
		if select("#", ...) > 0 then return end
		local now = os.clock()
		if now - (lastResetAt[player] or -math.huge) < RESET_COOLDOWN then return end

		local current = targetModel
		local humanoid = current and current:FindFirstChildOfClass("Humanoid")
		if not current or not humanoid or humanoid.Health > 0 then return end
		lastResetAt[player] = now
		current:Destroy()
		targetModel = createTarget()
		print(string.format("[Frontline][FL-011] alvo reiniciado por %s", player.Name))
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastResetAt[player] = nil
	end)
	print("[Frontline][FL-011] TrainingTargetService ativo | tecla T após eliminar o alvo")
end

return table.freeze(TrainingTargetService)
