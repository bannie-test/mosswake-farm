## 20. MVP Acceptance Criteria

The MVP is accepted when every row below has a passing, recorded test. Automated rows run in CI; playtest rows use the 15 outside players of M6.

| Feature | Acceptance criteria | Test type |
| --- | --- | --- |
| 5 crops | Each crop passes through all stages at its data-defined times within ±1 game minute. Growth pauses at 0 moisture. A crop withers after exactly 24 dry game hours. Tomato regrows 3 times, then clears | Automated |
| 3 animals | Each produces at its interval when fed and happy. Production stops at 0 hunger and resumes on feeding. No animal can die. Housing capacity is enforced | Automated |
| Items | All 32 definitions load. Every ID referenced by any definition exists. Each item is usable in every system its data says it is | Automated |
| 10 merge recipes | Over 100,000 simulated rolls per recipe, success rate is within 0.5 points of the formula. Pity guarantees success by the calculated attempt. A failure returns half the inputs and the correct Stardust. The displayed percentage equals the rolled percentage | Automated |
| Merge experience | At least 70% of playtesters attempt a Rare merge. Fewer than 20% describe merging as unfair | Playtest |
| 3 NPCs and reputation | Each NPC offers orders from its tag pool only. Reputation rises by the defined amounts and unlocks the defined rewards at each threshold | Automated |
| Delivery orders | 1,000 generated orders at each level 1–10 are completable with content unlocked at that level, within 24 game hours of that level's typical capacity. No board ever has zero orders that are at least half fillable from typical stock | Automated fuzz |
| Progression | A new save reaches level 10 using only unlocked content. Median playtest time to level 5 is 60–90 minutes. The unlock graph test finds no unreachable node | Automated and playtest |
| Farm map | 60 fps on Steam Deck with 36 plots planted, 12 animals and 1 spirit. No Y-sort errors in the scripted walk-around. Every interactable can be reached | Automated and manual |
| Inventory and storage | Stacks split and merge correctly at 99. Stations draw from backpack and chests. Nothing is lost or duplicated in 10,000 random transfer operations | Automated |
| Basic crafting | Feed, Sap, Revival Potion and Ancient Carrot Seeds consume and produce exactly what their data states | Automated |
| Research | A Golden Carrot yields 3 fragments, 6 the first time. The blueprint unlocks at 10 fragments and consumes them. Seed creation yields 4 seeds. 80% of playtesters harvest an Ancient Carrot unaided | Automated and playtest |
| Tree Spirit | Root-sense marks are always correct. The husk is always reachable within the digs provided. A Rootling keeps a 16-tile zone from reaching 0 moisture for 3 game days. It rests at 0 stamina and returns. Unpaid upkeep halves its speed and nothing else. No stuck state in a 2-hour soak at 20× speed | Automated |
| Automation is optional | A scripted player with no spirit reaches the end of MVP content | Automated |
| Automation is rewarding | At least 70% of playtesters say they want a second spirit. Median session length does not fall after the first spirit | Playtest |
| Core loop | A new player completes Plant → Grow → Harvest → Merge → Order → Reward within 10 minutes without external help | Playtest |
| Economy | The exploit test finds no buy-and-resell profit. Simulated and playtest income per game day agree within 20%. The next major purchase is never more than 3 game days of income away | Automated and playtest |
| Save and load | Save, quit, load reproduces identical state, including random streams. A save from each earlier milestone build loads through migrations | Automated |
| Art consistency | Every sprite passes asset lint: palette, size, alpha, naming. The human art lead has approved every asset in the style-sheet scene | Automated and manual |
| Stability | No crash in 20 hours of combined playtest. No blocker or critical bug open | Playtest |
