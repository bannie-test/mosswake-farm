extends RefCounted
## M4 tests: Root-sense and the dig site, the Spirit Bench and its two quests, the Rootling's job
## loop (zone, stamina, rest, skill, Sap upkeep), pathfinding in fenced and crowded layouts, and
## the soak test. Called by run_tests.gd.

var t: SceneTree
var sim: Node
var data: Node
var state: Node
var inv: Node
var farm: Node
var merge: Node
var quests: Node
var research: Node
var spirits: Node
var shop: Node
var session: Node
var save: Node
var completed := false


## A bare grid standing in for the farm map: what Spirits needs from a world, and nothing else.
class StubWorld:
	var nav := AStarGrid2D.new()
	var tiles := {}
	var well := Vector2i(0, 3)
	var home := Vector2i(1, 1)
	var farm: Node

	func _init(size: Vector2i, farm_: Node) -> void:
		farm = farm_
		nav.region = Rect2i(Vector2i.ZERO, size)
		nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		nav.update()

	func path_between(from: Vector2i, to: Vector2i) -> Array:
		if nav.is_point_solid(to):
			return []
		var path: Array = Array(nav.get_id_path(from, to))
		if not path.is_empty():
			path.pop_front()
		return path

	func plot_tile(plot_id: String) -> Vector2i:
		return tiles[plot_id]

	func plots_in(rect: Rect2i) -> Array:
		var out: Array = []
		for plot_id: String in tiles:
			if rect.has_point(tiles[plot_id]) and farm.plots.has(plot_id):
				out.append(plot_id)
		return out

	func well_tile() -> Vector2i:
		return well

	func home_tile() -> Vector2i:
		return home


func run(tree: SceneTree, root: Node) -> void:
	t = tree
	for pair: Array in [["sim", "Sim"], ["data", "GameData"], ["state", "GameState"], ["inv", "Inventory"], ["farm", "Farm"], ["merge", "Merge"],
			["quests", "Quests"], ["research", "Research"], ["spirits", "Spirits"], ["shop", "Shop"], ["session", "Session"], ["save", "SaveGame"]]:
		set(pair[0], root.get_node(pair[1]))
	sim.paused = true
	_test_root_sense()
	_test_dig_and_bench_story()
	_test_rootling_three_days()
	_test_zone_rules_and_skill()
	_test_upkeep()
	_test_pathfinding()
	_test_soak()
	_test_spirit_save()
	spirits.world = null
	completed = true


func check(cond: bool, what: String) -> void:
	t.check(cond, what)


# ------------------------------------------------------------------ helpers
## A 16-plot field in a 4x4 block at (2,2)-(5,5), a Rootling awake, Sap in the wallet.
func farm_with_rootling(seed_value: int = 1, sap: int = 10) -> StubWorld:
	session.new_game(seed_value)
	state.player["coins"] = 100000
	farm.buy_field()
	var world := StubWorld.new(Vector2i(12, 10), farm)
	var n := 0
	for plot_id: String in farm.plots:
		if n < 16:
			world.tiles[plot_id] = Vector2i(2 + n % 4, 2 + n / 4)
		n += 1
	spirits.world = world
	spirits.bench["spiritId"] = "spirit_rootling"
	spirits._finish_awakening()
	inv.add("mat_sap", sap)
	return world


func plant_all(world: StubWorld, plant_id: String = "plant_carrot") -> void:
	inv.add(data.plant(plant_id)["seedItemId"], world.tiles.size())
	for plot_id: String in world.tiles:
		farm.till(plot_id)
		farm.plant(plot_id, plant_id)
		farm.water(plot_id)


func rootling() -> Dictionary:
	return spirits.spirits[0]


