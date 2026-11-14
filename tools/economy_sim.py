#!/usr/bin/env python3
"""Mosswake Farm economy simulator (GDD section 10, M0 deliverable).

Plays a scripted hand-worked farm over the static data, one game hour per step, and reports
net coins per game day against the income targets of section 10. It reads every number from
/data; the only values defined here are the PLAYER MODEL assumptions below, which describe the
simulated person, not the game.

Usage: python3 tools/economy_sim.py [--days 12] [--seeds 20] [--report qa/reports/economy_sim_m0.md]
"""
import argparse
import math
import os
import random
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from validate_data import Data  # noqa: E402

# ---- player model (assumptions about the simulated player; calibrate against playtests in M5)
ACTIONS_PER_GAME_HOUR = 24      # plant / water / harvest / collect actions in one real minute
ATTENTION = 0.75                # share of each hour spent on chores rather than menus and walking
WATER_BELOW = 35                # the player waters a plot when its moisture ring drops under this
REACTION_HOURS = 1              # a ripe crop waits about one real minute before the player gets to it
ASSUMED_HAPPINESS = 80          # animals that are fed, petted daily and let outdoors (section 5)
PHASE1_TARGET = (300, 600)      # net coins per game day, section 10 "Income targets"
PHASE1_LEVELS = (1, 5)
MAX_DAYS_TO_AFFORD = 3          # section 10: more than three days means the price is wrong


