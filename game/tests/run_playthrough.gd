extends SceneTree
## Scripted playthrough through the real scene: the same player actions, prompts, screens and
## buttons a person uses. Run:
##   godot --headless --path game -s res://tests/run_playthrough.gd -- --seed=4 --new
## It shows that every M1 and M2 feature can be reached and used by following the prompts;
## whether it is pleasant needs human playtests.

const TEST_SLOT := 9

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


## Stand in front of something, check its prompt, press the act key, return the open screen.
func use(tile: Vector2i, facing: String, prompt: String, screen: String) -> Node:
	if ui.is_open():
		ui.close()
	await stand(tile, facing)
	check(player.prompt() == prompt, "prompt reads '%s' (got '%s')" % [prompt, player.prompt()])
	player.act()
	await frames(2)
	check(ui._screens[screen].visible, "the act key opens: " + prompt)
	return ui._screens[screen]


func press(screen: Node, text: String) -> bool:
	var found := buttons(screen, text)
	if found.is_empty():
		return false
	found[0].pressed.emit()
	await frames(2)
	return true


func load_scene() -> void:
	if farm_scene != null:
		farm_scene.queue_free()
		await frames(2)
	farm_scene = load("res://scenes/farm.tscn").instantiate()
	root.add_child(farm_scene)
	await frames(5)
	player = farm_scene.map.player
	ui = farm_scene.ui
	hud = ui.hud


func _initialize() -> void:
	_run()


