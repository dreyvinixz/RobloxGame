--!strict
-- HudController.client.luau — FL-022
-- HUD tático militar inspirado no Battlefield 6 (ref. GameRant & TechWiser)
-- Suporta: Barra de Tickets & Setores (1-4), Killfeed (5-7), Squad & Minimap (8-10, 16),
--          Confirmação de Abate/XP (11), Slots de Armas/Granada/Munição (12-15) e Retícula/Hitmarker (18).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local hitConfirmed = remotes:WaitForChild(NetProtocol.HitConfirmedEvent) :: RemoteEvent
local weaponStateEvent = remotes:WaitForChild(NetProtocol.WeaponStateEvent) :: RemoteEvent
local equipWeaponEvent = remotes:WaitForChild(NetProtocol.EquipWeaponEvent) :: RemoteEvent
local reloadWeaponEvent = remotes:WaitForChild(NetProtocol.ReloadWeaponEvent) :: RemoteEvent
local matchState = ReplicatedStorage:WaitForChild("MatchState")

-- Tenta obter o evento de eliminação para o killfeed
local eliminationEvent: RemoteEvent? = remotes:FindFirstChild(NetProtocol.EliminationEvent) :: RemoteEvent?
if not eliminationEvent then
	task.spawn(function()
		eliminationEvent = remotes:WaitForChild(NetProtocol.EliminationEvent, 5) :: RemoteEvent?
		if eliminationEvent then
			eliminationEvent.OnClientEvent:Connect(function(killerName: string, victimName: string, weaponId: string, isHeadshot: boolean)
				-- alimentado mais abaixo
			end)
		end
	end)
end

-- ─── Paleta de Cores Militar BF6 ─────────────────────────────────────────────
local THEME = {
	DarkBg = Color3.fromRGB(10, 14, 20),
	DarkCard = Color3.fromRGB(15, 20, 28),
	DarkBorder = Color3.fromRGB(45, 60, 75),
	TextWhite = Color3.fromRGB(242, 246, 250),
	TextMuted = Color3.fromRGB(150, 165, 180),
	CyanFriendly = Color3.fromRGB(0, 200, 255),
	CyanGaze = Color3.fromRGB(70, 215, 255),
	OrangeEnemy = Color3.fromRGB(255, 95, 45),
	OrangeGaze = Color3.fromRGB(255, 130, 70),
	SquadGreen = Color3.fromRGB(50, 225, 130),
	WarningYellow = Color3.fromRGB(250, 195, 50),
	CriticalRed = Color3.fromRGB(245, 65, 65),
}

-- ─── Criação da ScreenGui Principal ──────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "FrontlineHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

-- Estado do Modo Imersivo (GameRant: reduz elementos para foco visual)
local isImmersiveMode = false

-- ─── Helpers Visuais ─────────────────────────────────────────────────────────
local function addCorner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent: Instance, color: Color3, thickness: number, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function makeLabel(name: string, size: UDim2, position: UDim2, anchor: Vector2, textSize: number, parent: Instance?): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor
	label.BackgroundColor3 = THEME.DarkCard
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = THEME.TextWhite
	label.TextScaled = false
	label.TextSize = textSize
	label.TextWrapped = false
	label.Parent = parent or gui
	return label
end

-- ═════════════════════════════════════════════════════════════════════════════
-- 1. TOPO: BARRA DE REFORÇOS / TICKETS E SETORES (ELEMENTOS 1, 2, 3, 4)
-- ═════════════════════════════════════════════════════════════════════════════

local topSectorBar = Instance.new("Frame")
topSectorBar.Name = "TopSectorBar"
topSectorBar.Size = UDim2.new(0.48, 0, 0, 48)
topSectorBar.Position = UDim2.new(0.5, 0, 0, 18)
topSectorBar.AnchorPoint = Vector2.new(0.5, 0)
topSectorBar.BackgroundTransparency = 1
topSectorBar.Parent = gui

local topConstraint = Instance.new("UISizeConstraint")
topConstraint.MinSize = Vector2.new(380, 44)
topConstraint.MaxSize = Vector2.new(680, 52)
topConstraint.Parent = topSectorBar

-- Aliado (Azul/Ciano) [ 950 ]
local blueTicketBox = Instance.new("Frame")
blueTicketBox.Name = "BlueTicketBox"
blueTicketBox.Size = UDim2.new(0.34, 0, 0, 20)
blueTicketBox.Position = UDim2.new(0, 0, 0, 4)
blueTicketBox.BackgroundColor3 = THEME.DarkBg
blueTicketBox.BackgroundTransparency = 0.35
blueTicketBox.BorderSizePixel = 0
blueTicketBox.Parent = topSectorBar
addCorner(blueTicketBox, 3)
addStroke(blueTicketBox, THEME.DarkBorder, 1, 0.4)

local blueTicketFill = Instance.new("Frame")
blueTicketFill.Name = "BlueTicketFill"
blueTicketFill.Size = UDim2.new(1, 0, 1, 0)
blueTicketFill.Position = UDim2.new(0, 0, 0, 0)
blueTicketFill.BackgroundColor3 = THEME.CyanFriendly
blueTicketFill.BorderSizePixel = 0
blueTicketFill.Parent = blueTicketBox
addCorner(blueTicketFill, 3)

local blueTicketLabel = Instance.new("TextLabel")
blueTicketLabel.Name = "BlueTicketLabel"
blueTicketLabel.Size = UDim2.new(0, 70, 0, 20)
blueTicketLabel.Position = UDim2.new(0, -78, 0, 0)
blueTicketLabel.BackgroundTransparency = 1
blueTicketLabel.Font = Enum.Font.GothamBold
blueTicketLabel.Text = "[ 1000 ]"
blueTicketLabel.TextColor3 = THEME.CyanGaze
blueTicketLabel.TextSize = 16
blueTicketLabel.TextXAlignment = Enum.TextXAlignment.Right
blueTicketLabel.Parent = blueTicketBox

-- Inimigo (Laranja) [ 937 ]
local orangeTicketBox = Instance.new("Frame")
orangeTicketBox.Name = "OrangeTicketBox"
orangeTicketBox.Size = UDim2.new(0.34, 0, 0, 20)
orangeTicketBox.Position = UDim2.new(1, 0, 0, 4)
orangeTicketBox.AnchorPoint = Vector2.new(1, 0)
orangeTicketBox.BackgroundColor3 = THEME.DarkBg
orangeTicketBox.BackgroundTransparency = 0.35
orangeTicketBox.BorderSizePixel = 0
orangeTicketBox.Parent = topSectorBar
addCorner(orangeTicketBox, 3)
addStroke(orangeTicketBox, THEME.DarkBorder, 1, 0.4)

local orangeTicketFill = Instance.new("Frame")
orangeTicketFill.Name = "OrangeTicketFill"
orangeTicketFill.Size = UDim2.new(1, 0, 1, 0)
orangeTicketFill.Position = UDim2.new(1, 0, 0, 0)
orangeTicketFill.AnchorPoint = Vector2.new(1, 0)
orangeTicketFill.BackgroundColor3 = THEME.OrangeEnemy
orangeTicketFill.BorderSizePixel = 0
orangeTicketFill.Parent = orangeTicketBox
addCorner(orangeTicketFill, 3)