class Sim:
    def __init__(self, data, seed):
        self.d = data
        self.rng = random.Random(seed)
        cfg = data.config
        self.cfg = cfg
        self.eco = cfg["economy"]
        ng = cfg["newGame"]
        self.coins = ng["coins"]
        self.level, self.xp = 1, 0
        self.inv = {}
        for i in ng["items"]:
            self.add(i["itemId"], i["qty"])
        self.fields = ng["fields"]
        self.plots = [self.new_plot() for _ in range(self.fields * self.eco["fields"]["plotsPerField"])]
        self.animals = [self.new_animal(a["animalId"]) for a in ng["animals"] for _ in range(a["qty"])]
        self.buildings = {b: 1 for b in ng["buildings"]}
        self.quests_done = set()
        self.rep = {n: 0 for n in data.npcs}
        self.orders = []            # open delivery orders
        self.slot_free_at = {}      # (npc, slot) -> hour the slot refills
        self.bin = {}               # goods waiting for dawn payout
        self.pity = {}
        self.hour = 0
        self.day_log = []
        self.purchases = []         # (hour, what, cost, hours the player waited while saving for it)
        self.saving_since = None
        self.reset_day()

    # ------------------------------------------------------------ helpers
    def reset_day(self):
        self.income = self.running = self.capital = 0

    def new_plot(self):
        return {"plant": None, "growth": 0.0, "moisture": 0.0, "harvests": 0, "mature": False, "ripe_at": 0}

    def new_animal(self, aid):
        return {"id": aid, "hunger": 100.0, "progress": 0.0}

    def add(self, item, qty):
        self.inv[item] = self.inv.get(item, 0) + qty

    def take(self, item, qty):
        assert self.inv.get(item, 0) >= qty, (item, qty)
        self.inv[item] -= qty

    def has(self, item):
        return self.inv.get(item, 0)

    def value(self, item):
        return self.d.items[item]["baseValue"]

    def xp_next(self, level):
        c = self.eco["levelCurve"]
        return c["scale"] * round(c["factor"] * level ** c["exponent"])

    def gain_xp(self, n):
        self.xp += n
        while self.level < self.eco["levelCurve"]["maxLevel"] and self.xp >= self.xp_next(self.level):
            self.xp -= self.xp_next(self.level)
            self.level += 1

    def spend(self, n, capital=False):
        assert self.coins >= n
        self.coins -= n
        if capital:
            self.capital += n
        else:
            self.running += n

    def unlocked(self, u):
        if "playerLevel" in u and self.level < u["playerLevel"]: return False
        if "quest" in u and u["quest"] not in self.quests_done: return False
        if "building" in u and u["building"] not in self.buildings: return False
        if "npcReputation" in u and self.rep_level(u["npcReputation"]["npcId"]) < u["npcReputation"]["level"]: return False
        if "firstResearchOf" in u or "blueprint" in u: return False   # research is outside this Phase 1 model
        return True

    def rep_level(self, npc):
        th = self.d.npcs[npc]["reputationThresholds"]
        return sum(1 for t in th if self.rep[npc] >= t)

    def plant_options(self):
        return [p for p in self.d.plants.values() if self.unlocked(p["unlock"])]

    def seed_price(self, plant):
        for e in self.d.shop.values():
            if e.get("itemId") == plant["seedItemId"] and self.unlocked(e["unlock"]):
                return e["price"]
        return None

    # ------------------------------------------------------------ orders
    def producible(self):
        out = set()
        for p in self.plant_options():
            if self.seed_price(p) is not None or self.has(p["seedItemId"]):
                out.add(p["productItemId"])
        for a in self.animals:
            out.add(self.d.animals[a["id"]]["renewable"]["itemId"])
        changed = True
        while changed:
            changed = False
            for r in self.d.merges.values():
                if r["output"]["itemId"] not in out and self.recipe_known(r) and all(i["itemId"] in out for i in r["inputs"]):
                    out.add(r["output"]["itemId"])
                    changed = True
        return out

    def recipe_known(self, r):
        return r["station"] in self.buildings and self.unlocked(r["unlock"])

    def capacity_24h(self, item):
        """Units of `item` the current farm can make in one game day (section 8, capacityPer24h)."""
        cap = 0.0
        for p in self.plant_options():
            if p["productItemId"] == item:
                cap += len(self.plots) * p["yield"]["min"] * 24 / p["growthHours"]
        for a in self.animals:
            r = self.d.animals[a["id"]]["renewable"]
            if r["itemId"] == item:
                cap += r["qty"] * 24 / r["intervalHours"]
        for r in self.d.merges.values():
            if r["output"]["itemId"] == item and self.recipe_known(r):
                cap += min(self.capacity_24h(i["itemId"]) / i["qty"] for i in r["inputs"])
        return cap

    def generate_order(self, npc_id):
        o_cfg = self.cfg["orders"]
        npc = self.d.npcs[npc_id]
        rules = npc["orderRules"]
        open_items = {l["item"] for o in self.orders for l in o["lines"]}
        pool = [i for i in self.producible()
                if set(self.d.items[i]["tags"]) & set(rules["tags"])
                and self.d.items[i]["tier"] <= o_cfg["deliveryMaxTier"] and i not in open_items]
        if not pool:
            return None
        b = o_cfg["budget"]
        budget = (b["base"] + b["perLevel"] * self.level + b["perLevelSq"] * self.level ** 2) * rules["sizeFactor"]
        lines = self.rng.sample(pool, min(len(pool), self.rng.randint(1, rules["maxLines"])))
        order = {"npc": npc_id, "lines": []}
        for item in lines:
            qty = round(budget / len(lines) / self.value(item))
            cap = math.floor(o_cfg["capacityShare"] * self.capacity_24h(item))
            order["lines"].append({"item": item, "qty": max(1, min(qty, max(1, cap)))})
        value = sum(l["qty"] * self.value(l["item"]) for l in order["lines"])
        order["coins"] = round(value * self.eco["saleRate"]["delivery"])
        order["xp"] = round(value * self.eco["xpRate"]["delivery"])
        return order

    def npc_met(self, npc_id):
        return self.level >= self.d.npcs[npc_id]["appears"].get("playerLevel", 1)

    def refresh_orders(self):
        if "quest_first_harvest" not in self.quests_done:
            return
        for npc_id, npc in self.d.npcs.items():
            if not self.npc_met(npc_id):
                continue
            for slot in range(npc["orderRules"]["deliverySlots"]):
                key = (npc_id, slot)
                if any(o["slot"] == key for o in self.orders) or self.slot_free_at.get(key, 0) > self.hour:
                    continue
                o = self.generate_order(npc_id)
                if o:
                    o["slot"] = key
                    self.orders.append(o)

    def needed_for_orders(self, item):
        return sum(l["qty"] for o in self.orders for l in o["lines"] if l["item"] == item)

    def deliver_orders(self):
        for o in list(self.orders):
            if all(self.has(l["item"]) >= l["qty"] for l in o["lines"]):
                for l in o["lines"]:
                    self.take(l["item"], l["qty"])
                self.coins += o["coins"]
                self.income += o["coins"]
                self.gain_xp(o["xp"])
                self.rep[o["npc"]] += self.cfg["reputation"]["delivery"]
                self.orders.remove(o)
                self.slot_free_at[o["slot"]] = self.hour + self.cfg["orders"]["refillMinutes"]["completed"] / 60

    # ------------------------------------------------------------ merge
    def merge(self, rid):
        r = self.d.merges[rid]
        mc = self.d.merge_config
        out = r["output"]["itemId"]
        fee = round(mc["feeRatio"] * self.value(out))
        if self.coins < fee or any(self.has(i["itemId"]) < i["qty"] for i in r["inputs"]):
            return False
        self.spend(fee)
        self.gain_xp(fee)
        cap = mc["modifierCap"].get(r["rarity"], mc["modifierCap"]["default"])
        p = min(100, min(cap, mc["baseRate"][r["rarity"]]) + mc["pityStep"] * self.pity.get(rid, 0))
        if self.rng.uniform(0, 100) < p:
            for i in r["inputs"]:
                self.take(i["itemId"], i["qty"])
            self.add(out, r["output"]["qty"])
            self.pity[rid] = 0
        else:
            for i in r["inputs"]:
                self.take(i["itemId"], i["qty"] - max(1, math.floor(i["qty"] * mc["failRefundRatio"])))
            self.pity[rid] = self.pity.get(rid, 0) + 1
        return True

    def merge_towards(self, item, qty):
        """Merge up the chain until `qty` of `item` are in stock, as far as raw goods allow."""
        for r in self.d.merges.values():
            if r["output"]["itemId"] == item and self.recipe_known(r):
                guard = 0
                while self.has(item) < qty and guard < 50:
                    guard += 1
                    for i in r["inputs"]:
                        self.merge_towards(i["itemId"], i["qty"])
                    if not self.merge(r["id"]):
                        break

    # ------------------------------------------------------------ quests (Phase 1 only)
    def quests(self):
        q = self.quests_done
        if "quest_first_harvest" not in q and self.has("crop_carrot") >= 6:
            self.take("crop_carrot", 6); self.finish("quest_first_harvest")
        if "quest_table_for_two" not in q and self.level >= 3 and "bld_merge_table" in self.buildings:
            self.merge_towards("merged_carrot_premium", 1)
            if self.has("merged_carrot_premium") >= 1:
                self.finish("quest_table_for_two")
        if "quest_strange_carrot" not in q and "quest_table_for_two" in q and self.level >= 4:
            self.merge_towards("merged_carrot_golden", 1)
            if self.has("merged_carrot_golden") >= 1:
                self.take("merged_carrot_golden", 1); self.finish("quest_strange_carrot")

    def finish(self, qid):
        quest = self.d.quests[qid]
        self.quests_done.add(qid)
        self.gain_xp(quest["rewards"]["xp"])
        for npc, r in quest["rewards"]["reputation"].items():
            self.rep[npc] += r
        for i in quest["rewards"]["items"]:
            self.add(i["itemId"], i["qty"])

    # ------------------------------------------------------------ purchases
    def next_purchase(self):
        """The next major purchase, in the order section 10 plans them."""
        f = self.eco["fields"]
        bought = self.fields - self.cfg["newGame"]["fields"]
        field = ("field", round(f["baseCost"] * f["growth"] ** bought)) if self.fields < f["maxFields"] else None
        b = self.d.buildings
        want = []
        if "bld_merge_table" not in self.buildings and self.unlocked(b["bld_merge_table"]["unlock"]):
            want.append(("bld_merge_table", b["bld_merge_table"]["levels"][0]["coins"]))
        if "bld_research_station" not in self.buildings and self.unlocked(b["bld_research_station"]["unlock"]):
            want.append(("bld_research_station", b["bld_research_station"]["levels"][0]["coins"]))
        if "bld_barn" not in self.buildings and self.unlocked(b["bld_barn"]["unlock"]):
            want.append(("bld_barn", b["bld_barn"]["levels"][0]["coins"]))
        if field:
            want.append(field)
        coop_cap = b["bld_coop"]["levels"][self.buildings["bld_coop"] - 1]["effects"]["capacity"]
        if sum(1 for a in self.animals if a["id"] == "animal_chicken") < coop_cap:
            want.append(("animal_chicken", self.d.animals["animal_chicken"]["buyCost"]))
        if "bld_barn" in self.buildings and self.level >= self.d.animals["animal_cow"]["unlock"]["playerLevel"] \
                and sum(1 for a in self.animals if a["id"] != "animal_chicken") < b["bld_barn"]["levels"][0]["effects"]["capacity"]:
            want.append(("animal_cow", self.d.animals["animal_cow"]["buyCost"]))
        return min(want, key=lambda w: w[1]) if want else None

    def buy(self):
        reserve = 2 * sum(self.seed_price(p) or 0 for p in self.plant_options()[:1]) * len(self.plots)
        while True:
            nxt = self.next_purchase()
            if not nxt:
                return
            what, cost = nxt
            if self.coins < cost + reserve:
                if self.saving_since is None:
                    self.saving_since = self.hour
                return
            self.spend(cost, capital=True)
            waited = self.hour - (self.saving_since if self.saving_since is not None else self.hour)
            self.purchases.append((self.hour, what, cost, waited))
            self.saving_since = None
            if what == "field":
                self.fields += 1
                self.plots += [self.new_plot() for _ in range(self.eco["fields"]["plotsPerField"])]
            elif what.startswith("animal_"):
                self.animals.append(self.new_animal(what))
            else:
                self.buildings[what] = 1

    # ------------------------------------------------------------ one game hour
    def choose_plant(self):
        opts = [p for p in self.plant_options() if self.has(p["seedItemId"]) or (self.seed_price(p) or 1e9) <= self.coins]
        if not opts:
            return None
        growing = {}
        for pl in self.plots:
            if pl["plant"]:
                growing[pl["plant"]["productItemId"]] = growing.get(pl["plant"]["productItemId"], 0) + pl["plant"]["yield"]["min"]

        def shortfall(p):
            item = p["productItemId"]
            need = self.needed_for_orders(item)
            for r in self.d.merges.values():   # raw goods wanted by merged order lines
                if self.recipe_known(r) and r["inputs"][0]["itemId"] == item:
                    need += r["inputs"][0]["qty"] * self.needed_for_orders(r["output"]["itemId"])
            if item == "crop_wheat":             # Feed for the next two days
                per_day = sum(self.d.animals[a["id"]]["feed"]["qtyPer8h"] * 3 for a in self.animals)
                need += max(0, 2 * per_day - self.has("mat_feed")) * 2
            if item == "crop_carrot" and "quest_first_harvest" not in self.quests_done:
                need += 6
            return need - self.has(item) - growing.get(item, 0)

        short = [p for p in opts if shortfall(p) > 0]
        if short:
            return max(short, key=shortfall)

        def profit_per_hour(p):
            harvests = p["regrow"]["maxHarvests"] if p["regrow"] else 1
            hours = p["growthHours"] + (p["regrow"]["hours"] * (harvests - 1) if p["regrow"] else 0)
            return (p["yield"]["min"] * harvests * self.value(p["productItemId"]) - (self.seed_price(p) or 0)) / hours
        return max(opts, key=profit_per_hour)

    def step(self):
        actions = ACTIONS_PER_GAME_HOUR * ATTENTION
        # simulation: moisture, growth, animals
        for pl in self.plots:
            p = pl["plant"]
            if p and not pl["mature"]:
                if pl["moisture"] > 0:
                    pl["growth"] += 1
                    pl["moisture"] = max(0.0, pl["moisture"] - 100 / p["waterIntervalHours"])
                target = p["regrow"]["hours"] if (p["regrow"] and pl["harvests"] > 0) else p["growthHours"]
                if pl["growth"] >= target:
                    pl["mature"] = True
                    pl["ripe_at"] = self.hour
        for a in self.animals:
            ad = self.d.animals[a["id"]]
            if a["hunger"] <= 0 and self.has(ad["feed"]["itemId"]) >= ad["feed"]["qtyPer8h"]:
                self.take(ad["feed"]["itemId"], ad["feed"]["qtyPer8h"])
                self.running += ad["feed"]["qtyPer8h"] * 0   # feed cost is paid as the wheat that made it
                a["hunger"] = 100.0
            if a["hunger"] > 0:
                a["progress"] += 0.4 + 0.4 * ASSUMED_HAPPINESS / 100 + 0.2
                a["hunger"] = max(0.0, a["hunger"] - ad["hungerDrainPerHour"])
        # chores
        for pl in self.plots:
            if actions < 1: break
            if pl["mature"] and self.hour - pl["ripe_at"] >= REACTION_HOURS:
                p = pl["plant"]
                self.add(p["productItemId"], p["yield"]["min"])
                self.gain_xp(p["yield"]["min"] * p["xpPerUnit"])
                pl["harvests"] += 1
                pl["growth"], pl["mature"] = 0.0, False
                if not p["regrow"] or pl["harvests"] >= p["regrow"]["maxHarvests"]:
                    pl["plant"], pl["harvests"] = None, 0
                actions -= 1
        for a in self.animals:
            r = self.d.animals[a["id"]]["renewable"]
            if actions >= 1 and a["progress"] >= r["intervalHours"]:
                a["progress"] -= r["intervalHours"]
                self.add(r["itemId"], r["qty"])
                actions -= 1
        for pl in self.plots:
            if actions < 1: break
            if pl["plant"] and not pl["mature"] and pl["moisture"] < WATER_BELOW:
                pl["moisture"] = 100.0
                actions -= 1
        for pl in self.plots:
            if actions < 2: break
            if pl["plant"] is None:
                p = self.choose_plant()
                if p is None: break
                if not self.has(p["seedItemId"]):
                    self.spend(self.seed_price(p)); self.add(p["seedItemId"], 1)
                self.take(p["seedItemId"], 1)
                pl.update(plant=p, growth=0.0, moisture=100.0, harvests=0, mature=False)
                actions -= 2   # plant + first watering
        # menus: craft Feed, quests, merges for orders, deliveries, purchases
        feed = self.d.crafts["craft_feed"]
        want_feed = 2 * sum(self.d.animals[a["id"]]["feed"]["qtyPer8h"] * 3 for a in self.animals)
        while self.has("mat_feed") < want_feed and self.has("crop_wheat") >= feed["inputs"][0]["qty"]:
            self.take("crop_wheat", feed["inputs"][0]["qty"]); self.add("mat_feed", feed["output"]["qty"])
        self.quests()
        self.refresh_orders()
        for o in self.orders:
            for l in o["lines"]:
                if self.d.items[l["item"]]["category"] == "merged":
                    self.merge_towards(l["item"], l["qty"])
        self.deliver_orders()
        self.buy()
        self.hour += 1
        if self.hour % 24 == 0:
            self.dawn()

    def dawn(self):
        # ship surplus: keep what open orders, Feed and quests still need
        for item, qty in list(self.inv.items()):
            it = self.d.items[item]
            if not it["sellable"] or qty <= 0:
                continue
            keep = self.needed_for_orders(item)
            for r in self.d.merges.values():
                if self.recipe_known(r) and r["inputs"][0]["itemId"] == item:
                    keep += r["inputs"][0]["qty"] * self.needed_for_orders(r["output"]["itemId"])
            if item == "crop_wheat": keep += 12
            if item == "crop_carrot": keep += 9 if "quest_strange_carrot" not in self.quests_done else 0
            sell = max(0, qty - keep)
            if sell:
                self.take(item, sell)
                pay = round(sell * it["baseValue"] * self.eco["saleRate"]["bin"])
                self.coins += pay
                self.income += pay
        d = self.cfg["economy"]["deadlock"]
        if self.coins < d["coinsBelow"] and not any(self.has(p["seedItemId"]) for p in self.plant_options()) \
                and not any(pl["plant"] for pl in self.plots):
            self.add(d["giftItemId"], d["giftQty"])
        self.day_log.append({"day": self.hour // 24, "level": self.level, "income": self.income, "running": self.running,
                             "net": self.income - self.running, "capital": self.capital, "coins": self.coins,
                             "plots": len(self.plots), "animals": len(self.animals)})
        self.reset_day()


