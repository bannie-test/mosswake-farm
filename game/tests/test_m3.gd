extends RefCounted
## M3 tests: story quests and their step types, research yields and timing, blueprints, seed
## creation, the Ancient Carrot, the Storage Chest, and the story path from a new save to an
## Ancient Carrot harvest. Called by run_tests.gd.

var t: SceneTree
var sim: Node
var data: Node
var state: Node
var inv: Node
var farm: Node
var merge: Node
var orders: Node
var research: Node
var quests: Node
var unlocks: Node
var session: Node
var save: Node
var completed := false


func run(tree: SceneTree, root: Node) -> void:
	t = tree
	for pair: Array in [["sim", "Sim"], ["data", "GameData"], ["state", "GameState"], ["inv", "Inventory"], ["farm", "Farm"], ["merge", "Merge"],
			["orders", "Orders"], ["research", "Research"], ["quests", "Quests"], ["unlocks", "Unlocks"], ["session", "Session"], ["save", "SaveGame"]]:
		set(pair[0], root.get_node(pair[1]))
	sim.paused = true
	_test_quests()
	_test_research()
	_test_blueprint_and_ancient_carrot()
	_test_chest()
	_test_story_path()
	completed = true


func check(cond: bool, what: String) -> void:
	t.check(cond, what)


func active_ids() -> Array:
	return quests.active.map(func(e: Dictionary) -> String: return e["questId"])


func level_up_to(level: int) -> void:
	state.player["level"] = level
	state.leveled_up.emit(level)


# ------------------------------------------------------------------ section 8
func _test_quests() -> void:
	session.new_game(1)
	check(active_ids() == ["quest_first_harvest"], "a new game starts Mara's First Harvest")
	check(not orders.board_open() and orders.orders.is_empty(), "the order board is closed until it is done")
	var e: Dictionary = quests.entry("quest_first_harvest")
	check(quests.step_text(e) == "Bring Mara 6 Carrots (0/6)", "the step shows its text and progress")
	check(not quests.deliver("quest_first_harvest"), "nothing to hand over yet")
	inv.add("crop_carrot", 8)
	check(quests.reserved("crop_carrot") == 6 and quests.would_break("crop_carrot", 3) and not quests.would_break("crop_carrot", 2), "6 Carrots are reserved for the story")
	var xp: int = state.player["xp"]
	check(quests.deliver("quest_first_harvest") and inv.count("crop_carrot") == 2, "handing over takes 6 Carrots")
	check(quests.is_completed("quest_first_harvest") and state.reputation("npc_mara") == 60 and state.player["xp"] == xp + 40 and inv.count("seed_tomato") == 5,
		"First Harvest pays 60 reputation, 40 XP and 5 Tomato seeds")
	check(orders.board_open() and orders.orders.size() == 4, "and opens the order board")
	check(active_ids().is_empty(), "A Table for Two waits for level 3")
	# build and produce steps
	level_up_to(3)
	check(active_ids() == ["quest_table_for_two"], "Tobin's quest starts at level 3")
	check(not merge.known_recipes().has("merge_carrot_golden"), "the Golden Carrot recipe is not known yet")
	state.player["coins"] = 1000
	state.build("bld_merge_table")
	check(quests.entry("quest_table_for_two")["stepId"] == "s2", "building the Merge Table completes the build step")
	inv.add("crop_carrot", 3)
	merge.attempt("merge_carrot_premium")
	check(quests.is_completed("quest_table_for_two") and inv.count("lucky_clover") == 2 and merge.known_recipes().has("merge_carrot_golden"),
		"making a Premium Carrot completes it: 2 Clovers and the Golden Carrot recipe")
	# deliver step with the quest-item warning
	check(not unlocks.is_met(data.def("buildings", "bld_research_station")["unlock"]) and state.build_blocked("bld_research_station").contains("A Strange Carrot"), "the Research Station waits for A Strange Carrot")
	level_up_to(4)
	check(active_ids() == ["quest_strange_carrot"], "Ilse arrives at level 4 with A Strange Carrot")
	state.unlock("merge_carrot_crystal")
	inv.add("merged_carrot_golden", 3)
	check(merge.story_warning("merge_carrot_crystal") == "Ilse is waiting for your Golden Carrot" and merge.needs_confirmation("merge_carrot_crystal"), "merging away the last Golden Carrot warns first")
	inv.add("merged_carrot_golden", 1)
	check(merge.story_warning("merge_carrot_crystal") == "", "with a spare one there is no warning")
	check(quests.deliver("quest_strange_carrot") and state.build_blocked("bld_research_station") == "Need 2000 coins", "handing it over unlocks the Research Station plans")
	check(active_ids().is_empty(), "What Carrots Remember waits for the station to be built")
	state.player["coins"] = 5000
	state.build("bld_research_station")
	check(active_ids() == ["quest_what_carrots_remember"], "it starts once the station stands")
	# research step: 3 different goods
	state.player["mergePity"] = {}
	inv.add("merged_carrot_premium", 2)
	inv.add("merged_tomato_premium", 1)
	research.start("merged_carrot_premium")
	sim.advance(60.0)
	research.start("merged_carrot_premium")
	sim.advance(60.0)
	check(quests.progress(quests.entry("quest_what_carrots_remember")) == [1, 3], "researching the same good twice counts once")
	research.start("merged_tomato_premium")
	sim.advance(60.0)
	research.start("merged_carrot_golden")
	sim.advance(180.0)
	check(quests.is_completed("quest_what_carrots_remember") and state.is_unlocked("merge_carrot_crystal"), "three different goods complete it and reveal the Crystal Carrot recipe")
	level_up_to(8)
	check(active_ids().is_empty(), "The Sleeper stays off until the dig site exists (M4)")
	check(state.reputation("npc_ilse") == 120, "reputation from both of Ilse's quests")


