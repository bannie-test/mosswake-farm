extends Node
## Inventory model (GDD section 13). Autoload: Inventory. Its state has the shape of
## InventoryState: backpack, chests, silo, wallet, quest pouch. The stack key is item ID + quality.

signal changed

var state: Dictionary = {}


func _ready() -> void:
	SaveGame.register_section("inventory", self)
	new_game()


func new_game() -> void:
	var cfg: Dictionary = GameData.config.get("newGame", {})
	state = {
		"backpack": {"slots": int(cfg.get("backpackSlots", 0)), "stacks": []},
		"chests": {},
		"silo": {},
		"wallet": {},
		"questPouch": [],
	}
	for entry: Dictionary in cfg.get("items", []):
		add(entry["itemId"], int(entry["qty"]))
	changed.emit()


func _containers() -> Array:
	var out: Array = [state["backpack"]]
	for chest_id: String in state["chests"]:
		out.append(state["chests"][chest_id])
	return out


## How many units would fit in the backpack.
func room_for(item_id: String, quality: int = 1) -> int:
	var def: Dictionary = GameData.item(item_id)
	if def["storage"] != "inventory":
		return 1 << 30
	var limit := int(def["stackSize"])
	var pack: Dictionary = state["backpack"]
	var room: int = (int(pack["slots"]) - int(pack["stacks"].size())) * limit
	for stack: Dictionary in pack["stacks"]:
		if stack["itemId"] == item_id and stack["quality"] == quality:
			room += limit - int(stack["qty"])
	return room


## Add units; returns the quantity that did not fit (0 when everything was stored).
func add(item_id: String, qty: int, quality: int = 1) -> int:
	if qty <= 0:
		return 0
	var def: Dictionary = GameData.item(item_id)
	match def["storage"]:
		"wallet", "silo":
			var pool: Dictionary = state[def["storage"]]
			pool[item_id] = int(pool.get(item_id, 0)) + qty
			changed.emit()
			return 0
		"quest_pouch":
			state["questPouch"].append({"itemId": item_id, "quality": quality, "qty": qty})
			changed.emit()
			return 0
	var limit := int(def["stackSize"])
	var pack: Dictionary = state["backpack"]
	var left := qty
	for stack: Dictionary in pack["stacks"]:
		if left > 0 and stack["itemId"] == item_id and stack["quality"] == quality and stack["qty"] < limit:
			var moved := mini(left, limit - int(stack["qty"]))
			stack["qty"] += moved
			left -= moved
	while left > 0 and pack["stacks"].size() < int(pack["slots"]):
		var moved := mini(left, limit)
		pack["stacks"].append({"itemId": item_id, "quality": quality, "qty": moved})
		left -= moved
	if left != qty:
		changed.emit()
	return left


## Units held, across the backpack and every chest (stations read from all of them), or the
## wallet or silo for items stored there.
func count(item_id: String, min_quality: int = 1) -> int:
	var def: Dictionary = GameData.item(item_id)
	if def["storage"] == "wallet" or def["storage"] == "silo":
		return int(state[def["storage"]].get(item_id, 0))
	var total := 0
	for container: Dictionary in _containers():
		for stack: Dictionary in container["stacks"]:
			if stack["itemId"] == item_id and stack["quality"] >= min_quality:
				total += int(stack["qty"])
	return total


## Remove units, lowest quality first. All or nothing: returns false and changes nothing when
## there are too few.
func remove(item_id: String, qty: int, min_quality: int = 1) -> bool:
	if qty <= 0:
		return true
	if count(item_id, min_quality) < qty:
		return false
	var def: Dictionary = GameData.item(item_id)
	if def["storage"] == "wallet" or def["storage"] == "silo":
		state[def["storage"]][item_id] -= qty
		changed.emit()
		return true
	var left := qty
	for quality: int in range(min_quality, 5):
		for container: Dictionary in _containers():
			var stacks: Array = container["stacks"]
			for i: int in range(stacks.size() - 1, -1, -1):
				var stack: Dictionary = stacks[i]
				if left > 0 and stack["itemId"] == item_id and stack["quality"] == quality:
					var taken := mini(left, int(stack["qty"]))
					stack["qty"] -= taken
					left -= taken
					if stack["qty"] == 0:
						stacks.remove_at(i)
	changed.emit()
	return true


## The lowest quality among the units a recipe would consume (used by the merge quality bonus).
func lowest_quality_used(item_id: String, qty: int) -> int:
	var left := qty
	for quality: int in range(1, 5):
		for container: Dictionary in _containers():
			for stack: Dictionary in container["stacks"]:
				if stack["itemId"] == item_id and stack["quality"] == quality:
					left -= int(stack["qty"])
		if left <= 0:
			return quality
	return 1


func total_units() -> int:
	var total := 0
	for container: Dictionary in _containers():
		for stack: Dictionary in container["stacks"]:
			total += int(stack["qty"])
	for pool: String in ["wallet", "silo"]:
		for item_id: String in state[pool]:
			total += int(state[pool][item_id])
	return total


func save_state() -> Dictionary:
	return state.duplicate(true)


func load_state(data: Dictionary) -> void:
	state = SaveGame.whole_numbers(data)
	changed.emit()
