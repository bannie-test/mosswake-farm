#!/usr/bin/env python3
"""Mosswake Farm data validator (GDD sections 10, 11, 13, 14, 18).

Checks, in order:
  1. schema        every definition validates against its JSON Schema
  2. registry      every ID is registered in data/id_registry.json, and vice versa
  3. references    every ID referenced by any definition exists
  4. formulas      merged values, crop values and seed prices follow section 10
  5. exploit       nothing bought in a shop can be resold (or merged and resold) at a profit
  6. reachability  every definition can be reached from a new save

Exit code 0 only when all checks pass.  Usage: python3 tools/validate_data.py [--data DIR]
"""
import argparse
import json
import os
import re
import sys

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

ID_PREFIXES = ("seed", "crop", "prod", "merged", "food", "gene", "lucky", "mat", "spirit", "embryo",
               "quest", "tool", "special", "plant", "animal", "trait", "merge", "bp", "breed", "npc",
               "job", "bld", "craft", "site", "shop", "feature", "perk")
ID_RE = re.compile(r"^(%s)_[a-z0-9]+(_[a-z0-9]+)*$" % "|".join(ID_PREFIXES))
# string fields that are not ID references
NON_REF_KEYS = {"name", "icon", "sprite", "scene", "dialogue", "portrait", "text", "role", "species",
                "action", "priority", "resource", "refillAt", "stat", "target", "event", "category",
                "storage", "rarity", "placement", "kind", "favouredSeason", "targetType", "state",
                "questState", "tag", "slot", "type", "perk"}
NON_REF_PARENTS = {"tags", "likes", "appliesTo", "huskCondition"}


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


class Data:
    def __init__(self, root):
        self.root = root
        self.schemas = {}
        for fn in sorted(os.listdir(os.path.join(root, "schema"))):
            sch = load(os.path.join(root, "schema", fn))
            self.schemas[sch["title"]] = sch
        self.tables = {}  # type name -> list of definitions
        for name, sch in self.schemas.items():
            if sch.get("x-file"):
                self.tables[name] = load(os.path.join(root, sch["x-file"]))
        self.config = load(os.path.join(root, "config.json"))
        self.merge_config = load(os.path.join(root, "merge_config.json"))["mergeConfig"]
        self.registry = load(os.path.join(root, "id_registry.json"))
        t = self.tables
        self.items = {d["id"]: d for d in t["ItemDefinition"]}
        self.plants = {d["id"]: d for d in t["CropDefinition"]}
        self.animals = {d["id"]: d for d in t["AnimalDefinition"]}
        self.merges = {d["id"]: d for d in t["MergeRecipe"]}
        self.crafts = {d["id"]: d for d in t["CraftRecipe"]}
        self.blueprints = {d["id"]: d for d in t["ResearchRecipe"]}
        self.quests = {d["id"]: d for d in t["QuestDefinition"]}
        self.npcs = {d["id"]: d for d in t["NPCDefinition"]}
        self.spirits = {d["id"]: d for d in t["TreeSpiritDefinition"]}
        self.buildings = {d["id"]: d for d in t["BuildingDefinition"]}
        self.sites = {d["id"]: d for d in t["DigSiteDefinition"]}
        self.shop = {e["id"]: dict(e, npcId=n["id"]) for n in t["NPCDefinition"] for e in n.get("shop", [])}

    def defined_ids(self):
        ids = {}
        for name, rows in self.tables.items():
            for d in rows:
                ids.setdefault(d["id"], []).append(name)
        for sid in self.shop:
            ids.setdefault(sid, []).append("ShopEntry")
        return ids


# ---------------------------------------------------------------- 1. schema
def check_schema(data, errors):
    resources = [(s["$id"].split("/")[-1], Resource.from_contents(s)) for s in data.schemas.values()]
    resources += [(s["$id"], Resource.from_contents(s)) for s in data.schemas.values()]
    registry = Registry().with_resources(resources)
    for name, rows in data.tables.items():
        v = Draft202012Validator(data.schemas[name], registry=registry)
        if not isinstance(rows, list):
            errors.append(f"schema: {name}: file must hold a list")
            continue
        for d in rows:
            for e in v.iter_errors(d):
                errors.append(f"schema: {name} {d.get('id', '?')}: {'/'.join(map(str, e.path))}: {e.message}")
    # runtime fixtures (the GDD's own examples) must validate against the runtime schemas
    fx_dir = os.path.join(os.path.dirname(data.root.rstrip("/")) or ".", "qa", "fixtures")
    if os.path.isdir(fx_dir):
        for fn in sorted(os.listdir(fx_dir)):
            name = fn.split(".")[0]
            if name in data.schemas:
                v = Draft202012Validator(data.schemas[name], registry=registry)
                for e in v.iter_errors(load(os.path.join(fx_dir, fn))):
                    errors.append(f"schema: fixture {fn}: {'/'.join(map(str, e.path))}: {e.message}")


