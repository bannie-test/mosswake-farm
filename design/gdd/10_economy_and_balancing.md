## 10. Economy and Balancing

Coins are earned only by selling farm output, and every coin price in the game is derived from five formulas, so the economy can be re-tuned from one config file.

### Currencies and resources

| Resource | Type | Main sources | Main sinks | Cap |
| --- | --- | --- | --- | --- |
| Coins | Soft currency | Orders, shipping bin, market stall | Seeds, animals, land, buildings, merge and research fees, Dig Kits | None |
| XP | Progress | Harvests, orders, merges, research | – (converts to Player Level) | – |
| Reputation | Per-NPC progress | Orders, quests, gifts | – | 1,400 per NPC |
| Gene Fragments | Per-species wallet item | Research, Gene Sports, special requests | Blueprints, Gene Tonic, embryo recipes | 99 per species |
| Prism Fragments | Wildcard wallet item | Codex, story quests, Fossil Seeds | Blueprints | 30 |
| Stardust | Research material | Failed merges, research of tier 3+ | Seed creation, Gene Mulch, Gene Tonic | 999 |
| Lucky items | Wallet items | Weeds, happy animals, Tobin, special requests | Merge attempts | 20 each |
| Spirit Essence | Spirit material | Amber Shards, surplus husks, special requests | Revival, charms, grafts, embryos, Spirit Loam | 99 |
| Crafting materials | Inventory items | Compost, Ancient Clay, Amber, Sap, Feed | Fertilizer, restoration, upkeep, feeding | Stack 99 |

### The five formulas

**1. Crop value.** A crop is priced from a target profit per plot-hour.

```latex
\text{baseValue} = \frac{\text{CPH}(\text{rarity}) \times \text{totalGrowthHours} + \text{seedCost}}{\text{totalYield}}
```

| Rarity | Common | Uncommon | Rare | Epic | Legendary | Mythical |
| --- | --- | --- | --- | --- | --- | --- |
| Target coins per plot-hour (CPH) | 2 | 3 | 4 | 8 | 12 | 20 |

Check, Carrot: (2 × 6 + 4) / 2 = 8. Check, Tomato over 4 harvests: (2 × 25 + 20) / 12 = 5.8, rounded to 6. For blueprint species, seed cost is the creation recipe's cost divided by seeds made.

**2. Merged value.** `value = k(tier) × sum of ingredient values`, with k from section 6.

**3. Sale price.** Shipping bin pays 80% of value. Market stall (Tobin reputation 4) pays 90%. Delivery orders pay 130%. Special requests pay 160%. Quality multiplies all of them.

**4. Level curve.**

```latex
\text{XP}_{\text{next}}(L) = 10 \times \operatorname{round}(8 \times L^{1.5})
```

| Level | 1 | 2 | 3 | 5 | 8 | 10 | 15 | 20 | 30 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| XP to next level | 80 | 230 | 420 | 890 | 1,810 | 2,530 | 4,650 | 7,160 | 13,150 |

XP sources: 1 per harvested unit times rarity rank; 0.4 × goods value for delivery orders and 0.6 × for special requests; the fee amount for each merge attempt; 5 per Gene Fragment researched.

**5. Expansion cost.** A field is 6 plots. The player starts with 2 fields.

```latex
\text{fieldCost}(n) = \operatorname{round}(300 \times 1.5^{\,n-1}), \quad n = 1 \ldots 12
```

| Field bought | 1 | 2 | 3 | 4 | 6 | 8 | 10 | 12 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cost | 300 | 450 | 675 | 1,010 | 2,280 | 5,130 | 11,530 | 25,950 |

Maximum farm: 14 fields, 84 plots. Late fields do not pay back with Common crops, which pushes the player to rare species.

### Production costs and returns

| Producer | Buy cost | Running cost per hour | Output per hour at full care | Net per hour | Payback |
| --- | --- | --- | --- | --- | --- |
| Plot of Carrots | 50 (first field) | 0.67 (seed) | 2.67 | 2.0 | 25 h |
| Chicken | 150 | 0.75 (Feed) | 2.33 | 1.6 | 95 h |
| Cow | 450 | 1.5 | 4.5 | 3.0 | 150 h |
| Sheep | 400 | 0.75 | 3.25 | 2.5 | 160 h |
| Pig | 500 | 1.5 | 5.3 | 3.8 | 132 h |
| Bee colony | 350 | 0 (needs 4 flowers nearby) | 3.3 | 3.3 | 105 h |