local orangeTicketLabel = Instance.new("TextLabel")
orangeTicketLabel.Name = "OrangeTicketLabel"
orangeTicketLabel.Size = UDim2.new(0, 70, 0, 20)
orangeTicketLabel.Position = UDim2.new(1, 8, 0, 0)
orangeTicketLabel.BackgroundTransparency = 1
orangeTicketLabel.Font = Enum.Font.GothamBold
orangeTicketLabel.Text = "[ 1000 ]"
orangeTicketLabel.TextColor3 = THEME.OrangeGaze
orangeTicketLabel.TextSize = 16
orangeTicketLabel.TextXAlignment = Enum.TextXAlignment.Left
orangeTicketLabel.Parent = orangeTicketBox

-- Marcadores de Setores no Centro: A B C D E
local sectorBadgesContainer = Instance.new("Frame")
sectorBadgesContainer.Name = "SectorBadges"
sectorBadgesContainer.Size = UDim2.new(0.28, 0, 0, 24)
sectorBadgesContainer.Position = UDim2.new(0.5, 0, 0, 2)
sectorBadgesContainer.AnchorPoint = Vector2.new(0.5, 0)
sectorBadgesContainer.BackgroundTransparency = 1
sectorBadgesContainer.Parent = topSectorBar

local badgesLayout = Instance.new("UIListLayout")
badgesLayout.FillDirection = Enum.FillDirection.Horizontal
badgesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
badgesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
badgesLayout.Padding = UDim.new(0, 6)
badgesLayout.Parent = sectorBadgesContainer

local flagDefinitions = {
	{ id = "A", defaultOwner = "Blue" },
	{ id = "B", defaultOwner = "Orange" },
	{ id = "C", defaultOwner = "Blue" },
	{ id = "D", defaultOwner = "Neutral" },
	{ id = "E", defaultOwner = "Neutral" },
}

local flagIcons: { [string]: Frame } = {}
for _, flag in flagDefinitions do
	local badge = Instance.new("Frame")
	badge.Name = "Flag_" .. flag.id
	badge.Size = UDim2.new(0, 18, 0, 18)
	badge.BorderSizePixel = 0

	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "Letter"
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Font = Enum.Font.GothamBold
	badgeText.Text = flag.id
	badgeText.TextSize = 11
	badgeText.Parent = badge

	if flag.defaultOwner == "Blue" then
		badge.BackgroundColor3 = THEME.CyanFriendly
		badgeText.TextColor3 = THEME.DarkBg
		addCorner(badge, 9) -- Círculo
	elseif flag.defaultOwner == "Orange" then
		badge.BackgroundColor3 = THEME.OrangeEnemy
		badgeText.TextColor3 = THEME.DarkBg
		badge.Rotation = 45 -- Diamante tático BF6
		badgeText.Rotation = -45
		addCorner(badge, 2)
	else
		badge.BackgroundColor3 = Color3.fromRGB(120, 135, 150)
		badgeText.TextColor3 = THEME.DarkBg
		addCorner(badge, 9)
	end

	badge.Parent = sectorBadgesContainer
	flagIcons[flag.id] = badge
end

-- Preserva a compatibilidade de busca por TeamScore e RoundStatus
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "TeamScore"
scoreLabel.Size = UDim2.new(1, 0, 0, 16)
scoreLabel.Position = UDim2.new(0.5, 0, 0, 26)
scoreLabel.AnchorPoint = Vector2.new(0.5, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font = Enum.Font.GothamMedium
scoreLabel.Text = "SETOR DE OPERAÇÕES // FRONTLINE"
scoreLabel.TextColor3 = THEME.TextMuted
scoreLabel.TextSize = 12
scoreLabel.Parent = topSectorBar

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundStatus"
roundLabel.Size = UDim2.new(1, 0, 0, 14)
roundLabel.Position = UDim2.new(0.5, 0, 0, 42)
roundLabel.AnchorPoint = Vector2.new(0.5, 0)
roundLabel.BackgroundTransparency = 1
roundLabel.Font = Enum.Font.GothamBold
roundLabel.Text = "AGUARDANDO COMBATENTES"
roundLabel.TextColor3 = THEME.TextWhite
roundLabel.TextSize = 13
roundLabel.Parent = topSectorBar

-- ═════════════════════════════════════════════════════════════════════════════
-- 2. CANTO SUPERIOR DIREITO: KILL FEED TÁTICO BF6 (ELEMENTOS 5, 6, 7)
-- ═════════════════════════════════════════════════════════════════════════════

local killfeedContainer = Instance.new("Frame")
killfeedContainer.Name = "KillFeedContainer"
killfeedContainer.Size = UDim2.new(0, 320, 0, 180)
killfeedContainer.Position = UDim2.new(1, -20, 0, 24)
killfeedContainer.AnchorPoint = Vector2.new(1, 0)
killfeedContainer.BackgroundTransparency = 1
killfeedContainer.Parent = gui

local killfeedLayout = Instance.new("UIListLayout")
killfeedLayout.FillDirection = Enum.FillDirection.Vertical
killfeedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
killfeedLayout.VerticalAlignment = Enum.VerticalAlignment.Top
killfeedLayout.Padding = UDim.new(0, 4)
killfeedLayout.Parent = killfeedContainer

local function addKillFeedEntry(killerName: string, victimName: string, weaponId: string, isHeadshot: boolean, isExplosive: boolean?)
	local row = Instance.new("Frame")
	row.Name = "KillRow"
	row.Size = UDim2.new(0, 0, 0, 24)
	row.BackgroundColor3 = THEME.DarkCard
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel = 0
	row.ClipsDescendants = true
	addCorner(row, 3)
	addStroke(row, THEME.DarkBorder, 1, 0.5)

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = row

	-- Killer Name
	local killerLabel = Instance.new("TextLabel")
	killerLabel.Name = "Killer"
	killerLabel.Size = UDim2.new(0, 0, 1, 0)
	killerLabel.AutomaticSize = Enum.AutomaticSize.X
	killerLabel.BackgroundTransparency = 1
	killerLabel.Font = Enum.Font.GothamBold
	killerLabel.Text = killerName
	killerLabel.TextColor3 = if killerName == player.Name then THEME.CyanGaze else THEME.TextWhite
	killerLabel.TextSize = 13
	killerLabel.Parent = row

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 0, 1, 0)
	iconLabel.AutomaticSize = Enum.AutomaticSize.X
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.Gotham
	iconLabel.Text = if isHeadshot then " 💀 [HS] " else if isExplosive then " 💣 " else " ︻╦╤─ "
	iconLabel.TextColor3 = if isHeadshot then THEME.CriticalRed else THEME.TextMuted
	iconLabel.TextSize = 12
	iconLabel.Parent = row

	-- Victim Name
	local victimLabel = Instance.new("TextLabel")
	victimLabel.Name = "Victim"
	victimLabel.Size = UDim2.new(0, 0, 1, 0)
	victimLabel.AutomaticSize = Enum.AutomaticSize.X
	victimLabel.BackgroundTransparency = 1
	victimLabel.Font = Enum.Font.GothamBold
	victimLabel.Text = victimName
	victimLabel.TextColor3 = if victimName == player.Name then THEME.CriticalRed else THEME.OrangeEnemy
	victimLabel.TextSize = 13
	victimLabel.Parent = row

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = row

	row.Parent = killfeedContainer
	row.AutomaticSize = Enum.AutomaticSize.X

	-- Limite de 5 mensagens simultâneas
	local children = killfeedContainer:GetChildren()
	local rows = {}
	for _, c in children do
		if c:IsA("Frame") then table.insert(rows, c) end
	end
	if #rows > 5 then
		rows[1]:Destroy()
	end

	-- Efeito de fade out suave após 4.5s
	task.delay(4.5, function()
		if row and row.Parent then
			local tween = TweenService:Create(row, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
			})
			tween:Play()
			for _, item in row:GetDescendants() do
				if item:IsA("TextLabel") then
					TweenService:Create(item, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
				elseif item:IsA("UIStroke") then
					TweenService:Create(item, TweenInfo.new(0.5), { Transparency = 1 }):Play()
				end
			end
			tween.Completed:Connect(function()
				row:Destroy()
			end)
		end
	end)
