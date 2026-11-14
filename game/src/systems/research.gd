extends Node
## Research and blueprints (GDD section 7). Autoload: Research. State is ResearchProgress.
## Research destroys a rare good to learn from it; the yield has no random term.

signal changed

const STATION := "bld_research_station"

var state: Dictionary = {}


func _ready() -> void:
	Sim.register(self)
	SaveGame.register_section("research", self)
	new_game()


func cfg() -> Dictionary:
	return GameData.config["research"]


func new_game() -> void:
	state = {"level": 1, "xp": 0, "queue": [], "researchedOnce": [], "blueprints": [], "codex": {}, "traitsSeen": []}
	changed.emit()


func slots() -> int:
	var level := GameState.building_level(STATION)
	if level < 1:
		return 0
	var n := int(GameData.def("buildings", STATION)["levels"][level - 1]["effects"].get("queueSlots", 1))
	for unlock: Dictionary in cfg()["levelUnlocks"]:
		if int(state["level"]) >= int(unlock["level"]) and unlock["effect"].has("queueSlots"):
			n = maxi(n, int(unlock["effect"]["queueSlots"]))
	return n


func researchable(item_id: String) -> bool:
	return GameData.item(item_id)["research"] != null


func is_first(item_id: String) -> bool:
	return not state["researchedOnce"].has(item_id)


## fragments = round(base x qualityMult x (1 + levelBonus x ResearchLevel)) x (2 if first research)
func fragments_for(item_id: String, quality: int) -> int:
	var r: Dictionary = GameData.item(item_id)["research"]
	var mult := float(cfg()["qualityYield"][str(quality)])
	var n := roundi(float(r["fragments"]) * mult * (1.0 + float(cfg()["levelBonusPerLevel"]) * int(state["level"])))
	return n * (int(cfg()["firstResearchMultiplier"]) if is_first(item_id) else 1)


## "" when the item can be queued now, else the reason.
func blocked_reason(item_id: String) -> String:
	if GameState.building_level(STATION) < 1:
		return "Needs the Research Station"
	if not researchable(item_id):
		return "Nothing to learn from this"
	if Inventory.count(item_id) < 1:
		return "None in stock"
	if state["queue"].size() >= slots():
		return "The queue is full"
	var coins := int(GameData.item(item_id)["research"]["coins"])
	if GameState.coins() < coins:
		return "Need %d coins" % coins
	return ""


func start(item_id: String) -> bool:
	if blocked_reason(item_id) != "":
		return false
	var r: Dictionary = GameData.item(item_id)["research"]
	var quality := Inventory.lowest_quality_used(item_id, 1)
	Inventory.remove(item_id, 1)                     # deconstruction: the item is destroyed
	GameState.spend_coins(int(r["coins"]))
	state["queue"].append({"itemId": item_id, "quality": quality, "startedAt": Sim.game_minute, "readyAt": Sim.game_minute + float(r["hours"]) * 60.0})
	changed.emit()
	return true


func advance(delta_minutes: float) -> void:
	if state["queue"].is_empty():
		return
	var now := Sim.game_minute + delta_minutes
	for job: Dictionary in state["queue"].duplicate():
		if now >= float(job["readyAt"]) - 0.000001:
			state["queue"].erase(job)
			if job.has("blueprintId"):
				_finish_creation(job)
			else:
				_finish_research(job)


func _finish_research(job: Dictionary) -> void:
	var item_id: String = job["itemId"]
	var def: Dictionary = GameData.item(item_id)
	var r: Dictionary = def["research"]
	var gained := 0
	if r["geneId"] != null and int(r["fragments"]) > 0:
		var gene: Dictionary = GameData.def("genes", r["geneId"])
		gained = mini(fragments_for(item_id, int(job["quality"])), int(gene["walletCap"]) - Inventory.count(r["geneId"]))
		Inventory.add(r["geneId"], gained)
		_stamp(gene["species"], "researched")
	if int(r["stardust"]) > 0:
		Inventory.add("mat_stardust", int(r["stardust"]))
	var first := is_first(item_id)
	if first:
		state["researchedOnce"].append(item_id)
	var parts: Array = []
	if gained > 0:
		parts.append("%d %s%s" % [gained, GameData.item(r["geneId"])["name"], " (first time: doubled)" if first else ""])
	if int(r["stardust"]) > 0:
		parts.append("%d Stardust" % int(r["stardust"]))
	GameState.notice.emit("Research done: %s%s" % [def["name"], "" if parts.is_empty() else " -> " + ", ".join(parts)])
	_add_research_xp(gained)
	GameState.add_xp(gained * int(GameData.config["economy"]["xpRate"]["perGeneFragment"]))
	changed.emit()
	Quests.on_researched(item_id)
	Orders.fill_slots()


