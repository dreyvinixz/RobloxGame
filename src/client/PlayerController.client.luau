--!strict
-- PlayerController.client.luau
-- FL-008 — movimento/sprint; a câmera fica sob controle dos scripts padrão do Roblox.
-- O servidor NÃO é notificado de velocidade aqui; autoridade de combate fica no servidor.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local localPlayer = Players.LocalPlayer
local cfg = Config.Player
local isSprinting = false
local windowFocused = true
local humanoid: Humanoid? = nil

-- Classic + Custom mantém câmera/zoom padrão. Captura central do mouse gira
-- a câmera continuamente; menu e caixas de texto liberam o cursor.
localPlayer.CameraMode = Enum.CameraMode.Classic

local function updateMouseCapture()
	local textBoxFocused = UserInputService:GetFocusedTextBox() ~= nil
	local shouldCapture = windowFocused and not GuiService.MenuIsOpen and not textBoxFocused
	UserInputService.MouseBehavior = if shouldCapture
		then Enum.MouseBehavior.LockCenter
		else Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = not shouldCapture
end

updateMouseCapture()
GuiService.MenuOpened:Connect(updateMouseCapture)
GuiService.MenuClosed:Connect(updateMouseCapture)
UserInputService.TextBoxFocused:Connect(updateMouseCapture)
UserInputService.TextBoxFocusReleased:Connect(updateMouseCapture)
UserInputService.WindowFocusReleased:Connect(function()
	windowFocused = false
	updateMouseCapture()
end)
UserInputService.WindowFocused:Connect(function()
	windowFocused = true
	updateMouseCapture()
end)

local function useDefaultCamera(character: Model)
	local characterHumanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid = characterHumanoid
	characterHumanoid.WalkSpeed = cfg.WalkSpeed

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = characterHumanoid
		camera.FieldOfView = cfg.BaseFOV
	end
end

if localPlayer.Character then
	task.spawn(useDefaultCamera, localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(useDefaultCamera)

local function setSprint(enabled: boolean)
	if isSprinting == enabled then
		return
	end
	isSprinting = enabled

	local currentHumanoid = humanoid
	if currentHumanoid and currentHumanoid.Parent then
		currentHumanoid.WalkSpeed = if enabled then cfg.SprintSpeed else cfg.WalkSpeed
	end

	local camera = workspace.CurrentCamera
	if camera then
		TweenService:Create(camera, TweenInfo.new(0.2), {
			FieldOfView = if enabled then cfg.BaseFOV + cfg.SprintFOVBonus else cfg.BaseFOV,
		}):Play()
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		setSprint(true)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		setSprint(false)
	end
end)

print("[Frontline][FL-008] PlayerController carregado | câmera Roblox Classic | walk="
	.. cfg.WalkSpeed .. " sprint=" .. cfg.SprintSpeed)
