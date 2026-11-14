## 14. Technical Data Schema

Static definitions are read-only JSON shipped with the game. Runtime state is the save file, and it refers to definitions only by ID.

### Static and runtime

|  | Static definitions | Runtime state |
| --- | --- | --- |
| Lives in | res://data/*.json, one file per definition type | user://saves/slot_N.json |
| Written by | Designers and agents, through pull requests | The game |
| Loaded | At boot into registries keyed by ID; validated against JSON Schema | On load; migrated to the current saveVersion |
| Contains | Rules, numbers, references to other IDs | IDs, counts, timestamps in game minutes, per-instance rolls |
| Changing it | Never breaks a save, as long as IDs persist | Needs a migration step |

Adding a crop, animal, recipe or spirit is a data change: new rows in JSON plus sprites. Code changes only when a new kind of behaviour is needed, for example a new spirit job type.

**Note on Section 4 IDs:** the crop table lists product item IDs (`crop_carrot`). The plant itself is `plant_carrot`.

### Static definitions

**ItemDefinition**

```json
{
  "id": "merged_carrot_crystal",
  "name": "Crystal Carrot",
  "category": "merged",
  "tags": ["vegetable", "root", "carrot", "merged"],
  "rarity": "rare",
  "tier": 4,
  "species": "carrot",
  "baseValue": 700,
  "stackSize": 99,
  "storage": "inventory",
  "hasQuality": true,
  "sellable": true,
  "research": {"geneId": "gene_carrot", "fragments": 8, "stardust": 3, "hours": 6, "coins": 120},
  "lucky": null,
  "icon": "items/merged_carrot_crystal.png"
}
```

**CropDefinition** (`plant_*`)

```json
{
  "id": "plant_carrot",
  "species": "carrot",
  "seedItemId": "seed_carrot",
  "productItemId": "crop_carrot",
  "rarity": "common",
  "growthHours": 6,
  "stages": [
    {"name": "seed", "until": 0.10},
    {"name": "sprout", "until": 0.35},
    {"name": "young", "until": 0.55},
    {"name": "growing", "until": 0.75},
    {"name": "mature", "until": 1.0}
  ],
  "waterIntervalHours": 8,
  "fertilizerRequired": false,
  "yield": {"min": 2, "max": 2},
  "regrow": null,
  "witherDryHours": 24,
  "witherUnharvestedHours": 48,
  "nightOnly": false,
  "needsShade": false,
  "mutation": {"chance": 0.005, "resultItemId": "merged_carrot_premium", "sportGeneId": "gene_carrot"},
  "innateTraits": [],
  "favouredSeason": "spring",
  "xpPerUnit": 1,
  "unlock": {"playerLevel": 1},
  "sprite": "crops/carrot.png"
}
```

A regrowing crop sets `"regrow": {"hours": 5, "maxHarvests": 4}`.

**AnimalDefinition**

```json
{
  "id": "animal_chicken",
  "species": "chicken",
  "housing": "bld_coop",
  "buyCost": 150,
  "stageHours": {"baby": 24, "juvenile": 24, "elderAfterDays": 40},
  "feed": {"itemId": "mat_feed", "qtyPer8h": 1},
  "hungerDrainPerHour": 12.5,
  "happinessDecayPerHour": 2,
  "renewable": {"itemId": "prod_egg", "intervalHours": 6, "qty": 1, "needsTool": null},
  "oneTime": [
    {"event": "became_adult", "itemId": "prod_first_molt_feather"},
    {"event": "retired", "itemId": "prod_keepsake_chicken"}
  ],
  "geneId": "gene_chicken",
  "breedingRuleId": "breed_chicken",
  "defaultRarity": "common",
  "unlock": {"playerLevel": 1}
}
```

**GeneDefinition** and **TraitDefinition**

```json
{"id": "gene_carrot", "species": "carrot", "kind": "crop", "walletCap": 99, "blueprintIds": ["bp_carrot_ancient"]}
```

```json
{"id": "trait_prolific", "appliesTo": ["chicken", "cow", "sheep", "pig"], "maxLevel": 3,
 "effects": [{"stat": "productionInterval", "op": "mul", "perLevel": -0.08}], "codexStamp": true}
```

**MergeRecipe**