## Run the simulation and report what happened to the plots and the spirit.
func run_for(world: StubWorld, minutes: float, dt: float) -> Dictionary:
	var out := {"min_moisture": 100.0, "rested": false, "longest_busy": 0.0, "states": {}}
	var busy_for := 0.0
	var last_phase := ""
	var elapsed := 0.0
	while elapsed < minutes - 0.0001:
		sim.advance(dt)
		elapsed += dt
		for plot_id: String in world.tiles:
			var p: Dictionary = farm.plot(plot_id)
			if farm.is_planted(p):
				out["min_moisture"] = minf(out["min_moisture"], p["moisture"])
		var s: Dictionary = rootling()
		out["states"][s["state"]] = true
		out["rested"] = out["rested"] or s["state"] == "resting"
		var phase: String = spirits.runtime[s["instanceId"]]["phase"]
		if phase == last_phase and phase in ["walk", "act", "refill"]:
			busy_for += dt
			out["longest_busy"] = maxf(out["longest_busy"], busy_for)
		else:
			busy_for = 0.0
		last_phase = phase
	return out


# ------------------------------------------------------------------ Stage A
func _test_root_sense() -> void:
	session.new_game(1)
	var w := 6
	var wrong := 0
	var worst := 0
	for husk: int in range(36):
		spirits.dig = {"husks": [husk], "loot": {}, "dug": {}, "digsLeft": 0, "husksFound": 0}
		for cell: int in range(36):
			var d := maxi(absi(husk % w - cell % w), absi(husk / w - cell / w))
			var want := "hot" if d <= 1 else ("warm" if d <= 3 else "cold")
			if spirits.warmth(cell) != want:
				wrong += 1
		# a careful player: always dig the tile that leaves the fewest possibilities in the worst case
		var candidates: Array = range(36)
		var dug := {}
		var digs := 0
		while digs < 36:
			var best_cell := -1
			var best_worst := 999
			for cell: int in range(36):
				if dug.has(cell):
					continue
				var groups := {}
				for c: int in candidates:
					var d := maxi(absi(c % w - cell % w), absi(c / w - cell / w))
					var mark := "husk" if c == cell else ("hot" if d <= 1 else ("warm" if d <= 3 else "cold"))
					groups[mark] = int(groups.get(mark, 0)) + 1
				var worst_group := 0
				for mark: String in groups:
					if mark != "husk":
						worst_group = maxi(worst_group, groups[mark])
				if worst_group < best_worst or (worst_group == best_worst and candidates.has(cell) and not candidates.has(best_cell)):
					best_worst = worst_group
					best_cell = cell
			digs += 1
			dug[best_cell] = true
			if best_cell == husk:
				break
			var mark: String = spirits.warmth(best_cell)
			candidates = candidates.filter(func(c: int) -> bool:
				var d := maxi(absi(c % w - best_cell % w), absi(c / w - best_cell / w))
				return c != best_cell and ("hot" if d <= 1 else ("warm" if d <= 3 else "cold")) == mark)
		worst = maxi(worst, digs)
	check(wrong == 0, "Root-sense marks are correct for every tile and every husk position (36 x 36)")
	check(worst <= int(data.def("dig_sites", "site_mossy_hollow_mvp")["digsPerKit"]), "a careful player always finds the husk within one Dig Kit (worst case %d digs of 10)" % worst)
	print("INFO  dig site: worst case %d digs to find the husk by Root-sense" % worst)


