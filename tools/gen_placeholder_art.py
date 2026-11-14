#!/usr/bin/env python3
"""Placeholder pixel art for Mosswake Farm, drawn in code (GDD Appendix A).

Every sprite here is an original design drawn pixel by pixel in the master palette at its final
size. Nothing is traced, scaled or generated from the reference images. These are PLACEHOLDERS for
M0-M4; final art replaces them in M5 through the same lint and human approval gate.

Usage: python3 tools/gen_placeholder_art.py     (writes design/art_bible/palette.* and game/assets/**)
"""
import json
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
ASSETS = os.path.join(ROOT, "game", "assets")
BIBLE = os.path.join(ROOT, "design", "art_bible")

RAMPS = [
    ("Grass", ["#2f5d3a", "#4a8a45", "#6fae4f", "#a3cc5c", "#d4e07a"]),
    ("Soil and path", ["#4a2f25", "#6e4630", "#96643c", "#c08a4e", "#e0b872"]),
    ("Wood", ["#3a2620", "#5a3a2a", "#7d5236", "#a67348"]),
    ("Building warm", ["#8f3b32", "#c2623d", "#d9a066", "#f0dcae"]),
    ("Stone", ["#4b4a52", "#6f6e72", "#9a9790", "#c9c4b4"]),
    ("Sky and water", ["#3f6ea5", "#6d9fd1", "#a9d0e8", "#e6f2f0"]),
    ("Flower accents", ["#d9483b", "#f2a33a", "#f4d64e", "#f29bb5", "#b565c9", "#5b7fd6"]),
    ("Magic glow", ["#7ee0c2", "#c8f08f", "#ffe9a3"]),
    ("Outline and shadow", ["#2a1f2b"]),
]


def rgb(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)


G = [rgb(c) for c in RAMPS[0][1]]
S = [rgb(c) for c in RAMPS[1][1]]
W = [rgb(c) for c in RAMPS[2][1]]
B = [rgb(c) for c in RAMPS[3][1]]
T = [rgb(c) for c in RAMPS[4][1]]
K = [rgb(c) for c in RAMPS[5][1]]
RED, ORANGE, YELLOW, PINK, PURPLE, BLUE = [rgb(c) for c in RAMPS[6][1]]
TEAL, SAP, AMBER = [rgb(c) for c in RAMPS[7][1]]
OUT = rgb(RAMPS[8][1][0])
CLEAR = (0, 0, 0, 0)


def new(w, h, fill=CLEAR):
    return Image.new("RGBA", (w, h), fill)


def px(img, pts, col):
    for x, y in pts:
        if 0 <= x < img.width and 0 <= y < img.height:
            img.putpixel((x, y), col)


def rect(img, x0, y0, x1, y1, col):
    ImageDraw.Draw(img).rectangle([min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)], fill=col)


def ellipse(img, x0, y0, x1, y1, col):
    ImageDraw.Draw(img).ellipse([x0, y0, x1, y1], fill=col)


