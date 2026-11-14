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
    ImageDraw.Draw(img).rectangle([x0, y0, x1, y1], fill=col)


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


def rootling():
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


def main():
    write_palette()
    ground_tiles()
    backdrop()
    crops()
    player()
    chicken()
    rootling()
    farmhouse()
    props()
    print("placeholder art written to", os.path.relpath(ASSETS, ROOT))


if __name__ == "__main__":
    main()
