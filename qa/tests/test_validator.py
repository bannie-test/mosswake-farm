"""Negative tests: the validator must catch each kind of broken data (GDD section 18, rule 3)."""
import copy
import json
import os
import shutil
import sys
import tempfile
import unittest

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.join(ROOT, "tools"))
import validate_data  # noqa: E402


def run_with(mutate):
    tmp = tempfile.mkdtemp()
    try:
        dst = os.path.join(tmp, "data")
        shutil.copytree(os.path.join(ROOT, "data"), dst)
        mutate(dst)
        return validate_data.run(dst)[1]
    finally:
        shutil.rmtree(tmp)


def edit(name, fn):
    def mutate(dst):
        path = os.path.join(dst, name)
        with open(path) as f:
            d = json.load(f)
        fn(d)
        with open(path, "w") as f:
            json.dump(d, f)
    return mutate


def by_id(rows, i):
    return next(r for r in rows if r["id"] == i)


class ValidatorTests(unittest.TestCase):
    def test_shipped_data_passes(self):
        results = run_with(lambda dst: None)
        self.assertEqual(sorted(results), sorted(validate_data.CHECKS))
        for name, errs in results.items():
            self.assertEqual(errs, [], name)

    def test_mvp_counts(self):
        d = validate_data.Data(os.path.join(ROOT, "data"))
        self.assertEqual(len(d.items), 55)       # 32 of the first MVP + 23 of Revision 2 (section 21.8)
        self.assertEqual(len(d.plants), 5)
        self.assertEqual(len(d.animals), 3)
        self.assertEqual(len(d.merges), 10)
        self.assertEqual(len(d.npcs), 3)
        self.assertEqual(len(d.quests), 6)
        goods = [i for i in d.items.values() if i["sellable"]]
        self.assertEqual(len(goods), 23)         # section 21.8: 18 + Wild Flower + 4 fish
        self.assertEqual(len(d.tools), 7)
        self.assertEqual(len(d.nodes), 7)
        self.assertEqual(len(d.weather), 5)

    def test_schema_catches_bad_field(self):
        r = run_with(edit("plants.json", lambda d: d[0].update(growthHours=-1)))
        self.assertTrue(r["schema"])

    def test_schema_catches_unknown_field(self):
        r = run_with(edit("items.json", lambda d: d[0].update(colour="red")))
        self.assertTrue(r["schema"])

    def test_unregistered_id(self):
        def add(d):
            x = copy.deepcopy(d[0]); x["id"] = "crop_turnip"; d.append(x)
        self.assertTrue(run_with(edit("items.json", add))["registry"])

    def test_missing_reference(self):
        r = run_with(edit("merge_recipes.json", lambda d: d[0]["inputs"][0].update(itemId="crop_parsnip")))
        self.assertTrue(r["references"])

    def test_merged_value_off_formula(self):
        r = run_with(edit("items.json", lambda d: by_id(d, "merged_carrot_golden").update(baseValue=400)))
        self.assertTrue(any("merge_carrot_golden" in e for e in r["formulas"]))

    def test_crop_value_off_formula(self):
        r = run_with(edit("items.json", lambda d: by_id(d, "crop_carrot").update(baseValue=20)))
        self.assertTrue(any("crop_carrot" in e for e in r["formulas"]))

    def test_buy_and_resell_exploit(self):
        def cheap(d):
            by_id(d, "lucky_clover").update(sellable=True, baseValue=60)
        self.assertTrue(run_with(edit("items.json", cheap))["exploit"])

    def test_unreachable_unlock(self):
        r = run_with(edit("plants.json", lambda d: by_id(d, "plant_sunflower")["unlock"].update(playerLevel=99)))
        joined = " ".join(r["reachability"])
        self.assertIn("plant_sunflower", joined)
        self.assertIn("quest_first_vocation", joined)   # no Sun Bouquet, no Revival Potion, no spirit

    def test_node_without_a_tool(self):
        r = run_with(edit("tools.json", lambda d: d.remove(by_id(d, "tool_pickaxe"))))
        self.assertTrue(r["references"] or r["registry"])

    def test_weather_chances_must_sum_to_one(self):
        r = run_with(edit("weather.json", lambda d: by_id(d, "weather_rain").update(chance=0.5)))
        self.assertTrue(any("weather" in e for e in r["formulas"]))

    def test_item_only_a_missing_tool_could_yield(self):
        r = run_with(edit("config.json", lambda d: d["newGame"]["tools"].remove("tool_rod")))
        self.assertTrue(any("fish_moonscale" in e for e in r["reachability"]))

    def test_forward_pointing_quest(self):
        r = run_with(edit("quests.json", lambda d: by_id(d, "quest_strange_carrot")["requires"].update(quest="quest_sleeper")))
        self.assertTrue(any("quest_strange_carrot" in e for e in r["reachability"]))


if __name__ == "__main__":
    unittest.main()
