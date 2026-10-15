--!strict
-- FL-015: publica somente o clone visual auditado para o cliente local.
-- O WeaponsSystem importado permanece em ServerStorage e nunca é replicado.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ViewmodelAssetService = {}
local started = false

local function isSafeVisual(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BaseScript")
			or descendant:IsA("RemoteEvent")
			or descendant:IsA("RemoteFunction")
			or descendant:IsA("Sound") then
			return false
		end
	end
	return true
end

function ViewmodelAssetService.Start()
	if started then
		return
	end
	started = true

	local quarantine = ServerStorage:FindFirstChild("FL014_Quarantine")
	local candidate = quarantine and quarantine:FindFirstChild("FL014_RifleVisual_Candidate")
	if not candidate or not candidate:IsA("Model") or not isSafeVisual(candidate) then
		warn("[Frontline][FL-015] rifle visual ausente ou rejeitado; cliente usará o modelo procedural")
		return
	end

	local assets = ReplicatedStorage:FindFirstChild("FrontlineAssets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "FrontlineAssets"
		assets.Parent = ReplicatedStorage
	end

	local existing = assets:FindFirstChild("TestRifleVisual")
	if existing then
		if existing:IsA("Model") and isSafeVisual(existing) then
			return
		end
		existing:Destroy()
	end

	local visual = candidate:Clone()
	visual.Name = "TestRifleVisual"
	local rifleRoot = visual:FindFirstChild("Rifle", true)
	if rifleRoot and rifleRoot:IsA("BasePart") then
		visual.PrimaryPart = rifleRoot
	end
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
		end
	end
	visual.Parent = assets
	print("[Frontline][FL-015] clone visual limpo do rifle replicado para o viewmodel")
end

return ViewmodelAssetService
