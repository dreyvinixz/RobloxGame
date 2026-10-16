--!strict
-- FL-015: braços R15 e arma locais, presos à câmera; sem autoridade de combate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ARM_POSES: { [string]: CFrame } = {
	RightUpperArm = CFrame.new(0.46, -0.60, -1.05) * CFrame.Angles(math.rad(84), 0, math.rad(-18)),
	RightLowerArm = CFrame.new(0.31, -0.48, -1.52) * CFrame.Angles(math.rad(88), 0, math.rad(-12)),
	RightHand = CFrame.new(0.16, -0.39, -1.83) * CFrame.Angles(math.rad(82), 0, math.rad(-8)),
	LeftUpperArm = CFrame.new(-0.49, -0.62, -1.07) * CFrame.Angles(math.rad(82), 0, math.rad(18)),
	LeftLowerArm = CFrame.new(-0.30, -0.50, -1.61) * CFrame.Angles(math.rad(88), 0, math.rad(14)),
	LeftHand = CFrame.new(-0.08, -0.40, -2.03) * CFrame.Angles(math.rad(82), 0, math.rad(8)),
}

local RIFLE_OFFSET = CFrame.new(0.12, -0.43, -1.42)
local PISTOL_OFFSET = CFrame.new(0.20, -0.48, -1.15) * CFrame.Angles(math.rad(-4), 0, 0)
local RELOAD_DURATION_FALLBACK = 2.2
local RIG_PART_TIMEOUT = 5
local BULLET_SPEEDS: { [string]: number } = {
	TestRifle = 1200,
	ServicePistol = 850,
}
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
	weaponId: string,
	effectsFolder: Folder?,
	arms: { [string]: ArmEntry },
	started: boolean,
	destroyed: boolean,
	fireStartedAt: number?,
	reloadStartedAt: number?,
	reloadDuration: number,
	characterAddedConnection: RBXScriptConnection?,
	characterRemovingConnection: RBXScriptConnection?,
	Start: (self: Controller) -> (),
	SetWeapon: (self: Controller, weaponId: string) -> (),
	PlayFireAnimation: (self: Controller, targetPosition: Vector3, fallbackOrigin: Vector3) -> (),
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

local function getWeaponOffset(weaponId: string): CFrame
	return if weaponId == "ServicePistol" then PISTOL_OFFSET else RIFLE_OFFSET
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

local function createProceduralPistol(): Model
	local model = Instance.new("Model")
	model.Name = "ProceduralServicePistol"

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

	local receiver = addPart("Receiver", Vector3.new(0.24, 0.22, 0.64), CFrame.new(), Color3.fromRGB(50, 54, 54))
	addPart("Slide", Vector3.new(0.22, 0.15, 0.72), CFrame.new(0, 0.14, -0.06), Color3.fromRGB(72, 76, 76))
	addPart("Barrel", Vector3.new(0.11, 0.10, 0.22), CFrame.new(0, 0.15, -0.49), Color3.fromRGB(34, 38, 39))
	addPart("Grip", Vector3.new(0.20, 0.42, 0.25), CFrame.new(0, -0.29, 0.16) * CFrame.Angles(math.rad(-8), 0, 0), Color3.fromRGB(43, 47, 45))
	addPart("MagazineBase", Vector3.new(0.18, 0.06, 0.20), CFrame.new(0, -0.51, 0.16), Color3.fromRGB(63, 59, 48))
	model.PrimaryPart = receiver
	return model
end

local function cloneWeapon(weaponId: string): Model
	if weaponId == "ServicePistol" then
		return createProceduralPistol()
	end

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

local function createShotBullet(parent: Instance): Model
	local bullet = Instance.new("Model")
	bullet.Name = "LocalBullet"

	local body = Instance.new("Part")
	body.Name = "Jacket"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(0.30, 0.055, 0.055)
	body.Color = Color3.fromRGB(122, 105, 72)
	body.Material = Enum.Material.Metal
	preparePart(body)
	body.Parent = bullet

	local tip = Instance.new("Part")
	tip.Name = "ProjectileTip"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(0.065, 0.055, 0.055)
	tip.Color = Color3.fromRGB(180, 115, 55)
	tip.Material = Enum.Material.Metal
	preparePart(tip)
	tip.CFrame = CFrame.new(0.16, 0, 0)
	tip.Parent = bullet

	local trailBack = Instance.new("Attachment")
	trailBack.Position = Vector3.new(-0.12, 0, 0)
	trailBack.Parent = body
	local trailFront = Instance.new("Attachment")
	trailFront.Position = Vector3.new(-0.12, 0.025, 0)
	trailFront.Parent = body

	local trail = Instance.new("Trail")
	trail.Name = "BulletTrail"
	trail.Attachment0 = trailBack
	trail.Attachment1 = trailFront
	trail.Lifetime = 0.08
	trail.MinLength = 0.01
	trail.LightEmission = 0.8
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 220, 145), Color3.fromRGB(255, 120, 48))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.035),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = body

	bullet.PrimaryPart = body
	bullet.Parent = parent
	return bullet
end

local function getWeaponPoints(model: Model): (Vector3, Vector3)
	local pivot = model:GetPivot()
	local forward = pivot.LookVector
	local furthestForward = -math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local halfSize = descendant.Size * 0.5
			for _, xSign in { -1, 1 } do
				for _, ySign in { -1, 1 } do
					for _, zSign in { -1, 1 } do
						local corner = descendant.CFrame:PointToWorldSpace(Vector3.new(
							halfSize.X * xSign,
							halfSize.Y * ySign,
							halfSize.Z * zSign
						))
						furthestForward = math.max(furthestForward, (corner - pivot.Position):Dot(forward))
					end
				end
			end
		end
	end

	local muzzle = pivot.Position + forward * (furthestForward + 0.025)
	local ejectPort = pivot.Position + pivot.RightVector * 0.15 + pivot.UpVector * 0.08 + forward * 0.12
	return muzzle, ejectPort
