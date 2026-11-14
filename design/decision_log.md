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

| D-012 | 2026-11-14 | M2 accepted and merged into `main`; go for M3. Finding F-02 (level 4 instead of 5-6 after 60 minutes) stays with the balance pass after playtests | Milestone gate | - |

| D-013 | 2026-11-14 | M3 accepted and merged into `main`; go for M4. Finding F-03 (Ancient Carrot playtest) stays open for human playtests | Milestone gate | - |

| D-014 | 2026-11-14 | M4 accepted and merged into `main`; go for M5. Findings F-04 and F-05 go to the balance pass | Milestone gate | - |

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

## Made during M2, approved by the Director on 2026-11-14

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

## Made during M3, approved by the Director on 2026-11-14

| # | Decision | Reason |
| --- | --- | --- |
| P-30 | A story quest starts by itself when its giver is there and its requirements are met (one active quest per NPC). The HUD tracks the current step; deliver steps are handed over at the order board ("Hand over") | The GDD defines quests and steps but not how they are offered or turned in; the MVP has no NPC dialogue |
| P-31 | The order board opens as the reward of First Harvest, not at level 2 | Section 8 (quest reward) and section 11 (level list) both name it; the quest is the earlier and clearer gate |
| P-32 | A blueprint is learned by pressing "Learn the blueprint" once the fragments are held. Seed creation takes one research queue slot for its 2 hours | Section 7 gives the costs and times but not the interaction |
| P-33 | Story-item protection (section 10): the shipping bin keeps the units a story step needs; a merge that would use them up asks first; research needs a second press | The GDD asks for "a warning" without saying how |
| P-34 | M3 scaffolding (`game/dev/m3_scenario.json`, removed in M4): The Sleeper and First Vocation do not start, because the dig site and the Spirit Bench arrive in M4 | Milestone order |
| P-35 | A building pad whose building is unlocked by a story stays hidden until that story is done (Research Station, later the Spirit Bench) | Keeps the farm from showing signs the player cannot act on |
| P-36 | Display text for quests lives in `data/strings_en.json`, checked by the validator | Section 14's quest example uses text keys; section 18 names a string table |
| P-37 | One Storage Chest on a fixed pad next to the shipping bin; pressing a stack moves it between backpack and chest | Section 13 says chests are "placed anywhere"; free placement is left for a later release |

## Made during M4, approved by the Director on 2026-11-14

| # | Decision | Reason |
| --- | --- | --- |
| P-38 | The dig site is a screen (a 6x6 grid of soil) opened from an entrance on the farm map, not a walkable map of its own | Section 15 asks for "one 6x6 dig site"; a grid screen validates Root-sense with far less work. The walkable sites belong to release R3 |
| P-39 | MVP dig site contents: 1 husk and 2 Spirit Essence, positions rolled once per save; every other tile is plain soil. Root-sense distance counts diagonals as 1 | The MVP item list has no Clay, Amber, Fossil Seeds or scrolls; "within 1 tile" needed a distance rule |
| P-40 | Cleaning is six scrubs by hand, each removing a patch of mud (`spirits.cleanScrubs`); it needs no Water or Lavender in the MVP | Section 9 asks for a hands-on interaction, not a progress bar; Lavender is outside the MVP |
| P-41 | The Rootling charm is not an item: its ingredients are handed over at the bench when the sprout is woken | The MVP item list has no charm item |
| P-42 | A spirit with nothing to do rests where it stands and recovers stamina at its normal rest rate. Without this a skill-1 Rootling stops for its 3-hour rest in the middle of a watering round and plots dry out | Section 9 gives stamina and "rest to full" but not when a spirit rests; the M4 acceptance test (16 tiles, 3 days) fails otherwise |
| P-43 | Refilling water at the well takes one action time and no stamina (`spirits.refillActions`) | The GDD gives the carry size but no refill time |
| P-44 | A Drowsy (unfed) spirit works at half speed and gains no skill XP, as section 9 says. Section 20 says "halves its speed and nothing else"; the two differ on skill XP | Section 9 is the design; the acceptance test checks that zone, skill level and stamina are untouched |
| P-45 | Zone tool: walk to one corner and press the act key, walk to the opposite corner and press again; Esc cancels. Zones are outlined only while the tool is in use | Section 9 says "drags a rectangle"; with keyboard and gamepad in mind, two corners do the same job |
| P-46 | A spirit's position is not saved; after loading it starts from the bench | SpiritInstance (section 14) has no position field |
| P-47 | Sap is pressed at the Spirit Bench, from the cheapest common crops first; crops a story step needs are left alone | Section 15: "Sap crafted by hand" |

## M5 decisions by the Director (2026-11-14)

| # | Decision | Reason |
| --- | --- | --- |
| D-015 | M5 art: code-drawn sprites are upgraded and completed; they remain "temporary" quality until an artist replaces them | No artist is on the project |
| D-016 | M5 balance: tune by simulation now, and again with real players in M6 | No playtest data exists yet |

## M5 balance pass (Economy Balancer; numbers only, each change with before and after)

