--!strict
-- FL-022: replica HP/placar/rodada e só mostra hit confirmado pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local hitConfirmed = remotes:WaitForChild(NetProtocol.HitConfirmedEvent) :: RemoteEvent
local matchState = ReplicatedStorage:WaitForChild("MatchState")

local gui = Instance.new("ScreenGui")
gui.Name = "FrontlineHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(name: string, size: UDim2, position: UDim2, anchor: Vector2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor
	label.BackgroundColor3 = Color3.fromRGB(15, 19, 23)
	label.BackgroundTransparency = 0.2
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(242, 244, 246)
	label.TextScaled = true
	label.TextSize = textSize
	label.TextWrapped = true
	label.Parent = gui
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = 12
	constraint.MaxTextSize = textSize
	constraint.Parent = label
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	return label
end

local scoreLabel = makeLabel("TeamScore", UDim2.fromScale(0.28, 0.065), UDim2.fromScale(0.5, 0.035), Vector2.new(0.5, 0), 26)
local roundLabel = makeLabel("RoundStatus", UDim2.fromScale(0.22, 0.045), UDim2.fromScale(0.5, 0.105), Vector2.new(0.5, 0), 18)
local healthLabel = makeLabel("Health", UDim2.fromScale(0.18, 0.055), UDim2.fromScale(0.025, 0.92), Vector2.new(0, 1), 22)
local hitMarker = makeLabel("ConfirmedHitMarker", UDim2.fromOffset(44, 44), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 36)
hitMarker.BackgroundTransparency = 1
hitMarker.Text = ""

local endPanel = makeLabel("RoundResult", UDim2.fromScale(0.42, 0.16), UDim2.fromScale(0.5, 0.38), Vector2.new(0.5, 0.5), 30)
endPanel.BackgroundTransparency = 0.08
endPanel.Visible = false

local healthBarBack = Instance.new("Frame")
healthBarBack.Name = "HealthBarBackground"
healthBarBack.Size = UDim2.fromScale(0.18, 0.018)
healthBarBack.Position = UDim2.fromScale(0.025, 0.925)
healthBarBack.BackgroundColor3 = Color3.fromRGB(50, 54, 58)
healthBarBack.BorderSizePixel = 0
healthBarBack.Parent = gui
local healthFill = Instance.new("Frame")
healthFill.Name = "HealthBarFill"
healthFill.Size = UDim2.fromScale(1, 1)
healthFill.BackgroundColor3 = Color3.fromRGB(83, 205, 129)
healthFill.BorderSizePixel = 0
healthFill.Parent = healthBarBack

local healthConnection: RBXScriptConnection? = nil
local maxHealthConnection: RBXScriptConnection? = nil
local function setHealth(health: number, maxHealth: number)
	local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthFill.BackgroundColor3 = if ratio <= 0.25 then Color3.fromRGB(221, 76, 65)
		else if ratio <= 0.55 then Color3.fromRGB(231, 177, 69) else Color3.fromRGB(83, 205, 129)
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

local function refreshRound()
	local blue = matchState:GetAttribute("BlueScore") or 0
	local orange = matchState:GetAttribute("OrangeScore") or 0
	local round = matchState:GetAttribute("Round") or 0
	local phase = matchState:GetAttribute("Phase") or "Waiting"
	local winner = matchState:GetAttribute("Winner") or ""
	scoreLabel.Text = string.format("AZUL  %d   —   %d  LARANJA", blue, orange)
	if phase == "Active" then
		local remaining = math.max(0, (matchState:GetAttribute("PhaseEndAt") or 0) - Workspace:GetServerTimeNow())
		roundLabel.Text = string.format("RODADA %d  •  %02d:%02d", round, math.floor(remaining / 60), math.floor(remaining % 60))
		endPanel.Visible = false
	elseif phase == "Intermission" then
		roundLabel.Text = "INTERVALO"
		endPanel.Text = if winner == "Empate" then string.format("EMPATE  %d — %d", blue, orange)
			else string.format("VITÓRIA: %s  |  %d — %d", winner, blue, orange)
		endPanel.Visible = true
	else
		roundLabel.Text = "AGUARDANDO JOGADORES"
		endPanel.Visible = false
	end
end

for _, attribute in { "BlueScore", "OrangeScore", "Round", "Phase", "Winner", "PhaseEndAt" } do
	matchState:GetAttributeChangedSignal(attribute):Connect(refreshRound)
end
refreshRound()
task.spawn(function()
	while gui.Parent do
		if matchState:GetAttribute("Phase") == "Active" then refreshRound() end
		task.wait(0.25)
	end
end)

local hitToken = 0
hitConfirmed.OnClientEvent:Connect(function()
	hitToken += 1
	local currentToken = hitToken
	hitMarker.Text = "×"
	hitMarker.TextTransparency = 0
	task.spawn(function()
		task.wait(0.16)
		if hitMarker.Parent and currentToken == hitToken then hitMarker.Text = "" end
	end)
end)

print("[Frontline][FL-022] HUD de HP, equipes e resultado pronto")
