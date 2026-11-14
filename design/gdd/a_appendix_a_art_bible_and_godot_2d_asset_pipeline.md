## Appendix A. Art Bible and Godot 2D Asset Pipeline

Every asset is detailed 16-pixel-grid pixel art at a 640×360 internal resolution, drawn in one master palette and one orthogonal 3/4 top-down projection. An asset that breaks any rule in this appendix is rejected, whoever or whatever made it.

### How the two reference images are used

| Reference | Take from it | Do not take from it |
| --- | --- | --- |
| Image 1 (village house, bench, garden plot) | Primary reference: projection, pixel density, warm muted palette, shading in clusters, layered backdrop of hills and sky, density of small props | Any specific building, character, sign, prop or layout |
| Image 2 (large crop fields and paths) | How many crops fit on screen, how clearly plot types read apart, dirt path and fence language | Its diagonal layout, its higher saturation, any specific character or building |

The references set technique and mood only. No element of either may be traced, recoloured or reproduced. All buildings, characters, animals and spirits are original designs.

### Resolution and pixel density

| Item | Value |
| --- | --- |
| Internal resolution | 640×360 |
| Scaling | Integer only: ×2 (720p), ×3 (1080p), ×4 (1440p), ×6 (4K); Steam Deck ×2 with letterbox |
| Tile size | 16×16 px; 40×22.5 tiles on screen |
| Pixel rule | One art pixel is one internal pixel everywhere. No sprite is scaled, rotated or drawn at another density. No sub-pixel movement on screen |

### Perspective

- Orthogonal 3/4 top-down. The ground is seen from above; upright things show their front face and a little of their top.

- Buildings show the front wall and roof. No side walls in perspective, no isometric diagonals.

- Light comes from the top-left. Cast shadows fall down-right as a flat shape in the shadow colour at 35% opacity.

- Characters have four facings: south, north, east, and west as a mirror of east.

### Master palette

Sixty-four colours at most, stored as `/design/art_bible/palette.gpl` and `palette.png`. Ramps run dark to light. The values below are the starting ramps; the style test in M0 may adjust them once, after which the file is locked.

| Ramp | Colours |
| --- | --- |
| Grass | #2f5d3a #4a8a45 #6fae4f #a3cc5c #d4e07a |
| Soil and path | #4a2f25 #6e4630 #96643c #c08a4e #e0b872 |
| Wood | #3a2620 #5a3a2a #7d5236 #a67348 |
| Building warm | #8f3b32 #c2623d #d9a066 #f0dcae |
| Stone | #4b4a52 #6f6e72 #9a9790 #c9c4b4 |
| Sky and water | #3f6ea5 #6d9fd1 #a9d0e8 #e6f2f0 |
| Flower accents | #d9483b #f2a33a #f4d64e #f29bb5 #b565c9 #5b7fd6 |
| Magic glow | #7ee0c2 (spirit) #c8f08f (sap) #ffe9a3 (amber) |
| Outline and shadow | #2a1f2b |

Palette rules:

- Shadows shift hue toward cool violet; highlights shift toward warm yellow. Never darken by adding black.

- Saturation stays under 70% for everything except flower accents and glow, which stay under 85%.

- Glow colours cover no more than about 5% of a screen. Magic is a small warm or teal light, never neon.

- Seasons are palette swaps of the grass and foliage ramps, defined in the palette file.

### Outline rules

- Characters, animals, spirits and pick-up items have a 1 px outline in `#2a1f2b` or a darker shade of the local colour. Never pure black.

- Terrain tiles, buildings and large props have no outline; their edges come from value contrast.

- Interior lines use a darker shade of the surface they sit on.

- The interaction highlight is a 1 px outline in `#ffe9a3`, added by shader, not drawn.

### Shading rules

- Three to five tones per material, taken from one ramp.

- Shade in clusters of pixels. No single stray pixels, no soft brushes, no gradients, no blur.

- No anti-aliasing against transparency: alpha is 0 or 255, except on shadow and glow layers.

- Dithering is allowed only on large natural surfaces: grass-to-dirt transitions, distant hills, sky.

- Texture detail is densest on the gameplay layer and lighter on the backdrop, so the eye rests on what can be used.

### Proportions and sprite sizes

| Asset | Frame size (px) | Notes |
| --- | --- | --- |
| Player and NPCs | 32×32 | Figure about 14×26; about 2.5 heads tall; large readable head and hands |
| NPC portrait | 64×64 | Dialogue only |
| Chicken | 16×16 |  |
| Cow, sheep, pig | 32×32 | Body about 26×18 |
| Hive | 16×32 |  |
| Tree Spirit | 24×24 | Figure about 14×18: shorter than a person, with a round seed-shaped body, bark and moss textures, leaf or sprout on the head, small glowing eyes. Each class has a distinct head growth and tool so it reads by silhouette |
| Elder Tree Spirit | 32×32 | Same language, with amber inlays |
| Crop | 16×32, anchored at the bottom | Tall stages overlap the tile above |
| Tree | 48×64 | Trunk base and canopy as separate sprites |
| Farmhouse | 96×96 | 6×6 tiles; base and roof separate |
| Coop, Merge Table, Research Station | 48×48, 32×32, 64×64 |  |
| Item icon | 16×16 | 1 px clear margin |
| UI | 16 px grid; 9-slice panels with 4 px corners | Parchment and wood from the palette |

