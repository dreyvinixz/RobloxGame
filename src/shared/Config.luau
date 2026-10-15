--!strict
-- Fonte versionada em src/shared/Config.luau e sincronizada pelo Rojo para ReplicatedStorage.Shared.Config.
-- Configurações públicas; NÃO colocar tokens ou segredos em ReplicatedStorage.
local Config = {
    ProjectName = "Project Frontline",
    SchemaVersion = 1,
    Environment = "development",

    -- FL-009: limites públicos do primeiro contrato de disparo.
    -- O servidor usa estes valores para validar; o cliente não decide dano.
    Combat = {
        TestWeaponId = "TestRifle",
        FireInterval = 0.12,
        MaxRange = 500,
        MaxOriginOffset = 6,
        RejectLogInterval = 2,
    },
}

return table.freeze(Config)
