extends Node
## Runtime state that is not owned by a world system: player progression and the random
## streams (GDD section 14, "Save envelope and PlayerProgression"). Autoload name: GameState.

signal changed

const RNG_STREAMS := ["merge", "harvest", "orders", "breeding", "excavation"]

var player: Dictionary = {}
var rng: Dictionary = {}          # stream name -> RngStream


func _ready() -> void:
	new_game(int(Time.get_unix_time_from_system()))
	SaveGame.register_section("player", self)


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
	rng.clear()
	var seeder := RngStream.new(seed_value)
	for stream: String in RNG_STREAMS:
		rng[stream] = RngStream.new(seeder.next_u32())
	Sim.game_minute = float(GameData.config.get("time", {}).get("newGameHour", 0)) * Sim.MINUTES_PER_HOUR
	changed.emit()


func stream(name_: String) -> RngStream:
	return rng[name_]


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
