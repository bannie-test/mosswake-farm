class_name FarmMap
extends Node2D
## The MVP farm map (GDD section 15: one farm map of 48x36 tiles, NPC stalls at the farm gate).
## Hand-built: the layout below is authored content, not balance data.

const SIZE := Vector2i(48, 36)
const BACKDROP_ROWS := 3
## Field sites, 3x2 plots each, in the order they are bought.
const FIELD_SITES: Array[Rect2i] = [
	Rect2i(9, 13, 3, 2), Rect2i(13, 13, 3, 2), Rect2i(17, 13, 3, 2),
	Rect2i(9, 17, 3, 2), Rect2i(13, 17, 3, 2), Rect2i(17, 17, 3, 2),
]
## Building pads: footprint in tiles, sprite, and what the act key opens once built.
const PADS := {
	"bld_coop": {"tiles": Rect2i(15, 7, 3, 3), "sprite": "res://assets/buildings/bld_coop.png", "kind": "housing", "yard": Rect2(236, 166, 60, 22)},
	"bld_barn": {"tiles": Rect2i(21, 6, 4, 4), "sprite": "res://assets/buildings/bld_barn.png", "kind": "housing", "yard": Rect2(330, 166, 76, 24)},
	"bld_merge_table": {"tiles": Rect2i(26, 12, 2, 2), "sprite": "res://assets/buildings/bld_merge_table.png", "kind": "merge_table"},
	"bld_well": {"tiles": Rect2i(29, 16, 2, 2), "sprite": "res://assets/buildings/bld_well.png", "kind": ""},
	"bld_research_station": {"tiles": Rect2i(27, 6, 4, 4), "sprite": "res://assets/buildings/bld_research_station.png", "kind": "research"},
	"bld_chest": {"tiles": Rect2i(11, 10, 1, 1), "sprite": "res://assets/props/chest.png", "kind": "chest"},
	"bld_shipping_bin": {"tiles": Rect2i(9, 10, 1, 1), "sprite": "res://assets/props/shipping_bin.png", "kind": "bin"},
}
const STALLS := {
	"npc_mara": {"feet": Vector2(664, 320), "sprite": "res://assets/buildings/npc_stall.png", "kind": "order_board"},
	"npc_tobin": {"feet": Vector2(728, 320), "sprite": "res://assets/buildings/npc_cart_tobin.png", "kind": "shop"},
	"npc_ilse": {"feet": Vector2(664, 432), "sprite": "res://assets/buildings/npc_stall_ilse.png", "kind": "order_board"},
}
const PLAYER_START := Vector2(88, 180)
const PLOT_SOURCE := 0      # farm_plots.png: 0 dry, 1 wet
const FIELD_SOURCE := 1     # farm_field.png: 0 untended, 1 untilled
const PAD_SOURCE := 2       # build_pad.png

@onready var world: WorldLayers = $World

var player: Player
var _targets: Dictionary = {}        # tile -> target dictionary
var _plot_tiles: Dictionary = {}     # plot ID -> tile
var _plot_views: Dictionary = {}     # plot ID -> PlotView
var _field_signs: Dictionary = {}    # field index -> sign node
var _building_nodes: Dictionary = {} # building ID -> Array of nodes
var _stall_nodes: Dictionary = {}    # npc ID -> true once drawn
var _animal_nodes: Array = []
var _ready_marks: Dictionary = {}
var _cursor: Sprite2D


func build() -> void:
	world.plots.tile_set = SpriteSheet.tileset_multi([WorldLayers.PLOT_SHEET, WorldLayers.FIELD_SHEET, "res://assets/tiles/build_pad.png"])
	_ground()
	_farmhouse()
	for building_id: String in PADS:
		_refresh_building(building_id)
	_refresh_stalls()
	for i: int in range(FIELD_SITES.size()):
		_refresh_field(i)
	_borders()
	_cursor = Sprite2D.new()
	_cursor.texture = load("res://assets/fx/tile_cursor.png")
	_cursor.centered = false
	_cursor.z_index = -7
	_cursor.visible = false
	add_child(_cursor)
	player = Player.new()
	player.map = self
	world.add_object(player, PLAYER_START)
	player.target_changed.connect(_move_cursor)
	Farm.plot_changed.connect(_on_plot_changed)
	Farm.harvested.connect(_on_harvested)
	Farm.field_bought.connect(func(n: int) -> void: _refresh_field(n - 1))
	GameState.building_changed.connect(_refresh_building)
	GameState.leveled_up.connect(func(_level: int) -> void: _refresh_stalls())
	Animals.changed.connect(_refresh_animals)
	Quests.quest_completed.connect(func(_q: String) -> void:
		for building_id: String in PADS:
			if GameState.building_level(building_id) == 0:
				_refresh_building(building_id))
	_refresh_animals()


