class_name ResearchScreen
extends Control
## Research Station (GDD section 7): what can be researched and exactly what it will yield, the
## queue, the Gene Fragments held, and blueprints with their creation recipe.

var _goods: VBoxContainer
var _queue: VBoxContainer
var _plans: VBoxContainer
var _title: Label
var _pending := ""          # an item waiting for the "a story needs this" confirmation


func _ready() -> void:
	var parts := UiKit.window("Research Station", Vector2(600, 270))
	add_child(parts[0])
	_title = UiKit.label("")
	parts[1].add_child(_title)
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts[1].add_child(cols)
	_goods = _column(cols, "Research a good (it is used up)", 250)
	_queue = _column(cols, "Queue", 120)
	_plans = _column(cols, "Genes and blueprints", 206)
	Research.changed.connect(_on_changed)
	Inventory.changed.connect(_on_changed)
	GameState.changed.connect(_on_changed)


func _column(parent: HBoxContainer, title: String, width: int) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCHMENT, UiKit.PARCHMENT_DARK, 1, 4))
	parent.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	v.add_child(UiKit.label(title, UiKit.WOOD_LIGHT))
	var body := VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	return body


func open() -> void:
	visible = true
	_pending = ""
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _process(_delta: float) -> void:
	if is_visible_in_tree() and not Research.state["queue"].is_empty() and Engine.get_process_frames() % 20 == 0:
		refresh()


func yield_text(item_id: String) -> String:
	var r: Dictionary = GameData.item(item_id)["research"]
	var parts: Array = []
	if r["geneId"] != null and int(r["fragments"]) > 0:
		var n := Research.fragments_for(item_id, Inventory.lowest_quality_used(item_id, 1))
		parts.append("%d %s%s" % [n, GameData.item(r["geneId"])["name"].trim_suffix(" Fragment") + "s", " (first time x2)" if Research.is_first(item_id) else ""])
	elif Research.is_first(item_id):
		parts.append("reveals a recipe")
	else:
		parts.append("nothing new")
	if int(r["stardust"]) > 0:
		parts.append("%d Stardust" % int(r["stardust"]))
	return "%s. %d h, %d coins" % [", ".join(parts), int(r["hours"]), int(r["coins"])]


func refresh() -> void:
	var st: Dictionary = Research.state
	var thresholds: Array = Research.cfg()["levelThresholds"]
	var next := " (%d / %d)" % [int(st["xp"]), int(thresholds[int(st["level"]) - 1])] if int(st["level"]) - 1 < thresholds.size() else ""
	_title.text = "Research level %d%s    Queue %d of %d    Stardust %d" % [int(st["level"]), next, st["queue"].size(), Research.slots(), Inventory.count("mat_stardust")]
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_goods)
	UiKit.clear(_queue)
	UiKit.clear(_plans)
	var buttons: Array = []
	# goods in stock that can be researched
	var seen := {}
	for stack: Dictionary in Inventory.state["backpack"]["stacks"] + _chest_stacks():
		var item_id: String = stack["itemId"]
		if seen.has(item_id) or not Research.researchable(item_id):
			continue
		seen[item_id] = true
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(SpriteSheet.item_icon(item_id)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.label("%s x%d" % [GameData.item(item_id)["name"], Inventory.count(item_id)]))
		v.add_child(UiKit.label(yield_text(item_id), UiKit.WOOD_LIGHT))
		row.add_child(v)
		var b := Button.new()
		b.set_meta("key", "r/" + item_id)
		var reason := Research.blocked_reason(item_id)
		b.text = "Research" if reason == "" else reason
		b.disabled = reason != ""
		b.pressed.connect(func() -> void: _try_start(item_id))
		row.add_child(b)
		buttons.append(b)
		_goods.add_child(row)
		if _pending == item_id:
			_goods.add_child(UiKit.label("%s is waiting for this. Press Research again to use it anyway." % Quests.reserved_for(item_id), UiKit.RED))
	if seen.is_empty():
		var hint := UiKit.label("Nothing to research yet. Merged goods (Premium and better) and Ancient harvests can be studied.", UiKit.WOOD_LIGHT)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(236, 0)
		_goods.add_child(hint)
	# queue
	for job: Dictionary in st["queue"]:
		var left := maxf(0.0, float(job["readyAt"]) - Sim.game_minute)
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(SpriteSheet.item_icon(job["itemId"])))
		row.add_child(UiKit.label("%s %d:%02d" % ["Making" if job.has("blueprintId") else "Studying", int(left) / 60, int(left) % 60]))
		_queue.add_child(row)
	if st["queue"].is_empty():
		_queue.add_child(UiKit.label("Empty", UiKit.WOOD_LIGHT))
	# genes and blueprints
	for bp_id: String in GameData.ids("blueprints"):
		var bp: Dictionary = Research.blueprint(bp_id)
		var out: Dictionary = GameData.item(bp["creation"]["output"]["itemId"])
		var head := HBoxContainer.new()
		head.add_child(UiKit.icon(SpriteSheet.item_icon(out["id"])))
		head.add_child(UiKit.label(out["name"], UiKit.WOOD_DARK))
		_plans.add_child(head)
		if not Research.has_blueprint(bp_id):
			for cost: Dictionary in bp["fragmentCost"]:
				_plans.add_child(UiKit.label("%s: %d / %d" % [GameData.item(cost["geneId"])["name"] + "s", Inventory.count(cost["geneId"]), int(cost["qty"])],
					UiKit.GREEN if Inventory.count(cost["geneId"]) >= int(cost["qty"]) else UiKit.INK))
			var b := Button.new()
			b.set_meta("key", "u/" + bp_id)
			b.text = "Learn the blueprint"
			b.disabled = not Research.can_unlock(bp_id)
			b.pressed.connect(func() -> void:
				if Research.unlock_blueprint(bp_id):
					Sfx.play("level_up"))
			_plans.add_child(b)
			buttons.append(b)
		else:
			var c: Dictionary = bp["creation"]
			var needs: Array = []
			for input: Dictionary in c["inputs"]:
				needs.append("%d %s (have %d)" % [int(input["qty"]), GameData.item(input["itemId"])["name"], Inventory.count(input["itemId"])])
			var recipe := UiKit.label("Blueprint learned. %d seeds need: %s, %d coins, %d h" % [int(c["output"]["qty"]), ", ".join(needs), int(c["coins"]), int(c["hours"])], UiKit.WOOD_LIGHT)
			recipe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			recipe.custom_minimum_size = Vector2(194, 0)
			_plans.add_child(recipe)
			var b := Button.new()
			b.set_meta("key", "c/" + bp_id)
			var reason := Research.creation_blocked(bp_id)
			b.text = "Create seeds" if reason == "" else reason
			b.disabled = reason != ""
			b.pressed.connect(func() -> void:
				if Research.create(bp_id):
					Sfx.play("plant"))
			_plans.add_child(b)
			buttons.append(b)
	var pick: Button = null
	for b: Button in buttons:
		if not b.disabled and (pick == null or b.get_meta("key") == keep):
			pick = b
	if pick != null:
		UiKit.focus(pick)


func _chest_stacks() -> Array:
	var out: Array = []
	for chest_id: String in Inventory.state["chests"]:
		out += Inventory.state["chests"][chest_id]["stacks"]
	return out


func _try_start(item_id: String) -> void:
	if Quests.would_break(item_id, 1) and _pending != item_id:
		_pending = item_id            # section 10: warn before the last unit a story needs is used up
		refresh()
		return
	_pending = ""
	if Research.start(item_id):
		Sfx.play("ui_click")
