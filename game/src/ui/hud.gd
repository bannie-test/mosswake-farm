class_name Hud
extends Control
## Always-on HUD (design/specs/m1_ui_wireframes.md): coins, level and XP, clock, the next step,
## the selected seed, the act prompt and toasts.

const TOAST_SECONDS := 2.5
const MAX_TOASTS := 5

var player: Player
var _coins: Label
var _level: Label
var _xp_bar: ProgressBar
var _clock: Label
var _guide: Label
var _seed_icon: TextureRect
var _seed_label: Label
var _prompt_panel: PanelContainer
var _prompt: Label
var _toasts: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# top bar
	var top := PanelContainer.new()
	top.position = Vector2(4, 4)
	add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	row.add_child(UiKit.icon(load("res://assets/ui/coin.png")))
	_coins = UiKit.label("0")
	_coins.custom_minimum_size = Vector2(30, 0)
	row.add_child(_coins)
	_level = UiKit.label("Lv 1")
	row.add_child(_level)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(70, 7)
	_xp_bar.show_percentage = false
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.add_theme_stylebox_override("background", UiKit.box(UiKit.PARCHMENT_DARK, UiKit.WOOD, 1, 0))
	_xp_bar.add_theme_stylebox_override("fill", UiKit.box(UiKit.GREEN, UiKit.WOOD, 1, 0))
	row.add_child(_xp_bar)
	var clock_panel := PanelContainer.new()
	clock_panel.position = Vector2(560, 4)
	add_child(clock_panel)
	_clock = UiKit.label("")
	_clock.custom_minimum_size = Vector2(66, 0)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_panel.add_child(_clock)
	# the next step
	var guide_panel := PanelContainer.new()
	guide_panel.position = Vector2(4, 24)
	guide_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.INK, 0.7), UiKit.WOOD_DARK, 1, 3))
	add_child(guide_panel)
	_guide = UiKit.label("", UiKit.AMBER)
	guide_panel.add_child(_guide)
	# selected seed
	var seed_panel := PanelContainer.new()
	seed_panel.position = Vector2(4, 334)
	add_child(seed_panel)
	var seed_row := HBoxContainer.new()
	seed_panel.add_child(seed_row)
	_seed_icon = UiKit.icon(load("res://assets/items/seed_carrot.png"))
	seed_row.add_child(_seed_icon)
	_seed_label = UiKit.label("")
	seed_row.add_child(_seed_label)
	# act prompt
	_prompt_panel = PanelContainer.new()
	_prompt_panel.position = Vector2(280, 336)
	add_child(_prompt_panel)
	_prompt = UiKit.label("")
	_prompt_panel.add_child(_prompt)
	# toasts
	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(336, 232)          # right-aligned: long messages grow to the left
	_toasts.custom_minimum_size = Vector2(300, 96)
	_toasts.alignment = BoxContainer.ALIGNMENT_END
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)
	GameState.changed.connect(refresh)
	GameState.notice.connect(toast)
	Inventory.changed.connect(refresh)
	Farm.plot_changed.connect(func(_id: String) -> void: refresh())
	Orders.changed.connect(refresh)
	Animals.changed.connect(refresh)
	Controls.device_changed.connect(refresh)
	Spirits.changed.connect(refresh)
	Quests.changed.connect(refresh)
	Research.changed.connect(refresh)


func bind(p: Player) -> void:
	player = p
	player.target_changed.connect(refresh)
	player.seed_changed.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	_clock.text = Sim.clock_text()


func refresh() -> void:
	_coins.text = str(GameState.coins())
	var level: int = GameState.player["level"]
	_level.text = "Lv %d" % level
	_xp_bar.max_value = GameState.xp_to_next(level)
	_xp_bar.value = GameState.player["xp"]
	_xp_bar.tooltip_text = "%d / %d XP" % [GameState.player["xp"], GameState.xp_to_next(level)]
	var lines: Array = []
	var hint := guide_text()
	if hint != "":
		lines.append(hint)
	for e: Dictionary in Quests.active:
		lines.append("%s: %s" % [GameData.def("npcs", Quests.def(e["questId"])["giver"])["name"].get_slice(" ", 0), Quests.step_text(e)])
	_guide.text = "\n".join(lines)
	_guide.get_parent().visible = _guide.text != ""
	if player == null:
		return
	if player.selected_seed == "":
		_seed_icon.visible = false
		_seed_label.text = "No seeds"
	else:
		_seed_icon.visible = true
		_seed_icon.texture = SpriteSheet.item_icon(player.selected_seed)
		var more := "  (%s: next)" % Controls.label("seed_next") if player.seeds_held().size() > 1 else ""
		_seed_label.text = "%s x%d%s" % [GameData.item(player.selected_seed)["name"], Inventory.count(player.selected_seed), more]
	var words := player.prompt()
	_prompt_panel.visible = words != "" and player.control_enabled
	_prompt.text = "[%s] %s" % [Controls.label("act"), words]
	_prompt_panel.reset_size()
	_prompt_panel.position.x = round((640.0 - _prompt_panel.size.x) / 2.0)


