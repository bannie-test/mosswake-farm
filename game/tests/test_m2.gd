extends RefCounted
## M2 tests: animals, shop, shipping bin, fields, buildings, unlocks, the order generator (with
## the fuzz test of section 20), and the full save round trip. Called by run_tests.gd.

var t: SceneTree
var sim: Node
var data: Node
var state: Node
var inv: Node
var farm: Node
var merge: Node
var orders: Node
var animals: Node
var shop: Node
var shipping: Node
var unlocks: Node
var session: Node
var save: Node
var completed := false


func run(tree: SceneTree, root: Node) -> void:
	t = tree
	for pair: Array in [["sim", "Sim"], ["data", "GameData"], ["state", "GameState"], ["inv", "Inventory"], ["farm", "Farm"], ["merge", "Merge"],
			["orders", "Orders"], ["animals", "Animals"], ["shop", "Shop"], ["shipping", "Shipping"], ["unlocks", "Unlocks"], ["session", "Session"], ["save", "SaveGame"]]:
		set(pair[0], root.get_node(pair[1]))
	sim.paused = true
	_test_animals()
	_test_shop_and_crafting()
	_test_shipping()
	_test_fields_and_buildings()
	_test_unlocks()
	_test_generator()
	_test_order_fuzz()
	_test_full_save()
	_test_session_bot()
	completed = true


func check(cond: bool, what: String) -> void:
	t.check(cond, what)


## Mark the story as far along as a farm of this level would be, without playing it.
func story(level: int) -> void:
	var quests: Node = t.root.get_node("Quests")
	quests.active.clear()
	quests.completed.clear()
	for quest_id: String in (["quest_first_harvest", "quest_table_for_two"] if level >= 3 else ["quest_first_harvest"]):
		quests.completed.append(quest_id)
		for id: String in quests.def(quest_id)["rewards"]["unlocks"]:
			state.unlock(id)
	orders.fill_slots()


func hen() -> Dictionary:
	return animals.animals[0]


# ------------------------------------------------------------------ section 5
func _test_animals() -> void:
	session.new_game(1)
	check(animals.animals.size() == 2 and hen()["stage"] == "adult" and hen()["animalId"] == "animal_chicken", "a new game has 2 adult chickens")
	check(animals.capacity("bld_coop") == 4 and animals.free_slots("bld_coop") == 2, "the Coop holds 4 at level 1")
	# production at the data interval when fed and happy
	for a: Dictionary in animals.animals:
		a["happiness"] = 100.0
	inv.add("mat_feed", 50)
	var interval: float = float(data.def("animals", "animal_chicken")["renewable"]["intervalHours"]) * 60.0
	var minutes := 0
	sim.game_minute = 8 * 60.0
	while not animals.has_product(hen()) and minutes < 2000:
		hen()["happiness"] = 100.0
		sim.advance(1.0)
		minutes += 1
	check(absf(minutes - interval) <= 1.0, "a fed, happy chicken lays at its interval (%d min vs %.0f)" % [minutes, interval])
	check(is_equal_approx(animals.productivity(hen()), 1.0), "Productivity is 1.0 at full Happiness and Health")
	hen()["happiness"] = 50.0
	check(is_equal_approx(animals.productivity(hen()), 0.4 + 0.4 * 0.5 + 0.2), "Productivity = 0.4 + 0.4 x Happiness + 0.2 x Health")
	check(animals.collect(hen()["instanceId"]) == 1 and inv.count("prod_egg") == 1 and hen()["productionProgress"] == 0.0, "collecting gives 1 Egg and restarts the timer")
	check(animals.collect(hen()["instanceId"]) == 0, "nothing to collect twice")
	# feeding: 1 Feed per chicken per 8 hours
	session.new_game(1)
	inv.remove("mat_feed", inv.count("mat_feed"))
	inv.add("mat_feed", 20)
	sim.advance(24 * 60.0)
	check(inv.count("mat_feed") == 20 - 2 * 3, "2 chickens eat 6 Feed in a day")
	# production stops at 0 hunger and resumes on feeding; no animal can die
	inv.remove("mat_feed", inv.count("mat_feed"))
	hen()["productionProgress"] = 0.0
	sim.advance(9 * 60.0)
	check(hen()["hunger"] == 0.0 and animals.productivity(hen()) == 0.0, "with no Feed, hunger reaches 0 and Productivity is 0")
	var stalled: float = hen()["productionProgress"]
	sim.advance(3 * 60.0)
	check(hen()["productionProgress"] == stalled, "production stops at 0 hunger")
	sim.advance(20 * 24 * 60.0)
	check(animals.animals.size() == 2 and hen()["health"] == 0.0 and animals.is_sick(hen()), "20 days unfed: the animal is Sick, never dead")
	inv.add("mat_feed", 10)
	sim.advance(60.0)
	check(hen()["hunger"] > 80.0, "it eats as soon as there is Feed")
	sim.advance(8 * 60.0)
	check(not animals.is_sick(hen()) and hen()["productionProgress"] > stalled, "production resumes once fed and healthy")
	# petting, once a day
	var h0: float = hen()["happiness"]
	check(animals.pet(hen()["instanceId"]) and is_equal_approx(hen()["happiness"], minf(100.0, h0 + 15.0)), "petting adds 15 Happiness")
	check(not animals.pet(hen()["instanceId"]), "only once a day")
	# buying: capacity is enforced; babies grow up after 48 hours
	session.new_game(1)
	state.player["coins"] = 1000
	check(shop.buy("npc_tobin", "shop_tobin_chicken") and shop.buy("npc_tobin", "shop_tobin_chicken"), "two more chickens fit")
	check(state.coins() == 700 and animals.animals.size() == 4 and animals.animals[3]["stage"] == "baby", "each costs 150 and arrives as a baby")
	check(not shop.buy("npc_tobin", "shop_tobin_chicken") and animals.buy_blocked("animal_chicken", 150) == "Coop is full" and state.coins() == 700, "housing capacity is enforced")
	check(animals.buy_blocked("animal_cow", 450) == "Needs a Barn", "a cow needs a Barn")
	inv.add("mat_feed", 100)
	sim.advance(47 * 60.0)
	check(animals.animals[3]["stage"] == "juvenile" and animals.animals[3]["productionProgress"] == 0.0, "a juvenile does not produce")
	sim.advance(60.0)
	check(animals.animals[3]["stage"] == "adult", "adult after baby + juvenile hours")


