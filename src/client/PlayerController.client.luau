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

lockMouse()

-- ─── Helpers de personagem ───────────────────────────────────────────────────

-- Garante que trocamos referências ao respawn
local function onCharacterAdded(newChar: Model)
	character = newChar
	humanoid  = newChar:WaitForChild("Humanoid") :: Humanoid
	rootPart  = newChar:WaitForChild("HumanoidRootPart") :: BasePart
	head      = newChar:WaitForChild("Head") :: BasePart

	-- Oculta o próprio personagem da câmera FPS (transparência local)
	for _, part in newChar:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			(part :: BasePart).LocalTransparencyModifier = 1
		end
	end

	-- Reset de ângulos ao respawn
	pitchAngle = 0
	yawAngle   = 0

	lockMouse()
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Aplica transparência ao personagem atual também
do
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") then
			(part :: BasePart).LocalTransparencyModifier = 1
		end
	end
end

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

	camera.CFrame = CFrame.new(eyePosition) * cameraRotation

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