end

-- ═════════════════════════════════════════════════════════════════════════════
-- 3. CANTO INFERIOR DIREITO: ARMAS, SLOTS, MUNIÇÃO E CADÊNCIA (12, 13, 14, 15)
-- ═════════════════════════════════════════════════════════════════════════════

local weaponCluster = Instance.new("Frame")
weaponCluster.Name = "WeaponCluster"
weaponCluster.Size = UDim2.new(0, 240, 0, 105)
weaponCluster.Position = UDim2.new(1, -20, 1, -20)
weaponCluster.AnchorPoint = Vector2.new(1, 1)
weaponCluster.BackgroundTransparency = 1
weaponCluster.Parent = gui

-- Slots Superiores: [1] Primária, [2] Secundária, [G] Granada
local slotsRow = Instance.new("Frame")
slotsRow.Name = "SlotsRow"
slotsRow.Size = UDim2.new(1, 0, 0, 28)
slotsRow.Position = UDim2.new(0, 0, 0, 0)
slotsRow.BackgroundTransparency = 1
slotsRow.Parent = weaponCluster

local function makeSlotBox(name: string, keyText: string, iconText: string, posX: number, width: number): (Frame, UIStroke, TextLabel)
	local box = Instance.new("Frame")
	box.Name = name
	box.Size = UDim2.new(0, width, 1, 0)
	box.Position = UDim2.new(0, posX, 0, 0)
	box.BackgroundColor3 = THEME.DarkCard
	box.BackgroundTransparency = 0.35
	box.BorderSizePixel = 0
	box.Parent = slotsRow
	addCorner(box, 3)
	local stroke = addStroke(box, THEME.DarkBorder, 1, 0.4)

	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.Size = UDim2.new(0, 16, 0, 14)
	keyHint.Position = UDim2.new(0, 4, 0, 2)
	keyHint.BackgroundTransparency = 1
	keyHint.Font = Enum.Font.GothamBold
	keyHint.Text = keyText
	keyHint.TextColor3 = THEME.TextMuted
	keyHint.TextSize = 10
	keyHint.Parent = box

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(1, -20, 1, 0)
	icon.Position = UDim2.new(0, 18, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.GothamMedium
	icon.Text = iconText
	icon.TextColor3 = THEME.TextWhite
	icon.TextSize = 12
	icon.Parent = box

	return box, stroke, icon
end

local slot1Box, slot1Stroke, slot1Text = makeSlotBox("Slot1_Primary", "1", "RIFLE", 0, 88)
local slot2Box, slot2Stroke, slot2Text = makeSlotBox("Slot2_Secondary", "2", "PISTOL", 94, 88)
local grenadeBox, grenadeStroke, grenadeText = makeSlotBox("Slot_Grenade", "G", "💣 1", 188, 52)

-- Caixa Principal de Munição
local ammoCard = Instance.new("Frame")
ammoCard.Name = "AmmoCard"
ammoCard.Size = UDim2.new(1, 0, 0, 72)
ammoCard.Position = UDim2.new(0, 0, 0, 32)
ammoCard.BackgroundColor3 = THEME.DarkCard
ammoCard.BackgroundTransparency = 0.3
ammoCard.BorderSizePixel = 0
ammoCard.Parent = weaponCluster
addCorner(ammoCard, 4)
local ammoStroke = addStroke(ammoCard, THEME.DarkBorder, 1, 0.3)

-- Lado Esquerdo do Cartão: Nome da Arma, Modo de Fogo e Mensagem
local weaponNameLabel = Instance.new("TextLabel")
weaponNameLabel.Name = "WeaponName"
weaponNameLabel.Size = UDim2.new(0.55, 0, 0, 18)
weaponNameLabel.Position = UDim2.new(0, 12, 0, 8)
weaponNameLabel.BackgroundTransparency = 1
weaponNameLabel.Font = Enum.Font.GothamBold
weaponNameLabel.Text = "TEST RIFLE"
weaponNameLabel.TextColor3 = THEME.TextWhite
weaponNameLabel.TextSize = 14
weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponNameLabel.Parent = ammoCard

local fireModeLabel = Instance.new("TextLabel")
fireModeLabel.Name = "FireMode"
fireModeLabel.Size = UDim2.new(0.55, 0, 0, 16)
fireModeLabel.Position = UDim2.new(0, 12, 0, 26)
fireModeLabel.BackgroundTransparency = 1
fireModeLabel.Font = Enum.Font.Gotham
fireModeLabel.Text = "[B] ●●● AUTO"
fireModeLabel.TextColor3 = THEME.TextMuted
fireModeLabel.TextSize = 11
fireModeLabel.TextXAlignment = Enum.TextXAlignment.Left
fireModeLabel.Parent = ammoCard

local weaponStatusLabel = Instance.new("TextLabel")
weaponStatusLabel.Name = "StatusMessage"
weaponStatusLabel.Size = UDim2.new(0.55, 0, 0, 16)
weaponStatusLabel.Position = UDim2.new(0, 12, 0, 44)
weaponStatusLabel.BackgroundTransparency = 1
weaponStatusLabel.Font = Enum.Font.GothamBold
weaponStatusLabel.Text = ""
weaponStatusLabel.TextColor3 = THEME.WarningYellow
weaponStatusLabel.TextSize = 11
weaponStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
weaponStatusLabel.Parent = ammoCard

-- Lado Direito do Cartão: Contagem de Balas Gigante + Reserva
local ammoNumbersContainer = Instance.new("Frame")
ammoNumbersContainer.Name = "Numbers"
ammoNumbersContainer.Size = UDim2.new(0.42, 0, 1, -8)
ammoNumbersContainer.Position = UDim2.new(1, -12, 0, 4)
ammoNumbersContainer.AnchorPoint = Vector2.new(1, 0)
ammoNumbersContainer.BackgroundTransparency = 1
ammoNumbersContainer.Parent = ammoCard

local currentAmmoLabel = Instance.new("TextLabel")
currentAmmoLabel.Name = "CurrentAmmo"
currentAmmoLabel.Size = UDim2.new(0.65, 0, 1, -4)
currentAmmoLabel.Position = UDim2.new(0, 0, 0, 0)
currentAmmoLabel.BackgroundTransparency = 1
currentAmmoLabel.Font = Enum.Font.GothamBold
currentAmmoLabel.Text = "30"
currentAmmoLabel.TextColor3 = THEME.TextWhite
currentAmmoLabel.TextSize = 38
currentAmmoLabel.TextXAlignment = Enum.TextXAlignment.Right
currentAmmoLabel.Parent = ammoNumbersContainer

local reserveAmmoLabel = Instance.new("TextLabel")
reserveAmmoLabel.Name = "ReserveAmmo"
reserveAmmoLabel.Size = UDim2.new(0.35, 0, 1, -4)
reserveAmmoLabel.Position = UDim2.new(0.65, 4, 0, 6)
reserveAmmoLabel.BackgroundTransparency = 1
reserveAmmoLabel.Font = Enum.Font.GothamMedium
reserveAmmoLabel.Text = "/ 90"
reserveAmmoLabel.TextColor3 = THEME.TextMuted
reserveAmmoLabel.TextSize = 16
reserveAmmoLabel.TextXAlignment = Enum.TextXAlignment.Left
reserveAmmoLabel.Parent = ammoNumbersContainer

-- Barra de Progresso de Recarga na Borda Inferior
local reloadBarBack = Instance.new("Frame")
reloadBarBack.Name = "ReloadProgressBack"
reloadBarBack.Size = UDim2.new(1, 0, 0, 3)
reloadBarBack.Position = UDim2.new(0, 0, 1, -3)
reloadBarBack.BackgroundColor3 = Color3.fromRGB(30, 38, 48)
reloadBarBack.BorderSizePixel = 0
reloadBarBack.Visible = false
reloadBarBack.Parent = ammoCard
addCorner(reloadBarBack, 2)

local reloadBarFill = Instance.new("Frame")
reloadBarFill.Name = "ReloadProgressFill"
reloadBarFill.Size = UDim2.new(0, 0, 1, 0)
reloadBarFill.BackgroundColor3 = THEME.WarningYellow
reloadBarFill.BorderSizePixel = 0
reloadBarFill.Parent = reloadBarBack

-- ═════════════════════════════════════════════════════════════════════════════
-- 4. CENTRO INFERIOR: CONFIRMAÇÃO DE ABATE / XP TÁTICO BF6 (ELEMENTO 11)
-- ═════════════════════════════════════════════════════════════════════════════

local killConfirmCard = Instance.new("Frame")
killConfirmCard.Name = "KillConfirmCard"
killConfirmCard.Size = UDim2.new(0, 260, 0, 68)
killConfirmCard.Position = UDim2.new(0.5, 0, 0.70, 0)
killConfirmCard.AnchorPoint = Vector2.new(0.5, 0.5)
killConfirmCard.BackgroundColor3 = THEME.DarkCard
killConfirmCard.BackgroundTransparency = 1
killConfirmCard.BorderSizePixel = 0
killConfirmCard.Visible = false
killConfirmCard.Parent = gui
addCorner(killConfirmCard, 4)
local killStroke = addStroke(killConfirmCard, THEME.DarkBorder, 1, 1)

local killSkull = Instance.new("TextLabel")
killSkull.Name = "SkullIcon"
killSkull.Size = UDim2.new(0, 30, 0, 30)
killSkull.Position = UDim2.new(0.5, -45, 0, 6)
killSkull.AnchorPoint = Vector2.new(0.5, 0)
killSkull.BackgroundTransparency = 1
killSkull.Font = Enum.Font.Gotham
killSkull.Text = "☠"
killSkull.TextColor3 = THEME.TextWhite
killSkull.TextSize = 24
killSkull.Parent = killConfirmCard

local killXp = Instance.new("TextLabel")
killXp.Name = "XpLabel"
killXp.Size = UDim2.new(0, 80, 0, 24)
killXp.Position = UDim2.new(0.5, 12, 0, 8)
killXp.AnchorPoint = Vector2.new(0, 0)
killXp.BackgroundTransparency = 1
killXp.Font = Enum.Font.GothamBold
killXp.Text = "+100 XP"
killXp.TextColor3 = THEME.CyanGaze
killXp.TextSize = 18
killXp.TextXAlignment = Enum.TextXAlignment.Left
killXp.Parent = killConfirmCard

local killTargetName = Instance.new("TextLabel")
killTargetName.Name = "TargetName"
killTargetName.Size = UDim2.new(1, 0, 0, 16)
killTargetName.Position = UDim2.new(0.5, 0, 0, 34)
killTargetName.AnchorPoint = Vector2.new(0.5, 0)
killTargetName.BackgroundTransparency = 1
killTargetName.Font = Enum.Font.GothamBold
killTargetName.Text = "INIMIGO"
killTargetName.TextColor3 = THEME.OrangeEnemy
killTargetName.TextSize = 13
killTargetName.Parent = killConfirmCard

local killTagBadge = Instance.new("TextLabel")
killTagBadge.Name = "TagBadge"
killTagBadge.Size = UDim2.new(1, 0, 0, 14)
killTagBadge.Position = UDim2.new(0.5, 0, 0, 50)
killTagBadge.AnchorPoint = Vector2.new(0.5, 0)
killTagBadge.BackgroundTransparency = 1
killTagBadge.Font = Enum.Font.GothamMedium
killTagBadge.Text = "[ ELIMINAÇÃO CONFIRMADA ]"
killTagBadge.TextColor3 = THEME.TextWhite
killTagBadge.TextSize = 11
killTagBadge.Parent = killConfirmCard

local currentKillTween: Tween? = nil
local function triggerKillConfirmation(targetName: string, isHeadshot: boolean)
	if currentKillTween then currentKillTween:Cancel() end

	killTargetName.Text = string.upper(targetName)
	if isHeadshot then
		killSkull.Text = "💀"
		killSkull.TextColor3 = THEME.CriticalRed
		killXp.Text = "+125 XP"
		killTagBadge.Text = "[ TIRO NA CABEÇA ]"
		killTagBadge.TextColor3 = THEME.CriticalRed
	else
		killSkull.Text = "☠"
		killSkull.TextColor3 = THEME.TextWhite
		killXp.Text = "+100 XP"
		killTagBadge.Text = "[ ELIMINAÇÃO CONFIRMADA ]"
		killTagBadge.TextColor3 = THEME.TextWhite
	end

	killConfirmCard.Position = UDim2.new(0.5, 0, 0.72, 0)
	killConfirmCard.BackgroundTransparency = 0.25
	killStroke.Transparency = 0.4
	killSkull.TextTransparency = 0
	killXp.TextTransparency = 0
	killTargetName.TextTransparency = 0
	killTagBadge.TextTransparency = 0
	killConfirmCard.Visible = true

	-- Animação de flutuação e fade out
	currentKillTween = TweenService:Create(killConfirmCard, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.67, 0),
		BackgroundTransparency = 1,
	})
	currentKillTween:Play()

	for _, elem in { killSkull, killXp, killTargetName, killTagBadge } do
		TweenService:Create(elem, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
		}):Play()
	end
	TweenService:Create(killStroke, TweenInfo.new(1.6), { Transparency = 1 }):Play()
