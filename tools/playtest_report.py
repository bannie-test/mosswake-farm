#!/usr/bin/env python3
"""Playtest report (M6). Reads the session logs the game writes to user://playtest/ and the
answers of the questionnaire, and fills in the playtest rows of GDD section 20.

  python3 tools/playtest_report.py SESSIONS_DIR [--answers answers.csv] [--out qa/reports/playtest_report.md]

SESSIONS_DIR holds one folder per tester (any name), each with that tester's session_*.json files
in the order they were played. answers.csv is the export of qa/playtest/questionnaire.md: one row
per tester with the columns tester, unfair_merge (yes/no), wants_second_spirit (yes/no),
finished_first_loop_minutes, needed_help (yes/no), crashes (number).
"""
import argparse
import csv
import json
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

TARGETS = {
    "level5_minutes": (60, 90),          # Progression: median time to level 5
    "rare_merge_share": 0.70,            # Merge experience: at least 70% attempt a Rare merge
    "unfair_share_max": 0.20,            # ... fewer than 20% call merging unfair
    "ancient_share": 0.80,               # Research: 80% harvest an Ancient Carrot unaided
    "second_spirit_share": 0.70,         # Automation is rewarding: 70% want a second spirit
    "first_loop_minutes": 10,            # Core loop within 10 minutes without help
    "income_tolerance": 0.20,            # Economy: simulated and playtest income within 20%
    "testers": 15,
}


def load_testers(root):
    testers = {}
    for name in sorted(os.listdir(root)):
        path = os.path.join(root, name)
        files = [path] if name.endswith(".json") else sorted(os.path.join(path, f) for f in os.listdir(path) if f.endswith(".json")) if os.path.isdir(path) else []
        sessions = []
        for f in files:
            with open(f, encoding="utf-8") as fh:
                sessions.append(json.load(fh))
        if sessions:
            testers[os.path.splitext(name)[0]] = sessions
    return testers


def first_time(sessions, pred):
    """Real minutes of play, across a tester's sessions in order, until an event matches."""
    played = 0.0
    for s in sessions:
        for e in s["events"]:
            if pred(e):
                return (played + e["t"]) / 60.0
        played += s.get("realSeconds", 0.0)
    return None


def share(values):
    return sum(1 for v in values if v) / len(values) if values else 0.0


