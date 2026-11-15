## 21. Revision 2: changes after the first demo

Revision 2 replaces the single context key, fixed plots and one-click trading of demo 0.9.0 with hand tools, gatherable resources, fishing, a house interior and a confirmed trade window. The Director asked for it on 2026-11-15 after playing the demo. Where this section and sections 1–20 disagree, this section wins.

| # | Change | Replaces or extends | Sections it overrides |
| --- | --- | --- | --- |
| 1 | Tools used by hand, energy, bulky objects carried in the hands, movable objects | The single context action with no tools | 4, 13, 15 |
| 2 | Hoe, watering can and seeds on a hotbar; wild forage; fishing | Act-key tilling and unlimited watering | 4, 12, 15 |
| 3 | Effects for harvests, finished orders, and coins gained or spent | Text toasts only | 6, 8 |
| 4 | Farmhouse interior with a bed; a 5-second fast-forward clock scene when sleeping | A prompt at the farmhouse door | 12, 14 |
| 5 | Gatherable resources: trees, wild flowers and wild plants, stone, ore, well water | No raw materials | 10, 13 |
| 6 | A notification with sound when a new order arrives | Silent board refill | 8 |
| 7 | Gates with a keeper at the map edges | Fences and unseen walls | 12 |
| 8 | Trade window with a basket, quantity steppers and Confirm | Buy and Ship buttons that act at once | 8, 10 |

### How the reference games are used

Two published games were named as references for how these mechanics should feel: one for tool use, resource gathering and carrying objects, one for planting, foraging and fishing. As with the art references in Appendix A, they set mechanics and feel only. No name, character, item, map, art, sound, text or tuning number is taken from either. Every definition in this section is original to Mosswake Farm, and risks 8 and 9 of section 19 apply to it in full.

### 21.1 Tools, energy and carrying

Every physical job is done with a tool the player owns. Holding the act key fills a work ring over the target; each full ring is one unit of work and costs energy.

| ID | Tool | Used on | One ring does | Rings needed (tier 1) | Energy per ring |
| --- | --- | --- | --- | --- | --- |
| `tool_hoe` | Hoe | Field ground | Tills one tile | 1 | 2 |
| `tool_watering_can` | Watering Can | Tilled soil and crops; the well or pond | Waters one tile (1 charge), or refills all 10 charges | 1 | 1 |
| `tool_sickle` | Sickle | Wild plants, weeds, withered crops | Cuts and collects | 1 | 1 |
| `tool_axe` | Axe | Trees, stumps | Fells the tree or clears the stump | 5 (stump 3) | 4 |
| `tool_pickaxe` | Pickaxe | Stone outcrops, ore veins | Breaks the node | 5 (ore 6) | 4 |
| `tool_rod` | Fishing Rod | Water | One cast | 1 | 3 |
| `tool_net` | Bug Net | Insects | Catches one | 1 | 1 |

Rules:

- **Work ring.** A ring takes 0.5 real seconds. Letting go keeps the progress on that object for 10 seconds. The target shakes and throws chips on every ring.

- **Choosing a tool.** The player picks the tool. Tools, seeds, food and placeable objects sit on a 10-slot hotbar (number keys, or shoulder buttons on a gamepad). A resource only responds to a tool that fits it: an Axe on a tree, a Pickaxe on stone. With the wrong thing in hand the prompt says what is needed ("Needs an Axe") and nothing happens.

- **Durability.** Every tool has 100 durability and loses 1 per ring. At 0 the tool is Dull: it still works, but each ring takes twice as long. A tool is never lost.

- **Repair.** Tobin repairs any tool for free until the player builds the Tool Bench. From then on repairs are done at the bench and cost materials: 2 Wood for a wooden tool, 2 Wood and 1 Ore for a tier 2 tool.

- **Tool Bench.** A new building (proposed: level 5, 400 coins, 10 Wood, 6 Stone). It repairs tools and makes tier 2 tools from Wood, Stone and Ore (proposed: 4 Wood, 4 Stone and 8 Ore each). Tier 2 needs one ring fewer on trees, stone and ore, costs 25% less energy, has 200 durability, and gives the can 20 charges. Tier 3 is left for a later release.

