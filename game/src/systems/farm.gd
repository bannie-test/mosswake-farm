extends Node
## Plots and crops (GDD section 4; spec design/specs/m1_first_playable.md, section 2).
## Autoload: Farm. Each plot is a FarmPlotState dictionary keyed by its plot ID.

signal plot_changed(plot_id: String)
signal harvested(plot_id: String, item_id: String, qty: int)
signal field_bought(field_number: int)

const PLANTED := ["growing", "mature", "regrowing"]

var plots: Dictionary = {}      # plot ID -> FarmPlotState
var fields_owned := 0


func _ready() -> void:
	Sim.register(self)
	SaveGame.register_section("plots", self)


func new_game() -> void:
	plots.clear()
	fields_owned = 0
	for i: int in range(int(GameData.config["newGame"]["fields"])):
		_add_field()


func field_cfg() -> Dictionary:
	return GameData.config["economy"]["fields"]


func _add_field() -> void:
	fields_owned += 1
	for n: int in range(int(field_cfg()["plotsPerField"])):
		add_plot("field_%02d/%d" % [fields_owned, n])


## Cost of the next field: round(baseCost x growth^(n-1)) for the n-th field bought (section 10).
func next_field_cost() -> int:
	var bought := fields_owned - int(GameData.config["newGame"]["fields"])
	return roundi(float(field_cfg()["baseCost"]) * pow(float(field_cfg()["growth"]), bought))


func can_buy_field() -> bool:
	return fields_owned < int(field_cfg()["maxFields"])


func buy_field() -> bool:
	if not can_buy_field() or not GameState.spend_coins(next_field_cost()):
		return false
	_add_field()
	field_bought.emit(fields_owned)
	Orders.fill_slots()
	return true


## Called by the map for every plot of an owned field.
func add_plot(plot_id: String) -> void:
	if not plots.has(plot_id):
		plots[plot_id] = _blank(plot_id)


func _blank(plot_id: String) -> Dictionary:
	return {
		"plotId": plot_id, "plantId": null, "plantedAt": null, "growthMinutes": 0.0, "moisture": 0.0,
		"dryMinutes": 0.0, "everDry": false, "fertilizerItemId": null, "harvestsTaken": 0,
		"matureSince": null, "state": "empty",
	}


func plot(plot_id: String) -> Dictionary:
	return plots[plot_id]


func is_planted(p: Dictionary) -> bool:
	return PLANTED.has(p["state"])


# ------------------------------------------------------------------ simulation
func advance(delta_minutes: float) -> void:
	for plot_id: String in plots:
		var p: Dictionary = plots[plot_id]
		if is_planted(p) and _advance_plot(p, delta_minutes):
			plot_changed.emit(plot_id)


## Returns true when something the player can see changed (stage, state, wet or dry).
func _advance_plot(p: Dictionary, dt: float) -> bool:
	var def: Dictionary = GameData.plant(p["plantId"])
	var before_stage := stage_index(p)
	var before_state: String = p["state"]
	var was_wet: bool = p["moisture"] > 0.0
	# moisture: the wet part of the step grows the crop, the dry part runs the dry timer
	var wet_minutes := dt
	var interval: Variant = def["waterIntervalHours"]
	if interval != null:
		var drain_per_minute := 100.0 / (float(interval) * 60.0)
		wet_minutes = minf(dt, p["moisture"] / drain_per_minute)
		p["moisture"] = maxf(0.0, p["moisture"] - drain_per_minute * dt)
		if p["moisture"] <= 0.000001:
			p["moisture"] = 0.0
	var dry_minutes := dt - wet_minutes
	if dry_minutes > 0.0:
		p["everDry"] = true
		p["dryMinutes"] += dry_minutes
	if p["state"] != "mature" and wet_minutes > 0.0:
		p["growthMinutes"] += wet_minutes
		var total := float(def["growthHours"]) * 60.0
		if p["growthMinutes"] >= total - 0.000001:
			p["growthMinutes"] = total
			p["state"] = "mature"
			p["matureSince"] = Sim.game_minute + wet_minutes
	# withering (pillar 4: only after a full dry day, or two days unharvested)
	if p["dryMinutes"] >= float(def["witherDryHours"]) * 60.0 - 0.000001:
		p["state"] = "withered"
	elif p["state"] == "mature" and before_state == "mature" \
			and Sim.game_minute + dt - float(p["matureSince"]) >= float(def["witherUnharvestedHours"]) * 60.0 - 0.000001:
		p["state"] = "withered"
	return before_stage != stage_index(p) or before_state != p["state"] or was_wet != (p["moisture"] > 0.0)


## 0 seed, 1 sprout, 2 young, 3 growing, 4 mature (the sprite frames of Appendix A).
func stage_index(p: Dictionary) -> int:
	if p["plantId"] == null:
		return -1
	var def: Dictionary = GameData.plant(p["plantId"])
	var fraction: float = p["growthMinutes"] / (float(def["growthHours"]) * 60.0)
	var stages: Array = def["stages"]
	for i: int in range(stages.size()):
		if fraction < float(stages[i]["until"]) - 0.0000001:
			return i
	return stages.size() - 1


