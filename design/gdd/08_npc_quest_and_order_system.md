## 8. NPC Quest and Order System

Six villagers are the game's demand side and its gatekeepers: orders turn goods into coins and reputation, and reputation unlocks every later system.

### NPC roster

| ID | Name and role | Personality and background | Likes (item tags) | Appears |
| --- | --- | --- | --- | --- |
| npc_mara | Mara Oakhollow, innkeeper | Warm, talkative. Knew the player's grandparent and wants the farm alive again | vegetable, egg, dairy, cooked | Start |
| npc_tobin | Tobin Reed, travelling peddler | Wry, loves a bargain. Former caravan guard who collects lucky charms | flower, merged, lucky | Start |
| npc_ilse | Ilse Quill, scholar | Curious, forgetful. Came to study why the forest's plants differ | merged tier 3+, magical, flower | Level 4 |
| npc_odette | Odette Fenn, rancher | Loud, generous. Breeds the valley's livestock | egg, dairy, wool, truffle | Level 6 |
| npc_bram | Bram Hollowfoot, forester | Gruff, gentle. The last person who remembers the Ma Cây | root vegetable, mushroom, honey | Level 12 |
| npc_wren | Wren Ashby, apothecary | Precise, shy. Lost her teacher's alchemy notes in the forest | flower, honey, magical | When the first husk is found |

MVP uses Mara, Tobin and Ilse. In the MVP, Ilse also gives the single excavation quest that Bram owns in the full game.

### Reputation

Each NPC has reputation points and a relationship level from 1 to 8. Thresholds: 0, 40, 120, 250, 450, 700, 1,000, 1,400.

| Action | Reputation |
| --- | --- |
| Delivery order | +8 |
| Special request | +25 |
| Story quest | +60 |
| Gift of a liked item (once per NPC per day) | +5 |

Reputation never decreases.

### What reputation unlocks

| NPC | Level 2 | Level 3 | Level 4 | Level 5 | Level 6 |
| --- | --- | --- | --- | --- | --- |
| Mara | Kitchen recipes: soup, bread | Lavender seeds | Special requests (feasts) | Kitchen upgrade at half cost | Harvest Crown recipe |
| Tobin | Sells Clover | Sells Lucky Feather; Sun Bouquet recipe | Market stall: sell at 90% instead of 80% | Golden Clover recipe | Merchant Spirit vocation charm |
| Ilse | Moonbell seeds | Gene Mulch; second story quest | Genetic Laboratory plans | 3 Prism Fragments | Worldroot lore quest |
| Odette | Sells sheep | Sells pigs | Breeding Pen plans | Incubator upgrade | Mossback Boar blueprint hint |
| Bram | Glowcap spores | Excavation site 1, Mossy Hollow | Reinforced Dig Kit recipe | Site 2, Amber Glade | Site 3, Heartwood Deep |
| Wren | Sap Tonic recipe | Mending Resin recipe | Heartwood Graft recipe | Spirit Blessing recipe | Elder spirit awakening |

### Three order categories

| Category | Content | Expiry | Reward multiplier on goods value | Slots |
| --- | --- | --- | --- | --- |
| A. Delivery order | 1–3 lines of raw or tier 2 goods | None; can be dismissed | Coins 1.3×, XP 0.4× | 2 per NPC, 8 shown at most |
| B. Special request | 1–2 lines of tier 3+ merged, processed or rare goods | 3 game days, no penalty | Coins 1.6×, XP 0.6×, bonus roll | 1 per NPC from reputation 3; 2 active at most |
| C. Story quest | Hand-authored steps | None | Fixed: a system, area or blueprint | 1 active per NPC |

Special request bonus roll: 30% Clover, 10% Lucky Feather, 10% 2 Gene Fragments of a requested species, 5% Prism Fragment, 45% nothing extra.

### Order generation algorithm

```text
function generateOrder(npc, player, category):
  # 1. What can the player actually make?
  producible = { item |
      item.unlockLevel <= player.level
      and hasProductionPath(item, player)       # owns or can buy the seed, owns the animal,
                                                # or knows a recipe whose inputs are all producible
      and (category != SPECIAL or player.stats.timesProduced[item] >= 1) }

  # 2. What does this NPC want?
  pool = producible filtered by npc.orderRules.tags
  if category == DELIVERY: pool = pool where item.tier <= 2
  if category == SPECIAL:  pool = pool where item.tier >= 3 or item.rarity >= RARE
  remove items already requested on the board
  if pool is empty: return fallbackOrder(npc)   # 4-6 of the cheapest producible liked crop

  # 3. How big?
  budget = (40 + 25 * player.level + 3 * player.level^2) * npc.orderRules.sizeFactor   # coins of goods value
  if category == SPECIAL: budget *= 2.5
  lines = weightedPick(pool, count = rand(1..maxLines), weight = likeWeight * noveltyWeight)

  # 4. Quantities, limited by real capacity
  for line in lines:
      qty = round(budget / len(lines) / line.item.baseValue)
      cap = floor(0.5 * capacityPer24h(line.item, player))   # plots x yield, animals x rate, merge inputs
      line.qty = clamp(qty, 1, max(1, cap))

  # 5. Fairness checks; regenerate up to 5 times, then fall back
  reject if expectedProductionHours(order, player) > 24 (DELIVERY) or > 48 (SPECIAL)
  reject if order needs a Rare+ random merge and another such order is active
  reject if every board order would need more than 50% new production   # keep one easy order

  # 6. Reward
  value = sum(line.qty * line.item.baseValue)
  order.coins = round(value * multiplier[category])
  order.xp    = round(value * xpMultiplier[category])
  order.rep   = repByCategory[category]
  return order
```

`noveltyWeight` is 2.0 for goods the player unlocked in the last three levels, so new content shows up in orders straight away. `capacityPer24h` uses the player's current plots, animals and known recipes, never theoretical maximums.

A completed slot refills after 1 game hour. A dismissed slot refills after 2.

### Story quests and what they gate

| ID | Giver | Requirement to start | Steps | Reward |
| --- | --- | --- | --- | --- |
| quest_first_harvest | Mara | Start | Deliver 6 Carrots | Tomato seeds ×5; order board opens |
| quest_table_for_two | Tobin | Level 3 | Build the Merge Table; make 1 Premium Carrot | 2 Clovers; Basic recipes and the Golden Carrot recipe |
| quest_strange_carrot | Ilse | Level 4; Ilse met | Deliver 1 Golden Carrot | Research Station plans |
| quest_what_carrots_remember | Ilse | Research Station built | Research 3 different goods | Advanced-to-Rare recipe reveal; 2 Prism Fragments |
| quest_new_neighbours | Odette | Level 6 | Raise 2 chickens to Happiness 80 | Barn plans; can buy cows |
| quest_bloodlines | Odette | Odette reputation 4 | Own 2 adults of one species with any trait | Breeding Pen plans |
| quest_roots_remember | Bram | Level 12; 40 orders completed in total; Research Level 3 | Bring 3 Glowcap, 1 Honey, 1 Ancient Carrot | Ancient Forest gate opens; 1 Dig Kit |
| quest_sleeper | Bram | Bram reputation 3 | Excavate the marked tile in Mossy Hollow | First Dormant Husk; Wren appears |
| quest_wake_gently | Wren | First husk owned | Build the Alchemy Hut; brew 1 Revival Potion | Spirit Workshop plans |
| quest_first_vocation | Wren | Spirit Workshop built | Awaken the husk; craft a Rootling charm | Sap Press plans; zone tool |

Every requirement names something the player can already reach. Section 11 lists the dependency check.
