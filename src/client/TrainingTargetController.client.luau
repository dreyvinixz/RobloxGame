--!strict
-- FL-011: tecla T reinicia o dummy eliminado no servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local NetProtocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NetProtocol"))
local remotes = ReplicatedStorage:WaitForChild(NetProtocol.RemoteFolderName)
local resetEvent = remotes:WaitForChild(NetProtocol.ResetTrainingTargetEvent) :: RemoteEvent

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.T then return end
	resetEvent:FireServer()
end)

print("[Frontline][FL-011] controle do alvo ativo | T reinicia o dummy eliminado")
