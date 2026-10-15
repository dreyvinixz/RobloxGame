--!strict
-- Bootstrap.client.luau — ponto de entrada do cliente (S0/S1)
-- FL-008: PlayerController.client.luau é carregado automaticamente pelo Roblox
-- como LocalScript independente (mesmo diretório). Não é necessário require() aqui.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
print("[Frontline][client] bootstrap ok | " .. Config.ProjectName
	.. " | schema=" .. Config.SchemaVersion)
-- Adicione aqui apenas inicializações de sistemas globais do cliente (FL-009+).