func _run() -> void:
	var data: Node = root.get_node("GameData")
	var sim: Node = root.get_node("Sim")
	var state: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	var farm: Node = root.get_node("Farm")
	var orders: Node = root.get_node("Orders")
	var animals: Node = root.get_node("Animals")
	var shipping: Node = root.get_node("Shipping")
	var save: Node = root.get_node("SaveGame")
	var session: Node = root.get_node("Session")
	await process_frame
	session.slot = TEST_SLOT
	await load_scene()
	var start_minute: float = sim.game_minute
	check(farm.plots.size() == 12 and animals.animals.size() == 2, "a new game owns 2 fields and 2 chickens")
	check(hud.guide_text().contains("Till the soil"), "guide starts with: till and plant")

	# ---- movement
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

	# ---- plant the first field with the act key only
	for plot_id: String in farm.plots:
		if not plot_id.begins_with("field_01"):
			continue
		await stand(farm_scene.map.plot_tile(plot_id) + Vector2i(0, -1), "s")
		var seen: Array = []
		for i: int in range(3):
			seen.append(player.prompt().get_slice(" ", 0))
			player.act()
			await frames(1)
		check(seen == ["Till", "Plant", "Water"] and player.prompt() == "", "Till, Plant, Water in turn, then nothing left to do (%s)" % str(seen))
	check(inv.count("seed_carrot") == 0, "six Carrot seeds planted")

	# ---- the shop: buy Carrot seeds at Tobin's cart
	var shop_screen: Node = await use(Vector2i(45, 20), "n", "Tobin's cart", "shop")
	var coins: int = state.coins()
	check(await press(shop_screen, "Buy") and inv.count("seed_carrot") == 1 and state.coins() == coins - 4, "Buy puts a Carrot seed in the backpack for 4 coins")
	check(buttons(shop_screen, "Buy").size() == 4, "only what is unlocked and affordable can be bought (Carrot and Wheat seeds, x1 and x5)")

	# ---- wait for the crops, then harvest
	ui.close()
	sim.time_scale = 240.0
	var waited := 0
	while waited < 3000 and not farm.plot("field_01/5")["state"] == "mature":
		await frames(1)
		waited += 1
	sim.time_scale = 1.0
	check(hud.guide_text().contains("Harvest") or hud.guide_text().contains("Collect") or hud.guide_text().contains("Deliver"), "the guide moves on once crops are ripe: " + hud.guide_text())
	for plot_id: String in farm.plots:
		if plot_id.begins_with("field_01"):
			await stand(farm_scene.map.plot_tile(plot_id) + Vector2i(0, -1), "s")
			check(player.prompt() == "Harvest", "the prompt offers Harvest")
			player.act()
	check(inv.count("crop_carrot") == 12, "12 Carrots in the backpack")
	var loop_minutes: float = (sim.game_minute - start_minute) / 60.0 * float(data.config["time"]["realSecondsPerGameHour"]) / 60.0

	# ---- the Coop: collect eggs, pet, make Feed
	for a: Dictionary in animals.animals:
		a["productionProgress"] = 1.0
	animals.changed.emit()
	var coop: Node = await use(farm_scene.map.approach_tile("bld_coop"), "n", "Coop", "housing")
	check(await press(coop, "Collect all") and inv.count("prod_egg") == 2, "Collect all gathers 2 Eggs")
	check(await press(coop, "Pet") and animals.animals[0]["pettedDay"] == sim.day(), "a chicken can be petted")
	inv.add("crop_wheat", 4)
	await frames(2)
	var feed: int = inv.count("mat_feed")
	check(await press(coop, "Make") and inv.count("mat_feed") == feed + 2, "4 Wheat become 2 Feed")

	# ---- the order board: all met NPCs, deliver, skip
	var board: Node = await use(Vector2i(38, 20), "n", "Order board", "order_board")
	check(orders.orders.size() == 4, "the board shows Mara's and Tobin's orders")
	var target: Dictionary = orders.orders_for("npc_mara")[0]
	for line: Dictionary in target["lines"]:
		inv.add(line["itemId"], maxi(0, int(line["qty"]) - inv.count(line["itemId"])))
	await frames(2)
	coins = state.coins()
	check(await press(board, "Deliver") and state.coins() == coins + int(target["rewards"]["coins"]) and state.reputation("npc_mara") == 8, "Deliver pays the order's coins and reputation")
	var before: int = orders.orders.size()
	check(await press(board, "Skip") and orders.orders.size() == before - 1, "Skip dismisses an order")

	# ---- the shipping bin: ship, then get paid at dawn
	inv.add("crop_carrot", 10)
	var bin: Node = await use(farm_scene.map.approach_tile("bld_shipping_bin"), "n", "Shipping bin", "bin")
	check(await press(bin, "Ship all") and not shipping.bin.is_empty(), "Ship all moves a stack into the bin")
	var owed: int = shipping.pending_value()

	# ---- sleeping skips to dawn, pays the bin and saves
	var bed: Node = await use(Vector2i(5, 10), "n", "Sleep until morning", "confirm")
	coins = state.coins()
	check(await press(bed, "Sleep") and sim.hour() == 6 and sim.minute_of_hour() == 0, "sleeping skips to 06:00")
	check(state.coins() == coins + owed and shipping.bin.is_empty(), "the bin paid %d coins at dawn" % owed)
	check(save.has_save(TEST_SLOT), "sleeping saves the game")

	# ---- building: the Merge Table pad
	var pad: Node = await use(farm_scene.map.approach_tile("bld_merge_table"), "n", "Build: Merge Table", "confirm")
	check(buttons(pad, "Build").is_empty(), "at level 1 the Merge Table cannot be built yet")
	state.player["level"] = 3
	state.add_coins(400)
	pad = await use(farm_scene.map.approach_tile("bld_merge_table"), "n", "Build: Merge Table", "confirm")
	check(await press(pad, "Build") and state.building_level("bld_merge_table") == 1, "at level 3 with 250 coins it is built")
	inv.add("crop_carrot", 3)
	var table: Node = await use(farm_scene.map.approach_tile("bld_merge_table"), "n", "Merge Table", "merge_table")
	var premium: int = inv.count("merged_carrot_premium")
	check(await press(table, "Merge") and inv.count("merged_carrot_premium") > premium, "3 Carrots become a Premium Carrot")

	# ---- buying a field
	var sale: Node = await use(Vector2i(18, 12), "s", "Buy this field", "confirm")
	state.add_coins(300)
	sale = await use(Vector2i(18, 12), "s", "Buy this field", "confirm")
	check(await press(sale, "Buy") and farm.plots.size() == 18, "a third field adds 6 plots")
	await stand(Vector2i(18, 12), "s")
	check(player.prompt() == "Till", "the new plots can be tilled at once")

	# ---- quit and continue: the saved farm comes back
	sim.paused = true                 # so that no game time passes between saving and comparing
	session.autosave_enabled = true
	session.autosave()
	var saved := JSON.stringify(save.build_envelope())
	await load_scene_continue(session)
	check(JSON.stringify(save.build_envelope()) == saved, "continuing restores the saved farm exactly")
	check(farm.plots.size() == 18 and state.building_level("bld_merge_table") == 1, "the field and the Merge Table are still there")
	await stand(farm_scene.map.approach_tile("bld_merge_table"), "n")
	check(player.prompt() == "Merge Table", "and the rebuilt map knows about them")
	check(loop_minutes < 10.0, "plant to harvest took %.1f real minutes of game time" % loop_minutes)
	for suffix: String in ["", ".bak1", ".bak2", ".bak3"]:
		DirAccess.remove_absolute(save.slot_path(TEST_SLOT) + suffix)
	print("%s  scripted playthrough: %d passed, %d failed" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(1 if _failed else 0)


## Reload the scene the way a normal start does (no --new): it must pick up the save.
func load_scene_continue(session: Node) -> void:
	farm_scene.queue_free()
	await frames(2)
	session.new_game(123)
	farm_scene = load("res://scenes/farm.tscn").instantiate()
	farm_scene.set_meta("force_continue", true)
	root.add_child(farm_scene)
	await frames(5)
	player = farm_scene.map.player
	ui = farm_scene.ui
	hud = ui.hud