- **Energy.** The player has 100 energy. Sleeping restores all of it; eating restores an amount set per food item. At 0 the player is Tired: rings take twice as long, the character sways, small stars circle its head and the edges of the screen blur slightly (a dizzy effect). The player never faints and nothing is lost.

- **Spirits.** Tree Spirits use no tools and no energy; they keep their own stamina (section 9). A Rootling now also saves the player the walk to the well.

**Bulky objects.** Logs and Stone Blocks are too big for the backpack. The player carries one at a time in both hands, walks at 70% speed and cannot use tools while carrying. The act key puts it down on the ground or onto a stockpile.

| Object | From | Stored on | Turned into |
| --- | --- | --- | --- |
| Log (`mat_log`) | Felled trees | Log pile (holds 12) | 4 Wood at the Sawhorse (3 rings) |
| Stone Block (`mat_stone_block`) | Large stone outcrops | Stone pile (holds 12) | 4 Stone at the Sawhorse's twin, the Splitting Block (3 rings), or used whole in buildings |

**Movable objects.** Storage Chests, stockpiles, the Sawhorse and the Splitting Block are placed by hand on any free farm tile. An empty one can be picked up and carried like a bulky object. This replaces the fixed chest pad of the demo.

### 21.2 Gatherable resources

The farm map gains things to gather. Each is a resource node with a tool, a number of rings, a yield and a regrowth rule, defined in data.

| Node | Tool | Rings | Yield | Comes back |
| --- | --- | --- | --- | --- |
| Tree | Axe | 5 | 2 Logs and 1–2 Wood (branches) | Leaves a stump. A sapling grows back to a full tree in 3 game days; clearing the stump (3 rings, 1 Wood) stops that |
| Wild flower (grows by itself) | Sickle | 1 | 1 Wild Flower; 30% chance of 1 Wild Seeds; 20% chance an insect jumps out | New ones appear at dawn on free grass, up to 8 on the farm |
| Wild plant (grows by itself) | Sickle | 1 | 1 Fibre; 40% chance of 1 Wild Seeds; 25% chance an insect jumps out; 5% chance of a Clover | New ones appear at dawn, up to 10 on the farm |
| Stone outcrop | Pickaxe | 5 | 3 Stone | After 5 game days |
| Large stone outcrop | Pickaxe | 8 | 1 Stone Block and 2 Stone | After 7 game days |
| Ore vein | Pickaxe | 6 | 2 Ore | After 7 game days |
| Well | Watering Can | 1 | Refills the can | Always |

The 5% Clover from wild plants is the "clearing weeds" source that section 6 already names. Every chance is shown in the node's tooltip (pillar 3).

**Insects.** When a cut plant releases an insect it hops on the spot for 3 seconds. Walking up and using the Bug Net catches it. There are two: the Meadow Hopper (day) and the Glow Beetle (night, rarer).

**Wild Seeds.** A Wild Seeds packet grows into a random crop the player has already unlocked. It is a free way back into farming and never yields a blueprint species.

**Compost.** A Compost Bin (placed by hand; 6 Wood to make) turns 4 pieces of plant matter and 1 insect into 2 Compost by the next dawn. Plant matter is Fibre, Wild Flowers, cleared withered plants (which now give 1 Plant Scraps) or any Common crop. Compost is the fertilizer of 21.3.

### What each resource is for

Pillar 1 asks that every output feeds at least two systems.

| Resource | Uses |
| --- | --- |
| Wood | Building and upgrade costs; crafting chests, stockpiles, the Sawhorse, the Splitting Block and the Compost Bin; tool repair |
| Log | Sawn into Wood; used whole in the Barn and the Research Station |
| Stone | Building and upgrade costs; tier 2 tools; the Merge Table upgrade |
| Stone Block | Split into Stone; used whole in the Research Station and the Spirit Bench |
| Ore | Tier 2 tools and their repair; the second Merge Table upgrade |
| Fibre | Compost; Feed (4 Fibre make 1 Feed); pressed into Sap as a common plant |
| Wild Flower | Orders from Tobin and Ilse (it is a flower); Compost; pressed into Sap |
| Plant Scraps | Compost |
| Insect | Compost; fishing bait (a bite comes twice as fast); a treat for chickens (+25 Happiness, section 5) |
| Water | Charges of the Watering Can |