| Value | Before | After | Why | Measured effect |
| --- | --- | --- | --- | --- |
| Quest XP: First Harvest | 40 | 80 | Level pace (F-02). These XP values were set by the Balancer in M0 (P-08), not by the GDD | In-engine 60-minute session: level 4 -> level 5 (target 5-6), 16 -> 26 orders |
| Quest XP: A Table for Two | 100 | 200 | Same | Same run |
| Quest XP: What Carrots Remember | 300 | 400 | Same | Later in the story |
| Quest XP: The Sleeper | 300 | 500 | Same | Later in the story |
| Quest XP: First Vocation | 400 | 800 | Same | Later in the story |
| Quest XP: A Strange Carrot | 200 | 200 | Unchanged: 200 is the GDD's own example | - |
| `job_water_plots.moistureBelow` | 30 | 50 | Rootling could not keep 16 Tomato plots wet (F-04) | Lowest moisture over 2 days at skill 1: Tomato 0 -> 17, Carrot 6 -> 25, Wheat 13 -> 34 |
| `time.dawnEndHour` (visual only) | 7 | 6 | A new game starts at 06:00 and should not open in half darkness | - |

Not changed: every number the GDD states (crop values, order budget, XP rates, level curve, field prices, merge rates).

## Provisional (made to finish M5; need the Director's confirmation)

| # | Decision | Reason |
| --- | --- | --- |
| P-48 | Settings live in `user://settings.json`, apart from the save: music volume, sound volume, large text, hold-to-act, fullscreen. The Esc menu holds them, plus "Start a new farm" and "Save and quit" | The GDD lists settings and accessibility options but no screen for them |
| P-49 | Gamepad: stick or D-pad to move, A act, X next seed, Y backpack, B or Start close/menu. Prompts show the buttons of the device last used | The GDD asks for gamepad support without a layout |
| P-50 | "Large text" switches every screen to the engine's scalable font at 12 px; normal text uses the project's own 5x7 pixel font (`tools/gen_font.py`) | A bitmap font only looks right at whole multiples, and 2x is too large for a 640x360 screen |
| P-51 | Contextual prompts are computed from the game state each time (hungry animals, a learnable blueprint, a husk in the backpack, a spirit without a zone or Sap), so they need no "seen" flags | Section 15 asks that players understand research "without a text tutorial" |
| P-52 | Day and night: a cool violet tint from 18:00, full at 20:00, lifting between 05:00 and 06:00; animals sleep at night; day and night each have a looping tune | Section 12; Appendix A (shadows shift toward violet, never black) |
| P-53 | Not done in M5 and carried forward: the 47-tile terrain blob sets, atlas extrusion, the shader outline for the interaction highlight (a tile cursor and prompts are used instead), spirit carry and celebrate animations, crop sway | Polish items of Appendix A that do not change play; they need an artist's pass anyway |

## Findings

| # | Finding | Status |
| --- | --- | --- |
| F-01 | Economy simulator, Phase 1: income is inside the 300-600 target on days 1-3 (mean about 430) but reaches 1,500-2,000 on days 4-5 while the player is still level 4-5, because all four buyable fields (300 / 450 / 675 / 1,012 coins) are affordable by day 4. Section 10 plans only "fields 1-2" for Phase 1. Median time to level 5 is 96 minutes against a 60-90 target. Report: `qa/reports/economy_sim_m0.md` | Deferred to after the M1 playtests (D-009) |
| F-02 | M2 acceptance "a 60-minute session reaches level 5-6": the scripted hand-play session reaches level 4 after 60 real minutes of game time (about 29 orders, 24 plots, 4 animals). Same cause as F-01's "96 minutes to level 5": XP comes mostly from orders (0.4 x goods value) and the early order budgets are small | Addressed in the M5 balance pass by raising quest XP: the in-engine session now reaches level 5. The Python simulator, which plays a simpler farm without the story after A Strange Carrot, still says 96 minutes to level 5. Re-check with real players in M6 |
| F-03 | M3 acceptance "4 of 5 playtesters reach an Ancient Carrot harvest without help" needs people and is open. What the machine shows: a scripted path from a new save reaches the harvest using only real actions (about 2.5 game days of production time, levels set at the gates), needing at most four Golden Carrots and one Crystal Carrot | Open until human playtests |
| F-04 | A skill-1 Rootling cannot keep 16 Tomato plots wet when all 16 were watered at the same moment: Tomato dries in 6 hours, so all 16 fall under the watering threshold together and one round (16 x 6 minutes plus walking and a refill) takes longer than the 1.8 hours before the first plot is dry. Carrot and Wheat (8 and 12 hours) are fine, and the M4 acceptance test (16 tiles, 3 days) passes with Carrots | Fixed in the M5 balance pass: `moistureBelow` 30 -> 50 |
| F-05 | Dig site: a careful player always finds the husk within 6 digs using Root-sense (a Dig Kit holds 10). A player who stops when the husk appears may still be short of Spirit Essence; the site now says how much is still buried | Informational |
| F-06 | M5 acceptance, as it stands: (1) asset lint passes on all 87 sprites and now also checks that every definition has its art and every sheet its standard animations; (2) "no placeholder remains" is NOT met: all art is code-drawn and awaits an artist (D-015); (3) "simulator and playtest income agree within 20%" cannot be judged without playtests. Phase 1 income in the Python simulator: mean 706 against a 300-600 target, down from 962; days 1-3 are inside the target and the overshoot is the single day on which the player owns 30 plots but is still level 5 | Open until M6 playtests |