end

-- ═════════════════════════════════════════════════════════════════════════════
-- 5. CANTO INFERIOR ESQUERDO: MINIMAPA & ESQUADRÃO (8, 9, 10, 16)
-- ═════════════════════════════════════════════════════════════════════════════

local bottomCluster = Instance.new("Frame")
bottomCluster.Name = "BottomLeftCluster"
bottomCluster.Size = UDim2.new(0, 220, 0, 240)
bottomCluster.Position = UDim2.new(0, 20, 1, -20)
bottomCluster.AnchorPoint = Vector2.new(0, 1)
bottomCluster.BackgroundTransparency = 1
bottomCluster.Parent = gui

-- Painel de Esquadrão (Elementos 8, 9, 10)
local squadPanel = Instance.new("Frame")
squadPanel.Name = "SquadPanel"
squadPanel.Size = UDim2.new(1, 0, 0, 72)
squadPanel.Position = UDim2.new(0, 0, 0, 0)
squadPanel.BackgroundTransparency = 1
squadPanel.Parent = bottomCluster

local squadLayout = Instance.new("UIListLayout")
squadLayout.FillDirection = Enum.FillDirection.Vertical
squadLayout.Padding = UDim.new(0, 3)
squadLayout.Parent = squadPanel

local function createSquadRow(indexNumber: number, className: string, classIcon: string, memberName: string, isSelf: boolean): Frame
	local row = Instance.new("Frame")
	row.Name = "Member_" .. indexNumber
	row.Size = UDim2.new(1, 0, 0, 20)
	row.BackgroundColor3 = THEME.DarkCard
	row.BackgroundTransparency = 0.45
	row.BorderSizePixel = 0
	addCorner(row, 3)

	-- Número do Esquadrão (1-4)
	local numBadge = Instance.new("TextLabel")
	numBadge.Name = "Num"
	numBadge.Size = UDim2.new(0, 16, 1, 0)
	numBadge.Position = UDim2.new(0, 4, 0, 0)
	numBadge.BackgroundTransparency = 1
	numBadge.Font = Enum.Font.GothamBold
	numBadge.Text = tostring(indexNumber)
	numBadge.TextColor3 = THEME.SquadGreen
	numBadge.TextSize = 11
	numBadge.Parent = row

	-- Ícone de Classe (▲, ✚, ⬡, ⌖)
	local classBadge = Instance.new("TextLabel")
	classBadge.Name = "Class"
	classBadge.Size = UDim2.new(0, 16, 1, 0)
	classBadge.Position = UDim2.new(0, 22, 0, 0)
	classBadge.BackgroundTransparency = 1
	classBadge.Font = Enum.Font.GothamBold
	classBadge.Text = classIcon
	classBadge.TextColor3 = THEME.SquadGreen
	classBadge.TextSize = 12
	classBadge.Parent = row

	-- Nome do Jogador
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -90, 1, 0)
	nameLabel.Position = UDim2.new(0, 42, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = if isSelf then Enum.Font.GothamBold else Enum.Font.GothamMedium
	nameLabel.Text = memberName
	nameLabel.TextColor3 = if isSelf then THEME.CyanFriendly else THEME.TextWhite
	nameLabel.TextSize = 11
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	-- Mini Barra de Vida (Verde) / Status
	local hpBarBack = Instance.new("Frame")
	hpBarBack.Name = "MiniHpBack"
	hpBarBack.Size = UDim2.new(0, 40, 0, 4)
	hpBarBack.Position = UDim2.new(1, -46, 0.5, -2)
	hpBarBack.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
	hpBarBack.BorderSizePixel = 0
	hpBarBack.Parent = row
	addCorner(hpBarBack, 1)

	local hpBarFill = Instance.new("Frame")
	hpBarFill.Name = "MiniHpFill"
	hpBarFill.Size = UDim2.new(1, 0, 1, 0)
	hpBarFill.BackgroundColor3 = THEME.SquadGreen
	hpBarFill.BorderSizePixel = 0
	hpBarFill.Parent = hpBarBack
	addCorner(hpBarFill, 1)

	row.Parent = squadPanel
	return row
end

-- Inicializa linhas do squad
createSquadRow(1, "Assault", "▲", player.Name, true)
createSquadRow(2, "Medic", "✚", "Nikolas", false)
createSquadRow(3, "Engineer", "⬡", "SteveH9669", false)

-- Barra de Vida Principal do Jogador (Elemento 16)
local healthContainer = Instance.new("Frame")
healthContainer.Name = "PlayerHealthContainer"
healthContainer.Size = UDim2.new(1, 0, 0, 32)
healthContainer.Position = UDim2.new(0, 0, 0, 78)
healthContainer.BackgroundColor3 = THEME.DarkCard
healthContainer.BackgroundTransparency = 0.35
healthContainer.BorderSizePixel = 0
healthContainer.Parent = bottomCluster
addCorner(healthContainer, 3)
addStroke(healthContainer, THEME.DarkBorder, 1, 0.4)

local healthLabel = Instance.new("TextLabel")
healthLabel.Name = "Health"
healthLabel.Size = UDim2.new(0, 95, 1, 0)
healthLabel.Position = UDim2.new(0, 10, 0, 0)
healthLabel.BackgroundTransparency = 1
healthLabel.Font = Enum.Font.GothamBold
healthLabel.Text = "HP  100 / 100"
healthLabel.TextColor3 = THEME.TextWhite
healthLabel.TextSize = 13
healthLabel.TextXAlignment = Enum.TextXAlignment.Left
healthLabel.Parent = healthContainer

local healthBarBack = Instance.new("Frame")
healthBarBack.Name = "HealthBarBackground"
healthBarBack.Size = UDim2.new(1, -120, 0, 6)
healthBarBack.Position = UDim2.new(1, -10, 0.5, -3)
healthBarBack.AnchorPoint = Vector2.new(1, 0)
healthBarBack.BackgroundColor3 = Color3.fromRGB(35, 45, 55)
healthBarBack.BorderSizePixel = 0
healthBarBack.Parent = healthContainer
addCorner(healthBarBack, 2)

local healthFill = Instance.new("Frame")
healthFill.Name = "HealthBarFill"
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = THEME.SquadGreen
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBarBack
addCorner(healthFill, 2)

-- Minimapa Tático (Radar BF6)
local minimapFrame = Instance.new("Frame")
minimapFrame.Name = "MinimapFrame"
minimapFrame.Size = UDim2.new(0, 130, 0, 120)
minimapFrame.Position = UDim2.new(0, 0, 1, 0)
minimapFrame.AnchorPoint = Vector2.new(0, 1)
minimapFrame.BackgroundColor3 = THEME.DarkBg
minimapFrame.BackgroundTransparency = 0.25
minimapFrame.BorderSizePixel = 0
minimapFrame.ClipsDescendants = true
minimapFrame.Parent = bottomCluster
addCorner(minimapFrame, 4)
addStroke(minimapFrame, THEME.DarkBorder, 1, 0.3)

local minimapSectorLabel = Instance.new("TextLabel")
minimapSectorLabel.Name = "SectorTitle"
minimapSectorLabel.Size = UDim2.new(1, -8, 0, 16)
minimapSectorLabel.Position = UDim2.new(0, 6, 0, 4)
minimapSectorLabel.BackgroundTransparency = 1
minimapSectorLabel.Font = Enum.Font.GothamBold
minimapSectorLabel.Text = "FRONTLINE // SETOR 1"
minimapSectorLabel.TextColor3 = THEME.TextMuted
minimapSectorLabel.TextSize = 9
minimapSectorLabel.TextXAlignment = Enum.TextXAlignment.Left
minimapSectorLabel.Parent = minimapFrame

-- Radar Círculo & Grade
local radarCenter = Instance.new("Frame")
radarCenter.Name = "RadarCenter"
radarCenter.Size = UDim2.new(0, 96, 0, 96)
radarCenter.Position = UDim2.new(0.5, 0, 0.5, 6)
radarCenter.AnchorPoint = Vector2.new(0.5, 0.5)
radarCenter.BackgroundTransparency = 1
radarCenter.Parent = minimapFrame

local radarRing1 = Instance.new("Frame")
radarRing1.Name = "Ring1"
radarRing1.Size = UDim2.new(1, 0, 1, 0)
radarRing1.BackgroundTransparency = 1
radarRing1.Parent = radarCenter
addCorner(radarRing1, 48)
addStroke(radarRing1, Color3.fromRGB(45, 65, 80), 1, 0.5)

local radarRing2 = Instance.new("Frame")
radarRing2.Name = "Ring2"
radarRing2.Size = UDim2.new(0.5, 0, 0.5, 0)
radarRing2.Position = UDim2.new(0.5, 0, 0.5, 0)
radarRing2.AnchorPoint = Vector2.new(0.5, 0.5)
radarRing2.BackgroundTransparency = 1
radarRing2.Parent = radarCenter
addCorner(radarRing2, 24)
addStroke(radarRing2, Color3.fromRGB(45, 65, 80), 1, 0.6)

-- Marcador do Jogador no Minimapa (Chevron Ciano)
local playerBlip = Instance.new("TextLabel")
playerBlip.Name = "PlayerBlip"
playerBlip.Size = UDim2.new(0, 14, 0, 14)
playerBlip.Position = UDim2.new(0.5, 0, 0.5, 0)
playerBlip.AnchorPoint = Vector2.new(0.5, 0.5)
playerBlip.BackgroundTransparency = 1
playerBlip.Font = Enum.Font.GothamBold
playerBlip.Text = "▲"
playerBlip.TextColor3 = THEME.CyanFriendly
playerBlip.TextSize = 13
playerBlip.Parent = radarCenter

-- Marcador do Ponto de Treino (Dummy) no Minimapa
local dummyBlip = Instance.new("TextLabel")
dummyBlip.Name = "DummyBlip"
dummyBlip.Size = UDim2.new(0, 12, 0, 12)
dummyBlip.Position = UDim2.new(0.5, 20, 0.5, -25)
dummyBlip.AnchorPoint = Vector2.new(0.5, 0.5)
dummyBlip.BackgroundTransparency = 1
dummyBlip.Font = Enum.Font.GothamBold
dummyBlip.Text = "◆"
dummyBlip.TextColor3 = THEME.OrangeEnemy
dummyBlip.TextSize = 11
dummyBlip.Parent = radarCenter

-- ═════════════════════════════════════════════════════════════════════════════
-- 6. RETÍCULA CENTRAL, EXPANSÃO DINÂMICA & HITMARKERS (ELEMENTO 18)
-- ═════════════════════════════════════════════════════════════════════════════

local reticleContainer = Instance.new("Frame")
reticleContainer.Name = "ReticleContainer"
reticleContainer.Size = UDim2.new(0, 60, 0, 60)
reticleContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
reticleContainer.AnchorPoint = Vector2.new(0.5, 0.5)
reticleContainer.BackgroundTransparency = 1
reticleContainer.Parent = gui

-- 4 Barras do Crosshair Dinâmico
local crosshairGap = 7
local crosshairLength = 7
local crosshairThickness = 2

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0, crosshairThickness, 0, crosshairLength)
topBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, -crosshairGap - crosshairLength)
topBar.BackgroundColor3 = THEME.TextWhite
topBar.BorderSizePixel = 0
topBar.Parent = reticleContainer

