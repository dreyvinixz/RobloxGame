--!strict
-- Fonte versionada em src/shared/Config.luau e sincronizada pelo Rojo para ReplicatedStorage.Shared.Config.
-- Configurações públicas; NÃO colocar tokens ou segredos em ReplicatedStorage.
local Config = {
	ProjectName = "Project Frontline",
	SchemaVersion = 1,
	Environment = "development",

	-- FL-008: Constantes do controlador FPS (cliente).
	-- WalkSpeed e SprintSpeed são aplicados LOCALMENTE para sensação imediata;
	-- o servidor NÃO valida velocidade no MVP (autoridade de dano/HP é FL-009).
	Player = {
		WalkSpeed        = 16,   -- studs/s — padrão Roblox
		SprintSpeed      = 26,   -- studs/s — sprint visual, sem alterar autoridade
		SprintFOVBonus   = 10,   -- graus adicionais de FOV durante sprint (efeito visual)
		BaseFOV          = 70,   -- FOV padrão em graus
	},
}

return table.freeze(Config)
