## 12. World and Environment

The world is four hand-built maps: the farm, the village market, the forest edge and the excavation sites. Depth comes from how densely the farm fills, not from more maps.

### Areas

| Area | Size (16 px tiles) | Contents | Unlock |
| --- | --- | --- | --- |
| Farmstead | 96×64 | Farmhouse, 14 field sites, Coop, Barn yard, building pads for Merge Table, Mill, Kitchen, Research Station, Genetic Laboratory, Breeding Pen, well, shipping bin | Start; fields and pads open by purchase |
| Flower Meadow (east part of the farm map) | included above | Flower beds, 6 hive pads | Level 3 |
| Pasture (north part of the farm map) | included above | Fenced grazing; animals gain Happiness here | Level 6 |
| Village Market | 40×30 | Mara's inn, Tobin's cart, order board, Ilse's study, Odette's pens, festival square | Start |
| Ancient Forest edge | 64×48 | Bram's cabin, Wren's hut, Spirit Workshop pad, Alchemy Hut pad, the Grove, three site entrances, Glowcap shade plots | quest_roots_remember |
| Excavation sites ×3 | 8×8 to 12×12 dig grid, 30×20 map each | Dig grid, camp chest | Bram reputation 3, 5, 6 |

The Research Station and Genetic Laboratory sit on the farm so that research is one short walk from the Merge Table. The Spirit Workshop sits at the forest edge so that waking a spirit feels like a trip somewhere older.

### Day and night

One game day is 24 real minutes. Day runs 06:00–20:00, night 20:00–06:00. The player never has to sleep; sleeping in the farmhouse skips to 06:00 and is the manual save point.

| Period | Effects |
| --- | --- |
| Day | Animals graze (Happiness +3 per hour outdoors). Market NPCs are at their stalls |
| Night | Moonbell and trait_nightbloom crops grow. Animals return to housing by themselves. Glowcap and spirits emit light. Market is closed, but the order board still accepts deliveries |
| Dawn (06:00) | Spirit upkeep is paid, weather is rolled, bin sales are paid out, the game autosaves |

### Weather

Rolled each dawn. No weather destroys anything.

| Weather | Chance | Effect |
| --- | --- | --- |
| Sunny | 60% | None |
| Rain | 25% | All outdoor plots set to 100 moisture each hour; animals stay inside |
| Mist | 10% | Mutation chance ×1.5; Root-sense range +1 in excavation sites |
| Storm | 5% (never two days running) | Rain effects; spirits work at 75% speed; each Mature crop has a 10% chance of +1 quality step ("storm-kissed") |

### Seasons

Four seasons of 7 game days. A year is 28 days, about 11 real hours.

- Every crop grows in every season. A crop in its favoured season grows 20% faster and has a 50% chance of +1 quality step.

- Winter does not stop farming; outdoor growth is 15% slower except for winter-favoured crops, and Moonbell is in season.

- Tobin's stock and the tilesets' colour ramps change by season. Palette swaps reuse the same tiles.

### Environmental bonuses

| Bonus | Rule |
| --- | --- |
| Bee pollination | Crops within 3 tiles of an active hive: +10% growth speed |
| Shade | Tiles next to a tree are shaded: Glowcap requires it; other crops grow 10% slower |
| Well range | Plots within 8 tiles of a well water in one action per 3×1 row with the upgraded can |
| Spirit presence | Plots inside any spirit zone: withering timer doubled |

### Events

| Event | Day | What happens |
| --- | --- | --- |
| Bloom Festival | Spring 7 | Flower orders pay 2×; Tobin sells one random Rare flower seed |
| Midsummer Market | Summer 7 | Lucky items 30% off; one guaranteed special request per NPC |
| Harvest Fair | Autumn 7 | Enter one good; quality and tier score against three NPC entries; prize up to a Golden Clover |
| Spirit Night | Winter 7 | One wandering husk appears at the Grove; excavation finds are doubled for the night |

### Area unlocking and scope

Unlocks open gates on maps that already exist: a fence comes down, a bridge is repaired. No area is generated at run time. Total authored tile area is about 12,000 tiles, which one environment artist can build and dress in the roadmap's time.