local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(0, crosshairThickness, 0, crosshairLength)
bottomBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, crosshairGap)
bottomBar.BackgroundColor3 = THEME.TextWhite
bottomBar.BorderSizePixel = 0
bottomBar.Parent = reticleContainer

local leftBar = Instance.new("Frame")
leftBar.Size = UDim2.new(0, crosshairLength, 0, crosshairThickness)
leftBar.Position = UDim2.new(0.5, -crosshairGap - crosshairLength, 0.5, -math.floor(crosshairThickness / 2))
leftBar.BackgroundColor3 = THEME.TextWhite
leftBar.BorderSizePixel = 0
leftBar.Parent = reticleContainer

local rightBar = Instance.new("Frame")
rightBar.Size = UDim2.new(0, crosshairLength, 0, crosshairThickness)
rightBar.Position = UDim2.new(0.5, crosshairGap, 0.5, -math.floor(crosshairThickness / 2))
rightBar.BackgroundColor3 = THEME.TextWhite
rightBar.BorderSizePixel = 0
rightBar.Parent = reticleContainer

-- Preserva a compatibilidade de busca pelo ConfirmedHitMarker
local hitMarker = Instance.new("TextLabel")
hitMarker.Name = "ConfirmedHitMarker"
hitMarker.Size = UDim2.new(0, 48, 0, 48)
hitMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.BackgroundTransparency = 1
hitMarker.Font = Enum.Font.GothamBold
hitMarker.Text = ""
hitMarker.TextColor3 = THEME.TextWhite
hitMarker.TextSize = 38
hitMarker.Parent = gui