**Building costs gain materials.** Proposed first values, for the Economy Balancer to tune: Storage Chest 8 Wood and 20 coins (was 100 coins); Merge Table 250 coins and 10 Wood; Barn 1,200 coins, 6 Logs and 10 Stone; Research Station 2,000 coins, 4 Logs and 2 Stone Blocks; Spirit Bench 1,500 coins and 2 Stone Blocks. Field prices do not change (decision Q9).

### 21.3 Farming, foraging and fishing

Farming becomes work done with tools on open ground, foraging gives a reason to walk the map each morning, and fishing is a new way to spend the wait while crops grow.

**Farming: what changes from demo 0.9**

| Aspect | Demo 0.9 | Revision 2 |
| --- | --- | --- |
| Land | Six fixed plots per field, bought with coins | The farm is divided into lots. A lot is opened by paying the Kingdom Land Tax once (the field prices of section 10, under a new name). Inside an owned lot any free tile can be tilled, up to 12 tilled tiles per lot. The player starts with 2 lots and can open 4 more: 72 tiles in all |
| Tilling | Act key | Hoe: 1 ring, 2 energy. Tilled soil left empty for 2 game days grows over again |
| Planting | The selected seed and the act key | The seed is chosen on the hotbar; one seed per tilled tile |
| Watering | Act key, never runs out | Watering Can: 1 charge per tile, 10 charges, refilled at the well or the pond. Soil is either dry or moist; moist soil is darker |
| Growth | By game hours while the soil is moist | By days. At each dawn (06:00) a crop whose soil is moist grows by one day; then all soil dries. A crop that was not watered does not grow that day |
| Withering | After 24 dry hours, or 48 hours unharvested | After 2 dawns in a row with dry soil, or 2 days unharvested. Still never the seed back (pillar 4: at most one planting lost) |
| Harvest | Act key | By hand, with the harvest effect of 21.4 |
| Clearing a withered plant | Act key | Sickle: 1 ring, gives 1 Plant Scraps |

**Growth in days** (1 game day = 24 real minutes):

| Crop | Demo 0.9 | Revision 2 | Regrows |
| --- | --- | --- | --- |
| Wheat | 4 hours | 1 day | – |
| Carrot | 6 hours | 1 day | – |
| Sunflower | 8 hours | 2 days | – |
| Tomato | 10 hours | 2 days | 1 day, 4 harvests |
| Ancient Carrot | 14 hours | 3 days | – |

The value formula of section 10 is kept and re-run with the new growth times and 12 tiles per lot; item values, order budgets and the land tax amounts are re-derived in step R2-A.

**Weather** is rolled at each dawn and is pulled forward from release R1. No weather destroys anything.

| Weather | Chance | Effect |
| --- | --- | --- |
| Sunny | 55% | None |
| Rain | 20% | All soil is moist for the day; the can is not needed; animals stay indoors |
| Warm Rain | 10% | As Rain, and at the next dawn every crop grows two days instead of one |
| Mist | 10% | Twice as many wild plants and insects appear; Root-sense reaches 1 tile farther at the dig site |
| Storm | 5%, never two days running | As Rain; spirits work at 75% speed; each Mature crop has a 10% chance of +1 yield |

**Fertilizer** is also pulled forward. One fertilizer per tile per planting, put on tilled soil before or after sowing.

| Fertilizer | Made from | Effect |
| --- | --- | --- |
| Compost | Compost Bin: 4 plant matter and 1 insect (21.2) | The crop needs one day less to grow. A crop that already grows in 1 day gives +1 yield instead |

Rich Compost, Gene Mulch and Spirit Loam stay in the releases where section 4 puts them. Seasons and quality stay in release R1.

**Foraging.** Wild flowers and wild plants appear at dawn on free grass (21.2). They are cut with the Sickle. Nothing wild ever blocks a field tile or a path.

**Fishing.** A pond is added to the south-west of the farm map. Fishing has four steps:
1. Cast. Face the water with the Fishing Rod and press the act key (3 energy).

2. Wait. A bite comes after 3 to 12 seconds; bait halves the wait. The float dips and a sound plays.

3. Hook. Press the act key within 1 second of the bite. Too late and the fish is gone; only the bait is lost.

