--!strict
-- Nomes compartilhados do contrato de rede. Payloads são validados no servidor.
local NetProtocol = {
	Version = 1,
	RemoteFolderName = "Remotes",
	FireWeaponEvent = "FireWeapon",
	ReloadWeaponEvent = "ReloadWeapon",
	WeaponStateEvent = "WeaponState",
	EquipWeaponEvent = "EquipWeapon",
	HitConfirmedEvent = "HitConfirmed",
	ResetTrainingTargetEvent = "ResetTrainingTarget",
	VehicleActionEvent = "VehicleAction",
	VehicleInputEvent = "VehicleInput",
	VehicleStateEvent = "VehicleState",
	EliminationEvent = "Elimination",
}

return table.freeze(NetProtocol)
