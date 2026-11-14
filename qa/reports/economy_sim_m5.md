# Economy simulator report

Scripted hand-played farm, 12 game days, 20 seeds. All game numbers come from `/data`.
Player model: 24 actions per game hour at 75% attention, waters under 35 moisture, reaches ripe crops 1 game hour late, plays every hour of every day.

| Day | Level | Net coins (median) | Net (min-max) | Income | Running cost | Plots | Animals | Coins at dawn |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 2 | 152 | -2-285 | 266 | 122 | 12 | 2 | 150 |
| 2 | 3 | 704 | 330-954 | 862 | 130 | 12 | 4 | 575 |
| 3 | 4 | 581 | -54-818 | 945 | 390 | 18 | 4 | 335 |
| 4 | 5.5 | 1384 | 557-2042 | 1978 | 505 | 30 | 4 | 703 |
| 5 | 7 | 2212 | 746-2803 | 2918 | 704 | 36 | 4 | 659 |
| 6 | 7 | 2029 | 1401-2733 | 2646 | 630 | 36 | 8 | 1386 |
| 7 | 8 | 2406 | 1343-3383 | 3196 | 740 | 36 | 8 | 1373 |
| 8 | 9 | 2574 | 1319-3455 | 3269 | 708 | 36 | 8 | 4026 |
| 9 | 10 | 2646 | 1352-3771 | 3348 | 728 | 36 | 8 | 6710 |
| 10 | 10 | 2829 | 1359-3808 | 3532 | 705 | 36 | 8 | 9346 |
| 11 | 10 | 2725 | 1689-3523 | 3494 | 688 | 36 | 8 | 12210 |
| 12 | 10 | 2708 | 1645-4199 | 3536 | 724 | 36 | 8 | 14438 |

## Checks

- FAIL: Phase 1 net income target 300-600 coins per game day, averaged over the 4 days that start at level 1-5. Mean 706; per day: 152, 704, 581, 1384.
- PASS: no major purchase takes more than 3 game days of saving. Longest waits: field 1.8 d, animal_chicken 1.6 d, bld_research_station 1.2 d, bld_barn 1.1 d.
- PASS: every run finishes the three Phase 1 quests (worst run: 3 of 3). Median level after 12 days: 10.
- INFO: median real time to level 5 is 96 minutes (section 20 playtest target: 60-90).

## First purchases (seed 0)

| Game day | Purchase | Cost |
| --- | --- | --- |
| 1.2 | animal_chicken | 150 |
| 2.0 | animal_chicken | 150 |
| 2.0 | bld_merge_table | 250 |
| 2.2 | field | 300 |
| 3.5 | field | 450 |
| 4.0 | field | 675 |
| 4.4 | field | 1012 |
| 4.8 | bld_barn | 1200 |
| 5.0 | animal_cow | 450 |
| 5.4 | animal_cow | 450 |
| 5.8 | animal_cow | 450 |
| 6.1 | animal_cow | 450 |
| 6.9 | bld_research_station | 2000 |

**Overall: FAIL**
