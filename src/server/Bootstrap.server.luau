--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatRequestService = require(script.Parent:WaitForChild("CombatRequestService"))
local DamageService = require(script.Parent:WaitForChild("DamageService"))
local GameModeService = require(script.Parent:WaitForChild("GameModeService"))

ArenaBuilder.Build()
GameModeService.Start()
CombatRequestService.Start()
DamageService.Start(CombatRequestService, GameModeService)

-- FL-007 arena | FL-009 remotes | FL-010 rifle | FL-018 teams/rounds
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
