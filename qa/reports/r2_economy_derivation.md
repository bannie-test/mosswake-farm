# Revision 2 economy derivation

Section 10's formulas re-run with crops that grow by days (1 game day = 24 hours) and 12 tilled tiles per lot. Nothing here is applied yet; step R2-B applies it with the daily-growth code.

## Crop values

`baseValue = (CPH(rarity) x total growth hours + seed cost) / total yield`

| Crop | Growth now | Growth in R2 | Seed | Value now | Value in R2 | Net coins per tile per day |
| --- | --- | --- | --- | --- | --- | --- |
| Carrot | 6 h | 1 d | 4 | 8 | 26 | 48 |
| Wheat | 4 h | 1 d | 2 | 3 | 17 | 49 |
| Tomato | 10 h | 2 d, regrows in 1 d x4 | 20 | 6 | 22 | 49 |
| Sunflower | 8 h | 2 d | 6 | 22 | 102 | 48 |

Every Common crop still earns about 2 coins per tile-hour (48 per day), as section 10 intends; only the rhythm changes.

## Merged goods

`value = k(rarity) x sum of ingredient values`

| Recipe | Value now | Value in R2 |
| --- | --- | --- |
| Premium Carrot | 30 | 98 |
| Golden Carrot | 130 | 426 |
| Crystal Carrot | 700 | 2300 |
| Premium Tomato | 22 | 82 |
| Golden Tomato | 96 | 356 |
| Sun Bouquet | 82 | 382 |

Animal products and what is merged from them keep their values: animals still produce by the hour.

## Blueprint species

- Ancient Carrot Seeds: 225 -> 620. Ancient Carrot: 220 -> 740 (grows in 3 days).

## Land

- Tilled tiles: 24 at the start, 72 with all 6 lots (was 12 and 36).
- Kingdom Land Tax, paid once per lot: 300, 450, 675, 1012 coins (the field prices of section 10, unchanged for now).
- A full farm of Common crops earns about 3,456 coins per game day before orders pay their 1.3x (was about 1,728).

## What this moves, and what R2-B must re-tune

| Number | Effect of the change | Action |
| --- | --- | --- |
| Order budget (40 + 25L + 3L^2 in goods value) | The same value now buys about a third as many crop units, so early orders ask for 2-3 Carrots | Keep the formula; check that order quantities stay above 1 at level 1 |
| Harvest XP (1 per unit x rarity rank) | A tile is harvested once a day instead of four times, so harvest XP falls to about a quarter | Raise harvest XP per unit, or lean on order and quest XP; measure with the 60-minute session test |
| Income targets of section 10 | Twice the tiles at the same coins per tile-hour doubles top income | Re-tune the land tax so that the next lot costs 1-2 game days of income |
| Energy (100) | 24 tiles need 24 energy to water and 48 to till once; 72 tiles cannot all be worked by hand in one day | Intended: it is what makes a Rootling worth waking. Check with the simulator that a level 1 farm fits in one energy bar |
| Watering Can (10 charges) | 24 tiles need 3 walks to the well per day | Check the walk time on the real map |
| Story: Ancient Carrot | The chain costs more coins but the same number of Carrots (27 per Golden Carrot) | None |
| First loop in 10 minutes (section 20) | The first harvest now comes after the first night | Decision Q3: measured to the first delivered order |
