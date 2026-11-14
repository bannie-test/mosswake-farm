extends RefCounted
## M1 gameplay tests: growth and moisture, inventory, merge maths, orders and rewards, the full
## first loop, and a save round trip in the middle of it. Called by run_tests.gd.

var t: SceneTree
var sim: Node
var data: Node
var state: Node
var inv: Node
var farm: Node
var merge: Node
var orders: Node
var session: Node
var save: Node
var completed := false     ## stays false if a script error cut the run short

const P := "field_01/0"


func run(tree: SceneTree, root: Node) -> void:
	t = tree
	sim = root.get_node("Sim")
	data = root.get_node("GameData")
	state = root.get_node("GameState")
	inv = root.get_node("Inventory")
	farm = root.get_node("Farm")
	merge = root.get_node("Merge")
	orders = root.get_node("Orders")
	session = root.get_node("Session")
	save = root.get_node("SaveGame")
	sim.paused = true
	_test_growth()
	_test_moisture_and_wither()
	_test_regrow()
	_test_inventory()
	_test_merge_maths()
	_test_merge_outcomes()
	_test_orders_and_levels()
	_test_first_loop()
	_test_save_mid_game()
	completed = true


func check(cond: bool, what: String) -> void:
	t.check(cond, what)


func fresh(seed_value: int = 1) -> void:
	session.new_game(seed_value)
	for i: int in range(6):
		farm.add_plot("field_01/%d" % i)


func step_until(cond: Callable, limit_minutes: int) -> float:
	var start: float = sim.game_minute
	for i: int in range(limit_minutes):
		if cond.call():
			break
		sim.advance(1.0)
	return sim.game_minute - start


# ------------------------------------------------------------------ section 4
func _test_growth() -> void:
	for plant_id: String in ["plant_carrot", "plant_wheat"]:
		fresh()
		var def: Dictionary = data.plant(plant_id)
		var seeds_before: int = inv.count(def["seedItemId"])
		check(farm.action_for(P, def["seedItemId"]) == "till", plant_id + ": an empty plot offers Till")
		check(farm.till(P) and farm.plant(P, plant_id), plant_id + ": till then plant")
		check(inv.count(def["seedItemId"]) == seeds_before - 1, plant_id + ": planting consumes one seed")
		check(farm.water(P) and farm.plot(P)["moisture"] == 100.0, plant_id + ": watering fills moisture")
		var total: float = float(def["growthHours"]) * 60.0
		var entered := {}
		for minute: int in range(1, int(total) + 2):
			sim.advance(1.0)
			var name_: String = farm.stage_name(farm.plot(P))
			if not entered.has(name_):
				entered[name_] = minute
			if farm.plot(P)["state"] == "mature" and not entered.has("harvestable"):
				entered["harvestable"] = minute
		var previous := 0.0
		for stage: Dictionary in def["stages"]:
			if previous > 0.0:
				check(absf(float(entered[stage["name"]]) - previous * total) <= 1.0,
					"%s: stage '%s' starts at its data time (%d vs %.0f)" % [plant_id, stage["name"], entered[stage["name"]], previous * total])
			previous = float(stage["until"])
		check(absf(float(entered["harvestable"]) - total) <= 1.0, plant_id + ": harvestable at its growth time within 1 game minute")
		var xp_before: int = state.player["xp"]
		var got: int = farm.harvest(P)
		check(got == int(def["yield"]["min"]) and inv.count(def["productItemId"]) == got, plant_id + ": harvest gives the data yield")
		check(state.player["xp"] == xp_before + got * int(def["xpPerUnit"]), plant_id + ": harvest XP is units x xpPerUnit")
		check(farm.plot(P)["state"] == "tilled" and farm.plot(P)["plantId"] == null, plant_id + ": a single-harvest crop clears the plot")
		check(farm.harvest(P) == 0, plant_id + ": an empty plot cannot be harvested")


