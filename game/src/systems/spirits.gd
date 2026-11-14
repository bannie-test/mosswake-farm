extends Node
## Tree Spirits (GDD section 9; MVP scope of section 15). Autoload: Spirits.
##  - Discovery: one dig site with Root-sense
##  - Restoration and conversion at the Spirit Bench: clean, revive, give a vocation, awaken
##  - Automation: a generic job state machine (find target, walk, act, rest) driven by the
##    SpiritJobDefinition; one job in the MVP, job_water_plots
## All spirit time is game time (1 real second = 1 game minute at normal speed), so the same
## code runs frame by frame, while sleeping, and in soak tests.

signal changed
signal dig_changed
signal awakened(instance_id: String)

const BENCH := "bld_spirit_bench"
const SITE := "site_mossy_hollow_mvp"
const HUSK_ITEM := "spirit_husk_dormant"

var spirits: Array = []           # SpiritInstance dictionaries (saved)
var runtime: Dictionary = {}      # instance ID -> {pos, path, phase, timer, target} (not saved)
var bench: Dictionary = {}        # the husk on the Spirit Bench and its timers (saved in "misc")
var dig: Dictionary = {}          # the dig site (saved in "misc")
var world: Object = null          # the map: path_between(a, b), plot_tile(id), plots_in(rect), well_tile(), home_tile()
var _serial := 0


func _ready() -> void:
	Sim.register(self)
	Sim.dawn.connect(_on_dawn)
	SaveGame.register_section("spirits", self)
	SaveGame.register_section("misc", MiscSection.new(self))
	new_game()


func cfg() -> Dictionary:
	return GameData.config["spirits"]


func new_game() -> void:
	spirits.clear()
	runtime.clear()
	_serial = 0
	bench = {"stage": "empty", "scrubs": 0, "brewReadyAt": null, "awakenReadyAt": null, "spiritId": ""}
	dig = {}
	changed.emit()
	dig_changed.emit()


# ================================================================== Stage A: the dig site
func site() -> Dictionary:
	return GameData.def("dig_sites", SITE)


func site_open() -> bool:
	return Unlocks.is_met(site()["unlock"])


## Husk and loot positions are rolled once per save from the excavation stream.
func _ensure_dig() -> void:
	if not dig.is_empty():
		return
	var s := site()
	var rng := GameState.stream("excavation")
	var w := int(s["grid"]["w"])
	var h := int(s["grid"]["h"])
	var cells: Array = []
	for i: int in range(w * h):
		cells.append(i)
	var picks: Array = []
	var loot_count := 0
	for loot: Dictionary in s["guaranteedLoot"]:
		loot_count += int(loot["qty"])
	for i: int in range(int(s["husks"]) + loot_count):
		picks.append(cells.pop_at(rng.randi_range(0, cells.size() - 1)))
	var loot_cells := {}
	var n := int(s["husks"])
	for loot: Dictionary in s["guaranteedLoot"]:
		for k: int in range(int(loot["qty"])):
			loot_cells[str(picks[n])] = loot["itemId"]
			n += 1
	dig = {"husks": picks.slice(0, int(s["husks"])), "loot": loot_cells, "dug": {}, "digsLeft": 0, "husksFound": 0}


func digs_available() -> int:
	_ensure_dig()
	return int(dig["digsLeft"]) + Inventory.count("tool_dig_kit") * int(site()["digsPerKit"])


## Root-sense for a tile: "hot" (a husk within 1 tile), "warm" (within 3) or "cold".
func warmth(cell: int) -> String:
	_ensure_dig()
	var w := int(site()["grid"]["w"])
	var best := 999
	for husk: Variant in dig["husks"]:
		var d := maxi(absi(int(husk) % w - cell % w), absi(int(husk) / w - cell / w))
		best = mini(best, d)
	if best <= int(site()["rootSense"]["hot"]):
		return "hot"
	return "warm" if best <= int(site()["rootSense"]["warm"]) else "cold"


## Loot still buried at the site, by item ID (so the player knows it is worth digging on).
func loot_left() -> Dictionary:
	_ensure_dig()
	var out := {}
	for cell: String in dig["loot"]:
		if not dig["dug"].has(cell):
			out[dig["loot"][cell]] = int(out.get(dig["loot"][cell], 0)) + 1
	return out


## What a dug tile showed: "husk", an item ID, or its warmth mark. "" for an undug tile.
func dug_mark(cell: int) -> String:
	_ensure_dig()
	return dig["dug"].get(str(cell), "")


