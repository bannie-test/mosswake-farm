class_name FarmMap
extends Node2D
## The MVP farm map (GDD section 15: one farm map of 48x36 tiles, NPC stalls at the farm gate).
## Hand-built: the layout below is authored content, not balance data.

const SIZE := Vector2i(48, 36)
const BACKDROP_ROWS := 3
## Field sites, 3x2 plots each. The first `newGame.fields` are owned at the start.
const FIELD_SITES: Array[Rect2i] = [
	Rect2i(9, 13, 3, 2), Rect2i(13, 13, 3, 2), Rect2i(17, 13, 3, 2),
	Rect2i(9, 17, 3, 2), Rect2i(13, 17, 3, 2), Rect2i(17, 17, 3, 2),
]
const PLAYER_START := Vector2(88, 180)
const PLOT_SOURCE := 0      # farm_plots.png: 0 dry, 1 wet
const FIELD_SOURCE := 1     # farm_field.png: 0 untended, 1 untilled

@onready var world: WorldLayers = $World

var player: Player
var _targets: Dictionary = {}        # tile -> target dictionary
var _plot_tiles: Dictionary = {}     # plot ID -> tile
var _plot_views: Dictionary = {}     # plot ID -> PlotView
var _cursor: Sprite2D


func build() -> void:
	_ground()
	_buildings()
	_fields()
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


func map_rect() -> Rect2i:
	return Rect2i(0, 0, SIZE.x * WorldLayers.TILE, SIZE.y * WorldLayers.TILE)


func target_at(tile: Vector2i) -> Dictionary:
	return _targets.get(tile, {})


func plot_tile(plot_id: String) -> Vector2i:
	return _plot_tiles[plot_id]


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


func _buildings() -> void:
	# farmhouse: the base is Y-sorted, the roof sits on the Overhead layer
	var house_feet := Vector2(96, 160)
	world.add_object(WorldLayers.upright(load("res://assets/buildings/farmhouse_base.png")), house_feet)
	var roof := WorldLayers.upright(load("res://assets/buildings/farmhouse_roof.png"))
	roof.position = house_feet
	world.overhead.add_child(roof)
	_solid(Rect2(54, 100, 84, 58))
	# well
	world.add_object(WorldLayers.upright(load("res://assets/buildings/bld_well.png")), Vector2(368, 224))
	_solid(Rect2(355, 206, 26, 18))
	# Merge Table (pre-built in M1, see the M1 spec section 6)
	if GameState.building_level("bld_merge_table") > 0:
		world.add_object(WorldLayers.upright(load("res://assets/buildings/bld_merge_table.png")), Vector2(432, 224))
		_solid(Rect2(419, 208, 26, 16))
		for tile: Vector2i in [Vector2i(26, 12), Vector2i(27, 12), Vector2i(26, 13), Vector2i(27, 13)]:
			_targets[tile] = {"kind": "merge_table"}
	# Mara's stall and the order board at the farm gate
	world.add_object(WorldLayers.animated("res://assets/characters/npc_mara.png", "idle_s"), Vector2(664, 312))
	world.add_object(WorldLayers.upright(load("res://assets/buildings/npc_stall.png")), Vector2(664, 320))
	_solid(Rect2(642, 296, 44, 24))
	world.add_object(WorldLayers.upright(load("res://assets/props/order_board.png")), Vector2(616, 320))
	_solid(Rect2(610, 312, 12, 8))
	for tile: Vector2i in [Vector2i(38, 19), Vector2i(38, 18), Vector2i(40, 19), Vector2i(41, 19), Vector2i(42, 19)]:
		_targets[tile] = {"kind": "order_board", "npcId": "npc_mara"}
	for pos: Vector2 in [Vector2(176, 150), Vector2(30, 172), Vector2(330, 150), Vector2(480, 300), Vector2(560, 180), Vector2(250, 420), Vector2(700, 440)]:
		world.add_object(WorldLayers.upright(load("res://assets/props/bush.png")), pos)


func _fields() -> void:
	var owned := int(GameData.config["newGame"]["fields"])
	for i: int in range(FIELD_SITES.size()):
		var site := FIELD_SITES[i]
		var n := 0
		for y: int in range(site.position.y, site.end.y):
			for x: int in range(site.position.x, site.end.x):
				var tile := Vector2i(x, y)
				world.ground_detail.erase_cell(tile)
				if i < owned:
					var plot_id := "field_%02d/%d" % [i + 1, n]
					Farm.add_plot(plot_id)
					_plot_tiles[plot_id] = tile
					_targets[tile] = {"kind": "plot", "id": plot_id}
					var view := PlotView.new(plot_id)
					_plot_views[plot_id] = view
					world.add_object(view, WorldLayers.feet(tile))
					_on_plot_changed(plot_id)
				else:
					world.plots.set_cell(tile, FIELD_SOURCE, Vector2i(0, 0))
					_targets[tile] = {"kind": "locked_field"}
				n += 1
		if i >= owned:
			world.add_object(WorldLayers.upright(load("res://assets/props/field_sign.png")),
				WorldLayers.feet(Vector2i(site.position.x + 1, site.position.y - 1)))


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


func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.position = rect.position + rect.size / 2.0
	body.add_child(shape)
	add_child(body)


# ------------------------------------------------------------------ live updates
func _on_plot_changed(plot_id: String) -> void:
	if not _plot_tiles.has(plot_id):
		return
	var p: Dictionary = Farm.plot(plot_id)
	var tile: Vector2i = _plot_tiles[plot_id]
	if p["state"] == "empty":
		world.plots.set_cell(tile, FIELD_SOURCE, Vector2i(1, 0))
	else:
		world.plots.set_cell(tile, PLOT_SOURCE, Vector2i(1 if p["moisture"] > 0.0 else 0, 0))   # dry soil is lighter
	_plot_views[plot_id].refresh()


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
