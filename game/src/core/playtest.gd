extends Node
## Playtest log (M6): a plain record of one play session, kept on the player's own computer in
## user://playtest/. Nothing is sent anywhere. It exists so that the section 20 playtest criteria
## (time to level 5, who tries a Rare merge, income per game day against the simulator, session
## length before and after the first spirit) can be measured instead of guessed.
## Autoload: Playtest. Switched by the "playtestLog" setting.

var session: Dictionary = {}
var _path := ""
var _day_earned := 0
var _day_spent := 0
var _last_coins := 0
var _started_usec := 0
var active := false


func _ready() -> void:
	GameState.leveled_up.connect(func(level: int) -> void: event("level_up", {"level": level}))
	GameState.changed.connect(_track_coins)
	Orders.delivered.connect(func(o: Dictionary) -> void: event("order_delivered", {"npc": o["npcId"], "coins": o["rewards"]["coins"]}))
	Merge.merged.connect(func(recipe_id: String, r: Dictionary) -> void:
		event("merge", {"recipe": recipe_id, "rarity": Merge.recipe(recipe_id)["rarity"], "chance": r["chance"], "outcome": r["outcome"]}))
	Quests.quest_completed.connect(func(q: String) -> void: event("quest_completed", {"quest": q}))
	Farm.harvested.connect(func(_p: String, item_id: String, qty: int) -> void:
		if GameData.item(item_id)["rarity"] != "common":
			event("rare_harvest", {"item": item_id, "qty": qty}))
	Spirits.awakened.connect(func(_id: String) -> void: event("spirit_awake", {}))
	Sim.dawn.connect(_on_dawn)


## Begin recording. `dir` lets tests write somewhere else.
func start(dir: String = "user://playtest") -> void:
	if not Settings.get_value("playtestLog"):
		return
	DirAccess.make_dir_recursive_absolute(dir)
	_started_usec = Time.get_ticks_usec()
	_path = "%s/session_%d.json" % [dir, int(Time.get_unix_time_from_system())]
	_last_coins = GameState.coins()
	_day_earned = 0
	_day_spent = 0
	session = {"version": ProjectSettings.get_setting("application/config/version", ""), "dataVersion": GameData.data_version,
		"startLevel": GameState.player["level"], "startGameMinute": Sim.game_minute, "events": [], "days": [], "realSeconds": 0.0}
	active = true


func real_seconds() -> float:
	return (Time.get_ticks_usec() - _started_usec) / 1000000.0


func event(kind: String, info: Dictionary) -> void:
	if not active:
		return
	var e := {"t": snappedf(real_seconds(), 0.1), "gameMinute": int(Sim.game_minute), "level": GameState.player["level"], "kind": kind}
	e.merge(info)
	session["events"].append(e)


func _track_coins() -> void:
	if not active:
		return
	var delta: int = GameState.coins() - _last_coins
	_last_coins = GameState.coins()
	if delta > 0:
		_day_earned += delta
	else:
		_day_spent -= delta


func _on_dawn(day: int) -> void:
	if not active:
		return
	session["days"].append({"day": day - 1, "level": GameState.player["level"], "earned": _day_earned, "spent": _day_spent,
		"plots": Farm.plots.size(), "animals": Animals.animals.size(), "spirits": Spirits.spirits.size()})
	_day_earned = 0
	_day_spent = 0
	flush()


func flush() -> void:
	if not active:
		return
	session["realSeconds"] = snappedf(real_seconds(), 0.1)
	session["endLevel"] = GameState.player["level"]
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(session, "  "))
		f.close()


func stop() -> String:
	flush()
	active = false
	return _path