# ---------------------------------------------------------------- 2. registry
def check_registry(data, errors):
    defined = data.defined_ids()
    for i, names in defined.items():
        # a Gene Fragment item and its GeneDefinition share one ID by design (section 14)
        if len(names) > 1 and sorted(names) != ["GeneDefinition", "ItemDefinition"]:
            errors.append(f"registry: duplicate ID {i} in {names}")
        if not ID_RE.match(i):
            errors.append(f"registry: malformed ID {i}")
    reg = {r["id"]: r for r in data.registry["ids"]}
    if len(reg) != len(data.registry["ids"]):
        errors.append("registry: id_registry.json holds a duplicate row")
    for i in defined:
        if i not in reg:
            errors.append(f"registry: {i} is used but not registered")
    for i, r in reg.items():
        if r["status"] == "active" and r["type"] not in ("feature", "perk") and i not in defined:
            errors.append(f"registry: {i} is registered as active but has no definition")
    return set(reg)


# ---------------------------------------------------------------- 3. references
def walk_refs(node, key=None, parent=None, path=""):
    if isinstance(node, dict):
        for k, v in node.items():
            yield from walk_refs(v, k, key, f"{path}/{k}")
            if key in ("reputation", "timesProduced", "mergePity", "mergeMastery") and ID_RE.match(k):
                yield k, f"{path}/{k}"
    elif isinstance(node, list):
        for n, v in enumerate(node):
            yield from walk_refs(v, key, parent, f"{path}/{n}")
    elif isinstance(node, str):
        if key in NON_REF_KEYS or key in NON_REF_PARENTS or key == "id":
            return
        if ID_RE.match(node):
            yield node, path


def check_references(data, known, errors):
    for name, rows in data.tables.items():
        for d in rows:
            for ref, path in walk_refs(d):
                if ref not in known:
                    errors.append(f"reference: {name} {d['id']}{path} -> unknown ID {ref}")
    for ref, path in walk_refs(data.config):
        if ref not in known:
            errors.append(f"reference: config{path} -> unknown ID {ref}")
    strings = load(os.path.join(data.root, "strings_en.json"))
    for q in data.quests.values():
        name_key = "quest.%s.name" % q["id"][len("quest_"):]
        for key in [name_key] + [st["text"] for st in q["steps"]]:
            if key not in strings:
                errors.append(f"reference: {q['id']} uses text key {key}, which is not in strings_en.json")
    for p in data.plants.values():
        if data.items[p["productItemId"]]["rarity"] != p["rarity"]:
            errors.append(f"reference: {p['id']} rarity differs from its product item")


# ---------------------------------------------------------------- 4. formulas
def check_formulas(data, errors):
    eco = data.config["economy"]
    tol = eco["valueTolerance"]
    k = data.merge_config["valueFactor"]
    for r in data.merges.values():
        ing = sum(data.items[i["itemId"]]["baseValue"] * i["qty"] for i in r["inputs"])
        want = k[r["rarity"]] * ing / r["output"]["qty"]
        got = data.items[r["output"]["itemId"]]["baseValue"]
        if abs(got - want) > max(1.0, tol * want):
            errors.append(f"formula: {r['id']} output value {got} but k x inputs = {want:.1f}")
        if got <= ing / r["output"]["qty"]:
            errors.append(f"formula: {r['id']} output is not worth more than its inputs")
    shop_price = {e["itemId"]: e["price"] for e in data.shop.values() if "itemId" in e}
    for p in data.plants.values():
        seed = data.items[p["seedItemId"]]
        prod = data.items[p["productItemId"]]
        if p["seedItemId"] in shop_price:
            if shop_price[p["seedItemId"]] != seed["baseValue"]:
                errors.append(f"formula: {seed['id']} shop price differs from its base value")
            harvests = p["regrow"]["maxHarvests"] if p["regrow"] else 1
            hours = p["growthHours"] + (p["regrow"]["hours"] * (harvests - 1) if p["regrow"] else 0)
            total_yield = p["yield"]["min"] * harvests
            want = (eco["cphByRarity"][p["rarity"]] * hours + seed["baseValue"]) / total_yield
            if abs(prod["baseValue"] - want) > max(0.5, tol * want):
                errors.append(f"formula: {prod['id']} value {prod['baseValue']} but crop formula gives {want:.2f}")
        if p["xpPerUnit"] != eco["rarityRank"][p["rarity"]]:
            errors.append(f"formula: {p['id']} xpPerUnit must equal its rarity rank")
    for bp in data.blueprints.values():
        c = bp["creation"]
        cost = c["coins"] + sum(data.items[i["itemId"]]["baseValue"] * i["qty"] for i in c["inputs"])
        seed = data.items[c["output"]["itemId"]]
        if abs(seed["baseValue"] - cost / c["output"]["qty"]) > 1:
            errors.append(f"formula: {seed['id']} value {seed['baseValue']} but creation cost per seed is {cost / c['output']['qty']:.1f}")
    for n in data.npcs.values():
        if n["reputationThresholds"] != sorted(n["reputationThresholds"]):
            errors.append(f"formula: {n['id']} reputation thresholds are not ascending")