```json
{
  "id": "merge_carrot_crystal",
  "rarity": "rare",
  "inputs": [{"itemId": "merged_carrot_golden", "qty": 3}],
  "output": {"itemId": "merged_carrot_crystal", "qty": 1},
  "station": "bld_merge_table",
  "minStationLevel": 1,
  "allowLucky": true,
  "unlock": {"firstResearchOf": "merged_carrot_golden"}
}
```

Rate, fee, refund and Stardust come from `mergeConfig` by `rarity`; a recipe may override any of them with an `overrides` block.

**ResearchRecipe** (a blueprint and its creation recipe)

```json
{
  "id": "bp_carrot_ancient",
  "kind": "seed",
  "fragmentCost": [{"geneId": "gene_carrot", "qty": 10}],
  "prismMaxRatio": 0.3,
  "creation": {
    "station": "bld_research_station",
    "inputs": [{"itemId": "merged_carrot_crystal", "qty": 1}, {"itemId": "mat_stardust", "qty": 5}],
    "coins": 200,
    "hours": 2,
    "output": {"itemId": "seed_carrot_ancient", "qty": 4}
  },
  "unlock": {"researchLevel": 1}
}
```

**BreedingRule**

```json
{
  "id": "breed_chicken",
  "species": "chicken",
  "conditions": {"minHappiness": 70, "minFertility": 60, "minHealth": 30, "cooldownHours": 48, "forbidParentChild": true},
  "gestationHours": 12,
  "slotInheritance": {"parentA": 0.45, "parentB": 0.45, "mutation": 0.10},
  "sharedTraitLevelUpChance": 0.25,
  "tonic": {"itemId": "mat_gene_tonic", "mutation": 0.30, "lockSlots": 1},
  "rarity": {
    "same": {"same": 0.80, "up": 0.15, "down": 0.05},
    "different": {"lower": 0.50, "higher": 0.45, "up": 0.05},
    "max": "epic"
  },
  "traitPool": ["trait_prolific", "trait_hardy", "trait_gentle", "trait_golden_comb", "trait_sun_feather"],
  "specialOffspring": [{
    "resultAnimalId": "animal_sunhen",
    "requires": [{"traitId": "trait_golden_comb", "minLevel": 2}, {"traitId": "trait_sun_feather", "minLevel": 2}],
    "chance": 0.15
  }]
}
```

**QuestDefinition**

```json
{
  "id": "quest_strange_carrot",
  "giver": "npc_ilse",
  "category": "story",
  "requires": {"playerLevel": 4, "npcMet": ["npc_ilse"]},
  "steps": [
    {"id": "s1", "type": "deliver", "itemId": "merged_carrot_golden", "qty": 1, "text": "quest.strange_carrot.s1"}
  ],
  "rewards": {"reputation": {"npc_ilse": 60}, "xp": 200, "unlocks": ["bld_research_station"], "items": []},
  "next": "quest_what_carrots_remember"
}
```

Step types: `deliver`, `produce`, `build`, `research`, `reach` (a stat threshold), `interact`.

**NPCDefinition**

```json
{
  "id": "npc_ilse",
  "name": "Ilse Quill",
  "role": "scholar",
  "appears": {"playerLevel": 4},
  "likes": ["magical", "flower", "merged"],
  "orderRules": {
    "tags": ["merged", "flower", "magical"],
    "sizeFactor": 0.9,
    "maxLines": 2,
    "deliverySlots": 2,
    "specialFromReputation": 3
  },
  "reputationThresholds": [0, 40, 120, 250, 450, 700, 1000, 1400],
  "reputationRewards": [
    {"level": 2, "unlocks": ["seed_moonbell"]},
    {"level": 3, "unlocks": ["recipe_gene_mulch"]},
    {"level": 4, "unlocks": ["bld_genetic_lab"]}
  ],
  "specialBonusTable": "bonus_default",
  "dialogue": "dialogue/ilse.json",
  "portrait": "npc/ilse_portrait.png"
}
```

**OrderDefinition** (generated at run time and stored in the save; its shape is fixed here)

