## 7. Research and Genetic System

Research destroys a rare good to learn from it. Enough learning unlocks a permanent blueprint, and each use of the blueprint still costs a rare good.

### Workflow

- **Rare item.** Any merged good of tier 2 or higher, any Epic-or-better harvest, or a one-time animal product.

- **Research Station.** The player queues the item and pays coins. It takes game hours.

- **Deconstruction.** The item is destroyed.

- **Gene Fragments.** The player receives fragments of the item's species.

- **Genetic Blueprint.** When the fragment requirement is met, the player spends the fragments to unlock the blueprint for good.

- **Creation recipe.** The blueprint adds a recipe at the Research Station (seeds) or Genetic Laboratory (embryos).

- **Seed or embryo.** Crafted from creation materials each time.

### Terms

| Term | What it is | Stored as | Consumed? |
| --- | --- | --- | --- |
| Gene Fragment | Per-species research currency, for example gene_carrot | Wallet item, no slot | Yes: by blueprints, Gene Tonic, some creation recipes |
| Prism Fragment | Wildcard fragment; covers up to 30% of any requirement | Wallet item | Yes |
| Gene Blueprint | Permanent knowledge of one species, for example bp_carrot_ancient | Flag in ResearchProgress | Never |
| Creation Materials | Ingredients of one creation craft: a rare good, Stardust, Spirit Essence, coins | Inventory items | Yes, every craft |
| Seed | Plantable item | Inventory item | On planting |
| Animal Embryo | Item placed in an incubator; becomes an AnimalInstance with a founder genome | Inventory item, does not stack | On incubation |

### Research table

| Input | Duration | Cost | Base fragments | Stardust |
| --- | --- | --- | --- | --- |
| Tier 2 merged good | 1 h | 10 | 1 | 0 |
| Tier 3 merged good | 3 h | 40 | 3 | 1 |
| Tier 4 merged good | 6 h | 120 | 8 | 3 |
| Epic harvest | 3 h | 60 | 5 | 1 |
| Legendary harvest | 4 h | 150 | 8 | 2 |
| Mythical harvest | 8 h | 400 | 12 | 5 |
| One-time animal product | 2 h | 30 | 3–6 | 1 |

```latex
\text{fragments} = \operatorname{round}\bigl(\text{base} \times \text{qualityMult} \times (1 + 0.05 \times \text{ResearchLevel})\bigr) \times (2 \text{ if first research of this item})
```

The yield has no random term. The player can plan exactly how many goods a blueprint will cost.

### Research Level

Research XP equals fragments gained. Thresholds: 10, 30, 70, 150, 300, 500, 800, 1,200, 1,800 for levels 2 to 10.

| Level | Unlock |
| --- | --- |
| 2 | Gene Mulch recipe |
| 3 | Second research queue slot; one of the two gates to the Ancient Forest |
| 4 | Gene Tonic recipe |
| 5 | Genetic Laboratory can be built; embryos |
| 7 | Third queue slot |
| 10 | Research duration halved |

### Blueprints

| Blueprint | Fragment cost | Creation recipe | Output |
| --- | --- | --- | --- |
| bp_carrot_ancient | 10 carrot | 1 Crystal Carrot + 5 Stardust + 200 coins, 2 h | 4 Ancient Carrot Seeds |
| bp_emberpepper | 12 tomato | 1 Golden Tomato + 3 Stardust + 150 coins, 2 h | 3 Emberpepper Seeds |
| bp_starlit_gourd | 15 pumpkin + 10 moonbell | 1 Harvest Crown + 1 Spirit Essence + 500 coins, 6 h | 2 Starlit Gourd Seeds |
| bp_sunhen | 12 chicken (6 after a natural Sunhen birth) | 1 Golden Egg + 6 chicken fragments + 1 Spirit Essence + 300 coins, then 24 h incubation | 1 Sunhen Embryo |
| bp_cloudfleece | 12 sheep + 6 moonbell | 1 Fine Wool Bale + 6 sheep fragments + 1 Spirit Essence + 400 coins, then 36 h | 1 Cloudfleece Embryo |
| bp_worldroot | 20 each of any 4 Legendary species; Codex 80% | 1 Worldroot Heart | 1 Worldroot Seed |

**The brief's example, concretely:** one Crystal Carrot yields 8 carrot fragments, 16 the first time. That alone unlocks the Ancient Carrot blueprint. A player who never reaches Crystal can get there with four Golden Carrots (3 each, first one doubled, 15 total).

**Animals follow the same path.** Fragments come from merged animal products and one-time products. An embryo hatches a founder animal with one guaranteed trait and a rarity of Epic or higher. Founders then enter the breeding system, which is how a blueprint's value compounds.

### Genetic Codex

One page per species. Each page has five stamps: discovered, researched, blueprint unlocked, Q4 specimen produced, all traits seen.

| Codex completion | Reward |
| --- | --- |
| 10% | Backpack +6 slots |
| 25% | 5 Prism Fragments |
| 50% | Research duration −25% |
| 75% | 3 Golden Clovers and the Scholar's Lantern decoration |
| 80% | Worldroot blueprint becomes available |
| 100% | Heartwood Statue: all harvest quality +1 step on the home farm |

### How this avoids grind

- Requirements are small and fixed: 10 to 25 fragments, never hundreds.

- The first research of every item pays double, so trying new things beats repeating old ones.

- Prism Fragments, Gene Sports from mutation and order rewards give three other routes to the same fragments.

- Yield is deterministic. No research attempt is wasted.

### How rare species stay valuable

- Rare seeds and embryos are never sold in shops.

- Every creation craft consumes a tier 3 or tier 4 good, so supply is tied to the merge system.

- Blueprint species return their own seed only 25% of the time (`trait_seedful` is innate), so a crop line thins out without new crafting.

- Special requests pay 1.6× for rare goods, and higher fusion recipes need them as ingredients.
