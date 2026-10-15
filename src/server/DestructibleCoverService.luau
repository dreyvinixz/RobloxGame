--!strict
-- FL-021: vida, estado, visual e colisão da cobertura são alterados no servidor.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local DestructibleCoverService = {}
local started = false

local function setState(core: BasePart, state: string, health: number)
	core:SetAttribute("CoverHealth", health)
	core:SetAttribute("CoverState", state)
	if state == "Intact" then
		core.Color = Color3.fromRGB(104, 101, 92)
		core.Transparency = 0
		core.CanCollide = true
		core.CanQuery = true
	elseif state == "Damaged" then
		core.Color = Color3.fromRGB(135, 93, 74)
		core.Transparency = 0
		core.CanCollide = true
		core.CanQuery = true
		local armor = core.Parent and core.Parent:FindFirstChild("ArmorModules")
		if armor then
			for _, panel in armor:GetChildren() do
				if panel:IsA("BasePart") then panel.Color = Color3.fromRGB(135, 93, 74) end
			end
		end
	else
		core.Transparency = 1
		core.CanCollide = false
		core.CanQuery = false
		local cover = core.Parent
		local armor = cover and cover:FindFirstChild("ArmorModules")
		if armor then
			for _, panel in armor:GetChildren() do
				if panel:IsA("BasePart") then
					panel.Transparency = 1
					panel.CanCollide = false
					panel.CanQuery = false
				end
			end
		end
	end
end

function DestructibleCoverService.Start(arena: Model)
	if started then return end
	started = true
	for _, instance in arena:GetDescendants() do
		if instance:IsA("BasePart") and instance:GetAttribute("ArenaRole") == "CoverCore" then
			instance:SetAttribute("DestructibleCover", true)
			instance:SetAttribute("CoverMaxHealth", Config.Destruction.CoverMaxHealth)
			setState(instance, "Intact", Config.Destruction.CoverMaxHealth)
		end
	end
	print("[Frontline][FL-021] cobertura destrutível ativa")
end

function DestructibleCoverService.ApplyHit(instance: Instance, damage: number): boolean
	if not started or not instance:IsA("BasePart") or instance:GetAttribute("DestructibleCover") ~= true then
		return false
	end
	local state = instance:GetAttribute("CoverState")
	local health = instance:GetAttribute("CoverHealth")
	if typeof(health) ~= "number" or health <= 0 or state == "Destroyed" or damage <= 0 then
		return true
	end
	local nextHealth = math.max(0, health - damage)
	if nextHealth <= 0 then
		setState(instance, "Destroyed", 0)
	elseif nextHealth <= (instance:GetAttribute("CoverMaxHealth") :: number) / 2 then
		setState(instance, "Damaged", nextHealth)
	else
		instance:SetAttribute("CoverHealth", nextHealth)
	end
	return true
end

return DestructibleCoverService
