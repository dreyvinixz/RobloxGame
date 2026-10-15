--!strict
-- FL-015: braços R15 e arma locais, presos à câmera; sem autoridade de combate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ARM_POSES: { [string]: CFrame } = {
	RightUpperArm = CFrame.new(0.46, -0.60, -1.05) * CFrame.Angles(math.rad(84), 0, math.rad(-18)),
	RightLowerArm = CFrame.new(0.31, -0.48, -1.52) * CFrame.Angles(math.rad(88), 0, math.rad(-12)),
	RightHand = CFrame.new(0.16, -0.39, -1.83) * CFrame.Angles(math.rad(82), 0, math.rad(-8)),
	LeftUpperArm = CFrame.new(-0.49, -0.62, -1.07) * CFrame.Angles(math.rad(82), 0, math.rad(18)),
	LeftLowerArm = CFrame.new(-0.30, -0.50, -1.61) * CFrame.Angles(math.rad(88), 0, math.rad(14)),
	LeftHand = CFrame.new(-0.08, -0.40, -2.03) * CFrame.Angles(math.rad(82), 0, math.rad(8)),
}

local RIFLE_OFFSET = CFrame.new(0.12, -0.43, -1.42)
local RELOAD_DURATION_FALLBACK = 2.2
local RIG_PART_TIMEOUT = 5
local ARM_SIZES: { [string]: Vector3 } = {
	RightUpperArm = Vector3.new(0.22, 0.22, 0.55),
	RightLowerArm = Vector3.new(0.19, 0.19, 0.50),
	RightHand = Vector3.new(0.22, 0.16, 0.24),
	LeftUpperArm = Vector3.new(0.22, 0.22, 0.55),
	LeftLowerArm = Vector3.new(0.19, 0.19, 0.50),
	LeftHand = Vector3.new(0.22, 0.16, 0.24),
}

type ArmEntry = {
	part: BasePart,
	basePose: CFrame,
}

export type Controller = {
	player: Player,
	model: Model?,
	rifle: Model?,
	arms: { [string]: ArmEntry },
	started: boolean,
	destroyed: boolean,
	fireStartedAt: number?,
	reloadStartedAt: number?,
	reloadDuration: number,
	characterAddedConnection: RBXScriptConnection?,
	characterRemovingConnection: RBXScriptConnection?,
	Start: (self: Controller) -> (),
	PlayFireAnimation: (self: Controller) -> (),
	PlayReloadAnimation: (self: Controller, duration: number?) -> (),
	StopReloadAnimation: (self: Controller) -> (),
	Destroy: (self: Controller) -> (),
}

local ViewmodelController = {}
ViewmodelController.__index = ViewmodelController

