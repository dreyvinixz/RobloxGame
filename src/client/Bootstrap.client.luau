--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
print("[Frontline][client] bootstrap ok | " .. Config.ProjectName)
-- S0: teste de sincronização apenas. Gameplay começa na Sprint 1.
