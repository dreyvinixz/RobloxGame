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
	dropoffStart: number, -- distância em studs onde começa a redução de dano
	dropoffEnd: number, -- distância em studs onde chega ao dano mínimo
	minimumDamage: number, -- HP mínimo por hit antes do multiplicador de headshot
}

local WeaponConfig: { [string]: WeaponDef } = {
	TestRifle = {
		id                = "TestRifle",
		damage            = 25,   -- 4 hits para matar antes do dropoff (100 HP padrão)
		fireInterval      = 0.12, -- 500 RPM
		magazineSize      = 30,
		reloadTime        = 2.2,
		maxRange          = 500,
		headshotMultiplier = 2.0,
		dropoffStart      = 150,
		dropoffEnd        = 500,
		minimumDamage     = 12.5,
	},
	ServicePistol = {
		id                = "ServicePistol",
		damage            = 34, -- 3 hits para matar antes do dropoff
		fireInterval      = 0.28, -- ~214 RPM
		magazineSize      = 12,
		reloadTime        = 1.6,
		maxRange          = 350,
		headshotMultiplier = 1.8,
		dropoffStart      = 80,
		dropoffEnd        = 350,
		minimumDamage     = 17,
	},
}

return table.freeze(WeaponConfig)
