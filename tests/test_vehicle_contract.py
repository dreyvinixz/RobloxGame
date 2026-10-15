from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]
SERVER = (ROOT / "src/server/VehicleService.luau").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/client/VehicleController.client.luau").read_text(encoding="utf-8")
CONFIG = (ROOT / "src/shared/Config.luau").read_text(encoding="utf-8")
DAMAGE = (ROOT / "src/server/DamageService.luau").read_text(encoding="utf-8")


class VehicleContractTests(unittest.TestCase):
    """Static contract tests; Studio still has to prove the driving flow."""

    def test_server_vehicle_limits_are_configured(self):
        self.assertRegex(CONFIG, r"MaxSpeed\s*=\s*24")
        self.assertRegex(CONFIG, r"Acceleration\s*=\s*14")
        self.assertRegex(CONFIG, r"InputTimeout\s*=\s*0\.35")
        self.assertRegex(CONFIG, r"BoundaryX\s*=\s*125")
        self.assertRegex(CONFIG, r"BoundaryZ\s*=\s*100")
        self.assertRegex(SERVER, r"dt\s*=\s*math\.clamp\(dt,\s*0,\s*0\.1\)")

    def test_remote_intent_is_authenticated_and_bounded(self):
        self.assertIn("player ~= driver", SERVER)
        self.assertIn('select("#", ...) > 0', SERVER)
        self.assertIn("typeof(value) == \"number\"", SERVER)
        self.assertIn("math.clamp(nextThrottle, -1, 1)", SERVER)
        self.assertIn("math.clamp(nextSteering, -1, 1)", SERVER)
        self.assertIn("vehicleConfig.InputInterval * 0.8", SERVER)

    def test_client_sends_only_controls_not_transforms(self):
        self.assertIn("inputEvent:FireServer(throttle, steering)", CLIENT)
        self.assertNotRegex(CLIENT, r"FireServer\([^\n]*(?:CFrame|Position|PivotTo)")
        self.assertNotIn("PivotTo(", CLIENT)

    def test_server_owns_anchored_movement_and_collision_checks(self):
        self.assertIn("part.Anchored = true", SERVER)
        self.assertIn("currentVehicle:PivotTo(nextPivot)", SERVER)
        self.assertIn("Workspace:Raycast", SERVER)
        self.assertIn("vehicleConfig.BoundaryX", SERVER)
        self.assertIn("vehicleConfig.BoundaryZ", SERVER)

    def test_vehicle_damage_and_reset_are_server_owned(self):
        self.assertIn('SetAttribute("VehicleHealth", vehicleConfig.MaxHealth)', SERVER)
        self.assertIn('SetAttribute("VehicleState", "Destroyed")', SERVER)
        self.assertIn('currentVehicle:GetAttribute("VehicleState") ~= "Active" then return end', SERVER)
        self.assertIn('action ~= "Reset"', SERVER)
        self.assertIn("vehicleConfig.ResetCooldown", SERVER)
        self.assertIn("vehicleConfig.DamageInterval", SERVER)
        self.assertIn("vehicleService.ApplyHit(result.Instance, baseDamage, shooter)", DAMAGE)
        self.assertIn("vehicleServiceArg", DAMAGE)
        self.assertRegex(CONFIG, r"MaxHealth\s*=\s*300")


if __name__ == "__main__":
    unittest.main()
