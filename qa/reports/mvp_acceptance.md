# MVP acceptance (GDD section 20)

Status of every row on the M6 candidate (version 0.9.0). "Automated" rows are checked by
`tools/run_checks.sh` on every run; the test that covers each row is named. "Playtest" rows need
the 15 outside players of M6 and are open.

| Feature | Test type | Status | Evidence |
| --- | --- | --- | --- |
| 5 crops | Automated | Pass | `test_gameplay.gd`: every plant's stages start within 1 game minute of its data time; growth pauses at 0 moisture; withers after exactly 24 dry hours; Tomato regrows 3 times then clears |
| 3 animals | Automated | Pass | `test_m2.gd`: each animal produces at its interval when fed and happy; production stops at 0 hunger and resumes on feeding; 20 days unfed leaves it Sick, not dead; housing capacity enforced |
| Items | Automated | Pass | `validate_data.py`: all 32 item definitions load, every referenced ID exists, every item is obtainable from a new save; asset lint: every item has its icon |
| 10 merge recipes | Automated | Pass in part | `test_gameplay.gd`: 100,000 rolls each for the Advanced and Rare carrot recipes are within 0.5 points of the displayed rate; pity reaches 100% on the calculated attempt; a failure keeps half the inputs and pays the right Stardust; the screen shows the number that is rolled. Not rolled 100,000 times each: the other two Advanced recipes (same code path and rate) |
| Merge experience | Playtest | Open | Needs testers |
| 3 NPCs and reputation | Automated | Pass | `test_m2.gd`, `test_m3.gd`: orders come from each NPC's tag pool or the fallback; reputation rises by the data amounts; reputation gates (Clover, Sun Bouquet) open at their levels |
| Delivery orders | Automated fuzz | Pass | `test_m2.gd`: over 10,000 generated orders across levels 1-10 are all producible at that level within 24 game hours; every board has an order at least half fillable from typical stock |
| Progression | Automated and playtest | Automated part passes; playtest open | `test_m2.gd`: a hand-played farm with no spirit reaches level 10 in about 170 game hours (2.8 real hours); `validate_data.py`: no unreachable node. Median time to level 5 with real players: open (in-engine scripted session: level 5 at 60 minutes) |
| Farm map | Automated and manual | Open in part | `run_playthrough.gd`: every interactable tile can be walked to. `run_bench.gd`: game logic costs about 0.5 ms of CPU per frame with 36 plots, 12 animals and 1 spirit on the build server. Not verified: 60 fps on a Steam Deck, and a visual check for Y-sort errors |
| Inventory and storage | Automated | Pass | `test_gameplay.gd`, `test_m3.gd`: stacks split and merge at 99; stations draw from backpack and chest; 10,000 random add/remove operations and 10,000 random chest transfers lose and duplicate nothing |
| Basic crafting | Automated | Pass | `test_m2.gd`, `test_m3.gd`, `test_m4.gd`: Feed, Sap, Revival Potion and Ancient Carrot Seeds consume and produce exactly their data |
| Research | Automated and playtest | Automated part passes; playtest open | `test_m3.gd`: a Golden Carrot yields 3 fragments, 6 the first time; the blueprint unlocks at 10 and consumes them; creation yields 4 seeds. 80% of testers harvesting an Ancient Carrot unaided: open |
| Tree Spirit | Automated | Pass | `test_m4.gd`: Root-sense is correct for every tile and husk position; the husk is always found within one Dig Kit by a careful player (worst case 6 digs); a Rootling keeps 16 tiles above 0 moisture for 3 game days; it rests at 0 stamina and returns; unpaid upkeep halves its speed; no stall in the 2-hour soak at 20x |
| Automation is optional | Automated | Pass | `test_m2.gd`: level 10 with no spirit; `test_m3.gd`: the story up to the Ancient Carrot with no spirit |
| Automation is rewarding | Playtest | Open | Needs testers |
| Core loop | Playtest | Open | Scripted playthrough completes it in about 6 real minutes of game time; real players: open |
| Economy | Automated and playtest | Open in part | `validate_data.py`: no buy-and-resell profit; simulator: no major purchase is more than 3 game days away. Phase 1 income in the simulator is 706 against a 300-600 target (finding F-06). Simulated against played income: open |
| Save and load | Automated | Pass | `test_m2.gd`, `test_m4.gd`, `run_playthrough.gd`: save, quit, load reproduces identical state including random streams; real saves from the M2 and M4 builds load in this build |
| Art consistency | Automated and manual | Open in part | Asset lint passes on all sprites (palette, size, alpha, naming, completeness). Human approval: the Director approved the placeholder style (D-008); all art is still code-drawn and awaits an artist (D-015) |
| Stability | Playtest | Open | No crash in the automated runs; 20 hours of combined playtest: open |

Deviation to note: section 20 says unpaid upkeep "halves its speed and nothing else"; section 9
says a Drowsy spirit also gains no skill XP. The build follows section 9 (decision P-44).
