## 13. Inventory and Item Architecture

Every thing the player can hold is one `ItemDefinition` with one ID. Farming, merging, research and quests all point at that ID and never redefine the item.

### ID rules

- Format: `<prefix>_<species>[_<variant>]`, lowercase, ASCII, underscores. Example: `merged_carrot_crystal`.

- An ID is permanent once it ships. Retired IDs are listed in `retired_ids.json` with a replacement and are never reused.

- IDs are issued only through `data/id_registry.json` (section 18).

- Definitions of other kinds have their own prefixes: `plant_`, `animal_`, `trait_`, `merge_`, `bp_`, `breed_`, `quest_`, `npc_`, `spirit_`, `job_`, `bld_`.

### Item categories

| Category | Prefix | Stack | Stored in | Has quality | Example | Used by |
| --- | --- | --- | --- | --- | --- | --- |
| Seed | seed_ | 99 | Inventory | No | seed_carrot | Farming, shop, creation |
| Crop | crop_ | 99 | Inventory | Yes | crop_carrot | Orders, merge, Sap, Feed |
| Flower | crop_ with tag flower | 99 | Inventory | Yes | crop_sunflower | Orders, merge, hives, potions |
| Animal product | prod_ | 99 | Inventory | Yes | prod_egg | Orders, merge, research |
| Merged product | merged_ | 99 | Inventory | Yes | merged_carrot_golden | Orders, research, creation, charms |
| Processed food | food_ | 99 | Inventory | Yes | food_bread | Orders, animal treats |
| Gene Fragment | gene_ | 99 cap | Wallet | No | gene_carrot | Research, breeding |
| Lucky item | lucky_ | 20 cap | Wallet | No | lucky_clover | Merge |
| Crafting material | mat_ | 99 | Inventory (Feed in Silo) | No | mat_stardust, mat_feed | Fertilizer, creation, upkeep |
| Spirit material | spirit_ | 99; husks 1 | Inventory | No | spirit_essence, spirit_husk_dormant | Restoration, charms |
| Animal embryo | embryo_ | 1 | Inventory | No | embryo_sunhen | Genetic Laboratory |
| Quest item | quest_ | 1 | Quest pouch | No | quest_ilse_notes | Story quests |
| Tool and special | tool_, special_ | 1 or 99 | Inventory | No | tool_dig_kit | Excavation, events |

Animals and spirits are not items. They are instances (`AnimalInstance`, `SpiritInstance`) that live in the world. Embryos and husks are the item forms that become instances.

### Rarity and tier

- `rarity` is one of common, uncommon, rare, epic, legendary, mythical. It drives the frame colour, quality floor and research yield.

- `tier` is 1 to 5 within a merge chain. It drives order eligibility and research duration.

### Storage

| Container | Slots | Notes |
| --- | --- | --- |
| Backpack | 24, up to 48 | +6 at Codex 10%, +2 per Farm Level |
| Storage Chest | 36 each | Placed anywhere; spirits use the chest in or beside their zone |
| Silo | 200 Feed | Feeders draw from it |
| Wallet | No slots | Coins, genes, Prism, Stardust, lucky items, Spirit Essence |
| Quest pouch | No slots | Cannot be sold, merged or researched |

All crafting stations read from the backpack and every chest on the farm, so the player never carries ingredients by hand between buildings.

### Stacking and metadata

- The stack key is `itemId + quality`. Three Q1 Carrots and two Q3 Carrots are two stacks.

- Recipes consume the lowest quality first unless the player picks otherwise.

- Items with per-instance data do not stack: embryos carry a genome, husks carry `isElder` and `condition`.

- Tags (`vegetable`, `root`, `flower`, `dairy`, `magical`…) are the only way systems group items. NPC likes, order pools and "any Common crop" recipe inputs all use tags.

### No duplicated definitions

`Crop``Definition` holds `seedItemId` and `productItemId`; `AnimalDefinition` holds `productItemId`; recipes hold `itemId` references. A value, name or icon exists in exactly one place, the `ItemDefinition`. The build fails if any referenced ID is missing from the item table.
