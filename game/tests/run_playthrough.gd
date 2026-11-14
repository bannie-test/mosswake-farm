extends SceneTree
## Scripted playthrough of the M1 objective through the real scene: the same player actions,
## prompts, screens and buttons a person uses. Run:
##   godot --headless --path game -s res://tests/run_playthrough.gd
## It stands in for a person only as far as "can the loop be completed by following the
## on-screen guide"; whether the loop is pleasant needs human playtests.

var _failed := 0
var _passed := 0
var farm_scene: Node
var player: Node2D      # untyped on purpose: this script compiles before the autoloads exist
var hud: Node
var ui: Node


func check(cond: bool, what: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL  " + what)


func frames(n: int) -> void:
	for i: int in range(n):
		await physics_frame


func stand(tile: Vector2i, facing: String) -> void:
	player.position = Vector2(tile.x * 16 + 8, (tile.y + 1) * 16 - 4)
	player.facing = facing
	await frames(2)


func buttons(node: Node, text: String) -> Array:
	var out: Array = []
	for child: Node in node.get_children():
		if child is Button and child.text.begins_with(text) and not child.disabled:
			out.append(child)
		out.append_array(buttons(child, text))
	return out


func _initialize() -> void:
	_run()


func _run() -> void:
	var data: Node = root.get_node("GameData")
	var sim: Node = root.get_node("Sim")
	var state: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	var farm: Node = root.get_node("Farm")
	var orders: Node = root.get_node("Orders")
	await process_frame
	farm_scene = load("res://scenes/farm.tscn").instantiate()
	root.add_child(farm_scene)
	await frames(5)
	player = farm_scene.map.player
	ui = farm_scene.ui
	hud = ui.hud
	var start_minute: float = sim.game_minute
	var coins_start: int = state.coins()
	check(farm.plots.size() == 12, "a new game owns 2 fields of 6 plots")
	check(hud.guide_text().contains("Till the soil"), "guide starts with: till and plant")

	# movement: walk down the path, stop at the fence, face the way you walk
	var y0 := player.position.y
	Input.action_press("move_down")
	await frames(30)
	Input.action_release("move_down")
	var per_second := (player.position.y - y0) / (30.0 / Engine.physics_ticks_per_second)
	check(absf(per_second - float(data.config["player"]["moveTilesPerSecond"]) * 16.0) < 4.0 and player.facing == "s", "the player walks at the data speed")
	Input.action_press("move_up")
	await frames(240)
	Input.action_release("move_up")
	check(player.position.y > 150.0, "the farmhouse wall stops the player")
	Input.action_press("move_left")
	await frames(400)
	Input.action_release("move_left")
	check(player.position.x >= 2.0 and player.facing == "w", "the map edge stops the player")

	# plant the first field with the act key only: till, plant, water
	var planted := 0
	for plot_id: String in farm.plots:
		if not plot_id.begins_with("field_01"):
			continue
		var tile: Vector2i = farm_scene.map.plot_tile(plot_id)
		await stand(tile + Vector2i(0, -1), "s")
		check(player.target.get("id", "") == plot_id, "facing a plot targets it: " + plot_id)
		var seen: Array = []
		for i: int in range(3):
			seen.append(player.prompt().get_slice(" ", 0))
			player.act()
			await frames(1)
		check(seen == ["Till", "Plant", "Water"], "the prompt reads Till, Plant, Water in turn (%s)" % str(seen))
		check(player.prompt() == "", "nothing left to do on a planted, watered plot")
		planted += 1
	check(planted == 6 and inv.count("seed_carrot") == 0, "six Carrot seeds planted")
	check(hud.guide_text().contains("Till the soil"), "guide: the second field and the Wheat seeds are still waiting")

	# the backpack opens and closes, and the player stands still while it is open
	player.opened.emit("backpack", {})
	await frames(2)
	check(ui.is_open() and not player.control_enabled, "the backpack opens and holds the player")
	ui.close()
	check(not ui.is_open() and player.control_enabled, "closing gives control back")

	# wait for the crops (time runs faster here; the game minutes are what is measured)
	sim.time_scale = 240.0
	var waited := 0
	while waited < 3000 and not farm.plot("field_01/5")["state"] == "mature":
		await frames(1)
		waited += 1
	sim.time_scale = 1.0
	check(farm.plot("field_01/0")["state"] == "mature", "the Carrots are Mature")
	check(hud.guide_text().contains("Harvest"), "guide: harvest the sparkling crops")
	for plot_id: String in farm.plots:
		if plot_id.begins_with("field_01"):
			await stand(farm_scene.map.plot_tile(plot_id) + Vector2i(0, -1), "s")
			check(player.prompt() == "Harvest", "the prompt offers Harvest")
			player.act()
	check(inv.count("crop_carrot") == 12, "12 Carrots in the backpack")
	check(hud.guide_text().contains("Deliver"), "guide: deliver at Mara's board")

	# Merge Table: walk up to it, open it with the act key, press Merge
	await stand(Vector2i(26, 14), "n")
	check(player.prompt() == "Merge Table", "the Merge Table shows its prompt")
	player.act()
	await frames(2)
	var screen: Node = ui._screens["merge_table"]
	check(screen.visible, "the act key opens the merge screen")
	var merge_buttons := buttons(screen, "Merge")
	check(merge_buttons.size() == 2 and merge_buttons[1].text == "Merge x4", "a Basic recipe offers Merge and Merge x4")
	merge_buttons[0].pressed.emit()
	await frames(2)
	check(inv.count("merged_carrot_premium") >= 1 and inv.count("crop_carrot") == 9, "3 Carrots became a Premium Carrot")
	ui.close()

	# order board: deliver both of Mara's first orders
	await stand(Vector2i(38, 20), "n")
	check(player.prompt() == "Mara's orders", "the order board shows its prompt")
	player.act()
	await frames(2)
	var board: Node = ui._screens["order_board"]
	check(board.visible, "the act key opens the order board")
	var delivered := 0
	for i: int in range(2):
		var deliver := buttons(board, "Deliver")
		if deliver.is_empty():
			break
		deliver[0].pressed.emit()
		delivered += 1
		await frames(2)
	check(delivered == 2 and state.player["stats"]["ordersCompleted"] == 2, "both orders delivered from the board")
	check(state.coins() > coins_start and state.player["xp"] > 12 and state.reputation("npc_mara") == 16, "coins, XP and reputation earned")
	check(inv.count("seed_carrot") == 10, "the orders paid 10 Carrot seeds for the next round")
	ui.close()
	var real_minutes: float = (sim.game_minute - start_minute) / 60.0 * float(data.config["time"]["realSecondsPerGameHour"]) / 60.0
	check(real_minutes < 10.0, "Plant -> Grow -> Harvest -> Merge -> Order -> Reward took %.1f real minutes of game time (limit 10)" % real_minutes)
	check(hud.guide_text().contains("Till the soil"), "guide points back to planting")
	print("%s  scripted playthrough: %d passed, %d failed" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(1 if _failed else 0)
