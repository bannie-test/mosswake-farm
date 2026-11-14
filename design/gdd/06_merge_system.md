## 6. Merge System

Merging turns several goods into one higher-tier good at the Merge Table, using a recipe the player has unlocked, at a success chance the player can see and raise.

### Recipe tiers

| Recipe rarity | Base success | Cap from modifiers | Fee (share of output value) | Value factor k | Expected attempts with pity |
| --- | --- | --- | --- | --- | --- |
| Basic | 100% | 100% | 10% | 1.25 | 1.00 |
| Advanced | 85% | 95% | 10% | 1.45 | 1.17 |
| Rare | 65% | 95% | 10% | 1.8 | 1.49 |
| Epic | 40% | 95% | 10% | 2.6 | 2.21 |
| Legendary | 20% | 95% | 10% | 4.5 | 3.42 |
| Mythical | 10% | 95% | 10% | 8.0 | 4.52 |

Output value = k × the summed value of the ingredients. k is set above the expected ingredient loss, so merging is profitable on average at every tier and more so at the risky ones.

### Probability formula

```latex
P = \min\Bigl(100,\ \min\bigl(P_{\text{cap}},\ P_{\text{base}} + L_{\text{charm}} + L_{\text{blessing}} + S_{\text{table}} + M_{\text{mastery}} + Q_{\text{inputs}}\bigr) + 5f\Bigr)
```

| Term | Meaning | Values |
| --- | --- | --- |
| P_base | Base rate of the recipe's rarity | Table above |
| L_charm | One charm slot | Clover +5, Lucky Feather +10, Golden Clover +20 |
| L_blessing | One blessing slot | Spirit Blessing +15, and a failure refunds every ingredient |
| S_table | Merge Table level 1 / 2 / 3 | 0 / +3 / +6 |
| M_mastery | +1 per 5 successes of this recipe | Maximum +5 |
| Q_inputs | All ingredients are Q3 or better | +5 |
| f | Consecutive failures on this recipe (pity) | +5 each; resets on success; not limited by the cap |

Every number lives in one config file, so balance changes need no code.

```json
{
  "mergeConfig": {
    "baseRate": {"basic": 100, "advanced": 85, "rare": 65, "epic": 40, "legendary": 20, "mythical": 10},
    "modifierCap": {"basic": 100, "default": 95},
    "pityStep": 5,
    "tableBonus": [0, 3, 6],
    "masteryPerSuccesses": 5,
    "masteryMax": 5,
    "qualityBonus": {"minQuality": 3, "bonus": 5},
    "critBase": 5,
    "critPerMastery": 1,
    "failRefundRatio": 0.5,
    "stardustPerFailByTier": {"advanced": 1, "rare": 3, "epic": 6, "legendary": 12, "mythical": 25},
    "feeRatio": 0.10
  }
}
```

### Lucky items

| ID | Name | Effect | Sources |
| --- | --- | --- | --- |
| lucky_clover | Clover | +5 | 5% when clearing weeds; Tobin for 40 coins (reputation 2); order bonus |
| lucky_feather | Lucky Feather | +10 | 2% when collecting from an animal with Happiness 90+; Tobin for 150 coins (reputation 3) |
| lucky_clover_golden | Golden Clover | +20 | Merge 3 Clover + 1 Lucky Feather (Rare recipe); special requests |
| lucky_spirit_blessing | Spirit Blessing | +15 and full refund on failure | Given once a season by each spirit at skill level 5; Wren recipe at reputation 5 |

A lucky item is consumed on every attempt, success or failure, except that a Spirit Blessing is returned if the merge succeeds without a critical.

### Outcomes

- **Success:** one output; ingredients and fee consumed.

- **Critical success:** chance of 5% plus 1% per mastery point (maximum 10%), rolled on successes. Output is doubled.

- **Failure:** the fee and the charm are consumed. Half the main ingredients are returned, rounded down, minimum 1. The player gains Stardust by tier. The pity counter for that recipe rises by 1. No lower-tier product is created: returning real ingredients is clearer than inventing a consolation item.

### Why this is not punishing

- Basic recipes never fail, so the first two hours contain no failed merge.

- Pity makes the worst case finite and visible: a Mythical recipe is guaranteed on attempt 19 with no charms.

- A failure pays Stardust, which the research system needs. A failed merge moves the player forward on another track.

- Risk is opt-in. Every tier 3+ good can also be sold or researched as it is.

- Nothing here can be bought with real money.

**Worked example, Crystal Carrot (Rare):** 3 Golden Carrots (390 value) at 65%. Expected attempts 1.49, each failure losing 2 of 3, so 3.98 Golden Carrots per success, about 517 coins plus a 70-coin fee. Output value 700. Expected margin 19%, rising to 30% with a Lucky Feather.

### Recipe discovery

| Source | Rule |
| --- | --- |
| Species unlock | Unlocking a crop or animal grants its Basic recipe once the Merge Table is built |
| Research | The first research of a tier N good reveals the tier N+1 recipe of that chain |
| NPC reputation | Listed per NPC in section 8 |
| Recipe scrolls | Found in excavation sites; they unlock cross-species fusion recipes |

Unknown recipes appear in the list as silhouettes with their source ("Ilse, reputation 3"), so the player always knows where to look.

### Example recipes

| ID | Inputs | Output | Rarity | Value |
| --- | --- | --- | --- | --- |
| merge_carrot_premium | 3 Carrot | Premium Carrot | Basic | 30 |
| merge_carrot_golden | 3 Premium Carrot | Golden Carrot | Advanced | 130 |
| merge_carrot_crystal | 3 Golden Carrot | Crystal Carrot | Rare | 700 |
| merge_egg_golden | 3 Speckled Egg | Golden Egg | Advanced | 225 |
| merge_harvest_crown | 1 Crystal Carrot + 1 Golden Tomato + 1 Sun Bouquet | Harvest Crown | Epic | 2,280 |
| merge_moon_elixir | 1 Harvest Crown + 2 Moonbell Posy + 1 Spirit Essence | Moon Elixir | Legendary | 13,800 |
| merge_worldroot_heart | 1 Moon Elixir + 1 Starlit Gourd + 3 Spirit Essence | Worldroot Heart | Mythical | not sellable |

### UI and UX

One screen with three columns.

- **Left, recipe list.** Grouped by chain. Shows a count of how many the player can afford. Known recipes are icons; unknown ones are silhouettes.

- **Centre, the table.** Ingredient slots fill automatically with the lowest quality that satisfies the recipe; the player can swap in better ones. One charm slot and one blessing slot sit below.

- **Right, the result.** Output icon and value, the success percentage in large type, and the fee.

Display rules:

- The percentage is the real number used by the roll. Hovering it lists every term: "Base 65 + Clover 5 + Table 3 + Pity 10 = 83%".

- Below it, one line states the cost of failure: "On failure you keep 1 of 3 Golden Carrots and gain 3 Stardust".

- A confirmation dialog appears only when the chance is under 100% and the attempt would consume a Rare-or-better ingredient, a Q4 ingredient or a lucky item. Basic merges have no dialog and support "Merge ×N".

- The result animation lasts 1.5 seconds and can be skipped. A failure uses a soft puff and a neutral tone, never a harsh buzzer.