4. Reel. A tension gauge appears. Holding the act key raises the tension, letting go lowers it. Keep the needle inside the green band until the catch bar fills. The band is narrower for rarer fish. Leaving the band for 2 seconds in a row loses the fish.

In keeping with pillar 3, the Fishing Log shows each species, when it bites and its odds; three lost fish in a row widen the next band by 25%; bait and the rod tier improve the odds.

| ID | Fish | Rarity | Bites | Proposed value | Uses |
| --- | --- | --- | --- | --- | --- |
| `fish_pond_minnow` | Pond Minnow | Common | Any time | 10 | Orders (Mara), food (+10 energy) |
| `fish_mosscarp` | Mosscarp | Common | Day | 18 | Orders (Mara), food (+15 energy) |
| `fish_reedfin` | Reedfin | Uncommon | Dawn and dusk | 40 | Orders (Mara), food (+25 energy) |
| `fish_moonscale` | Moonscale | Rare | Night | 120 | Orders (Mara, Ilse), research (as a Rare good) |

The Economy Balancer sets the final values so that a minute of fishing earns no more than a minute of tending a full carrot field.

### 21.4 Feedback: effects and notifications

Every gain and every cost is shown where it happens, with a sound, so the player never has to read a number to know what changed.

| Event | What the player sees | Sound |
| --- | --- | --- |
| Tool ring | The target shakes by 2 px and throws 3–4 chips in its own colour | One per tool: thud, chop, chink, splash |
| Harvest | The plant squashes and springs back, 4–6 leaf bits fly out, the item's icon arcs into the hotbar, "+2" floats up | Pluck |
| Catch (fish or insect) | The catch arcs to the hotbar with its name | Splash or flutter |
| Order delivered | The card is stamped "Delivered", a burst of 12 confetti bits in palette colours, coins fly from the card to the coin counter | Short fanfare |
| Coins gained (order, sale, bin payout) | Coin icons fly to the counter, the counter counts up, "+42" floats in green | Coin chime, one per batch |
| Coins spent (purchase, fee, building) | "−250" drops from the counter in red, the counter counts down | Soft thud |
| New order | The order board in the world shows a mark above it, a board icon bounces at the screen edge, a toast names the NPC | Bell |
| Level up, story complete | Unchanged from demo 0.9 | Unchanged |

Rules:

- No effect lasts longer than 0.6 seconds or stops the player from moving or acting.

- New-order bells are batched: one bell for all orders that arrive within the same game minute, and none during the sleep scene (the dawn summary lists them instead).

- Effects use the master palette only; glow colours stay under the 5% limit of Appendix A.

- A "Fewer effects" setting turns the particles and flying icons off and keeps the numbers and sounds.

### 21.5 Farmhouse interior and sleeping

The farmhouse door now leads into a room, and sleeping is a 5-second scene of the clock running forward.

- **Interior.** One room of 10×8 tiles: a bed, a table, a window that shows the time of day outside, and the door mat that leads back out. Entering and leaving is a 0.3-second fade. Game time keeps running indoors.

- **Bed.** Using the bed asks "Sleep until 06:00?". Sleeping is allowed at any hour.

- **Sleep scene.** It lasts exactly 5 real seconds. The room dims, a clock face fills the middle of the screen and its hands spin from the current time to 06:00, the window turns from night to dawn, and the day counter flips. The simulation advances underneath in the 10-minute steps of section 14, spread evenly over the 5 seconds and cannot be skipped (decision Q7).

- **Waking.** Energy is full, the game is saved, and a dawn summary card lists what happened overnight: the shipping bin's payout, new orders, spirit upkeep, crops that ripened.

This replaces the door prompt of the demo (decision P-27). The save rules of section 14 do not change.

### 21.6 Area gates

The edges of the farm map get gates with a keeper instead of fences and unseen walls, so the player can see that the world goes on.

| Gate | Leads to | Opens in |
| --- | --- | --- |
| East gate | Village Market | Release R1 |
| North gate | Ancient Forest edge | Release R3 |
| South gate | A fourth area, not yet designed | After 1.0 |

- Each gate is a closed wooden gate across a path, with a gatekeeper NPC standing beside it.

