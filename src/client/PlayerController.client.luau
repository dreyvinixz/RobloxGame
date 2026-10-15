--!strict
-- PlayerController.client.luau
-- FL-008 — Controlador FPS inicial
-- Responsabilidade: câmera local, movimento (walk/sprint), mouse lock e bloqueio por UI.
-- O servidor NÃO é notificado de velocidade aqui; autoridade de estado fica em FL-009.
-- Pré-requisito Rojo: StarterPlayer.StarterPlayerScripts.GameClient.PlayerController

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- ─── Referências locais ──────────────────────────────────────────────────────

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

-- Aguarda personagem estar disponível
local character   = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid    = character:WaitForChild("Humanoid") :: Humanoid
local rootPart    = character:WaitForChild("HumanoidRootPart") :: BasePart
local head        = character:WaitForChild("Head") :: BasePart

-- ─── Estado interno ──────────────────────────────────────────────────────────

local cfg         = Config.Player

local pitchAngle  = 0   -- rotação vertical acumulada (graus)
local yawAngle    = 0   -- rotação horizontal acumulada (graus)
local isSprinting = false
local isFirstPerson = true

local cameraRayParams = RaycastParams.new()
cameraRayParams.FilterType = Enum.RaycastFilterType.Exclude
cameraRayParams.FilterDescendantsInstances = { character }

-- ─── Câmera: definir modo scriptable ─────────────────────────────────────────

camera.CameraType = Enum.CameraType.Scriptable

-- Ajusta FOV inicial
camera.FieldOfView = cfg.BaseFOV

-- ─── Mouse lock ──────────────────────────────────────────────────────────────

-- Bloqueia o cursor ao centro da tela
local function lockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
end

-- Libera o cursor (abrir menus, chat, etc.)
local function unlockMouse()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end

local function setCharacterVisibility()
	local localTransparency = if isFirstPerson then 1 else 0
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = localTransparency
		end
	end
end

local function setFirstPerson(enabled: boolean)
	if isFirstPerson == enabled then
		return
	end

	isFirstPerson = enabled
	setCharacterVisibility()
end

lockMouse()

-- ─── Helpers de personagem ───────────────────────────────────────────────────

-- Garante que trocamos referências ao respawn
local function onCharacterAdded(newChar: Model)
	character = newChar
	humanoid  = newChar:WaitForChild("Humanoid") :: Humanoid
	rootPart  = newChar:WaitForChild("HumanoidRootPart") :: BasePart
	head      = newChar:WaitForChild("Head") :: BasePart
	cameraRayParams.FilterDescendantsInstances = { newChar }
	setCharacterVisibility()

	-- Reset de ângulos ao respawn
	pitchAngle = 0
	yawAngle   = 0

	lockMouse()
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Aplica transparência ao personagem atual também
setCharacterVisibility()

-- Scroll para baixo afasta a câmera; scroll para cima retorna à primeira pessoa.
UserInputService.InputChanged:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then return end
	if UserInputService:GetFocusedTextBox() then return end

	if input.Position.Z > 0 then
		setFirstPerson(true)
	elseif input.Position.Z < 0 then
		setFirstPerson(false)
	end
end)

-- ─── Detecção de sprint ──────────────────────────────────────────────────────

-- Sprint: tecla LeftShift mantida pressionada
-- IMPORTANTE: só altera WalkSpeed LOCAL — o servidor não lê isso para autoridade de dano.
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end  -- bloquear se UI capturou o input

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		humanoid.WalkSpeed = cfg.SprintSpeed

		-- Tween suave no FOV para dar sensação de velocidade
		TweenService:Create(camera, TweenInfo.new(0.2), {
			FieldOfView = cfg.BaseFOV + cfg.SprintFOVBonus
		}):Play()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		humanoid.WalkSpeed = cfg.WalkSpeed

		TweenService:Create(camera, TweenInfo.new(0.2), {
			FieldOfView = cfg.BaseFOV
		}):Play()
	end
end)

-- ─── Loop de câmera (RenderStepped — antes do render) ────────────────────────

RunService.RenderStepped:Connect(function()
	-- Verifica se o personagem ainda existe (após respawn pode haver frame de delay)
	if not rootPart or not rootPart.Parent then return end

	-- ── 1. Coletar delta do mouse ────────────────────────────────────────────
	-- Só processa se o mouse estiver bloqueado (sem UI aberta)
	local mouseDelta: Vector2
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		mouseDelta = UserInputService:GetMouseDelta()
	else
		mouseDelta = Vector2.zero
	end

	-- ── 2. Acumular ângulos ──────────────────────────────────────────────────
	yawAngle   = yawAngle   - mouseDelta.X * cfg.CameraSensitivity
	pitchAngle = pitchAngle - mouseDelta.Y * cfg.CameraSensitivity

	-- Clampear pitch para evitar gimbal lock e posições impossíveis
	pitchAngle = math.clamp(pitchAngle, cfg.CameraMinPitch, cfg.CameraMaxPitch)

	-- ── 3. Montar CFrame da câmera ───────────────────────────────────────────
	-- Posição: olhos do personagem (head + offset vertical)
	local eyeOffset = Vector3.new(0, 0.5, 0)
	local eyePosition = head.Position + eyeOffset

	-- Rotação: yaw no eixo Y do mundo, pitch no eixo X local
	local cameraRotation = CFrame.Angles(0, math.rad(yawAngle), 0)
		* CFrame.Angles(math.rad(pitchAngle), 0, 0)

	if isFirstPerson then
		camera.CFrame = CFrame.new(eyePosition) * cameraRotation
	else
		local desiredPosition = eyePosition - cameraRotation.LookVector * cfg.ThirdPersonDistance
		local cameraPosition = desiredPosition
		local obstruction = workspace:Raycast(eyePosition, desiredPosition - eyePosition, cameraRayParams)
		if obstruction then
			cameraPosition = obstruction.Position + obstruction.Normal * 0.5
		end
		camera.CFrame = CFrame.lookAt(cameraPosition, eyePosition)
	end
	camera.Focus = CFrame.new(eyePosition)

	-- ── 4. Orientar o RootPart ao yaw da câmera ──────────────────────────────
	-- Permite que o personagem vire junto com a visão horizontal.
	-- O pitch NÃO é aplicado ao body (evita animação estranha de torso).
	rootPart.CFrame = CFrame.new(rootPart.Position)
		* CFrame.Angles(0, math.rad(yawAngle), 0)
end)

-- ─── Bloqueio de câmera quando GUI captura o mouse ───────────────────────────
-- Ex: menu, chat nativo do Roblox — quando o foco vai para UI, liberamos o cursor.

UserInputService.WindowFocused:Connect(lockMouse)
UserInputService.WindowFocusReleased:Connect(unlockMouse)

-- Detecta se algum ScreenGui está capturando input globalmente (heurística básica)
-- Uma implementação mais robusta pode usar um sinal customizado do sistema de UI (FL-022).
game:GetService("StarterGui"):SetCore("TopbarEnabled", true)  -- garante topbar padrão visível

-- ─── Confirmação de carregamento ─────────────────────────────────────────────

print("[Frontline][FL-008] PlayerController carregado | walk=" .. cfg.WalkSpeed
	.. " sprint=" .. cfg.SprintSpeed
	.. " fov=" .. cfg.BaseFOV)