```json
{
  "orderId": "ord_000142",
  "npcId": "npc_mara",
  "category": "delivery",
  "lines": [{"itemId": "crop_carrot", "qty": 12, "minQuality": 1}, {"itemId": "prod_egg", "qty": 4, "minQuality": 1}],
  "rewards": {"coins": 198, "xp": 61, "reputation": 8, "bonusItems": []},
  "createdAt": 31680,
  "expiresAt": null,
  "pinnedForSpirit": false
}
```

**TreeSpiritDefinition**

```json
{
  "id": "spirit_rootling",
  "name": "Rootling",
  "jobId": "job_water_plots",
  "charmRecipe": {"inputs": [{"itemId": "merged_carrot_premium", "qty": 5}, {"itemId": "spirit_essence", "qty": 1}], "coins": 200},
  "base": {"actionSeconds": 6, "moveTilesPerSecond": 2.5, "carry": 10},
  "levels": [
    {"level": 1, "xp": 0, "zoneTiles": 16, "speed": 1.0, "stamina": 40, "restHours": 3},
    {"level": 2, "xp": 100, "zoneTiles": 24, "speed": 1.2, "stamina": 50, "restHours": 3},
    {"level": 3, "xp": 300, "zoneTiles": 36, "speed": 1.5, "stamina": 60, "restHours": 2.5, "perk": "perk_apply_fertilizer"},
    {"level": 4, "xp": 700, "zoneTiles": 48, "speed": 1.7, "stamina": 80, "restHours": 2.5},
    {"level": 5, "xp": 1500, "zoneTiles": 64, "speed": 2.0, "stamina": 100, "restHours": 2, "perk": "perk_well_tended_zone"}
  ],
  "upkeep": {"itemId": "mat_sap", "qtyPerDay": 1, "unpaidSpeed": 0.5},
  "unlock": {"quest": "quest_first_vocation"},
  "sprite": "spirits/rootling.png"
}
```

**SpiritJobDefinition**

```json
{
  "id": "job_water_plots",
  "targetType": "plot",
  "targetFilter": {"moistureBelow": 30, "hasCrop": true},
  "action": "water",
  "consumes": {"resource": "water", "perAction": 1, "refillAt": "well"},
  "outputTo": null,
  "priority": "lowestMoistureFirst",
  "needsChest": false
}
```

Job behaviour is one generic state machine: find target, walk, act, deposit, rest. A job definition only supplies the filter, the action and the endpoints.

**BuildingDefinition**

```json
{
  "id": "bld_merge_table",
  "name": "Merge Table",
  "footprint": {"w": 2, "h": 2},
  "placement": "pad",
  "levels": [
    {"level": 1, "coins": 250, "materials": [], "effects": {"mergeBonus": 0}},
    {"level": 2, "coins": 2000, "materials": [], "effects": {"mergeBonus": 3}},
    {"level": 3, "coins": 8000, "materials": [{"itemId": "spirit_essence", "qty": 5}], "effects": {"mergeBonus": 6}}
  ],
  "farmPoints": 1,
  "unlock": {"playerLevel": 3},
  "scene": "buildings/merge_table.tscn"
}
```

### Runtime state

**Save envelope and PlayerProgression**

```json
{
  "saveVersion": 3,
  "dataVersion": "1.0.0",
  "gameMinute": 31925,
  "rng": {"merge": 918273645, "harvest": 55512, "orders": 7781, "breeding": 40961, "excavation": 1203},
  "player": {
    "level": 6,
    "xp": 412,
    "coins": 1840,
    "farmPoints": 7,
    "reputation": {"npc_mara": 164, "npc_tobin": 96, "npc_ilse": 60},
    "unlocked": ["plant_carrot", "plant_wheat", "plant_tomato", "plant_sunflower", "merge_carrot_premium", "merge_carrot_golden"],
    "stats": {"ordersCompleted": 23, "timesProduced": {"merged_carrot_golden": 2}},
    "mergePity": {"merge_carrot_crystal": 1},
    "mergeMastery": {"merge_carrot_premium": 14}
  }
}
```

**FarmPlotState**

```json
{
  "plotId": "field_02/3",
  "plantId": "plant_tomato",
  "plantedAt": 31020,
  "growthMinutes": 512,
  "moisture": 46.5,
  "dryMinutes": 0,
  "everDry": false,
  "fertilizerItemId": "mat_compost",
  "harvestsTaken": 1,
  "matureSince": null,
  "state": "regrowing"
}
```

