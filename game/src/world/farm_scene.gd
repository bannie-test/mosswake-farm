extends Node2D
## The game scene: resumes the saved farm or starts a new one, builds the map, wires the camera
## and the UI, and saves on quit.
## Dev arguments (after `--`): --new, --seed=N, --nosave, --shot=<png>, --demo=<name>.

@onready var map: FarmMap = $Map
@onready var camera: PixelCamera = $Camera
@onready var ui: UiRoot = $Ui

var _args := {}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	var seed_value := int(_args.get("seed", str(int(Time.get_unix_time_from_system()))))
	var dev: bool = _args.has("demo") or _args.has("shot") or _args.has("nosave")
	var loaded := false
	if has_meta("force_continue"):
		loaded = Session.continue_or_new(seed_value)
	elif _args.has("new") or dev:
		Session.new_game(seed_value)
	else:
		loaded = Session.continue_or_new(seed_value)
	Session.autosave_enabled = not dev
	get_tree().auto_accept_quit = false
	map.build()
	camera.target = map.player
	camera.set_map_rect(map.map_rect())
	ui.bind(map.player)
	ui.restart_requested.connect(_restart)
	if loaded:
		GameState.notice.emit("Welcome back")
	if _args.has("demo"):
		_demo(_args["demo"])
	if _args.has("shot"):
		_shoot(_args["shot"])


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Session.autosave()
		get_tree().quit()


func _restart() -> void:
	Session.new_game(int(Time.get_unix_time_from_system()))
	SaveGame.save(Session.slot)
	get_tree().reload_current_scene()


## Puts the game into a state worth a screenshot. Development aid only.
func _demo(what: String) -> void:
	Sim.paused = true
	GameState.player["level"] = 6
	GameState.player["coins"] = 1500
	GameState.add_reputation("npc_tobin", 120)
	GameState.add_reputation("npc_mara", 64)
	Quests.active.clear()
	for quest_id: String in ["quest_first_harvest", "quest_table_for_two", "quest_strange_carrot"]:
		Quests.completed.append(quest_id)
		for id: String in Quests.def(quest_id)["rewards"]["unlocks"]:
			GameState.unlock(id)
	for id: String in ["bld_merge_table", "bld_barn", "bld_research_station", "bld_chest"]:
		GameState.buildings[id] = 1
	Research.state["researchedOnce"] = ["merged_carrot_golden"]
	Inventory.add("gene_carrot", 7)
	Inventory.add("merged_carrot_golden", 2)
	Inventory.add("merged_tomato_premium", 1)
	Farm.buy_field()
	GameState.leveled_up.emit(6)
	Animals._spawn("animal_chicken", "adult")
	for i: int in range(2):
		Animals._spawn("animal_cow", "adult")
	Animals._spawn("animal_sheep", "juvenile")
	for a: Dictionary in Animals.animals:
		a["productionProgress"] = 1.0 if a["instanceId"] in ["an_0001", "an_0004"] else 0.45
		a["happiness"] = 82.0
	var stages := [30.0, 100.0, 170.0, 250.0, 330.0, 400.0]
	var plants := ["plant_carrot", "plant_wheat", "plant_tomato", "plant_sunflower"]
	var n := 0
	for plot_id: String in Farm.plots:
		Farm.till(plot_id)
		var plant_id: String = plants[(n / 6) % plants.size()]
		Inventory.add(GameData.plant(plant_id)["seedItemId"], 1)
		Farm.plant(plot_id, plant_id)
		if n % 5 != 4:
			Farm.water(plot_id)
		Farm.plot(plot_id)["growthMinutes"] = minf(stages[n % 6] * float(GameData.plant(plant_id)["growthHours"]) / 6.0, float(GameData.plant(plant_id)["growthHours"]) * 60.0 - 1.0)
		n += 1
	Sim.advance(1.0)
	for id: String in ["crop_carrot", "crop_wheat", "crop_tomato", "prod_egg", "prod_milk", "merged_carrot_premium", "merged_egg_speckled"]:
		Inventory.add(id, 9)
	Inventory.add("lucky_clover", 2)
	Inventory.add("crop_sunflower", 4)
	Quests.refresh()
	Orders.orders.clear()
	Orders.fill_slots()
	map.refresh_all()
	for plot_id: String in Farm.plots:
		Farm.plot_changed.emit(plot_id)
	map.player.position = Vector2(300, 250)
	match what:
		"merge":
			ui.open("merge_table")
			ui._screens["merge_table"]._selected = "merge_carrot_golden"
			ui._screens["merge_table"]._charm = "lucky_clover"
			ui._screens["merge_table"].refresh(true)
		"orders":
			map.player.position = Vector2(616, 344)
			ui.open("order_board")
		"shop":
			map.player.position = Vector2(700, 344)
			ui.open("shop", {"npcId": "npc_tobin"})
		"housing":
			ui.open("housing", {"buildingId": "bld_barn"})
		"bin":
			ui.open("bin")
		"research":
			Research.start("merged_carrot_premium")
			ui.open("research")
		"gate":
			map.player.position = Vector2(600, 350)


func _shoot(path: String) -> void:
	for i: int in range(8):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
