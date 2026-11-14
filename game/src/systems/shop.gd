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


func craft_affordable(craft_id: String) -> int:
	var c: Dictionary = GameData.def("craft_recipes", craft_id)
	var n := 1 << 30
	for input: Dictionary in c["inputs"]:
		if not input.has("itemId"):
			return 0                      # tag inputs (Sap) are crafted from M4
		n = mini(n, Inventory.count(input["itemId"]) / int(input["qty"]))
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
			Inventory.remove(input["itemId"], int(input["qty"]))
		GameState.spend_coins(int(c["coins"]))
		Inventory.add(c["output"]["itemId"], int(c["output"]["qty"]))
		made += int(c["output"]["qty"])
	return made
