#!/usr/bin/env python3
"""Asset lint (GDD Appendix A, pipeline step 4).

For every PNG under game/assets:
  - every colour is in the master palette (design/art_bible/palette.gpl)
  - alpha is 0 or 255
  - dimensions are a multiple of the frame size for its folder
  - crop sheets are exactly 7 frames of 16x32
  - ID-named folders (crops, animals, spirits, items) use a registered ID as the file name
  - animation tags in the JSON sidecar follow <action>_<facing> and the standard frame counts

Usage: python3 tools/asset_lint.py     (exit code 0 only when every asset passes)
"""
import json
import os
import re
import sys

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
ASSETS = os.path.join(ROOT, "game", "assets")

FRAME = {"tiles": (16, 16), "crops": (16, 32), "characters": (32, 32), "spirits": (24, 24), "items": (16, 16),
         "props": (16, 8), "fx": (16, 16), "buildings": (16, 16), "ui": (4, 4)}
# 9-slice UI panels are 12x12 with 4 px corners
ANIMAL_FRAME = {"animal_chicken": (16, 16)}            # other animals are 32x32
ID_FOLDERS = {"crops": "plant", "animals": "animal", "spirits": "spirit", "items": None}
ID_NAMED_BUILDINGS = ("bld_", "site_")
# Appendix A animation standards: frames per action
FRAMES = {"characters": {"idle": 4, "walk": 6, "work": 4, "carry": 6, "celebrate": 6, "sleep": 2},
          "spirits": {"idle": 4, "walk": 6, "work": 4, "carry": 6, "celebrate": 6, "sleep": 2},
          "animals": {"idle": 4, "walk": (4, 6), "eat": 4, "sleep": 2, "produce": 4, "interact": 4}}
TAG_RE = re.compile(r"^([a-z]+)_([sne])$")


def palette():
    cols = set()
    with open(os.path.join(ROOT, "design", "art_bible", "palette.gpl")) as f:
        for line in f:
            m = re.match(r"\s*(\d+)\s+(\d+)\s+(\d+)", line)
            if m:
                cols.add(tuple(int(g) for g in m.groups()))
    return cols


