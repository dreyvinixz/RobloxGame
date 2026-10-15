--!strict
-- Fonte versionada em src/shared/Config.luau e sincronizada pelo Rojo para ReplicatedStorage.Shared.Config.
-- Configurações públicas; NÃO colocar tokens ou segredos em ReplicatedStorage.
local Config = {
	ProjectName = "Project Frontline",
	SchemaVersion = 1,
	Environment = "development",

	-- FL-008: Constantes do controlador FPS (cliente).
	Player = {
		WalkSpeed = 16,
		SprintSpeed = 26,
		SprintFOVBonus = 10,
		BaseFOV = 70,
	},

	-- FL-009: limites públicos do contrato de disparo.
	Combat = {
		TestWeaponId = "TestRifle",
		FireInterval = 0.12,
		ReloadRequestInterval = 0.25,
		MaxRange = 500,
		MaxOriginOffset = 6,
		RejectLogInterval = 2,
	},

	-- FL-018: regras públicas da partida; pontuação é alterada apenas no servidor.
	Match = {
		ScoreToWin = 5,
		RoundDurationSeconds = 300,
		IntermissionSeconds = 8,
		SpawnProtectionSeconds = 3,
		RespawnSeconds = 5,
	},
}

return table.freeze(Config)
