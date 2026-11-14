# Decision log

Owner: Game Director (human). Every decision is recorded with its reason and what it changes
(GDD section 18). Agents may not act on a "Provisional" row beyond the milestone it was made in
until the Director confirms it.

## Approved by the Director

| # | Date | Decision | Reason | Changes |
| --- | --- | --- | --- | --- |
| D-001 | 2026-11-14 | The "Assumptions and resolved contradictions" table of the GDD is approved as written (8 assumptions, 9 resolutions) | Task 1 of the first ten tasks; everything else depends on it | All sections |
| D-002 | 2026-11-14 | Engine version is Godot 4.7.2 (stable) | Director's choice | `game/project.godot`, CI |
| D-003 | 2026-11-14 | Art for M0-M4 is original placeholder pixel art drawn in code in the master palette; the Director acts as art lead and approves from screenshots. Final art in M5 | No art lead or art exists yet | `tools/gen_placeholder_art.py`, `game/assets` |
| D-004 | 2026-11-14 | Work stops for a go or no-go after every milestone | GDD human gate | Process |
| D-005 | 2026-11-14 | The 7 MVP merge recipes without stated inputs use "3 of the previous tier": 3 Tomato -> Premium Tomato (Basic), 3 Premium Tomato -> Golden Tomato (Advanced), 3 Sunflower -> Sun Bouquet (Basic), 3 Egg -> Speckled Egg (Basic), 3 Speckled Egg -> Golden Egg (Advanced), 3 Milk -> Cream (Basic), 3 Wool -> Fine Wool Bale (Basic) | The GDD lists the recipes but not their inputs; traits (the full-game source of Speckled Egg and Cream) are out of the MVP | `data/merge_recipes.json`, `data/items.json` |
| D-006 | 2026-11-14 | Sun Bouquet unlocks at Tobin reputation 3, not with the Sunflower | Sections 6 and 8 disagree; the NPC table wins | `data/merge_recipes.json`, `data/npcs.json` |
| D-007 | 2026-11-14 | Spirit Bench: 1,500 coins, plans rewarded by the MVP quest The Sleeper | The GDD gives no cost or unlock | `data/buildings.json`, `data/quests.json` |

| D-008 | 2026-11-14 | M0 accepted; go for M1. The M0 style test screen (`design/art_bible/style_test_m0.png`) is approved as the placeholder style and the master palette is locked | Milestone gate | `design/art_bible/palette.gpl` may no longer change |
| D-009 | 2026-11-14 | Finding F-01 (Phase 1 income overshoot): re-tune after the M1 playtests, when the simulated player can be calibrated | Avoids tuning against a guess | `tools/economy_sim.py`, field prices stay as in the GDD for now |

| D-010 | 2026-11-14 | M1 accepted; go for M2. The Director approved without a playtest report, so the human parts of M1's acceptance stay open: the under-10-minute first loop with real players, five internal playtests, and the 18 / 24 / 30 minute day test | Milestone gate | Carried into the M6 outside playtest at the latest |
| D-011 | 2026-11-14 | Repository: github.com/bannie-test/mosswake-farm. `main` holds accepted milestones; each milestone is built on its own branch | Director's choice | Process |

## Made during M0, approved by the Director on 2026-11-14 ("approve all")

| # | Decision | Reason |
| --- | --- | --- |
| P-01 | `/data` is the single source of truth; `tools/sync_data.py` copies it to `game/data` so Godot reads it as `res://data`. CI fails if the copy is stale | Section 18 puts data at `/data`, section 14 reads `res://data`, and the Godot project lives in `/game` |
| P-02 | Three supporting data types beyond the GDD's 20: `CraftRecipe` (Feed, Sap, Revival Potion), `DigSiteDefinition` (the MVP dig site) and `config.json` (time, economy, orders, reputation, research numbers). Shop stock is an optional `shop` list on the NPC definition | The GDD names these mechanics and numbers but gives them no definition type; "numbers live in data" needs a home for them |
| P-03 | In the MVP only carrot goods yield Gene Fragments. Other merged goods can still be researched (`geneId: null`): they count for quests and reveal the next recipe, but bank no fragments | The MVP item list has one Gene Fragment (carrot), yet What Carrots Remember asks for 3 different researched goods and no quest may need a merge above Advanced |
| P-04 | Golden Tomato and Golden Egg recipes are revealed by the first research of Premium Tomato and Speckled Egg | Section 6: first research of a tier N good reveals the tier N+1 recipe |
| P-05 | MVP quest The Sleeper (Ilse, level 8, after What Carrots Remember): step 1 deliver 1 Ancient Carrot (Ilse hands over a Dig Kit), step 2 find the husk. Reward: Spirit Bench plans. The dig site always yields 2 Spirit Essence (one for the Revival Potion, one for the Rootling charm) | Combines Bram's and Wren's quests as section 15 asks; keeps "one carrot through the whole loop"; both spirit recipes need an Essence |
| P-06 | Tobin's shop sells the MVP seeds, Clover (reputation 2), Dig Kits (150) and, because Odette is not in the MVP, the three animals | The MVP has no other seller |
| P-07 | MVP Barn unlocks at level 4 with no quest (its quest giver Odette is out of the MVP; the MVP cow is level 4) | Section 15 |
| P-08 | Numbers set as Economy Balancer where the GDD is silent: new game = 50 coins, 6 Carrot seeds, 6 Wheat seeds, 6 Feed, 2 adult chickens; quest XP 40 / 100 / 200 (GDD) / 300 / 300 / 400; Mara orders up to 3 lines, Tobin 2, size factor 1.0; merged goods are Common at tier 2, Uncommon at tier 3, Rare at tier 4 | Needed by the data; all are single values in `/data` |
| P-09 | Reputation rewards that point at content outside the MVP (Mara 2-4, Ilse 2-4, Tobin 4) are left out of the MVP data | They would be unreachable IDs |
| P-10 | MVP Ancient Carrot needs no fertilizer and has no innate Seedful trait | Fertilizer and traits are out of the MVP |
| P-11 | Renderer: GL Compatibility. Random streams: a 32-bit generator whose whole state is one integer | Runs on Steam Deck and low-end PCs; a 32-bit state survives JSON exactly, so a reload cannot change a roll |
| P-12 | Revival Potion ID is `spirit_revival_potion`; it brews for 3 game hours as in the full design | ID rules of section 13 |