-- ═════════════════════════════════════════════════════════════════════════════
-- 7. PAINEL DE FIM DE RODADA / VITÓRIA / DERROTA (ROUND RESULT)
-- ═════════════════════════════════════════════════════════════════════════════

local endPanel = Instance.new("TextLabel")
endPanel.Name = "RoundResult"
endPanel.Size = UDim2.new(0.56, 0, 0, 110)
endPanel.Position = UDim2.new(0.5, 0, 0.38, 0)
endPanel.AnchorPoint = Vector2.new(0.5, 0.5)
endPanel.BackgroundColor3 = THEME.DarkBg
endPanel.BackgroundTransparency = 0.15
endPanel.BorderSizePixel = 0
endPanel.Font = Enum.Font.GothamBold
endPanel.Text = ""
endPanel.TextColor3 = THEME.TextWhite
endPanel.TextSize = 28
endPanel.TextWrapped = false
endPanel.Visible = false
endPanel.Parent = gui
addCorner(endPanel, 6)
addStroke(endPanel, THEME.DarkBorder, 2, 0.2)

-- ═════════════════════════════════════════════════════════════════════════════
-- 8. LÓGICA DE ATUALIZAÇÃO DE SAÚDE, PARTIDA E MUNIÇÃO
-- ═════════════════════════════════════════════════════════════════════════════

