extends Node
## Livestock (GDD section 5). Autoload: Animals. Each animal is an AnimalInstance dictionary.
## MVP scope: hunger, happiness, health, productivity and the production timer. Traits,
## breeding, quality and one-time products arrive in R2.

signal changed

var animals: Array = []
var _serial := 0


func _ready() -> void:
	Sim.register(self)
	SaveGame.register_section("animals", self)


func cfg() -> Dictionary:
	return GameData.config["animals"]


func new_game() -> void:
	animals.clear()
	_serial = 0
	for entry: Dictionary in GameData.config["newGame"].get("animals", []):
		for i: int in range(int(entry["qty"])):
			_spawn(entry["animalId"], entry.get("stage", "adult"))
	changed.emit()


func _spawn(animal_id: String, stage: String) -> Dictionary:
	var def: Dictionary = GameData.def("animals", animal_id)
	_serial += 1
	var names: Array = cfg()["names"]
	var age_hours := 0.0
	if stage == "juvenile":
		age_hours = float(def["stageHours"]["baby"])
	elif stage == "adult":
		age_hours = float(def["stageHours"]["baby"]) + float(def["stageHours"]["juvenile"])
	var a := {
		"instanceId": "an_%04d" % _serial, "animalId": animal_id, "name": names[(_serial - 1) % names.size()],
		"rarity": def["defaultRarity"], "traits": [], "parents": [], "bornAt": Sim.game_minute - age_hours * 60.0,
		"stage": stage, "hunger": 100.0, "happiness": float(cfg()["startHappiness"]), "health": 100.0, "fertility": 0.0,
		"productionProgress": 0.0, "breedReadyAt": 0.0, "oneTimeGiven": [], "housingId": "%s#1" % def["housing"], "pettedDay": 0,
	}
	animals.append(a)
	return a


func housed_in(building_id: String) -> Array:
	return animals.filter(func(a: Dictionary) -> bool: return a["housingId"].begins_with(building_id + "#"))


func capacity(building_id: String) -> int:
	var level := GameState.building_level(building_id)
	if level < 1:
		return 0
	return int(GameData.def("buildings", building_id)["levels"][level - 1]["effects"].get("capacity", 0))


func free_slots(building_id: String) -> int:
	return capacity(building_id) - housed_in(building_id).size()


## "" when the animal can be bought, else the reason.
func buy_blocked(animal_id: String, price: int) -> String:
	var def: Dictionary = GameData.def("animals", animal_id)
	if GameState.building_level(def["housing"]) < 1:
		return "Needs a %s" % GameData.def("buildings", def["housing"])["name"]
	if free_slots(def["housing"]) < 1:
		return "%s is full" % GameData.def("buildings", def["housing"])["name"]
	if GameState.coins() < price:
		return "Need %d coins" % price
	return ""


func buy(animal_id: String, price: int) -> bool:
	if buy_blocked(animal_id, price) != "" or not GameState.spend_coins(price):
		return false
	var a := _spawn(animal_id, cfg()["purchasedStage"])
	GameState.notice.emit("%s the %s moved in" % [a["name"], GameData.def("animals", animal_id)["species"]])
	changed.emit()
	return true


func productivity(a: Dictionary) -> float:
	if a["hunger"] <= 0.0:
		return 0.0
	var p: Dictionary = cfg()["productivity"]
	var value: float = float(p["base"]) + float(p["happiness"]) * a["happiness"] / 100.0 + float(p["health"]) * a["health"] / 100.0
	if a["stage"] == "elder":
		value *= float(cfg()["elderProductionFactor"])
	return value


func is_sick(a: Dictionary) -> bool:
	return a["health"] < float(cfg()["sickBelow"])


func produces(a: Dictionary) -> bool:
	return a["stage"] in ["adult", "elder"] and not is_sick(a) and a["hunger"] > 0.0


func has_product(a: Dictionary) -> bool:
	return a["productionProgress"] >= 1.0


