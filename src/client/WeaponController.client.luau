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
local ViewmodelController = require(script.Parent:WaitForChild("FirstPersonViewmodel"))

local localPlayer  = Players.LocalPlayer
local viewmodel    = ViewmodelController.new(localPlayer)
viewmodel:Start()

-- ─── RemoteEvent ──────────────────────────────────────────────────────────────

-- Aguarda o servidor criar o evento (feito pelo CombatRequestService.Start)
local remotesFolder = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local fireWeaponEvent: RemoteEvent = remotesFolder:WaitForChild(NetProtocol.FireWeaponEvent) :: RemoteEvent
local reloadWeaponEvent: RemoteEvent = remotesFolder:WaitForChild(NetProtocol.ReloadWeaponEvent) :: RemoteEvent
local weaponStateEvent: RemoteEvent = remotesFolder:WaitForChild(NetProtocol.WeaponStateEvent) :: RemoteEvent
local equipWeaponEvent: RemoteEvent = remotesFolder:WaitForChild(NetProtocol.EquipWeaponEvent) :: RemoteEvent

-- ─── Estado da arma ──────────────────────────────────────────────────────────

local weaponId = Config.Combat.TestWeaponId
local weaponDef = WeaponConfig[weaponId]
assert(weaponDef, "[Frontline][FL-010] WeaponConfig não encontrado para: " .. weaponId)

local ammo         = weaponDef.magazineSize  -- balas no pente atual
local isReloading  = false
local lastShotAt   = -math.huge              -- os.clock() do último disparo aceito
local isTriggerHeld = false                  -- para modo automático (mouse mantido)
local startReload: () -> ()

-- ─── HUD integrado FL-022 ───────────────────────────────────────────────────
-- Estados visuais repassados via atributos locais para o HudController definitivo.

local function updateHUD()
	localPlayer:SetAttribute("CurrentWeapon", weaponId)
	localPlayer:SetAttribute("CurrentAmmo", ammo)
	localPlayer:SetAttribute("IsReloading", isReloading)
end

local function showStatus(msg: string, duration: number?)
	localPlayer:SetAttribute("StatusMessage", msg)
	task.delay(duration or 1.5, function()
		if localPlayer:GetAttribute("StatusMessage") == msg then
			localPlayer:SetAttribute("StatusMessage", "")
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
	local camera = workspace.CurrentCamera
	if not camera then return end
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
	viewmodel:PlayFireAnimation(targetPosition, head.Position)
	localPlayer:SetAttribute("LastShotAt", now)

	-- Envia intenção ao servidor — servidor valida e aplica dano se aprovado
	fireWeaponEvent:FireServer({
		weaponId       = weaponId,
		origin         = origin,
		direction      = direction,
		targetPosition = targetPosition,
	})

end

-- ─── Recarga ─────────────────────────────────────────────────────────────────

startReload = function()
	if isReloading then return end
	if ammo == weaponDef.magazineSize then
		showStatus("Pente cheio")
		return
	end

	local humanoid = getCharacterRefs()
	if not humanoid or humanoid.Health <= 0 then return end

	reloadWeaponEvent:FireServer()
end

weaponStateEvent.OnClientEvent:Connect(function(serverWeaponId: string, serverAmmo: number, serverReloading: boolean)
	local serverWeapon = WeaponConfig[serverWeaponId]
	if not serverWeapon or typeof(serverAmmo) ~= "number" or typeof(serverReloading) ~= "boolean" then return end
	weaponId = serverWeaponId
	weaponDef = serverWeapon
	viewmodel:SetWeapon(serverWeaponId)
	local wasReloading = isReloading
	ammo = math.clamp(math.floor(serverAmmo), 0, weaponDef.magazineSize)
	isReloading = serverReloading
	if isReloading and not wasReloading then
		viewmodel:PlayReloadAnimation(weaponDef.reloadTime)
	elseif not isReloading and wasReloading then
		viewmodel:StopReloadAnimation()
	end
	updateHUD()
	if ammo == 0 and not isReloading then
		task.defer(function() startReload() end)
	end
end)

-- ─── Inputs ──────────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isTriggerHeld = true
		tryFire()
	elseif input.KeyCode == Enum.KeyCode.R then
		startReload()
	elseif input.KeyCode == Enum.KeyCode.One then
		equipWeaponEvent:FireServer("TestRifle")
	elseif input.KeyCode == Enum.KeyCode.Two then
		equipWeaponEvent:FireServer("ServicePistol")
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
	isReloading = false
	lastShotAt  = -math.huge
	isTriggerHeld = false
	viewmodel:StopReloadAnimation()
	updateHUD()
	showStatus("Rifle pronto")
end)

script.Destroying:Connect(function()
	viewmodel:Destroy()
end)

-- ─── Init ────────────────────────────────────────────────────────────────────

updateHUD()
showStatus("Rifle pronto")
print(string.format(
	"[Frontline][FL-010] WeaponController | arma=%s | mag=%d | cadência=%.2fs | range=%d",
	weaponId, weaponDef.magazineSize, weaponDef.fireInterval, weaponDef.maxRange
))