## One dig clears one tile. Returns what was found ("" when the dig could not be made).
func dig_tile(cell: int) -> String:
	_ensure_dig()
	if not site_open() or dig["dug"].has(str(cell)) or digs_available() < 1:
		return ""
	if int(dig["digsLeft"]) < 1:
		Inventory.remove("tool_dig_kit", 1)                 # opening a kit gives its digs
		dig["digsLeft"] = int(site()["digsPerKit"])
	dig["digsLeft"] = int(dig["digsLeft"]) - 1
	var found := warmth(cell)
	if dig["husks"].has(cell) or dig["husks"].has(float(cell)):
		found = "husk"
		dig["husksFound"] = int(dig["husksFound"]) + 1
		dig["dug"][str(cell)] = found
		Inventory.add(HUSK_ITEM, 1)
		GameState.notice.emit("You found a Dormant Husk")
	elif dig["loot"].has(str(cell)):
		found = dig["loot"][str(cell)]
		dig["dug"][str(cell)] = found
		Inventory.add(found, 1)
		GameState.notice.emit("+1 " + GameData.item(found)["name"])
	else:
		dig["dug"][str(cell)] = found
	dig_changed.emit()
	return found


# ================================================================== Stages B and C: the Spirit Bench
func bench_built() -> bool:
	return GameState.building_level(BENCH) > 0


## Put a husk from the backpack on the bench.
func place_husk() -> bool:
	if not bench_built() or bench["stage"] != "empty" or not Inventory.remove(HUSK_ITEM, 1):
		return false
	bench["stage"] = "dormant"
	bench["scrubs"] = 0
	changed.emit()
	return true


## Cleaning is hands-on: each scrub removes one patch of mud; the last one shows the face.
func scrub() -> bool:
	if bench["stage"] != "dormant":
		return false
	bench["scrubs"] = int(bench["scrubs"]) + 1
	if int(bench["scrubs"]) >= int(cfg()["cleanScrubs"]):
		bench["stage"] = "cleaned"
		Quests.on_interact("clean_husk")
	changed.emit()
	return true


## Whether a restoration step has already happened (story steps ask this).
func has_done(target: String) -> bool:
	match target:
		"clean_husk":
			return bench["stage"] in ["cleaned", "sprout", "awakening"] or not spirits.is_empty()
		"revive_husk":
			return bench["stage"] in ["sprout", "awakening"] or not spirits.is_empty()
		"awaken_spirit":
			return not spirits.is_empty()
	return false


func potion_recipe() -> Dictionary:
	return GameData.def("craft_recipes", "craft_revival_potion")


func brew_blocked() -> String:
	if not bench_built():
		return "Needs the Spirit Bench"
	if bench["brewReadyAt"] != null:
		return "Already brewing"
	var c := potion_recipe()
	for input: Dictionary in c["inputs"]:
		if Inventory.count(input["itemId"]) < int(input["qty"]):
			return "Need %d %s" % [int(input["qty"]), GameData.item(input["itemId"])["name"]]
	if GameState.coins() < int(c["coins"]):
		return "Need %d coins" % int(c["coins"])
	return ""


func brew() -> bool:
	if brew_blocked() != "":
		return false
	var c := potion_recipe()
	for input: Dictionary in c["inputs"]:
		Inventory.remove(input["itemId"], int(input["qty"]))
	GameState.spend_coins(int(c["coins"]))
	bench["brewReadyAt"] = Sim.game_minute + float(c["hours"]) * 60.0
	changed.emit()
	return true


func revive() -> bool:
	if bench["stage"] != "cleaned" or not Inventory.remove("spirit_revival_potion", 1):
		return false
	bench["stage"] = "sprout"
	Quests.on_interact("revive_husk")
	changed.emit()
	return true


func classes() -> Array:
	return GameData.ids("spirits").filter(func(id: String) -> bool: return Unlocks.is_met(GameData.def("spirits", id)["unlock"]))


func charm_blocked(spirit_id: String) -> String:
	if bench["stage"] != "sprout":
		return "Needs a revived sprout"
	var charm: Dictionary = GameData.def("spirits", spirit_id)["charmRecipe"]
	for input: Dictionary in charm["inputs"]:
		if Inventory.count(input["itemId"]) < int(input["qty"]):
			return "Need %d %s" % [int(input["qty"]), GameData.item(input["itemId"])["name"]]
	if GameState.coins() < int(charm["coins"]):
		return "Need %d coins" % int(charm["coins"])
	return ""


