#!/usr/bin/env python3
"""Copy /data (the single source of truth) into /game/data so Godot can read it as res://data.

  python3 tools/sync_data.py          copy
  python3 tools/sync_data.py --check  exit 1 if /game/data differs from /data (used by CI)

/game/data is a build copy. Never edit it by hand; edit /data and run this script.
"""
import filecmp
import os
import shutil
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SRC, DST = os.path.join(ROOT, "data"), os.path.join(ROOT, "game", "data")


def files():
    return sorted(f for f in os.listdir(SRC) if f.endswith(".json"))


def main():
    if "--check" in sys.argv:
        have = sorted(f for f in os.listdir(DST) if f.endswith(".json")) if os.path.isdir(DST) else []
        bad = [f for f in files() if f not in have or not filecmp.cmp(os.path.join(SRC, f), os.path.join(DST, f), shallow=False)]
        bad += [f for f in have if f not in files()]
        print("PASS  game/data matches data" if not bad else f"FAIL  game/data is out of date: {bad} (run tools/sync_data.py)")
        sys.exit(1 if bad else 0)
    os.makedirs(DST, exist_ok=True)
    for f in os.listdir(DST):
        if f.endswith(".json"):
            os.remove(os.path.join(DST, f))
    for f in files():
        shutil.copyfile(os.path.join(SRC, f), os.path.join(DST, f))
    print(f"copied {len(files())} files to game/data")


if __name__ == "__main__":
    main()
