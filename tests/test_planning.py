import sys
from pathlib import Path
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from validate_project import load, validate

class ProjectPlanningTests(unittest.TestCase):
    def test_project_integrity(self):
        self.assertEqual(validate(),[])
    def test_backlog_has_high_priority_vertical_slice(self):
        ids={issue['id'] for issue in load() if issue['priority']=='P0'}
        self.assertTrue({'FL-007','FL-008','FL-009','FL-010','FL-011','FL-012'}.issubset(ids))
    def test_future_rnd_not_in_current_sprints(self):
        rnd=[x for x in load() if x['id']=='FL-028'][0]
        self.assertEqual(rnd['sprint'],'LATER')

if __name__=='__main__':unittest.main()
