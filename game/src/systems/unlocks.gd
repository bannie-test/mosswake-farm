extends Node
## Evaluates the `unlock` block every definition carries (GDD section 11: "the same table exists
## as data"). Autoload: Unlocks. All keys of a block must hold.


func is_met(unlock: Dictionary) -> bool:
	for key: String in unlock:
		var v: Variant = unlock[key]
		match key:
			"start":
				if not v: return false
			"playerLevel":
				if GameState.player["level"] < int(v): return false
			"quest":
				var ok: bool = Quests.is_started(v) if unlock.get("questState", "completed") == "started" else Quests.is_completed(v)
				if not ok: return false
			"questState":
				pass
			"building":
				if GameState.building_level(v) < 1: return false
			"firstResearchOf":
				if not Research.state["researchedOnce"].has(v): return false
			"blueprint":
				if not Research.has_blueprint(v): return false
			"researchLevel":
				if int(Research.state["level"]) < int(v): return false
			"npcReputation":
				if GameState.reputation_level(v["npcId"]) < int(v["level"]): return false
			"npcMet":
				for npc_id: String in v:
					if not npc_met(npc_id): return false
	return true


## What still blocks an unlock, in words the player can act on ("Level 3", "Tobin reputation 2").
func missing_text(unlock: Dictionary) -> String:
	var parts: Array = []
	if unlock.has("playerLevel") and GameState.player["level"] < int(unlock["playerLevel"]):
		parts.append("Level %d" % int(unlock["playerLevel"]))
	if unlock.has("building") and GameState.building_level(unlock["building"]) < 1:
		parts.append(GameData.def("buildings", unlock["building"])["name"])
	if unlock.has("npcReputation") and not is_met({"npcReputation": unlock["npcReputation"]}):
		var rep: Dictionary = unlock["npcReputation"]
		parts.append("%s reputation %d" % [GameData.def("npcs", rep["npcId"])["name"].get_slice(" ", 0), int(rep["level"])])
	if unlock.has("quest") and not is_met({"quest": unlock["quest"], "questState": unlock.get("questState", "completed")}):
		parts.append("the story '%s'" % Quests.title(unlock["quest"]))
	if parts.is_empty() and not is_met(unlock):
		parts.append("research")
	return ", ".join(parts)


func npc_met(npc_id: String) -> bool:
	return is_met(GameData.def("npcs", npc_id)["appears"])


func recipe_known(recipe_id: String) -> bool:
	var r: Dictionary = GameData.def("merge_recipes", recipe_id)
	if GameState.is_unlocked(recipe_id):              # granted directly, e.g. by a quest reward
		return true
	return GameState.building_level(r["station"]) >= 1 and is_met(r["unlock"])


## The player level at which a good can first be produced (for the order generator's novelty weight).
func item_unlock_level(item_id: String) -> int:
	for plant_id: String in GameData.ids("plants"):
		var p: Dictionary = GameData.plant(plant_id)
		if p["productItemId"] == item_id:
			return int(p["unlock"].get("playerLevel", 1))
	for animal_id: String in GameData.ids("animals"):
		var a: Dictionary = GameData.def("animals", animal_id)
		if a["renewable"]["itemId"] == item_id:
			return int(a["unlock"].get("playerLevel", 1))
	for recipe_id: String in GameData.ids("merge_recipes"):
		var r: Dictionary = GameData.def("merge_recipes", recipe_id)
		if r["output"]["itemId"] == item_id:
			var level := int(r["unlock"].get("playerLevel", 1))
			if r["unlock"].has("building"):
				level = maxi(level, int(GameData.def("buildings", r["unlock"]["building"])["unlock"].get("playerLevel", 1)))
			for input: Dictionary in r["inputs"]:
				level = maxi(level, item_unlock_level(input["itemId"]))
			return level
	return 1
