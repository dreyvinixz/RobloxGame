--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatRequestService = require(script.Parent:WaitForChild("CombatRequestService"))

ArenaBuilder.Build()
CombatRequestService.Start()
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
-- Arena greybox criada pelo servidor (FL-007); contrato de disparo ativo (FL-009).
