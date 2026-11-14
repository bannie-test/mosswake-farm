extends Node2D
## The Art Bible style-sheet scene (Appendix A, "Asset consistency pipeline"): one 640x360
## screen holding the farmhouse corner, six plots with every carrot stage, the player, a
## chicken and a Rootling. It is the working definition of the style; new assets are approved
## by viewing them here next to approved ones.
##
## Run with `-- --shot=<path>` to save a 640x360 screenshot and quit.

const CROP_FRAME := Vector2i(16, 32)

@onready var world: WorldLayers = $World
@onready var clock: Label = $Hud/Clock


func _ready() -> void:
	_build()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shoot(arg.trim_prefix("--shot="))


func _process(_delta: float) -> void:
	clock.text = Sim.clock_text()


func _build() -> void:
	var rng := RngStream.new(7)
	# backdrop: sky, far hills and forest line at the top edge of the map
	var hills := Sprite2D.new()
	hills.texture = load("res://assets/tiles/backdrop_hills.png")
	hills.centered = false
	world.backdrop.add_child(hills)
	# ground: grass with three centre variants, a dirt path across the screen
	for y: int in range(3, 23):
		for x: int in range(0, 40):
			world.ground.set_cell(Vector2i(x, y), 0, Vector2i(rng.randi_range(0, 2), 0))
	for x: int in range(0, 40):
		world.ground.set_cell(Vector2i(x, 13), 0, Vector2i(6, 0))
		world.ground.set_cell(Vector2i(x, 14), 0, Vector2i(3 + rng.randi_range(0, 2), 0))
		world.ground.set_cell(Vector2i(x, 15), 0, Vector2i(7, 0))
	for i: int in range(46):
		var cell := Vector2i(rng.randi_range(0, 39), rng.randi_range(4, 22))
		if cell.y < 13 or cell.y > 15:
			world.ground_detail.set_cell(cell, 0, Vector2i(rng.randi_range(0, 3), 0))
	# farmhouse corner: base is Y-sorted, the roof sits on the Overhead layer
	var base := WorldLayers.upright(load("res://assets/buildings/farmhouse_base.png"))
	world.add_object(base, Vector2(72, 192))
	var roof := WorldLayers.upright(load("res://assets/buildings/farmhouse_roof.png"))
	roof.position = Vector2(72, 192)
	world.overhead.add_child(roof)
	for x: int in range(9, 14):
		world.add_object(WorldLayers.upright(load("res://assets/props/fence_h.png")), WorldLayers.feet(Vector2i(x, 11)))
	world.add_object(WorldLayers.upright(load("res://assets/props/bush.png")), Vector2(140, 150))
	world.add_object(WorldLayers.upright(load("res://assets/props/bush.png")), Vector2(20, 205))
	# six plots with all carrot stages on dry soil; six wheat plots on wet soil below them
	for i: int in range(6):
		var dry := Vector2i(16 + i * 2, 8)
		var wet := Vector2i(16 + i * 2, 11)
		world.plots.set_cell(dry, 0, Vector2i(0, 0))
		world.plots.set_cell(wet, 0, Vector2i(1, 0))
		world.ground_detail.erase_cell(dry)
		world.ground_detail.erase_cell(wet)
		world.add_object(WorldLayers.upright(SpriteSheet.frame("res://assets/crops/plant_carrot.png", i, CROP_FRAME)), WorldLayers.feet(dry))
		world.add_object(WorldLayers.upright(SpriteSheet.frame("res://assets/crops/plant_wheat.png", i, CROP_FRAME)), WorldLayers.feet(wet))
	# a small planted field, to judge how plots read when the farm is crowded
	for y: int in range(17, 21):
		for x: int in range(22, 34):
			var cell := Vector2i(x, y)
			world.plots.set_cell(cell, 0, Vector2i((x + y) % 2, 0))
			world.ground_detail.erase_cell(cell)
			var sheet := "res://assets/crops/plant_carrot.png" if y < 19 else "res://assets/crops/plant_wheat.png"
			world.add_object(WorldLayers.upright(SpriteSheet.frame(sheet, 1 + (x * 3 + y) % 4, CROP_FRAME)), WorldLayers.feet(cell))
	var sparkle := WorldLayers.animated("res://assets/fx/mature_sparkle.png", "sparkle")
	world.add_object(sparkle, WorldLayers.feet(Vector2i(24, 8)) + Vector2(0, -8))
	# the player (three facings), a chicken and a Rootling
	world.add_object(WorldLayers.animated("res://assets/characters/player.png", "idle_s"), Vector2(200, 232), true)
	world.add_object(WorldLayers.animated("res://assets/characters/player.png", "walk_e"), Vector2(236, 232), true)
	world.add_object(WorldLayers.animated("res://assets/characters/player.png", "idle_n"), Vector2(272, 232), true)
	world.add_object(WorldLayers.animated("res://assets/animals/animal_chicken.png", "idle_e"), Vector2(150, 226), true)
	world.add_object(WorldLayers.animated("res://assets/animals/animal_chicken.png", "idle_e"), Vector2(118, 240), true)
	world.add_object(WorldLayers.animated("res://assets/spirits/spirit_rootling.png", "idle_s"), Vector2(318, 300), true)


func _shoot(path: String) -> void:
	for i: int in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
