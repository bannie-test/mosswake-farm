extends Node
## Runtime state that is not owned by a world system: player progression, buildings and the
## random streams (GDD section 14, "Save envelope and PlayerProgression"). Autoload: GameState.

signal changed
signal leveled_up(level: int)
signal notice(text: String)          ## short messages for the HUD toasts

const RNG_STREAMS := ["merge", "harvest", "orders", "breeding", "excavation"]

var player: Dictionary = {}
var buildings: Dictionary = {}    # building ID -> level (built buildings only)
var rng: Dictionary = {}          # stream name -> RngStream


func _ready() -> void:
	SaveGame.register_section("player", self)
	new_game(int(Time.get_unix_time_from_system()))


func new_game(seed_value: int) -> void:
	var cfg: Dictionary = GameData.config.get("newGame", {})
	player = {
		"level": 1,
		"xp": 0,
		"coins": int(cfg.get("coins", 0)),
		"farmPoints": 0,
		"reputation": {},
		"unlocked": [],
		"stats": {"ordersCompleted": 0, "timesProduced": {}},
		"mergePity": {},
		"mergeMastery": {},
	}
	buildings.clear()
	for id: String in cfg.get("buildings", []):
		buildings[id] = 1
	rng.clear()
	var seeder := RngStream.new(seed_value)
	for stream_name: String in RNG_STREAMS:
		rng[stream_name] = RngStream.new(seeder.next_u32())
	Sim.game_minute = float(GameData.config.get("time", {}).get("newGameHour", 0)) * Sim.MINUTES_PER_HOUR
	changed.emit()


func stream(stream_name: String) -> RngStream:
	return rng[stream_name]


# ---- coins
func coins() -> int:
	return player["coins"]


func add_coins(n: int) -> void:
	player["coins"] += n
	changed.emit()


func spend_coins(n: int) -> bool:
	if player["coins"] < n:
		return false
	player["coins"] -= n
	changed.emit()
	return true


# ---- XP and level (section 10, formula 4)
func xp_to_next(level: int) -> int:
	var c: Dictionary = GameData.config["economy"]["levelCurve"]
	return int(c["scale"]) * roundi(float(c["factor"]) * pow(level, float(c["exponent"])))


func max_level() -> int:
	return int(GameData.config["economy"]["levelCurve"]["maxLevel"])


func add_xp(n: int) -> void:
	if n <= 0:
		return
	player["xp"] += n
	while player["level"] < max_level() and player["xp"] >= xp_to_next(player["level"]):
		player["xp"] -= xp_to_next(player["level"])
		player["level"] += 1
		leveled_up.emit(player["level"])
		notice.emit("Level %d!" % player["level"])
	changed.emit()


# ---- reputation (section 8)
func reputation(npc_id: String) -> int:
	return player["reputation"].get(npc_id, 0)


func add_reputation(npc_id: String, n: int) -> void:
	player["reputation"][npc_id] = reputation(npc_id) + n      # reputation never decreases
	changed.emit()


func reputation_level(npc_id: String) -> int:
	var level := 0
	for threshold: Variant in GameData.def("npcs", npc_id)["reputationThresholds"]:
		if reputation(npc_id) >= int(threshold):
			level += 1
	return level


# ---- unlocks and buildings
func unlock(id: String) -> void:
	if not player["unlocked"].has(id):
		player["unlocked"].append(id)
		changed.emit()


func is_unlocked(id: String) -> bool:
	return player["unlocked"].has(id)


func building_level(id: String) -> int:
	return buildings.get(id, 0)


func count_produced(item_id: String, qty: int) -> void:
	var produced: Dictionary = player["stats"]["timesProduced"]
	produced[item_id] = produced.get(item_id, 0) + qty


# ---- save section "player"
func save_state() -> Dictionary:
	return player.duplicate(true)


func load_state(data: Dictionary) -> void:
	player = SaveGame.whole_numbers(data)      # JSON numbers arrive as floats; every player number is a count
	changed.emit()


func rng_state() -> Dictionary:
	var out := {}
	for stream_name: String in rng:
		out[stream_name] = rng[stream_name].state
	return out


func load_rng_state(data: Dictionary) -> void:
	for stream_name: String in RNG_STREAMS:
		rng[stream_name] = RngStream.new(int(data.get(stream_name, 0)))
