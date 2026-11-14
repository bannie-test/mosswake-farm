## 4. Detailed Farming System

A crop is one plant on one 16×16 px plot tile. Its species sets how long it grows; its rarity sets how good and how genetically interesting it is.

### Growth stages

- **Seed** (0–10% of growth time): planted, not visible above soil.

- **Sprout** (10–35%).

- **Growing** (35–75%, drawn as two sprites: young and growing).

- **Mature** (75–100%, then harvestable): stays harvestable for 48 game hours.

- **Harvested / Regrowing**: single-harvest crops clear the plot. Regrowing crops return to Growing and count down `regrowHours`.

- **Withered**: reached after 24 consecutive dry game hours, or 48 hours unharvested. Clearing a withered plant returns 1 Compost. It never returns the seed.

### Water

Each plot stores `moisture` from 0 to 100. Watering sets it to 100. It drains at `100 / waterIntervalHours` per game hour. Rain sets every outdoor plot to 100.

- Moisture above 0: the crop grows at full speed.

- Moisture at 0: growth pauses and the dry timer runs. Watering resets the dry timer.

- A crop that never reached 0 gets the **Well Tended** bonus: +1 quality step.

### Fertilizer

One fertilizer per plot per planting, applied before the Growing stage ends.

| ID | Name | Effect | Source |
| --- | --- | --- | --- |
| mat_compost | Compost | +10% growth speed | Withered plants, Kitchen scraps |
| mat_rich_compost | Rich Compost | +1 quality step | 2 Compost + 1 animal product |
| mat_gene_mulch | Gene Mulch | Mutation chance ×2 | 1 Compost + 1 Stardust (Research Level 2) |
| mat_spirit_loam | Spirit Loam | +1 yield | 1 Rich Compost + 1 Spirit Essence (Phase 4) |

No crop requires fertilizer except Legendary species, which need any fertilizer to pass the Growing stage. That is the `fertilizerRequired` field.

### Product quality

Harvests have four quality steps. Quality multiplies value and gene yield.

| Step | Name | Value multiplier | Gene yield multiplier |
| --- | --- | --- | --- |
| Q1 | Normal | 1.0 | 1.0 |
| Q2 | Fine | 1.25 | 1.0 |
| Q3 | Superb | 1.5 | 1.5 |
| Q4 | Pristine | 2.0 | 2.0 |

```latex
Q = \min\bigl(4,\ Q_{\text{floor}}(\text{rarity}) + [\text{well tended}] + [\text{rich compost}] + [\text{in season}] + \text{trait bonus}\bigr)
```

Each bracket is 1 if true and 0 if not. In-season adds its step with 50% probability, the only random term.

### What rarity changes

| Rarity | Quality floor | Trait slots | Base mutation chance | Gene yield per researched unit | Seed source |
| --- | --- | --- | --- | --- | --- |
| Common | Q1 | 0 | 0.5% | 1 | Shop |
| Uncommon | Q1 | 1 | 1% | 2 | Shop after unlock |
| Rare | Q2 | 1 | 2% | 3 | NPC reputation |
| Epic | Q2 | 2 | 3% | 5 | Research blueprint |
| Legendary | Q3 | 2 | 4% | 8 | Research blueprint |
| Mythical | Q3 | 3 | 5% | 12 | Research blueprint plus spirit help |

Growth time is absent from this table on purpose. A Legendary Ancient Carrot grows in 14 hours; a Common Pumpkin takes 20.

**Crop traits** fill the trait slots. Examples: `trait_thrifty` (water interval +50%), `trait_twin` (20% chance of +1 yield), `trait_nightbloom` (grows 50% faster at night), `trait_seedful` (25% chance to return a seed), `trait_generich` (+1 gene fragment when researched).

### Mutation

Each harvested unit rolls once.

```latex
p_{\text{mut}} = p_{\text{base}}(\text{rarity}) \times (2 \text{ if Gene Mulch}) \times (1.5 \text{ if Mist weather}) \times (1 + 0.1 \times \text{ResearchLevel})
```

A mutated unit becomes the species' tier 2 merged product (a Carrot becomes a Premium Carrot). One mutation in ten is a **Gene Sport** and also drops 1 Gene Fragment of that species. Cap: 25%.

### Crop table

Values are base values in coins. Growth, water and regrow are in game hours. Rows 1–4 and Ancient Carrot are the MVP set.

| ID | Name | Category | Rarity | Growth | Water interval | Yield | Regrow (harvests) | Seed cost | Base value | Research value | Favoured season | Unlock |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| crop_carrot | Carrot | Vegetable | Common | 6 | 8 | 2 | – | 4 | 8 | 1 | Spring | Start |
| crop_wheat | Wheat | Vegetable | Common | 4 | 12 | 3 | – | 2 | 3 | 1 | Summer | Start |
| crop_tomato | Tomato | Vegetable | Common | 10 | 6 | 3 | 5 (4) | 20 | 6 | 1 | Summer | Level 2 |
| crop_sunflower | Sunflower | Flower | Common | 8 | 10 | 1 | – | 6 | 22 | 1 | Summer | Level 3 |
| crop_potato | Potato | Vegetable | Common | 9 | 12 | 4 | – | 8 | 7 | 1 | Autumn | Level 5 |
| crop_pumpkin | Pumpkin | Vegetable | Common | 20 | 8 | 1 | – | 15 | 58 | 1 | Autumn | Level 7 |
| crop_lavender | Lavender | Flower | Uncommon | 10 | 14 | 2 | 6 (3) | 30 | 16 | 2 | Spring | Mara reputation 3 |
| crop_strawberry | Strawberry | Fruit | Uncommon | 12 | 6 | 3 | 4 (5) | 45 | 9 | 2 | Spring | Level 9 |
| crop_moonbell | Moonbell | Flower | Rare | 12, night only | 10 | 1 | – | 40 | 85 | 3 | Winter | Ilse reputation 2 |
| crop_glowcap | Glowcap | Magical | Rare | 8 | never (needs shade) | 2 | 8 (unlimited) | 120 | 34 | 3 | Autumn | Bram reputation 2 |
| crop_emberpepper | Emberpepper | Magical | Epic | 16 | 5 | 2 | 8 (3) | Blueprint | 60 | 5 | Summer | Research: 12 tomato genes |
| crop_carrot_ancient | Ancient Carrot | Vegetable | Legendary | 14 | 8 | 2 | – | Blueprint | 220 | 8 | Any | Research: 10 carrot genes |
| crop_starlit_gourd | Starlit Gourd | Fruit | Legendary | 30 | 8 | 1 | – | Blueprint | 1,900 | 8 | Winter | Research: 15 pumpkin + 10 moonbell genes |
| crop_worldroot | Worldroot | Magical | Mythical | 48 | 12 | 1 | – | Blueprint | 4,000 | 12 | Any | Codex 80% + spirit-tended plot |

Base value comes from one formula (section 10), so new crops can be priced without hand tuning.

### Player experience

The player sees a moisture ring under each plant, a stage sprite, and a sparkle when a crop is Mature. Harvest pops the goods out with a quality star. A mutation plays a distinct chime and a short glow, so the rare event is never missed.