Feed is valued at 6 coins (2 Wheat by hand). The Mill makes 3 Feed from 2 Wheat, which cuts animal running costs by two thirds and is the reason to build it.

### Buildings

| ID | Building | Cost | Requirement | Upgrades |
| --- | --- | --- | --- | --- |
| bld_coop | Coop | Owned at start | – | 800 (8 hens), 2,500 (12) |
| bld_chest | Storage Chest | 100 | – | – |
| bld_merge_table | Merge Table | 250 | Level 3 | 2,000; 8,000 + 5 Spirit Essence |
| bld_mill | Mill | 600 | Level 5 | – |
| bld_barn | Barn | 1,200 | Level 6, quest_new_neighbours | 4,000 (8 animals) |
| bld_kitchen | Kitchen | 1,500 | Level 7 | 5,000 |
| bld_hive | Hive (maximum 6) | 350 | Level 10 | – |
| bld_research_station | Research Station | 2,000 | quest_strange_carrot | 6,000; 15,000 |
| bld_breeding_pen | Breeding Pen | 3,000 | Odette reputation 4 | – |
| bld_genetic_lab | Genetic Laboratory | 6,000 | Research Level 5, Ilse reputation 4 | 15,000 |
| bld_alchemy_hut | Alchemy Hut | 4,000 | quest_wake_gently | – |
| bld_sap_press | Sap Press | 1,000 | quest_first_vocation | – |
| bld_spirit_workshop | Spirit Workshop | 8,000 + 20 Ancient Clay | quest_wake_gently | ×1.5 per level, to level 6 |

### Order rewards by level

Delivery budget in goods value is `40 + 25L + 3L²`; special requests use 2.5× that.

| Player level | Delivery goods value | Delivery coins | Special request goods value | Special coins |
| --- | --- | --- | --- | --- |
| 1 | 68 | 88 | – | – |
| 5 | 240 | 312 | 600 | 960 |
| 10 | 590 | 767 | 1,475 | 2,360 |
| 20 | 1,740 | 2,262 | 4,350 | 6,960 |
| 30 | 3,490 | 4,537 | 8,725 | 13,960 |

### Income targets

These are tuning targets for the economy simulator (task 4 in the final list), not measured results.

| Phase | Net coins per game day | Biggest planned purchase | Days to afford it |
| --- | --- | --- | --- |
| 1 | 300–600 | Merge Table, fields 1–2 | 1–2 |
| 2 | 1,500–3,000 | Barn, Kitchen, Research Station | 1–2 |
| 3 | 6,000–10,000 | Genetic Laboratory | 1 |
| 4 | 15,000–25,000 | Spirit Workshop | 1 |
| 5 | 40,000+ | Workshop levels 4–6, fields 11–12 | 1–2 |

The rule behind the table: the next major purchase should cost one to two game days of income. If the simulator shows more than three, the price is wrong.

### Exploit and inflation controls

| Risk | Control |
| --- | --- |
| Infinite money | Nothing sold in a shop can be resold, or merged and resold, for more than it cost unless it passes through a plot or animal timer. A data test enforces this on every build |
| Trivial loops | Every recipe's output value is checked against its inputs in the same test. Critical doubles are capped at 10% |
| Order farming | Slots refill on a timer of 1 game hour; the board holds 8 delivery orders and 2 special requests at most |
| Flooding the bin with rare goods | After 5 units of one tier 3+ good in a day, the bin price for it drops 10% per unit, to a floor of 50% |
| Hoarding | Stack limit 99, wallet caps above, storage bought per chest |
| Rare value collapse | Rare seeds are never sold; blueprint crops reseed 25%; creation always consumes a tier 3+ good |
| Self-feeding gene loop | Blueprints are one-time. Later fragments only go into Gene Tonic and embryos, which cost other rare inputs |

### Deadlock prevention

- Tobin always stocks Carrot and Wheat seeds, at any reputation.

- If the player has under 4 coins, no seeds and no sellable goods, Mara hands over 6 Carrot seeds, once per game day.

- Items needed by an active story quest are flagged. Selling, merging or researching the last required unit shows a warning.

- No story quest requires a merge above Advanced, except `quest_roots_remember`, whose Ancient Carrot has a deterministic path with pity.

- Unpaid spirit upkeep slows spirits; it never removes them. Animals cannot die. Orders carry no penalty.