# ------------------------------------------------------------------ section 7
func _test_research() -> void:
	session.new_game(2)
	inv.add("merged_carrot_golden", 3)
	state.player["coins"] = 1000
	check(research.blocked_reason("merged_carrot_golden") == "Needs the Research Station" and not research.start("merged_carrot_golden"), "no research without the station")
	state.buildings["bld_research_station"] = 1
	check(research.slots() == 1, "one queue slot at Research level 1")
	check(research.fragments_for("merged_carrot_golden", 1) == 6, "a Golden Carrot yields 6 fragments the first time")
	check(research.blocked_reason("crop_carrot") == "Nothing to learn from this", "a plain Carrot cannot be researched")
	var xp: int = state.player["xp"]
	check(research.start("merged_carrot_golden") and inv.count("merged_carrot_golden") == 2 and state.coins() == 960, "research destroys the good and costs 40 coins")
	check(research.blocked_reason("merged_carrot_golden") == "The queue is full", "the queue holds one job")
	sim.advance(179.0)
	check(inv.count("gene_carrot") == 0, "not done a minute early")
	sim.advance(1.0)
	check(inv.count("gene_carrot") == 6 and inv.count("mat_stardust") == 1, "after 3 hours: 6 Carrot genes and 1 Stardust")
	check(research.state["researchedOnce"] == ["merged_carrot_golden"] and research.state["xp"] == 6 and state.player["xp"] == xp + 30, "Research XP = fragments; 5 player XP per fragment")
	check(research.fragments_for("merged_carrot_golden", 1) == 3, "the second time it yields 3")
	check(research.fragments_for("merged_carrot_golden", 3) == 5 and research.fragments_for("merged_carrot_golden", 4) == 6, "quality multiplies the yield (x1.5 at Q3, x2 at Q4)")
	research.start("merged_carrot_golden")
	sim.advance(180.0)
	check(inv.count("gene_carrot") == 9, "3 more fragments")
	research.start("merged_carrot_golden")
	sim.advance(180.0)
	check(research.state["level"] == 2 and research.state["xp"] == 12, "10 Research XP reaches Research level 2")
	check(research.fragments_for("merged_carrot_crystal", 1) == 18, "a Crystal Carrot yields 8 x 1.1 at level 2, doubled the first time")
	research.state["level"] = 3
	check(research.slots() == 2, "Research level 3 opens a second queue slot")
	# a good with no gene in the MVP still reveals its next recipe
	state.buildings["bld_merge_table"] = 1
	check(not merge.known_recipes().has("merge_egg_golden"), "Golden Egg is unknown before research")
	inv.add("merged_egg_speckled", 1)
	var genes: int = inv.count("gene_carrot")
	research.start("merged_egg_speckled")
	sim.advance(60.0)
	check(merge.known_recipes().has("merge_egg_golden") and inv.count("gene_carrot") == genes, "researching a Speckled Egg reveals Golden Egg and banks no Carrot genes")
	# save in the middle of a job
	inv.add("merged_carrot_premium", 1)
	research.start("merged_carrot_premium")
	sim.advance(20.0)
	var before := JSON.stringify(save.build_envelope())
	save.save(6)
	session.new_game(9)
	check(save.load_slot(6) == OK and JSON.stringify(save.build_envelope()) == before, "a research queue survives save and load")
	sim.advance(40.0)
	check(research.state["queue"].is_empty() and research.state["researchedOnce"].has("merged_carrot_premium"), "and finishes on time after loading")
	for suffix: String in ["", ".bak1"]:
		DirAccess.remove_absolute(save.slot_path(6) + suffix)


