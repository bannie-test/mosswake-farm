extends Node
## Player settings (M5: settings and accessibility). Autoload: Settings.
## Stored in user://settings.json, apart from the save, so they survive a new farm.

signal changed

const PATH := "user://settings.json"
const DEFAULTS := {"music": 0.6, "sfx": 0.8, "largeText": false, "holdToAct": true, "fullscreen": false, "playtestLog": true}

var values: Dictionary = DEFAULTS.duplicate()


func _ready() -> void:
	for bus: String in ["Music", "Sfx"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var text := FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else ""
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if typeof(parsed) == TYPE_DICTIONARY:
		for key: String in DEFAULTS:
			if parsed.has(key) and typeof(parsed[key]) == typeof(DEFAULTS[key]):
				values[key] = parsed[key]
	apply()


func get_value(key: String) -> Variant:
	return values[key]


func set_value(key: String, value: Variant, persist: bool = true) -> void:
	values[key] = value
	apply()
	if persist:
		var f := FileAccess.open(PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(values))
			f.close()
	changed.emit()


func apply() -> void:
	for pair: Array in [["Music", "music"], ["Sfx", "sfx"]]:
		var bus := AudioServer.get_bus_index(pair[0])
		var v: float = values[pair[1]]
		AudioServer.set_bus_mute(bus, v <= 0.001)
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.001)))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