func _test_shop_and_crafting() -> void:
	session.new_game(1)
	var coins: int = state.coins()
	check(shop.buy("npc_tobin", "shop_tobin_seed_carrot", 5) and state.coins() == coins - 20 and inv.count("seed_carrot") == 11, "5 Carrot seeds cost 20 coins")
	check(not shop.buy("npc_tobin", "shop_tobin_seed_tomato") and shop.blocked_reason(shop.entries("npc_tobin")[2]) == "Level 2", "Tomato seeds are locked until level 2")
	check(shop.blocked_reason(shop.entries("npc_tobin")[4]) == "Tobin reputation 2", "Clover needs Tobin reputation 2")
	state.add_reputation("npc_tobin", 40)
	state.player["coins"] = 40
	check(shop.buy("npc_tobin", "shop_tobin_clover") and inv.count("lucky_clover") == 1 and state.coins() == 0, "Clover costs 40 coins at reputation 2")
	check(not shop.buy("npc_tobin", "shop_tobin_seed_wheat") and inv.count("seed_wheat") == 6, "no coins, no purchase")
	inv.add("crop_wheat", 7)
	var feed: int = inv.count("mat_feed")
	check(shop.craft_affordable("craft_feed") == 3 and shop.craft("craft_feed", 10) == 3, "Feed: 2 Wheat make 1")
	check(inv.count("mat_feed") == feed + 3 and inv.count("crop_wheat") == 1, "crafting consumes and produces exactly what the data says")
	# Clover in a merge: +5, consumed on every attempt
	state.buildings["bld_merge_table"] = 1
	story(3)
	state.player["coins"] = 500
	inv.add("merged_carrot_premium", 3)
	check(merge.chance("merge_carrot_golden", "lucky_clover")["total"] == 90.0, "Clover adds 5 points (85 -> 90)")
	merge.attempt("merge_carrot_golden", "lucky_clover")
	check(inv.count("lucky_clover") == 0, "the Clover is used up by the attempt")