func map_rect() -> Rect2i:
	return Rect2i(0, 0, SIZE.x * WorldLayers.TILE, SIZE.y * WorldLayers.TILE)


func target_at(tile: Vector2i) -> Dictionary:
	return _targets.get(tile, {})


func plot_tile(plot_id: String) -> Vector2i:
	return _plot_tiles[plot_id]


## A tile to stand on in front of a building, facing north at it (used by tests and guides).
func approach_tile(building_id: String) -> Vector2i:
	var r: Rect2i = PADS[building_id]["tiles"]
	return Vector2i(r.position.x + r.size.x / 2, r.end.y)


# ------------------------------------------------------------------ building the map
func _ground() -> void:
	var rng := RngStream.new(20261114)
	for x: int in [0, 640]:
		var hills := Sprite2D.new()
		hills.texture = load("res://assets/tiles/backdrop_hills.png")
		hills.centered = false
		hills.position = Vector2(x, 0)
		world.backdrop.add_child(hills)
	for y: int in range(BACKDROP_ROWS, SIZE.y):
		for x: int in range(SIZE.x):
			world.ground.set_cell(Vector2i(x, y), 0, Vector2i(rng.randi_range(0, 2), 0))
	# the lane from the gate, and the path from the farmhouse door down to it
	for x: int in range(SIZE.x):
		world.ground.set_cell(Vector2i(x, 20), 0, Vector2i(6, 0))
		world.ground.set_cell(Vector2i(x, 21), 0, Vector2i(3 + rng.randi_range(0, 2), 0))
		world.ground.set_cell(Vector2i(x, 22), 0, Vector2i(3 + rng.randi_range(0, 2), 0))
		world.ground.set_cell(Vector2i(x, 23), 0, Vector2i(7, 0))
	for y: int in range(10, 21):
		for x: int in [5, 6]:
			world.ground.set_cell(Vector2i(x, y), 0, Vector2i(3 + rng.randi_range(0, 2), 0))
	for i: int in range(150):
		var cell := Vector2i(rng.randi_range(0, SIZE.x - 1), rng.randi_range(BACKDROP_ROWS + 1, SIZE.y - 1))
		if world.ground.get_cell_atlas_coords(cell).x <= 2:
			world.ground_detail.set_cell(cell, 0, Vector2i(rng.randi_range(0, 3), 0))
	for pos: Vector2 in [Vector2(176, 150), Vector2(30, 172), Vector2(480, 300), Vector2(560, 180), Vector2(250, 420), Vector2(500, 470), Vector2(120, 500)]:
		world.add_object(WorldLayers.upright(load("res://assets/props/bush.png")), pos)


func _farmhouse() -> void:
	var house_feet := Vector2(96, 160)
	world.add_object(WorldLayers.upright(load("res://assets/buildings/farmhouse_base.png")), house_feet)
	var roof := WorldLayers.upright(load("res://assets/buildings/farmhouse_roof.png"))
	roof.position = house_feet
	world.overhead.add_child(roof)
	_solid(Rect2(54, 100, 84, 58))
	for tile: Vector2i in [Vector2i(5, 9), Vector2i(6, 9)]:      # the door: sleep and save
		_targets[tile] = {"kind": "bed"}


func _pad_tiles(rect: Rect2i) -> Array:
	var out: Array = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			out.append(Vector2i(x, y))
	return out


