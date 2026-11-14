extends Node2D
## The game scene: starts a session, builds the farm map, wires the camera and the UI.
## Dev arguments (after `--`): --seed=N, --shot=<png>, --demo=<field|grown|backpack|merge|orders>.

@onready var map: FarmMap = $Map
@onready var camera: PixelCamera = $Camera
@onready var ui: UiRoot = $Ui


func _ready() -> void:
	var args := {}
	for arg: String in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else ""
	Session.new_game(int(args.get("seed", str(int(Time.get_unix_time_from_system())))))
	map.build()
	camera.target = map.player
	camera.set_map_rect(map.map_rect())
	ui.bind(map.player)
	if args.has("demo"):
		_demo(args["demo"])
	if args.has("shot"):
		_shoot(args["shot"])


## Puts the game into a state worth a screenshot. Development aid only.
func _demo(what: String) -> void:
	Sim.paused = true
	var stages := [30.0, 100.0, 170.0, 250.0, 330.0, 400.0]
	var n := 0
	for plot_id: String in Farm.plots:
		Farm.till(plot_id)
		if what == "field" and n >= 9:
			n += 1
			continue
		Inventory.add("seed_carrot", 1)
		Farm.plant(plot_id, "plant_carrot" if n < 6 else "plant_wheat")
		if n % 4 != 3:
			Farm.water(plot_id)
		Farm.plot(plot_id)["growthMinutes"] = stages[n % 6] if n < 6 else stages[n % 6] * 0.6
		n += 1
	Sim.advance(1.0)
	for plot_id: String in Farm.plots:
		Farm.plot_changed.emit(plot_id)
	map.player.position = Vector2(200, 260)
	if what != "field":
		Inventory.add("crop_carrot", 14)
		Inventory.add("crop_wheat", 9)
		Inventory.add("merged_carrot_premium", 4)
		GameState.add_xp(55)
		GameState.add_coins(120)
	match what:
		"backpack":
			ui.open("backpack")
		"merge":
			ui.open("merge_table")
		"merge_golden":
			ui.open("merge_table")
			ui._screens["merge_table"]._selected = "merge_carrot_golden"
			ui._screens["merge_table"].refresh(true)
		"orders":
			map.player.position = Vector2(616, 344)
			ui.open("order_board", {"npcId": "npc_mara"})


func _shoot(path: String) -> void:
	for i: int in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