func _test_dig_and_bench_story() -> void:
	session.new_game(5)
	check(not spirits.site_open() and spirits.dig_tile(0) == "", "the dig site is closed before The Sleeper")
	for quest_id: String in ["quest_first_harvest", "quest_table_for_two", "quest_strange_carrot", "quest_what_carrots_remember"]:
		quests.completed.append(quest_id)
		for id: String in quests.def(quest_id)["rewards"]["unlocks"]:
			state.unlock(id)
	quests.active.clear()
	state.player["level"] = 8
	state.player["coins"] = 100000
	state.buildings["bld_merge_table"] = 1
	quests.refresh()
	check(quests.entry("quest_sleeper").get("stepId", "") == "s1" and spirits.site_open(), "The Sleeper starts at level 8 and opens the site")
	inv.add("crop_carrot_ancient", 1)
	check(quests.deliver("quest_sleeper") and inv.count("tool_dig_kit") == 1 and spirits.digs_available() == 10, "Ilse takes an Ancient Carrot and hands over a Dig Kit: 10 digs")
	check(state.build_blocked("bld_spirit_bench").contains("The Sleeper"), "the Spirit Bench waits for the husk")
	shop.buy("npc_tobin", "shop_tobin_dig_kit", 3)
	check(inv.count("tool_dig_kit") == 4 and state.coins() == 100000 - 450, "Tobin sells more Dig Kits for 150 once the quest has begun")
	var found := {}
	for cell: int in range(36):
		var result: String = spirits.dig_tile(cell)
		found[result] = int(found.get(result, 0)) + 1
		if result in ["hot", "warm", "cold"]:
			check(result == spirits.warmth(cell), "a dug tile shows its Root-sense mark")
	check(found.get("husk", 0) == 1 and found.get("spirit_essence", 0) == 2, "the site holds exactly 1 husk and 2 Spirit Essence")
	check(inv.count("spirit_husk_dormant") == 1 and inv.count("spirit_essence") == 2, "both reach the player")
	check(spirits.digs_available() == 4 and inv.count("tool_dig_kit") == 0 and spirits.dig_tile(3) == "", "36 digs used 4 kits' worth; a dug tile cannot be dug again")
	check(quests.is_completed("quest_sleeper"), "finding the husk completes The Sleeper")
	check(state.build("bld_spirit_bench") and state.coins() == 100000 - 450 - 1500, "the Spirit Bench costs 1,500 coins")
	check(quests.entry("quest_first_vocation").get("stepId", "") == "s1", "First Vocation begins once the bench stands")
	# brewing early must not strand the quest
	inv.add("merged_sun_bouquet", 2)
	check(spirits.brew() and inv.count("spirit_essence") == 1 and inv.count("merged_sun_bouquet") == 0 and state.coins() == 100000 - 450 - 1500 - 100, "the potion takes 1 Essence, 2 Sun Bouquets and 100 coins")
	sim.advance(179.0)
	check(inv.count("spirit_revival_potion") == 0, "it brews for 3 hours")
	sim.advance(1.0)
	check(inv.count("spirit_revival_potion") == 1, "then it is ready")
	check(not spirits.revive(), "a husk that is not on the bench, or not clean, cannot be revived")
	check(spirits.place_husk() and inv.count("spirit_husk_dormant") == 0 and spirits.bench["stage"] == "dormant", "the husk is laid on the bench")
	for i: int in range(5):
		spirits.scrub()
	check(spirits.bench["stage"] == "dormant", "five scrubs are not enough")
	spirits.scrub()
	check(spirits.bench["stage"] == "cleaned" and quests.entry("quest_first_vocation")["stepId"] == "s3", "the sixth shows its face; the potion brewed earlier counts, so the quest is on step 3")
	check(spirits.revive() and spirits.bench["stage"] == "sprout" and quests.entry("quest_first_vocation")["stepId"] == "s4", "the potion revives it into a Sleeping Sprout")
	check(spirits.charm_blocked("spirit_rootling") == "Need 5 Premium Carrot", "the Rootling charm needs 5 Premium Carrots")
	inv.add("merged_carrot_premium", 5)
	var coins: int = state.coins()
	check(spirits.start_awakening("spirit_rootling") and inv.count("merged_carrot_premium") == 0 and inv.count("spirit_essence") == 0 and state.coins() == coins - 200, "the charm takes 5 Premium Carrots, 1 Essence and 200 coins")
	sim.advance(359.0)
	check(spirits.spirits.is_empty(), "awakening takes 6 hours")
	sim.advance(1.0)
	check(spirits.spirits.size() == 1 and rootling()["spiritId"] == "spirit_rootling" and rootling()["skillLevel"] == 1 and rootling()["stamina"] == 40.0, "a Rootling wakes at skill 1 with 40 stamina")
	check(quests.is_completed("quest_first_vocation") and state.is_unlocked("feature_zone_tool") and shop.craft_known("craft_sap"), "First Vocation is complete: the zone tool and the Sap recipe")
	check(quests.completed.size() == 6, "all six MVP story quests are done")
	inv.add("crop_wheat", 13)
	check(shop.craft_affordable("craft_sap") == 2 and shop.craft("craft_sap", 1) == 2 and inv.count("mat_sap") == 2 and inv.count("crop_wheat") == 7, "6 common crops press into 2 Sap")