## Draws a building, or its empty pad with a sign while it is not built.
func _refresh_building(building_id: String) -> void:
	if not PADS.has(building_id):
		return
	for node: Node in _building_nodes.get(building_id, []):
		node.queue_free()
	var nodes: Array = []
	var pad: Dictionary = PADS[building_id]
	var rect: Rect2i = pad["tiles"]
	var feet := Vector2((rect.position.x + rect.size.x / 2.0) * WorldLayers.TILE, rect.end.y * WorldLayers.TILE)
	var built := GameState.building_level(building_id) > 0
	for tile: Vector2i in _pad_tiles(rect):
		world.ground_detail.erase_cell(tile)
		if built:
			world.plots.erase_cell(tile)
			if pad["kind"] != "":
				_targets[tile] = {"kind": pad["kind"], "buildingId": building_id}
			else:
				_targets.erase(tile)
		else:
			world.plots.set_cell(tile, PAD_SOURCE, Vector2i(0, 0))
			_targets[tile] = {"kind": "build_pad", "buildingId": building_id}
	if built and building_id == "bld_chest":
		Inventory.ensure_chest(ChestScreen.CHEST, int(GameData.def("buildings", building_id)["levels"][0]["effects"]["slots"]))
	if not built and not Unlocks.is_met(GameData.def("buildings", building_id)["unlock"]) and GameData.def("buildings", building_id)["unlock"].has("quest"):
		for tile: Vector2i in _pad_tiles(rect):       # a story reveals this pad; until then it is plain grass
			world.plots.erase_cell(tile)
			_targets.erase(tile)
		_building_nodes[building_id] = nodes
		return
	if built:
		var tex: Texture2D = load(pad["sprite"])
		nodes.append(world.add_object(WorldLayers.upright(tex), feet))
		var depth := minf(tex.get_height() * 0.45, rect.size.y * WorldLayers.TILE - 4.0)
		nodes.append(_solid(Rect2(feet.x - tex.get_width() / 2.0 + 3, feet.y - depth, tex.get_width() - 6, depth - 1)))
		if pad["kind"] == "housing":
			var mark := WorldLayers.animated("res://assets/fx/ready_mark.png", "sparkle")
			mark.position = feet + Vector2(0, -tex.get_height() - 2)
			mark.z_index = 12
			mark.visible = false
			add_child(mark)
			nodes.append(mark)
			_ready_marks[building_id] = mark
	else:
		nodes.append(world.add_object(WorldLayers.upright(load("res://assets/props/field_sign.png")), WorldLayers.feet(Vector2i(rect.position.x, rect.position.y))))
	_building_nodes[building_id] = nodes
	_refresh_animals()


func _refresh_stalls() -> void:
	for npc_id: String in STALLS:
		if _stall_nodes.has(npc_id) or not Unlocks.npc_met(npc_id):
			continue
		_stall_nodes[npc_id] = true
		var stall: Dictionary = STALLS[npc_id]
		var feet: Vector2 = stall["feet"]
		world.add_object(WorldLayers.animated("res://assets/characters/%s.png" % npc_id, "idle_s"), feet + Vector2(0, -8))
		world.add_object(WorldLayers.upright(load(stall["sprite"])), feet)
		_solid(Rect2(feet.x - 22, feet.y - 24, 44, 24))
		var row := int(feet.y / WorldLayers.TILE) - 1
		for x: int in range(int(feet.x / WorldLayers.TILE) - 1, int(feet.x / WorldLayers.TILE) + 2):
			_targets[Vector2i(x, row)] = {"kind": stall["kind"], "npcId": npc_id}
	if not _stall_nodes.has("board"):
		_stall_nodes["board"] = true
		world.add_object(WorldLayers.upright(load("res://assets/props/order_board.png")), Vector2(616, 320))
		_solid(Rect2(610, 312, 12, 8))
		for tile: Vector2i in [Vector2i(38, 19), Vector2i(38, 18)]:
			_targets[tile] = {"kind": "order_board"}


func _refresh_field(index: int) -> void:
	var site := FIELD_SITES[index]
	var owned := index < Farm.fields_owned
	var n := 0
	for tile: Vector2i in _pad_tiles(site):
		world.ground_detail.erase_cell(tile)
		if owned:
			var plot_id := "field_%02d/%d" % [index + 1, n]
			_plot_tiles[plot_id] = tile
			_targets[tile] = {"kind": "plot", "id": plot_id}
			if not _plot_views.has(plot_id):
				var view := PlotView.new(plot_id)
				_plot_views[plot_id] = view
				world.add_object(view, WorldLayers.feet(tile))
			_on_plot_changed(plot_id)
		else:
			world.plots.set_cell(tile, FIELD_SOURCE, Vector2i(0, 0))
			_targets[tile] = {"kind": "field_sale"}
		n += 1
	if owned and _field_signs.has(index):
		_field_signs[index].queue_free()
		_field_signs.erase(index)
	elif not owned and not _field_signs.has(index):
		_field_signs[index] = world.add_object(WorldLayers.upright(load("res://assets/props/field_sign.png")),
			WorldLayers.feet(Vector2i(site.position.x + 1, site.position.y - 1)))


