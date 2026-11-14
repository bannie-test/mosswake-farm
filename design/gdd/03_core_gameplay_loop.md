## 3. Core Gameplay Loop

The loop has three speeds, and each slower loop is fed by the output of the faster one.

_[Diagram: core gameplay loop · 3 nested loops, 2 feedback paths — see the GDD doc]_

Read it as a snake: chores produce raw goods, the value loop turns them into coins and rare goods, and the discovery loop sends new species and spirit labour back up to the chores (the two highlighted paths).

| Loop | Length | Player actions | Output that feeds the next loop |
| --- | --- | --- | --- |
| Chore loop | 1–5 real minutes | Plant, water, feed, harvest, collect | Raw goods |
| Value loop | 1 game day (24 min) | Merge and process goods, fill NPC orders, sell surplus | Coins, XP, reputation, lucky items, rare goods |
| Discovery loop | 1 season (about 3 hours) | Research rare goods, craft seeds and embryos, breed, excavate, restore and assign spirits | New species, recipes, areas and automation that change the chore loop |

### How the 14 steps connect

| Step | Action | System | Consumes | Produces | Feeds step |
| --- | --- | --- | --- | --- | --- |
| 1 | Plant seeds, house animals | Farming, Livestock | Seeds, coins | Growing crops, young animals | 2 |
| 2 | Water, feed, care | Farming, Livestock | Water, Feed, time | Quality and productivity | 3 |
| 3 | Harvest and collect | Farming, Livestock | Time | Raw goods, XP, mutation rolls | 4, 5, 12 |
| 4 | Merge or process | Merge, Crafting | Raw goods, coins, lucky items | Higher-tier goods, Stardust on failure | 5, 8 |
| 5 | Fill NPC orders | Orders | Goods | Coins, XP, reputation, lucky items | 6, 7 |
| 6 | Earn and spend | Economy | Coins | Seeds, land, buildings | 1, 14 |
| 7 | Unlock content | Progression | Level, reputation | Crops, animals, recipes, areas | 1, 4, 11 |
| 8 | Research rare goods | Research | Tier 2+ goods, coins | Gene Fragments, Stardust | 9 |
| 9 | Complete a blueprint | Genetics | Gene Fragments | Creation recipe | 10 |
| 10 | Create seeds and embryos | Genetic Lab | Rare good, fragments, essence | Rare seeds, embryos | 1 |
| 11 | Excavate | Tree Spirits | Dig Kits | Dormant Husks, Amber, Fossil Seeds | 8, 12 |
| 12 | Restore and give a vocation | Tree Spirits | Husk, potion, goods | Working spirit | 13 |
| 13 | Assign spirits to zones | Automation | Sap (pressed from crops) | Chores done without the player | 2, 3 |
| 14 | Expand | Economy | Coins, materials | More plots and buildings | 1 |

### Connection rule

No system ships unless it has at least one input from and one output to another system. The table above is the checklist: a new feature must add a row with both columns filled.