- Talking to the gatekeeper (act key) opens a dialogue box with a portrait and one line: "This area is not open yet!" (shown in Vietnamese as "Khu vực chưa được mở!", kept for the later Vietnamese localisation, decision Q8).

- When a later release opens an area, its gate stands open and the keeper's line changes.

- The rest of the border is closed by things the eye accepts: hedges, rocks, water. There are no unseen walls.

- The dialogue box is a new, reusable UI piece; later NPC conversations use it too.

Mara, Tobin and Ilse keep their stalls inside the farm by the east gate until the Village Market exists.

### 21.7 Trade window

Buying and selling go through one window with a basket: the player collects what to trade, adjusts the amounts, and nothing happens until Confirm is pressed.

```text
+-- Tobin's cart ------------------------------------------- [ Buy ] [ Sell ] --+
| Stock                          | Basket                                       |
| [icon] Carrot Seeds      4     | [icon] Carrot Seeds    4 each   [-]  6 [+]   |
| [icon] Wheat Seeds       2     | [icon] Wheat Seeds     2 each   [-]  3 [+]   |
| [icon] Tomato Seeds     20     | [icon] Clover         40 each   [-]  1 [+]   |
| [icon] Clover           40     |                                              |
| [icon] Chicken         150     |                                              |
|                                | Total: 70 coins                              |
|                                | You have 182  ->  112 after this trade       |
|                                |                    [ Confirm ]  [ Cancel ]   |
+--------------------------------------------------------------------------------+
```

Rules:

- **Left side.** On the Buy tab it lists the seller's stock with unit prices; locked rows say what unlocks them. On the Sell tab it lists the player's sellable goods with what each fetches.

- **Adding.** Choosing a row on the left puts 1 of it in the basket.

- **Basket.** Each line shows the icon, name, unit price and the quantity with a minus and a plus button on its right. Each press changes the quantity by 1; holding repeats; at 0 the line leaves the basket.

- **Footer.** The total, and the player's coins before and after. Confirm is greyed out with the reason when the trade cannot be made: not enough coins, no room in the backpack, no free place in the Coop or Barn.

- **Confirm.** Only now do coins and items change, with the coin effect of 21.4. Cancel or Esc closes the window and changes nothing.

- **Limits.** A quantity cannot exceed what the seller offers, what the player holds, or free housing places for animals. Goods an active story step needs cannot be put in the Sell basket; the row says who is waiting for them.

**Where it is used.** Tobin's cart uses it for buying and for selling. Tobin pays the shipping-bin rate of section 10 (80%) at once, and the rule that lowers the price of a tier 3+ good after 5 units a day counts bin and cart together. The shipping bin stays for goods the player wants to drop off without walking to the gate; it uses the same basket and still pays at dawn (decision Q6).

### 21.8 Data and MVP scope

Revision 2 adds four definition types, about 22 items and a new save version. Everything stays data-driven: a new tool, node or fish is a row of JSON plus sprites.

| New or changed | What it holds |
| --- | --- |
| `ToolDefinition` (`tool_*`) | Target kinds, rings, energy and durability per tier, repair and crafting cost, can capacity |
| `ResourceNodeDefinition` (`node_*`) | Tool, rings, yield table with chances, regrowth days, spawn rule for wild plants |
| `FishingDefinition` | Bite wait, hook window, band width per rarity, pity rule; species per time of day |
| `GateDefinition` (`gate_*`) | Position, the area it leads to, the keeper, the line spoken while closed |
| `WeatherDefinition` | Chance and effects of each weather |
| `ItemDefinition` | Two new fields: `bulky` (carried in the hands) and `energy` (restored when eaten) |
| `CropDefinition` | `growthDays` and `regrow.days` replace the hour fields; moisture and water interval go |
| `BuildingDefinition` | `materials` per level are now used in the MVP; new buildings Tool Bench and (placed by hand) Compost Bin |
| Player state | `energy`; tier and durability of each tool; the hotbar |
| World state | Felled trees and broken nodes with their regrowth day, wild plants, placed and dropped objects, tilled tiles with moist or dry soil and fertilizer, today's weather |
| Save | `saveVersion` 2. A migration turns a version 1 save's fixed plots into tilled tiles in the same places, converts growth so far into days, and gives the player the tier 1 tools |