func _test_moisture_and_wither() -> void:
	fresh()
	var def: Dictionary = data.plant("plant_carrot")
	farm.till(P)
	farm.plant(P, "plant_carrot")
	sim.advance(120.0)
	check(farm.plot(P)["growthMinutes"] == 0.0, "growth pauses at 0 moisture")
	check(is_equal_approx(farm.plot(P)["dryMinutes"], 120.0) and farm.plot(P)["everDry"], "the dry timer runs at 0 moisture")
	farm.water(P)
	check(farm.plot(P)["dryMinutes"] == 0.0, "watering resets the dry timer")
	sim.advance(240.0)
	check(is_equal_approx(farm.plot(P)["growthMinutes"], 240.0), "growth resumes when watered")
	check(is_equal_approx(farm.plot(P)["moisture"], 100.0 - 240.0 / (float(def["waterIntervalHours"]) * 60.0) * 100.0), "moisture drains at 100 / waterIntervalHours per hour")
	# a step that runs dry in the middle: only the wet part grows
	farm.plot(P)["moisture"] = 100.0 / (float(def["waterIntervalHours"]) * 60.0) * 10.0     # 10 minutes of water left
	var growth_before: float = farm.plot(P)["growthMinutes"]
	sim.advance(30.0)
	check(is_equal_approx(farm.plot(P)["growthMinutes"], growth_before + 10.0) and is_equal_approx(farm.plot(P)["dryMinutes"], 20.0), "a step that dries out grows only while wet")
	# withers after exactly witherDryHours dry hours
	fresh()
	farm.till(P)
	farm.plant(P, "plant_carrot")
	var limit: float = float(def["witherDryHours"]) * 60.0
	sim.advance(limit - 1.0)
	check(farm.plot(P)["state"] == "growing", "not withered one minute before the dry limit")
	sim.advance(1.0)
	check(farm.plot(P)["state"] == "withered", "withers after exactly %d dry game hours" % int(def["witherDryHours"]))
	check(farm.action_for(P, "seed_carrot") == "clear" and farm.clear(P), "a withered plant can be cleared")
	check(farm.plot(P)["state"] == "tilled" and inv.count("seed_carrot") == 5, "clearing never returns the seed")
	# withers when left unharvested, even if kept watered
	fresh()
	farm.till(P)
	farm.plant(P, "plant_carrot")
	farm.water(P)
	step_until(func() -> bool: return farm.plot(P)["state"] == "mature", 1000)
	var mature_at: float = farm.plot(P)["matureSince"]
	var waited := 0
	while farm.plot(P)["state"] == "mature" and waited < 5000:
		if int(sim.game_minute) % 120 == 0:
			farm.water(P)
		sim.advance(1.0)
		waited += 1
	check(farm.plot(P)["state"] == "withered" and absf(sim.game_minute - mature_at - float(def["witherUnharvestedHours"]) * 60.0) <= 1.0,
		"a Mature crop withers %d hours unharvested" % int(def["witherUnharvestedHours"]))


func _test_regrow() -> void:
	fresh()
	var def: Dictionary = data.plant("plant_tomato")
	inv.add("seed_tomato", 1)
	farm.till(P)
	farm.plant(P, "plant_tomato")
	var harvests := 0
	var times: Array = []
	var start: float = sim.game_minute
	for minute: int in range(4000):
		if int(sim.game_minute) % 180 == 0:
			farm.water(P)
		sim.advance(1.0)
		if farm.plot(P)["state"] == "mature":
			times.append(sim.game_minute - start)
			farm.harvest(P)
			harvests += 1
		if farm.plot(P)["state"] == "tilled":
			break
	check(harvests == int(def["regrow"]["maxHarvests"]), "Tomato regrows %d times, then clears" % (int(def["regrow"]["maxHarvests"]) - 1))
	check(absf(times[0] - float(def["growthHours"]) * 60.0) <= 1.0 and absf(times[1] - times[0] - float(def["regrow"]["hours"]) * 60.0) <= 1.0, "regrowth takes regrow.hours")
	check(inv.count("crop_tomato") == harvests * int(def["yield"]["min"]), "every Tomato harvest yields")