func _test_blueprint_and_ancient_carrot() -> void:
	session.new_game(3)
	state.buildings["bld_research_station"] = 1
	state.player["coins"] = 1000
	inv.add("gene_carrot", 9)
	check(not research.can_unlock("bp_carrot_ancient") and not research.unlock_blueprint("bp_carrot_ancient"), "9 fragments are not enough")
	inv.add("gene_carrot", 3)
	check(research.unlock_blueprint("bp_carrot_ancient") and inv.count("gene_carrot") == 2, "the blueprint unlocks at 10 fragments and consumes them")
	check(research.has_blueprint("bp_carrot_ancient") and research.state["codex"]["carrot"].has("blueprint"), "it is permanent and stamped in the Codex")
	check(not research.unlock_blueprint("bp_carrot_ancient"), "it cannot be bought twice")
	check(research.creation_blocked("bp_carrot_ancient") == "Need 1 Crystal Carrot", "each use still costs a Crystal Carrot")
	inv.add("merged_carrot_crystal", 1)
	inv.add("mat_stardust", 5)
	check(research.create("bp_carrot_ancient") and inv.count("merged_carrot_crystal") == 0 and inv.count("mat_stardust") == 0 and state.coins() == 800, "creation consumes 1 Crystal Carrot, 5 Stardust and 200 coins")
	sim.advance(119.0)
	check(inv.count("seed_carrot_ancient") == 0, "seeds take 2 hours")
	sim.advance(1.0)
	check(inv.count("seed_carrot_ancient") == 4, "seed creation yields 4 Ancient Carrot seeds")
	check(unlocks.is_met(data.plant("plant_carrot_ancient")["unlock"]), "the Ancient Carrot can now be planted")
	farm.till("field_01/0")
	check(farm.plant("field_01/0", "plant_carrot_ancient") and farm.water("field_01/0"), "planted and watered")
	sim.advance(8 * 60.0 - 1.0)
	farm.water("field_01/0")
	sim.advance(6 * 60.0 + 1.0)
	var xp: int = state.player["xp"]
	check(farm.plot("field_01/0")["state"] == "mature" and farm.harvest("field_01/0") == 2 and inv.count("crop_carrot_ancient") == 2, "it grows in 14 hours and yields 2")
	check(state.player["xp"] == xp + 10, "a Legendary harvest gives 5 XP per unit")
	check(research.fragments_for("crop_carrot_ancient", 1) == 16, "an Ancient Carrot can itself be researched (8 fragments, doubled the first time)")


# ------------------------------------------------------------------ section 13
func _test_chest() -> void:
	session.new_game(4)
	state.player["coins"] = 500
	check(state.build("bld_chest") and state.coins() == 400, "a Storage Chest costs 100 coins")
	inv.ensure_chest("chest_01", 36)
	inv.add("crop_carrot", 150)
	var index: int = inv.state["backpack"]["stacks"].size() - 1
	check(inv.move_stack("chest_01", index, true) == 51 and inv.state["chests"]["chest_01"]["stacks"].size() == 1, "a stack moves into the chest")
	check(inv.count("crop_carrot") == 150, "stations still count what is in the chest")
	state.buildings["bld_merge_table"] = 1
	inv.remove("crop_carrot", 99)
	check(inv.count("crop_carrot") == 51 and not merge.attempt("merge_carrot_premium").is_empty() and inv.count("crop_carrot") == 48, "the Merge Table draws from the chest")
	check(inv.move_stack("chest_01", 0, false) == 48 and inv.state["chests"]["chest_01"]["stacks"].is_empty(), "and the stack moves back")
	var rng := RngStream.new(5)
	var total: int = inv.total_units()
	for i: int in range(10000):
		var to_chest := rng.randf() < 0.5
		var from: Array = inv.state["backpack"]["stacks"] if to_chest else inv.state["chests"]["chest_01"]["stacks"]
		if not from.is_empty():
			inv.move_stack("chest_01", rng.randi_range(0, from.size() - 1), to_chest)
	check(inv.total_units() == total, "nothing is lost or duplicated in 10,000 random transfers")


