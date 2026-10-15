--!strict
-- Nomes compartilhados do contrato de rede. Payloads são validados no servidor.
local NetProtocol = {
	Version = 1,
	RemoteFolderName = "Remotes",
	FireWeaponEvent = "FireWeapon",
}

return table.freeze(NetProtocol)