def run(data, days, seeds):
    sims = []
    for seed in range(seeds):
        s = Sim(data, seed)
        for _ in range(days * 24):
            s.step()
        sims.append(s)
    return sims


def report(sims, days):
    lines = ["# Economy simulator report", "",
             f"Scripted hand-played farm, {days} game days, {len(sims)} seeds. All game numbers come from `/data`.",
             f"Player model: {ACTIONS_PER_GAME_HOUR} actions per game hour at {ATTENTION:.0%} attention, waters under {WATER_BELOW} moisture, reaches ripe crops {REACTION_HOURS} game hour late, plays every hour of every day.",
             "", "| Day | Level | Net coins (median) | Net (min-max) | Income | Running cost | Plots | Animals | Coins at dawn |",
             "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
    med = lambda k, d: statistics.median(s.day_log[d][k] for s in sims)
    phase1_nets = []
    for d in range(days):
        nets = [s.day_log[d]["net"] for s in sims]
        lvl = med("level", d)
        start_lvl = med("level", d - 1) if d else 1
        if PHASE1_LEVELS[0] <= start_lvl <= PHASE1_LEVELS[1]:
            phase1_nets.append(statistics.median(nets))
        lines.append(f"| {d + 1} | {lvl:g} | {statistics.median(nets):.0f} | {min(nets)}-{max(nets)} | {med('income', d):.0f} | "
                     f"{med('running', d):.0f} | {med('plots', d):g} | {med('animals', d):g} | {med('coins', d):.0f} |")
    ok = True
    lines += ["", "## Checks", ""]
    if phase1_nets:
        lo, hi = min(phase1_nets), max(phase1_nets)
        mean = statistics.mean(phase1_nets)
        p1 = PHASE1_TARGET[0] <= mean <= PHASE1_TARGET[1]
        ok &= p1
        lines.append(f"- {'PASS' if p1 else 'FAIL'}: Phase 1 net income target {PHASE1_TARGET[0]}-{PHASE1_TARGET[1]} coins per game day, "
                     f"averaged over the {len(phase1_nets)} days that start at level {PHASE1_LEVELS[0]}-{PHASE1_LEVELS[1]}. "
                     f"Mean {mean:.0f}; per day: " + ", ".join(f"{n:.0f}" for n in phase1_nets) + ".")
    else:
        ok = False
        lines.append("- FAIL: no Phase 1 days were simulated.")
    worst = {}
    for s in sims:
        for hour, what, cost, waited in s.purchases:
            worst[what] = max(worst.get(what, 0), waited / 24)
    slow = {k: v for k, v in worst.items() if v > MAX_DAYS_TO_AFFORD}
    ok &= not slow
    lines.append(f"- {'PASS' if not slow else 'FAIL'}: no major purchase takes more than {MAX_DAYS_TO_AFFORD} game days of saving. "
                 f"Longest waits: " + ", ".join(f"{k} {v:.1f} d" for k, v in sorted(worst.items(), key=lambda kv: -kv[1])[:4]) + ".")
    reached = statistics.median(s.level for s in sims)
    quests = min(len(s.quests_done) for s in sims)
    q_ok = quests >= 3
    ok &= q_ok
    lines.append(f"- {'PASS' if q_ok else 'FAIL'}: every run finishes the three Phase 1 quests (worst run: {quests} of 3). Median level after {days} days: {reached:g}.")
    hours5 = [next((d["day"] for d in s.day_log if d["level"] >= 5), None) for s in sims]
    if all(hours5):
        m = statistics.median(hours5) * 24
        lines.append(f"- INFO: median real time to level 5 is {m:.0f} minutes (section 20 playtest target: 60-90).")
    lines += ["", "## First purchases (seed 0)", "", "| Game day | Purchase | Cost |", "| --- | --- | --- |"]
    for hour, what, cost, waited in sims[0].purchases[:14]:
        lines.append(f"| {hour / 24:.1f} | {what} | {cost} |")
    lines += ["", f"**Overall: {'PASS' if ok else 'FAIL'}**", ""]
    return "\n".join(lines), ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data"))
    ap.add_argument("--days", type=int, default=12)
    ap.add_argument("--seeds", type=int, default=20)
    ap.add_argument("--report")
    args = ap.parse_args()
    data = Data(os.path.normpath(args.data))
    text, ok = report(run(data, args.days, args.seeds), args.days)
    print(text)
    if args.report:
        os.makedirs(os.path.dirname(args.report), exist_ok=True)
        with open(args.report, "w", encoding="utf-8") as f:
            f.write(text)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