**MVP content after Revision 2** (changes to section 15):

| Area | Demo 0.9 | Revision 2 |
| --- | --- | --- |
| Item definitions | 32 | About 56: plus 7 tools, Wood, Log, Stone, Stone Block, Ore, Fibre, Plant Scraps, Compost, Wild Flower, Wild Seeds, 2 insects, 4 fish |
| Tradeable goods | 18 | 23: plus Wild Flower and 4 fish |
| Land | 2 fields plus 4 to buy, 36 plots | 2 lots plus 4 opened by the Kingdom Land Tax, 12 tilled tiles each, 72 tiles |
| Buildings | 8 | 9: plus the Tool Bench |
| Scenes | Farm map, dig site | Farm map with a pond, trees, outcrops and gates; farmhouse interior; dig site |
| Placed by hand | Nothing | Storage Chest, Log pile, Stone pile, Sawhorse, Splitting Block, Compost Bin |
| Screens | Shop, shipping bin | One trade window; dialogue box; Fishing Log; dawn summary; sleep scene |
| Systems pulled forward from R1 | – | Weather; one fertilizer (Compost) |
| Out of the MVP | As in section 15 | Also: tool tier 3, more fish and insects, cooking, fences and paths built by the player |

The acceptance row "All 32 definitions load" of section 20 becomes "all item definitions load".

### 21.9 Build steps, acceptance and risks

Revision 2 is built in six steps before the outside playtest of M6, which now waits for demo 0.10. Each step ends in a build the Director can play and a go or no-go.

| Step | Content | Depends on |
| --- | --- | --- |
| R2-A | Data and schemas for tools, nodes, fishing, gates, weather and the new items; growth in days; values, order budgets and land tax re-derived for 72 tiles; building material costs; save version 2 with its migration; simulator extended | This section approved |
| R2-B | Hotbar and tool choice, work ring, energy and the dizzy effect, durability and free repair at Tobin's cart; lots and free tilling; daily watering and growth at dawn; weather; refilling at the well | R2-A |
| R2-C | Trees, stone and ore nodes; carrying Logs and Stone Blocks; stockpiles, Sawhorse and Splitting Block; movable objects; the Tool Bench with tier 2 tools and paid repair | R2-B |
| R2-D | Wild flowers and wild plants, insects and the Bug Net, Wild Seeds; Compost Bin and Compost; the pond, fishing and the Fishing Log | R2-B |
| R2-E | Farmhouse interior, bed, sleep scene, dawn summary; gates, gatekeepers and the dialogue box | R2-B |
| R2-F | Trade window at Tobin's cart and the shipping bin; effects for harvests, orders and coins; new-order notification; balance pass; demo 0.10 | R2-C, R2-D, R2-E |

**Acceptance criteria added to section 20**

| Feature | Acceptance criteria | Test type |
| --- | --- | --- |
| Tools and energy | Each tool does its data-defined work per ring and costs its data-defined energy. At 0 energy a ring takes twice as long and the player can still act. Sleeping restores all energy. Tier 2 changes rings, energy and can capacity as defined | Automated |
| Watering Can | Watering uses 1 charge per tile and cannot water at 0 charges. The well and the pond refill it in one ring | Automated |
| Resource nodes | Every node yields within its data ranges over 10,000 uses. A felled tree is back after its regrowth time. Wild plants never appear on field tiles, paths, buildings or water, and never exceed their caps | Automated |
| Carrying | A carried object slows the player to the data speed and blocks tools. Nothing is lost or duplicated in 10,000 pick-up, drop and stockpile operations. Every placed object can be picked up again when empty | Automated |
| Fishing | Bite time, hook window and band width match the data. The pity rule widens the band after three losses. Species caught over 10,000 casts match the listed odds within 1 point | Automated |
| Trade window | Nothing changes before Confirm. Cancel changes nothing. The basket can never hold more than can be bought, sold or housed. Totals equal the sum of the lines | Automated |
| Sleep scene | It lasts 5 seconds within one frame. State after it equals state after sleeping without the scene | Automated |
| Gates | Every map edge is closed by a gate or a visible barrier; the player can leave the map nowhere. Every gatekeeper answers with its line | Automated |
| Save migration | A version 1 save loads into version 2 with the same crops in the same places | Automated |
| Feel | Players describe tool use and gathering as satisfying, not as a chore; fewer than 20% say they ran out of energy too often | Playtest |