# ---------------------------------------------------------------- 5. exploit
def check_exploit(data, errors):
    """Section 10: nothing sold in a shop can be resold, or merged and resold, for more than it
    cost unless it passes through a plot or animal timer."""
    best_rate = max(data.config["economy"]["saleRate"].values())
    cost = {e["itemId"]: e["price"] for e in data.shop.values() if "itemId" in e}
    fee = data.merge_config["feeRatio"]
    changed = True
    while changed:  # close over timer-free conversions: merges and hand crafts
        changed = False
        for r in list(data.merges.values()) + list(data.crafts.values()):
            ins = r["inputs"]
            if not all("itemId" in i and i["itemId"] in cost for i in ins):
                continue
            out = r["output"]
            total = sum(cost[i["itemId"]] * i["qty"] for i in ins) + r.get("coins", 0)
            if r["id"].startswith("merge_"):
                total += fee * data.items[out["itemId"]]["baseValue"]
            unit = total / out["qty"]
            if unit < cost.get(out["itemId"], float("inf")) - 1e-9:
                cost[out["itemId"]] = unit
                changed = True
    for item_id, c in cost.items():
        it = data.items[item_id]
        if it["sellable"] and it["baseValue"] * best_rate > c + 1e-9:
            errors.append(f"exploit: {item_id} costs {c:.1f} without a timer but sells for up to {it['baseValue'] * best_rate:.1f}")


