extends Node
## Story quests (GDD section 8, "Story quests and what they gate"). Autoload: Quests.
## State has the shape of QuestProgress. A quest starts by itself when its giver is there and
## its requirements are met; each NPC has at most one active quest.

signal changed
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)

var active: Array = []        # {questId, stepId, counters}
var completed: Array = []
var disabled: Array = []      # scaffolding: quests whose systems do not exist yet


func _ready() -> void:
	SaveGame.register_section("quests", self)
	GameState.leveled_up.connect(func(_l: int) -> void: refresh())
	GameState.building_changed.connect(func(_id: String) -> void: refresh())
	GameState.produced.connect(_on_produced)
	Inventory.changed.connect(_check_steps)


func new_game() -> void:
	active.clear()
	completed.clear()
	refresh()


func def(quest_id: String) -> Dictionary:
	return GameData.def("quests", quest_id)


func title(quest_id: String) -> String:
	return GameData.text("quest.%s.name" % quest_id.trim_prefix("quest_"))


func is_completed(quest_id: String) -> bool:
	return completed.has(quest_id)


func is_started(quest_id: String) -> bool:
	return completed.has(quest_id) or active.any(func(e: Dictionary) -> bool: return e["questId"] == quest_id)


func entry(quest_id: String) -> Dictionary:
	for e: Dictionary in active:
		if e["questId"] == quest_id:
			return e
	return {}


func current_step(e: Dictionary) -> Dictionary:
	for step: Dictionary in def(e["questId"])["steps"]:
		if step["id"] == e["stepId"]:
			return step
	return {}


func requirements_met(req: Dictionary) -> bool:
	for key: String in req:
		var v: Variant = req[key]
		match key:
			"playerLevel":
				if GameState.player["level"] < int(v): return false
			"npcMet":
				for npc_id: String in v:
					if not Unlocks.npc_met(npc_id): return false
			"quest":
				if not is_completed(v): return false
			"building":
				if GameState.building_level(v) < 1: return false
			"npcReputation":
				if GameState.reputation_level(v["npcId"]) < int(v["level"]): return false
			"researchLevel":
				if int(Research.state["level"]) < int(v): return false
			"ordersCompleted":
				if int(GameState.player["stats"]["ordersCompleted"]) < int(v): return false
	return true


## Start every quest that can start now, then see whether any step is already satisfied.
func refresh() -> void:
	if SaveGame.loading:
		return
	var started := false
	for quest_id: String in GameData.ids("quests"):
		var q := def(quest_id)
		if is_started(quest_id) or disabled.has(quest_id) or not Unlocks.npc_met(q["giver"]):
			continue
		if active.any(func(e: Dictionary) -> bool: return def(e["questId"])["giver"] == q["giver"]):
			continue                                  # one active quest per NPC
		if not requirements_met(q["requires"]):
			continue
		active.append({"questId": quest_id, "stepId": q["steps"][0]["id"], "counters": {}})
		started = true
		quest_started.emit(quest_id)
		GameState.notice.emit("New story from %s: %s" % [GameData.def("npcs", q["giver"])["name"].get_slice(" ", 0), title(quest_id)])
	if started:
		changed.emit()
	_check_steps()


## [have, need] for the step an active quest is on.
func progress(e: Dictionary) -> Array:
	var step := current_step(e)
	match step["type"]:
		"deliver":
			return [mini(Inventory.count(step["itemId"]), int(step["qty"])), int(step["qty"])]
		"produce":
			# goods made before the step began count too, as long as they are still held
			return [mini(maxi(int(e["counters"].get(step["id"], 0)), Inventory.count(step["itemId"])), int(step["qty"])), int(step["qty"])]
		"build":
			return [mini(1, GameState.building_level(step["buildingId"])), 1]
		"research":
			return [mini(e["counters"].get("research", []).size(), int(step["qty"])), int(step["qty"])]
		"reach":
			return [mini(Inventory.count(step["itemId"]), int(step["qty"])), int(step["qty"])]
	# interact steps read the world, so doing things early never strands a quest
	return [1 if int(e["counters"].get(step["id"], 0)) > 0 or Spirits.has_done(step["target"]) else 0, 1]


func step_text(e: Dictionary) -> String:
	var p := progress(e)
	return "%s (%d/%d)" % [GameData.text(current_step(e)["text"]), p[0], p[1]]


func can_deliver(quest_id: String) -> bool:
	var e := entry(quest_id)
	if e.is_empty():
		return false
	var step := current_step(e)
	return step["type"] == "deliver" and Inventory.count(step["itemId"]) >= int(step["qty"])


