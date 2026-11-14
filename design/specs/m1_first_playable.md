# M1 feature specs: first playable

Derived from GDD sections 4, 6, 8, 10, 13, 14 and 17 (M1). Every number named here lives in
`/data`; this file only states rules. Objective of M1: Plant -> Grow -> Harvest -> Merge ->
Complete NPC order -> Earn reward, by a new player in under 10 minutes with on-screen prompts only.

## 1. Time (`Sim`)

- 1 game hour = `time.realSecondsPerGameHour` real seconds. A new game starts at `time.newGameHour`.
- Every system implements `advance(delta_game_minutes)`; steps never cross an hour boundary.
- `hour_changed` fires on each hour, `dawn` at `time.dayStartHour`. Night is `nightStartHour`-`dayStartHour`.
- Time keeps running while a screen is open. No wall-clock time is stored.
- Tests: a day delivers 1,440 minutes, 24 hour events, 1 dawn; frame-sized steps do not drift.

## 2. Plots and crops (`Farm`), Carrot and Wheat

State per plot is `FarmPlotState` (section 14). States: `empty` -> `tilled` -> `growing` -> `mature`
-> (`regrowing` | `tilled`), and `withered` from any planted state.

| Action | Allowed when | Effect |
| --- | --- | --- |
| Till | `empty` | -> `tilled` |
| Plant | `tilled`, seed in the backpack | consumes 1 seed; -> `growing`; moisture is unchanged |
| Water | any state except `empty` and moisture below 100 | moisture = 100; dry timer = 0 |
| Harvest | `mature` | adds `yield` units of the product (Q1 in the MVP); XP = units x `xpPerUnit`; then `regrowing` if the plant regrows and harvests remain, else `tilled` |
| Clear | `withered` | -> `tilled`; the seed is not returned |

Rules:
- While planted, moisture drains by 100 / `waterIntervalHours` per game hour. Growth advances only
  while moisture is above 0. Inside one step the wet part grows and the dry part runs the dry timer.
- Stage = growth fraction against the `stages[].until` thresholds; at 1.0 the plot is `mature`.
- Withers after `witherDryHours` consecutive dry hours, or `witherUnharvestedHours` after maturing.
- `everDry` records whether moisture ever reached 0 (used by Well Tended from R1).
- Regrowing crops return to the growing stage and need `regrow.hours` more.
- Edge cases: watering a mature crop is allowed (it stops the dry timer); planting with no seed
  does nothing and says so; a full backpack blocks the harvest and says so; nothing is lost.
- Out of M1: quality, fertilizer, seasons, weather, mutation.
- Tests: each stage starts within +-1 game minute of its data time; growth pauses at 0 moisture;
  withers after exactly `witherDryHours`; watering resets the dry timer; a regrowing plant gives
  `maxHarvests` harvests, then clears.

Display: dry soil is lighter than wet soil; a moisture ring under each plant (amber under 30);
a 2-frame sparkle on a Mature crop; harvest pops the goods out.

## 3. Inventory (`Inventory`)

- Shape is `InventoryState`. Backpack has `newGame.backpackSlots` slots. Stack key is item ID +
  quality; stack limit is the item's `stackSize`.
- `add` routes by the item's `storage`: `inventory` -> backpack, `wallet` -> wallet, `silo` -> silo.
  It fills existing stacks first, then free slots, and returns the quantity that did not fit.
- `remove` takes the lowest quality first. `count` sums backpack and chests.
- Tests: stacks split at the stack limit; add then remove returns to the same state; nothing is
  lost or duplicated in 10,000 random operations.

## 4. Merge (`Merge`), two recipes: Premium Carrot, Golden Carrot

- Chance: `P = min(100, min(cap, base + charm + blessing + table + mastery + quality) + pityStep x f)`
  with every term from `merge_config.json`. The displayed number is the number rolled against.
- Fee = round(`feeRatio` x output value) coins, paid on every attempt; XP gained = the fee.
- Success: inputs consumed, 1 output. Critical (rolled only on a success): chance `critBase` +
  `critPerMastery` x mastery points; output doubled.
- Failure: fee and charm consumed; each input keeps max(1, floor(qty x `failRefundRatio`)) units;
  Stardust by recipe rarity; pity +1. Pity resets on success. Mastery = +1 per
  `masteryPerSuccesses` successes, up to `masteryMax`.
- Rolls come from the `merge` random stream, so a reload cannot change a result.
- Blocked (nothing consumed) when: recipe unknown, inputs missing, not enough coins for the fee.
- Tests: chance equals the formula for every tier; pity guarantees success by the calculated
  attempt; a failure returns half the inputs; over many rolls the success rate matches.

Screen (three columns, section 6): recipe list with "can afford" counts; table with ingredient
slots; result with value, the percentage in large type, the fee, the term-by-term breakdown and the
cost-of-failure line. Confirmation only when the chance is under 100% and a Rare-or-better
ingredient, a Q4 ingredient or a lucky item would be consumed. Basic recipes offer "Merge xN".

## 5. Orders and rewards (`Orders`), Mara only

- M1 uses a fixed list (`game/dev/m1_scenario.json`); the generator of section 8 arrives in M2.
- An order is an `OrderDefinition`. Coins = round(value x `saleRate.delivery`), XP = round(value x
  `xpRate.delivery`), reputation = `reputation.delivery`. Value = sum(qty x base value).
- Mara shows `orderRules.deliverySlots` orders. A delivered slot refills after
  `orders.refillMinutes.completed` game minutes with the next order of the list.
- Delivery needs every line in stock; goods leave the backpack, rewards arrive at once.
- XP raises the level by the curve `scale x round(factor x L^exponent)`; reputation never decreases.
- Deadlock rule (section 10): with fewer than `deadlock.coinsBelow` coins, no seeds and nothing
  growing, Mara gives `giftQty` Carrot seeds, once per game day.
- Tests: rewards equal the formula; delivery without stock changes nothing; the slot refills on time.

## 6. M1 scaffolding (removed in M2)

The data gates the Merge Table behind level 3 and 250 coins and sells seeds in a shop, neither of
which fits a 10-minute first loop. `game/dev/m1_scenario.json` therefore: starts with a built
Merge Table and the two carrot recipes known; holds Mara's fixed order list; lets orders hand
out seeds as `bonusItems` because the shop arrives in M2. None of this is game data.