func _test_shipping() -> void:
	session.new_game(1)
	inv.add("crop_carrot", 10)
	check(shipping.ship("crop_carrot", 10) and inv.count("crop_carrot") == 0 and shipping.pending_value() == 64, "10 Carrots in the bin are worth 80% of 80")
	check(not shipping.ship("seed_carrot", 1) and not shipping.ship("crop_carrot", 1), "seeds cannot be shipped; nor goods you do not have")
	var coins: int = state.coins()
	sim.game_minute = 5 * 60.0 + 59.0
	sim.advance(1.0)
	check(state.coins() == coins + 64 and shipping.bin.is_empty(), "the bin pays out at dawn")
	check(shipping.value_of("merged_carrot_golden", 5) == 520, "5 Golden Carrots sell at the full bin price")
	check(shipping.value_of("merged_carrot_golden", 7) == roundi(104.0 * (5 + 0.9 + 0.8)), "the 6th and 7th drop by 10% each")
	check(shipping.value_of("merged_carrot_golden", 30) == roundi(104.0 * (5 + 0.9 + 0.8 + 0.7 + 0.6 + 0.5 * 21)), "the price floor is 50%")
	check(shipping.value_of("crop_carrot", 500) == 3200, "tier 1 goods never drop")


func _test_fields_and_buildings() -> void:
	session.new_game(1)
	check(farm.fields_owned == 2 and farm.plots.size() == 12, "2 starting fields, 12 plots")
	var costs: Array = []
	state.player["coins"] = 100000
	while farm.can_buy_field():
		costs.append(farm.next_field_cost())
		farm.buy_field()
	check(costs == [300, 450, 675, 1013], "field costs follow 300 x 1.5^(n-1): %s" % str(costs))
	check(farm.fields_owned == 6 and farm.plots.size() == 36 and not farm.buy_field(), "the MVP farm tops out at 6 fields, 36 plots")
	check(state.coins() == 100000 - 300 - 450 - 675 - 1013, "each field is paid for")
	session.new_game(1)
	state.player["coins"] = 5000
	check(state.build_blocked("bld_merge_table") == "Needs Level 3" and not state.build("bld_merge_table"), "the Merge Table needs level 3")
	state.player["level"] = 3
	check(state.build("bld_merge_table") and state.coins() == 4750 and state.building_level("bld_merge_table") == 1, "it costs 250 coins")
	check(state.build("bld_merge_table") and state.coins() == 2750 and merge.chance("merge_carrot_golden")["total"] == 88.0, "level 2 costs 2,000 and adds 3 points")
	check(state.build_blocked("bld_merge_table") == "Need 8000 coins", "level 3 costs 8,000")
	check(state.build("bld_coop") and animals.capacity("bld_coop") == 8, "the Coop upgrade holds 8")
	state.player["level"] = 4
	check(state.build("bld_barn") and animals.capacity("bld_barn") == 4, "the Barn can be built at level 4 and holds 4")


func _test_unlocks() -> void:
	session.new_game(1)
	check(merge.known_recipes().is_empty(), "no recipes before the Merge Table is built")
	check(unlocks.npc_met("npc_mara") and unlocks.npc_met("npc_tobin") and not unlocks.npc_met("npc_ilse"), "Mara and Tobin are there from the start; Ilse is not")
	state.buildings["bld_merge_table"] = 1
	var known: Array = merge.known_recipes()
	check(known.has("merge_carrot_premium") and known.has("merge_egg_speckled") and not known.has("merge_tomato_premium") and not known.has("merge_cream"), "Basic recipes follow their species' level")
	check(not known.has("merge_sun_bouquet"), "Sun Bouquet waits for Tobin reputation 3")
	state.player["level"] = 6
	state.add_reputation("npc_tobin", 120)
	check(merge.known_recipes().size() == 6, "level, building and reputation open 6 recipes; the other 4 wait for the story and research")
	check(merge.source_hint("merge_carrot_golden") == "Tobin's story" and merge.source_hint("merge_egg_golden") == "Research a Speckled Egg", "unknown recipes say where to look")
	story(3)
	t.root.get_node("Research").state["researchedOnce"] = ["merged_carrot_golden", "merged_tomato_premium", "merged_egg_speckled"]
	check(merge.known_recipes().size() == 10, "with A Table for Two done and three goods researched, all 10 are known")
	check(unlocks.npc_met("npc_ilse"), "Ilse arrives at level 4")
	check(unlocks.item_unlock_level("merged_cream") == 4 and unlocks.item_unlock_level("crop_tomato") == 2 and unlocks.item_unlock_level("merged_carrot_premium") == 3, "goods know the level they unlock at")


