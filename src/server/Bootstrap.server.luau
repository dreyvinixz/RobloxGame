--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local TrainingTargetService = require(script.Parent:WaitForChild("TrainingTargetService"))
local CombatRequestService = require(script.Parent:WaitForChild("CombatRequestService"))
local DamageService = require(script.Parent:WaitForChild("DamageService"))
local ViewmodelAssetService = require(script.Parent:WaitForChild("ViewmodelAssetService"))

ArenaBuilder.Build()
TrainingTargetService.Start()
CombatRequestService.Start()
DamageService.Start(CombatRequestService)
ViewmodelAssetService.Start()

-- Arena greybox (FL-007) | contrato de disparo (FL-009) | rifle (FL-010) | alvo (FL-011)
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
