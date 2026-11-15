#!/usr/bin/env python3
"""Revision 2 economy derivation (GDD 21.3, step R2-A).

Re-runs the value formulas of section 10 with growth in days and 12 tilled tiles per lot, and
prints what every dependent number becomes. It changes nothing: the values are applied in step
R2-B, together with the code that grows crops by days.

Usage: python3 tools/r2_derive.py [--out qa/reports/r2_economy_derivation.md]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from validate_data import Data  # noqa: E402


def nice(v):
    """Round a derived price to a tidy number, as the GDD's own tables do."""
    if v < 50:
        return round(v)
    if v < 500:
        return int(round(v / 2.0) * 2)
    if v < 2000:
        return int(round(v / 10.0) * 10)
    return int(round(v / 50.0) * 50)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out")
    args = ap.parse_args()
    d = Data(os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")))
    eco, land = d.config["economy"], d.config["land"]
    k = d.merge_config["valueFactor"]
    shop = {e["itemId"]: e["price"] for e in d.shop.values() if "itemId" in e}
    new = {}
    out = ["# Revision 2 economy derivation", "",
           "Section 10's formulas re-run with crops that grow by days (1 game day = 24 hours) and 12 tilled tiles per lot. "
           "Nothing here is applied yet; step R2-B applies it with the daily-growth code.", "",
           "## Crop values", "", "`baseValue = (CPH(rarity) x total growth hours + seed cost) / total yield`", "",
           "| Crop | Growth now | Growth in R2 | Seed | Value now | Value in R2 | Net coins per tile per day |", "| --- | --- | --- | --- | --- | --- | --- |"]
    for p in sorted(d.plants.values(), key=lambda p: p["growthDays"]):
        if p["seedItemId"] not in shop:
            continue
        harvests = p["regrow"]["maxHarvests"] if p["regrow"] else 1
        days = p["growthDays"] + (p["regrow"]["days"] * (harvests - 1) if p["regrow"] else 0)
        seed = shop[p["seedItemId"]]
        total_yield = p["yield"]["min"] * harvests
        v = nice((eco["cphByRarity"][p["rarity"]] * days * 24 + seed) / total_yield)
        new[p["productItemId"]] = v
        out.append(f"| {d.items[p['productItemId']]['name']} | {p['growthHours']} h | {p['growthDays']} d"
                   + (f", regrows in {p['regrow']['days']} d x{harvests}" if p["regrow"] else "")
                   + f" | {seed} | {d.items[p['productItemId']]['baseValue']} | {v} | {(v * total_yield - seed) / days:.0f} |")
    out += ["", "Every Common crop still earns about 2 coins per tile-hour (48 per day), as section 10 intends; only the rhythm changes.", "",
            "## Merged goods", "", "`value = k(rarity) x sum of ingredient values`", "", "| Recipe | Value now | Value in R2 |", "| --- | --- | --- |"]
    changed = True
    while changed:
        changed = False
        for r in d.merges.values():
            o = r["output"]["itemId"]
            if o in new or not all(i["itemId"] in new or d.items[i["itemId"]]["category"] == "animal_product" for i in r["inputs"]):
                continue
            if all(new.get(i["itemId"], d.items[i["itemId"]]["baseValue"]) == d.items[i["itemId"]]["baseValue"] for i in r["inputs"]):
                new[o] = d.items[o]["baseValue"]          # nothing it is made of changed
            else:
                ing = sum(new.get(i["itemId"], d.items[i["itemId"]]["baseValue"]) * i["qty"] for i in r["inputs"])
                new[o] = nice(k[r["rarity"]] * ing)
            changed = True
    for r in d.merges.values():
        o = r["output"]["itemId"]
        if new.get(o) != d.items[o]["baseValue"]:
            out.append(f"| {d.items[o]['name']} | {d.items[o]['baseValue']} | {new[o]} |")
    out += ["", "Animal products and what is merged from them keep their values: animals still produce by the hour.", "", "## Blueprint species", ""]
    for bp in d.blueprints.values():
        c = bp["creation"]
        cost = c["coins"] + sum(new.get(i["itemId"], d.items[i["itemId"]]["baseValue"]) * i["qty"] for i in c["inputs"])
        seed_item = c["output"]["itemId"]
        seed_v = nice(cost / c["output"]["qty"])
        plant = next(p for p in d.plants.values() if p["seedItemId"] == seed_item)
        crop_v = nice((eco["cphByRarity"][plant["rarity"]] * plant["growthDays"] * 24 + seed_v) / plant["yield"]["min"])
        out.append(f"- {d.items[seed_item]['name']}: {d.items[seed_item]['baseValue']} -> {seed_v}. "
                   f"{d.items[plant['productItemId']]['name']}: {d.items[plant['productItemId']]['baseValue']} -> {crop_v} (grows in {plant['growthDays']} days).")
    tiles_start = land["startingLots"] * land["tilledTilesPerLot"]
    tiles_max = land["lots"] * land["tilledTilesPerLot"]
    f = eco["fields"]
    taxes = [round(f["baseCost"] * f["growth"] ** n) for n in range(land["lots"] - land["startingLots"])]
    out += ["", "## Land", "",
            f"- Tilled tiles: {tiles_start} at the start, {tiles_max} with all {land['lots']} lots (was 12 and 36).",
            f"- {land['taxName']}, paid once per lot: {', '.join(str(t) for t in taxes)} coins (the field prices of section 10, unchanged for now).",
            f"- A full farm of Common crops earns about {tiles_max * 48:,} coins per game day before orders pay their 1.3x (was about {36 * 48:,}).", "",
            "## What this moves, and what R2-B must re-tune", "",
            "| Number | Effect of the change | Action |", "| --- | --- | --- |",
            "| Order budget (40 + 25L + 3L^2 in goods value) | The same value now buys about a third as many crop units, so early orders ask for 2-3 Carrots | Keep the formula; check that order quantities stay above 1 at level 1 |",
            "| Harvest XP (1 per unit x rarity rank) | A tile is harvested once a day instead of four times, so harvest XP falls to about a quarter | Raise harvest XP per unit, or lean on order and quest XP; measure with the 60-minute session test |",
            "| Income targets of section 10 | Twice the tiles at the same coins per tile-hour doubles top income | Re-tune the land tax so that the next lot costs 1-2 game days of income |",
            "| Energy (100) | 24 tiles need 24 energy to water and 48 to till once; 72 tiles cannot all be worked by hand in one day | Intended: it is what makes a Rootling worth waking. Check with the simulator that a level 1 farm fits in one energy bar |",
            "| Watering Can (10 charges) | 24 tiles need 3 walks to the well per day | Check the walk time on the real map |",
            "| Story: Ancient Carrot | The chain costs more coins but the same number of Carrots (27 per Golden Carrot) | None |",
            "| First loop in 10 minutes (section 20) | The first harvest now comes after the first night | Decision Q3: measured to the first delivered order |", ""]
    text = "\n".join(out)
    print(text)
    if args.out:
        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(text)


if __name__ == "__main__":
    main()