# ------------------------------------------------------------------ section 13
func _test_inventory() -> void:
	fresh()
	var limit := int(data.item("crop_carrot")["stackSize"])
	check(inv.add("crop_carrot", limit * 2 + 52) == 0, "250 carrots fit")
	var sizes: Array = inv.state["backpack"]["stacks"].filter(func(s: Dictionary) -> bool: return s["itemId"] == "crop_carrot").map(func(s: Dictionary) -> int: return s["qty"])
	sizes.sort()
	check(sizes == [52, limit, limit], "stacks split at the stack limit")
	check(inv.remove("crop_carrot", 100) and inv.count("crop_carrot") == limit * 2 - 48, "removal spans stacks")
	check(not inv.remove("crop_carrot", 9999) and inv.count("crop_carrot") == limit * 2 - 48, "removing too many changes nothing")
	inv.add("crop_carrot", 3, 3)
	check(inv.state["backpack"]["stacks"].any(func(s: Dictionary) -> bool: return s["quality"] == 3 and s["qty"] == 3), "quality is part of the stack key")
	inv.remove("crop_carrot", inv.count("crop_carrot") - 2)
	check(inv.count("crop_carrot", 3) == 2 and inv.count("crop_carrot") == 2, "recipes consume the lowest quality first")
	inv.add("mat_stardust", 5)
	inv.add("mat_feed", 4)
	check(inv.count("mat_stardust") == 5 and inv.state["wallet"]["mat_stardust"] == 5, "wallet items take no slot")
	check(inv.state["silo"]["mat_feed"] == 10, "Feed goes to the silo")
	# a backpack that is full refuses the rest and loses nothing
	fresh()
	var slots := int(inv.state["backpack"]["slots"])
	var used: int = inv.state["backpack"]["stacks"].size()
	var left: int = inv.add("crop_wheat", (slots - used) * limit + 7)
	check(left == 7 and inv.room_for("crop_wheat") == 0, "a full backpack returns what did not fit")
	# 10,000 random operations against a plain reference count
	fresh(5)
	var rng := RngStream.new(99)
	var ids := ["crop_carrot", "crop_wheat", "merged_carrot_premium", "seed_carrot", "mat_stardust", "prod_egg"]
	var ref := {}
	for id: String in ids:
		ref[id] = inv.count(id)
	var ok := true
	for i: int in range(10000):
		var id: String = ids[rng.randi_range(0, ids.size() - 1)]
		var qty := rng.randi_range(1, 140)
		if rng.randf() < 0.55:
			ref[id] += qty - inv.add(id, qty)
		elif inv.remove(id, qty):
			ref[id] -= qty
		else:
			ok = ok and ref[id] < qty
		if i % 500 == 0:
			for check_id: String in ids:
				ok = ok and inv.count(check_id) == ref[check_id]
	for id: String in ids:
		ok = ok and inv.count(id) == ref[id]
	for stack: Dictionary in inv.state["backpack"]["stacks"]:
		ok = ok and stack["qty"] >= 1 and stack["qty"] <= int(data.item(stack["itemId"])["stackSize"])
	check(ok and inv.state["backpack"]["stacks"].size() <= slots, "nothing is lost or duplicated in 10,000 random operations")