## One sprite per animal, standing in the yard in front of its house.
func _refresh_animals() -> void:
	for node: Node in _animal_nodes:
		node.queue_free()
	_animal_nodes.clear()
	for building_id: String in PADS:
		if not PADS[building_id].has("yard") or GameState.building_level(building_id) < 1:
			continue
		var yard: Rect2 = PADS[building_id]["yard"]
		var housed: Array = Animals.housed_in(building_id)
		for i: int in range(housed.size()):
			var a: Dictionary = housed[i]
			var sprite := WorldLayers.animated("res://assets/animals/%s.png" % a["animalId"], "idle_e")
			sprite.flip_h = i % 2 == 1
			sprite.frame = i % 4
			var cols := maxi(1, ceili(housed.size() / 2.0))
			var pos := yard.position + Vector2((i / 2 + 0.5) * yard.size.x / cols, 6 + (i % 2) * (yard.size.y - 8))
			_animal_nodes.append(world.add_object(sprite, pos.round(), true))
		if _ready_marks.has(building_id) and is_instance_valid(_ready_marks[building_id]):
			_ready_marks[building_id].visible = Animals.products_ready(building_id) > 0


func _borders() -> void:
	var w := float(SIZE.x * WorldLayers.TILE)
	var h := float(SIZE.y * WorldLayers.TILE)
	_solid(Rect2(0, 0, w, BACKDROP_ROWS * WorldLayers.TILE + 6))
	_solid(Rect2(0, h - 10, w, 16))
	_solid(Rect2(-8, 0, 10, h))
	_solid(Rect2(w - 2, 0, 10, h))
	for x: int in range(SIZE.x):
		world.add_object(WorldLayers.upright(load("res://assets/props/fence_h.png")), WorldLayers.feet(Vector2i(x, SIZE.y - 1)))
		if x < 3 or x > 8:
			world.add_object(WorldLayers.upright(load("res://assets/props/fence_h.png")), WorldLayers.feet(Vector2i(x, BACKDROP_ROWS)))


func _solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.position + rect.size / 2.0
	body.add_child(shape)
	add_child(body)
	return body


# ------------------------------------------------------------------ live updates
func _on_plot_changed(plot_id: String) -> void:
	if not _plot_tiles.has(plot_id) or not _plot_views.has(plot_id) or not Farm.plots.has(plot_id):
		return
	var p: Dictionary = Farm.plot(plot_id)
	var tile: Vector2i = _plot_tiles[plot_id]
	if p["state"] == "empty":
		world.plots.set_cell(tile, FIELD_SOURCE, Vector2i(1, 0))
	else:
		world.plots.set_cell(tile, PLOT_SOURCE, Vector2i(1 if p["moisture"] > 0.0 else 0, 0))   # dry soil is lighter
	_plot_views[plot_id].refresh()


## After a save is loaded: redraw everything that depends on state.
func refresh_all() -> void:
	for i: int in range(FIELD_SITES.size()):
		_refresh_field(i)
	for building_id: String in PADS:
		_refresh_building(building_id)
	_refresh_stalls()


## Harvest pops the goods out of the plot (section 4, "Player experience").
func _on_harvested(plot_id: String, item_id: String, qty: int) -> void:
	if not _plot_tiles.has(plot_id):
		return
	var icon := Sprite2D.new()
	icon.texture = SpriteSheet.item_icon(item_id)
	icon.position = WorldLayers.feet(_plot_tiles[plot_id]) + Vector2(0, -12)
	icon.z_index = 15
	add_child(icon)
	var tween := create_tween()
	tween.tween_property(icon, "position:y", icon.position.y - 14.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.15)
	tween.tween_callback(icon.queue_free)
	GameState.notice.emit("+%d %s" % [qty, GameData.item(item_id)["name"]])


func _move_cursor() -> void:
	var t: Dictionary = player.target
	_cursor.visible = t.get("kind", "") == "plot" and player.prompt() != ""
	if _cursor.visible:
		_cursor.position = Vector2(_plot_tiles[t["id"]] * WorldLayers.TILE)
