--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder          = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatRequestService  = require(script.Parent:WaitForChild("CombatRequestService"))
local DamageService         = require(script.Parent:WaitForChild("DamageService"))

ArenaBuilder.Build()
CombatRequestService.Start()
DamageService.Start(CombatRequestService)
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
-- Arena greybox (FL-007) | contrato de disparo (FL-009) | rifle hitscan (FL-010)