# ------------------------------------------------------------------ section 6
func _test_merge_maths() -> void:
	fresh()
	state.unlock("merge_carrot_crystal")
	var cfg: Dictionary = data.merge_config
	var by_recipe := {"merge_carrot_premium": "basic", "merge_carrot_golden": "advanced", "merge_carrot_crystal": "rare"}
	for recipe_id: String in by_recipe:
		check(merge.chance(recipe_id)["total"] == float(cfg["baseRate"][by_recipe[recipe_id]]), recipe_id + ": chance is the base rate of its rarity")
	check(merge.fee("merge_carrot_golden") == roundi(float(cfg["feeRatio"]) * 130.0), "the fee is feeRatio x output value")
	state.player["mergePity"]["merge_carrot_crystal"] = 2
	check(merge.chance("merge_carrot_crystal")["total"] == 65.0 + 2 * float(cfg["pityStep"]), "each failure adds pityStep points")
	state.player["mergePity"]["merge_carrot_crystal"] = 7
	check(merge.chance("merge_carrot_crystal")["total"] == 100.0, "pity guarantees a Rare merge on the 8th attempt")
	state.player["mergePity"]["merge_carrot_crystal"] = 0
	state.player["mergeMastery"]["merge_carrot_crystal"] = 14
	check(merge.mastery_points("merge_carrot_crystal") == 2 and merge.chance("merge_carrot_crystal")["total"] == 67.0, "mastery: +1 per 5 successes")
	state.player["mergeMastery"]["merge_carrot_crystal"] = 500
	check(merge.mastery_points("merge_carrot_crystal") == int(cfg["masteryMax"]), "mastery stops at masteryMax")
	check(merge.crit_chance("merge_carrot_crystal") == 10.0, "critical chance is 5% + 1% per mastery point, at most 10%")
	inv.add("lucky_clover", 2)
	state.player["mergeMastery"]["merge_carrot_golden"] = 500
	check(merge.needs_confirmation("merge_carrot_golden", "lucky_clover") and not merge.needs_confirmation("merge_carrot_premium"), "confirmation only below 100% with something precious at stake")
	state.buildings["bld_merge_table"] = 3
	var capped: Dictionary = merge.chance("merge_carrot_golden", "lucky_clover")
	check(capped["total"] == 95.0 and capped["capped"], "modifiers stop at the 95% cap (85 + 5 + 6 + 5 = 101)")
	state.player["mergePity"]["merge_carrot_golden"] = 1
	check(merge.chance("merge_carrot_golden", "lucky_clover")["total"] == 100.0, "pity is added after the cap")
	state.buildings["bld_merge_table"] = 2
	state.player["mergeMastery"]["merge_carrot_crystal"] = 0
	check(merge.chance("merge_carrot_crystal")["total"] == 65.0 + float(cfg["tableBonus"][1]), "a level 2 table adds its bonus")
	var sum := 0.0
	for term: Dictionary in merge.chance("merge_carrot_crystal")["terms"]:
		sum += term["value"]
	check(sum == merge.chance("merge_carrot_crystal")["total"], "the listed terms add up to the displayed percentage")
	inv.add("merged_carrot_golden", 3, 3)
	check(merge.chance("merge_carrot_crystal")["total"] == 65.0 + float(cfg["tableBonus"][1]) + float(cfg["qualityBonus"]["bonus"]), "all inputs at Q3 or better add the quality bonus")
	check(merge.refund_qty(3) == 1 and merge.refund_qty(1) == 1 and merge.refund_qty(5) == 2, "a failure keeps half the inputs, rounded down, at least 1")