# ---------------------------------------------------------------- 6. reachability
def check_reachability(data, errors):
    cfg = data.config
    max_level = cfg["economy"]["levelCurve"]["maxLevel"]
    max_rep = cfg["reputation"]["maxLevelMvp"]
    have = set(i["itemId"] for i in cfg["newGame"]["items"])        # obtainable items
    done = set(cfg["newGame"]["buildings"])                         # reachable definitions / flags
    done |= set(a["animalId"] for a in cfg["newGame"]["animals"])
    started = set()
    granted = set()                                                  # unlocked through rewards

    def researchable():
        return {i for i in have if data.items[i]["research"]} if "bld_research_station" in done else set()

    def level_ok(n):
        return n == 1 or (n <= max_level and any(p in done for p in data.plants))

    def rep_ok(npc, level):
        if npc not in done or level > max_rep:
            return False
        n = data.npcs[npc]
        wanted = any(set(data.items[i]["tags"]) & set(n["orderRules"]["tags"]) and data.items[i]["tier"] <= cfg["orders"]["deliveryMaxTier"]
                     and data.items[i]["sellable"] for i in have)
        return wanted or any(q["giver"] == npc and qid in done for qid, q in data.quests.items())

    def sat(u):
        for key, v in u.items():
            if key == "start" and not v: return False
            if key == "playerLevel" and not level_ok(v): return False
            if key == "quest":
                pool = started if u.get("questState") == "started" else done
                if v not in pool: return False
            if key == "building" and v not in done: return False
            if key == "firstResearchOf" and v not in researchable(): return False
            if key == "blueprint" and v not in done: return False
            if key == "researchLevel" and v > 1 and not any(data.items[i]["research"]["geneId"] for i in researchable()): return False
            if key == "npcReputation" and not rep_ok(v["npcId"], v["level"]): return False
            if key == "npcMet" and not all(n in done for n in v): return False
        return True

    def inputs_ok(inputs):
        for i in inputs:
            if "itemId" in i:
                if i["itemId"] not in have: return False
            elif not any(i["tag"] in data.items[x]["tags"] and data.items[x]["rarity"] == i.get("rarity", data.items[x]["rarity"]) for x in have):
                return False
        return True

    def step_ok(s):
        t = s["type"]
        if t in ("deliver", "produce"): return s["itemId"] in have
        if t == "build": return s["buildingId"] in done
        if t == "research": return len(researchable()) >= s["qty"]
        if t == "reach": return s.get("itemId") in have
        if t == "interact":
            if s["target"] == "clean_husk": return "spirit_husk_dormant" in have
            if s["target"] == "revive_husk": return "spirit_revival_potion" in have
            if s["target"] == "awaken_spirit":
                sp = data.spirits[s["spiritId"]]
                return s["spiritId"] in done and inputs_ok(sp["charmRecipe"]["inputs"])
        return False

    while True:
        before = (len(have), len(done), len(started), len(granted))
        for nid, n in data.npcs.items():
            if sat(n["appears"]): done.add(nid)
            for rw in n["reputationRewards"]:
                if rep_ok(nid, rw["level"]): granted.update(rw["unlocks"])
        for sid, e in data.shop.items():
            if e["npcId"] in done and (sat(e["unlock"]) or sid in granted):
                done.add(sid)
                if "itemId" in e: have.add(e["itemId"])
                elif data.animals[e["animalId"]]["housing"] in done: done.add(e["animalId"])
        for table in (data.buildings, data.plants, data.spirits, data.sites):
            for did, d in table.items():
                if sat(d["unlock"]) or did in granted: done.add(did)
        for aid, a in data.animals.items():
            if aid in done and (a["feed"] is None or a["feed"]["itemId"] in have):
                have.add(a["renewable"]["itemId"])
        for pid, p in data.plants.items():
            if pid in done and p["seedItemId"] in have: have.add(p["productItemId"])
        for rid, r in list(data.merges.items()) + list(data.crafts.items()):
            if (sat(r["unlock"]) or rid in granted) and (r["station"] is None or r["station"] in done):
                done.add(rid)
                if inputs_ok(r["inputs"]):
                    have.add(r["output"]["itemId"])
                    if r.get("rarity", "basic") != "basic": have.add("mat_stardust")
        for i in researchable():
            r = data.items[i]["research"]
            if r["stardust"] > 0: have.add("mat_stardust")
            if r["geneId"] and r["fragments"] > 0: have.add(r["geneId"])
        for bid, bp in data.blueprints.items():
            if sat(bp["unlock"]) and all(f["geneId"] in have for f in bp["fragmentCost"]):
                done.add(bid)
                if bp["creation"]["station"] in done and inputs_ok(bp["creation"]["inputs"]):
                    have.add(bp["creation"]["output"]["itemId"])
        for sid, site in data.sites.items():
            if sid in done and "tool_dig_kit" in have:
                have.add("spirit_husk_dormant")
                have.update(l["itemId"] for l in site["guaranteedLoot"])
        for qid, q in data.quests.items():
            if q["giver"] in done and sat(q["requires"]):
                started.add(qid)
                ok = True
                for s in q["steps"]:
                    if not step_ok(s):
                        ok = False
                        break
                    have.update(g["itemId"] for g in s.get("grants", []))
                if ok:
                    done.add(qid)
                    granted.update(q["rewards"]["unlocks"])
                    have.update(i["itemId"] for i in q["rewards"]["items"])
        done |= {g for g in granted if g.startswith(("feature_", "perk_"))}
        if before == (len(have), len(done), len(started), len(granted)):
            break

    for i in data.items:
        if i not in have: errors.append(f"reachability: item {i} cannot be obtained from a new save")
    for table in (data.plants, data.animals, data.merges, data.crafts, data.blueprints, data.quests,
                  data.npcs, data.spirits, data.buildings, data.sites, data.shop):
        for did in table:
            if did not in done: errors.append(f"reachability: {did} cannot be reached from a new save")
    for g in granted:
        if g not in done and not g.startswith(("feature_", "perk_")):
            errors.append(f"reachability: reward unlocks {g}, which is never usable")


CHECKS = ["schema", "registry", "references", "formulas", "exploit", "reachability"]


def run(root):
    data = Data(root)
    results = {}
    errs = []; check_schema(data, errs); results["schema"] = errs
    errs = []; known = check_registry(data, errs); results["registry"] = errs
    errs = []; check_references(data, known, errs); results["references"] = errs
    if not results["schema"] and not results["references"]:
        errs = []; check_formulas(data, errs); results["formulas"] = errs
        errs = []; check_exploit(data, errs); results["exploit"] = errs
        errs = []; check_reachability(data, errs); results["reachability"] = errs
    return data, results


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data"))
    args = ap.parse_args()
    data, results = run(os.path.normpath(args.data))
    failed = False
    for name in CHECKS:
        if name not in results:
            print(f"SKIP  {name} (earlier check failed)")
            failed = True
            continue
        errs = results[name]
        print(f"{'PASS' if not errs else 'FAIL'}  {name}" + (f" ({len(errs)} errors)" if errs else ""))
        for e in errs:
            print("      " + e)
        failed = failed or bool(errs)
    counts = ", ".join(f"{len(v)} {k}" for k, v in data.tables.items() if v)
    print(f"Definitions: {counts}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
