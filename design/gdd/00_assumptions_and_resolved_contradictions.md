## Assumptions and resolved contradictions

The brief is sufficient to proceed without clarification questions. "Mosswake Farm" is a working title. These decisions hold for every section below; change one here and the dependent tables must be re-derived.

### Assumptions

| Topic | Decision | Reason |
| --- | --- | --- |
| Platform | PC (Windows, Linux, Steam Deck) first; mobile port after 1.0 | The reference art needs screen space; premium PC is the proven market for this style |
| Engine | Godot 4 (2D, GDScript), 640×360 internal resolution, integer scaling | Stated in the art brief |
| Business model | Premium, one-time purchase, no in-app purchases | Merge randomness must never be sold; it keeps the probability design honest |
| Team | 2–3 people plus AI agents; MVP in about 22 weeks | "Small indie team" in the brief |
| Time model | 1 game hour = 1 real minute; 1 game day = 24 real minutes; 1 season = 7 game days | Short crops finish inside one sitting; no real-time waiting overnight |
| Offline progression | None on PC: the simulation pauses when the game closes. All timers are stored in game time, so a mobile port can call the same advance(dt) with a capped dt | Avoids punishing absence and removes a whole class of save exploits |
| Fail states | Nothing dies and nothing is lost permanently except merge ingredients | Cozy audience; see pillar 4 |
| Language | English design terms; "Ma Cây" is kept as the in-world name of Tree Spirits | The brief uses both |

### Contradictions found in the brief, and how each is resolved

| # | Contradiction or gap | Resolution |
| --- | --- | --- |
| 1 | Ancient Carrot is both the top of the merge chain and a seed unlocked by research | Ancient-tier species come only from research. The carrot merge chain stops at Crystal Carrot. This gives the gene system an exclusive reward. Epic and higher merge tiers are used by cross-species fusion recipes instead |
| 2 | Legendary 20% and Mythical 10% merge rates conflict with "not excessively punishing" | A pity counter adds 5 percentage points per failure, failures refund half the ingredients, and residue from failures feeds research (section 6) |
| 3 | "Merge" can mean a merge board or recipe crafting | Recipe crafting at a Merge Table. No board, no drag-to-merge grid: it would be a second game inside the farm |
| 4 | Day/night and seasons conflict with "avoid excessive waiting" | Seasons give bonuses and never block a crop. Night is playable and has its own content (night-blooming plants) |
| 5 | Automation conflicts with "without removing strategic decisions" | Spirits only do repeatable physical tasks inside a zone the player draws. Planting choice, merging, research, breeding and order selection stay manual |
| 6 | Pigs and "one-time animal products" imply slaughter, which clashes with a cozy tone | Pigs forage truffles. One-time products are life events: First Molt Feather, First Fleece, a Keepsake when an animal retires to the forest sanctuary |
| 7 | MVP asks for 15–20 items but also 5 crops, 3 animals and 10 merge recipes | Counted as 18 tradeable goods (5 crops, 3 animal products, 10 merged products). Seeds, materials and lucky items add 14 supporting definitions |
| 8 | The two reference images use different projections: image 1 is straight-on 3/4 top-down, image 2 is laid out on diagonals | Image 1 is the primary reference for rendering, palette and projection. Image 2 is a reference for crop density and plot readability only. The game uses an orthogonal square grid |
| 9 | Spirit names in the brief are examples; some overlap ordinary animals | Names are kept as given for now (Rootling, Leafling, Bloomling, Chickling, Moo Spirit, Merchant Spirit). A naming pass is task 10 in the final list |