def outline(img, col=OUT):
    """1 px outline around every opaque shape (characters, animals, spirits, pick-up items)."""
    src = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y))[3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < img.width and 0 <= ny < img.height and src.getpixel((nx, ny))[3]:
                        img.putpixel((x, y), col)
                        break
    return img


def strip(frames):
    w, h = frames[0].size
    out = new(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out


def save(img, rel, meta=None):
    path = os.path.join(ASSETS, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    if meta:
        with open(os.path.splitext(path)[0] + ".json", "w") as f:
            json.dump(meta, f, indent=2)
            f.write("\n")


def clusters(img, rng, cols, n, x0=0, y0=0, w=16, h=16):
    """Shade in small clusters, never single stray pixels (Appendix A, shading rules)."""
    for _ in range(n):
        x, y = x0 + rng.randrange(w - 1), y0 + rng.randrange(h - 1)
        c = rng.choice(cols)
        shape = rng.choice([[(0, 0), (1, 0)], [(0, 0), (0, 1)], [(0, 0), (1, 0), (1, 1)], [(0, 0), (1, 0), (0, 1)]])
        px(img, [(x + dx, y + dy) for dx, dy in shape], c)


# ------------------------------------------------------------------ palette
def write_palette():
    os.makedirs(BIBLE, exist_ok=True)
    with open(os.path.join(BIBLE, "palette.gpl"), "w") as f:
        f.write("GIMP Palette\nName: Mosswake Farm master palette\nColumns: 6\n#\n")
        for name, cols in RAMPS:
            for i, c in enumerate(cols):
                r, g, b, _ = rgb(c)
                f.write(f"{r:3d} {g:3d} {b:3d}\t{name} {i + 1}\n")
    flat = [c for _, cols in RAMPS for c in cols]
    sw = new(len(flat), 1)
    px(sw, [], OUT)
    for i, c in enumerate(flat):
        sw.putpixel((i, 0), rgb(c))
    sw.save(os.path.join(BIBLE, "palette.png"))


# ------------------------------------------------------------------ terrain
def ground_tiles():
    rng = random.Random(11)
    tiles = []
    for _ in range(3):                                   # three grass centre variants
        t = new(16, 16, G[2])
        clusters(t, rng, [G[1]], 5)
        clusters(t, rng, [G[3]], 4)
        tiles.append(t)
    for _ in range(3):                                   # three dirt path variants
        t = new(16, 16, S[3])
        clusters(t, rng, [S[2]], 5)
        clusters(t, rng, [S[4]], 3)
        tiles.append(t)
    edge = new(16, 16, G[2])                             # grass above, path below (soft dithered edge)
    rect(edge, 0, 8, 15, 15, S[3])
    px(edge, [(x, 8) for x in range(0, 16, 2)] + [(x, 7) for x in range(1, 16, 4)], G[1])
    px(edge, [(x, 9) for x in range(1, 16, 4)], G[2])
    tiles.append(edge)
    edge2 = edge.transpose(Image.FLIP_TOP_BOTTOM)        # path above, grass below
    tiles.append(edge2)
    save(strip(tiles), "tiles/farm_ground.png",
         {"frameSize": [16, 16], "tiles": ["grass_a", "grass_b", "grass_c", "path_a", "path_b", "path_c", "edge_grass_path", "edge_path_grass"]})

    detail = []
    tuft = new(16, 16)
    px(tuft, [(5, 11), (5, 10), (6, 9), (7, 11), (7, 10), (9, 11), (9, 10), (10, 9)], G[1])
    px(tuft, [(6, 11), (8, 11), (8, 10), (10, 10)], G[3])
    detail.append(tuft)
    pebble = new(16, 16)
    px(pebble, [(4, 10), (5, 10), (5, 11), (4, 11), (10, 6), (11, 6)], T[2])
    px(pebble, [(4, 9), (5, 9), (10, 5)], T[3])
    px(pebble, [(6, 11), (11, 7), (10, 7)], T[1])
    detail.append(pebble)
    for col in (YELLOW, PINK):
        fl = new(16, 16)
        for cx, cy in ((4, 5), (11, 9), (7, 12)):
            px(fl, [(cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)], col)
            px(fl, [(cx, cy)], B[3])
            px(fl, [(cx, cy + 2), (cx, cy + 3)], G[1])
        detail.append(fl)
    save(strip(detail), "tiles/farm_ground_detail.png", {"frameSize": [16, 16], "tiles": ["tuft", "pebbles", "flowers_yellow", "flowers_pink"]})

    plots = []
    for base, dark, light in ((S[2], S[1], S[3]), (S[1], S[0], S[2])):   # dry (lighter), wet (darker)
        t = new(16, 16, base)
        for y in (3, 7, 11, 15):
            rect(t, 1, y, 14, y, dark)
        for y in (1, 5, 9, 13):
            px(t, [(x, y) for x in (2, 3, 8, 9, 13)], light)
        rect(t, 0, 0, 0, 15, dark)
        rect(t, 15, 0, 15, 15, dark)
        rect(t, 0, 0, 15, 0, dark)
        plots.append(t)
    save(strip(plots), "tiles/farm_plots.png", {"frameSize": [16, 16], "tiles": ["soil_dry", "soil_wet"]})


def backdrop():
    w, h = 640, 48
    img = new(w, h, K[2])
    rect(img, 0, 0, w, 13, K[1])
    for x in range(0, w, 2):                              # dither between the two sky tones (allowed on sky)
        px(img, [(x, 14), (x + 1, 15)], K[1])
    rng = random.Random(5)
    for cx in range(-40, w + 60, 90):                     # far hills
        r = rng.randint(50, 80)
        ellipse(img, cx - r, 30 - rng.randint(4, 12), cx + r, 110, G[1])
    for cx in range(-20, w + 60, 26):                     # forest line
        r = rng.randint(9, 14)
        ellipse(img, cx - r, 36 - rng.randint(0, 5), cx + r, 70, G[0])
    rect(img, 0, 44, w, h, G[0])
    save(img, "tiles/backdrop_hills.png")


# ------------------------------------------------------------------ crops
def frond(img, x, y, dx, length, cols):
    """A feathery leaf: a stem leaning by dx with short side leaflets; lit from the top-left."""
    for i in range(length):
        sx = x + round(dx * i / max(1, length - 1))
        sy = y - i
        px(img, [(sx, sy)], cols[1])
        if i % 2 == 1 and i < length - 1:
            px(img, [(sx - 1, sy)], cols[2])
            px(img, [(sx + 1, sy)], cols[0])
    px(img, [(x + dx, y - length)], cols[2])


def crop_frames(kind):
    f = [new(16, 32) for _ in range(7)]
    base_y = 28
    green = (G[0], G[1], G[3])
    # 0 seed: a small mound
    px(f[0], [(7, base_y), (8, base_y), (9, base_y)], S[3])
    px(f[0], [(8, base_y - 1)], S[4])
    px(f[0], [(7, base_y + 1), (8, base_y + 1), (9, base_y + 1)], S[0])
    # 1 sprout
    px(f[1], [(8, base_y), (8, base_y - 1), (8, base_y - 2)], G[2])
    px(f[1], [(7, base_y - 3), (6, base_y - 3)], G[3])
    px(f[1], [(9, base_y - 3), (10, base_y - 4)], G[1])
    if kind == "carrot":
        for i, (rx, ry, n, ln) in enumerate(((2, 2, 3, 5), (4, 3, 5, 8), (5, 5, 7, 11))):   # young, growing, mature
            fr = f[2 + i]
            cy = base_y - 2 - ry
            ellipse(fr, 8 - rx, cy - ry, 8 + rx, cy + ry, G[1])           # leafy clump, readable on soil
            ellipse(fr, 8 - rx, cy - ry, 8 + rx - 2, cy + ry - 2, G[2])
            px(fr, [(8 + rx - 1, cy + ry - 1), (8 + rx, cy + 1), (8 + rx - 1, cy + ry)], G[0])
            spread = [(-3, ln - 2), (-1, ln), (1, ln), (3, ln - 2), (-5, ln - 4), (5, ln - 4), (0, ln + 1)][:n]
            for dx, l in spread:
                frond(fr, 8, base_y - 1, dx, l, green)
        m = f[4]                                                       # carrot shoulder shows at maturity
        px(m, [(7, base_y), (8, base_y), (9, base_y), (7, base_y - 1), (8, base_y - 1)], ORANGE)
        px(m, [(9, base_y - 1), (9, base_y + 1), (8, base_y + 1)], RED)
        px(m, [(7, base_y - 1)], YELLOW)
        w_ = f[6]                                                      # withered: brown, drooping
        for dx, l in ((-4, 5), (-2, 6), (2, 6), (4, 5)):
            frond(w_, 8, base_y - 1, dx * 2 if abs(dx) > 2 else dx, l - 2, (W[1], S[2], S[3]))
    else:                                                              # wheat
        for i, (n, ln, head) in enumerate(((3, 6, 0), (5, 11, 0), (5, 14, 5))):
            fr = f[2 + i]
            xs = [8, 5, 11, 3, 13][:n]
            for j, x in enumerate(xs):
                lean = (-1 if x < 8 else 1 if x > 8 else 0)
                stem = G[2] if not head else S[4]
                shade = G[1] if not head else S[3]
                for k in range(ln - j % 2):
                    px(fr, [(x + (lean if k > ln // 2 else 0), base_y - k)], stem if (x <= 8) else shade)
                if head:
                    hx = x + lean
                    top = base_y - (ln - j % 2)
                    for k in range(head):
                        px(fr, [(hx, top - k)], YELLOW)
                        px(fr, [(hx + 1, top - k)], S[4] if k % 2 else ORANGE)
                        px(fr, [(hx - 1, top - k)], AMBER if k % 2 else YELLOW)
        w_ = f[6]
        for x, l in ((5, 6), (8, 8), (11, 5)):
            for k in range(l):
                px(w_, [(x + (k // 3) * (1 if x > 6 else -1), base_y - k)], S[2] if k % 2 else W[1])
            px(w_, [(x + 2, base_y - l + 1), (x + 3, base_y - l + 2)], S[3])
    # 5 harvested: a dimple of turned soil
    px(f[5], [(6, base_y), (7, base_y), (8, base_y), (9, base_y), (10, base_y)], S[0])
    px(f[5], [(7, base_y - 1), (8, base_y - 1), (9, base_y - 1)], S[1])
    px(f[5], [(6, base_y + 1), (10, base_y + 1)], S[3])
    return f


def crops():
    for kind in ("carrot", "wheat"):
        save(strip(crop_frames(kind)), f"crops/plant_{kind}.png",
             {"frameSize": [16, 32], "frames": [f"stage_{i}" for i in range(7)]})


# ------------------------------------------------------------------ characters
def player_frame(facing, leg=0, bob=0):
    """Original farmer design: wide straw hat, blue tunic, brown trousers. 32x32, feet at the bottom centre."""
    img = new(32, 32)
    y = bob
    skin, skin_sh = B[3], B[2]
    # legs and boots (leg: -1 left forward, 0 standing, 1 right forward)
    lx, rx = 12, 17
    for x, fwd in ((lx, leg == -1), (rx, leg == 1)):
        top = 23
        bottom = 28 - (1 if fwd else 0)
        rect(img, x, top, x + 2, bottom, W[2] if x == lx else W[1])
        rect(img, x, bottom, x + 2, bottom + 1, W[0])
    if facing == "e":                                    # side view: legs overlap, stride shows
        img = new(32, 32)
        off = leg * 2
        rect(img, 13 + off, 23, 15 + off, 28, W[2]); rect(img, 13 + off, 28, 16 + off, 29, W[0])
        rect(img, 16 - off, 23, 18 - off, 28, W[1]); rect(img, 16 - off, 28, 19 - off, 29, W[0])
    # tunic
    x0, x1 = (11, 20) if facing != "e" else (12, 19)
    rect(img, x0, 15 + y, x1, 23, K[1])
    rect(img, x1 - 2, 16 + y, x1, 23, K[0])               # shade on the right
    rect(img, x0, 21, x1, 21, W[1])                        # belt
    px(img, [(x0 + 1, 16 + y), (x0 + 2, 16 + y), (x0 + 1, 17 + y)], K[2])
    # arms and hands
    if facing == "e":
        rect(img, 15, 16 + y, 17, 21 + y, K[0]); rect(img, 15, 21 + y, 17, 22 + y, skin)
    else:
        rect(img, x0 - 2, 16 + y, x0 - 1, 21 + y, K[1]); rect(img, x0 - 2, 21 + y, x0 - 1, 22 + y, skin)
        rect(img, x1 + 1, 16 + y, x1 + 2, 21 + y, K[0]); rect(img, x1 + 1, 21 + y, x1 + 2, 22 + y, skin_sh)
    # head
    hx0, hx1 = (10, 21) if facing != "e" else (11, 21)
    ellipse(img, hx0, 5 + y, hx1, 15 + y, skin)
    if facing == "n":
        ellipse(img, hx0, 5 + y, hx1, 15 + y, W[1])       # back of the head: hair
        px(img, [(hx0 + 3, 13 + y), (hx0 + 4, 14 + y), (hx1 - 3, 13 + y)], W[2])
    else:
        rect(img, hx1 - 2, 9 + y, hx1 - 1, 13 + y, skin_sh)
        if facing == "s":
            px(img, [(13, 11 + y), (13, 12 + y), (18, 11 + y), (18, 12 + y)], OUT)
            px(img, [(12, 13 + y), (19, 13 + y)], PINK)
            rect(img, hx0, 7 + y, hx0 + 1, 10 + y, W[1]); rect(img, hx1 - 1, 7 + y, hx1, 10 + y, W[1])
        else:
            px(img, [(18, 11 + y), (18, 12 + y)], OUT)
            px(img, [(19, 13 + y)], PINK)
            rect(img, hx0, 7 + y, hx0 + 3, 13 + y, W[1])   # hair at the back of the head
    # straw hat: wide brim, crown, band
    rect(img, 7, 6 + y, 24, 7 + y, S[4])
    rect(img, 8, 8 + y, 23, 8 + y, S[3])
    rect(img, 11, 2 + y, 20, 5 + y, S[4])
    rect(img, 11, 5 + y, 20, 5 + y, RED)
    px(img, [(12, 3 + y), (13, 3 + y), (12, 4 + y), (8, 6 + y), (9, 6 + y)], AMBER)
    rect(img, 18, 2 + y, 20, 4 + y, S[3])
    px(img, [(11, 2 + y), (20, 2 + y)], CLEAR)
    return outline(img)


def player():
    frames, anims, i = [], {}, 0
    for facing in ("s", "n", "e"):
        idle = [player_frame(facing, 0, b) for b in (0, 0, 1, 1)]
        walk = [player_frame(facing, l, b) for l, b in ((-1, 0), (0, 1), (1, 0), (1, 0), (0, 1), (-1, 0))]
        for name, fr, fps in ((f"idle_{facing}", idle, 5), (f"walk_{facing}", walk, 10)):
            anims[name] = {"from": i, "to": i + len(fr) - 1, "fps": fps}
            frames += fr
            i += len(fr)
    save(strip(frames), "characters/player.png", {"frameSize": [32, 32], "animations": anims})


def chicken_frame(bob=0, peck=0):
    img = new(16, 16)
    ellipse(img, 3, 7, 11, 13, B[3])                       # body
    px(img, [(9, 12), (10, 11), (10, 12), (8, 13), (9, 13)], T[3])
    px(img, [(3, 8), (2, 7), (2, 8), (3, 7)], T[3])        # tail
    hy = 4 + bob + peck * 3
    hx = 10 + peck
    rect(img, hx, hy, hx + 2, hy + 3, B[3])                # head
    px(img, [(hx, hy - 1), (hx + 1, hy - 1), (hx + 1, hy - 2)], RED)   # comb
    px(img, [(hx + 3, hy + 1), (hx + 3, hy + 2)], ORANGE)  # beak
    px(img, [(hx + 2, hy + 3)], RED)                       # wattle
    px(img, [(hx + 1, hy + 1)], OUT)                       # eye
    px(img, [(5, 9), (6, 9), (6, 10), (7, 10)], T[3])      # wing
    px(img, [(6, 14), (8, 14)], ORANGE)                    # legs
    return outline(img)


def chicken():
    idle = [chicken_frame(0), chicken_frame(0), chicken_frame(1), chicken_frame(0, 1)]
    save(strip(idle), "animals/animal_chicken.png", {"frameSize": [16, 16], "animations": {"idle_e": {"from": 0, "to": 3, "fps": 5}}})


def rootling_frame(sway=0, blink=False):
    """Original Tree Spirit (Rootling): a seed-shaped bark body, moss shoulders, a forked root-sprout
    on the head, small glowing eyes, and a little gourd for carrying water. 24x24."""
    img = new(24, 24)
    ellipse(img, 5, 8, 18, 21, W[2])                       # seed-shaped body
    ellipse(img, 7, 6, 16, 14, W[2])
    ellipse(img, 7, 9, 12, 14, W[3])                       # light from the top-left
    px(img, [(8, 7), (9, 7), (9, 6), (10, 6)], W[3])
    for yy in range(12, 21):                               # bark shade on the lower right
        px(img, [(17 - (yy > 18), yy), (16 - (yy > 18), yy)], W[1])
    px(img, [(13, 19), (14, 19), (14, 20), (12, 20), (13, 20)], W[1])
    px(img, [(9, 17), (9, 18), (10, 18), (14, 15), (14, 16)], W[1])       # bark grain
    px(img, [(6, 9), (7, 8), (6, 10), (5, 10), (7, 9), (16, 8), (17, 9), (17, 10), (16, 9)], G[1])   # moss
    px(img, [(6, 8), (7, 7), (16, 7)], G[3])
    if not blink:
        px(img, [(9, 12), (9, 13), (14, 12), (14, 13)], TEAL)             # glowing eyes
        px(img, [(10, 12), (15, 12)], K[3])
    else:
        px(img, [(9, 13), (10, 13), (14, 13), (15, 13)], W[0])
    px(img, [(11, 16), (12, 16)], W[0])                    # small mouth
    px(img, [(8, 22), (9, 22), (14, 22), (15, 22)], W[1])  # feet
    sx = 12 + sway                                         # forked sprout: the Rootling's head growth
    px(img, [(12, 5), (12, 4), (sx, 3), (sx, 2)], G[1])
    px(img, [(sx - 1, 2), (sx - 2, 1), (sx - 3, 1)], G[3])
    px(img, [(sx + 1, 2), (sx + 2, 1), (sx + 2, 0)], G[2])
    px(img, [(sx - 3, 0), (sx - 2, 0)], G[4])
    px(img, [(4, 15), (3, 16), (3, 17)], W[1])             # left root arm
    px(img, [(19, 15), (20, 16)], W[1])                    # right arm holding the gourd
    ellipse(img, 19, 16, 22, 20, S[4])
    px(img, [(21, 19), (22, 18), (21, 20)], S[3])
    px(img, [(20, 15)], S[3])
    px(img, [(20, 17)], AMBER)
    return outline(img)


def rootling_m0_only():
    idle = [rootling_frame(0), rootling_frame(1), rootling_frame(0), rootling_frame(-1, blink=True)]
    save(strip(idle), "spirits/spirit_rootling.png", {"frameSize": [24, 24], "animations": {"idle_s": {"from": 0, "to": 3, "fps": 5}}})


# ------------------------------------------------------------------ buildings and props
def farmhouse():
    """Original cottage: plaster walls, timber frame, stone footing, terracotta roof. Base and roof are separate."""
    base = new(96, 96)
    rng = random.Random(3)
    rect(base, 6, 44, 89, 95, B[3])                        # plaster wall
    clusters(base, rng, [B[2]], 40, 8, 46, 80, 40)
    rect(base, 6, 86, 89, 95, T[2])                        # stone footing
    for x in range(6, 90, 8):
        rect(base, x, 86, x, 95, T[1])
    rect(base, 6, 90, 89, 90, T[1])
    clusters(base, rng, [T[3]], 14, 8, 87, 80, 8)
    for x in (6, 30, 62, 87):                              # timber posts
        rect(base, x, 44, x + 2, 86, W[1])
        rect(base, x, 44, x, 86, W[2])
    rect(base, 6, 44, 89, 46, W[1])                        # top beam (under the eave shadow)
    rect(base, 6, 47, 89, 48, W[0])
    rect(base, 33, 64, 61, 65, W[1])
    rect(base, 40, 62, 55, 95, W[0])                       # door frame
    rect(base, 42, 64, 53, 95, W[2])
    rect(base, 42, 64, 44, 95, W[3])
    for x in (46, 50):
        rect(base, x, 64, x, 95, W[1])
    px(base, [(51, 80), (52, 80), (51, 81), (52, 81)], AMBER)
    rect(base, 38, 93, 57, 95, T[3])                       # doorstep
    for wx in (12, 68):                                    # two windows with flower boxes
        rect(base, wx, 56, wx + 15, 72, W[1])
        rect(base, wx + 2, 58, wx + 13, 70, K[1])
        rect(base, wx + 2, 58, wx + 7, 63, K[2])
        px(base, [(wx + 3, 59), (wx + 4, 59), (wx + 3, 60)], K[3])
        rect(base, wx + 7, 58, wx + 8, 70, W[1])
        rect(base, wx + 2, 64, wx + 13, 64, W[1])
        rect(base, wx - 1, 73, wx + 16, 76, W[2])
        rect(base, wx - 1, 76, wx + 16, 76, W[0])
        for i, c in enumerate((RED, YELLOW, PINK, RED, YELLOW)):
            cx = wx + 1 + i * 3
            px(base, [(cx, 71), (cx + 1, 71), (cx, 72), (cx + 1, 72)], c)
            px(base, [(cx + 2, 72), (cx - 1, 72)], G[1])
    save(base, "buildings/farmhouse_base.png")

    roof = new(96, 96)
    for row in range(8):                                   # terracotta rows, widening toward the eave
        y0 = 8 + row * 5
        inset = 10 - row
        rect(roof, inset, y0, 95 - inset, y0 + 4, B[1])
        rect(roof, inset, y0 + 4, 95 - inset, y0 + 4, B[0])
        for x in range(inset + (3 if row % 2 else 0), 96 - inset, 6):
            rect(roof, x, y0, x, y0 + 3, B[0])
            px(roof, [(x + 1, y0), (x + 2, y0), (x + 1, y0 + 1)], B[2])
    rect(roof, 2, 48, 93, 50, B[0])                        # eave
    rect(roof, 10, 5, 85, 7, W[1])                         # ridge beam
    rect(roof, 10, 5, 85, 5, W[2])
    rect(roof, 66, 0, 77, 16, T[2])                        # chimney
    rect(roof, 74, 0, 77, 16, T[1])
    rect(roof, 65, 0, 78, 2, T[3])
    px(roof, [(68, 6), (69, 6), (68, 7), (71, 11), (72, 11)], T[3])
    save(roof, "buildings/farmhouse_roof.png")


def props():
    fence = new(16, 16)
    rect(fence, 0, 6, 15, 7, W[2]); rect(fence, 0, 7, 15, 7, W[1])
    rect(fence, 0, 11, 15, 12, W[2]); rect(fence, 0, 12, 15, 12, W[1])
    rect(fence, 6, 2, 9, 15, W[3]); rect(fence, 8, 3, 9, 15, W[2]); rect(fence, 6, 2, 9, 2, S[4])
    rect(fence, 6, 15, 9, 15, W[0])
    save(fence, "props/fence_h.png")
    bush = new(16, 16)
    ellipse(bush, 1, 4, 14, 15, G[1])
    ellipse(bush, 2, 4, 10, 11, G[2])
    px(bush, [(4, 6), (5, 6), (5, 5), (4, 7)], G[3])
    px(bush, [(11, 13), (12, 12), (12, 13), (10, 14), (11, 14)], G[0])
    px(bush, [(8, 8), (9, 8), (11, 6)], PINK)
    save(bush, "props/bush.png")
    shadow = new(16, 8)                                    # flat cast shadow, drawn at 35% by the engine
    ellipse(shadow, 1, 1, 14, 6, OUT)
    save(shadow, "props/shadow_small.png")
    sparkle = strip([new(16, 16), new(16, 16)])
    px(sparkle, [(4, 3), (3, 4), (4, 4), (5, 4), (4, 5), (11, 9)], AMBER)
    px(sparkle, [(16 + 11, 8), (16 + 10, 9), (16 + 11, 9), (16 + 12, 9), (16 + 11, 10), (16 + 4, 4)], AMBER)
    save(sparkle, "fx/mature_sparkle.png", {"frameSize": [16, 16], "animations": {"sparkle": {"from": 0, "to": 1, "fps": 4}}})


# ------------------------------------------------------------------ M1 additions
def mara_frame(bob=0):
    """Mara Oakhollow, innkeeper (original design): auburn hair in a bun, green dress, cream apron."""
    img = new(32, 32)
    y = bob
    rect(img, 10, 16 + y, 21, 28, G[1])                    # dress
    rect(img, 19, 17 + y, 21, 28, G[0])
    rect(img, 12, 28, 14, 29, W[0]); rect(img, 17, 28, 19, 29, W[0])   # shoes
    rect(img, 12, 18 + y, 19, 27, B[3])                    # apron
    rect(img, 18, 19 + y, 19, 27, B[2])
    rect(img, 12, 18 + y, 19, 18 + y, T[3])
    rect(img, 8, 17 + y, 9, 22 + y, G[1]); rect(img, 8, 22 + y, 9, 23 + y, B[3])     # arms
    rect(img, 22, 17 + y, 23, 22 + y, G[0]); rect(img, 22, 22 + y, 23, 23 + y, B[2])
    ellipse(img, 10, 5 + y, 21, 15 + y, B[3])              # head
    rect(img, 19, 9 + y, 20, 13 + y, B[2])
    rect(img, 10, 4 + y, 21, 8 + y, B[1])                  # hair
    rect(img, 10, 8 + y, 11, 12 + y, B[1]); rect(img, 20, 8 + y, 21, 11 + y, B[0])
    ellipse(img, 13, 0 + y, 18, 4 + y, B[1])               # bun
    px(img, [(14, 1 + y), (15, 1 + y), (12, 5 + y), (13, 5 + y)], B[2])
    px(img, [(17, 3 + y), (18, 2 + y), (19, 6 + y), (20, 6 + y)], B[0])
    px(img, [(13, 11 + y), (13, 12 + y), (18, 11 + y), (18, 12 + y)], OUT)
    px(img, [(12, 13 + y), (19, 13 + y)], PINK)
    px(img, [(15, 14 + y), (16, 14 + y)], B[0])
    return outline(img)


def npcs():
    idle = [mara_frame(b) for b in (0, 0, 1, 1)]
    save(strip(idle), "characters/npc_mara.png", {"frameSize": [32, 32], "animations": {"idle_s": {"from": 0, "to": 3, "fps": 5}}})


def m1_buildings():
    well = new(32, 32)                                     # stone well with a small roof
    ellipse(well, 3, 14, 28, 31, T[2])
    ellipse(well, 3, 12, 28, 26, T[3])
    ellipse(well, 7, 14, 24, 23, K[0])
    ellipse(well, 9, 15, 18, 20, K[1])
    for x in range(5, 27, 5):
        rect(well, x, 26, x, 30, T[1])
    rect(well, 4, 27, 27, 27, T[1])
    rect(well, 4, 4, 6, 20, W[1]); rect(well, 25, 4, 27, 20, W[1])
    rect(well, 4, 4, 4, 20, W[2]); rect(well, 25, 4, 25, 20, W[2])
    rect(well, 1, 1, 30, 5, B[1]); rect(well, 1, 5, 30, 5, B[0]); rect(well, 3, 0, 28, 0, B[2])
    for x in range(4, 30, 5):
        rect(well, x, 1, x, 4, B[0])
    rect(well, 15, 6, 15, 13, S[4]); rect(well, 13, 13, 17, 16, W[2]); rect(well, 13, 16, 17, 16, W[0])
    save(well, "buildings/bld_well.png")

    table = new(32, 32)                                    # Merge Table: heavy bench with a faintly glowing ring
    rect(table, 2, 12, 29, 22, W[2])
    rect(table, 2, 12, 29, 13, W[3])
    rect(table, 2, 21, 29, 23, W[1])
    for x in (9, 16, 23):
        rect(table, x, 14, x, 20, W[1])
    rect(table, 3, 24, 6, 30, W[1]); rect(table, 25, 24, 28, 30, W[1])
    rect(table, 3, 24, 3, 30, W[2]); rect(table, 25, 24, 25, 30, W[2])
    rect(table, 6, 26, 25, 27, W[0])
    ring = [(12, 14), (13, 13), (14, 13), (15, 13), (16, 13), (17, 13), (18, 13), (19, 14), (20, 15), (20, 16), (20, 17),
            (19, 18), (18, 19), (17, 19), (16, 19), (15, 19), (14, 19), (13, 19), (12, 18), (11, 17), (11, 16), (11, 15)]
    px(table, ring, TEAL)
    px(table, [(15, 15), (16, 15), (15, 16), (16, 17), (16, 16)], AMBER)
    rect(table, 23, 8, 26, 12, S[4]); rect(table, 25, 8, 26, 12, S[3]); px(table, [(24, 7), (25, 7)], W[1])   # jar
    rect(table, 4, 9, 8, 12, T[2]); rect(table, 4, 9, 8, 9, T[3])                                               # mortar
    save(table, "buildings/bld_merge_table.png")

    stall = new(48, 48)                                    # Mara's stall at the farm gate
    rect(stall, 3, 22, 44, 44, W[2])
    rect(stall, 3, 22, 44, 24, W[3])
    rect(stall, 3, 43, 44, 45, W[0])
    for x in range(8, 44, 7):
        rect(stall, x, 26, x, 42, W[1])
    rect(stall, 3, 6, 5, 45, W[1]); rect(stall, 42, 6, 44, 45, W[1])
    for i, x in enumerate(range(0, 48, 6)):               # striped awning
        rect(stall, x, 2, x + 5, 12, RED if i % 2 == 0 else B[3])
        rect(stall, x, 11, x + 5, 12, B[0] if i % 2 == 0 else B[2])
        px(stall, [(x + 1, 13), (x + 2, 13), (x + 3, 13), (x + 4, 13), (x + 2, 14), (x + 3, 14)], RED if i % 2 == 0 else B[3])
    rect(stall, 0, 1, 47, 1, W[1])
    for x, c in ((9, ORANGE), (14, ORANGE), (20, YELLOW), (27, RED), (33, G[3]), (38, ORANGE)):   # goods on the counter
        ellipse(stall, x, 18, x + 4, 22, c)
        px(stall, [(x + 1, 19)], B[3])
    save(stall, "buildings/npc_stall.png")

    board = new(16, 32)                                    # order board
    rect(board, 1, 6, 14, 22, W[2]); rect(board, 1, 6, 14, 7, W[3]); rect(board, 1, 21, 14, 22, W[1])
    rect(board, 3, 22, 4, 31, W[1]); rect(board, 11, 22, 12, 31, W[1])
    rect(board, 0, 4, 15, 5, B[1]); rect(board, 0, 5, 15, 5, B[0])
    for x, y, c in ((3, 9, B[3]), (9, 9, T[3]), (3, 15, T[3]), (9, 15, B[3])):
        rect(board, x, y, x + 3, y + 4, c)
        px(board, [(x + 1, y + 1), (x + 2, y + 1), (x + 1, y + 3)], S[2])
        px(board, [(x + 1, y - 1)], RED)
    save(board, "props/order_board.png")

    sign = new(16, 16)                                     # an untended field site
    rect(sign, 7, 8, 8, 15, W[1])
    rect(sign, 2, 2, 13, 9, W[3]); rect(sign, 2, 9, 13, 9, W[1]); rect(sign, 12, 3, 13, 9, W[2])
    px(sign, [(4, 4), (5, 4), (6, 4), (8, 4), (9, 4), (11, 4), (4, 6), (5, 6), (7, 6), (8, 6), (9, 6), (10, 6)], W[0])
    save(sign, "props/field_sign.png")

    cursor = new(16, 16)                                   # tile cursor: four corner brackets
    for cx, cy, dx, dy in ((0, 0, 1, 1), (15, 0, -1, 1), (0, 15, 1, -1), (15, 15, -1, -1)):
        px(cursor, [(cx, cy), (cx + dx, cy), (cx + 2 * dx, cy), (cx, cy + dy), (cx, cy + 2 * dy)], AMBER)
    save(cursor, "fx/tile_cursor.png")

    weeds = new(16, 16, G[2])                              # untended field ground
    rng = random.Random(21)
    clusters(weeds, rng, [G[1]], 9)
    clusters(weeds, rng, [G[0]], 4)
    clusters(weeds, rng, [S[2]], 3)
    untilled = new(16, 16, S[3])                           # owned but not yet tilled
    clusters(untilled, rng, [S[2]], 6)
    clusters(untilled, rng, [G[1]], 3)
    rect(untilled, 0, 0, 15, 0, S[2]); rect(untilled, 0, 0, 0, 15, S[2])
    save(strip([weeds, untilled]), "tiles/farm_field.png", {"frameSize": [16, 16], "tiles": ["untended", "untilled"]})


def carrot_icon(body, shade, light, leaf=True):
    img = new(16, 16)
    pts = [(9, 5), (10, 5), (8, 6), (9, 6), (10, 6), (11, 6), (7, 7), (8, 7), (9, 7), (10, 7), (6, 8), (7, 8), (8, 8), (9, 8),
           (5, 9), (6, 9), (7, 9), (8, 9), (4, 10), (5, 10), (6, 10), (7, 10), (3, 11), (4, 11), (5, 11), (3, 12), (4, 12)]
    px(img, pts, body)
    px(img, [(11, 6), (10, 7), (9, 8), (8, 9), (7, 10), (5, 11), (4, 12)], shade)
    px(img, [(9, 5), (8, 6), (7, 7), (6, 8)], light)
    if leaf:
        px(img, [(11, 4), (12, 3), (12, 4), (13, 2), (11, 3)], G[2])
        px(img, [(12, 5), (13, 4), (13, 5), (14, 4)], G[1])
        px(img, [(10, 3), (11, 2)], G[3])
    return img


def seed_bag(dot):
    img = new(16, 16)
    rect(img, 4, 6, 11, 13, S[4])
    rect(img, 10, 7, 11, 13, S[3])
    rect(img, 5, 4, 10, 5, S[4]); rect(img, 6, 5, 9, 5, W[1])
    px(img, [(5, 13), (4, 13), (11, 13)], S[3])
    rect(img, 6, 8, 9, 11, B[3])
    px(img, [(7, 9), (8, 9), (7, 10), (8, 10)], dot)
    return outline(img)


def icons():
    save(outline(carrot_icon(ORANGE, RED, YELLOW)), "items/crop_carrot.png")
    prem = carrot_icon(ORANGE, RED, YELLOW)
    px(prem, [(3, 4), (2, 5), (3, 5), (4, 5), (3, 6)], AMBER)             # a sparkle marks the premium grade
    save(outline(prem), "items/merged_carrot_premium.png")
    gold = carrot_icon(YELLOW, ORANGE, AMBER)
    px(gold, [(3, 4), (2, 5), (3, 5), (4, 5), (3, 6), (12, 11), (11, 12), (12, 12), (13, 12), (12, 13)], AMBER)
    save(outline(gold), "items/merged_carrot_golden.png")
    wheat = new(16, 16)
    for x, top in ((5, 3), (8, 2), (11, 3)):
        rect(wheat, x, top + 5, x, 13, S[4])
        for k in range(5):
            px(wheat, [(x, top + k)], YELLOW)
            px(wheat, [(x + 1, top + k)], ORANGE if k % 2 else S[4])
            px(wheat, [(x - 1, top + k)], AMBER if k % 2 else YELLOW)
    rect(wheat, 4, 10, 12, 11, RED)
    save(outline(wheat), "items/crop_wheat.png")
    save(seed_bag(ORANGE), "items/seed_carrot.png")
    save(seed_bag(YELLOW), "items/seed_wheat.png")
    coin = new(8, 8)
    ellipse(coin, 1, 1, 6, 6, YELLOW)
    px(coin, [(5, 5), (6, 4), (5, 6), (4, 6), (6, 3)], ORANGE)
    px(coin, [(2, 2), (3, 2), (2, 3)], AMBER)
    save(outline(coin), "ui/coin.png")
    drop = new(8, 8)
    px(drop, [(3, 1), (4, 1), (3, 2), (4, 2), (2, 3), (3, 3), (4, 3), (5, 3), (2, 4), (3, 4), (4, 4), (5, 4), (2, 5), (3, 5), (4, 5), (5, 5), (3, 6), (4, 6)], K[1])
    px(drop, [(3, 3), (3, 4)], K[3])
    save(outline(drop), "ui/water.png")


# ------------------------------------------------------------------ M2 additions
def m2_crops():
    for kind in ("tomato", "sunflower"):
        f = [new(16, 32) for _ in range(7)]
        by = 28
        px(f[0], [(7, by), (8, by), (9, by)], S[3]); px(f[0], [(8, by - 1)], S[4]); px(f[0], [(7, by + 1), (8, by + 1), (9, by + 1)], S[0])
        px(f[1], [(8, by), (8, by - 1), (8, by - 2)], G[2]); px(f[1], [(7, by - 3), (6, by - 3)], G[3]); px(f[1], [(9, by - 3), (10, by - 4)], G[1])
        for i, h in enumerate((7, 12, 17) if kind == "tomato" else (8, 15, 22)):
            fr = f[2 + i]
            rect(fr, 8, by - h, 8, by, G[1])                              # stem
            if kind == "tomato":
                rect(fr, 7, by - h, 7, by, W[2])                          # stake
                for k, yy in enumerate(range(by - 3, by - h, -4)):
                    side = -1 if k % 2 else 1
                    ellipse(fr, 8 + side * 4 - 2, yy - 2, 8 + side * 4 + 2, yy + 1, G[2])
                    px(fr, [(8 + side * 4 - 1, yy - 2), (8 + side * 4, yy - 2)], G[3])
                    px(fr, [(8 + side, yy), (8 + side * 2, yy)], G[1])
                    if i == 2:
                        fx = 8 - side * 3
                        ellipse(fr, fx - 1, yy - 1, fx + 1, yy + 1, RED)
                        px(fr, [(fx - 1, yy - 1)], ORANGE)
            else:
                for k, yy in enumerate(range(by - 3, by - h + 3, -4)):
                    side = -1 if k % 2 else 1
                    px(fr, [(8 + side, yy), (8 + side * 2, yy - 1), (8 + side * 3, yy - 1), (8 + side * 2, yy)], G[2])
                    px(fr, [(8 + side * 3, yy - 2)], G[3])
                top = by - h
                if i == 2:                                               # the flower head
                    ellipse(fr, 4, top - 5, 12, top + 3, YELLOW)
                    px(fr, [(4, top - 1), (12, top - 1), (8, top - 5), (8, top + 3)], ORANGE)
                    ellipse(fr, 6, top - 3, 10, top + 1, W[1])
                    px(fr, [(7, top - 2), (8, top - 2)], W[2])
                else:
                    ellipse(fr, 6, top - 2, 10, top + 1, G[3])
        px(f[5], [(6, by), (7, by), (8, by), (9, by), (10, by)], S[0]); px(f[5], [(7, by - 1), (8, by - 1), (9, by - 1)], S[1])
        w_ = f[6]
        rect(w_, 8, by - 9, 8, by, W[1])
        px(w_, [(9, by - 9), (10, by - 8), (11, by - 7), (11, by - 6), (7, by - 5), (6, by - 4), (5, by - 3)], S[2])
        px(w_, [(11, by - 5), (5, by - 2)], S[3])
        save(strip(f), f"crops/plant_{kind}.png", {"frameSize": [16, 32], "frames": [f"stage_{i}" for i in range(7)]})


def npc_frame(hair, hair_sh, top, top_sh, apron=None, hat=None, glasses=False, bob=0):
    img = new(32, 32)
    y = bob
    rect(img, 10, 16 + y, 21, 28, top); rect(img, 19, 17 + y, 21, 28, top_sh)
    rect(img, 12, 28, 14, 29, W[0]); rect(img, 17, 28, 19, 29, W[0])
    if apron:
        rect(img, 12, 18 + y, 19, 27, apron[0]); rect(img, 18, 19 + y, 19, 27, apron[1])
    rect(img, 8, 17 + y, 9, 22 + y, top); rect(img, 8, 22 + y, 9, 23 + y, B[3])
    rect(img, 22, 17 + y, 23, 22 + y, top_sh); rect(img, 22, 22 + y, 23, 23 + y, B[2])
    ellipse(img, 10, 5 + y, 21, 15 + y, B[3]); rect(img, 19, 9 + y, 20, 13 + y, B[2])
    rect(img, 10, 4 + y, 21, 8 + y, hair); rect(img, 10, 8 + y, 11, 12 + y, hair); rect(img, 20, 8 + y, 21, 11 + y, hair_sh)
    px(img, [(13, 11 + y), (13, 12 + y), (18, 11 + y), (18, 12 + y)], OUT)
    px(img, [(15, 14 + y), (16, 14 + y)], B[0])
    if glasses:
        px(img, [(12, 10 + y), (13, 10 + y), (14, 10 + y), (12, 13 + y), (14, 13 + y), (17, 10 + y), (18, 10 + y), (19, 10 + y), (17, 13 + y), (19, 13 + y), (15, 11 + y), (16, 11 + y)], T[1])
    if hat:
        rect(img, 8, 5 + y, 23, 6 + y, hat[0]); rect(img, 11, 1 + y, 20, 4 + y, hat[0]); rect(img, 11, 4 + y, 20, 4 + y, hat[1]); rect(img, 18, 1 + y, 20, 3 + y, hat[1])
    return outline(img)


def m2_npcs():
    tobin = [npc_frame(W[1], W[0], PURPLE, K[0], hat=(W[2], W[1]), bob=b) for b in (0, 0, 1, 1)]
    save(strip(tobin), "characters/npc_tobin.png", {"frameSize": [32, 32], "animations": {"idle_s": {"from": 0, "to": 3, "fps": 5}}})
    ilse = [npc_frame(T[2], T[1], K[0], OUT, apron=(T[3], T[2]), glasses=True, bob=b) for b in (0, 0, 1, 1)]
    save(strip(ilse), "characters/npc_ilse.png", {"frameSize": [32, 32], "animations": {"idle_s": {"from": 0, "to": 3, "fps": 5}}})


def stall_like(a, a_sh, b, b_sh, goods, name):
    stall = new(48, 48)
    rect(stall, 3, 22, 44, 44, W[2]); rect(stall, 3, 22, 44, 24, W[3]); rect(stall, 3, 43, 44, 45, W[0])
    for x in range(8, 44, 7):
        rect(stall, x, 26, x, 42, W[1])
    rect(stall, 3, 6, 5, 45, W[1]); rect(stall, 42, 6, 44, 45, W[1])
    for i, x in enumerate(range(0, 48, 6)):
        rect(stall, x, 2, x + 5, 12, a if i % 2 == 0 else b)
        rect(stall, x, 11, x + 5, 12, a_sh if i % 2 == 0 else b_sh)
        px(stall, [(x + 1, 13), (x + 2, 13), (x + 3, 13), (x + 4, 13), (x + 2, 14), (x + 3, 14)], a if i % 2 == 0 else b)
    rect(stall, 0, 1, 47, 1, W[1])
    for x, c in goods:
        ellipse(stall, x, 18, x + 4, 22, c); px(stall, [(x + 1, 19)], B[3])
    save(stall, name)


def animal_frames(kind):
    out = []
    for bob in (0, 0, 1, 0):
        img = new(32, 32)
        if kind == "cow":
            body, sh, spot = B[3], T[3], W[1]
            ellipse(img, 3, 10, 26, 25, body); rect(img, 20, 12, 25, 24, sh)
            ellipse(img, 8, 12, 14, 18, spot); ellipse(img, 16, 17, 21, 22, spot)
            for x in (6, 11, 18, 22):
                rect(img, x, 24, x + 2, 29, body if x < 15 else sh); rect(img, x, 29, x + 2, 30, W[0])
            rect(img, 22, 6 + bob, 30, 16 + bob, body); rect(img, 24, 13 + bob, 30, 16 + bob, PINK)
            px(img, [(25, 15 + bob), (29, 15 + bob)], B[0]); px(img, [(24, 9 + bob), (28, 9 + bob)], OUT)
            px(img, [(22, 5 + bob), (21, 4 + bob), (30, 5 + bob), (31, 4 + bob)], T[3]); rect(img, 22, 6 + bob, 23, 8 + bob, spot)
            px(img, [(2, 12), (1, 13), (1, 14), (1, 15)], spot); rect(img, 12, 25, 16, 26, PINK)
        else:
            body, sh = T[3], T[2]
            for cx, cy in ((7, 15), (13, 12), (19, 13), (22, 17), (9, 20), (16, 20)):
                ellipse(img, cx - 6, cy - 5, cx + 6, cy + 5, body)
            for cx, cy in ((20, 20), (23, 17)):
                ellipse(img, cx - 3, cy - 2, cx + 3, cy + 3, sh)
            px(img, [(8, 12), (9, 12), (14, 10), (15, 10), (9, 13)], K[3])
            for x in (7, 12, 18, 22):
                rect(img, x, 24, x + 1, 29, W[1]); rect(img, x, 29, x + 1, 30, W[0])
            rect(img, 23, 9 + bob, 29, 17 + bob, W[1]); rect(img, 27, 10 + bob, 29, 17 + bob, W[0])
            px(img, [(24, 12 + bob), (27, 12 + bob)], B[3]); px(img, [(22, 10 + bob), (30, 10 + bob)], W[1])
            ellipse(img, 22, 5 + bob, 30, 10 + bob, body)
        out.append(outline(img))
    return out


def m2_buildings():
    stall_like(PURPLE, K[0], S[4], S[3], [(9, YELLOW), (15, G[3]), (21, PINK), (27, YELLOW), (33, ORANGE), (38, TEAL)], "buildings/npc_cart_tobin.png")
    stall_like(K[0], OUT, T[3], T[2], [(10, T[3]), (17, K[2]), (24, AMBER), (31, T[3]), (37, K[1])], "buildings/npc_stall_ilse.png")
    for kind in ("cow", "sheep"):
        save(strip(animal_frames(kind)), f"animals/animal_{kind}.png", {"frameSize": [32, 32], "animations": {"idle_e": {"from": 0, "to": 3, "fps": 5}}})

    def shed(w, h, wall, wall_sh, roof_c, roof_sh, name, door_w):
        img = new(w, h)
        top = h * 2 // 5
        rect(img, 3, top, w - 4, h - 1, wall); rect(img, w - 12, top, w - 4, h - 1, wall_sh)
        for x in range(3, w - 3, 5):
            rect(img, x, top, x, h - 1, wall_sh)
        rect(img, 3, h - 4, w - 4, h - 1, T[1]); rect(img, 3, h - 4, w - 4, h - 4, T[2])
        dx = (w - door_w) // 2
        rect(img, dx, h - 5 - door_w, dx + door_w, h - 1, W[0]); rect(img, dx + 2, h - 3 - door_w, dx + door_w - 2, h - 1, W[1])
        px(img, [(dx + door_w - 4, h - 8)], AMBER)
        for row in range(top // 4 + 1):
            y0 = 1 + row * 4
            inset = max(0, 6 - row * 2)
            rect(img, inset, y0, w - 1 - inset, y0 + 3, roof_c); rect(img, inset, y0 + 3, w - 1 - inset, y0 + 3, roof_sh)
            for x in range(inset + (2 if row % 2 else 0), w - inset, 5):
                rect(img, x, y0, x, y0 + 2, roof_sh)
        if w < 60:
            rect(img, 6, top + 6, 13, top + 11, W[0]); rect(img, 7, top + 7, 12, top + 10, K[1])
        else:
            rect(img, 8, top + 8, 19, top + 17, W[0]); rect(img, 9, top + 9, 18, top + 16, K[1])
            rect(img, w - 20, top + 8, w - 9, top + 17, W[0]); rect(img, w - 19, top + 9, w - 10, top + 16, K[0])
        save(img, name)

    shed(48, 48, W[3], W[2], B[1], B[0], "buildings/bld_coop.png", 10)
    shed(64, 64, B[0], W[1], T[2], T[1], "buildings/bld_barn.png", 18)
    binp = new(16, 16)
    rect(binp, 1, 5, 14, 14, W[2]); rect(binp, 1, 5, 14, 6, W[3]); rect(binp, 11, 7, 14, 14, W[1]); rect(binp, 1, 14, 14, 15, W[0])
    for x in (5, 10):
        rect(binp, x, 7, x, 13, W[1])
    rect(binp, 0, 3, 15, 4, B[1]); rect(binp, 0, 4, 15, 4, B[0])
    px(binp, [(7, 9), (8, 9), (7, 10), (8, 10)], AMBER)
    save(binp, "props/shipping_bin.png")
    pad = new(16, 16, S[3])
    rng = random.Random(8)
    clusters(pad, rng, [S[2]], 5); clusters(pad, rng, [S[4]], 3)
    px(pad, [(x, 0) for x in range(0, 16, 2)] + [(0, y) for y in range(0, 16, 2)], W[1])
    save(pad, "tiles/build_pad.png", {"frameSize": [16, 16], "tiles": ["pad"]})
    ready = strip([new(16, 16), new(16, 16)])
    for off, dy in ((0, 0), (16, -1)):
        px(ready, [(off + 7, 4 + dy), (off + 8, 4 + dy), (off + 7, 5 + dy), (off + 8, 5 + dy), (off + 7, 6 + dy), (off + 8, 6 + dy), (off + 7, 7 + dy), (off + 8, 7 + dy), (off + 7, 10 + dy), (off + 8, 10 + dy)], AMBER)
    save(outline(ready), "fx/ready_mark.png", {"frameSize": [16, 16], "animations": {"sparkle": {"from": 0, "to": 1, "fps": 3}}})


def m2_icons():
    def blob(c, sh, hi, leaf=None, speck=None, tall=False):
        img = new(16, 16)
        ellipse(img, 4, 3 if tall else 5, 11, 13, c)
        px(img, [(10, 11), (11, 10), (10, 12), (9, 13), (8, 13), (11, 9)], sh)
        px(img, [(5, 6 if not tall else 5), (6, 5 if not tall else 4), (5, 7 if not tall else 6)], hi)
        if leaf:
            px(img, [(7, 4), (8, 4), (6, 3), (9, 3), (8, 5)] if not tall else [], leaf)
        for pt in speck or []:
            px(img, [pt], sh)
        return img
    save(outline(blob(RED, B[0], PINK, leaf=G[1])), "items/crop_tomato.png")
    t2 = blob(RED, B[0], PINK, leaf=G[1]); px(t2, [(2, 2), (1, 3), (2, 3), (3, 3), (2, 4)], AMBER); save(outline(t2), "items/merged_tomato_premium.png")
    t3 = blob(YELLOW, ORANGE, AMBER, leaf=G[1]); px(t3, [(2, 2), (1, 3), (2, 3), (3, 3), (2, 4), (13, 11), (12, 12), (13, 12), (14, 12), (13, 13)], AMBER); save(outline(t3), "items/merged_tomato_golden.png")
    save(outline(blob(B[3], T[3], K[3], tall=True)), "items/prod_egg.png")
    save(outline(blob(B[3], T[3], K[3], tall=True, speck=[(6, 7), (9, 6), (7, 10), (9, 10), (6, 11)])), "items/merged_egg_speckled.png")
    save(outline(blob(YELLOW, ORANGE, AMBER, tall=True)), "items/merged_egg_golden.png")
    save(outline(blob(T[3], T[2], K[3])), "items/prod_wool.png")

    def bottle(liquid, cap):
        img = new(16, 16)
        rect(img, 5, 6, 10, 13, K[3]); rect(img, 5, 8, 10, 13, liquid); rect(img, 9, 8, 10, 13, T[3]); rect(img, 6, 3, 9, 5, K[3]); rect(img, 6, 2, 9, 2, cap)
        px(img, [(6, 7)], K[2])
        return outline(img)
    save(bottle(B[3], RED), "items/prod_milk.png")
    save(bottle(AMBER, YELLOW), "items/merged_cream.png")
    bale = new(16, 16)
    rect(bale, 3, 5, 12, 12, T[3]); rect(bale, 10, 6, 12, 12, T[2]); rect(bale, 3, 7, 12, 7, RED); rect(bale, 3, 10, 12, 10, RED); px(bale, [(4, 6), (5, 6)], K[3])
    save(outline(bale), "items/merged_wool_bale_fine.png")
    for name, bunch in (("crop_sunflower", 1), ("merged_sun_bouquet", 3)):
        img = new(16, 16)
        for i in range(bunch):
            cx = 8 if bunch == 1 else 4 + i * 4
            cy = 6 if bunch == 1 else 5 + (i % 2)
            rect(img, cx, cy + 2, cx, 13, G[1])
            ellipse(img, cx - 3, cy - 3, cx + 3, cy + 3, YELLOW)
            px(img, [(cx - 3, cy), (cx + 3, cy), (cx, cy - 3), (cx, cy + 3)], ORANGE)
            ellipse(img, cx - 1, cy - 1, cx + 1, cy + 1, W[1])
        if bunch == 3:
            rect(img, 4, 11, 12, 12, PINK)
        save(outline(img), f"items/{name}.png")
    save(outline(carrot_icon(K[2], K[0], K[3])), "items/merged_carrot_crystal.png")
    save(outline(carrot_icon(PURPLE, K[0], PINK)), "items/crop_carrot_ancient.png")
    save(seed_bag(RED), "items/seed_tomato.png")
    save(seed_bag(W[1]), "items/seed_sunflower.png")
    save(seed_bag(PURPLE), "items/seed_carrot_ancient.png")
    feed = new(16, 16)
    rect(feed, 4, 5, 11, 13, S[3]); rect(feed, 10, 6, 11, 13, S[2]); rect(feed, 5, 3, 10, 4, S[3]); rect(feed, 6, 4, 9, 4, W[1])
    px(feed, [(6, 8), (8, 9), (7, 11), (9, 7)], YELLOW)
    save(outline(feed), "items/mat_feed.png")
    star = new(16, 16)
    px(star, [(8, 3), (8, 4), (7, 5), (8, 5), (9, 5), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (7, 8), (8, 8), (9, 8), (6, 9), (7, 9), (9, 9), (10, 9), (6, 10), (10, 10)], AMBER)
    px(star, [(8, 6), (8, 7), (7, 7)], K[3])
    save(outline(star), "items/mat_stardust.png")
    clover = new(16, 16)
    for cx, cy in ((6, 6), (10, 6), (6, 10), (10, 10)):
        ellipse(clover, cx - 2, cy - 2, cx + 2, cy + 2, G[2])
        px(clover, [(cx - 1, cy - 1)], G[3])
    px(clover, [(8, 8)], G[0]); px(clover, [(9, 12), (10, 13), (11, 14)], G[1])
    save(outline(clover), "items/lucky_clover.png")
    heart = new(8, 8)
    px(heart, [(1, 2), (2, 1), (3, 2), (4, 2), (5, 1), (6, 2), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (2, 4), (3, 4), (4, 4), (5, 4), (3, 5), (4, 5), (2, 2), (5, 2)], RED)
    px(heart, [(2, 2)], PINK)
    save(outline(heart), "ui/heart.png")


# ------------------------------------------------------------------ M3 additions
def m3_art():
    f = crop_frames("carrot")                              # Ancient Carrot: the carrot shape in old violet tones
    remap = {G[0]: K[0], G[1]: PURPLE, G[2]: PURPLE, G[3]: PINK, ORANGE: PURPLE, RED: K[0], YELLOW: PINK}
    out = []
    for fr in f:
        img = fr.copy()
        for y in range(img.height):
            for x in range(img.width):
                c = img.getpixel((x, y))
                if c in remap:
                    img.putpixel((x, y), remap[c])
        out.append(img)
    px(out[4], [(3, 12), (2, 13), (3, 13), (4, 13), (3, 14)], AMBER)
    save(strip(out), "crops/plant_carrot_ancient.png", {"frameSize": [16, 32], "frames": [f"stage_{i}" for i in range(7)]})

    st = new(64, 64)                                       # Research Station: a small stone study with a lens on the roof
    rect(st, 4, 26, 59, 63, T[2]); rect(st, 46, 26, 59, 63, T[1])
    rng = random.Random(4)
    clusters(st, rng, [T[3]], 30, 6, 28, 50, 32)
    for x in range(4, 60, 8):
        rect(st, x, 26, x, 63, T[1])
    rect(st, 4, 44, 59, 44, T[1])
    rect(st, 4, 60, 59, 63, T[0])
    rect(st, 25, 40, 38, 63, W[0]); rect(st, 27, 42, 36, 63, W[2]); rect(st, 27, 42, 29, 63, W[3]); px(st, [(34, 53), (35, 53)], AMBER)
    for wx in (9, 44):
        rect(st, wx, 34, wx + 10, 46, W[1]); rect(st, wx + 1, 35, wx + 9, 45, K[0]); rect(st, wx + 1, 35, wx + 4, 39, TEAL)
    for row in range(5):
        y0 = 4 + row * 5
        inset = 8 - row * 2
        rect(st, inset, y0, 63 - inset, y0 + 4, K[0]); rect(st, inset, y0 + 4, 63 - inset, y0 + 4, OUT)
        for x in range(inset + (3 if row % 2 else 0), 64 - inset, 6):
            rect(st, x, y0, x, y0 + 3, OUT)
    ellipse(st, 26, 0, 37, 10, T[3]); ellipse(st, 28, 2, 35, 8, TEAL); px(st, [(30, 3), (31, 3), (30, 4)], K[3])
    save(st, "buildings/bld_research_station.png")

    chest = new(16, 16)
    rect(chest, 1, 6, 14, 14, W[2]); rect(chest, 11, 7, 14, 14, W[1]); rect(chest, 1, 4, 14, 7, W[3]); rect(chest, 1, 7, 14, 7, W[0]); rect(chest, 1, 14, 14, 15, W[0])
    rect(chest, 7, 6, 8, 9, AMBER); px(chest, [(2, 5), (3, 5)], S[4])
    for x in (1, 14):
        rect(chest, x, 4, x, 14, W[0])
    save(chest, "props/chest.png")

    gene = new(16, 16)                                     # Gene Fragment: a small twisted strand
    for i, y in enumerate(range(3, 14)):
        a = [(6, 9), (5, 10), (5, 10), (6, 9), (7, 8), (8, 7), (9, 6), (10, 5), (10, 5), (9, 6), (8, 7)][i]
        px(gene, [(a[0], y)], ORANGE); px(gene, [(a[1], y)], TEAL)
        if i % 3 == 1 and max(a) - min(a) >= 2:
            rect(gene, min(a) + 1, y, max(a) - 1, y, K[3])
    save(outline(gene), "items/gene_carrot.png")
    scroll = new(8, 8)
    rect(scroll, 1, 2, 6, 5, B[3]); rect(scroll, 1, 1, 6, 1, S[3]); rect(scroll, 1, 6, 6, 6, S[3]); px(scroll, [(2, 3), (3, 3), (4, 3), (2, 4), (3, 4)], W[1])
    save(outline(scroll), "ui/quest.png")


# ------------------------------------------------------------------ M4 additions
def m4_art():
    def root(sway=0, blink=False, step=0, tilt=0, lie=False):
        img = rootling_frame(sway, blink)
        if step:                                           # walking: one foot lifts
            x0 = 8 if step < 0 else 14
            px(img, [(x0, 22), (x0 + 1, 22), (x0 - 1, 22), (x0 + 2, 22)], CLEAR)
            px(img, [(x0, 23), (x0 + 1, 23)], CLEAR)
            px(img, [(x0, 21), (x0 + 1, 21)], W[1])
        if tilt:                                           # working: water drops fall from the gourd
            px(img, [(21, 21 + (tilt % 2)), (22, 22 + (tilt % 2)), (20, 22)], K[1])
        return img
    idle = [rootling_frame(0), rootling_frame(1), rootling_frame(0), rootling_frame(-1, blink=True)]
    walk = [root(0, step=-1), root(1), root(0, step=1), root(0, step=1), root(-1), root(0, step=-1)]
    work = [root(0, tilt=1), root(0, tilt=2), root(1, tilt=1), root(0, tilt=2)]
    sleep = [rootling_frame(0, blink=True), rootling_frame(1, blink=True)]
    for fr in sleep:
        px(fr, [(19, 3), (20, 3), (21, 3), (20, 4), (19, 5), (20, 5), (21, 5)], K[3])       # a small "z"
    frames, anims, i = [], {}, 0
    for name, fr, fps in (("idle_s", idle, 5), ("walk_s", walk, 10), ("work_s", work, 10), ("sleep_s", sleep, 2)):
        anims[name] = {"from": i, "to": i + len(fr) - 1, "fps": fps}
        frames += fr
        i += len(fr)
    save(strip(frames), "spirits/spirit_rootling.png", {"frameSize": [24, 24], "animations": anims})

    def husk(mud):
        img = new(16, 16)
        ellipse(img, 3, 3, 12, 14, W[2]); ellipse(img, 4, 4, 8, 9, W[3]); px(img, [(11, 11), (10, 12), (11, 12), (9, 13), (10, 13)], W[1])
        px(img, [(7, 2), (8, 1), (8, 2)], G[1])
        if mud:
            px(img, [(5, 6), (6, 6), (5, 7), (9, 8), (10, 8), (9, 9), (6, 11), (7, 11), (7, 12), (10, 5), (11, 6)], S[1])
        else:
            px(img, [(6, 8), (9, 8)], TEAL); px(img, [(7, 10), (8, 10)], W[0])
        return outline(img)
    save(husk(True), "items/spirit_husk_dormant.png")
    save(husk(False), "ui/husk_clean.png")
    ess = new(16, 16)
    ellipse(ess, 5, 5, 10, 12, TEAL); px(ess, [(7, 3), (8, 3), (7, 4), (8, 4)], TEAL); px(ess, [(6, 7), (7, 6)], K[3]); px(ess, [(9, 11), (10, 10)], K[1])
    save(outline(ess), "items/spirit_essence.png")
    pot = new(16, 16)
    rect(pot, 5, 7, 10, 13, K[3]); rect(pot, 5, 9, 10, 13, TEAL); rect(pot, 9, 9, 10, 13, K[1]); rect(pot, 6, 4, 9, 6, K[3]); rect(pot, 6, 3, 9, 3, W[2]); px(pot, [(6, 10), (7, 11)], SAP)
    save(outline(pot), "items/spirit_revival_potion.png")
    sap = new(16, 16)
    ellipse(sap, 4, 6, 11, 13, SAP); px(sap, [(7, 4), (8, 4), (7, 5), (8, 5), (8, 3)], SAP); px(sap, [(6, 8), (6, 9)], K[3]); px(sap, [(10, 11), (9, 12), (10, 12)], G[3])
    save(outline(sap), "items/mat_sap.png")
    kit = new(16, 16)
    rect(kit, 7, 3, 8, 13, W[2]); rect(kit, 8, 3, 8, 13, W[1])
    px(kit, [(4, 3), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 3), (12, 4), (3, 4)], T[2]); px(kit, [(5, 3), (6, 3), (9, 3), (10, 3)], T[3])
    save(outline(kit), "items/tool_dig_kit.png")
    bench = new(32, 32)                                    # Spirit Bench: a mossy stone slab with a bowl and a lantern
    rect(bench, 3, 14, 28, 22, T[2]); rect(bench, 3, 14, 28, 15, T[3]); rect(bench, 3, 21, 28, 23, T[1])
    rect(bench, 5, 24, 9, 30, T[1]); rect(bench, 22, 24, 26, 30, T[1]); rect(bench, 5, 24, 5, 30, T[2]); rect(bench, 22, 24, 22, 30, T[2])
    px(bench, [(4, 14), (5, 14), (6, 15), (7, 14), (20, 14), (21, 15), (26, 14), (27, 14), (27, 15), (3, 16), (28, 17)], G[1]); px(bench, [(5, 13), (26, 13)], G[3])
    ellipse(bench, 11, 9, 20, 15, W[2]); ellipse(bench, 12, 9, 19, 13, TEAL); px(bench, [(13, 10), (14, 10)], K[3])
    rect(bench, 24, 5, 27, 12, W[1]); rect(bench, 25, 7, 26, 10, AMBER); px(bench, [(25, 4), (26, 4)], W[0])
    save(bench, "buildings/bld_spirit_bench.png")
    site = new(32, 32)                                     # the dig site entrance: a mossy hollow between roots
    ellipse(site, 2, 8, 29, 31, G[0]); ellipse(site, 4, 9, 27, 28, G[1]); ellipse(site, 8, 13, 23, 29, S[0]); ellipse(site, 10, 15, 21, 28, OUT)
    px(site, [(6, 12), (7, 11), (8, 11), (22, 11), (23, 12), (24, 12), (12, 10), (13, 9)], G[3])
    for x, y in ((7, 20), (6, 21), (6, 22), (24, 19), (25, 20), (25, 21), (25, 22)):
        px(site, [(x, y)], W[2])
    px(site, [(15, 22), (16, 22)], TEAL)
    save(site, "buildings/site_mossy_hollow_mvp.png")
    mud = new(8, 8)
    ellipse(mud, 0, 1, 7, 6, S[1]); px(mud, [(2, 2), (3, 2)], S[2]); px(mud, [(5, 5), (4, 5)], S[0])
    save(mud, "ui/mud.png")


# ------------------------------------------------------------------ M5: UI panels (9-slice, 4 px corners)
def m5_ui():
    def panel(fill, edge, edge_hi, corner, name):
        img = new(12, 12, fill)
        rect(img, 0, 0, 11, 0, edge); rect(img, 0, 11, 11, 11, edge); rect(img, 0, 0, 0, 11, edge); rect(img, 11, 0, 11, 11, edge)
        rect(img, 1, 1, 10, 1, edge_hi); rect(img, 1, 1, 1, 10, edge_hi)
        rect(img, 1, 10, 10, 10, corner); rect(img, 10, 1, 10, 10, corner)
        for cx, cy in ((0, 0), (11, 0), (0, 11), (11, 11)):
            px(img, [(cx, cy)], CLEAR)
        px(img, [(1, 1), (10, 1), (1, 10), (10, 10)], edge)
        save(img, name)
    panel(B[3], W[1], S[4], B[2], "ui/panel.png")                  # parchment with a wood rim
    panel(B[2], W[1], B[3], S[2], "ui/button.png")
    panel(AMBER, W[1], K[3], S[4], "ui/button_hover.png")
    panel(W[3], W[0], W[2], W[1], "ui/button_pressed.png")
    panel(B[3], S[3], B[3], B[2], "ui/button_disabled.png")
    panel(B[3], B[2], B[3], B[2], "ui/inset.png")


# ------------------------------------------------------------------ M5: the full animation sets
def shifted(img, dy):
    out = new(img.width, img.height)
    out.paste(img, (0, dy))
    return out


def player_full():
    """Every animation of Appendix A for the player: idle, walk, work, carry, celebrate, sleep."""
    frames, anims, i = [], {}, 0

    def add(name, fr, fps):
        nonlocal i
        anims[name] = {"from": i, "to": i + len(fr) - 1, "fps": fps}
        frames.extend(fr)
        i += len(fr)

    for facing in ("s", "n", "e"):
        add(f"idle_{facing}", [player_frame(facing, 0, b) for b in (0, 0, 1, 1)], 5)
        add(f"walk_{facing}", [player_frame(facing, l, b) for l, b in ((-1, 0), (0, 1), (1, 0), (1, 0), (0, 1), (-1, 0))], 10)
        work = []
        for k, (bob, reach) in enumerate(((0, 0), (1, 1), (1, 2), (0, 1))):       # bending to the soil, hands forward
            fr = player_frame(facing, 0, bob)
            hx = 22 if facing != "n" else 9
            hy = 21 + reach
            px(fr, [(hx, hy), (hx + 1, hy), (hx, hy + 1), (hx + 1, hy + 1)], B[3])
            px(fr, [(hx - 1, hy + 2), (hx, hy + 2), (hx + 1, hy + 2), (hx + 2, hy + 2), (hx + 1, hy + 3)], W[2])    # a hand tool
            px(fr, [(hx + 2, hy + 3), (hx + 3, hy + 3)], T[2])
            work.append(outline(fr))
        add(f"work_{facing}", work, 10)
        carry = []
        for l, b in ((-1, 0), (0, 1), (1, 0), (1, 0), (0, 1), (-1, 0)):            # walking with a crate held high
            fr = player_frame(facing, l, b)
            rect(fr, 10, 0 + b, 21, 1 + b, W[3]); rect(fr, 10, 1 + b, 21, 1 + b, W[1])
            px(fr, [(12, 0 + b), (15, 0 + b), (18, 0 + b)], ORANGE)
            carry.append(outline(fr))
        add(f"carry_{facing}", carry, 10)
    cheer = []
    for dy, arms in ((0, 0), (-1, 1), (-2, 2), (-2, 2), (-1, 1), (0, 0)):         # a small jump, arms up
        fr = player_frame("s", 0, 0)
        if arms:
            for x in (8, 9, 22, 23):
                rect(fr, x, 16, x, 22, CLEAR)
            for x in (7, 24):
                rect(fr, x, 12 - arms, x + (1 if x == 7 else -1), 17, K[1])
                px(fr, [(x, 11 - arms), (x + (1 if x == 7 else -1), 11 - arms)], B[3])
        cheer.append(outline(shifted(fr, dy)))
    add("celebrate_s", cheer, 10)
    sleep = []
    for k in range(2):
        fr = player_frame("s", 0, 1)
        px(fr, [(13, 12), (13, 13), (18, 12), (18, 13)], B[3])
        px(fr, [(12, 13), (13, 13), (14, 13), (17, 13), (18, 13), (19, 13)], W[1])
        px(fr, [(24 + k, 3), (25 + k, 3), (26 + k, 3), (25 + k, 4), (24 + k, 5), (25 + k, 5), (26 + k, 5)], K[3])
        sleep.append(outline(fr))
    add("sleep_s", sleep, 2)
    save(strip(frames), "characters/player.png", {"frameSize": [32, 32], "animations": anims})


def animals_full():
    """idle, walk, eat and sleep for the three MVP animals."""
    def build(name, size, idle, leg_boxes, head_box, eye):
        frames, anims, i = [], {}, 0

        def add(tag, fr, fps):
            nonlocal i
            anims[tag] = {"from": i, "to": i + len(fr) - 1, "fps": fps}
            frames.extend(fr)
            i += len(fr)
        add("idle_e", idle, 5)
        walk = []
        for k in range(4):                                  # legs lift in pairs
            fr = idle[0].copy()
            for j, (x0, y0, x1, y1) in enumerate(leg_boxes):
                if (j + k) % 2 == 0:
                    rect(fr, x0 - 1, y1 - 1, x1 + 1, y1 + 1, CLEAR)
            walk.append(outline(shifted(fr, -(k % 2))))
        add("walk_e", walk, 8)
        eat = []
        for k in range(4):                                  # head down to the ground and back
            fr = idle[0].copy()
            x0, y0, x1, y1 = head_box
            head = fr.crop((x0, y0, x1 + 1, y1 + 1))
            rect(fr, x0, y0, x1, y1, CLEAR)
            dy = (2, 4, 4, 2)[k] if size == 32 else (1, 3, 3, 1)[k]
            fr.alpha_composite(head, (x0, y0 + dy))
            eat.append(outline(fr))
        add("eat_e", eat, 8)
        sleep = []
        for k in range(2):
            fr = idle[0].copy()
            px(fr, [eye], B[3] if name != "sheep" else W[1])
            zx = size - 6 - k
            px(fr, [(zx, 1), (zx + 1, 1), (zx + 2, 1), (zx + 1, 2), (zx, 3), (zx + 1, 3), (zx + 2, 3)], K[3])
            sleep.append(outline(shifted(fr, 1)))
        add("sleep_e", sleep, 2)
        save(strip(frames), f"animals/animal_{name}.png", {"frameSize": [size, size], "animations": anims})

    hen = [chicken_frame(0), chicken_frame(0), chicken_frame(1), chicken_frame(0, 1)]
    build("chicken", 16, hen, [(6, 13, 6, 14), (8, 13, 8, 14)], (10, 2, 14, 8), (11, 5))
    build("cow", 32, animal_frames("cow"), [(6, 24, 8, 30), (11, 24, 13, 30), (18, 24, 20, 30), (22, 24, 24, 30)], (21, 3, 31, 17), (24, 9))
    build("sheep", 32, animal_frames("sheep"), [(7, 24, 8, 30), (12, 24, 13, 30), (18, 24, 19, 30), (22, 24, 23, 30)], (21, 4, 31, 18), (24, 12))


def trees():
    """A broadleaf tree in two parts: trunk base (Y-sorted) and canopy (Overhead layer)."""
    base = new(48, 64)
    rect(base, 20, 40, 27, 62, W[2]); rect(base, 25, 40, 27, 62, W[1]); rect(base, 20, 40, 21, 62, W[3])
    px(base, [(18, 62), (19, 61), (19, 62), (28, 61), (28, 62), (29, 62), (17, 63), (30, 63)], W[1])
    px(base, [(22, 46), (23, 47), (22, 52), (24, 56)], W[0])
    save(base, "props/tree_base.png")
    top = new(48, 64)
    rng = random.Random(12)
    for cx, cy, r in ((24, 22, 19), (13, 28, 11), (35, 28, 11), (24, 12, 12), (17, 17, 10), (31, 17, 10)):
        ellipse(top, cx - r, cy - r, cx + r, cy + r, G[1])
    for cx, cy, r in ((20, 18, 12), (14, 25, 7), (26, 10, 8)):
        ellipse(top, cx - r, cy - r, cx + r, cy + r, G[2])
    for cx, cy, r in ((17, 13, 5), (11, 22, 3), (25, 7, 4)):
        ellipse(top, cx - r, cy - r, cx + r, cy + r, G[3])
    for _ in range(26):                                     # leaf clusters in the shade side
        x, y = rng.randrange(24, 44), rng.randrange(18, 40)
        if top.getpixel((x, y))[3]:
            px(top, [(x, y), (x + 1, y), (x, y + 1)], G[0])
    for y in range(64):
        for x in range(48):
            if top.getpixel((x, y))[3] and y > 34 and (x + y) % 9 == 0:
                top.putpixel((x, y), G[0])
    save(top, "props/tree_top.png")


def main():
    write_palette()
    ground_tiles()
    backdrop()
    crops()
    player()
    chicken()
    farmhouse()
    props()
    npcs()
    m1_buildings()
    icons()
    m2_crops()
    m2_npcs()
    m2_buildings()
    m2_icons()
    m3_art()
    m4_art()
    m5_ui()
    player_full()
    animals_full()
    trees()
    print("placeholder art written to", os.path.relpath(ASSETS, ROOT))


if __name__ == "__main__":
    main()