end

local function spawnBullet(parent: Instance, origin: Vector3, targetPosition: Vector3, weaponId: string)
	local offset = targetPosition - origin
	local distance = offset.Magnitude
	if distance < 0.01 then
		return
	end

	local direction = offset.Unit
	local bullet = createShotBullet(parent)
	local orientationOffset = CFrame.Angles(0, math.pi / 2, 0)
	local function placeAt(distanceAlongPath: number)
		local center = origin + direction * distanceAlongPath
		bullet:PivotTo(CFrame.lookAt(center, center + direction) * orientationOffset)
	end

	local speed = BULLET_SPEEDS[weaponId] or BULLET_SPEEDS.TestRifle
	local duration = distance / speed
	local elapsed = 0
	placeAt(0)
	local connection: RBXScriptConnection?
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not bullet.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		elapsed += deltaTime
		local progress = math.min(elapsed / duration, 1)
		placeAt(distance * progress)
		if progress >= 1 and connection then
			connection:Disconnect()
		end
	end)
	Debris:AddItem(bullet, duration + 0.12)
end

local function spawnCasing(parent: Instance, position: Vector3, right: Vector3, up: Vector3, weaponId: string)
	local casing = Instance.new("Part")
	casing.Name = "LocalSpentCasing"
	casing.Shape = Enum.PartType.Cylinder
	casing.Size = Vector3.new(if weaponId == "ServicePistol" then 0.16 else 0.22, 0.055, 0.055)
	casing.Color = Color3.fromRGB(174, 133, 62)
	casing.Material = Enum.Material.Metal
	casing.Anchored = false
	casing.CanCollide = false
	casing.CanTouch = false
	casing.CanQuery = false
	casing.CastShadow = false
	casing.Massless = true
	casing.CFrame = CFrame.lookAt(position, position + right) * CFrame.Angles(0, math.pi / 2, 0)
	casing.AssemblyLinearVelocity = right * 7 + up * 5 + Vector3.new(0, 1.5, 0)
	casing.AssemblyAngularVelocity = Vector3.new(8, 13, 5)
	casing.Parent = parent
	Debris:AddItem(casing, 2.5)
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

	local rifle = cloneWeapon(self.weaponId)
	rifle.Parent = viewmodel
	self.rifle = rifle
	local camera = workspace.CurrentCamera
	viewmodel.Parent = camera
	if camera then
		rifle:PivotTo(camera.CFrame * getWeaponOffset(self.weaponId))
	end
	print(string.format(
		"[Frontline][FL-015] viewmodel R15 pronto | braços=%d | rifle=%s",
		#viewmodel:GetChildren() - 1,
		rifle.Name
	))
end

function ViewmodelController.SetWeapon(self: Controller, weaponId: string)
	if self.destroyed or self.weaponId == weaponId then
		return
	end
	self.weaponId = weaponId

	local viewmodel = self.model
	if not viewmodel then
		return
	end
	if self.rifle then
		self.rifle:Destroy()
	end
	local weaponModel = cloneWeapon(weaponId)
	weaponModel.Parent = viewmodel
	self.rifle = weaponModel
	local camera = workspace.CurrentCamera
	if camera then
		weaponModel:PivotTo(camera.CFrame * getWeaponOffset(weaponId))
	end
end

function ViewmodelController.new(player: Player): Controller
	local self = setmetatable({
		player = player,
		model = nil,
		rifle = nil,
		weaponId = "TestRifle",
		effectsFolder = nil,
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
		rifle:PivotTo(camera.CFrame * getWeaponOffset(self.weaponId) * reloadWeaponPose * recoilPose)

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

function ViewmodelController.PlayFireAnimation(self: Controller, targetPosition: Vector3, fallbackOrigin: Vector3)
	if not self.destroyed then
		self.fireStartedAt = os.clock()
		local camera = workspace.CurrentCamera
		local effectsFolder = self.effectsFolder
		if not effectsFolder then
			effectsFolder = Instance.new("Folder")
			effectsFolder.Name = "FrontlineLocalWeaponEffects"
			effectsFolder.Parent = workspace
			self.effectsFolder = effectsFolder
		end

		local muzzlePosition = fallbackOrigin
		local ejectPosition = fallbackOrigin
		local right = if camera then camera.CFrame.RightVector else Vector3.new(1, 0, 0)
		local up = if camera then camera.CFrame.UpVector else Vector3.new(0, 1, 0)
		local firstPerson = camera and (camera.CFrame.Position - fallbackOrigin).Magnitude <= 1.75
		if firstPerson and self.model and self.model.Parent == camera and self.rifle then
			muzzlePosition, ejectPosition = getWeaponPoints(self.rifle)
			local weaponPivot = self.rifle:GetPivot()
			right = weaponPivot.RightVector
			up = weaponPivot.UpVector
		else
			ejectPosition = fallbackOrigin + right * 0.15 + up * 0.08
		end

		spawnBullet(effectsFolder, muzzlePosition, targetPosition, self.weaponId)
		spawnCasing(effectsFolder, ejectPosition, right, up, self.weaponId)
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
	if self.effectsFolder then
		self.effectsFolder:Destroy()
		self.effectsFolder = nil
	end
end

return ViewmodelController
