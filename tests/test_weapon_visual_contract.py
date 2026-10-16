from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
VIEWMODEL = (ROOT / "src/client/FirstPersonViewmodel.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/client/WeaponController.client.luau").read_text(encoding="utf-8")
COMBAT = (ROOT / "src/server/CombatRequestService.luau").read_text(encoding="utf-8")
DAMAGE = (ROOT / "src/server/DamageService.luau").read_text(encoding="utf-8")


class WeaponVisualContractTests(unittest.TestCase):
    """Static contracts for cosmetics; Studio still has to prove the visual result."""

    def test_weapon_switch_selects_a_dedicated_pistol_viewmodel(self):
        self.assertIn("createProceduralPistol", VIEWMODEL)
        self.assertIn('if weaponId == "ServicePistol" then', VIEWMODEL)
        self.assertIn("viewmodel:SetWeapon(serverWeaponId)", CLIENT)
        self.assertIn(
            'return if weaponId == "ServicePistol" then PISTOL_OFFSET else RIFLE_OFFSET',
            VIEWMODEL,
        )

    def test_shot_spawns_bullet_trail_and_short_lived_casing(self):
        self.assertIn('body.Name = "Jacket"', VIEWMODEL)
        self.assertIn('tip.Name = "ProjectileTip"', VIEWMODEL)
        self.assertIn("trail.Name = \"BulletTrail\"", VIEWMODEL)
        self.assertIn("spawnBullet(effectsFolder, muzzlePosition, targetPosition, self.weaponId)", VIEWMODEL)
        self.assertIn("spawnCasing(effectsFolder, ejectPosition, right, up, self.weaponId)", VIEWMODEL)
        self.assertIn("Debris:AddItem(casing, 2.5)", VIEWMODEL)

    def test_cosmetics_do_not_change_server_hit_authority(self):
        self.assertIn("fireWeaponEvent:FireServer({", CLIENT)
        self.assertNotIn("TakeDamage", CLIENT)
        self.assertIn("shotAccepted:Fire(player, shot)", COMBAT)
        self.assertIn("workspace:Raycast(shot.origin, shot.direction * shot.maxRange, params)", DAMAGE)
        self.assertIn("humanoid:TakeDamage(damage)", DAMAGE)


if __name__ == "__main__":
    unittest.main()
