# Economy simulator report

Scripted hand-played farm, 12 game days, 20 seeds. All game numbers come from `/data`.
Player model: 24 actions per game hour at 75% attention, waters under 35 moisture, reaches ripe crops 1 game hour late, plays every hour of every day.

| Day | Level | Net coins (median) | Net (min-max) | Income | Running cost | Plots | Animals | Coins at dawn |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2 | 97 | 28-193 | 250 | 188 | 12 | 2 | 147 |
| 2 | 3 | 861 | 591-1156 | 934 | 43 | 12 | 4 | 677 |
| 3 | 4 | 548 | 261-975 | 1010 | 494 | 24 | 4 | 346 |
| 4 | 6 | 1394 | 365-2364 | 2106 | 620 | 30 | 4 | 769 |
| 5 | 7 | 2372 | 1412-2846 | 2960 | 586 | 36 | 5 | 564 |
| 6 | 7 | 1834 | 1225-3171 | 2482 | 652 | 36 | 8 | 966 |
| 7 | 8 | 2386 | 1455-3198 | 2988 | 688 | 36 | 8 | 2008 |
| 8 | 9 | 2510 | 1285-3198 | 3288 | 713 | 36 | 8 | 4433 |
| 9 | 10 | 2598 | 1994-3879 | 3284 | 730 | 36 | 8 | 6916 |
| 10 | 10 | 2511 | 1218-3019 | 3210 | 746 | 36 | 8 | 9396 |
| 11 | 10 | 2417 | 1724-3843 | 3138 | 678 | 36 | 8 | 12458 |
| 12 | 10 | 2640 | 1608-3821 | 3469 | 731 | 36 | 8 | 14876 |

## Checks

- FAIL: Phase 1 net income target 300-600 coins per game day, averaged over the 4 days that start at level 1-5. Mean 725; per day: 97, 861, 548, 1394.
- PASS: no major purchase takes more than 3 game days of saving. Longest waits: animal_chicken 2.0 d, bld_research_station 1.2 d, field 1.0 d, bld_barn 1.0 d.
- PASS: every run finishes the three Phase 1 quests (worst run: 3 of 3). Median level after 12 days: 10.
- INFO: median real time to level 5 is 96 minutes (section 20 playtest target: 60-90).

## First purchases (seed 0)

| Game day | Purchase | Cost |
| --- | --- | --- |
| 1.6 | animal_chicken | 150 |
| 2.0 | animal_chicken | 150 |
| 2.0 | bld_merge_table | 250 |
| 2.0 | field | 300 |
| 2.9 | field | 450 |
| 3.3 | field | 675 |
| 4.0 | field | 1012 |
| 4.6 | bld_barn | 1200 |
| 4.8 | animal_cow | 450 |
| 5.3 | animal_cow | 450 |
| 5.5 | animal_cow | 450 |
| 5.6 | animal_cow | 450 |
| 6.7 | bld_research_station | 2000 |

**Overall: FAIL**
