"""FL-018 source-contract checks (static only; never a substitute for Studio multiplayer QA)."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


class GameModeContractTests(unittest.TestCase):
    def test_server_initialization_order(self):
        bootstrap = read("src/server/Bootstrap.server.luau")
        self.assertLess(bootstrap.index("ArenaBuilder.Build()"), bootstrap.index("GameModeService.Start()"))
        self.assertLess(bootstrap.index("GameModeService.Start()"), bootstrap.index("DamageService.Start("))
        self.assertIn("DamageService.Start(CombatRequestService, GameModeService)", bootstrap)

    def test_damage_service_checks_game_mode_before_take_damage(self):
        damage = read("src/server/DamageService.luau")
        self.assertLess(damage.index("gameModeService.CanDamage(shooter, humanoid)"),
                        damage.index("gameModeService.RecordHit(shooter, humanoid)"))
        self.assertLess(damage.index("gameModeService.RecordHit(shooter, humanoid)"),
                        damage.index("humanoid:TakeDamage(damage)"))

    def test_scores_are_only_updated_by_server_on_death(self):
        source = read("src/server/GameModeService.luau")
        self.assertIn("humanoid.Died:Connect", source)
        self.assertIn('phase ~= "ACTIVE"', source)
        self.assertIn("attacker.Team == player.Team", source)
        self.assertIn("Match.KillCreditSeconds", source)
        self.assertIn("SpawnProtection", source)
        self.assertIn("player.RespawnLocation", source)
        self.assertNotIn("OnServerEvent", source)
        self.assertNotIn("FireServer", source)

    def test_match_config_has_bounded_positive_values(self):
        config = read("src/shared/Config.luau")
        for name in ("MinPlayers", "IntermissionSeconds", "RoundSeconds",
                     "EndSeconds", "ScoreLimit", "RespawnSeconds",
                     "SpawnProtectionSeconds", "KillCreditSeconds"):
            match = re.search(r"\b" + name + r"\s*=\s*(\d+)", config)
            self.assertIsNotNone(match, name)
            self.assertGreater(int(match.group(1)), 0)


if __name__ == "__main__":
    unittest.main()