# ------------------------------------------------------------------ the whole MVP path so far
## From a new save to an Ancient Carrot harvest, using only real actions. The player level is
## set at each gate (levelling is covered by the session bot); everything else is played.
func _test_story_path() -> void:
	session.new_game(77)
	var start: float = sim.game_minute
	state.player["coins"] = 100000

	var grow := func(plant_id: String, plots: int) -> void:
		var def: Dictionary = data.plant(plant_id)
		for i: int in range(plots):
			var id := "field_%02d/%d" % [1 + i / 6, i % 6]
			if farm.plot(id)["state"] == "empty":
				farm.till(id)
			if inv.count(def["seedItemId"]) == 0:
				t.root.get_node("Shop").buy("npc_tobin", "shop_tobin_" + def["seedItemId"])
			farm.plant(id, plant_id)
			farm.water(id)
		var waited := 0
		while waited < 3000 and farm.plot("field_01/0")["state"] != "mature":
			if waited % 240 == 0:
				for i: int in range(plots):
					farm.water("field_%02d/%d" % [1 + i / 6, i % 6])
			sim.advance(1.0)
			waited += 1
		for i: int in range(plots):
			farm.harvest("field_%02d/%d" % [1 + i / 6, i % 6])

	grow.call("plant_carrot", 6)
	check(quests.deliver("quest_first_harvest"), "path: First Harvest handed over")
	level_up_to(3)
	state.build("bld_merge_table")
	# 27 Carrots make a Golden Carrot; 4 Golden Carrots researched make the 10 fragments
	var need_golden := func(n: int) -> void:
		var guard := 0
		while inv.count("merged_carrot_golden") < n and guard < 40:
			guard += 1
			while inv.count("merged_carrot_premium") < 3:
				if inv.count("crop_carrot") < 3:
					grow.call("plant_carrot", 12)
				merge.attempt("merge_carrot_premium")
			merge.attempt("merge_carrot_golden")
	need_golden.call(1)
	check(quests.is_completed("quest_table_for_two"), "path: A Table for Two done by building and merging")
	level_up_to(4)
	check(quests.deliver("quest_strange_carrot"), "path: the Golden Carrot goes to Ilse")
	state.build("bld_research_station")
	var guard := 0
	while not research.can_unlock("bp_carrot_ancient") and guard < 12:
		guard += 1
		need_golden.call(1)
		research.start("merged_carrot_golden")
		sim.advance(181.0)
		if not quests.is_completed("quest_what_carrots_remember") and inv.count("merged_carrot_premium") == 0:
			while inv.count("crop_carrot") < 3:
				grow.call("plant_carrot", 12)
			merge.attempt("merge_carrot_premium")
		if not quests.is_completed("quest_what_carrots_remember") and research.blocked_reason("merged_carrot_premium") == "":
			research.start("merged_carrot_premium")
			sim.advance(61.0)
	check(research.unlock_blueprint("bp_carrot_ancient"), "path: 10 Carrot genes from Golden Carrots (%d researched) unlock the blueprint" % guard)
	check(guard <= 4, "path: at most four Golden Carrots are needed (6 + 3 + 3 + 3 fragments; a researched Premium Carrot helps)")
	# a Crystal Carrot for the seeds: a Rare merge, with pity making the worst case finite
	var attempts := 0
	while inv.count("merged_carrot_crystal") < 1 and attempts < 12:
		need_golden.call(3)
		merge.attempt("merge_carrot_crystal")
		attempts += 1
	check(inv.count("merged_carrot_crystal") >= 1 and attempts <= 8, "path: a Crystal Carrot within the pity limit (%d attempts)" % attempts)
	check(inv.count("mat_stardust") >= 5 or attempts == 1, "path: failed merges and research supplied Stardust (%d)" % inv.count("mat_stardust"))
	while inv.count("mat_stardust") < 5:
		need_golden.call(1)
		research.start("merged_carrot_golden")
		sim.advance(181.0)
	check(research.create("bp_carrot_ancient"), "path: seed creation started")
	sim.advance(121.0)
	grow.call("plant_carrot_ancient", 4)
	check(inv.count("crop_carrot_ancient") == 8, "path: 8 Ancient Carrots harvested from 4 seeds")
	if not quests.is_completed("quest_what_carrots_remember"):      # a third different good: the Ancient Carrot itself
		research.start("crop_carrot_ancient")
		sim.advance(241.0)
	check(quests.completed.size() == 4, "path: all four M3 story quests are complete")
	print("INFO  story path to the Ancient Carrot: %.1f game days of pure production time" % ((sim.game_minute - start) / 1440.0))
