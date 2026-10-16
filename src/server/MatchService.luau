--!strict
-- FL-018: times, spawns e placar são controlados somente pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MatchService = {}
local started = false
local blueTeam: Team
local orangeTeam: Team
local blueSpawn: SpawnLocation
local orangeSpawn: SpawnLocation
local state: Folder
local phase = "Waiting"
local roundNumber = 0
local blueScore = 0
local orangeScore = 0
local phaseEndAt = 0
local winner = ""
local nextTieGoesBlue = true

local function getOrCreateTeam(name: string, color: BrickColor): Team
	local existing = Teams:FindFirstChild(name)
	if existing then
		assert(existing:IsA("Team"), name .. " precisa ser Team")
		existing.TeamColor = color
		existing.AutoAssignable = false
		return existing
	end
	local team = Instance.new("Team")
	team.Name = name
	team.TeamColor = color
	team.AutoAssignable = false
	team.Parent = Teams
	return team
end

local function requireSpawn(arena: Model, name: string): SpawnLocation
	local instance = arena:FindFirstChild(name, true)
	assert(instance and instance:IsA("SpawnLocation"), "spawn ausente: " .. name)
	return instance
end

local function configureSpawn(spawn: SpawnLocation, team: Team)
	spawn.Neutral = false
	spawn.TeamColor = team.TeamColor
	spawn.BrickColor = team.TeamColor
	spawn.Enabled = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = Config.Match.SpawnProtectionSeconds
end

local function getTerrain2TestSpawn(): SpawnLocation?
	if Workspace:GetAttribute("Terrain2TestMode") ~= true then return nil end
	local instance = Workspace:FindFirstChild("V7_TestSpawn", true)
	assert(instance and instance:IsA("SpawnLocation"),
		"Terrain2TestMode exige um Workspace.V7_TestSpawn")
	instance.Neutral = true
	instance.Enabled = true
	instance.AllowTeamChangeOnTouch = false
	instance.Duration = Config.Match.SpawnProtectionSeconds
	return instance
end

local function setState()
	state:SetAttribute("Phase", phase)
	state:SetAttribute("Round", roundNumber)
	state:SetAttribute("BlueScore", blueScore)
	state:SetAttribute("OrangeScore", orangeScore)
	state:SetAttribute("ScoreToWin", Config.Match.ScoreToWin)
	state:SetAttribute("PhaseEndAt", phaseEndAt)
	state:SetAttribute("Winner", winner)
end

local function getOrCreateStat(player: Player, name: string): IntValue
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	assert(leaderstats:IsA("Folder"), "leaderstats precisa ser Folder")
	local existing = leaderstats:FindFirstChild(name)
	if existing then
		assert(existing:IsA("IntValue"), name .. " precisa ser IntValue")
		return existing
	end
	local value = Instance.new("IntValue")
	value.Name = name
	value.Parent = leaderstats
	return value
end

local function assignTeam(player: Player)
	local blueCount, orangeCount = 0, 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			if other.Team == blueTeam then blueCount += 1 end
			if other.Team == orangeTeam then orangeCount += 1 end
		end
	end
	local chooseBlue = blueCount < orangeCount or (blueCount == orangeCount and nextTieGoesBlue)
	if blueCount == orangeCount then nextTieGoesBlue = not nextTieGoesBlue end
	player.Team = if chooseBlue then blueTeam else orangeTeam
	player.Neutral = false
	player.RespawnLocation = if chooseBlue then blueSpawn else orangeSpawn
	getOrCreateStat(player, "KOs")
	getOrCreateStat(player, "Deaths")
	print(string.format("[Frontline][FL-018] %s -> %s", player.Name, player.Team.Name))
end

local function resetCurrentCharacters()
	for _, player in Players:GetPlayers() do
		task.spawn(function()
			if player.Parent == Players then
				local ok, err = pcall(function() player:LoadCharacterAsync() end)
				if not ok then warn("[Frontline][FL-018] falha no respawn:", player.Name, err) end
			end
		end)
	end
end

