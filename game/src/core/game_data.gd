extends Node
## Read-only registries of the static definitions in res://data (GDD section 14).
## Autoload name: GameData. Code never holds balance numbers; it asks this node.

const TABLES := {
	"items": "items.json",
	"plants": "plants.json",
	"animals": "animals.json",
	"genes": "genes.json",
	"traits": "traits.json",
	"merge_recipes": "merge_recipes.json",
	"craft_recipes": "craft_recipes.json",
	"blueprints": "blueprints.json",
	"breeding_rules": "breeding_rules.json",
	"quests": "quests.json",
	"npcs": "npcs.json",
	"spirits": "spirits.json",
	"spirit_jobs": "spirit_jobs.json",
	"buildings": "buildings.json",
	"dig_sites": "dig_sites.json",
	"tools": "tools.json",
	"resource_nodes": "resource_nodes.json",
	"gates": "gates.json",
	"weather": "weather.json",
}

var tables: Dictionary = {}       # table name -> { id -> definition }
var config: Dictionary = {}
var merge_config: Dictionary = {}
var retired_ids: Array = []
var data_version: String = ""
var strings: Dictionary = {}
var fishing: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	tables.clear()
	for table: String in TABLES:
		var rows: Array = _read(TABLES[table])
		var index: Dictionary = {}
		for row: Dictionary in rows:
			index[row["id"]] = row
		tables[table] = index
	config = _read("config.json")
	merge_config = _read("merge_config.json")["mergeConfig"]
	retired_ids = _read("retired_ids.json")["retired"]
	data_version = config["dataVersion"]
	strings = _read("strings_en.json")
	fishing = _read("fishing.json")["fishing"]


func _read(file: String) -> Variant:
	var path := "res://data/" + file
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("GameData: cannot read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("GameData: %s is not valid JSON" % path)
		return {}
	return parsed


## The definition with this ID. A missing ID is a data bug and is reported loudly.
func def(table: String, id: String) -> Dictionary:
	var index: Dictionary = tables.get(table, {})
	if not index.has(id):
		push_error("GameData: no '%s' in table '%s'" % [id, table])
		return {}
	return index[id]


func has_def(table: String, id: String) -> bool:
	return tables.get(table, {}).has(id)


func item(id: String) -> Dictionary:
	return def("items", id)


func plant(id: String) -> Dictionary:
	return def("plants", id)


func ids(table: String) -> Array:
	return tables.get(table, {}).keys()


## Display text for a string-table key (the UI/UX string table of section 18).
func text(key: String) -> String:
	return strings.get(key, key)
