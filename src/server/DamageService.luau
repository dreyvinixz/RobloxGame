--!strict
-- FL-010: munição, recarga e dano são mantidos pelo servidor.
-- FL-018: team damage, spawn protection and kill attribution use GameModeService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))
local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))

type ShotPayload = {
    weaponId: string,
    origin: Vector3,
    direction: Vector3,
    targetPosition: Vector3,
    maxRange: number,
}

type WeaponState = { ammo: number, reloading: boolean, generation: number }

local DamageService = {}
local started = false
local states: {[Player]: WeaponState} = {}
local stateEvent: RemoteEvent
local worldExclusions: {Instance} = {}

local function getOrCreateRemote(name: string): RemoteEvent
    local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
    local existing = remotes:FindFirstChild(name)
    if existing then
        assert(existing:IsA("RemoteEvent"), name .. " precisa ser RemoteEvent")
        return existing
    end
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = remotes
    return event
end

local function getState(player: Player): WeaponState
    local state = states[player]
    if not state then
        state = { ammo = WeaponConfig.TestRifle.magazineSize, reloading = false, generation = 0 }
        states[player] = state
    end
    return state
end

local function sendState(player: Player)
    local state = getState(player)
    stateEvent:FireClient(player, state.ammo, state.reloading)
end

local function resetState(player: Player)
    local state = getState(player)
    state.generation += 1
    state.ammo = WeaponConfig.TestRifle.magazineSize
    state.reloading = false
    sendState(player)
end

local function beginReload(player: Player)
    local def = WeaponConfig.TestRifle
    local state = getState(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 or state.reloading or state.ammo >= def.magazineSize then
        sendState(player)
        return
    end
    state.generation += 1
    local generation = state.generation
    state.reloading = true
    sendState(player)
    task.delay(def.reloadTime, function()
        if player.Parent ~= Players or states[player] ~= state or state.generation ~= generation then return end
        local currentCharacter = player.Character
        local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
        if not currentHumanoid or currentHumanoid.Health <= 0 then
            state.reloading = false
        else
            state.ammo = def.magazineSize
            state.reloading = false
        end
        sendState(player)
    end)
end

local function applyShot(shooter: Player, shot: ShotPayload, gameModeService: any)
    local def = WeaponConfig[shot.weaponId]
    if not def then return end
    local state = getState(shooter)
    if state.reloading or state.ammo <= 0 then
        sendState(shooter)
        return
    end
    state.ammo -= 1
    sendState(shooter)

    local excluded = table.clone(worldExclusions)
    local character = shooter.Character
    if character then table.insert(excluded, character) end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = excluded
    local result = workspace:Raycast(shot.origin, shot.direction * shot.maxRange, params)
    if not result then return end

    local model = result.Instance:FindFirstAncestorOfClass("Model")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not model or model == character or not humanoid or humanoid.Health <= 0 then return end
    -- Player damage is blocked during intermission, for allies and during spawn shield.
    -- NPC dummies remain valid training targets; all checks execute server-side.
    if not gameModeService.CanDamage(shooter, humanoid) then return end
    local damage = def.damage * (if result.Instance.Name == "Head" then def.headshotMultiplier else 1)
    -- Register BEFORE TakeDamage: a lethal hit may synchronously fire Humanoid.Died.
    gameModeService.RecordHit(shooter, humanoid)
    local ok, err = pcall(function() humanoid:TakeDamage(damage) end)
    if not ok then
        warn("[Frontline][FL-010] erro ao aplicar dano:", err)
        return
    end
    print(string.format("[Frontline][FL-010] HIT | %s -> %s | dmg=%.0f%s", shooter.Name, model.Name, damage,
        if result.Instance.Name == "Head" then " [HEADSHOT]" else ""))
end

function DamageService.Start(combatRequestService: any, gameModeService: any)
    if started then return end
    started = true
    stateEvent = getOrCreateRemote(NetProtocol.WeaponStateEvent)
    local reloadEvent = getOrCreateRemote(NetProtocol.ReloadWeaponEvent)
    for _, desc in workspace:GetDescendants() do
        if desc:IsA("BasePart") and (desc:GetAttribute("ArenaRole") == "Ground" or desc:IsA("SpawnLocation")) then
            table.insert(worldExclusions, desc)
        end
    end
    reloadEvent.OnServerEvent:Connect(function(player: Player, ...: any)
        if select("#", ...) > 0 then return end
        beginReload(player)
    end)
    combatRequestService.OnShotAccepted(function(player: Player, shot: ShotPayload)
        applyShot(player, shot, gameModeService)
    end)
    Players.PlayerAdded:Connect(function(player)
        getState(player)
        player.CharacterAdded:Connect(function()
            task.defer(resetState, player)
        end)
    end)
    for _, player in Players:GetPlayers() do
        getState(player)
        player.CharacterAdded:Connect(function() task.defer(resetState, player) end)
        if player.Character then task.defer(sendState, player) end
    end
    Players.PlayerRemoving:Connect(function(player) states[player] = nil end)
    print("[Frontline][FL-010/FL-018] server-authoritative rifle and team damage active")
end

return DamageService
