--!strict
-- WeaponController.client.luau — FL-010
-- Responsabilidade: input de tiro, controle de munição/recarga, feedback visual e
--                   envio de intenção ao servidor via FireWeapon RemoteEvent.
-- NUNCA decide dano ou HP. Toda validação de combate fica em CombatRequestService + DamageService.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config       = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetProtocol  = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))

local localPlayer  = Players.LocalPlayer
local camera       = workspace.CurrentCamera

-- ─── RemoteEvent ──────────────────────────────────────────────────────────────

-- Aguarda o servidor criar o evento (feito pelo CombatRequestService.Start)
local remotesFolder = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local fireWeaponEvent: RemoteEvent = remotesFolder:WaitForChild(NetProtocol.FireWeaponEvent) :: RemoteEvent

-- ─── Estado da arma ──────────────────────────────────────────────────────────

local WEAPON_ID  = Config.Combat.TestWeaponId
local weaponDef  = WeaponConfig[WEAPON_ID]
assert(weaponDef, "[Frontline][FL-010] WeaponConfig não encontrado para: " .. WEAPON_ID)

local ammo         = weaponDef.magazineSize  -- balas no pente atual
local isReloading  = false
local lastShotAt   = -math.huge              -- os.clock() do último disparo aceito
local isTriggerHeld = false                  -- para modo automático (mouse mantido)

-- ─── HUD temporário ──────────────────────────────────────────────────────────
-- UI mínima em texto enquanto FL-022 não cria o HUD definitivo.

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WeaponHUD_FL010"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = localPlayer.PlayerGui

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.Size = UDim2.new(0, 200, 0, 40)
ammoLabel.Position = UDim2.new(1, -220, 1, -70)
ammoLabel.BackgroundTransparency = 0.5
ammoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ammoLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
ammoLabel.TextScaled = true
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.Text = ammo .. " / " .. weaponDef.magazineSize
ammoLabel.Parent = screenGui

-- Crosshair central
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 16, 0, 16)
crosshair.Position = UDim2.new(0.5, -8, 0.5, -8)
crosshair.BackgroundTransparency = 1
crosshair.Parent = screenGui

for _, axis in { {UDim2.new(0, 14, 0, 2), UDim2.new(0, 1, 0, 7)},
                 {UDim2.new(0, 2, 0, 14), UDim2.new(0, 7, 0, 1)} } do
	local bar = Instance.new("Frame")
	bar.Size       = axis[1]
	bar.Position   = axis[2]
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BorderSizePixel  = 0
	bar.Parent = crosshair
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 200, 0, 30)
statusLabel.Position = UDim2.new(1, -220, 1, -110)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = ""
statusLabel.Parent = screenGui

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function updateHUD()
	if isReloading then
		ammoLabel.Text = "RECARREGANDO..."
		ammoLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
	else
		ammoLabel.Text = ammo .. " / " .. weaponDef.magazineSize
		ammoLabel.TextColor3 = if ammo == 0
			then Color3.fromRGB(255, 80, 80)
			else Color3.fromRGB(230, 230, 230)
	end
end

local function showStatus(msg: string, duration: number?)
	statusLabel.Text = msg
	task.delay(duration or 1.5, function()
		if statusLabel.Text == msg then
			statusLabel.Text = ""
		end
	end)
end

-- ─── Lógica de disparo ───────────────────────────────────────────────────────

local function getCharacterRefs(): (Humanoid?, BasePart?, BasePart?)
	local character = localPlayer.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head     = character:FindFirstChild("Head") :: BasePart?
	return humanoid, rootPart, head
end

local function tryFire()
	-- Bloqueia se UI capturou input
	if UserInputService:GetFocusedTextBox() then return end

	local humanoid, _, head = getCharacterRefs()
	if not humanoid or humanoid.Health <= 0 or not head then return end
	if isReloading then
		showStatus("Recarregando!")
		return
	end
	if ammo <= 0 then
		showStatus("Sem balas! [R]")
		return
	end

	-- Cadência local (espelho do rate limit do servidor)
	local now = os.clock()
	if now - lastShotAt < weaponDef.fireInterval then return end
	lastShotAt = now

	-- Construir payload
	local unitRay    = camera:ScreenPointToRay(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)
	local origin     = head.Position
	local direction  = unitRay.Direction.Unit

	-- Raycast local para encontrar targetPosition (sem aplicar dano — só posição)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { localPlayer.Character :: Instance }

	local localRayResult = workspace:Raycast(origin, direction * weaponDef.maxRange, params)
	local targetPosition = if localRayResult
		then localRayResult.Position
		else origin + direction * weaponDef.maxRange

	-- Decrementa munição antes do envio (reverte se servidor rejeitar — MVP simples)
	ammo -= 1
	updateHUD()

	-- Envia intenção ao servidor — servidor valida e aplica dano se aprovado
	fireWeaponEvent:FireServer({
		weaponId       = WEAPON_ID,
		origin         = origin,
		direction      = direction,
		targetPosition = targetPosition,
	})

	-- Recarrega automático quando pente esvaziar
	if ammo == 0 then
		task.delay(0.1, function()
			if ammo == 0 and not isReloading then
				-- dispara reload automaticamente
				UserInputService.InputBegan:Fire(
					{ KeyCode = Enum.KeyCode.R, UserInputType = Enum.UserInputType.Keyboard } :: any,
					false
				)
			end
		end)
	end
end

-- ─── Recarga ─────────────────────────────────────────────────────────────────

local function startReload()
	if isReloading then return end
	if ammo == weaponDef.magazineSize then
		showStatus("Pente cheio")
		return
	end

	local humanoid = getCharacterRefs()
	if not humanoid or humanoid.Health <= 0 then return end

	isReloading = true
	updateHUD()
	showStatus("Recarregando... " .. weaponDef.reloadTime .. "s", weaponDef.reloadTime)

	task.delay(weaponDef.reloadTime, function()
		if isReloading then
			ammo = weaponDef.magazineSize
			isReloading = false
			updateHUD()
			showStatus("Pronto!")
		end
	end)
end

-- ─── Inputs ──────────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isTriggerHeld = true
		tryFire()
	elseif input.KeyCode == Enum.KeyCode.R then
		startReload()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isTriggerHeld = false
	end
end)

-- Modo automático: enquanto botão mantido, dispara em cadência
RunService.Heartbeat:Connect(function()
	if isTriggerHeld then
		tryFire()
	end
end)

-- ─── Reset ao respawn ─────────────────────────────────────────────────────────

localPlayer.CharacterAdded:Connect(function()
	ammo        = weaponDef.magazineSize
	isReloading = false
	lastShotAt  = -math.huge
	isTriggerHeld = false
	updateHUD()
	showStatus("Rifle pronto")
end)

-- ─── Init ────────────────────────────────────────────────────────────────────

updateHUD()
showStatus("Rifle pronto")
print(string.format(
	"[Frontline][FL-010] WeaponController | arma=%s | mag=%d | cadência=%.2fs | range=%d",
	WEAPON_ID, weaponDef.magazineSize, weaponDef.fireInterval, weaponDef.maxRange
))
