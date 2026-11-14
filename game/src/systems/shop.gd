extends Node
## NPC shops and hand crafting (GDD sections 8 and 10; shop stock lives on the NPC definition).
## Autoload: Shop.


func entries(npc_id: String) -> Array:
	return GameData.def("npcs", npc_id).get("shop", [])


func is_open(entry: Dictionary) -> bool:
	return Unlocks.is_met(entry["unlock"])


func blocked_reason(entry: Dictionary, qty: int = 1) -> String:
	if not is_open(entry):
		return Unlocks.missing_text(entry["unlock"])
	if entry.has("animalId"):
		return Animals.buy_blocked(entry["animalId"], int(entry["price"]))
	if GameState.coins() < int(entry["price"]) * qty:
		return "Need %d coins" % (int(entry["price"]) * qty)
	if Inventory.room_for(entry["itemId"]) < qty:
		return "Backpack is full"
	return ""


func buy(npc_id: String, entry_id: String, qty: int = 1) -> bool:
	for entry: Dictionary in entries(npc_id):
		if entry["id"] != entry_id:
			continue
		if blocked_reason(entry, qty) != "":
			return false
		if entry.has("animalId"):
			return Animals.buy(entry["animalId"], int(entry["price"]))
		GameState.spend_coins(int(entry["price"]) * qty)
		Inventory.add(entry["itemId"], qty)
		return true
	return false


# ---- hand crafting (CraftRecipe)
func craft_known(craft_id: String) -> bool:
	var c: Dictionary = GameData.def("craft_recipes", craft_id)
	return Unlocks.is_met(c["unlock"]) and (c["station"] == null or GameState.building_level(c["station"]) >= 1)


## Items that can fill a tag input, cheapest first (so Sap is pressed from Wheat before Sunflowers).
func tag_candidates(input: Dictionary) -> Array:
	var out: Array = []
	for item_id: String in GameData.ids("items"):
		var def: Dictionary = GameData.item(item_id)
		if def["tags"].has(input["tag"]) and (not input.has("rarity") or def["rarity"] == input["rarity"]) and Inventory.count(item_id) > 0:
			out.append(item_id)
	out.sort_custom(func(a: String, b: String) -> bool: return GameData.item(a)["baseValue"] < GameData.item(b)["baseValue"])
	return out


func _tag_stock(input: Dictionary) -> int:
	var total := 0
	for item_id: String in tag_candidates(input):
		total += maxi(0, Inventory.count(item_id) - Quests.reserved(item_id))
	return total


func craft_affordable(craft_id: String) -> int:
	var c: Dictionary = GameData.def("craft_recipes", craft_id)
	var n := 1 << 30
	for input: Dictionary in c["inputs"]:
		if input.has("itemId"):
			n = mini(n, Inventory.count(input["itemId"]) / int(input["qty"]))
		else:
			n = mini(n, _tag_stock(input) / int(input["qty"]))
	if int(c["coins"]) > 0:
		n = mini(n, GameState.coins() / int(c["coins"]))
	return n


func craft(craft_id: String, times: int = 1) -> int:
	var c: Dictionary = GameData.def("craft_recipes", craft_id)
	if not craft_known(craft_id) or float(c["hours"]) > 0.0:
		return 0
	var made := 0
	for i: int in range(mini(times, craft_affordable(craft_id))):
		for input: Dictionary in c["inputs"]:
			if input.has("itemId"):
				Inventory.remove(input["itemId"], int(input["qty"]))
				continue
			var left := int(input["qty"])
			for item_id: String in tag_candidates(input):
				var take := mini(left, maxi(0, Inventory.count(item_id) - Quests.reserved(item_id)))
				Inventory.remove(item_id, take)
				left -= take
		GameState.spend_coins(int(c["coins"]))
		Inventory.add(c["output"]["itemId"], int(c["output"]["qty"]))
		GameState.count_produced(c["output"]["itemId"], int(c["output"]["qty"]))
		made += int(c["output"]["qty"])
	return made