Rows for the decisions of 21.10:

| Feature | Acceptance criteria | Test type |
| --- | --- | --- |
| Tool choice | A resource reacts only to a fitting tool held on the hotbar; with anything else nothing changes and the prompt names the tool needed | Automated |
| Durability and repair | Each ring costs 1 durability. At 0 the tool is Dull: rings take twice as long and the tool still works. Repair is free at Tobin's cart until the Tool Bench is built, and costs its data materials at the bench afterwards. No tool can be lost | Automated |
| Lots and land tax | A lot opens for its data price, once. No tile outside an owned lot can be tilled, and no lot holds more than 12 tilled tiles | Automated |
| Daily growth | A crop with moist soil at dawn grows exactly one day; a dry one does not. Two dry dawns in a row wither it. Soil is dry after every dawn unless it rains | Automated |
| Weather | Over 10,000 rolled dawns each weather appears within 1 point of its chance and Storm never follows Storm. Rain keeps all soil moist; Warm Rain gives two days of growth | Automated |
| Compost | The Compost Bin turns 4 plant matter and 1 insect into 2 Compost by the next dawn. A composted crop needs one day less, or yields +1 if it already grows in a day | Automated |
| Dizzy effect | At 0 energy the Tired effect shows and work is twice as slow; it clears as soon as energy is above 0 | Automated |

**Risks added to section 19**

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Scope grows by about a third before any outside player has seen the game | High | High | Six playable steps; the Director may stop after any of them; nothing in releases R1–R4 is pulled forward |
| Energy makes chores feel like punishment | Medium | High | Tired is slower, never blocked; energy numbers live in data; a playtest row measures it |
| New sources (fish, forage) and sinks (materials) unbalance the economy | Medium | Medium | The simulator is extended in R2-A; fishing is capped against field income |
| The game reads as a copy of its reference games | Medium | High | Original content only (section 21 rule); the questionnaire's question 11 asks testers directly |
| Spirits lose their point when tools make chores fun | Low | Medium | A Rootling saves energy and can refills; measure session length after the first spirit as before |

### 21.10 Decisions by the Director (2026-11-15)

The Director decided all nine questions on 2026-11-15. Sections 21.1 to 21.9 are written to these decisions.

| # | Question | Decision | What it costs |
| --- | --- | --- | --- |
| Q1 | How is a tool chosen? | The player chooses the tool on the hotbar; a resource reacts only to a fitting tool | A 10-slot hotbar; one more step than a single act key, most felt on a gamepad |
| Q2 | Where can soil be tilled? | Anywhere inside an owned lot, up to 12 tilled tiles per lot. A lot is opened by paying the Kingdom Land Tax once | 72 tiles instead of 36: values, order budgets and tax amounts are re-derived |
| Q3 | How do crops grow? | Watered each day, growing one day at each dawn; weather and Compost can speed the harvest | Growth times change from hours to 1–3 days; weather and one fertilizer are pulled forward from R1. The first harvest now comes after the first sleep, so the "first loop in 10 minutes" row of section 20 is measured to the first delivered order of bought or gathered goods, and is re-checked in playtests |
| Q4 | What happens at 0 energy? | Tired: work is twice as slow, with a dizzy effect | – |
| Q5 | Do tools wear out? | Yes. A worn tool is Dull and slow, never lost. Repair is free at Tobin's cart until the Tool Bench is built, then costs Wood, Stone or Ore at the bench | A new building, the Tool Bench. The Dull rule (slow, not broken) is the designer's reading of pillar 4 and can be changed |
| Q6 | Where are goods sold for coins? | Both: Tobin's cart pays at once, the shipping bin pays at dawn, at the same rate | – |
| Q7 | Can the sleep scene be skipped? | No. Always 5 seconds | – |
| Q8 | What language is the game's text? | English now; Vietnamese as a later localisation | The gatekeeper's line is stored under a text key so that the Vietnamese wording is ready |
| Q9 | Do buildings cost materials as well as coins? | Yes | Proposed amounts in 21.2, tuned in R2-A |
