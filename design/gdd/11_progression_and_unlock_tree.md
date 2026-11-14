## 11. Progression and Unlock Tree

Progress runs on seven tracks, but the player only has to follow one sign: the next story quest, which always names its requirements.

### Tracks

| Track | Range | Raised by | Gates |
| --- | --- | --- | --- |
| Player Level | 1–30 | XP | Crops, animals, buildings, NPC arrival |
| Farm Level | 1–10 | Farm Points: 1 per field bought, 1 per building level. Thresholds 3, 6, 10, 14, 19, 24, 30, 36, 43 | Backpack +2 slots per level; decorations; Farm Level 4 for the Genetic Laboratory, 6 for the Spirit Workshop |
| NPC Reputation | 1–8 per NPC | Orders, quests, gifts | Recipes, seeds, plans, excavation sites |
| Research Level | 1–10 | Fragments researched | Queue slots, Gene Mulch, Gene Tonic, Genetic Laboratory |
| Spirit Level | 1–6 (Workshop level) and 1–5 per spirit | Coins and clay; spirit actions | Spirit cap, charm recipes, perks |
| Collection | 0–100% Codex | Stamps | Rewards in section 7 |
| Quest milestones | 10 story quests at 1.0 | Story steps | Systems and areas |

### Five phases

| Phase | Player level | Entry gate | Systems that open | Capstone that ends the phase |
| --- | --- | --- | --- | --- |
| 1. Beginner Farmer | 1–5 | New game | Crops, watering, chickens, shipping bin, delivery orders, Merge Table with Basic recipes (level 3), Mill (level 5) | quest_strange_carrot: deliver a Golden Carrot |
| 2. Advanced Farmer | 6–11 | Level 6 | Barn, cows, sheep, Kitchen, flowers and hives, fertilizer, lucky items, Advanced and Rare recipes, special requests, Research Station | Research Level 3 |
| 3. Genetic Researcher | 12–19 | Level 12 and Research Level 3 | Blueprints, rare seeds, pigs, Breeding Pen, Genetic Laboratory, embryos, Epic recipes, Codex rewards | quest_roots_remember |
| 4. Ancient Forest Explorer | 20–27 | Forest gate open | Ancient Forest, excavation sites 1–2, Alchemy Hut, restoration, Spirit Workshop levels 1–2, Rootling, Leafling, Bloomling, Sap Press | Three working spirits |
| 5. Spirit Farm Manager | 28+ | Three spirits and Workshop level 3 | Chickling, Moo Spirit, Merchant Spirit, site 3, Elder spirits, Legendary and Mythical recipes, Worldroot | Codex 100% (optional end goal) |

Player levels in phases 4 and 5 are typical, not required. The hard gates are the quests.

### Level unlock list

| Level | Unlock |
| --- | --- |
| 1 | Carrot, Wheat, Coop with 2 chickens, Mara, Tobin |
| 2 | Tomato; order board |
| 3 | Sunflower; Merge Table |
| 4 | Ilse arrives |
| 5 | Potato; Mill |
| 6 | Odette arrives; Barn; cows |
| 7 | Pumpkin; Kitchen |
| 8 | Sheep |
| 9 | Strawberry |
| 10 | Hives |
| 12 | Bram arrives |
| 14 | Third backpack row |
| 16 | Second Kitchen tier |
| 20, 25, 30 | Cosmetic farmhouse upgrades |

### Dependency check

Each unlock is listed with what it needs and where that need is first available. No row may point forward.

| Unlock | Needs | First available |
| --- | --- | --- |
| Merge Table | Level 3, 250 coins | Phase 1 |
| Golden Carrot (capstone 1) | Merge Table; 9 Carrots; Advanced recipe | Advanced carrot recipe is given by quest_table_for_two at level 3 |
| Research Station | Golden Carrot; 2,000 coins | Phase 1 capstone |
| Ancient Carrot blueprint | 10 carrot fragments | 4 Golden Carrots or 1 Crystal Carrot, Phase 2 |
| Moonbell | Ilse reputation 2 | About 5 Ilse orders, Phase 2 |
| Hives and Honey | Level 10; 4 flowers | Sunflower at level 3 |
| Breeding Pen | Odette reputation 4 | Phase 3 |
| Sunhen embryo | Genetic Laboratory; Golden Egg; 1 Spirit Essence | Essence before the forest comes from special requests (Phase 2 onward) |
| Forest gate | Level 12; 40 orders; Research Level 3; 3 Glowcap; 1 Honey; 1 Ancient Carrot | Glowcap at Bram reputation 2; the rest in Phases 2–3 |
| Revival Potion | 1 Spirit Essence; 2 Moonbell; 1 Honey | Essence from the Amber found in site 1 during quest_sleeper |
| Rootling charm | 5 Premium Carrot; 1 Spirit Essence | Phase 1 goods; Essence from site 1 |
| Merchant Spirit | Harvest Crown; Golden Clover; Tobin reputation 6 | Epic recipe from Mara reputation 6; Phase 5 |
| Worldroot | Codex 80%; 4 Legendary species; Worldroot Heart | Phase 5 |

The same table exists as data: every definition has an `unlock` block, and a build-time test walks the graph and fails if any requirement is unreachable from a new save.