## Hand over the goods of a deliver step.
func deliver(quest_id: String) -> bool:
	if not can_deliver(quest_id):
		return false
	var e := entry(quest_id)
	var step := current_step(e)
	Inventory.remove(step["itemId"], int(step["qty"]))
	_advance(e)
	return true


## Units of an item that active deliver steps still need (section 10: such items are flagged, and
## selling, merging or researching the last required unit warns first).
func reserved(item_id: String) -> int:
	var total := 0
	for e: Dictionary in active:
		var step := current_step(e)
		if step["type"] == "deliver" and step["itemId"] == item_id:
			total += int(step["qty"])
	return total


func reserved_for(item_id: String) -> String:
	for e: Dictionary in active:
		var step := current_step(e)
		if step["type"] == "deliver" and step["itemId"] == item_id:
			return GameData.def("npcs", def(e["questId"])["giver"])["name"].get_slice(" ", 0)
	return ""


## True when using up `qty` units would leave fewer than a story step needs.
func would_break(item_id: String, qty: int) -> bool:
	var need := reserved(item_id)
	return need > 0 and Inventory.count(item_id) >= need and Inventory.count(item_id) - qty < need


func _on_produced(item_id: String, qty: int) -> void:
	for e: Dictionary in active:
		var step := current_step(e)
		if step["type"] == "produce" and step["itemId"] == item_id:
			e["counters"][step["id"]] = int(e["counters"].get(step["id"], 0)) + qty
	_check_steps()


func on_researched(item_id: String) -> void:
	for e: Dictionary in active:
		if current_step(e)["type"] == "research":
			var seen: Array = e["counters"].get("research", [])
			if not seen.has(item_id):
				seen.append(item_id)
			e["counters"]["research"] = seen
	_check_steps()


## An interact step (M4) reports itself here.
func on_interact(target: String) -> void:
	for e: Dictionary in active:
		var step := current_step(e)
		if step["type"] == "interact" and step["target"] == target:
			e["counters"][step["id"]] = 1
	_check_steps()


var _checking := false


## Steps that finish by themselves: produce, build, research, reach, interact.
func _check_steps() -> void:
	if _checking or SaveGame.loading:
		return
	_checking = true
	var moved := true
	while moved:
		moved = false
		for e: Dictionary in active.duplicate():
			var step := current_step(e)
			if step["type"] == "deliver":
				continue
			var p := progress(e)
			if p[0] >= p[1]:
				_advance(e)
				moved = true
	_checking = false


func _advance(e: Dictionary) -> void:
	var q := def(e["questId"])
	var step := current_step(e)
	for grant: Dictionary in step.get("grants", []):
		Inventory.add(grant["itemId"], int(grant["qty"]))
		GameState.notice.emit("+%d %s" % [int(grant["qty"]), GameData.item(grant["itemId"])["name"]])
	var index: int = q["steps"].find(step)
	if index + 1 < q["steps"].size():
		e["stepId"] = q["steps"][index + 1]["id"]
		changed.emit()
		return
	active.erase(e)
	completed.append(e["questId"])
	var rewards: Dictionary = q["rewards"]
	for npc_id: String in rewards["reputation"]:
		GameState.add_reputation(npc_id, int(rewards["reputation"][npc_id]))
	for id: String in rewards["unlocks"]:
		GameState.unlock(id)
	for item: Dictionary in rewards["items"]:
		Inventory.add(item["itemId"], int(item["qty"]))
		GameState.notice.emit("+%d %s" % [int(item["qty"]), GameData.item(item["itemId"])["name"]])
	GameState.notice.emit("Story complete: " + title(e["questId"]))
	GameState.add_xp(int(rewards["xp"]))
	quest_completed.emit(e["questId"])
	changed.emit()
	Orders.fill_slots()
	refresh()


# ---- save section "quests" (QuestProgress)
func save_state() -> Dictionary:
	return {"active": active.duplicate(true), "completed": completed.duplicate(),
		"orders": Orders.orders.map(func(o: Dictionary) -> String: return o["orderId"]),
		"slotRefillAt": Orders.slot_refill_at.duplicate()}


func load_state(data: Dictionary) -> void:
	active = SaveGame.whole_numbers(data.get("active", []))
	completed = data.get("completed", []).duplicate()
	Orders.slot_refill_at = data.get("slotRefillAt", {}).duplicate()
	changed.emit()