local healthConnection: RBXScriptConnection? = nil
local maxHealthConnection: RBXScriptConnection? = nil

local function setHealth(health: number, maxHealth: number)
	local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
	healthFill.Size = UDim2.new(ratio, 0, 1, 0)
	local hpColor = if ratio <= 0.25 then THEME.CriticalRed
		elseif ratio <= 0.55 then THEME.WarningYellow
		else THEME.SquadGreen
	healthFill.BackgroundColor3 = hpColor
	healthLabel.Text = string.format("HP  %d / %d", math.ceil(health), math.ceil(maxHealth))
end

local function attachCharacter(character: Model)
	if healthConnection then healthConnection:Disconnect() end
	if maxHealthConnection then maxHealthConnection:Disconnect() end
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	setHealth(humanoid.Health, humanoid.MaxHealth)
	healthConnection = humanoid.HealthChanged:Connect(function(value)
		setHealth(value, humanoid.MaxHealth)
	end)
	maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		setHealth(humanoid.Health, humanoid.MaxHealth)
	end)
end

if player.Character then task.spawn(attachCharacter, player.Character) end
player.CharacterAdded:Connect(attachCharacter)

-- Atualização da Partida / Placar / Rodada
local function refreshRound()
	local blue = matchState:GetAttribute("BlueScore") or 0
	local orange = matchState:GetAttribute("OrangeScore") or 0
	local round = matchState:GetAttribute("Round") or 0
	local phase = matchState:GetAttribute("Phase") or "Waiting"
	local winner = matchState:GetAttribute("Winner") or ""

	blueTicketLabel.Text = string.format("[ %d ]", blue)
	orangeTicketLabel.Text = string.format("[ %d ]", orange)

	local maxScore = 50 -- meta de pontuação
	blueTicketFill.Size = UDim2.new(math.clamp(blue / maxScore, 0.05, 1), 0, 1, 0)
	orangeTicketFill.Size = UDim2.new(math.clamp(orange / maxScore, 0.05, 1), 0, 1, 0)

	scoreLabel.Text = string.format("SETOR DE OPERAÇÕES // AZUL %d  —  %d LARANJA", blue, orange)

	if phase == "Active" then
		local remaining = math.max(0, (matchState:GetAttribute("PhaseEndAt") or 0) - Workspace:GetServerTimeNow())
		roundLabel.Text = string.format("RODADA %d  •  %02d:%02d", round, math.floor(remaining / 60), math.floor(remaining % 60))
		roundLabel.TextColor3 = THEME.TextWhite
		endPanel.Visible = false
	elseif phase == "Intermission" then
		roundLabel.Text = "INTERVALO DE MISSÃO"
		roundLabel.TextColor3 = THEME.WarningYellow
		endPanel.Text = if winner == "Empate" then string.format("EMPATE TÁTICO  %d — %d", blue, orange)
			else string.format("VITÓRIA: %s  |  %d — %d", string.upper(winner), blue, orange)
		endPanel.TextColor3 = if winner == "Azul" then THEME.CyanFriendly else THEME.OrangeEnemy
		endPanel.Visible = true
	else
		roundLabel.Text = "AGUARDANDO COMBATENTES..."
		roundLabel.TextColor3 = THEME.TextMuted
		endPanel.Visible = false
	end
end

for _, attribute in { "BlueScore", "OrangeScore", "Round", "Phase", "Winner", "PhaseEndAt" } do
	matchState:GetAttributeChangedSignal(attribute):Connect(refreshRound)
end
refreshRound()

-- Atualização periódica leve da partida
task.spawn(function()
	while gui.Parent do
		if matchState:GetAttribute("Phase") == "Active" then refreshRound() end
		task.wait(0.25)
	end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- 9. MUNIÇÃO & ESTADO DA ARMA (SERVIÇO AUTORITATIVO + ATRIBUTOS LOCAIS)
-- ═════════════════════════════════════════════════════════════════════════════

local currentWeaponId = "TestRifle"
local currentAmmo = 30
local isReloading = false

local function updateWeaponDisplay(weaponId: string, ammo: number, reloading: boolean)
	currentWeaponId = weaponId
	currentAmmo = ammo
	isReloading = reloading

	local def = WeaponConfig[weaponId]
	local maxMag = if def then def.magazineSize else 30
	local maxReserve = if weaponId == "TestRifle" then 90 else 48

	weaponNameLabel.Text = string.upper(weaponId == "TestRifle" and "TEST RIFLE" or "SERVICE PISTOL")
	currentAmmoLabel.Text = tostring(ammo)
	reserveAmmoLabel.Text = "/ " .. tostring(maxReserve)

	-- Destaque visual dos slots
	if weaponId == "TestRifle" then
		slot1Stroke.Color = THEME.CyanFriendly
		slot1Stroke.Thickness = 2
		slot2Stroke.Color = THEME.DarkBorder
		slot2Stroke.Thickness = 1
		fireModeLabel.Text = "[B] ●●● AUTO"
	else
		slot1Stroke.Color = THEME.DarkBorder
		slot1Stroke.Thickness = 1
		slot2Stroke.Color = THEME.CyanFriendly
		slot2Stroke.Thickness = 2
		fireModeLabel.Text = "[B] ● SEMI"
	end

	-- Alerta de munição baixa
	local ratio = if maxMag > 0 then ammo / maxMag else 0
	if ratio <= 0.20 then
		currentAmmoLabel.TextColor3 = THEME.CriticalRed
	elseif ratio <= 0.40 then
		currentAmmoLabel.TextColor3 = THEME.WarningYellow
	else
		currentAmmoLabel.TextColor3 = THEME.TextWhite
	end

	-- Animação da barra de recarga
	if reloading then
		weaponStatusLabel.Text = "RECARREGANDO..."
		weaponStatusLabel.TextColor3 = THEME.WarningYellow
		reloadBarBack.Visible = true
		reloadBarFill.Size = UDim2.new(0, 0, 1, 0)
		local reloadDuration = if def then def.reloadTime else 2.0
		TweenService:Create(reloadBarFill, TweenInfo.new(reloadDuration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0),
		}):Play()
	else
		weaponStatusLabel.Text = ""
		reloadBarBack.Visible = false
	end
