--!strict
-- FL-010: munição, recarga e dano são mantidos pelo servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))
local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))

type ShotPayload = {
	weaponId: string,
	origin: Vector3,
	direction: Vector3,
	targetPosition: Vector3,
	maxRange: number,
}

type WeaponState = {
	equippedWeaponId: string,
	ammoByWeapon: {[string]: number},
	reloadingByWeapon: {[string]: boolean},
	generationByWeapon: {[string]: number},
}

local DamageService = {}
local started = false
local states: {[Player]: WeaponState} = {}
local lastReloadRequestAt: {[Player]: number} = {}
local stateEvent: RemoteEvent
local worldExclusions: {Instance} = {}
local matchService: any
local destructionService: any

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
		local ammoByWeapon: {[string]: number} = {}
		local reloadingByWeapon: {[string]: boolean} = {}
		local generationByWeapon: {[string]: number} = {}
		for weaponId, def in WeaponConfig do
			ammoByWeapon[weaponId] = def.magazineSize
			reloadingByWeapon[weaponId] = false
			generationByWeapon[weaponId] = 0
		end
		state = {
			equippedWeaponId = Config.Combat.TestWeaponId,
			ammoByWeapon = ammoByWeapon,
			reloadingByWeapon = reloadingByWeapon,
			generationByWeapon = generationByWeapon,
		}
		states[player] = state
	end
	return state
end

local function sendState(player: Player)
	local state = getState(player)
	local weaponId = state.equippedWeaponId
	stateEvent:FireClient(player, weaponId, state.ammoByWeapon[weaponId], state.reloadingByWeapon[weaponId])
end

local function resetState(player: Player)
	local state = getState(player)
	for weaponId, def in WeaponConfig do
		state.generationByWeapon[weaponId] += 1
		state.ammoByWeapon[weaponId] = def.magazineSize
		state.reloadingByWeapon[weaponId] = false
	end
	sendState(player)
end

local function beginReload(player: Player)
	local state = getState(player)
	local weaponId = state.equippedWeaponId
	local def = WeaponConfig[weaponId]
	if not def then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or state.reloadingByWeapon[weaponId] or state.ammoByWeapon[weaponId] >= def.magazineSize then
		sendState(player)
		return
	end
	state.generationByWeapon[weaponId] += 1
	local generation = state.generationByWeapon[weaponId]
	state.reloadingByWeapon[weaponId] = true
	sendState(player)
	task.delay(def.reloadTime, function()
		if player.Parent ~= Players or states[player] ~= state or state.generationByWeapon[weaponId] ~= generation then return end
		local currentCharacter = player.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		if not currentHumanoid or currentHumanoid.Health <= 0 then
			state.reloadingByWeapon[weaponId] = false
		else
			state.ammoByWeapon[weaponId] = def.magazineSize
			state.reloadingByWeapon[weaponId] = false
		end
		sendState(player)
	end)
end

local function applyShot(shooter: Player, shot: ShotPayload)
	local def = WeaponConfig[shot.weaponId]
	if not def then return end
	local state = getState(shooter)
	if shot.weaponId ~= state.equippedWeaponId then return end
	if state.reloadingByWeapon[shot.weaponId] or state.ammoByWeapon[shot.weaponId] <= 0 then
		sendState(shooter)
		return
	end
	state.ammoByWeapon[shot.weaponId] -= 1
	sendState(shooter)

	-- Constrói exclusões por disparo para garantir que o atirador nunca bloqueie o próprio tiro.
	local excluded = table.clone(worldExclusions)
	local character = shooter.Character
	if character then table.insert(excluded, character) end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	local result = workspace:Raycast(shot.origin, shot.direction * shot.maxRange, params)
	if not result then return end
	local distance = (result.Position - shot.origin).Magnitude
	local dropoffAlpha = math.clamp((distance - def.dropoffStart) / (def.dropoffEnd - def.dropoffStart), 0, 1)
	local baseDamage = def.damage + (def.minimumDamage - def.damage) * dropoffAlpha
	if destructionService.ApplyHit(result.Instance, baseDamage) then
		print(string.format("[Frontline][FL-021] cobertura atingida | arma=%s | dano=%.1f", shot.weaponId, baseDamage))
		return
	end

	local model = result.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	if not model or model == character or not humanoid or humanoid.Health <= 0 then return end
	local targetPlayer = Players:GetPlayerFromCharacter(model)
	if targetPlayer and not matchService.CanDamage(shooter, targetPlayer) then return end
	local damage = baseDamage * (if result.Instance.Name == "Head" then def.headshotMultiplier else 1)
	local healthBefore = humanoid.Health
	local ok, err = pcall(function() humanoid:TakeDamage(damage) end)
	if not ok then
		warn("[Frontline][FL-010] erro ao aplicar dano:", err)
		return
	end
	if targetPlayer and healthBefore > 0 and humanoid.Health <= 0 then
		matchService.RecordElimination(shooter, targetPlayer)
	end
	print(string.format("[Frontline][FL-010] HIT | %s -> %s | dmg=%.0f%s", shooter.Name, model.Name, damage,
		if result.Instance.Name == "Head" then " [HEADSHOT]" else ""))
end

function DamageService.Start(combatRequestService: any, matchServiceArg: any, destructionServiceArg: any)
	if started then return end
	assert(matchServiceArg, "MatchService ausente")
	assert(destructionServiceArg, "DestructibleCoverService ausente")
	matchService = matchServiceArg
	destructionService = destructionServiceArg
	started = true
	stateEvent = getOrCreateRemote(NetProtocol.WeaponStateEvent)
	local reloadEvent = getOrCreateRemote(NetProtocol.ReloadWeaponEvent)
	combatRequestService.OnWeaponEquipped(function(player: Player, weaponId: string)
		local state = getState(player)
		state.equippedWeaponId = weaponId
		sendState(player)
	end)
	for _, desc in workspace:GetDescendants() do
		if desc:IsA("BasePart") and (desc:GetAttribute("ArenaRole") == "Ground" or desc:IsA("SpawnLocation")) then
			table.insert(worldExclusions, desc)
		end
	end
	reloadEvent.OnServerEvent:Connect(function(player: Player, ...: any)
		if select("#", ...) > 0 then return end
		local now = os.clock()
		local lastRequest = lastReloadRequestAt[player] or -math.huge
		if now - lastRequest < Config.Combat.ReloadRequestInterval then return end
		lastReloadRequestAt[player] = now
		beginReload(player)
	end)
	combatRequestService.OnShotAccepted(function(player: Player, shot: ShotPayload)
		applyShot(player, shot)
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
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		lastReloadRequestAt[player] = nil
	end)
	print("[Frontline][FL-010] dano e estado autoritativo do rifle ativos")
end

return DamageService