func stage_name(p: Dictionary) -> String:
	var i := stage_index(p)
	return "" if i < 0 else GameData.plant(p["plantId"])["stages"][i]["name"]


# ------------------------------------------------------------------ player actions
## What the act key would do on this plot: "till", "plant", "water", "harvest", "clear" or "".
func action_for(plot_id: String, seed_item_id: String) -> String:
	var p: Dictionary = plots[plot_id]
	# watering is offered once the soil has visibly dried a little, not the instant after watering
	var thirsty: bool = p["moisture"] < float(GameData.config["player"]["waterPromptBelow"])
	match p["state"]:
		"empty":
			return "till"
		"withered":
			return "clear"
		"mature":
			return "harvest"
		"tilled":
			if seed_item_id != "" and Inventory.count(seed_item_id) > 0:
				return "plant"
			return "water" if thirsty else ""
	return "water" if thirsty else ""


func till(plot_id: String) -> bool:
	var p: Dictionary = plots[plot_id]
	if p["state"] != "empty":
		return false
	p["state"] = "tilled"
	plot_changed.emit(plot_id)
	return true


func plant_for_seed(seed_item_id: String) -> String:
	for plant_id: String in GameData.ids("plants"):
		if GameData.plant(plant_id)["seedItemId"] == seed_item_id:
			return plant_id
	return ""


func plant(plot_id: String, plant_id: String) -> bool:
	var p: Dictionary = plots[plot_id]
	if p["state"] != "tilled" or not GameData.has_def("plants", plant_id):
		return false
	if not Inventory.remove(GameData.plant(plant_id)["seedItemId"], 1):
		return false
	p["plantId"] = plant_id
	p["plantedAt"] = Sim.game_minute
	p["growthMinutes"] = 0.0
	p["dryMinutes"] = 0.0
	p["everDry"] = false
	p["harvestsTaken"] = 0
	p["matureSince"] = null
	p["state"] = "growing"
	plot_changed.emit(plot_id)
	return true


func water(plot_id: String) -> bool:
	var p: Dictionary = plots[plot_id]
	if p["state"] == "empty" or p["moisture"] >= 100.0:
		return false
	p["moisture"] = 100.0
	p["dryMinutes"] = 0.0          # watering resets the dry timer
	plot_changed.emit(plot_id)
	return true


## Harvest a Mature plot. Returns the units gained, or 0 when nothing happened (not mature, or
## the backpack has no room, in which case nothing is lost).
func harvest(plot_id: String) -> int:
	var p: Dictionary = plots[plot_id]
	if p["state"] != "mature":
		return 0
	var def: Dictionary = GameData.plant(p["plantId"])
	var qty := GameState.stream("harvest").randi_range(int(def["yield"]["min"]), int(def["yield"]["max"]))
	var item_id: String = def["productItemId"]
	if Inventory.room_for(item_id) < qty:
		GameState.notice.emit("Backpack is full")
		return 0
	Inventory.add(item_id, qty)
	GameState.count_produced(item_id, qty)
	GameState.add_xp(qty * int(def["xpPerUnit"]))
	p["harvestsTaken"] += 1
	var regrow: Variant = def["regrow"]
	if regrow != null and (regrow["maxHarvests"] == null or p["harvestsTaken"] < int(regrow["maxHarvests"])):
		p["state"] = "regrowing"
		p["growthMinutes"] = (float(def["growthHours"]) - float(regrow["hours"])) * 60.0
		p["matureSince"] = null
	else:
		_reset(p)
	harvested.emit(plot_id, item_id, qty)
	plot_changed.emit(plot_id)
	return qty


func clear(plot_id: String) -> bool:
	var p: Dictionary = plots[plot_id]
	if p["state"] != "withered":
		return false
	_reset(p)
	plot_changed.emit(plot_id)
	return true


func _reset(p: Dictionary) -> void:
	var moisture: float = p["moisture"]
	var blank := _blank(p["plotId"])
	for key: String in blank:
		p[key] = blank[key]
	p["state"] = "tilled"
	p["moisture"] = moisture


func anything_growing() -> bool:
	for plot_id: String in plots:
		if is_planted(plots[plot_id]):
			return true
	return false


# ------------------------------------------------------------------ save section "plots"
func save_state() -> Array:
	var out: Array = []
	for plot_id: String in plots:
		out.append(plots[plot_id].duplicate(true))
	return out


func load_state(data: Array) -> void:
	plots.clear()
	fields_owned = 0
	for p: Dictionary in data:
		fields_owned = maxi(fields_owned, int(p["plotId"].substr(6, 2)))
	for p: Dictionary in data:
		var copy: Dictionary = p.duplicate(true)
		copy["harvestsTaken"] = int(copy["harvestsTaken"])
		plots[copy["plotId"]] = copy
		plot_changed.emit(copy["plotId"])
