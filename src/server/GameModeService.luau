--!strict
-- FL-018: two server-owned teams, protected spawns, timed rounds and kill scoring.
-- Clients observe MatchState attributes; they never submit scores or team assignments.
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Match = Config.Match

type HitRecord = { attacker: Player, at: number }

local GameModeService = {}
local started = false
local phase = "WAITING_FOR_PLAYERS"
local roundNumber = 0
local blueScore = 0
local redScore = 0
local lastHit: {[Humanoid]: HitRecord} = {}

local blueTeam: Team
local redTeam: Team
local westSpawn: SpawnLocation
local eastSpawn: SpawnLocation
local matchState: Folder

local function ensureTeam(name: string, color: BrickColor): Team
    local existing = Teams:FindFirstChild(name)
    if existing then
        assert(existing:IsA("Team"), name .. " must be a Team")
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

local function ensureMatchState(): Folder
    local existing = ReplicatedStorage:FindFirstChild("MatchState")
    if existing then
        assert(existing:IsA("Folder"), "MatchState must be a Folder")
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = "MatchState"
    folder.Parent = ReplicatedStorage
    return folder
end

local function configureSpawn(arena: Model, name: string, team: Team): SpawnLocation
    local spawn = arena:FindFirstChild(name)
    assert(spawn and spawn:IsA("SpawnLocation"), "Missing team spawn: " .. name)
    spawn.Neutral = false
    spawn.TeamColor = team.TeamColor
    spawn.AllowTeamChangeOnTouch = false
    spawn.Enabled = true
    -- Shield is added explicitly to CharacterAdded to make protection testable.
    spawn.Duration = 0
    return spawn
end

local function teamCount(team: Team): number
    local count = 0
    for _, player in Players:GetPlayers() do
        if player.Team == team then count += 1 end
    end
    return count
end

local function enoughPlayers(): boolean
    return #Players:GetPlayers() >= Match.MinPlayers
        and teamCount(blueTeam) > 0
        and teamCount(redTeam) > 0
end

local function publishScores()
    matchState:SetAttribute("BlueScore", blueScore)
    matchState:SetAttribute("RedScore", redScore)
end

local function setPhase(nextPhase: string, seconds: number)
    phase = nextPhase
    matchState:SetAttribute("Phase", nextPhase)
    matchState:SetAttribute("SecondsRemaining", seconds)
end

local function finishRound(winner: string)
    if phase ~= "ACTIVE" then return end
    matchState:SetAttribute("Winner", winner)
    setPhase("ENDED", Match.EndSeconds)
    print(string.format("[Frontline][FL-018] round %d ended | winner=%s | %d-%d",
        roundNumber, winner, blueScore, redScore))
end

local function getStat(player: Player, name: string): IntValue?
    local board = player:FindFirstChild("leaderstats")
    local value = if board then board:FindFirstChild(name) else nil
    if value and value:IsA("IntValue") then return value end
    return nil
end

local function incrementStat(player: Player, name: string)
    local value = getStat(player, name)
    if value then value.Value += 1 end
end

local function ensureStats(player: Player)
    local board = player:FindFirstChild("leaderstats")
    if not board then
        board = Instance.new("Folder")
        board.Name = "leaderstats"
        board.Parent = player
    end
    for _, name in { "Kills", "Deaths" } do
        if not board:FindFirstChild(name) then
            local value = Instance.new("IntValue")
            value.Name = name
            value.Value = 0
            value.Parent = board
        end
    end
end

local function assignTeam(player: Player)
    local team = if teamCount(blueTeam) <= teamCount(redTeam) then blueTeam else redTeam
    player.Team = team
    player.Neutral = false
    player.RespawnLocation = if team == blueTeam then westSpawn else eastSpawn
end

local function onCharacterAdded(player: Player, character: Model)
    -- Humanoid:TakeDamage respects ForceField. A new shield is bound to every life.
    local shield = Instance.new("ForceField")
    shield.Name = "SpawnProtection"
    shield.Visible = true
    shield.Parent = character
    task.delay(Match.SpawnProtectionSeconds, function()
        if shield.Parent then shield:Destroy() end
    end)

    task.spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid or not humanoid:IsA("Humanoid") then return end
        local counted = false
        humanoid.Died:Connect(function()
            if counted then return end
            counted = true
            local hit = lastHit[humanoid]
            lastHit[humanoid] = nil
            if phase ~= "ACTIVE" then return end
            incrementStat(player, "Deaths")
            if not hit or os.clock() - hit.at > Match.KillCreditSeconds then return end
            local attacker = hit.attacker
            if attacker.Parent ~= Players or attacker == player
                or attacker.Team == nil or player.Team == nil
                or attacker.Team == player.Team then
                return
            end
            incrementStat(attacker, "Kills")
            if attacker.Team == blueTeam then
                blueScore += 1
            elseif attacker.Team == redTeam then
                redScore += 1
            else
                return
            end
            publishScores()
            print(string.format("[Frontline][FL-018] elimination | %s -> %s | %d-%d",
                attacker.Name, player.Name, blueScore, redScore))
            if blueScore >= Match.ScoreLimit then
                finishRound(blueTeam.Name)
            elseif redScore >= Match.ScoreLimit then
                finishRound(redTeam.Name)
            end
        end)
    end)
