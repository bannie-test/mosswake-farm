## 9. Tree Spirit System (Ma Cây)

Tree Spirits are the forest's old caretakers, asleep underground as seed-like husks. The player finds them, wakes them, gives each a vocation, and assigns it a zone of the farm to tend.

They are original creatures: small beings of root, bark, leaf and moss, not undead and not servants. The fiction is that they want to tend growing things again, and the Sap the player presses is a shared meal, not a wage.

### Stage A: Discovery

Excavation sites are small separate maps in the Ancient Forest. Each is a grid of soil tiles with one to three layers.

| Site | Unlock | Grid | Layers | Husks | Husk condition |
| --- | --- | --- | --- | --- | --- |
| Mossy Hollow | Bram reputation 3 | 8×8 | 2 | 4 | Muddy |
| Amber Glade | Bram reputation 5 | 10×10 | 3 | 6 | Muddy or Cracked |
| Heartwood Deep | Bram reputation 6 and Codex 50% | 12×12 | 3 | 8 | Cracked |

- **Tool and resource:** a Dig Kit gives 10 digs and costs 150 coins from Bram. The Reinforced Dig Kit (1 Dig Kit + 2 Amber Shards) gives 25 digs.

- **One dig** clears one layer of one tile.

- **Root-sense, the agency rule:** every cleared tile shows a warmth mark: hot (a husk within 1 tile), warm (within 3), or cold. The player triangulates. Husk positions are random per save but their number is fixed, so a site can always be fully cleared.

- **Other tile contents:** 45% plain soil, 20% Ancient Clay, 15% Amber Shard, 8% Fossil Seed (researches into 1 Prism Fragment), 7% recipe scroll or 3 Stardust, 5% thick root (needs 2 digs).

- **Rare encounters:** each husk has a 10% chance to be an Elder husk, with a skill cap of 7 instead of 5 and a distinct look. If nine husks pass without one, the tenth is an Elder.

- **Supply:** 18 husks across the three sites, against a cap of 12 working spirits. Non-husk loot regrows each season. One wandering husk can be found on Spirit Night each year. A surplus husk can be returned to the Grove for 3 Spirit Essence.

### Stage B: Restoration

| Step | Station | Inputs | Time | Result |
| --- | --- | --- | --- | --- |
| 1. Clean | Wash Basin | 5 Water, 1 Lavender | 1 h | Cleaned Husk |
| 2. Mend (Cracked husks only) | Alchemy Hut | 2 Mending Resin (each: 1 Sap + 1 Ancient Clay) | 2 h | Mended Husk |
| 3. Revive | Alchemy Hut | 1 Revival Potion (1 Spirit Essence + 2 Moonbell + 1 Honey + 150 coins, brewed 3 h) | Instant | Sleeping Sprout |

Spirit Essence is refined at the Alchemy Hut from 3 Amber Shards. It also comes from special requests and surplus husks.

Cleaning is a short hands-on interaction: the player scrubs the husk and its face appears. It is the emotional beat of the system and must not be a progress bar.

### Stage C: Conversion

At the Spirit Workshop the player places a Sleeping Sprout with a Vocation Charm. Awakening takes 6 game hours and ends in a short scene where the spirit opens its eyes and takes its tool.

| Class | Vocation Charm recipe | Recipe source |
| --- | --- | --- |
| Rootling | 5 Premium Carrot + 1 Spirit Essence + 200 coins | quest_first_vocation |
| Leafling | 3 Golden Tomato + 1 Spirit Essence + 300 coins | Workshop level 2 |
| Bloomling | 5 Sun Bouquet + 2 Lavender + 1 Spirit Essence + 300 coins | Workshop level 2 |
| Chickling | 2 Golden Egg + 1 First Molt Feather + 1 Spirit Essence + 400 coins | Workshop level 3 |
| Moo Spirit | 3 Cream + 1 Fine Wool Bale + 1 Spirit Essence + 500 coins | Workshop level 3 |
| Merchant Spirit | 1 Harvest Crown + 1 Golden Clover + 2 Spirit Essence + 1,500 coins | Tobin reputation 6 |
| Tinkerling (post-1.0) | 1 Moon Elixir + 3 Spirit Essence | Workshop level 5 |