# ------------------------------------------------------------------ section 8
func _test_generator() -> void:
	session.new_game(4)
	check(orders.orders.is_empty(), "the board is empty until Mara's first quest is done")
	story(1)
	check(orders.orders.size() == 4, "then it has 2 orders each from Mara and Tobin")
	var again: Array = orders.orders.map(func(o: Dictionary) -> String: return JSON.stringify(o["lines"]))
	session.new_game(4)
	story(1)
	check(again == orders.orders.map(func(o: Dictionary) -> String: return JSON.stringify(o["lines"])), "the same seed generates the same board")
	var seen := {}
	for o: Dictionary in orders.orders_for("npc_mara"):
		for line: Dictionary in o["lines"]:
			check(not seen.has(line["itemId"]), "Mara does not ask for the same good twice: " + line["itemId"])
			seen[line["itemId"]] = true
	check(orders.orders_for("npc_tobin").all(func(o: Dictionary) -> bool: return o["lines"].size() == 1 and int(o["lines"][0]["qty"]) in [4, 5, 6]),
		"Tobin, who likes nothing a level 1 farm makes, falls back to 4-6 of a crop")
	var mara: Dictionary = orders.orders_for("npc_mara")[0]
	var value := 0.0
	for line: Dictionary in mara["lines"]:
		value += int(line["qty"]) * float(data.item(line["itemId"])["baseValue"])
	check(value <= 68.0 * 1.3 and mara["rewards"]["coins"] == roundi(value * 1.3), "a level 1 order stays near its budget of 68 and pays 1.3x")
	var id: String = mara["orderId"]
	check(orders.dismiss(id) and orders.find(id).is_empty() and orders.orders_for("npc_mara").size() == 1, "an order can be dismissed without penalty")
	sim.advance(119.0)
	check(orders.orders_for("npc_mara").size() == 1, "a dismissed slot stays empty for 2 game hours")
	sim.advance(1.0)
	check(orders.orders_for("npc_mara").size() == 2, "then it refills")
	state.player["level"] = 4
	state.leveled_up.emit(4)
	check(orders.orders_for("npc_ilse").size() == 2, "Ilse's orders appear when she arrives")


## A typical farm at each level (section 20: "content unlocked at that level ... typical capacity").
func profile(level: int, seed_value: int) -> void:
	session.new_game(seed_value)
	state.player["level"] = level
	state.player["coins"] = 100000
	for i: int in range([0, 0, 0, 1, 2, 3, 4, 4, 4, 4, 4][level]):
		farm.buy_field()
	if level >= 3:
		state.buildings["bld_merge_table"] = 1
	if level >= 2:
		for i: int in range(2):
			animals._spawn("animal_chicken", "adult")
	if level >= 5:
		state.buildings["bld_barn"] = 1
		for i: int in range(2):
			animals._spawn("animal_cow", "adult")
	if level >= 7:
		for i: int in range(2):
			animals._spawn("animal_sheep", "adult")
	if level >= 6:
		state.add_reputation("npc_tobin", 120)
	state.player["coins"] = 200
	story(level)