# ------------------------------------------------------------------ Stage D
func _test_rootling_three_days() -> void:
	var world := farm_with_rootling(2)
	plant_all(world)
	check(spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4)), "a 4x4 zone of 16 tiles is accepted at skill 1")
	var r := run_for(world, 3 * 24 * 60.0, 1.0)
	check(r["min_moisture"] > 0.0, "a Rootling keeps a 16-tile zone from reaching 0 moisture for 3 game days (lowest %.0f)" % r["min_moisture"])
	check(r["states"].has("walking") and r["states"].has("working") and r["states"].has("idle"), "it walks, works, and idles between rounds")
	check(rootling()["skillXp"] > 20 and inv.count("mat_sap") == 7, "it gains skill XP by working and is fed 1 Sap at each of 3 dawns")
	check(r["longest_busy"] < 30.0, "no single walk or action runs longer than 30 game minutes (longest %.1f)" % r["longest_busy"])
	# rest: from 0 stamina it is back to full after restHours, then returns to work
	rootling()["stamina"] = 0.0
	spirits.runtime[rootling()["instanceId"]]["phase"] = "idle"
	sim.advance(1.0)
	check(rootling()["state"] == "resting", "at 0 stamina it rests")
	sim.advance(float(spirits.level_def(rootling())["restHours"]) * 60.0)
	check(rootling()["stamina"] > 30.0 and rootling()["state"] != "resting", "after its rest hours it is back at work")
	var per_day := 1440.0 / (6.0 + 3.0 * 60.0 / 40.0)
	print("INFO  Rootling at skill 1: %d waterings in 3 days (GDD ceiling without walking: about %.0f per day)" % [rootling()["skillXp"], per_day])


func _test_zone_rules_and_skill() -> void:
	var world := farm_with_rootling(3)
	var id: String = rootling()["instanceId"]
	check(spirits.zone_blocked(id, Rect2i(2, 2, 5, 4)) == "Too large: 20 of 16 tiles" and not spirits.set_zone(id, Rect2i(2, 2, 5, 4)), "a 20-tile zone is refused at skill 1")
	# a plot outside the zone is never watered
	plant_all(world)
	spirits.set_zone(id, Rect2i(2, 2, 4, 2))
	run_for(world, 16 * 60.0, 1.0)
	var inside := 100.0
	var outside := 100.0
	for plot_id: String in world.tiles:
		var m: float = farm.plot(plot_id)["moisture"]
		if world.tiles[plot_id].y <= 3:
			inside = minf(inside, m)
		else:
			outside = minf(outside, m)
	check(inside > 0.0 and outside == 0.0, "it works only inside its zone: zone plots stay wet, the rest dry out")
	# skill levels: thresholds from data, zone and speed grow, the MVP cap is 3
	rootling()["skillXp"] = 99
	spirits._gain_skill(rootling())
	check(rootling()["skillLevel"] == 2 and spirits.zone_limit(rootling()) == 24 and spirits.speed(rootling()) == 1.2, "100 skill XP: level 2, 24 tiles, speed 1.2")
	rootling()["skillXp"] = 5000
	spirits._gain_skill(rootling())
	check(rootling()["skillLevel"] == 3 and spirits.zone_limit(rootling()) == 36, "the MVP skill cap is 3 (36 tiles)")
	check(spirits.set_zone(id, Rect2i(2, 2, 4, 4)), "the bigger zone is now allowed")


