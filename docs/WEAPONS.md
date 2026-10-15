# Initial weapon tuning — FL-020

These are prototype tuning values, not a claim of final balance. Server-side `WeaponConfig` is authoritative for damage, cadence, range, magazines, and reload time. `DamageService` applies linear damage falloff between the configured start and end distances; headshot multiplier applies after falloff.

| Weapon | Body damage | Head multiplier | Fire interval | Magazine | Reload | Max range | Falloff start → end | Minimum damage |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| TestRifle | 25 | 2.0× | 0.12 s (500 RPM) | 30 | 2.2 s | 500 studs | 150 → 500 studs | 12.5 |
| ServicePistol | 34 | 1.8× | 0.28 s (~214 RPM) | 12 | 1.6 s | 350 studs | 80 → 350 studs | 17 |

For a 100 HP body target at point-blank range and ideal cadence, rifle time-to-kill is four hits over three intervals (**0.36 s**); pistol time-to-kill is three hits over two intervals (**0.56 s**). These are arithmetic expectations from the current config, not measured latency-inclusive times. At max range, rifle needs eight body hits (0.84 s from first to eighth shot); pistol needs six (1.40 s). No reload is included.

Players start with `TestRifle`; keys **1** and **2** request rifle and pistol. The server accepts only IDs in `WeaponConfig`, rate-limits equip requests, validates shots against the server-held equipped weapon, and keeps ammunition/reload state per weapon. Switching does not refill a magazine. Reload uses the currently equipped weapon.

## Verification status

The config-derived time-to-kill values are documented above. Two-client Studio verification of equip, separate ammo/reload state, damage falloff, and measured kill times is required before calling these values balanced.
