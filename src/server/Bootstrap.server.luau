--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local CombatRequestService = require(script.Parent:WaitForChild("CombatRequestService"))

ArenaBuilder.Build()
CombatRequestService.Start()
print("[Frontline][server] bootstrap ok | " .. Config.ProjectName)
-- A arena greybox é criada pelo servidor quando ainda não existe no Workspace.
