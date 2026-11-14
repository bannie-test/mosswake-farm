## 5. Detailed Livestock System

Animals are persistent individuals with a genome. They produce on a timer whose speed depends on care, and they pass traits to offspring.

### Species

| ID | Species | Housing (capacity) | Cost | Feed per 8 h | Renewable product | Base interval | Product value | One-time products | Unlock |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| animal_chicken | Chicken | Coop (4 / 8 / 12) | 150 | 1 | Egg | 6 h | 14 | First Molt Feather, Keepsake | Start |
| animal_cow | Cow | Barn (4 / 8) | 450 | 2 | Milk | 8 h | 36 | Keepsake | Level 6 |
| animal_sheep | Sheep | Barn | 400 | 1 | Wool | 16 h | 52 | First Fleece, Keepsake | Level 8 |
| animal_pig | Pig | Barn | 500 | 2 | Truffle (foraged) | 18 h | 95 | Keepsake | Odette reputation 3 |
| animal_bee | Bee colony | Hive (1 colony) | 350 | none; needs 4 blooming flowers within 3 tiles | Honey | 12 h | 40 | Royal Jelly on first swarm | Level 10 |
| animal_sunhen | Sunhen (magical chicken) | Coop | Embryo | 1 | Sun Egg | 8 h | 90 | Ember Plume | Research: 12 chicken genes |

Future magical animals follow the Sunhen pattern: Cloudfleece Sheep, Mossback Boar, Lantern Bees.

### Growth stages

Baby (no product, 24 h) → Juvenile (no product, can be petted, 24 h) → Adult (produces, can breed) → Elder (after 40 game days: production −25%, cannot breed, can retire to the forest sanctuary for a Keepsake).

### Stats

| Stat | Range | Goes down | Goes up | Effect |
| --- | --- | --- | --- | --- |
| Hunger (fed) | 0–100 | −12.5 per hour | Eating from the feeder sets 100 | At 0, production stops and Health falls 5 per hour |
| Happiness | 0–100 | −2 per hour; −10 when hungry; −5 in an overcrowded house | Petting +15 (once a day), outdoor time +3 per hour, favourite treat +25 | Sets product quality |
| Health | 0–100 | Hunger at 0; storm while outside | +5 per hour when fed; Tonic sets 100 | Below 30 the animal is Sick: no production, no breeding. Animals never die |
| Productivity | 0.4–1.5 | – | – | Derived; speeds the production timer |
| Fertility | 0–100 | −40 after breeding | +2 per hour | Must be 60 or more to breed |

```latex
\text{Productivity} = \bigl(0.4 + 0.4\,\tfrac{\text{Happiness}}{100} + 0.2\,\tfrac{\text{Health}}{100}\bigr) \times (1 + \text{trait bonus}), \quad \text{0 if Hunger} = 0
```

The production timer advances by Productivity per game hour. Product quality is Q1 below Happiness 50, Q2 at 50–79, Q3 at 80–94 and Q4 at 95 or more, plus the rarity floor from section 4.

### Renewable and one-time products

- **Renewable:** eggs, milk, wool, truffles, honey. Timer based, collected by hand or by a spirit.

- **One-time:** produced by a life event and never repeated for that animal. First Molt Feather when a chick becomes adult, First Fleece on a sheep's first shearing, Keepsake on retirement. Each is worth 3–6 Gene Fragments when researched, which makes raising new animals a research source.

### Genome

Every animal has a rarity and one to three trait slots (by rarity, as in section 4). Each slot holds a trait ID and a level from 1 to 3.

| Trait | Effect per level | Species |
| --- | --- | --- |
| trait_prolific | Interval −8% | All |
| trait_hardy | Hunger drains 10% slower | All |
| trait_gentle | Happiness decay −15% | All |
| trait_golden_comb | 4% chance per egg of a Speckled Egg | Chicken |
| trait_sun_feather | Egg quality +1 step at level 2 and above | Chicken |
| trait_creamline | 5% chance per milking of Cream | Cow |
| trait_silkcoat | Wool value +10% | Sheep |
| trait_keen_nose | 3% chance of a Black Truffle | Pig |

### Breeding

**Conditions:** same species, both Adult, not parent and child, Happiness 70+, Fertility 60+, Health 30+, a free slot in the house, and a 48-hour cooldown per animal. Gestation or incubation: chicken 12 h, sheep and pig 24 h, cow 36 h. Bees do not breed; a colony swarms into a second hive once, at hive level 3.

**Inheritance, per trait slot of the offspring:**

- 45%: copy parent A's trait in that slot.

- 45%: copy parent B's trait in that slot.

- 10% (`mutationChance`): mutate. Half of mutations raise the inherited trait's level by 1. The other half roll a new trait from the species pool.

If both parents carry the same trait in a slot, the offspring has a 25% chance of that trait at +1 level (maximum 3).

**Rarity inheritance:**

| Parents | Same as lower parent | Same as higher parent | One step above higher | One step below lower |
| --- | --- | --- | --- | --- |
| Same rarity | 80% | – | 15% | 5% |
| Different rarity | 50% | 45% | 5% | – |

Breeding alone cannot exceed Epic. Legendary and Mythical animals come only from embryos (section 7).

**Special offspring:** fixed trait pairs produce a named breed. Two parents that together carry `trait_golden_comb` level 2+ and `trait_sun_feather` level 2+ have a 15% chance of a Sunhen chick. The first such birth also unlocks the Sunhen codex entry and halves its blueprint cost.

**Link to research:** a Gene Tonic (3 Gene Fragments of the species + 1 Stardust) used at breeding raises the mutation chance from 10% to 30% and lets the player lock one slot to a chosen parent. Fragments therefore stay useful after every blueprint is unlocked.

### Player experience

A Breeding Pen screen shows both parents, each slot with its percentage outcomes, and the rarity odds. Nothing about inheritance is hidden.
