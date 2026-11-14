extends SceneTree
## Headless engine tests. Run: godot --headless --path game -s res://tests/run_tests.gd
## Exit code 0 only when every check passes.

var _failed := 0
var _passed := 0


class Counter:
	var minutes := 0.0
	var calls := 0
	var largest := 0.0
	func advance(delta: float) -> void:
		minutes += delta
		calls += 1
		largest = maxf(largest, delta)


func check(cond: bool, what: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL  " + what)


func _initialize() -> void:
	await process_frame            # let the autoloads finish _ready
	var data: Node = root.get_node("GameData")
	var sim: Node = root.get_node("Sim")
	var state: Node = root.get_node("GameState")
	var save: Node = root.get_node("SaveGame")
	sim.paused = true
	_test_data(data)
	_test_sim(sim)
	_test_rng()
	_test_save(sim, state, save)
	var gameplay: RefCounted = load("res://tests/test_gameplay.gd").new()
	gameplay.run(self, root)
	check(gameplay.completed, "the gameplay tests ran to the end (a script error stops them early)")
	var m2: RefCounted = load("res://tests/test_m2.gd").new()
	m2.run(self, root)
	check(m2.completed, "the M2 tests ran to the end (a script error stops them early)")
	var m3: RefCounted = load("res://tests/test_m3.gd").new()
	m3.run(self, root)
	check(m3.completed, "the M3 tests ran to the end (a script error stops them early)")
	print("%s  engine tests: %d passed, %d failed" % ["PASS" if _failed == 0 else "FAIL", _passed, _failed])
	quit(1 if _failed else 0)


func _test_data(data: Node) -> void:
	check(data.tables["items"].size() == 32, "all 32 item definitions load")
	check(data.tables["plants"].size() == 5, "5 plants load")
	check(data.tables["animals"].size() == 3, "3 animals load")
	check(data.tables["merge_recipes"].size() == 10, "10 merge recipes load")
	check(data.tables["npcs"].size() == 3, "3 NPCs load")
	check(data.tables["quests"].size() == 6, "6 quests load")
	check(data.item("merged_carrot_crystal")["baseValue"] == 700, "Crystal Carrot is worth 700")
	check(data.plant("plant_carrot")["growthHours"] == 6, "Carrot grows in 6 game hours")
	check(int(data.merge_config["baseRate"]["rare"]) == 65, "Rare merges start at 65%")
	for recipe: Dictionary in data.tables["merge_recipes"].values():
		check(data.has_def("items", recipe["output"]["itemId"]), "recipe output exists: " + recipe["id"])


func _test_sim(sim: Node) -> void:
	var c := Counter.new()
	sim.register(c)
	sim.game_minute = 6 * 60.0
	var events := {"dawns": 0, "hours": 0}
	var on_dawn := func(_d: int) -> void: events["dawns"] += 1
	var on_hour := func(_h: int) -> void: events["hours"] += 1
	sim.dawn.connect(on_dawn)
	sim.hour_changed.connect(on_hour)
	sim.advance(24 * 60.0)
	check(is_equal_approx(c.minutes, 1440.0), "systems receive every game minute of a day")
	check(events["hours"] == 24, "24 hour events in a game day")
	check(events["dawns"] == 1, "exactly one dawn in a game day")
	check(c.largest <= 60.0, "no system step crosses an hour boundary")
	check(sim.day() == 2 and sim.hour() == 6, "a full day later it is day 2, 06:00")
	sim.advance(15 * 60.0 + 30.0)
	check(sim.hour() == 21 and sim.minute_of_hour() == 30 and sim.is_night(), "21:30 is night")
	c.calls = 0
	c.largest = 0.0
	sim.sleep_until_dawn()
	check(sim.hour() == 6 and sim.minute_of_hour() == 0 and sim.day() == 3, "sleeping skips to 06:00 the next day")
	check(c.largest <= 10.0 and c.calls >= 51, "sleep advances in steps of 10 game minutes")
	check(events["dawns"] == 2, "dawn fires on waking")
	# small frame-sized deltas add up to the same time as one large delta
	sim.game_minute = 0.0
	for i: int in range(6000):
		sim.advance(0.0166)
	check(absf(sim.game_minute - 99.6) < 0.001, "frame-sized steps accumulate without drift")
	sim.dawn.disconnect(on_dawn)
	sim.hour_changed.disconnect(on_hour)
	sim.unregister(c)


func _test_rng() -> void:
	var a := RngStream.new(12345)
	var b := RngStream.new(12345)
	var same := true
	var total := 0.0
	var in_range := true
	for i: int in range(20000):
		var v := a.randf()
		same = same and v == b.randf()
		in_range = in_range and v >= 0.0 and v < 1.0
		total += v
	check(same, "the same seed gives the same rolls")
	check(in_range, "rolls stay inside [0, 1)")
	check(absf(total / 20000.0 - 0.5) < 0.01, "rolls are uniform on average")
	var hits := 0
	for i: int in range(100000):
		if a.roll_percent() < 65.0:
			hits += 1
	check(absf(hits / 1000.0 - 65.0) < 0.5, "a 65% roll succeeds 65% of the time, within 0.5 points")
	var lo := 99
	var hi := -99
	for i: int in range(2000):
		var n := a.randi_range(1, 6)
		lo = mini(lo, n)
		hi = maxi(hi, n)
	check(lo == 1 and hi == 6, "randi_range covers both ends")


func _test_save(sim: Node, state: Node, save: Node) -> void:
	state.new_game(42)
	sim.game_minute = 31925.0
	state.player["coins"] = 1840
	state.player["level"] = 6
	state.player["reputation"] = {"npc_mara": 164}
	state.player["mergePity"] = {"merge_carrot_crystal": 1}
	state.stream("merge").randf()
	var before: Dictionary = save.build_envelope()
	var next_roll_stream := RngStream.new(state.stream("merge").state)
	var expected_roll := next_roll_stream.randf()
	check(save.save(9) == OK, "a save file is written")
	check(save.save(9) == OK and FileAccess.file_exists(save.slot_path(9) + ".bak1"), "saving again keeps a backup")
	check(not FileAccess.file_exists(save.slot_path(9) + ".tmp"), "no temporary file is left behind")
	state.new_game(7)
	sim.game_minute = 0.0
	check(save.load_slot(9) == OK, "the save loads")
	var after: Dictionary = save.build_envelope()
	check(JSON.stringify(before) == JSON.stringify(after), "save, quit, load reproduces identical state")
	check(typeof(state.player["reputation"]["npc_mara"]) == TYPE_INT, "nested counts stay integers")
	check(state.stream("merge").randf() == expected_roll, "reloading does not change the next merge roll")
	check(typeof(state.player["coins"]) == TYPE_INT and state.player["coins"] == 1840, "coins stay an integer")
	# migrations run in order from the save's version to the current one
	var old := {"saveVersion": 1, "gameMinute": 5.0}
	check(save.migrate(old.duplicate())["saveVersion"] == save.SAVE_VERSION, "a current save needs no migration")
	check(save.migrate({"saveVersion": 99}) == null, "a save from a newer build is refused, not corrupted")
	for n: int in range(4):
		DirAccess.remove_absolute(save.slot_path(9) + (".bak%d" % n if n else ""))