end

local function bindPlayer(player: Player)
    ensureStats(player)
    assignTeam(player)
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    if player.Character then onCharacterAdded(player, player.Character) end
end

local function waitPhase(seconds: number): boolean
    local deadline = os.clock() + seconds
    while os.clock() < deadline do
        if not enoughPlayers() then
            setPhase("WAITING_FOR_PLAYERS", 0)
            return false
        end
        matchState:SetAttribute("SecondsRemaining", math.max(0, math.ceil(deadline - os.clock())))
        task.wait(math.min(1, math.max(0.05, deadline - os.clock())))
    end
    return enoughPlayers()
end

local function runRounds()
    while true do
        if not enoughPlayers() then
            setPhase("WAITING_FOR_PLAYERS", 0)
            task.wait(1)
        else
            matchState:SetAttribute("Winner", "")
            setPhase("INTERMISSION", Match.IntermissionSeconds)
            if waitPhase(Match.IntermissionSeconds) then
                roundNumber += 1
                blueScore = 0
                redScore = 0
                publishScores()
                matchState:SetAttribute("RoundNumber", roundNumber)
                setPhase("ACTIVE", Match.RoundSeconds)
                local deadline = os.clock() + Match.RoundSeconds
                while phase == "ACTIVE" and enoughPlayers() and os.clock() < deadline do
                    matchState:SetAttribute("SecondsRemaining", math.max(0, math.ceil(deadline - os.clock())))
                    task.wait(0.5)
                end
                if phase == "ACTIVE" then
                    if not enoughPlayers() then
                        setPhase("WAITING_FOR_PLAYERS", 0)
                    else
                        local winner = if blueScore > redScore then blueTeam.Name
                            elseif redScore > blueScore then redTeam.Name else "TIE"
                        finishRound(winner)
                    end
                end
                if phase == "ENDED" then
                    waitPhase(Match.EndSeconds)
                end
            end
        end
    end
end

function GameModeService.CanDamage(shooter: Player, humanoid: Humanoid): boolean
    local model = humanoid.Parent
    if not model or not model:IsA("Model") then return false end
    if model:FindFirstChildOfClass("ForceField") then return false end
    local victim = Players:GetPlayerFromCharacter(model)
    if not victim then return true end -- training dummy remains usable
    return phase == "ACTIVE" and shooter ~= victim
        and shooter.Team ~= nil and victim.Team ~= nil
        and shooter.Team ~= victim.Team
end

function GameModeService.RecordHit(shooter: Player, humanoid: Humanoid)
    if phase ~= "ACTIVE" then return end
    local model = humanoid.Parent
    if not model or not model:IsA("Model") then return end
    local victim = Players:GetPlayerFromCharacter(model)
    if not victim or not GameModeService.CanDamage(shooter, humanoid) then return end
    lastHit[humanoid] = { attacker = shooter, at = os.clock() }
end

function GameModeService.Start()
    if started then return end
    started = true
    blueTeam = ensureTeam("Blue", BrickColor.new("Bright blue"))
    redTeam = ensureTeam("Red", BrickColor.new("Bright red"))
    local arena = Workspace:WaitForChild("GreyboxArena")
    assert(arena:IsA("Model"), "GreyboxArena must be a Model")
    westSpawn = configureSpawn(arena, "Spawn_WestEntry", blueTeam)
    eastSpawn = configureSpawn(arena, "Spawn_EastEntry", redTeam)
    Players.RespawnTime = Match.RespawnSeconds
    matchState = ensureMatchState()
    matchState:SetAttribute("RoundNumber", roundNumber)
    matchState:SetAttribute("ScoreLimit", Match.ScoreLimit)
    matchState:SetAttribute("Winner", "")
    publishScores()
    setPhase("WAITING_FOR_PLAYERS", 0)
    Players.PlayerAdded:Connect(bindPlayer)
    for _, player in Players:GetPlayers() do bindPlayer(player) end
    Players.PlayerRemoving:Connect(function(player)
        for humanoid, hit in lastHit do
            if hit.attacker == player then lastHit[humanoid] = nil end
        end
    end)
    task.spawn(runRounds)
    print("[Frontline][FL-018] teams, protected spawns and match loop ready")
end

return GameModeService
