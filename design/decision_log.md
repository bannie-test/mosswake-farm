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

## Provisional (made to finish M0; need the Director's confirmation)

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

## Open findings

| # | Finding | Options |
| --- | --- | --- |
| F-01 | Economy simulator, Phase 1: income is inside the 300-600 target on days 1-3 (mean about 430) but reaches 1,500-2,000 on days 4-5 while the player is still level 4-5, because all four buyable fields (300 / 450 / 675 / 1,012 coins) are affordable by day 4. Section 10 plans only "fields 1-2" for Phase 1. Median time to level 5 is 96 minutes against a 60-90 target. Report: `qa/reports/economy_sim_m0.md` | (a) accept: the targets are tuning targets and the bot never idles; (b) gate fields 3-4 behind level 6; (c) raise field prices; (d) re-tune after M1 playtests, when the player model can be calibrated |