The class is the player's choice, never a roll. A spirit can change vocation with a new charm and 1 Spirit Essence; its skill level is halved, rounded up.

### Stage D: Automation

**Assignment.** The player picks a spirit, picks the zone tool, and drags a rectangle on the farm. The spirit works only inside it. Each zone needs a chest inside or touching it for inputs and outputs. Two zones of the same class cannot overlap.

| Class | Job inside its zone | Action time at level 1 | Carry | Level 3 perk | Level 5 perk |
| --- | --- | --- | --- | --- | --- |
| Rootling | Waters plots below 30 moisture | 6 s | 10 water | Applies fertilizer from the chest | Zone crops always count as Well Tended |
| Leafling | Harvests Mature vegetables and fruit into the chest | 5 s | 8 | Replants the same seed if the chest holds it | Mutation chance +5% in zone |
| Bloomling | Waters and harvests flowers | 5 s | 6 | Hives in zone make honey 25% faster | Zone flowers +1 quality step |
| Chickling | Collects eggs | 4 s | 6 | Refills coop feeders from the silo | Pets each chicken once a day |
| Moo Spirit | Milks, shears, gathers truffles | 8 s | 4 | Refills barn feeders | Product quality +1 step |
| Merchant Spirit | Carries goods from chests to pinned delivery orders; ships surplus above a set stock level | 10 s per trip | 12 | Pinned orders 2 → 4 | Orders it completes pay +10% coins |

Action times are real seconds.

**Skill progression.** A spirit gains 1 skill XP per action. Thresholds for levels 2 to 5: 100, 300, 700, 1,500. Elders continue to level 6 (speed +20%) and level 7 (a second zone).

| Skill level | Zone size (tiles) | Speed | Stamina (actions) | Rest to full |
| --- | --- | --- | --- | --- |
| 1 | 16 | 1.0× | 40 | 3 h |
| 2 | 24 | 1.2× | 50 | 3 h |
| 3 | 36 | 1.5× | 60 | 2.5 h |
| 4 | 48 | 1.7× | 80 | 2.5 h |
| 5 | 64 | 2.0× | 100 | 2 h |

```latex
\text{actions per game day} \approx \frac{1440\ \text{s}}{\dfrac{\text{actionTime}}{\text{speed}} + \dfrac{\text{restHours} \times 60\ \text{s}}{\text{stamina}}} \times \text{upkeepFactor}
```

A level 1 Rootling manages about 137 waterings a day; its 16-tile zone needs at most 64. The zone size, not the speed, is the real limit at low levels, which is what the player upgrades for.

**Limits and costs.**

- Working spirits are capped at 2 per Spirit Workshop level, 12 at level 6.

- One spirit, one job, one zone (two for Elder level 7).

- Upkeep is 1 Sap per spirit at each dawn. The Sap Press turns any 6 Common crops into 2 Sap in 1 hour. An unfed spirit is Drowsy: half speed, no skill XP. It never leaves.

- A Sap Tonic (2 Sap + 1 Honey) refills stamina at once.

- Spirits do not work in excavation sites, do not merge, research, breed, cook or accept orders.

**Upgrades.**

| Upgrade | Cost | Effect |
| --- | --- | --- |
| Rootbed (per spirit) | 500 coins + 5 Ancient Clay | Rest time −30% |
| Tool graft, tiers 1–3 | 500 / 1,500 / 4,000 coins + 2 / 4 / 8 Spirit Essence | Carry +50% per tier |
| Heartwood Graft | 1 surplus husk + 3 Spirit Essence | Skill cap +1 (once per spirit) |
| Workshop level n | 8,000 × 1.5^(n−1) coins + 20n Ancient Clay | Cap +2; new charm recipes |

### What automation leaves to the player

| Decision | Stays manual because |
| --- | --- |
| What to plant where | It is the main strategic choice of the farm |
| Which goods to merge, research or sell | These carry risk and trade-offs |
| Breeding pairs | Long-term collection goal |
| Which orders to pin for the Merchant Spirit | The spirit delivers; the player chooses |
| Zone layout and Sap budget | Spirits create a new layout puzzle instead of removing one |

A farm with no spirits must remain fully playable; a test in section 20 checks this.