## Give the sprout its vocation. The class is the player's choice, never a roll.
func start_awakening(spirit_id: String) -> bool:
	if charm_blocked(spirit_id) != "":
		return false
	var charm: Dictionary = GameData.def("spirits", spirit_id)["charmRecipe"]
	for input: Dictionary in charm["inputs"]:
		Inventory.remove(input["itemId"], int(input["qty"]))
	GameState.spend_coins(int(charm["coins"]))
	bench["stage"] = "awakening"
	bench["spiritId"] = spirit_id
	bench["awakenReadyAt"] = Sim.game_minute + float(cfg()["awakenHours"]) * 60.0
	changed.emit()
	return true


func _finish_awakening() -> void:
	var def: Dictionary = GameData.def("spirits", bench["spiritId"])
	_serial += 1
	var names: Array = cfg()["names"]
	var s := {
		"instanceId": "sp_%04d" % _serial, "spiritId": def["id"], "name": names[(_serial - 1) % names.size()], "isElder": false,
		"skillLevel": 1, "skillXp": 0, "skillCap": mini(int(cfg()["mvpSkillCap"]), def["levels"].size()),
		"stamina": float(def["levels"][0]["stamina"]), "state": "idle", "zone": null, "chestId": null, "carrying": {},
		"upkeepPaidDay": Sim.day(), "grafts": {"tool": 0, "heartwood": false, "rootbed": false},
	}
	spirits.append(s)
	bench = {"stage": "empty", "scrubs": 0, "brewReadyAt": bench["brewReadyAt"], "awakenReadyAt": null, "spiritId": ""}
	Quests.on_interact("awaken_spirit")
	GameState.notice.emit("%s the %s is awake" % [s["name"], def["name"]])
	awakened.emit(s["instanceId"])
	changed.emit()


# ================================================================== Stage D: automation
func find(instance_id: String) -> Dictionary:
	for s: Dictionary in spirits:
		if s["instanceId"] == instance_id:
			return s
	return {}


func level_def(s: Dictionary) -> Dictionary:
	return GameData.def("spirits", s["spiritId"])["levels"][int(s["skillLevel"]) - 1]


func job(s: Dictionary) -> Dictionary:
	return GameData.def("spirit_jobs", GameData.def("spirits", s["spiritId"])["jobId"])


## An unfed spirit is Drowsy: it works at `upkeep.unpaidSpeed` and gains no skill XP. It never leaves.
func is_drowsy(s: Dictionary) -> bool:
	return int(s["upkeepPaidDay"]) < Sim.day()


func speed(s: Dictionary) -> float:
	var v := float(level_def(s)["speed"])
	if is_drowsy(s):
		v *= float(GameData.def("spirits", s["spiritId"])["upkeep"]["unpaidSpeed"])
	return v


func zone_limit(s: Dictionary) -> int:
	return int(level_def(s)["zoneTiles"])


## "" when the rectangle can be this spirit's zone, else the reason.
func zone_blocked(instance_id: String, rect: Rect2i) -> String:
	var s := find(instance_id)
	if s.is_empty():
		return "No such spirit"
	if rect.size.x < 1 or rect.size.y < 1:
		return "Empty zone"
	if rect.size.x * rect.size.y > zone_limit(s):
		return "Too large: %d of %d tiles" % [rect.size.x * rect.size.y, zone_limit(s)]
	for other: Dictionary in spirits:
		if other["instanceId"] != instance_id and other["spiritId"] == s["spiritId"] and other["zone"] != null:
			var z: Dictionary = other["zone"]
			if Rect2i(int(z["x"]), int(z["y"]), int(z["w"]), int(z["h"])).intersects(rect):
				return "Overlaps another %s's zone" % GameData.def("spirits", s["spiritId"])["name"]
	return ""