local function startRound()
	roundNumber += 1
	blueScore = 0
	orangeScore = 0
	winner = ""
	phase = "Active"
	phaseEndAt = Workspace:GetServerTimeNow() + Config.Match.RoundDurationSeconds
	setState()
	resetCurrentCharacters()
	print(string.format("[Frontline][FL-018] rodada %d iniciada", roundNumber))
end

local function finishRound()
	if phase ~= "Active" then return end
	if blueScore > orangeScore then winner = blueTeam.Name
	elseif orangeScore > blueScore then winner = orangeTeam.Name
	else winner = "Empate" end
	phase = "Intermission"
	phaseEndAt = Workspace:GetServerTimeNow() + Config.Match.IntermissionSeconds
	setState()
	print(string.format("[Frontline][FL-018] rodada %d encerrada | vencedor=%s | %d:%d", roundNumber, winner, blueScore, orangeScore))
end

local function waitForPlayers()
	phase = "Waiting"
	blueScore = 0
	orangeScore = 0
	winner = ""
	phaseEndAt = 0
	setState()
end

function MatchService.CanDamage(shooter: Player, target: Player): boolean
	if not started or phase ~= "Active" or shooter == target then return false end
	if shooter.Parent ~= Players or target.Parent ~= Players then return false end
	if not shooter.Team or not target.Team or shooter.Team == target.Team then return false end
	local character = target.Character
	if character and character:FindFirstChildWhichIsA("ForceField", true) then return false end
	return true
end

function MatchService.RecordElimination(shooter: Player, target: Player)
	if not MatchService.CanDamage(shooter, target) then return end
	local score: number
	if shooter.Team == blueTeam then
		blueScore += 1
		score = blueScore
	elseif shooter.Team == orangeTeam then
		orangeScore += 1
		score = orangeScore
	else
		return
	end
	getOrCreateStat(shooter, "KOs").Value += 1
	getOrCreateStat(target, "Deaths").Value += 1
	setState()
	print(string.format("[Frontline][FL-018] eliminação | %s -> %s | %d:%d", shooter.Name, target.Name, blueScore, orangeScore))
	if score >= Config.Match.ScoreToWin then finishRound() end
end

function MatchService.Start(arena: Model)
	if started then return end
	blueTeam = getOrCreateTeam("Azul", BrickColor.new("Bright blue"))
	orangeTeam = getOrCreateTeam("Laranja", BrickColor.new("Bright orange"))
	local terrain2TestSpawn = getTerrain2TestSpawn()
	if terrain2TestSpawn then
		-- Opt-in only in the isolated Terrain 2 test place; production keeps team entries.
		blueSpawn = terrain2TestSpawn
		orangeSpawn = terrain2TestSpawn
		print("[Frontline][FL-018] Terrain 2 test spawn enabled")
	else
		blueSpawn = requireSpawn(arena, "Spawn_WestEntry")
		orangeSpawn = requireSpawn(arena, "Spawn_EastEntry")
		configureSpawn(blueSpawn, blueTeam)
		configureSpawn(orangeSpawn, orangeTeam)
	end
	Players.RespawnTime = Config.Match.RespawnSeconds
	local existing = ReplicatedStorage:FindFirstChild("MatchState")
	if existing then
		assert(existing:IsA("Folder"), "MatchState precisa ser Folder")
		state = existing
	else
		state = Instance.new("Folder")
		state.Name = "MatchState"
		state.Parent = ReplicatedStorage
	end
	started = true
	setState()
	Players.PlayerAdded:Connect(assignTeam)
	for _, player in Players:GetPlayers() do assignTeam(player) end
	task.spawn(function()
		while started do
			local now = Workspace:GetServerTimeNow()
			local playerCount = #Players:GetPlayers()
			if phase == "Waiting" and playerCount >= 2 then
				startRound()
			elseif phase == "Active" then
				if playerCount < 2 then waitForPlayers()
				elseif now >= phaseEndAt then finishRound() end
			elseif phase == "Intermission" and now >= phaseEndAt then
				if playerCount >= 2 then startRound() else waitForPlayers() end
			end
			task.wait(0.5)
		end
	end)
	print("[Frontline][FL-018] MatchService ativo | 2 times | alvo=" .. Config.Match.ScoreToWin)
end

return MatchService