def lint():
    errors = []
    pal = palette()
    if len(pal) > 64:
        errors.append(f"palette holds {len(pal)} colours; the limit is 64")
    with open(os.path.join(ROOT, "data", "id_registry.json")) as f:
        ids = {r["id"] for r in json.load(f)["ids"]}
    count = 0
    for dirpath, _, files in os.walk(ASSETS):
        for fn in sorted(files):
            if not fn.endswith(".png") or fn.startswith("font_"):      # the font atlas is white-on-clear, tinted by the theme
                continue
            count += 1
            path = os.path.join(dirpath, fn)
            rel = os.path.relpath(path, ASSETS).replace(os.sep, "/")
            folder, name = rel.split("/")[0], os.path.splitext(fn)[0]
            if not re.match(r"^[a-z0-9_]+$", name):
                errors.append(f"{rel}: file names are lowercase ASCII with underscores")
            img = Image.open(path).convert("RGBA")
            bad_col, bad_alpha = set(), False
            for r, g, b, a in getattr(img, "get_flattened_data", img.getdata)():
                if a not in (0, 255):
                    bad_alpha = True
                elif a == 255 and (r, g, b) not in pal:
                    bad_col.add("#%02x%02x%02x" % (r, g, b))
            if bad_alpha:
                errors.append(f"{rel}: alpha must be 0 or 255")
            if bad_col:
                errors.append(f"{rel}: {len(bad_col)} colours outside the master palette, e.g. {sorted(bad_col)[:3]}")
            fw, fh = ANIMAL_FRAME.get(name, (32, 32)) if folder == "animals" else FRAME.get(folder, (16, 16))
            if img.width % fw or img.height % fh:
                errors.append(f"{rel}: {img.width}x{img.height} is not a multiple of the {fw}x{fh} frame")
            if folder == "crops" and img.size != (112, 32):
                errors.append(f"{rel}: a crop sheet is one strip of 7 frames, 112x32")
            if folder in ID_FOLDERS:
                prefix = ID_FOLDERS[folder]
                if name not in ids or (prefix and not name.startswith(prefix + "_")):
                    errors.append(f"{rel}: file name must be a registered {prefix or 'item'} ID")
            side = os.path.splitext(path)[0] + ".json"
            if folder in FRAMES:
                if not os.path.exists(side):
                    errors.append(f"{rel}: missing JSON sidecar with animation tags")
                    continue
                with open(side) as f:
                    meta = json.load(f)
                if meta.get("frameSize") != [fw, fh]:
                    errors.append(f"{rel}: sidecar frameSize must be [{fw}, {fh}]")
                for tag, a in meta.get("animations", {}).items():
                    m = TAG_RE.match(tag)
                    if not m or m.group(1) not in FRAMES[folder]:
                        errors.append(f"{rel}: animation '{tag}' is not <action>_<facing> from the standard list")
                        continue
                    want = FRAMES[folder][m.group(1)]
                    n = a["to"] - a["from"] + 1
                    if n != want and not (isinstance(want, tuple) and want[0] <= n <= want[1]):
                        errors.append(f"{rel}: '{tag}' has {n} frames, standard is {want}")
                    if (a["to"] + 1) * fw > img.width:
                        errors.append(f"{rel}: '{tag}' runs past the end of the sheet")
    # completeness: every definition that needs art has it (M5: "no placeholder remains" starts here)
    data = os.path.join(ROOT, "data")
    def rows(name):
        with open(os.path.join(data, name)) as f:
            return json.load(f)
    needed = [f"items/{i['id']}.png" for i in rows("items.json")]
    needed += [f"crops/{p['id']}.png" for p in rows("plants.json")]
    needed += [f"animals/{a['id']}.png" for a in rows("animals.json")]
    needed += [f"spirits/{sp['id']}.png" for sp in rows("spirits.json")]
    needed += [f"characters/{n['id']}.png" for n in rows("npcs.json")]
    needed += [f"buildings/{d['id']}.png" for d in rows("dig_sites.json")]
    needed += [n["sprite"] if n["sprite"].endswith(".png") else n["sprite"] + "_base.png" for n in rows("resource_nodes.json")]
    needed += [g["keeperSprite"] for g in rows("gates.json")]
    in_props = {"bld_chest": "props/chest.png", "bld_shipping_bin": "props/shipping_bin.png"}
    needed += [in_props.get(b["id"], f"buildings/{b['id']}.png") for b in rows("buildings.json")]
    for rel in needed:
        if not os.path.exists(os.path.join(ASSETS, rel)):
            errors.append(f"{rel}: missing (a definition in /data needs this sprite)")
    # the standard animations each kind of sheet must carry (Appendix A)
    must = {"characters/player.png": ["idle_s", "idle_n", "idle_e", "walk_s", "walk_n", "walk_e", "work_s", "work_n", "work_e", "carry_s", "celebrate_s", "sleep_s"],
            "spirits/spirit_rootling.png": ["idle_s", "walk_s", "work_s", "sleep_s"]}
    for a in rows("animals.json"):
        must[f"animals/{a['id']}.png"] = ["idle_e", "walk_e", "eat_e", "sleep_e"]
    for rel, tags in must.items():
        side = os.path.join(ASSETS, os.path.splitext(rel)[0] + ".json")
        have = json.load(open(side)).get("animations", {}) if os.path.exists(side) else {}
        for tag in tags:
            if tag not in have:
                errors.append(f"{rel}: animation '{tag}' is missing")
    return count, errors


if __name__ == "__main__":
    n, errs = lint()
    for e in errs:
        print("FAIL  " + e)
    print(f"{'PASS' if not errs else 'FAIL'}  asset lint: {n} sprites, {len(errs)} errors")
    sys.exit(1 if errs else 0)