func _test_order_fuzz() -> void:
	var per_level := 1000
	for level: int in range(1, 11):
		var made := 0
		var bad: Array = []
		var boards := 0
		var boards_without_easy := 0
		var seed_value := level * 1000
		while made < per_level:
			seed_value += 1
			profile(level, seed_value)
			# typical stock: half a day of each raw good the farm makes
			var can_make: Dictionary = orders.producible()
			for item_id: String in can_make:
				if int(data.item(item_id)["tier"]) == 1:
					inv.add(item_id, int(orders.capacity_per_24h(item_id) * 0.5))
			for round_: int in range(6):
				orders.orders.clear()
				orders.slot_refill_at.clear()
				orders.fill_slots()
				boards += 1
				if not orders.orders.any(func(o: Dictionary) -> bool: return orders.stock_share(o) >= 0.5):
					boards_without_easy += 1
				for o: Dictionary in orders.orders:
					made += 1
					var value := 0.0
					for line: Dictionary in o["lines"]:
						var def: Dictionary = data.item(line["itemId"])
						value += int(line["qty"]) * float(def["baseValue"])
						if not can_make.has(line["itemId"]) or unlocks.item_unlock_level(line["itemId"]) > level or int(def["tier"]) > 2 or int(line["qty"]) < 1:
							bad.append("%s x%d" % [line["itemId"], line["qty"]])
					if orders.expected_production_hours(o) > 24.0:
						bad.append("needs %.1f h" % orders.expected_production_hours(o))
					if o["rewards"]["coins"] != roundi(value * 1.3) or o["rewards"]["xp"] != roundi(value * 0.4) or o["rewards"]["reputation"] != 8:
						bad.append("wrong reward")
					if o["lines"].size() > int(data.def("npcs", o["npcId"])["orderRules"]["maxLines"]):
						bad.append("too many lines")
		check(bad.is_empty(), "level %d: %d generated orders are all completable within 24 game hours (%s)" % [level, made, str(bad.slice(0, 3))])
		check(boards_without_easy == 0, "level %d: every one of %d boards has an order at least half fillable from typical stock" % [level, boards])


# ------------------------------------------------------------------ section 14
func _test_full_save() -> void:
	profile(6, 77)
	farm.till("field_01/0")
	inv.add("seed_tomato", 2)
	farm.plant("field_01/0", "plant_tomato")
	farm.water("field_01/0")
	inv.add("crop_carrot", 30)
	inv.add("merged_carrot_golden", 2, 3)
	shipping.ship("crop_carrot", 5)
	orders.fill_slots()
	orders.dismiss(orders.orders[0]["orderId"])
	animals.pet(animals.animals[0]["instanceId"])
	state.player["coins"] = 2000
	state.build("bld_coop")
	merge.attempt("merge_carrot_premium")
	sim.advance(333.0)
	var envelope: Dictionary = save.build_envelope()
	var before := JSON.stringify(envelope)
	var roll_merge: float = RngStream.new(state.stream("merge").state).randf()
	var roll_orders: float = RngStream.new(state.stream("orders").state).randf()
	check(save.save(7) == OK, "a full M2 save is written")
	session.new_game(5)
	check(save.load_slot(7) == OK, "and loads")
	check(JSON.stringify(save.build_envelope()) == before, "save, quit, load reproduces identical state: plots, animals, orders, bin, buildings, inventory")
	check(state.stream("merge").randf() == roll_merge and state.stream("orders").randf() == roll_orders, "including the random streams")
	check(farm.fields_owned == 6 and animals.animals.size() == 6 and state.building_level("bld_coop") == 2 and shipping.bin["crop_carrot"] == 5, "fields, animals, buildings and the bin are back")
	sim.advance(600.0)
	check(farm.plot("field_01/0")["state"] in ["mature", "growing"] and not orders.orders.is_empty(), "the loaded game keeps running")
	# the envelope is also written out so the Python validator checks it against the JSON Schema
	var fixture := ProjectSettings.globalize_path("res://").path_join("../qa/fixtures/SaveEnvelope.m2_sample.json")
	var f := FileAccess.open(fixture, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(save.whole_numbers_where_whole(envelope), "  ") + "\n")
		f.close()
	for suffix: String in ["", ".bak1"]:
		DirAccess.remove_absolute(save.slot_path(7) + suffix)