### Animation standards

| Subject | Animations (frames at frames per second) |
| --- | --- |
| Player, NPCs | idle 4 at 5; walk 6 at 10; work 4 at 10; carry 6 at 10; celebrate 6 at 10; sleep 2 at 2 |
| Animals | idle 4 at 5; walk 4–6 at 8; eat 4 at 8; sleep 2 at 2; produce 4 at 8; interact 4 at 8 |
| Tree Spirits | idle 4 at 5; walk 6 at 10; work 4 at 10; carry 6 at 10; celebrate 6 at 10; sleep 2 at 2 |
| Crops | 7 still frames: seed, sprout, young, growing, mature, harvested, withered; a 2-frame sway on mature is optional |

Every crop sheet is one horizontal strip of 7 frames, 112×32. The six growth frames match the art brief; the seventh is the withered state from section 4.

### Naming

- Files are named by ID: `crops/plant_carrot.png`, `animals/animal_chicken.png`, `spirits/spirit_rootling.png`, `items/merged_carrot_crystal.png`.

- Animation names are `<action>_<facing>`: `walk_s`, `walk_n`, `walk_e`, `work_e`, `sleep_s`. West is `walk_e` mirrored in engine.

- Crop frames are `stage_0` to `stage_6`.

- Tilesets are `tiles/<area>_<layer>.png`: `tiles/farm_ground.png`.

### Godot setup

| Setting | Value |
| --- | --- |
| Viewport | 640×360; stretch mode viewport; aspect keep; integer scale |
| Texture filter | Nearest, project-wide; no mipmaps |
| Pixel snap | 2D transforms and vertices snapped to pixel |
| Camera | Follows the player; position rounded to whole pixels; limits at map edges |

**Tilemap structure.** One `TileMapLayer` node per layer.

| Layer | Z | Contents | Collision | Y-sort |
| --- | --- | --- | --- | --- |
| Backdrop | −100 | Sky, far hills, forest line; parallax; visible at the top edge of maps | No | No |
| Ground | −10 | Grass, dirt paths, water; terrain auto-tiling that matches corners and sides | Water only | No |
| GroundDetail | −9 | Grass tufts, pebbles, small flowers | No | No |
| Plots | −8 | Tilled soil: dry, wet, fertilized | No | No |
| Objects | 0 | Fences, crops, props, building bases, characters, animals, spirits | Yes | Yes |
| Overhead | 10 | Roofs, tree canopies; fade to 40% when the player is behind | No | No |
| Weather and light | 20 | Rain, mist, night tint | No | No |

**Tileset rules.** Terrain sets need the full 47-tile blob set for grass-to-dirt and grass-to-water. Each terrain has at least 3 variants of its centre tile to break repetition. Atlases are extruded by 1 px.

**Y-sorting.** Every sprite's origin is at its feet, bottom-centre. All moving entities and upright props are children of the Y-sorted Objects layer. Anything taller than 32 px is split into a base (Y-sorted) and a top (Overhead).

**Collision.** Collision covers the footprint only: the bottom 8–12 px of an upright object, never its full sprite. Characters use a 10×6 capsule at the feet. Physics layers: 1 world, 2 player, 3 animals, 4 spirits, 5 interactables. Spirits and animals do not block the player; they step aside.

**Export.** PNG, 32-bit RGBA, no premultiplied alpha, sheets as horizontal strips per animation with a JSON sidecar of frame tags. Source files stay in `/art_src` as `.aseprite`.

### Readability on a crowded farm

- Gameplay objects are at least 15% higher in value contrast than the ground under them.

- A Mature crop has a 2-frame sparkle; a dry plot has visibly lighter soil. Both read without any UI.

- Each crop family has its own leaf shape and one signature colour at maturity.

- Spirit zones show as a faint outline only while the zone tool is held.

- Canopies and roofs fade when they hide the player, an animal or a spirit.

### Asset consistency pipeline

Every asset, generated or hand-drawn, passes five steps.

- **Brief.** The asset list gives the ID, frame size, animations, and the template to draw over.

- **Produce.** Drawn or generated on the template at final size. A generated image at another size is reduced with nearest-neighbour to the grid before anything else.

- **Normalise.** Quantise to the master palette. Clean up by hand: outline, stray pixels, cluster shapes, grid alignment.

- **Lint (automated).** Dimensions are multiples of the frame size; every colour is in the palette; alpha is 0 or 255; the file name is a registered ID; animation tags match the standard.

- **Approve (human).** The art lead views the asset inside the style-sheet scene, next to approved assets, at ×3 scale. Only approved assets enter `/game/assets`.

The style-sheet scene is one 640×360 screen holding the approved farmhouse corner, six plots at each crop stage, the player, a chicken and a Rootling. It is the working definition of the style, and it is built first.