func _test_upkeep() -> void:
	var world := farm_with_rootling(4, 0)
	plant_all(world, "plant_tomato")
	var id: String = rootling()["instanceId"]
	spirits.set_zone(id, Rect2i(2, 2, 4, 4))
	check(not spirits.is_drowsy(rootling()), "the day it wakes it is fed")
	sim.sleep_until_dawn()
	check(spirits.is_drowsy(rootling()) and spirits.speed(rootling()) == 0.5, "with no Sap at dawn it is Drowsy: half speed")
	var before: Dictionary = rootling().duplicate(true)
	for plot_id: String in world.tiles:
		farm.plot(plot_id)["moisture"] = 10.0
	spirits.runtime[id]["phase"] = "idle"
	rootling()["stamina"] = 40.0
	rootling()["carrying"]["water"] = 40          # enough water that neither run stops to refill
	spirits.runtime[id]["pos"] = Vector2(2, 2)
	var xp_before: int = rootling()["skillXp"]
	var watered := func() -> int:
		var n := 0
		for plot_id: String in world.tiles:
			if farm.plot(plot_id)["moisture"] > 50.0:
				n += 1
		return n
	sim.advance(60.0)
	var drowsy_actions: int = watered.call()
	check(rootling()["skillXp"] == xp_before, "a Drowsy spirit gains no skill XP")
	check(spirits.spirits.size() == 1 and rootling()["zone"] == before["zone"] and rootling()["skillLevel"] == before["skillLevel"], "it never leaves, and keeps its zone and skill")
	# the same hour, fed
	inv.add("mat_sap", 1)
	rootling()["upkeepPaidDay"] = sim.day()
	for plot_id: String in world.tiles:
		farm.plot(plot_id)["moisture"] = 10.0
	spirits.runtime[id]["phase"] = "idle"
	rootling()["stamina"] = 40.0
	rootling()["carrying"]["water"] = 40
	spirits.runtime[id]["pos"] = Vector2(2, 2)
	sim.advance(60.0)
	var fed_actions: int = watered.call()
	check(absi(fed_actions - drowsy_actions * 2) <= 1, "fed, it does twice the work in the same hour (%d plots against %d)" % [fed_actions, drowsy_actions])
	sim.sleep_until_dawn()
	check(not spirits.is_drowsy(rootling()) and inv.count("mat_sap") == 0, "1 Sap at dawn keeps it fed for the day")


func _test_pathfinding() -> void:
	# a fence between the well and the field, with one gap
	var world := farm_with_rootling(6)
	for y: int in range(0, 10):
		if y != 8:
			world.nav.set_point_solid(Vector2i(1, y), true)
	world.home = Vector2i(0, 0)
	spirits.runtime.clear()
	var path: Array = world.path_between(world.well, Vector2i(2, 3))
	check(path.size() == 12 and path.has(Vector2i(1, 8)), "the path to the field goes around the fence through the gap (%d steps)" % path.size())
	plant_all(world)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	var r := run_for(world, 24 * 60.0, 1.0)
	check(r["min_moisture"] > 0.0 and r["longest_busy"] < 30.0, "fenced farm: the zone stays watered and the spirit never stalls")
	# a crowded field: one plot walled in on all four sides
	world = farm_with_rootling(7)
	plant_all(world)
	var walled := ""
	for plot_id: String in world.tiles:
		if world.tiles[plot_id] == Vector2i(8, 8):
			walled = plot_id
	if walled == "":
		walled = world.tiles.keys()[15]
		world.tiles[walled] = Vector2i(8, 8)
	for side: Vector2i in [Vector2i(7, 8), Vector2i(9, 8), Vector2i(8, 7), Vector2i(8, 9)]:
		world.nav.set_point_solid(side, true)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	rootling()["skillLevel"] = 3
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 7, 5))
	check(world.path_between(Vector2i(2, 2), Vector2i(8, 8)).is_empty(), "the walled-in plot has no path")
	r = run_for(world, 24 * 60.0, 1.0)
	var others_ok := true
	for plot_id: String in world.tiles:
		if plot_id != walled and farm.is_planted(farm.plot(plot_id)) and farm.plot(plot_id)["moisture"] <= 0.0:
			others_ok = false
	check(others_ok and farm.plot(walled)["moisture"] == 0.0, "it skips the plot it cannot reach and keeps the others watered")
	check(r["longest_busy"] < 30.0 and r["states"].has("working"), "an unreachable target never traps it")
	# the well cut off: it waits, and resumes when the way opens
	world = farm_with_rootling(8)
	plant_all(world)
	for plot_id: String in world.tiles:
		farm.plot(plot_id)["moisture"] = 5.0
	for side: Vector2i in [Vector2i(1, 3), Vector2i(0, 2), Vector2i(0, 4)]:
		world.nav.set_point_solid(side, true)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	sim.advance(120.0)
	check(rootling()["state"] == "idle" and rootling()["stamina"] == 40.0 and rootling()["skillXp"] == 0, "with the well cut off it waits; nothing is spent")
	world.nav.set_point_solid(Vector2i(1, 3), false)
	sim.advance(60.0)
	check(rootling()["stamina"] < 40.0, "when the way opens it goes back to work")