local function preparePart(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
	part.LocalTransparencyModifier = 0
end

local function containsUnsafeInstance(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BaseScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("Sound") then
			return true
		end
	end
	return false
end

local function createProceduralRifle(): Model
	local model = Instance.new("Model")
	model.Name = "ProceduralTestRifle"

	local function addPart(name: string, size: Vector3, offset: CFrame, color: Color3): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = offset
		part.Color = color
		part.Material = Enum.Material.Metal
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		preparePart(part)
		part.Parent = model
		return part
	end

	local receiver = addPart("Receiver", Vector3.new(0.28, 0.34, 1.1), CFrame.new(), Color3.fromRGB(48, 53, 54))
	addPart("Barrel", Vector3.new(0.12, 0.12, 1.15), CFrame.new(0, 0.02, -1.08), Color3.fromRGB(34, 38, 39))
	addPart("Handguard", Vector3.new(0.24, 0.27, 0.72), CFrame.new(0, 0, -0.62), Color3.fromRGB(61, 66, 62))
	addPart("Stock", Vector3.new(0.22, 0.28, 0.62), CFrame.new(0, 0.01, 0.83), Color3.fromRGB(63, 66, 60))
	addPart("Magazine", Vector3.new(0.22, 0.52, 0.32), CFrame.new(0, -0.39, -0.1), Color3.fromRGB(39, 43, 43))
	addPart("Sight", Vector3.new(0.09, 0.12, 0.16), CFrame.new(0, 0.22, -0.47), Color3.fromRGB(34, 38, 39))
	model.PrimaryPart = receiver
	return model
end

local function cloneRifle(): Model
	local assets = ReplicatedStorage:FindFirstChild("FrontlineAssets")
	local candidate = assets and assets:FindFirstChild("TestRifleVisual")
	local model: Model

	if candidate and candidate:IsA("Model") and not containsUnsafeInstance(candidate) then
		model = candidate:Clone()
		model.Name = "ViewmodelRifle"
		local rifleRoot = model:FindFirstChild("Rifle", true)
		if rifleRoot and rifleRoot:IsA("BasePart") then
			model.PrimaryPart = rifleRoot
		end
		local ok = pcall(function()
			model:ScaleTo(0.5)
		end)
		if not ok then
			model:Destroy()
			model = createProceduralRifle()
		end
	else
		model = createProceduralRifle()
	end

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			preparePart(descendant)
		end
	end
	if not model.PrimaryPart then
		local root = model:FindFirstChildWhichIsA("BasePart", true)
		if root then
			model.PrimaryPart = root
		end
	end
	return model
end

local function cleanupModel(self: Controller)
	if self.model then
		self.model:Destroy()
		self.model = nil
	end
	self.rifle = nil
	table.clear(self.arms)
	self.fireStartedAt = nil
	self.reloadStartedAt = nil
end

local function addArm(self: Controller, character: Model, name: string, pose: CFrame)
	local source = character:FindFirstChild(name) or character:WaitForChild(name, RIG_PART_TIMEOUT)
	if not source or not source:IsA("BasePart") then
		return
	end

	local clone = Instance.new("Part")
	clone.Name = "Viewmodel_" .. name
	clone.Shape = Enum.PartType.Block
	clone.Size = ARM_SIZES[name]
	clone.Color = Color3.fromRGB(205, 174, 145)
	clone.Material = Enum.Material.SmoothPlastic
	clone.TopSurface = Enum.SurfaceType.Smooth
	clone.BottomSurface = Enum.SurfaceType.Smooth
	preparePart(clone)
	clone.Parent = self.model
	self.arms[name] = {
		part = clone,
		basePose = pose,
	}
end

local function createViewmodel(self: Controller, character: Model)
	cleanupModel(self)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", RIG_PART_TIMEOUT)
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		warn("[Frontline][FL-015] viewmodel aguarda um personagem R15")
		return
	end

	local viewmodel = Instance.new("Model")
	viewmodel.Name = "FrontlineViewmodel"
	self.model = viewmodel
	for name, pose in ARM_POSES do
		addArm(self, character, name, pose)
	end

	if not self.arms.RightHand or not self.arms.LeftHand then
		cleanupModel(self)
		warn("[Frontline][FL-015] mãos R15 ausentes; viewmodel não criado")
		return
	end

	local rifle = cloneRifle()
	rifle.Parent = viewmodel
	self.rifle = rifle
	local camera = workspace.CurrentCamera
	viewmodel.Parent = camera
	print(string.format(
		"[Frontline][FL-015] viewmodel R15 pronto | braços=%d | rifle=%s",
		#viewmodel:GetChildren() - 1,
		rifle.Name
	))
end

function ViewmodelController.new(player: Player): Controller
	local self = setmetatable({
		player = player,
		model = nil,
		rifle = nil,
		arms = {},
		started = false,
		destroyed = false,
		fireStartedAt = nil,
		reloadStartedAt = nil,
		reloadDuration = RELOAD_DURATION_FALLBACK,
		characterAddedConnection = nil,
		characterRemovingConnection = nil,
	}, ViewmodelController) :: any
	return self
end

function ViewmodelController.Start(self: Controller)
	if self.started or self.destroyed then
		return
	end
	self.started = true

	self.characterAddedConnection = self.player.CharacterAdded:Connect(function(character)
		task.spawn(createViewmodel, self, character)
	end)
	self.characterRemovingConnection = self.player.CharacterRemoving:Connect(function()
		cleanupModel(self)
	end)

	if self.player.Character then
		task.spawn(createViewmodel, self, self.player.Character)
	end

	RunService:BindToRenderStep("FrontlineViewmodel", Enum.RenderPriority.Camera.Value + 1, function()
		if self.destroyed then
			return
		end
		local viewmodel = self.model
		local rifle = self.rifle
		local camera = workspace.CurrentCamera
		local character = self.player.Character
		local head = character and character:FindFirstChild("Head")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not viewmodel or not rifle or not camera or not head or not head:IsA("BasePart")
			or not humanoid or humanoid.Health <= 0 then
			return
		end

		if viewmodel.Parent ~= camera then
			viewmodel.Parent = camera
		end

		local firstPerson = (camera.CFrame.Position - head.Position).Magnitude <= 1.75
		local now = os.clock()
		local recoil = if self.fireStartedAt
			then math.clamp(1 - (now - self.fireStartedAt) / 0.16, 0, 1)
			else 0
		local reload = if self.reloadStartedAt
			then math.sin(math.clamp((now - self.reloadStartedAt) / self.reloadDuration, 0, 1) * math.pi)
			else 0
		local recoilPose = CFrame.new(0, 0, 0.12 * recoil) * CFrame.Angles(math.rad(-3.5 * recoil), 0, 0)
		local reloadWeaponPose = CFrame.new(-0.18 * reload, -0.28 * reload, 0.08 * reload)
			* CFrame.Angles(0, 0, math.rad(-12 * reload))
		rifle:PivotTo(camera.CFrame * RIFLE_OFFSET * reloadWeaponPose * recoilPose)

		local reloadHandPose = CFrame.new(0.13 * reload, -0.18 * reload, 0.40 * reload)
		for _, arm in self.arms do
			arm.part.CFrame = camera.CFrame * arm.basePose * reloadHandPose * recoilPose
			arm.part.LocalTransparencyModifier = if firstPerson then 0 else 1
		end
		for _, descendant in rifle:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.LocalTransparencyModifier = if firstPerson then 0 else 1
			end
		end
	end)
end

function ViewmodelController.PlayFireAnimation(self: Controller)
	if not self.destroyed then
		self.fireStartedAt = os.clock()
	end
end

function ViewmodelController.PlayReloadAnimation(self: Controller, duration: number?)
	if self.destroyed then
		return
	end
	self.reloadDuration = if duration and duration > 0 then duration else RELOAD_DURATION_FALLBACK
	self.reloadStartedAt = os.clock()
end

function ViewmodelController.StopReloadAnimation(self: Controller)
	self.reloadStartedAt = nil
end

function ViewmodelController.Destroy(self: Controller)
	if self.destroyed then
		return
	end
	self.destroyed = true
	RunService:UnbindFromRenderStep("FrontlineViewmodel")
	if self.characterAddedConnection then
		self.characterAddedConnection:Disconnect()
		self.characterAddedConnection = nil
	end
	if self.characterRemovingConnection then
		self.characterRemovingConnection:Disconnect()
		self.characterRemovingConnection = nil
	end
	cleanupModel(self)
end

return ViewmodelController