end

-- Escuta eventos autoritativos do servidor
weaponStateEvent.OnClientEvent:Connect(function(serverWeaponId: string, serverAmmo: number, serverReloading: boolean)
	updateWeaponDisplay(serverWeaponId, serverAmmo, serverReloading)
end)

-- Escuta atributos locais do jogador
player:GetAttributeChangedSignal("CurrentAmmo"):Connect(function()
	local a = player:GetAttribute("CurrentAmmo")
	if typeof(a) == "number" then
		updateWeaponDisplay(currentWeaponId, a, isReloading)
	end
end)

player:GetAttributeChangedSignal("CurrentWeapon"):Connect(function()
	local w = player:GetAttribute("CurrentWeapon")
	if typeof(w) == "string" then
		updateWeaponDisplay(w, currentAmmo, isReloading)
	end
end)

player:GetAttributeChangedSignal("IsReloading"):Connect(function()
	local r = player:GetAttribute("IsReloading")
	if typeof(r) == "boolean" then
		updateWeaponDisplay(currentWeaponId, currentAmmo, r)
	end
end)

player:GetAttributeChangedSignal("StatusMessage"):Connect(function()
	local msg = player:GetAttribute("StatusMessage")
	if typeof(msg) == "string" and msg ~= "" then
		weaponStatusLabel.Text = string.upper(msg)
	elseif not isReloading then
		weaponStatusLabel.Text = ""
	end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- 10. EXPANSÃO DA RETÍCULA & HITMARKER CONFIRMADO (ELEMENTO 18)
-- ═════════════════════════════════════════════════════════════════════════════

local hitToken = 0
hitConfirmed.OnClientEvent:Connect(function(targetName: string?, isHeadshot: boolean?, isKill: boolean?)
	hitToken += 1
	local currentToken = hitToken

	-- Hitmarker visual
	hitMarker.Text = "×"
	hitMarker.TextColor3 = if isHeadshot or isKill then THEME.CriticalRed else THEME.TextWhite
	hitMarker.TextSize = if isKill then 44 else 36
	hitMarker.TextTransparency = 0

	-- Se foi abate confirmado, dispara a notificação central estilo BF6 (+100 XP)
	if isKill and targetName then
		triggerKillConfirmation(targetName, isHeadshot or false)
		addKillFeedEntry(player.Name, targetName, currentWeaponId, isHeadshot or false)
	end

	task.spawn(function()
		task.wait(0.18)
		if hitMarker.Parent and currentToken == hitToken then
			hitMarker.Text = ""
		end
	end)
end)

-- Recoil dinâmico na retícula ao atirar
player:GetAttributeChangedSignal("LastShotAt"):Connect(function()
	topBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, -crosshairGap - crosshairLength - 6)
	bottomBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, crosshairGap + 6)
	leftBar.Position = UDim2.new(0.5, -crosshairGap - crosshairLength - 6, 0.5, -math.floor(crosshairThickness / 2))
	rightBar.Position = UDim2.new(0.5, crosshairGap + 6, 0.5, -math.floor(crosshairThickness / 2))

	task.delay(0.08, function()
		topBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, -crosshairGap - crosshairLength)
		bottomBar.Position = UDim2.new(0.5, -math.floor(crosshairThickness / 2), 0.5, crosshairGap)
		leftBar.Position = UDim2.new(0.5, -crosshairGap - crosshairLength, 0.5, -math.floor(crosshairThickness / 2))
		rightBar.Position = UDim2.new(0.5, crosshairGap, 0.5, -math.floor(crosshairThickness / 2))
	end)
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- 11. ATUALIZAÇÃO DO RADAR / MINIMAPA (RENDERSTEPPED)
-- ═════════════════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	-- Rotação do blip do jogador de acordo com a câmera
	local _, yaw, _ = camera.CFrame:ToOrientation()
	playerBlip.Rotation = -math.deg(yaw)

	-- Posição do Dummy em relação ao jogador
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local dummy = Workspace:FindFirstChild("TrainingDummy") :: Model?
	if root and dummy then
		local dummyPart = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChildWhichIsA("BasePart")
		if dummyPart and dummyPart:IsA("BasePart") then
			local delta = dummyPart.Position - root.Position
			local localOffset = camera.CFrame:VectorToObjectSpace(delta)
			local scaleDist = 0.45
			local blipX = math.clamp(localOffset.X * scaleDist, -40, 40)
			local blipY = math.clamp(-localOffset.Z * scaleDist, -40, 40)
			dummyBlip.Position = UDim2.new(0.5, math.floor(blipX), 0.5, math.floor(blipY))
			dummyBlip.Visible = true
		else
			dummyBlip.Visible = false
		end
	else
		dummyBlip.Visible = false
	end
end)

-- ═════════════════════════════════════════════════════════════════════════════
-- 12. MODO IMERSIVO (GAMERANT: DECLUTTER HUD SETTING VIA TECLA 'H')
-- ═════════════════════════════════════════════════════════════════════════════

local immersionBadge = Instance.new("TextLabel")
immersionBadge.Name = "ImmersionBadge"
immersionBadge.Size = UDim2.new(0, 240, 0, 24)
immersionBadge.Position = UDim2.new(0.5, 0, 0, 72)
immersionBadge.AnchorPoint = Vector2.new(0.5, 0)
immersionBadge.BackgroundColor3 = THEME.DarkCard
immersionBadge.BackgroundTransparency = 0.3
immersionBadge.Font = Enum.Font.GothamMedium
immersionBadge.Text = "[H] MODO IMERSIVO: PADRÃO"
immersionBadge.TextColor3 = THEME.TextMuted
immersionBadge.TextSize = 11
immersionBadge.Visible = false
immersionBadge.Parent = gui
addCorner(immersionBadge, 3)

local function toggleImmersiveMode()
	isImmersiveMode = not isImmersiveMode
	immersionBadge.Text = if isImmersiveMode then "[H] MODO IMERSIVO: ATIVO (SEM CLUTTER)" else "[H] MODO IMERSIVO: DESATIVADO"
	immersionBadge.TextColor3 = if isImmersiveMode then THEME.CyanFriendly else THEME.TextMuted
	immersionBadge.Visible = true

	local targetAlpha = if isImmersiveMode then 0.9 else 0
	local targetVisible = not isImmersiveMode

	TweenService:Create(squadPanel, TweenInfo.new(0.3), { GroupTransparency = targetAlpha }):Play()
	TweenService:Create(minimapFrame, TweenInfo.new(0.3), { BackgroundTransparency = if isImmersiveMode then 0.85 else 0.25 }):Play()
	radarCenter.Visible = targetVisible

	task.delay(2.5, function()
		if immersionBadge.Parent then immersionBadge.Visible = false end
	end)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.H then
		toggleImmersiveMode()
	end
end)

-- Inicializa com display padrão
updateWeaponDisplay("TestRifle", 30, false)

print("[Frontline][FL-022] HUD tático militar Battlefield 6 carregado com sucesso!")