**AnimalInstance**

```json
{
  "instanceId": "an_0007",
  "animalId": "animal_chicken",
  "name": "Pip",
  "rarity": "uncommon",
  "traits": [{"traitId": "trait_golden_comb", "level": 1}],
  "parents": ["an_0002", "an_0003"],
  "bornAt": 21600,
  "stage": "adult",
  "hunger": 71,
  "happiness": 88,
  "health": 100,
  "fertility": 62,
  "productionProgress": 0.42,
  "breedReadyAt": 30240,
  "oneTimeGiven": ["became_adult"],
  "housingId": "bld_coop#1"
}
```

**InventoryState**

```json
{
  "backpack": {"slots": 24, "stacks": [
    {"itemId": "crop_carrot", "quality": 1, "qty": 14},
    {"itemId": "crop_carrot", "quality": 3, "qty": 2},
    {"itemId": "embryo_sunhen", "quality": 1, "qty": 1, "instanceData": {"rarity": "epic", "traits": [{"traitId": "trait_sun_feather", "level": 2}]}}
  ]},
  "chests": {"chest_01": {"slots": 36, "stacks": []}},
  "silo": {"mat_feed": 38},
  "wallet": {"gene_carrot": 6, "prism_fragment": 2, "mat_stardust": 4, "lucky_clover": 3, "spirit_essence": 0},
  "questPouch": []
}
```

**ResearchProgress**

```json
{
  "level": 2,
  "xp": 17,
  "queue": [{"itemId": "merged_carrot_golden", "quality": 1, "startedAt": 31800, "readyAt": 31980}],
  "researchedOnce": ["merged_carrot_premium", "merged_tomato_premium"],
  "blueprints": ["bp_carrot_ancient"],
  "codex": {"carrot": ["discovered", "researched", "blueprint"], "chicken": ["discovered"]},
  "traitsSeen": ["trait_golden_comb"]
}
```

**QuestProgress**

```json
{
  "active": [{"questId": "quest_what_carrots_remember", "stepId": "s1", "counters": {"research": 2}}],
  "completed": ["quest_first_harvest", "quest_table_for_two", "quest_strange_carrot"],
  "orders": ["ord_000142", "ord_000143"],
  "slotRefillAt": {"npc_mara/1": 31985}
}
```

**SpiritInstance**

```json
{
  "instanceId": "sp_0001",
  "spiritId": "spirit_rootling",
  "name": "Mossy",
  "isElder": false,
  "skillLevel": 2,
  "skillXp": 141,
  "skillCap": 5,
  "stamina": 23,
  "state": "working",
  "zone": {"map": "farm", "x": 34, "y": 20, "w": 6, "h": 4},
  "chestId": null,
  "carrying": {"water": 4},
  "upkeepPaidDay": 22,
  "grafts": {"tool": 0, "heartwood": false, "rootbed": true}
}
```

### Save, load and versioning

- **Format:** one JSON file per slot, gzip-compressed. Written to a temporary file and renamed, so a crash cannot corrupt a save.

- **When:** autosave at each dawn and on quit; manual save by sleeping. Three rotating backups per slot.

- **Versioning:** `saveVersion` is an integer. Migrations are an ordered list of functions, each taking version N to N+1, run in sequence on load. `dataVersion` records which definitions the save last ran with.

- **Missing IDs:** an ID in a save but not in the data is looked up in `retired_ids.json` and replaced, or refunded as coins at its last value. The load never fails on an unknown ID.

- **Randomness:** each system has its own seeded stream stored in the save. Reloading does not change a merge result, which removes save-scumming without any extra rule.

- **Time:** every timer is an absolute `gameMinute` or an accumulated counter. No wall-clock time is stored.

### Simulation and offline progression

Every system implements `advance(deltaGameMinutes)`. The frame loop calls it with small deltas. Sleeping calls it with a large one, in steps of 10 game minutes so that spirits, moisture and animals interleave correctly.

On PC the game does not advance while closed. For a mobile port the same function is called on resume with the elapsed time, under three rules: a cap of 8 real hours, no withering while away, and spirits at 50% speed. No other code changes.
