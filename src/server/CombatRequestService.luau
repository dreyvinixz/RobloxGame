--!strict
-- FL-009: valida intenções de disparo; não aceita nem aplica dano do cliente.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))

type ShotPayload = {
	weaponId: string,
	origin: Vector3,
	direction: Vector3,
	targetPosition: Vector3,
	maxRange: number,
}

local CombatRequestService = {}
local lastRequestAt: {[Player]: number} = {}
local lastRejectLogAt: {[Player]: {[string]: number}} = {}
local shotAccepted = Instance.new("BindableEvent")
local started = false

local function getOrCreateFireEvent(): RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
	local existing = remotes:FindFirstChild(NetProtocol.FireWeaponEvent)
	if existing then
		assert(existing:IsA("RemoteEvent"), "FireWeapon precisa ser RemoteEvent")
		return existing
	end

	local fireEvent = Instance.new("RemoteEvent")
	fireEvent.Name = NetProtocol.FireWeaponEvent
	fireEvent.Parent = remotes
	return fireEvent
end

local function reject(player: Player, reason: string)
	local now = os.clock()
	local playerLogs = lastRejectLogAt[player]
	if not playerLogs then
		playerLogs = {}
		lastRejectLogAt[player] = playerLogs
	end

	local lastLog = playerLogs[reason]
	if not lastLog or now - lastLog >= Config.Combat.RejectLogInterval then
		playerLogs[reason] = now
		warn(string.format("[Frontline][FL-009] tiro recusado | player=%s | motivo=%s", player.Name, reason))
	end
end

local function isFiniteVector3(value: Vector3): boolean
	return value.X == value.X and value.Y == value.Y and value.Z == value.Z
		and math.abs(value.X) < 1e6 and math.abs(value.Y) < 1e6 and math.abs(value.Z) < 1e6
end

local function hasExactPayloadKeys(payload: {[any]: any}): boolean
	local count = 0
	for key in payload do
		if key ~= "weaponId" and key ~= "origin" and key ~= "direction" and key ~= "targetPosition" then
			return false
		end
		count += 1
	end
	return count == 4
end

local function validateShot(player: Player, payload: any): (ShotPayload?, string?)
	if typeof(payload) ~= "table" or not hasExactPayloadKeys(payload) then
		return nil, "payload_shape"
	end
	if typeof(payload.weaponId) ~= "string" or payload.weaponId ~= Config.Combat.TestWeaponId then
		return nil, "weapon_id"
	end
	if typeof(payload.origin) ~= "Vector3" or not isFiniteVector3(payload.origin) then
		return nil, "origin_type_or_value"
	end
	if typeof(payload.direction) ~= "Vector3" or not isFiniteVector3(payload.direction) then
		return nil, "direction_type_or_value"
	end
	if typeof(payload.targetPosition) ~= "Vector3" or not isFiniteVector3(payload.targetPosition) then
		return nil, "target_type_or_value"
	end

	local directionMagnitude = payload.direction.Magnitude
	if directionMagnitude < 0.99 or directionMagnitude > 1.01 then
		return nil, "direction_not_unit"
	end
	if Config.Combat.MaxRange <= 0 then
		return nil, "weapon_range_invalid"
	end
	local targetOffset = payload.targetPosition - payload.origin
	local targetDistance = targetOffset.Magnitude
	if targetDistance < 0.01 or targetDistance > Config.Combat.MaxRange then
		return nil, "target_out_of_range"
	end
	if payload.direction.Unit:Dot(targetOffset.Unit) < 0.98 then
		return nil, "direction_target_mismatch"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not rootPart or not rootPart:IsA("BasePart")
		or not head or not head:IsA("BasePart") then
		return nil, "character_unavailable"
	end
	if (payload.origin - head.Position).Magnitude > Config.Combat.MaxOriginOffset then
		return nil, "origin_too_far_from_character"
	end

	return {
		weaponId = payload.weaponId,
		origin = payload.origin,
		direction = payload.direction.Unit,
		targetPosition = payload.targetPosition,
		maxRange = Config.Combat.MaxRange,
	}, nil
end

function CombatRequestService.Start()
	if started then
		return
	end
	started = true

	local fireEvent = getOrCreateFireEvent()
	fireEvent.OnServerEvent:Connect(function(player: Player, payload: any, ...: any)
		local now = os.clock()
		local lastRequest = lastRequestAt[player] or -math.huge
		if now - lastRequest < Config.Combat.FireInterval then
			reject(player, "fire_interval")
			return
		end
		lastRequestAt[player] = now

		-- Não ignorar campos/argumentos extras: tentativas de incluir dano/HP também são recusadas.
		if select("#", ...) > 0 then
			reject(player, "extra_arguments")
			return
		end

		local shot, reason = validateShot(player, payload)
		if not shot then
			reject(player, reason or "invalid_request")
			return
		end

		-- Só dados validados seguem para consumidores internos, como a arma da FL-010.
		shotAccepted:Fire(player, shot)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
		lastRejectLogAt[player] = nil
	end)

	print("[Frontline][FL-009] contrato FireWeapon ativo | validação server-side")
end

function CombatRequestService.OnShotAccepted(callback: (Player, ShotPayload) -> ()): RBXScriptConnection
	return shotAccepted.Event:Connect(callback)
end

return CombatRequestService