## The next step for a new player, worked out from the game state; no text tutorial.
func guide_text() -> String:
	for e: Dictionary in Quests.active:
		if Quests.can_deliver(e["questId"]):       # e.g. Ilse's prompt for the Golden Carrot (M3 risk)
			var step: Dictionary = Quests.current_step(e)
			return "> %s is waiting for your %s: hand it over at the order board" % [GameData.def("npcs", Quests.def(e["questId"])["giver"])["name"].get_slice(" ", 0), GameData.item(step["itemId"])["name"]]
	var late := late_hint()
	if late != "":
		return late
	if GameState.player["level"] >= 4:
		return ""
	for order: Dictionary in Orders.orders:
		if Orders.can_deliver(order):
			return "> Deliver your goods at the order board by the gate"
	for order: Dictionary in Orders.orders:
		for line: Dictionary in order["lines"]:
			for recipe_id: String in Merge.known_recipes():
				if Merge.recipe(recipe_id)["output"]["itemId"] == line["itemId"] and Merge.blocked_reason(recipe_id) == "":
					return "> Make a %s at the Merge Table" % GameData.item(line["itemId"])["name"]
	for building_id: String in ["bld_coop", "bld_barn"]:
		if Animals.products_ready(building_id) > 0:
			return "> Collect from your animals at the %s" % GameData.def("buildings", building_id)["name"]
	for a: Dictionary in Animals.animals:
		if a["hunger"] <= 0.0:
			return "> Your animals are hungry: make Feed from Wheat at the Coop"
	if GameState.building_level("bld_merge_table") == 0 and GameState.build_blocked("bld_merge_table") == "":
		return "> You can build the Merge Table now: look for its sign"
	var dry := false
	var growing := false
	for plot_id: String in Farm.plots:
		var p: Dictionary = Farm.plot(plot_id)
		if p["state"] == "mature":
			return "> Harvest the sparkling crops"
		if p["state"] == "withered":
			return "> Clear the withered plants"
		if Farm.is_planted(p):
			growing = true
			dry = dry or p["moisture"] <= 0.0
	if dry:
		return "> Water your crops: they only grow in wet soil"
	if player != null and player.selected_seed != "":
		for plot_id: String in Farm.plots:
			if Farm.plot(plot_id)["state"] in ["empty", "tilled"]:
				return "> Till the soil and plant your seeds in the field"
	if growing:
		return "> Crops are growing. Check the order board, or buy seeds from Tobin"
	if GameState.coins() >= int(GameData.config["economy"]["deadlock"]["coinsBelow"]):
		return "> Buy seeds at Tobin's cart by the gate"
	return "> Out of seeds and coins: Mara will leave some at dawn"


## Contextual prompts for the later systems. Each is read from the game state, so it shows
## exactly while it applies and never needs a "seen" flag.
func late_hint() -> String:
	for a: Dictionary in Animals.animals:
		if a["hunger"] <= 0.0:
			return "> Your animals are hungry: make Feed from Wheat at the Coop"
	if Research.can_unlock("bp_carrot_ancient"):
		return "> You have enough Carrot genes: learn the blueprint at the Research Station"
	if GameState.building_level("bld_research_station") > 0 and Research.state["researchedOnce"].is_empty() and Research.state["queue"].is_empty():
		for stack: Dictionary in Inventory.state["backpack"]["stacks"]:
			if Research.researchable(stack["itemId"]) and not Quests.would_break(stack["itemId"], 1):
				return "> Study a %s at the Research Station to see what it holds" % GameData.item(stack["itemId"])["name"]
	if Inventory.count("seed_carrot_ancient") > 0 and player != null and player.selected_seed != "seed_carrot_ancient":
		return "> Ancient Carrot seeds are ready: press %s to select them" % Controls.label("seed_next")
	if Spirits.site_open() and Inventory.count(Spirits.HUSK_ITEM) == 0 and Spirits.bench["stage"] == "empty" and Spirits.spirits.is_empty() and Spirits.digs_available() > 0:
		return "> Something sleeps at the dig site, south-east of the gate"
	if Spirits.bench_built() and Inventory.count(Spirits.HUSK_ITEM) > 0:
		return "> Lay the husk on the Spirit Bench"
	for s: Dictionary in Spirits.spirits:
		if s["zone"] == null:
			return "> %s is waiting for a zone: draw one at the Spirit Bench" % s["name"]
		if Spirits.is_drowsy(s):
			return "> %s is drowsy: press Sap at the Spirit Bench before dawn" % s["name"]
	if not Spirits.spirits.is_empty() and Inventory.count("mat_sap") < Spirits.spirits.size():
		return "> No Sap for tomorrow: press some at the Spirit Bench"
	return ""


func toast(text: String) -> void:
	while _toasts.get_child_count() >= MAX_TOASTS:
		var oldest := _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.add_child(UiKit.label(text))
	_toasts.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)
