extends Node
## Merge system (GDD section 6; spec section 4). Autoload: Merge.
## Every number comes from merge_config.json. The percentage shown is the percentage rolled.

signal merged(recipe_id: String, result: Dictionary)

const STATION := "bld_merge_table"


func config() -> Dictionary:
	return GameData.merge_config


func recipe(recipe_id: String) -> Dictionary:
	return GameData.def("merge_recipes", recipe_id)


func known_recipes() -> Array:
	var out: Array = []
	for recipe_id: String in GameData.ids("merge_recipes"):
		if Unlocks.recipe_known(recipe_id):
			out.append(recipe_id)
	return out


func output_value(recipe_id: String) -> float:
	return float(GameData.item(recipe(recipe_id)["output"]["itemId"])["baseValue"])


func fee(recipe_id: String) -> int:
	return roundi(float(config()["feeRatio"]) * output_value(recipe_id))


func mastery_points(recipe_id: String) -> int:
	var successes := int(GameState.player["mergeMastery"].get(recipe_id, 0))
	return mini(int(config()["masteryMax"]), successes / int(config()["masteryPerSuccesses"]))


func pity(recipe_id: String) -> int:
	return int(GameState.player["mergePity"].get(recipe_id, 0))


## Every term of the probability formula, in display order, and the total that is rolled against.
## P = min(100, min(cap, base + charm + blessing + table + mastery + quality) + pityStep * f)
func chance(recipe_id: String, charm_item_id: String = "", blessing_item_id: String = "") -> Dictionary:
	var cfg := config()
	var r := recipe(recipe_id)
	var terms: Array = [{"label": "Base", "value": float(cfg["baseRate"][r["rarity"]])}]
	if charm_item_id != "":
		var lucky: Dictionary = GameData.item(charm_item_id)["lucky"]
		terms.append({"label": GameData.item(charm_item_id)["name"], "value": float(lucky["bonus"])})
	if blessing_item_id != "":
		var lucky: Dictionary = GameData.item(blessing_item_id)["lucky"]
		terms.append({"label": GameData.item(blessing_item_id)["name"], "value": float(lucky["bonus"])})
	var table_level := maxi(1, GameState.building_level(STATION))
	var table_bonus := float(cfg["tableBonus"][table_level - 1])
	if table_bonus > 0.0:
		terms.append({"label": "Table", "value": table_bonus})
	if mastery_points(recipe_id) > 0:
		terms.append({"label": "Mastery", "value": float(mastery_points(recipe_id))})
	var all_fine := true
	for input: Dictionary in r["inputs"]:
		if Inventory.lowest_quality_used(input["itemId"], int(input["qty"])) < int(cfg["qualityBonus"]["minQuality"]):
			all_fine = false
	if all_fine:
		terms.append({"label": "Quality", "value": float(cfg["qualityBonus"]["bonus"])})
	var sum := 0.0
	for term: Dictionary in terms:
		sum += term["value"]
	var cap := float(cfg["modifierCap"].get(r["rarity"], cfg["modifierCap"]["default"]))
	var capped := minf(cap, sum)
	var pity_bonus := float(cfg["pityStep"]) * pity(recipe_id)      # pity is not limited by the cap
	if pity_bonus > 0.0:
		terms.append({"label": "Pity", "value": pity_bonus})
	return {"terms": terms, "cap": cap, "capped": sum > cap, "total": minf(100.0, capped + pity_bonus)}


func crit_chance(recipe_id: String) -> float:
	return float(config()["critBase"]) + float(config()["critPerMastery"]) * mastery_points(recipe_id)


## What a failure would keep of each input: max(1, floor(qty * failRefundRatio)).
func refund_qty(qty: int) -> int:
	return maxi(1, floori(qty * float(config()["failRefundRatio"])))


func stardust_on_fail(recipe_id: String) -> int:
	return int(config()["stardustPerFailByTier"].get(recipe(recipe_id)["rarity"], 0))


## How many times the recipe can be made from current stock and coins.
## Recipes not yet known, with where to look for them (section 6: silhouettes with their source).
func unknown_recipes() -> Array:
	var out: Array = []
	for recipe_id: String in GameData.ids("merge_recipes"):
		if not Unlocks.recipe_known(recipe_id):
			out.append(recipe_id)
	return out