func _test_merge_outcomes() -> void:
	fresh(3)
	state.unlock("merge_carrot_crystal")
	# blocked attempts consume nothing
	check(merge.attempt("merge_carrot_premium").is_empty() and merge.blocked_reason("merge_carrot_premium") == "Need 3 more Carrot", "missing ingredients block the merge")
	inv.add("crop_carrot", 3)
	state.player["coins"] = 0
	check(merge.attempt("merge_carrot_premium").is_empty() and inv.count("crop_carrot") == 3, "no coins for the fee: nothing is consumed")
	state.player["coins"] = 100
	var xp_before: int = state.player["xp"]
	var r: Dictionary = merge.attempt("merge_carrot_premium")
	check(r["outcome"] in ["success", "critical"] and inv.count("crop_carrot") == 0 and inv.count("merged_carrot_premium") == r["qty"], "a Basic merge always succeeds")
	check(state.player["coins"] == 100 - merge.fee("merge_carrot_premium") and state.player["xp"] == xp_before + merge.fee("merge_carrot_premium"), "each attempt costs the fee and gives that much XP")
	# find a failure and check exactly what it costs
	state.player["coins"] = 1000000
	var failure := {}
	for i: int in range(200):
		inv.remove("merged_carrot_golden", inv.count("merged_carrot_golden"))
		inv.add("merged_carrot_golden", 3)
		state.player["mergePity"]["merge_carrot_crystal"] = 0
		var dust_before: int = inv.count("mat_stardust")
		var res: Dictionary = merge.attempt("merge_carrot_crystal")
		if res.is_empty():
			check(false, "crystal merge blocked: " + merge.blocked_reason("merge_carrot_crystal"))
			break
		if res["outcome"] == "failure":
			failure = res
			check(inv.count("merged_carrot_golden") == 1 and res["kept"]["merged_carrot_golden"] == 1, "a failed Rare merge keeps 1 of 3 Golden Carrots")
			check(inv.count("mat_stardust") == dust_before + int(data.merge_config["stardustPerFailByTier"]["rare"]), "a failed Rare merge pays 3 Stardust")
			check(merge.pity("merge_carrot_crystal") == 1 and inv.count("merged_carrot_crystal") == dust_before * 0 + inv.count("merged_carrot_crystal"), "a failure raises pity by 1")
			break
	check(not failure.is_empty(), "a Rare merge can fail")
	# pity: the worst case is finite and equals the calculated attempt
	state.player["mergePity"]["merge_carrot_crystal"] = 7
	inv.add("merged_carrot_golden", 3)
	check(merge.attempt("merge_carrot_crystal")["outcome"] != "failure" and merge.pity("merge_carrot_crystal") == 0, "the guaranteed attempt succeeds and resets pity")
	# distribution: the rolled rate equals the displayed rate
	for recipe_id: String in ["merge_carrot_golden", "merge_carrot_crystal"]:
		var input: Dictionary = merge.recipe(recipe_id)["inputs"][0]
		var wins := 0
		var crits := 0
		var n := 100000
		state.player["mergeMastery"][recipe_id] = 0
		var shown: float = merge.chance(recipe_id)["total"]
		for i: int in range(n):
			state.player["mergePity"][recipe_id] = 0
			state.player["mergeMastery"][recipe_id] = 0
			state.player["coins"] = 1000
			inv.state["backpack"]["stacks"] = [{"itemId": input["itemId"], "quality": 1, "qty": int(input["qty"])}]
			var outcome: String = merge.attempt(recipe_id)["outcome"]
			if outcome != "failure":
				wins += 1
			if outcome == "critical":
				crits += 1
		check(absf(wins * 100.0 / n - shown) <= 0.5, "%s: %.2f%% success over 100,000 rolls against %.0f%% shown" % [recipe_id, wins * 100.0 / n, shown])
		check(absf(crits * 100.0 / wins - float(data.merge_config["critBase"])) <= 0.5, recipe_id + ": criticals are 5% of successes")