## Section 17, M4: "soak test at 20x speed" and "no stuck state in a 2-hour soak".
## Two real hours at 20x are 2,400 game minutes, fed to the simulation in frame-sized steps.
func _test_soak() -> void:
	var world := farm_with_rootling(9, 20)
	plant_all(world)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	var frame_dt := 20.0 / 60.0
	var r := run_for(world, 2400.0, frame_dt)
	var frame_actions: int = rootling()["skillXp"]
	check(r["min_moisture"] > 0.0 and r["longest_busy"] < 30.0, "2-hour soak at 20x: no dry plot, no stall (longest busy stretch %.1f min)" % r["longest_busy"])
	check(not is_nan(rootling()["stamina"]) and rootling()["stamina"] >= 0.0 and rootling()["stamina"] <= float(spirits.level_def(rootling())["stamina"]), "stamina stays inside its range")
	var pos: Vector2 = spirits.position_of(rootling()["instanceId"])
	check(pos.x >= 0 and pos.y >= 0 and pos.x < 12 and pos.y < 10 and not world.nav.is_point_solid(Vector2i(pos.round())), "it ends on a walkable tile of the map")
	# the same stretch in sleep-sized steps does the same work
	world = farm_with_rootling(9, 20)
	plant_all(world)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	r = run_for(world, 2400.0, 10.0)
	var step_actions: int = rootling()["skillXp"]
	check(r["min_moisture"] > 0.0 and absi(step_actions - frame_actions) <= maxi(3, frame_actions / 10), "10-minute steps do the same work as frame steps (%d against %d waterings)" % [step_actions, frame_actions])


	# information for balancing: the thirstiest MVP crop, all 16 plots watered at the same moment
	world = farm_with_rootling(9, 20)
	plant_all(world, "plant_tomato")
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	r = run_for(world, 1440.0, 1.0)
	print("INFO  16 Tomato plots (water every 6 h) watered in one go, skill-1 Rootling, 1 day: lowest moisture %.0f" % r["min_moisture"])


func _test_spirit_save() -> void:
	var world := farm_with_rootling(10)
	plant_all(world)
	spirits.set_zone(rootling()["instanceId"], Rect2i(2, 2, 4, 4))
	spirits.dig = {"husks": [7], "loot": {"3": "spirit_essence"}, "dug": {"0": "cold"}, "digsLeft": 6, "husksFound": 0}
	run_for(world, 500.0, 1.0)
	var before := JSON.stringify(save.build_envelope())
	check(save.save(5) == OK, "a save with a working spirit is written")
	session.new_game(99)
	spirits.world = world
	check(save.load_slot(5) == OK and JSON.stringify(save.build_envelope()) == before, "spirit, zone, bench and dig site survive save and load exactly")
	check(spirits.dug_mark(0) == "cold" and spirits.digs_available() == 6, "the dig site remembers what was dug")
	var xp: int = rootling()["skillXp"]
	for plot_id: String in world.tiles:
		farm.plot(plot_id)["moisture"] = 5.0
	sim.advance(180.0)
	check(rootling()["skillXp"] > xp, "the loaded spirit goes straight back to work")
	var fixture := ProjectSettings.globalize_path("res://").path_join("../qa/fixtures/SaveEnvelope.m4_sample.json")
	var f := FileAccess.open(fixture, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(save.whole_numbers_where_whole(save.build_envelope()), "  ") + "\n")
		f.close()
	for suffix: String in ["", ".bak1"]:
		DirAccess.remove_absolute(save.slot_path(5) + suffix)