# ------------------------------------------------------------------ M2 acceptance: a 60-minute session
## A plain hand-play policy run for 60 real minutes of game time (60 game hours). It reports the
## level reached against the M2 target of level 5-6; it is information for balancing, not a gate.
func _test_session_bot() -> void:
	session.new_game(2026)
	var water_below := 35.0
	inv.add("seed_carrot", 0)
	for hour: int in range(60):
		# chores
		for plot_id: String in farm.plots:
			var p: Dictionary = farm.plot(plot_id)
			if p["state"] == "mature":
				farm.harvest(plot_id)
			if p["state"] == "withered":
				farm.clear(plot_id)
			if p["state"] == "empty":
				farm.till(plot_id)
			if p["state"] == "tilled":
				var plant_id := _bot_pick_plant()
				var seed_id: String = data.plant(plant_id)["seedItemId"]
				if inv.count(seed_id) == 0:
					for entry: Dictionary in shop.entries("npc_tobin"):
						if entry.get("itemId", "") == seed_id:
							shop.buy("npc_tobin", entry["id"])
				farm.plant(plot_id, plant_id)
			if farm.is_planted(p) and p["moisture"] < water_below:
				farm.water(plot_id)
		for building_id: String in ["bld_coop", "bld_barn"]:
			animals.collect_all(building_id)
		for a: Dictionary in animals.animals:
			animals.pet(a["instanceId"])
		var feed_wanted: int = animals.animals.size() * 6
		if inv.count("mat_feed") < feed_wanted:
			shop.craft("craft_feed", feed_wanted - inv.count("mat_feed"))
		# story hand-overs, then orders
		var quests: Node = t.root.get_node("Quests")
		for e: Dictionary in quests.active.duplicate():
			quests.deliver(e["questId"])
		for o: Dictionary in orders.orders.duplicate():
			for line: Dictionary in o["lines"]:
				for recipe_id: String in merge.known_recipes():
					if merge.recipe(recipe_id)["output"]["itemId"] == line["itemId"]:
						while inv.count(line["itemId"]) < int(line["qty"]) and not merge.attempt(recipe_id).is_empty():
							pass
			orders.deliver(o["orderId"])
		# purchases, cheapest useful thing first
		if state.build_blocked("bld_merge_table") == "" and state.building_level("bld_merge_table") == 0:
			state.build("bld_merge_table")
		if farm.can_buy_field() and state.coins() >= farm.next_field_cost() + 60:
			farm.buy_field()
		if animals.free_slots("bld_coop") > 0 and state.coins() >= 150 + 200:
			shop.buy("npc_tobin", "shop_tobin_chicken")
		# ship what no order asks for, keeping Wheat for Feed
		if sim.hour() == 5:
			for stack: Dictionary in inv.state["backpack"]["stacks"].duplicate(true):
				var def: Dictionary = data.item(stack["itemId"])
				var wanted := 12 if stack["itemId"] == "crop_wheat" else 0
				for o: Dictionary in orders.orders:
					for line: Dictionary in o["lines"]:
						if line["itemId"] == stack["itemId"]:
							wanted += int(line["qty"])
				if def["sellable"] and inv.count(stack["itemId"]) > wanted:
					shipping.ship(stack["itemId"], inv.count(stack["itemId"]) - wanted)
		sim.advance(60.0)
	var level: int = state.player["level"]
	print("INFO  60-minute scripted session: level %d, %d coins, %d orders, %d plots, %d animals (M2 target: level 5-6)" %
		[level, state.coins(), state.player["stats"]["ordersCompleted"], farm.plots.size(), animals.animals.size()])
	check(level >= 3 and state.player["stats"]["ordersCompleted"] >= 10, "a 60-minute session makes steady progress (level %d)" % level)


func _bot_pick_plant() -> String:
	var need := {}
	for o: Dictionary in orders.orders:
		for line: Dictionary in o["lines"]:
			need[line["itemId"]] = int(need.get(line["itemId"], 0)) + int(line["qty"])
			for recipe_id: String in merge.known_recipes():
				var r: Dictionary = merge.recipe(recipe_id)
				if r["output"]["itemId"] == line["itemId"]:
					need[r["inputs"][0]["itemId"]] = int(need.get(r["inputs"][0]["itemId"], 0)) + int(line["qty"]) * int(r["inputs"][0]["qty"])
	need["crop_wheat"] = int(need.get("crop_wheat", 0)) + maxi(0, animals.animals.size() * 6 - inv.count("mat_feed")) * 2
	var best := "plant_carrot"
	var best_short := 0
	for plant_id: String in data.ids("plants"):
		var p: Dictionary = data.plant(plant_id)
		if not unlocks.is_met(p["unlock"]):
			continue
		var growing := 0
		for plot_id: String in farm.plots:
			if farm.plot(plot_id)["plantId"] == plant_id:
				growing += int(p["yield"]["min"])
		var short: int = int(need.get(p["productItemId"], 0)) - inv.count(p["productItemId"]) - growing
		if short > best_short:
			best_short = short
			best = plant_id
	return best