func set_zone(instance_id: String, rect: Rect2i) -> bool:
	if zone_blocked(instance_id, rect) != "":
		return false
	find(instance_id)["zone"] = {"map": "farm", "x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y}
	changed.emit()
	return true


func zone_rect(s: Dictionary) -> Rect2i:
	var z: Dictionary = s["zone"]
	return Rect2i(int(z["x"]), int(z["y"]), int(z["w"]), int(z["h"]))


func _rt(s: Dictionary) -> Dictionary:
	if not runtime.has(s["instanceId"]):
		var home := Vector2(world.home_tile()) if world != null else Vector2.ZERO
		runtime[s["instanceId"]] = {"pos": home, "path": [], "phase": "idle", "timer": 0.0, "target": "", "retry": 0.0}
	return runtime[s["instanceId"]]


func position_of(instance_id: String) -> Vector2:
	return runtime[instance_id]["pos"] if runtime.has(instance_id) else Vector2.ZERO


func advance(delta_minutes: float) -> void:
	var now := Sim.game_minute + delta_minutes
	if bench.get("brewReadyAt") != null and now >= float(bench["brewReadyAt"]) - 0.000001:
		bench["brewReadyAt"] = null
		var out: Dictionary = potion_recipe()["output"]
		Inventory.add(out["itemId"], int(out["qty"]))
		GameState.count_produced(out["itemId"], int(out["qty"]))
		GameState.notice.emit("The %s is ready" % GameData.item(out["itemId"])["name"])
		changed.emit()
	if bench.get("awakenReadyAt") != null and now >= float(bench["awakenReadyAt"]) - 0.000001:
		_finish_awakening()
	if world == null:
		return
	for s: Dictionary in spirits:
		_run(s, _rt(s), delta_minutes)


## The generic job loop. It spends the step's time budget moving through its phases, so one long
## step (sleeping, a soak test) plays out the same as many short ones.
func _run(s: Dictionary, rt: Dictionary, dt: float) -> void:
	var def: Dictionary = GameData.def("spirits", s["spiritId"])
	var lv := level_def(s)
	var budget := dt
	var guard := 0
	while budget > 0.000001 and guard < 400:
		guard += 1
		var v := speed(s)
		match rt["phase"]:
			"rest":
				var full := float(lv["stamina"])
				var per_minute := full / (float(lv["restHours"]) * 60.0)
				var used := minf(budget, (full - float(s["stamina"])) / per_minute)
				s["stamina"] = minf(full, float(s["stamina"]) + used * per_minute)
				budget -= used
				if float(s["stamina"]) >= full - 0.000001:
					s["stamina"] = full
					rt["phase"] = "idle"
			"wait":
				# with nothing to do a spirit rests where it stands, at its normal rest rate
				var used := minf(budget, float(rt["retry"]))
				rt["retry"] = float(rt["retry"]) - used
				budget -= used
				s["stamina"] = minf(float(lv["stamina"]), float(s["stamina"]) + used * float(lv["stamina"]) / (float(lv["restHours"]) * 60.0))
				if float(rt["retry"]) <= 0.000001:
					rt["phase"] = "idle"
			"idle":
				if float(s["stamina"]) < 1.0:
					rt["phase"] = "rest"
				elif s["zone"] == null:
					_wait(rt, 5.0)
				else:
					_choose(s, rt)
			"walk":
				var tiles := float(def["base"]["moveTilesPerSecond"]) * v * budget
				while tiles > 0.000001 and not rt["path"].is_empty():
					var next: Vector2 = Vector2(rt["path"][0])
					var d: float = rt["pos"].distance_to(next)
					if d <= tiles:
						rt["pos"] = next
						rt["path"].pop_front()
						tiles -= d
					else:
						rt["pos"] = rt["pos"].move_toward(next, tiles)
						tiles = 0.0
				budget = tiles / (float(def["base"]["moveTilesPerSecond"]) * v)
				if rt["path"].is_empty():
					rt["phase"] = rt["then"]
					rt["timer"] = float(def["base"]["actionSeconds"]) / v * (float(cfg()["refillActions"]) if rt["then"] == "refill" else 1.0)
			"refill", "act":
				# the timer is in game minutes at the current speed; a speed change mid-action is ignored
				var used := minf(budget, float(rt["timer"]))
				rt["timer"] = float(rt["timer"]) - used
				budget -= used
				if float(rt["timer"]) <= 0.000001:
					if rt["phase"] == "refill":
						s["carrying"][job(s)["consumes"]["resource"]] = int(def["base"]["carry"])
					else:
						_act(s, rt)
					rt["phase"] = "idle"
	s["state"] = {"rest": "resting", "wait": "idle", "idle": "idle", "walk": "walking", "refill": "working", "act": "working"}[rt["phase"]]


func _wait(rt: Dictionary, minutes: float) -> void:
	rt["phase"] = "wait"
	rt["retry"] = minutes


## Find the next thing to do: refill when empty-handed, else the best target of the job.
func _choose(s: Dictionary, rt: Dictionary) -> void:
	var j := job(s)
	var consumes: Variant = j["consumes"]
	var here := Vector2i(rt["pos"].round())
	if consumes != null and int(s["carrying"].get(consumes["resource"], 0)) < int(consumes["perAction"]):
		var path: Array = world.path_between(here, world.well_tile())
		if path.is_empty() and here != world.well_tile():
			_wait(rt, 5.0)                        # no way to the well right now: try again shortly
			return
		rt["path"] = path
		rt["phase"] = "walk"
		rt["then"] = "refill"
		return
	var best := ""
	var best_path: Array = []
	var best_score := INF
	for plot_id: String in world.plots_in(zone_rect(s)):
		if not _is_target(j, plot_id):
			continue
		var score: float = Farm.plot(plot_id)["moisture"]          # priority: lowestMoistureFirst
		if score >= best_score:
			continue
		var tile: Vector2i = world.plot_tile(plot_id)
		var path: Array = world.path_between(here, tile)
		if path.is_empty() and here != tile:
			continue                              # unreachable: skip it, never get stuck on it
		best = plot_id
		best_path = path
		best_score = score
	if best == "":
		_wait(rt, 5.0)                            # nothing to do: look again in a few minutes
		return
	rt["target"] = best
	rt["path"] = best_path
	rt["phase"] = "walk"
	rt["then"] = "act"


func _is_target(j: Dictionary, plot_id: String) -> bool:
	var p: Dictionary = Farm.plot(plot_id)
	var f: Dictionary = j["targetFilter"]
	if f.get("hasCrop", false) and not Farm.is_planted(p):
		return false
	return not f.has("moistureBelow") or float(p["moisture"]) < float(f["moistureBelow"])


func _act(s: Dictionary, rt: Dictionary) -> void:
	var j := job(s)
	var plot_id: String = rt["target"]
	rt["target"] = ""
	if not Farm.plots.has(plot_id) or not _is_target(j, plot_id):
		return                                    # the player got there first; nothing is spent
	if j["action"] == "water":
		Farm.water(plot_id)
	if j["consumes"] != null:
		var res: String = j["consumes"]["resource"]
		s["carrying"][res] = int(s["carrying"].get(res, 0)) - int(j["consumes"]["perAction"])
	s["stamina"] = float(s["stamina"]) - 1.0
	if not is_drowsy(s):
		_gain_skill(s)


func _gain_skill(s: Dictionary) -> void:
	s["skillXp"] = int(s["skillXp"]) + 1
	var levels: Array = GameData.def("spirits", s["spiritId"])["levels"]
	while int(s["skillLevel"]) < int(s["skillCap"]) and int(s["skillXp"]) >= int(levels[int(s["skillLevel"])]["xp"]):
		s["skillLevel"] = int(s["skillLevel"]) + 1
		GameState.notice.emit("%s reached skill level %d" % [s["name"], int(s["skillLevel"])])
		changed.emit()


## Upkeep is paid at each dawn: 1 Sap per spirit. Unpaid upkeep slows a spirit; it never removes it.
func _on_dawn(day: int) -> void:
	for s: Dictionary in spirits:
		var upkeep: Dictionary = GameData.def("spirits", s["spiritId"])["upkeep"]
		if Inventory.remove(upkeep["itemId"], int(upkeep["qtyPerDay"])):
			s["upkeepPaidDay"] = day
		else:
			GameState.notice.emit("%s is drowsy: no %s for breakfast" % [s["name"], GameData.item(upkeep["itemId"])["name"]])
	if not spirits.is_empty():
		changed.emit()


# ================================================================== save
func save_state() -> Array:
	return spirits.duplicate(true)


func load_state(data: Array) -> void:
	spirits = data.duplicate(true)
	runtime.clear()
	_serial = 0
	for s: Dictionary in spirits:
		for key: String in ["skillLevel", "skillXp", "skillCap", "upkeepPaidDay"]:
			s[key] = int(s[key])
		s["carrying"] = SaveGame.whole_numbers(s["carrying"])
		s["grafts"]["tool"] = int(s["grafts"]["tool"])
		if s["zone"] != null:
			s["zone"] = SaveGame.whole_numbers(s["zone"])
		_serial = maxi(_serial, int(s["instanceId"].trim_prefix("sp_")))
	changed.emit()


class MiscSection:
	var _spirits: Node
	func _init(owner_: Node) -> void:
		_spirits = owner_
	func save_state() -> Dictionary:
		return {"bench": _spirits.bench.duplicate(true), "dig": _spirits.dig.duplicate(true)}
	func load_state(data: Dictionary) -> void:
		_spirits.bench = data.get("bench", _spirits.bench).duplicate(true)
		_spirits.bench["scrubs"] = int(_spirits.bench.get("scrubs", 0))
		var d: Dictionary = data.get("dig", {}).duplicate(true)
		if not d.is_empty():
			d["husks"] = d["husks"].map(func(v: Variant) -> int: return int(v))
			d["digsLeft"] = int(d["digsLeft"])
			d["husksFound"] = int(d["husksFound"])
		_spirits.dig = d
		_spirits.changed.emit()
		_spirits.dig_changed.emit()
