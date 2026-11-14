extends Node
## Save and load (GDD section 14, "Save, load and versioning"). Autoload name: SaveGame.
##  - one gzip-compressed JSON file per slot, written to a temporary file and renamed
##  - three rotating backups per slot
##  - saveVersion is an integer; MIGRATIONS[n] turns version n+1 into n+2 and they run in order
##  - only game time is stored, never wall-clock time

const SAVE_VERSION := 1
const BACKUPS := 3
const SAVE_DIR := "user://saves"

## Ordered migrations. Entry 0 migrates saveVersion 1 -> 2, entry 1 migrates 2 -> 3, and so on.
## Each is a Callable taking and returning the envelope Dictionary.
var migrations: Array[Callable] = []

var _sections: Dictionary = {}     # name -> object with save_state() / load_state(data)


func register_section(section: String, owner_: Object) -> void:
	assert(owner_.has_method("save_state") and owner_.has_method("load_state"))
	_sections[section] = owner_


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func build_envelope() -> Dictionary:
	var env := {
		"saveVersion": SAVE_VERSION,
		"dataVersion": GameData.data_version,
		"gameMinute": Sim.game_minute,
		"rng": GameState.rng_state(),
	}
	for section: String in _sections:
		env[section] = _sections[section].save_state()
	return env


func apply_envelope(env: Dictionary) -> void:
	Sim.game_minute = float(env["gameMinute"])
	GameState.load_rng_state(env["rng"])
	for section: String in _sections:
		if env.has(section):
			_sections[section].load_state(env[section])


func save(slot: int) -> Error:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var file := FileAccess.open_compressed(tmp, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(build_envelope()))
	file.close()
	_rotate_backups(path)
	return DirAccess.rename_absolute(tmp, path)   # a crash before this line leaves the old save intact


func _rotate_backups(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	for n: int in range(BACKUPS, 1, -1):
		var older := "%s.bak%d" % [path, n - 1]
		if FileAccess.file_exists(older):
			DirAccess.rename_absolute(older, "%s.bak%d" % [path, n])
	DirAccess.copy_absolute(path, path + ".bak1")


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Read a slot, migrate it to the current version and apply it. Returns OK or an Error.
func load_slot(slot: int) -> Error:
	var env: Variant = read_envelope(slot_path(slot))
	if env == null:
		return ERR_FILE_CORRUPT
	apply_envelope(env)
	return OK


func read_envelope(path: String) -> Variant:
	var file := FileAccess.open_compressed(path, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return migrate(parsed)


func migrate(env: Dictionary) -> Variant:
	var version := int(env.get("saveVersion", 0))
	if version < 1 or version > SAVE_VERSION:
		push_error("SaveGame: cannot load saveVersion %d (this build reads 1..%d)" % [version, SAVE_VERSION])
		return null
	while version < SAVE_VERSION:
		env = migrations[version - 1].call(env)
		version += 1
		env["saveVersion"] = version
	return env


## A deep copy in which every float is turned back into an int. JSON has one number type, so
## sections that hold only counts (coins, levels, reputation) call this when loading.
static func whole_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value)
		TYPE_DICTIONARY:
			var out := {}
			for key: Variant in value:
				out[key] = whole_numbers(value[key])
			return out
		TYPE_ARRAY:
			return (value as Array).map(whole_numbers)
	return value


## A deep copy in which floats that hold whole numbers become ints (for readable exported JSON).
static func whole_numbers_where_whole(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			return int(value) if value == floorf(value) else value
		TYPE_DICTIONARY:
			var out := {}
			for key: Variant in value:
				out[key] = whole_numbers_where_whole(value[key])
			return out
		TYPE_ARRAY:
			return (value as Array).map(whole_numbers_where_whole)
	return value
