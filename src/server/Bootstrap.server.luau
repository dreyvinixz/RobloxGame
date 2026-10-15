--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CombatRequestService = require(script.Parent:WaitForChild("CombatRequestService"))

CombatRequestService.Start()
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
-- S0: teste de sincronização apenas. Não há lógica de combate aqui.