func source_hint(recipe_id: String) -> String:
	var u: Dictionary = recipe(recipe_id)["unlock"]
	if u.has("firstResearchOf") and not Unlocks.is_met({"firstResearchOf": u["firstResearchOf"]}):
		return "Research a " + GameData.item(u["firstResearchOf"])["name"]
	if u.has("quest") and not Unlocks.is_met({"quest": u["quest"]}):
		return GameData.def("npcs", GameData.def("quests", u["quest"])["giver"])["name"].get_slice(" ", 0) + "'s story"
	return Unlocks.missing_text(u)


func affordable(recipe_id: String) -> int:
	var r := recipe(recipe_id)
	var n := 1 << 30
	for input: Dictionary in r["inputs"]:
		n = mini(n, Inventory.count(input["itemId"]) / int(input["qty"]))
	if fee(recipe_id) > 0:
		n = mini(n, GameState.coins() / fee(recipe_id))
	return n


## "" when an attempt can be made, otherwise a short reason for the screen.
func blocked_reason(recipe_id: String) -> String:
	var r := recipe(recipe_id)
	if not Unlocks.recipe_known(recipe_id):
		return "Recipe not known"
	if GameState.building_level(STATION) < int(r["minStationLevel"]):
		return "Needs a better Merge Table"
	for input: Dictionary in r["inputs"]:
		var missing := int(input["qty"]) - Inventory.count(input["itemId"])
		if missing > 0:
			return "Need %d more %s" % [missing, GameData.item(input["itemId"])["name"]]
	if GameState.coins() < fee(recipe_id):
		return "Need %d coins for the fee" % fee(recipe_id)
	if Inventory.room_for(r["output"]["itemId"]) < int(r["output"]["qty"]) * 2:
		return "Backpack is full"
	return ""


## True when section 6 asks for a confirmation dialog before the attempt.
func needs_confirmation(recipe_id: String, charm_item_id: String = "") -> bool:
	if chance(recipe_id, charm_item_id)["total"] >= 100.0:
		return false
	if charm_item_id != "":
		return true
	var rank: Dictionary = GameData.config["economy"]["rarityRank"]
	for input: Dictionary in recipe(recipe_id)["inputs"]:
		if int(rank[GameData.item(input["itemId"])["rarity"]]) >= int(rank["rare"]):
			return true
		if Inventory.lowest_quality_used(input["itemId"], int(input["qty"])) >= 4:
			return true
	return false


## One merge attempt. Returns {} when blocked, else
## {outcome: "success" | "critical" | "failure", chance, itemId, qty, kept: {itemId: qty}, stardust, fee}.
func attempt(recipe_id: String, charm_item_id: String = "") -> Dictionary:
	if blocked_reason(recipe_id) != "":
		return {}
	var r := recipe(recipe_id)
	var p: float = chance(recipe_id, charm_item_id)["total"]
	var paid := fee(recipe_id)
	GameState.spend_coins(paid)
	GameState.add_xp(paid)                       # section 10: XP = the fee of each attempt
	if charm_item_id != "":
		Inventory.remove(charm_item_id, 1)       # a lucky item is consumed on every attempt
	var stream := GameState.stream("merge")
	var result := {"chance": p, "itemId": r["output"]["itemId"], "qty": 0, "kept": {}, "stardust": 0, "fee": paid}
	if stream.roll_percent() < p:
		for input: Dictionary in r["inputs"]:
			Inventory.remove(input["itemId"], int(input["qty"]))
		var critical := stream.roll_percent() < crit_chance(recipe_id)
		result["outcome"] = "critical" if critical else "success"
		result["qty"] = int(r["output"]["qty"]) * (2 if critical else 1)
		Inventory.add(result["itemId"], result["qty"])
		GameState.count_produced(result["itemId"], result["qty"])
		GameState.player["mergePity"][recipe_id] = 0
		GameState.player["mergeMastery"][recipe_id] = int(GameState.player["mergeMastery"].get(recipe_id, 0)) + 1
	else:
		result["outcome"] = "failure"
		for input: Dictionary in r["inputs"]:
			var keep := refund_qty(int(input["qty"]))
			Inventory.remove(input["itemId"], int(input["qty"]) - keep)
			result["kept"][input["itemId"]] = keep
		result["stardust"] = stardust_on_fail(recipe_id)
		if result["stardust"] > 0:
			Inventory.add("mat_stardust", result["stardust"])
		GameState.player["mergePity"][recipe_id] = pity(recipe_id) + 1
	GameState.changed.emit()
	merged.emit(recipe_id, result)
	return result