## Made during M1, approved by the Director on 2026-11-14 ("approve all, go to M2")

| # | Decision | Reason |
| --- | --- | --- |
| P-13 | M1 scaffolding (`game/dev/m1_scenario.json`, removed in M2): the Merge Table is already built and both carrot recipes are known; Mara's orders come from a fixed list of 8; orders hand out seeds as bonus items | The data gates the Merge Table behind level 3 and 250 coins and the shop arrives in M2, but M1 must show the whole loop in under 10 minutes |
| P-14 | One context action (E or Space) on the faced tile: Till, Plant, Water, Harvest or Clear, whichever applies. Q changes the selected seed. No tool items, and the watering can never runs dry | The GDD names no tools among its items and gives the player's can no capacity |
| P-15 | After a single-harvest crop is picked, or a withered plant is cleared, the plot stays tilled | The GDD says the plot is cleared but not whether it must be tilled again |
| P-16 | Moisture drains and the dry timer runs on a Mature crop too, so an unwatered ripe crop can wither after 24 dry hours | Section 4 does not exclude Mature crops from the dry rule |
| P-17 | Clearing a withered plant returns nothing in the MVP (Compost is outside the MVP item list) | Section 15 |
| P-18 | New numbers in `data/config.json`: the player walks 5 tiles per second; Water is offered once moisture is under 90 | The GDD gives no player speed; without the second number the Water prompt returns the instant after watering |
| P-19 | UI text uses the engine's default font, anti-aliased, at 8 px. A proper pixel font is part of the M5 UI pass | No licensed pixel font is in the project yet |

## Provisional (made to finish M2; need the Director's confirmation)

| # | Decision | Reason |
| --- | --- | --- |
| P-20 | M2 scaffolding (`game/dev/m2_scenario.json`, removed in M3): the quests First Harvest and A Table for Two, and the first research of Golden Carrot, Premium Tomato and Speckled Egg, count as done. So the order board is open from the start and all 10 recipes can be reached. Level, building and reputation gates are real | Quests and research are M3 features, but M2 must deliver "all 10 recipes" and the order board |
| P-21 | One order board at the gate shows every met NPC's orders. Mara's and Ilse's stalls open the same board; Tobin's cart opens his shop | The MVP has no Village Market map; "NPC stalls at the farm gate" (section 15) |
| P-22 | Buildings stand on fixed pads marked by a sign; the act key on a pad offers to build. Upgrades are bought inside the building's screen | Section 14 gives buildings `placement: pad`; the GDD does not say how a pad is used |
| P-23 | Bought animals arrive as babies (48 game hours before they produce); new animals start at Happiness 60. Each animal holds one finished product until it is collected | The GDD defines the stages but not the purchased stage, the starting Happiness, or what happens to an uncollected product |
| P-24 | Daytime adds the "outdoor" +3 Happiness per hour to every fed animal automatically | The Pasture area is outside the MVP map |
| P-25 | Feed is made in the Coop or Barn screen ("Make Feed"); animals eat from the silo the moment their hunger reaches 0 | The GDD names hand crafting of Feed but no place for it |
| P-26 | Order generator details the algorithm leaves open: like weight 2.0 (`orders.likeWeight`); an order is "easy" when half its goods value is in stock (`orders.easyStockShare`); a fallback order prefers a crop nobody has asked for yet. Orders can be skipped from the board | Needed to implement section 8's pseudocode |
| P-27 | Sleeping at the farmhouse door skips to 06:00 and saves. The game also saves at dawn and on quit, and resumes the save on start. Esc opens a small menu with "Start a new farm" | Section 14 (save rules); the GDD has no title screen design |
| P-28 | The Storage Chest is deferred to M3 | It is not in M2's feature list; the Research Station, which reads from chests, arrives in M3 |
| P-29 | Shipping bin screen: Ship 1 / Ship all per good | No design in the GDD |

## Findings

| # | Finding | Status |
| --- | --- | --- |
| F-01 | Economy simulator, Phase 1: income is inside the 300-600 target on days 1-3 (mean about 430) but reaches 1,500-2,000 on days 4-5 while the player is still level 4-5, because all four buyable fields (300 / 450 / 675 / 1,012 coins) are affordable by day 4. Section 10 plans only "fields 1-2" for Phase 1. Median time to level 5 is 96 minutes against a 60-90 target. Report: `qa/reports/economy_sim_m0.md` | Deferred to after the M1 playtests (D-009) |
| F-02 | M2 acceptance "a 60-minute session reaches level 5-6": the scripted hand-play session reaches level 4 after 60 real minutes of game time (about 29 orders, 24 plots, 4 animals). Same cause as F-01's "96 minutes to level 5": XP comes mostly from orders (0.4 x goods value) and the early order budgets are small | Deferred with F-01 to the balance pass after playtests (D-009). Levers inside the Economy Balancer's remit: `xpRate.delivery`, `orders.budget`, quest XP (quests add 40 to 400 XP each from M3 and are not in this run) |