func _add_research_xp(n: int) -> void:
	state["xp"] += n                                  # Research XP equals fragments gained
	var thresholds: Array = cfg()["levelThresholds"]
	while int(state["level"]) - 1 < thresholds.size() and int(state["xp"]) >= int(thresholds[int(state["level"]) - 1]):
		state["level"] += 1
		GameState.notice.emit("Research level %d" % int(state["level"]))


func _stamp(species: String, stamp: String) -> void:
	var page: Array = state["codex"].get(species, ["discovered"])
	if not page.has(stamp):
		page.append(stamp)
	state["codex"][species] = page


# ---- blueprints
func blueprint(bp_id: String) -> Dictionary:
	return GameData.def("blueprints", bp_id)


func has_blueprint(bp_id: String) -> bool:
	return state["blueprints"].has(bp_id)


func can_unlock(bp_id: String) -> bool:
	if has_blueprint(bp_id) or GameState.building_level(STATION) < 1:
		return false
	for cost: Dictionary in blueprint(bp_id)["fragmentCost"]:
		if Inventory.count(cost["geneId"]) < int(cost["qty"]):
			return false
	return true


## Spend the fragments; the blueprint is permanent knowledge.
func unlock_blueprint(bp_id: String) -> bool:
	if not can_unlock(bp_id):
		return false
	for cost: Dictionary in blueprint(bp_id)["fragmentCost"]:
		Inventory.remove(cost["geneId"], int(cost["qty"]))
		_stamp(GameData.def("genes", cost["geneId"])["species"], "blueprint")
	state["blueprints"].append(bp_id)
	GameState.notice.emit("Blueprint learned: " + GameData.item(blueprint(bp_id)["creation"]["output"]["itemId"])["name"])
	changed.emit()
	return true


func creation_blocked(bp_id: String) -> String:
	if not has_blueprint(bp_id):
		return "Blueprint not learned"
	var c: Dictionary = blueprint(bp_id)["creation"]
	if GameState.building_level(c["station"]) < 1:
		return "Needs the " + GameData.def("buildings", c["station"])["name"]
	if state["queue"].size() >= slots():
		return "The queue is full"
	for input: Dictionary in c["inputs"]:
		if Inventory.count(input["itemId"]) < int(input["qty"]):
			return "Need %d %s" % [int(input["qty"]), GameData.item(input["itemId"])["name"]]
	if GameState.coins() < int(c["coins"]):
		return "Need %d coins" % int(c["coins"])
	return ""


## Each use of a blueprint still costs a rare good (section 7).
func create(bp_id: String) -> bool:
	if creation_blocked(bp_id) != "":
		return false
	var c: Dictionary = blueprint(bp_id)["creation"]
	for input: Dictionary in c["inputs"]:
		Inventory.remove(input["itemId"], int(input["qty"]))
	GameState.spend_coins(int(c["coins"]))
	state["queue"].append({"itemId": c["output"]["itemId"], "quality": 1, "startedAt": Sim.game_minute,
		"readyAt": Sim.game_minute + float(c["hours"]) * 60.0, "blueprintId": bp_id})
	changed.emit()
	return true


func _finish_creation(job: Dictionary) -> void:
	var out: Dictionary = blueprint(job["blueprintId"])["creation"]["output"]
	Inventory.add(out["itemId"], int(out["qty"]))
	GameState.count_produced(out["itemId"], int(out["qty"]))
	GameState.notice.emit("+%d %s" % [int(out["qty"]), GameData.item(out["itemId"])["name"]])
	changed.emit()
	Orders.fill_slots()


func save_state() -> Dictionary:
	return state.duplicate(true)


func load_state(data: Dictionary) -> void:
	state = data.duplicate(true)
	state["level"] = int(state["level"])
	state["xp"] = int(state["xp"])
	for job: Dictionary in state["queue"]:
		job["quality"] = int(job["quality"])
	changed.emit()
