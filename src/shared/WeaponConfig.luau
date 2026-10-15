--!strict
-- WeaponConfig.luau — FL-010
-- Configurações das armas. Compartilhado; NÃO colocar segredos aqui.
-- O servidor usa estes valores como fonte de verdade para validação de dano.
-- O cliente usa apenas para UI/feedback visual.

export type WeaponDef = {
	id: string,
	damage: number,         -- HP removido por hit confirmado no servidor
	fireInterval: number,   -- segundos entre disparos (cadência)
	magazineSize: number,   -- balas por magazine
	reloadTime: number,     -- segundos para recarregar
	maxRange: number,       -- studs — igual ao Config.Combat.MaxRange por enquanto
	headshotMultiplier: number, -- multiplicador de dano em headshot
}

local WeaponConfig: { [string]: WeaponDef } = {
	TestRifle = {
		id                = "TestRifle",
		damage            = 25,   -- 4 hits para matar (100 HP padrão)
		fireInterval      = 0.12, -- ~500 RPM — deve coincidir com Config.Combat.FireInterval
		magazineSize      = 30,
		reloadTime        = 2.2,
		maxRange          = 500,
		headshotMultiplier = 2.0,
	},
}

return table.freeze(WeaponConfig)
