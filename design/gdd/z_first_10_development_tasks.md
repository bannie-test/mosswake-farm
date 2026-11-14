## First 10 development tasks

In priority order. Tasks 1–6 are milestone M0 and must finish before gameplay code; tasks 7–9 are the first playable.

- **Sign off the assumptions and contradictions table.** Owner: Game Director. Output: an approved decision log. Everything else depends on it.

- **Set up the repository and single source of truth.** Folders from section 18, `id_registry.json`, CI skeleton. Owner: Technical Architect.

- **Write JSON Schemas for the 20 definition and state types and the validator.** Includes reference-integrity and unlock-reachability tests. Owner: Technical Architect.

- **Enter all MVP data and build the economy simulator.** 32 items, 5 plants, 3 animals, 10 recipes, 3 NPCs, 6 quests; a script that plays a scripted farm over the data and reports income per game day and any exploit. Owners: Systems Designer, Economy Balancer.

- **Build the Art Bible style-sheet scene.** One 640×360 screen: farmhouse corner, six plots with all carrot stages, player, chicken, Rootling. Lock the palette file. Owners: human art lead, 2D Asset Agent.

- **Create the Godot project skeleton.** Project settings, tilemap layers, Y-sort, pixel-snapped camera, the `advance(dt)` simulation core, the save envelope. Owner: Gameplay Programmer.

- **Implement player movement, plots and crop growth.** Carrot and Wheat: till, plant, water, grow, harvest, wither. Unit tests for growth and moisture.

- **Implement inventory and the Merge Table.** Stacks, backpack UI, merge roll from `mergeConfig`, the probability breakdown, pity counter, two recipes.

- **Implement the order board and rewards.** Mara with a fixed order list, delivery, coins, XP and level-up. This completes Plant → Grow → Harvest → Merge → Order → Reward; run five internal playtests.

- **Run the naming and identity pass.** Final game title, final spirit class names and silhouettes, and a check that no name, character or design resembles an existing game's. Owner: Game Director with the art lead. It runs alongside tasks 7–9 and must finish before spirit assets are made in M4.