def simulated_income():
    """Median net coins per game day by player level, from the economy simulator."""
    try:
        import economy_sim
        from validate_data import Data
        data = Data(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data"))
        sims = economy_sim.run(data, 12, 10)
        by_level = {}
        for s in sims:
            for d in s.day_log:
                by_level.setdefault(d["level"], []).append(d["net"])
        return {lvl: statistics.median(v) for lvl, v in by_level.items()}
    except Exception as exc:      # the report still works without the simulator
        print("note: simulator comparison skipped:", exc, file=sys.stderr)
        return {}


def row(feature, criterion, value, ok):
    mark = "n/a" if ok is None else ("PASS" if ok else "FAIL")
    return f"| {feature} | {criterion} | {value} | {mark} |"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sessions")
    ap.add_argument("--answers")
    ap.add_argument("--out")
    args = ap.parse_args()
    testers = load_testers(args.sessions)
    n = len(testers)
    answers = {}
    if args.answers:
        with open(args.answers, newline="", encoding="utf-8") as f:
            answers = {r["tester"]: r for r in csv.DictReader(f)}
    yes = lambda t, col: answers.get(t, {}).get(col, "").strip().lower() in ("yes", "y", "1", "true")

    lvl5 = [first_time(s, lambda e: e["kind"] == "level_up" and e["level"] >= 5) for s in testers.values()]
    lvl5_done = [m for m in lvl5 if m is not None]
    rare = [any(e["kind"] == "merge" and e["rarity"] in ("rare", "epic", "legendary", "mythical") for s in ss for e in s["events"]) for ss in testers.values()]
    ancient = [any(e["kind"] == "rare_harvest" and e["item"] == "crop_carrot_ancient" for s in ss for e in s["events"]) for ss in testers.values()]
    spirit = [any(e["kind"] == "spirit_awake" for s in ss for e in s["events"]) for ss in testers.values()]
    before, after = [], []
    for ss in testers.values():
        woke = False
        for s in ss:
            (after if woke else before).append(s.get("realSeconds", 0.0) / 60.0)
            woke = woke or any(e["kind"] == "spirit_awake" for e in s["events"])
    play_income = {}
    for ss in testers.values():
        for s in ss:
            for d in s["days"]:
                play_income.setdefault(d["level"], []).append(d["earned"] - d["spent"])
    sim = simulated_income()
    compared = []
    for lvl in sorted(set(play_income) & set(sim)):
        p = statistics.median(play_income[lvl])
        if len(play_income[lvl]) >= 3 and sim[lvl] > 0:
            compared.append((lvl, p, sim[lvl], abs(p - sim[lvl]) / sim[lvl]))

    out = ["# Playtest report", "", f"Testers with session logs: {n} (section 17 asks for {TARGETS['testers']} outside players). "
           f"Sessions: {sum(len(s) for s in testers.values())}. Questionnaire answers: {len(answers)}.", ""]
    if n < TARGETS["testers"]:
        out += [f"**Not enough testers yet: {n} of {TARGETS['testers']}. The figures below are provisional.**", ""]
    out += ["| Feature (section 20) | Criterion | Measured | Result |", "| --- | --- | --- | --- |"]
    med5 = statistics.median(lvl5_done) if lvl5_done else None
    out.append(row("Progression", "Median time to level 5 is 60-90 minutes", f"{med5:.0f} min ({len(lvl5_done)} of {n} reached it)" if med5 is not None else "nobody reached level 5",
                   None if med5 is None else TARGETS["level5_minutes"][0] <= med5 <= TARGETS["level5_minutes"][1]))
    out.append(row("Merge experience", "At least 70% attempt a Rare merge", f"{share(rare):.0%}", None if not n else share(rare) >= TARGETS["rare_merge_share"]))
    if answers:
        unfair = share([yes(t, "unfair_merge") for t in answers])
        out.append(row("Merge experience", "Fewer than 20% call merging unfair", f"{unfair:.0%}", unfair < TARGETS["unfair_share_max"]))
        unaided = share([a and not yes(t, "needed_help") for t, a in zip(testers, ancient)])
        out.append(row("Research", "80% harvest an Ancient Carrot unaided", f"{unaided:.0%}", unaided >= TARGETS["ancient_share"]))
        second = share([yes(t, "wants_second_spirit") for t in answers])
        out.append(row("Automation is rewarding", "At least 70% want a second spirit", f"{second:.0%}", second >= TARGETS["second_spirit_share"]))
        loops = [float(a["finished_first_loop_minutes"]) for a in answers.values() if a.get("finished_first_loop_minutes", "").strip()]
        if loops:
            out.append(row("Core loop", "First loop within 10 minutes without help", f"median {statistics.median(loops):.0f} min, slowest {max(loops):.0f}", max(loops) <= TARGETS["first_loop_minutes"]))
        crashes = sum(int(a.get("crashes", "0") or 0) for a in answers.values())
        hours = sum(s.get("realSeconds", 0.0) for ss in testers.values() for s in ss) / 3600.0
        out.append(row("Stability", "No crash in 20 hours of combined playtest", f"{crashes} crashes in {hours:.1f} hours", crashes == 0 and hours >= 20))
    else:
        out.append(row("Research", "80% harvest an Ancient Carrot unaided", f"{share(ancient):.0%} harvested one (help not known without the questionnaire)", None))
        out.append(row("Merge experience / Automation / Core loop / Stability", "Questionnaire answers", "no answers.csv given", None))
    if before and after:
        out.append(row("Automation is rewarding", "Median session length does not fall after the first spirit",
                       f"{statistics.median(before):.0f} min before, {statistics.median(after):.0f} min after", statistics.median(after) >= statistics.median(before)))
    else:
        out.append(row("Automation is rewarding", "Median session length does not fall after the first spirit", f"{share(spirit):.0%} woke a spirit; no later sessions to compare", None))
    if compared:
        worst = max(c[3] for c in compared)
        out.append(row("Economy", "Simulated and playtest income per game day agree within 20%",
                       "; ".join(f"level {l}: played {p:.0f}, simulated {s:.0f} ({d:.0%} apart)" for l, p, s, d in compared), worst <= TARGETS["income_tolerance"]))
    else:
        out.append(row("Economy", "Simulated and playtest income per game day agree within 20%", "too few played days per level to compare (3 needed)", None))
    out += ["", "Rows marked n/a need more sessions or the questionnaire. Automated rows of section 20 are in `qa/reports/mvp_acceptance.md`.", ""]
    text = "\n".join(out)
    print(text)
    if args.out:
        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)


if __name__ == "__main__":
    main()
