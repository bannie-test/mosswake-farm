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


func by_key(node: Node, prefix: String) -> Array:
	var out: Array = []
	for child: Node in node.get_children():
		if child is Button and not child.disabled and str(child.get_meta("key", "")).begins_with(prefix):
			out.append(child)
		out.append_array(by_key(child, prefix))
	return out


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
	var quests: Node = root.get_node("Quests")
	var research: Node = root.get_node("Research")
	var merge: Node = root.get_node("Merge")
	var spirits: Node = root.get_node("Spirits")
	await process_frame
	session.slot = TEST_SLOT
	await load_scene()
	var playtest: Node = root.get_node("Playtest")
	playtest.start("user://playtest_check")
	var start_minute: float = sim.game_minute
	check(farm.plots.size() == 12 and animals.animals.size() == 2, "a new game owns 2 fields and 2 chickens")
	check(hud.guide_text().contains("Till the soil"), "guide starts with: till and plant")
	check(hud._guide.text.contains("Mara: Bring Mara 6 Carrots (0/6)"), "the HUD tracks Mara's quest")

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

	# ---- M5: pause menu, settings, gamepad bindings, hold-to-act, day and night
	var settings: Node = root.get_node("Settings")
	var controls: Node = root.get_node("Controls")
	ui.open("menu")
	await frames(2)
	var menu: Node = ui._screens["menu"]
	check(menu.visible and not player.control_enabled, "the pause menu opens and holds the player")
	var toggles: Array = []
	var sliders: Array = []
	var stack: Array = [menu]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CheckButton:
			toggles.append(n)
		elif n is HSlider:
			sliders.append(n)
		stack.append_array(n.get_children())
	check(sliders.size() == 2 and toggles.size() == 4, "it has music and sound sliders and the large text, hold-to-act, fullscreen and playtest-log switches")
	for slider: HSlider in sliders:
		if slider.get_meta("key") == "music":
			slider.value = 0.2
	check(is_equal_approx(settings.get_value("music"), 0.2) and absf(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) - 0.2) < 0.01, "the music slider sets the Music bus volume")
	settings.set_value("largeText", true, false)
	check(ui._root.theme.default_font_size == 12, "Large text switches every screen to the bigger font")
	settings.set_value("largeText", false, false)
	check(ui._root.theme.default_font_size == 9 and ui._root.theme.default_font != null, "normal text uses the pixel font")
	settings.set_value("music", 0.6, false)
	check(await press(menu, "Back to the farm") and not ui.is_open(), "Back to the farm closes the menu")
	var pad_ok := true
	for action: String in ["move_left", "move_right", "move_up", "move_down", "act", "seed_next", "backpack", "close"]:
		pad_ok = pad_ok and InputMap.action_get_events(action).any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton or e is InputEventJoypadMotion)
	check(pad_ok, "every action has a gamepad binding")
	var pad_event := InputEventJoypadButton.new()
	pad_event.button_index = JOY_BUTTON_A
	pad_event.pressed = true
	controls._input(pad_event)
	check(controls.label("act") == "A" and hud._prompt.text.begins_with("[A]"), "prompts show gamepad buttons once a gamepad is used")
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_E
	controls._input(key_event)
	check(controls.label("act") == "E", "and keys again after a key press")
	# hold-to-act: hold the act key and walk along a row of plots
	settings.set_value("holdToAct", true, false)
	await stand(farm_scene.map.plot_tile("field_02/0") + Vector2i(-1, -1), "e")
	player.position.y += 16
	Input.action_press("act")
	Input.action_press("move_right")
	await frames(70)
	Input.action_release("move_right")
	Input.action_release("act")
	var tilled := 0
	for n: int in range(3):
		if farm.plot("field_02/%d" % n)["state"] != "empty":
			tilled += 1
	check(tilled >= 2, "holding the act key while walking tills the row (%d of 3 plots)" % tilled)
	settings.set_value("holdToAct", false, false)
	await stand(farm_scene.map.plot_tile("field_02/3") + Vector2i(-1, 0), "e")
	Input.action_press("act")
	Input.action_press("move_right")
	await frames(70)
	Input.action_release("move_right")
	Input.action_release("act")
	check(farm.plot("field_02/4")["state"] == "empty" and farm.plot("field_02/5")["state"] == "empty", "with the option off, holding does nothing extra")
	settings.set_value("holdToAct", true, false)
	inv.add("seed_carrot", 6 - inv.count("seed_carrot"))       # the rows above used some seeds; start the next part with six
	var noon: float = sim.game_minute
	sim.game_minute = 12 * 60.0
	await frames(2)
	var day_color: Color = farm_scene.map._tint.color
	sim.game_minute = 23 * 60.0
	await frames(2)
	check(day_color == Color.WHITE and farm_scene.map._tint.color.b > farm_scene.map._tint.color.r and farm_scene.map._tint.color.r > 0.3, "noon is untinted; night is a cool tint, never black")
	sim.game_minute = noon
	await frames(2)

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

	# ---- the order board: the story hand-over opens it; then all met NPCs, deliver, skip
	var board: Node = await use(Vector2i(38, 20), "n", "Order board", "order_board")
	check(orders.orders.is_empty() and hud.guide_text().contains("Mara is waiting for your Carrot"), "before the first quest the board has no orders and the guide points to Mara")
	check(await press(board, "Hand over") and quests.is_completed("quest_first_harvest") and inv.count("seed_tomato") == 5, "Hand over completes First Harvest: 5 Tomato seeds")
	check(orders.orders.size() == 4, "the board now shows Mara's and Tobin's orders")
	var target: Dictionary = orders.orders_for("npc_mara")[0]
	for line: Dictionary in target["lines"]:
		inv.add(line["itemId"], maxi(0, int(line["qty"]) - inv.count(line["itemId"])))
	await frames(2)
	coins = state.coins()
	check(await press(board, "Deliver") and state.coins() == coins + int(target["rewards"]["coins"]) and state.reputation("npc_mara") == 68, "Deliver pays the order's coins and reputation")
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
	state.leveled_up.emit(3)
	check(hud._guide.text.contains("Tobin: Build the Merge Table (0/1)"), "at level 3 Tobin's quest appears in the tracker")
	state.add_coins(400)
	pad = await use(farm_scene.map.approach_tile("bld_merge_table"), "n", "Build: Merge Table", "confirm")
	check(await press(pad, "Build") and state.building_level("bld_merge_table") == 1, "at level 3 with 250 coins it is built")
	inv.add("crop_carrot", 3)
	var table: Node = await use(farm_scene.map.approach_tile("bld_merge_table"), "n", "Merge Table", "merge_table")
	var premium: int = inv.count("merged_carrot_premium")
	check(await press(table, "Merge") and inv.count("merged_carrot_premium") > premium, "3 Carrots become a Premium Carrot")
	check(quests.is_completed("quest_table_for_two") and inv.count("lucky_clover") == 2, "which completes A Table for Two: 2 Clovers")

	# ---- the story-item warning, Ilse's quest, the Research Station
	await stand(farm_scene.map.approach_tile("bld_research_station"), "n")
	check(player.prompt() == "", "the Research Station pad is hidden until the story reveals it")
	state.player["level"] = 4
	state.leveled_up.emit(4)
	inv.add("merged_carrot_golden", 1)
	await frames(2)
	check(hud.guide_text().contains("Ilse is waiting for your Golden Carrot"), "Ilse's prompt appears when a Golden Carrot is in the backpack")
	inv.add("crop_carrot", 6)
	bin = await use(farm_scene.map.approach_tile("bld_shipping_bin"), "n", "Shipping bin", "bin")
	var ship_keys: Array = buttons(bin, "Ship").map(func(b: Button) -> String: return b.get_meta("key", ""))
	check(ship_keys.has("crop_carrot/0") and not ship_keys.any(func(k: String) -> bool: return k.begins_with("merged_carrot_golden")),
		"the bin offers the Carrots but keeps the Golden Carrot Ilse is waiting for")
	board = await use(Vector2i(38, 20), "n", "Order board", "order_board")
	check(await press(board, "Hand over") and quests.is_completed("quest_strange_carrot"), "the Golden Carrot is handed to Ilse")
	state.add_coins(2100)
	pad = await use(farm_scene.map.approach_tile("bld_research_station"), "n", "Build: Research Station", "confirm")
	check(await press(pad, "Build") and state.building_level("bld_research_station") == 1, "the Research Station is built for 2,000 coins")
	inv.add("merged_carrot_golden", 1)
	var lab: Node = await use(farm_scene.map.approach_tile("bld_research_station"), "n", "Research Station", "research")
	check(await press(lab, "Research") and research.state["queue"].size() == 1, "Research queues a good")
	sim.time_scale = 600.0
	waited = 0
	while waited < 2000 and not research.state["queue"].is_empty():
		await frames(1)
		waited += 1
	sim.time_scale = 1.0
	check(inv.count("gene_carrot") > 0 or research.state["researchedOnce"].size() == 1, "the study finishes and is recorded")

	# ---- the Storage Chest
	var chest_pad: Node = await use(farm_scene.map.approach_tile("bld_chest"), "n", "Build: Storage Chest", "confirm")
	check(await press(chest_pad, "Build"), "a Storage Chest is built")
	var chest: Node = await use(farm_scene.map.approach_tile("bld_chest"), "n", "Storage Chest", "chest")
	var stacks: int = inv.state["backpack"]["stacks"].size()
	chest._pack.get_child(0).pressed.emit()
	await frames(2)
	check(inv.state["backpack"]["stacks"].size() == stacks - 1 and inv.state["chests"]["chest_01"]["stacks"].size() == 1, "pressing a stack stores it in the chest")

	# ---- The Sleeper: the dig site
	await stand(Vector2i(43, 30), "n")
	check(player.prompt() == "", "the dig site entrance is not there before The Sleeper")
	quests.active.clear()
	quests.completed.append("quest_what_carrots_remember")
	state.player["level"] = 8
	state.leveled_up.emit(8)
	check(hud._guide.text.contains("Ilse: Bring Ilse 1 Ancient Carrot (0/1)"), "at level 8 The Sleeper appears in the tracker")
	inv.add("crop_carrot_ancient", 1)
	board = await use(Vector2i(38, 20), "n", "Order board", "order_board")
	check(await press(board, "Hand over") and inv.count("tool_dig_kit") == 1, "Ilse trades the Ancient Carrot for a Dig Kit")
	inv.add("tool_dig_kit", 3)
	var dig: Node = await use(Vector2i(43, 30), "n", "Dig site", "dig")
	var digs := 0
	while inv.count("spirit_husk_dormant") == 0 and digs < 36:
		var cells: Array = dig._grid.get_children().filter(func(b: Node) -> bool: return not b.disabled)
		if cells.is_empty():
			break
		cells[0].pressed.emit()
		digs += 1
		await frames(1)
	check(inv.count("spirit_husk_dormant") == 1 and quests.is_completed("quest_sleeper"), "digging finds the husk (%d digs, row by row) and completes The Sleeper" % digs)
	check(dig._info.text.contains("Spirit Essence still buried here") or inv.count("spirit_essence") == 2, "the site says when Spirit Essence is still buried")
	while inv.count("spirit_essence") < 2 and digs < 36:
		var left: Array = dig._grid.get_children().filter(func(b: Node) -> bool: return not b.disabled)
		if left.is_empty():
			break
		left[0].pressed.emit()
		digs += 1
		await frames(1)
	check(inv.count("spirit_essence") == 2, "digging on finds both Spirit Essence")
	var marks: Array = dig._grid.get_children().filter(func(b: Node) -> bool: return b.text in ["HOT", "warm", "cold"])
	check(marks.size() >= 1, "dug tiles show their Root-sense mark")

	# ---- First Vocation: the Spirit Bench
	state.add_coins(2500)
	pad = await use(farm_scene.map.approach_tile("bld_spirit_bench"), "n", "Build: Spirit Bench", "confirm")
	check(await press(pad, "Build") and state.building_level("bld_spirit_bench") == 1, "the Spirit Bench is built for 1,500 coins")
	var bench: Node = await use(farm_scene.map.approach_tile("bld_spirit_bench"), "n", "Spirit Bench", "bench")
	check(await press(bench, "Lay the Dormant Husk") and spirits.bench["stage"] == "dormant", "the husk goes on the bench")
	var scrubs := 0
	while spirits.bench["stage"] == "dormant" and scrubs < 10:
		by_key(bench, "scrub")[0].pressed.emit()
		scrubs += 1
		await frames(2)
	check(scrubs == 6 and spirits.bench["stage"] == "cleaned", "six scrubs by hand clean it")
	inv.add("merged_sun_bouquet", 2)
	await frames(2)
	check(await press(bench, "Brew a Revival Potion"), "the potion is set to brew")
	sim.time_scale = 600.0
	waited = 0
	while waited < 2000 and inv.count("spirit_revival_potion") == 0:
		await frames(1)
		waited += 1
	sim.time_scale = 1.0
	check(await press(bench, "Pour the Revival Potion") and spirits.bench["stage"] == "sprout", "the potion revives the husk into a sprout")
	inv.add("merged_carrot_premium", 5)
	await frames(2)
	check(await press(bench, "Wake it as a Rootling") and spirits.bench["stage"] == "awakening", "the sprout is offered the Rootling charm")
	sim.time_scale = 600.0
	waited = 0
	while waited < 3000 and spirits.spirits.is_empty():
		await frames(1)
		waited += 1
	sim.time_scale = 1.0
	await frames(3)
	check(spirits.spirits.size() == 1 and ui._screens["awaken"].visible, "six hours later the Rootling wakes and its scene plays")
	check(await press(ui._screens["awaken"], "Welcome") and not ui.is_open(), "the scene closes on Welcome")
	check(quests.is_completed("quest_first_vocation") and quests.completed.size() == 6, "First Vocation is complete: the whole MVP story is done")

	# ---- the zone tool and the Rootling at work on the real map
	var spirit: Dictionary = spirits.spirits[0]
	bench = await use(farm_scene.map.approach_tile("bld_spirit_bench"), "n", "Spirit Bench", "bench")
	check(await press(bench, "Draw") and player.zone_spirit == spirit["instanceId"] and not ui.is_open(), "Draw zone closes the screen and starts the zone tool")
	await stand(Vector2i(9, 13), "s")
	check(player.prompt() == "Mark the first corner", "the prompt asks for the first corner")
	player.act()
	await stand(Vector2i(19, 15), "s")
	check(player.prompt() == "Set the zone (33 of 16 tiles)", "an oversized rectangle shows its size against the limit")
	player.act()
	check(spirit["zone"] == null and player.zone_spirit != "", "and is refused")
	await stand(Vector2i(15, 14), "s")
	player.act()
	check(spirit["zone"] != null and spirits.zone_rect(spirit) == Rect2i(9, 13, 7, 2) and player.zone_spirit == "", "a 7x2 zone over the first two fields is set")
	inv.add("seed_wheat", 12)
	for plot_id: String in farm.plots:
		if plot_id.begins_with("field_01") or plot_id.begins_with("field_02"):
			if farm.plot(plot_id)["state"] == "empty":
				farm.till(plot_id)
			if farm.plot(plot_id)["state"] == "tilled":
				farm.plant(plot_id, "plant_wheat")
			farm.plot(plot_id)["moisture"] = 5.0
	check(not farm_scene.map.path_between(farm_scene.map.home_tile(), farm_scene.map.well_tile()).is_empty(), "on the real map there is a path from the bench to the well")
	sim.time_scale = 240.0
	waited = 0
	var dry := 12
	while waited < 2400 and dry > 0:
		await frames(1)
		waited += 1
		dry = 0
		for plot_id: String in farm.plots:
			if (plot_id.begins_with("field_01") or plot_id.begins_with("field_02")) and farm.is_planted(farm.plot(plot_id)) and farm.plot(plot_id)["moisture"] < 30.0:
				dry += 1
	sim.time_scale = 1.0
	check(dry == 0 and spirit["skillXp"] >= 8, "the Rootling walked the real map and watered every planted plot in its zone (%d waterings)" % spirit["skillXp"])
	check(farm_scene.map._spirit_views.has(spirit["instanceId"]), "and is drawn on the map")
	await stand(Vector2i(10, 13), "s")
	Input.action_press("move_right")
	await frames(40)
	Input.action_release("move_right")
	check(player.position.x > 200.0, "the player walks straight through where the spirit works: spirits never block")

	# ---- buying a field
	ui.close()
	var sale: Node = await use(Vector2i(18, 12), "s", "Buy this field", "confirm")
	state.add_coins(300)
	sale = await use(Vector2i(18, 12), "s", "Buy this field", "confirm")
	check(await press(sale, "Buy") and farm.plots.size() == 18, "a third field adds 6 plots")
	await stand(Vector2i(18, 12), "s")
	check(player.prompt() == "Till", "the new plots can be tilled at once")

	# ---- section 20, Farm map: every interactable can be reached on foot
	var start_tile := Vector2i(5, 11)
	var unreachable: Array = []
	for tile: Vector2i in farm_scene.map._targets:
		var ok := false
		for step: Vector2i in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if not farm_scene.map.path_between(start_tile, tile + step).is_empty():
				ok = true
				break
		if not ok:
			unreachable.append("%s at %s" % [farm_scene.map._targets[tile]["kind"], tile])
	check(unreachable.is_empty(), "every one of the %d interactable tiles can be walked to (%s)" % [farm_scene.map._targets.size(), str(unreachable.slice(0, 4))])

	# ---- the playtest log recorded this session
	var log_path: String = playtest.stop()
	var log: Variant = JSON.parse_string(FileAccess.get_file_as_string(log_path))
	var kinds := {}
	if typeof(log) == TYPE_DICTIONARY:
		for e: Dictionary in log["events"]:
			kinds[e["kind"]] = int(kinds.get(e["kind"], 0)) + 1
	check(kinds.has("level_up") and kinds.has("order_delivered") and kinds.has("merge") and kinds.has("quest_completed") and kinds.has("spirit_awake"),
		"the playtest log holds level-ups, orders, merges, quests and the spirit's awakening (%s)" % str(kinds))
	check(typeof(log) == TYPE_DICTIONARY and log["days"].size() >= 1 and log["days"][0].has("earned"), "and coins earned and spent per game day")
	var sample := ProjectSettings.globalize_path("res://").path_join("../qa/playtest/sample_session.json")
	DirAccess.make_dir_recursive_absolute(sample.get_base_dir())
	DirAccess.copy_absolute(log_path, sample)
	DirAccess.remove_absolute(log_path)

	# ---- quit and continue: the saved farm comes back
	sim.paused = true                 # so that no game time passes between saving and comparing
	session.autosave_enabled = true
	session.autosave()
	var saved := JSON.stringify(save.build_envelope())
	await load_scene_continue(session)
	check(JSON.stringify(save.build_envelope()) == saved, "continuing restores the saved farm exactly")
	check(farm.plots.size() == 18 and state.building_level("bld_merge_table") == 1 and state.building_level("bld_research_station") == 1, "the field, the Merge Table and the Research Station are still there")
	check(quests.completed.size() == 6 and inv.state["chests"].has("chest_01"), "so are the story and the chest")
	check(spirits.spirits.size() == 1 and spirits.zone_rect(spirits.spirits[0]) == Rect2i(9, 13, 7, 2) and farm_scene.map._spirit_views.size() == 1, "and the Rootling with its zone")
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
