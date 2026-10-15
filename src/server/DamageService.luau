--!strict
-- DamageService.luau — FL-010 (servidor)
-- Consome shots validados do CombatRequestService e aplica dano autoritativo.
-- NUNCA aceita valores de HP do cliente. Toda a lógica de dano vive aqui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponConfig"))

-- ─── Tipos ────────────────────────────────────────────────────────────────────

-- ShotPayload replicado do CombatRequestService (mesma estrutura)
type ShotPayload = {
	weaponId: string,
	origin: Vector3,
	direction: Vector3,
	targetPosition: Vector3,
	maxRange: number,
}

type HitResult = {
	hit: boolean,
	targetPlayer: Player?,
	isHeadshot: boolean,
	damage: number,
	point: Vector3?,
}

-- ─── Constantes ───────────────────────────────────────────────────────────────

-- Partes consideradas headshot para multiplicação de dano
local HEADSHOT_PARTS = { Head = true }

-- Raycasting: ignorar partes que não são colisão sólida
local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
RAYCAST_PARAMS.FilterDescendantsInstances = {} -- preenchido em Start()

-- ─── Serviço ──────────────────────────────────────────────────────────────────

local DamageService = {}
local started = false

-- Dado o resultado de raycast, descobre se acertou um jogador e qual parte
local function resolveHit(
	shooter: Player,
	rayResult: RaycastResult?,
	weaponId: string
): HitResult

	local weaponDef = WeaponConfig[weaponId]
	if not weaponDef then
		return { hit = false, targetPlayer = nil, isHeadshot = false, damage = 0, point = nil }
	end

	if not rayResult then
		return { hit = false, targetPlayer = nil, isHeadshot = false, damage = 0, point = nil }
	end

	-- Verifica se a instância atingida pertence a um personagem de jogador
	local hitInstance = rayResult.Instance
	local hitModel = hitInstance:FindFirstAncestorOfClass("Model")
	if not hitModel then
		return { hit = false, targetPlayer = nil, isHeadshot = false, damage = 0, point = rayResult.Position }
	end

	local targetPlayer: Player? = nil
	for _, p in Players:GetPlayers() do
		if p ~= shooter and p.Character == hitModel then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then
		-- Acertou geometria do mundo, não um jogador
		return { hit = false, targetPlayer = nil, isHeadshot = false, damage = 0, point = rayResult.Position }
	end

	-- Verifica se o target ainda está vivo
	local targetHumanoid = hitModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return { hit = false, targetPlayer = targetPlayer, isHeadshot = false, damage = 0, point = rayResult.Position }
	end

	local isHeadshot = HEADSHOT_PARTS[hitInstance.Name] == true
	local damage = weaponDef.damage * (if isHeadshot then weaponDef.headshotMultiplier else 1)

	return {
		hit        = true,
		targetPlayer = targetPlayer,
		isHeadshot = isHeadshot,
		damage     = damage,
		point      = rayResult.Position,
	}
end

-- Aplica dano a um Humanoid de forma segura (protegido por pcall)
local function applyDamage(target: Player, damage: number): boolean
	local character = target.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local ok, err = pcall(function()
		humanoid:TakeDamage(damage)
	end)

	if not ok then
		warn("[Frontline][FL-010][DamageService] Erro ao aplicar dano:", err)
		return false
	end
	return true
end

-- Processa um shot validado vindo do CombatRequestService
function DamageService.ProcessShot(shooter: Player, shot: ShotPayload)
	local weaponDef = WeaponConfig[shot.weaponId]
	if not weaponDef then
		warn("[Frontline][FL-010][DamageService] weaponId desconhecido:", shot.weaponId)
		return
	end

	-- Recast autoritativo no servidor — ignora o targetPosition do cliente para dano,
	-- usa apenas origin + direction como vetor. O targetPosition já foi validado
	-- em alcance pelo CombatRequestService, mas o hit real é determinado aqui.
	local rayResult = workspace:Raycast(
		shot.origin,
		shot.direction * shot.maxRange,
		RAYCAST_PARAMS
	)

	local result = resolveHit(shooter, rayResult, shot.weaponId)

	if result.hit and result.targetPlayer and result.damage > 0 then
		local applied = applyDamage(result.targetPlayer, result.damage)
		if applied then
			print(string.format(
				"[Frontline][FL-010] HIT | %s → %s | dmg=%.0f%s",
				shooter.Name,
				result.targetPlayer.Name,
				result.damage,
				if result.isHeadshot then " [HEADSHOT]" else ""
			))
		end
	end
end

function DamageService.Start(combatRequestService: any)
	if started then return end
	started = true

	-- Exclui o chão e partes de spawn do raycast para evitar self-hit em superfícies
	-- A lista real de instâncias a ignorar pode ser estendida via atributo "ArenaRole"
	local toExclude: { Instance } = {}
	for _, desc in workspace:GetDescendants() do
		if desc:IsA("BasePart") and desc:GetAttribute("ArenaRole") == "Ground" then
			table.insert(toExclude, desc)
		end
	end
	-- Spawn locations também são excluídas
	for _, desc in workspace:GetDescendants() do
		if desc:IsA("SpawnLocation") then
			table.insert(toExclude, desc)
		end
	end
	RAYCAST_PARAMS.FilterDescendantsInstances = toExclude

	-- Escuta shots aceitos pelo CombatRequestService
	combatRequestService.OnShotAccepted(function(player: Player, shot: ShotPayload)
		DamageService.ProcessShot(player, shot)
	end)

	print("[Frontline][FL-010] DamageService ativo | arma TestRifle configurada")
end

return DamageService