# ------------------------------------------------------------------ sections 8 and 10
func _test_orders_and_levels() -> void:
	fresh()
	check(state.xp_to_next(1) == 80 and state.xp_to_next(2) == 230 and state.xp_to_next(3) == 420 and state.xp_to_next(10) == 2530, "the level curve matches section 10")
	var board: Array = orders.orders_for("npc_mara")
	check(board.size() == int(data.def("npcs", "npc_mara")["orderRules"]["deliverySlots"]), "Mara shows her delivery slots")
	var first: Dictionary = board[0]
	check(first["rewards"]["coins"] == 42 and first["rewards"]["xp"] == 13 and first["rewards"]["reputation"] == 8, "4 Carrots pay 1.3x value in coins, 0.4x in XP and 8 reputation")
	var coins_before: int = state.coins()
	check(not orders.can_deliver(first) and not orders.deliver(first["orderId"]) and state.coins() == coins_before, "delivery without the goods changes nothing")
	inv.add("crop_carrot", 5)
	var seeds_before: int = inv.count("seed_carrot")
	check(orders.deliver(first["orderId"]), "an order with the goods in stock is delivered")
	check(inv.count("crop_carrot") == 1 and state.coins() == coins_before + 42 and state.player["xp"] == 13, "goods leave, coins and XP arrive")
	check(state.reputation("npc_mara") == 8 and state.reputation_level("npc_mara") == 1 and state.player["stats"]["ordersCompleted"] == 1, "reputation and the order count rise")
	check(inv.count("seed_carrot") == seeds_before + 4, "bonus items are handed over")
	check(orders.orders_for("npc_mara").size() == 1, "the delivered slot is empty while it refills")
	sim.advance(float(data.config["orders"]["refillMinutes"]["completed"]) - 1.0)
	check(orders.orders_for("npc_mara").size() == 1, "the slot is still empty a minute before the refill time")
	sim.advance(1.0)
	check(orders.orders_for("npc_mara").size() == 2, "the slot refills after refillMinutes.completed")
	state.add_xp(80 - 13)
	check(state.player["level"] == 2 and state.player["xp"] == 0, "80 XP reaches level 2")
	state.add_xp(230 + 420 + 5)
	check(state.player["level"] == 4 and state.player["xp"] == 5, "XP carries over several levels")
	state.add_reputation("npc_mara", 40)
	check(state.reputation_level("npc_mara") == 2, "40 reputation is relationship level 2")
	# deadlock rule
	fresh()
	check(not orders.check_deadlock(2), "no gift while the player has seeds")
	for id: String in ["seed_carrot", "seed_wheat"]:
		inv.remove(id, inv.count(id))
	state.player["coins"] = 3
	check(orders.check_deadlock(2) and inv.count("seed_carrot") == 6, "a stuck player gets 6 Carrot seeds from Mara")
	inv.remove("seed_carrot", 6)
	check(not orders.check_deadlock(2), "the gift comes once per game day")
	check(orders.check_deadlock(3), "and again the next day if still stuck")


# ------------------------------------------------------------------ M1 objective
func _test_first_loop() -> void:
	fresh(11)
	var start: float = sim.game_minute
	var coins_start: int = state.coins()
	for i: int in range(6):
		var id := "field_01/%d" % i
		check(farm.till(id) and farm.plant(id, "plant_carrot") and farm.water(id), "loop: plot %d planted and watered" % i)
	step_until(func() -> bool: return farm.plot("field_01/5")["state"] == "mature", 2000)
	for i: int in range(6):
		farm.harvest("field_01/%d" % i)
	check(inv.count("crop_carrot") == 12, "loop: 12 Carrots harvested")
	check(not merge.attempt("merge_carrot_premium").is_empty() and inv.count("merged_carrot_premium") >= 1, "loop: 3 Carrots merged into a Premium Carrot")
	var done := 0
	for order: Dictionary in orders.orders_for("npc_mara").duplicate():
		if orders.deliver(order["orderId"]):
			done += 1
	check(done == 2, "loop: both of Mara's first orders delivered")
	check(state.coins() > coins_start and state.player["xp"] > 0 and state.reputation("npc_mara") == 16, "loop: coins, XP and reputation earned")
	var real_minutes: float = (sim.game_minute - start) / 60.0 * float(data.config["time"]["realSecondsPerGameHour"]) / 60.0
	check(real_minutes <= 10.0, "loop: Plant -> Grow -> Harvest -> Merge -> Order -> Reward fits in 10 real minutes (%.1f)" % real_minutes)
	check(inv.count("seed_carrot") >= 6, "loop: the rewards include seeds for the next round")


func _test_save_mid_game() -> void:
	fresh(21)
	farm.till(P)
	farm.plant(P, "plant_carrot")
	farm.water(P)
	sim.advance(200.0)
	inv.add("crop_carrot", 7)
	var before: String = JSON.stringify(save.build_envelope())
	check(save.save(8) == OK, "mid-game save is written")
	fresh(99)
	check(save.load_slot(8) == OK and JSON.stringify(save.build_envelope()) == before, "plots and inventory survive save and load exactly")
	sim.advance(160.0)
	check(farm.plot(P)["state"] == "mature", "a loaded crop keeps growing to maturity")
	for suffix: String in ["", ".bak1"]:
		DirAccess.remove_absolute(save.slot_path(8) + suffix)