func advance(delta_minutes: float) -> void:
	if animals.is_empty():
		return
	var hours := delta_minutes / 60.0
	var c := cfg()
	var daytime: bool = not Sim.is_night()
	var visible_change := false
	for a: Dictionary in animals:
		var def: Dictionary = GameData.def("animals", a["animalId"])
		# growing up
		var age_hours: float = (Sim.game_minute + delta_minutes - float(a["bornAt"])) / 60.0
		var stage := "baby"
		if age_hours >= float(def["stageHours"]["elderAfterDays"]) * 24.0:
			stage = "elder"
		elif age_hours >= float(def["stageHours"]["baby"]) + float(def["stageHours"]["juvenile"]):
			stage = "adult"
		elif age_hours >= float(def["stageHours"]["baby"]):
			stage = "juvenile"
		if stage != a["stage"]:
			a["stage"] = stage
			visible_change = true
			if stage == "adult":
				GameState.notice.emit("%s has grown up" % a["name"])
		# hunger: an animal eats from the feeder the moment it is empty, if the silo has Feed
		a["hunger"] = maxf(0.0, a["hunger"] - float(def["hungerDrainPerHour"]) * hours)
		if a["hunger"] <= 0.0 and def["feed"] != null and Inventory.remove(def["feed"]["itemId"], int(def["feed"]["qtyPer8h"])):
			a["hunger"] = 100.0
		var hungry: bool = a["hunger"] <= 0.0
		# happiness
		var mood: float = -float(def["happinessDecayPerHour"])
		if hungry:
			mood -= float(c["hungryPenaltyPerHour"])
		elif daytime:
			mood += float(c["outdoorPerHour"])
		a["happiness"] = clampf(a["happiness"] + mood * hours, 0.0, 100.0)
		# health: animals never die
		var heal: float = -float(c["healthLossPerHourHungry"]) if hungry else float(c["healthGainPerHourFed"])
		a["health"] = clampf(a["health"] + heal * hours, 0.0, 100.0)
		# production timer advances by Productivity per game hour
		if produces(a) and not has_product(a):
			a["productionProgress"] = minf(1.0, a["productionProgress"] + productivity(a) * hours / float(def["renewable"]["intervalHours"]))
			if has_product(a):
				visible_change = true
	if visible_change:
		changed.emit()


## Pet an animal: once per game day.
func pet(instance_id: String) -> bool:
	var a := find(instance_id)
	if a.is_empty() or a["stage"] == "baby" or int(a["pettedDay"]) == Sim.day():
		return false
	a["pettedDay"] = Sim.day()
	a["happiness"] = minf(100.0, a["happiness"] + float(cfg()["petBonus"]))
	changed.emit()
	return true


func find(instance_id: String) -> Dictionary:
	for a: Dictionary in animals:
		if a["instanceId"] == instance_id:
			return a
	return {}


## Collect one animal's product. Returns the units gained (0 when none, or no room).
func collect(instance_id: String) -> int:
	var a := find(instance_id)
	if a.is_empty() or not has_product(a):
		return 0
	var r: Dictionary = GameData.def("animals", a["animalId"])["renewable"]
	if Inventory.room_for(r["itemId"]) < int(r["qty"]):
		GameState.notice.emit("Backpack is full")
		return 0
	Inventory.add(r["itemId"], int(r["qty"]))
	GameState.count_produced(r["itemId"], int(r["qty"]))
	a["productionProgress"] = 0.0
	changed.emit()
	return int(r["qty"])


func collect_all(building_id: String) -> Dictionary:
	var got := {}
	for a: Dictionary in housed_in(building_id):
		var item_id: String = GameData.def("animals", a["animalId"])["renewable"]["itemId"]
		var n := collect(a["instanceId"])
		if n > 0:
			got[item_id] = got.get(item_id, 0) + n
	return got


func products_ready(building_id: String) -> int:
	return housed_in(building_id).filter(has_product).size()


func count_producing(item_id: String) -> Array:
	return animals.filter(func(a: Dictionary) -> bool:
		return a["stage"] in ["adult", "elder"] and GameData.def("animals", a["animalId"])["renewable"]["itemId"] == item_id)


func save_state() -> Array:
	return animals.duplicate(true)


func load_state(data: Array) -> void:
	animals = data.duplicate(true)
	_serial = 0
	for a: Dictionary in animals:
		a["pettedDay"] = int(a.get("pettedDay", 0))
		_serial = maxi(_serial, int(a["instanceId"].trim_prefix("an_")))
	changed.emit()
