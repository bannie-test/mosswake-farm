class_name MergeScreen
extends Control
## Merge Table screen (GDD section 6, "UI and UX"): recipe list, table, result. The percentage
## shown is the number rolled; every term is listed; the cost of failure is stated up front.

const RESULT_SECONDS := 1.5

var _recipes: VBoxContainer
var _table: VBoxContainer
var _result: VBoxContainer
var _selected := ""
var _charm := ""              ## the lucky item in the charm slot, or ""
var _banner: Label
var _confirm: PanelContainer
var _banner_timer: SceneTreeTimer


func _ready() -> void:
	var parts := UiKit.window("Merge Table", Vector2(560, 250))
	add_child(parts[0])
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts[1].add_child(cols)
	var list := _column(cols, "Recipes", 176)
	var scroll := ScrollContainer.new()               # ten recipes do not fit without scrolling
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 176)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	list.add_child(scroll)
	_recipes = VBoxContainer.new()
	_recipes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipes)
	_table = _column(cols, "Table", 160)
	_result = _column(cols, "Result", 200)
	_banner = UiKit.label("", UiKit.WOOD_DARK)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.custom_minimum_size = Vector2(0, 14)
	parts[1].add_child(_banner)
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
	_banner.text = ""
	var known := Merge.known_recipes()
	if not known.has(_selected):
		_selected = known[0] if not known.is_empty() else ""
	refresh(true)


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh(false)


func refresh(focus_list: bool) -> void:
	UiKit.clear(_recipes)
	UiKit.clear(_table)
	UiKit.clear(_result)
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
	var known := Merge.known_recipes()
	if known.is_empty():
		_recipes.add_child(UiKit.label("No recipes known yet"))
		return
	for recipe_id: String in known:
		var out: Dictionary = GameData.item(Merge.recipe(recipe_id)["output"]["itemId"])
		var b := Button.new()
		b.text = "%s  x%d" % [out["name"], mini(Merge.affordable(recipe_id), 99)]
		b.icon = SpriteSheet.item_icon(out["id"])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.button_pressed = recipe_id == _selected
		b.pressed.connect(func() -> void:
			_selected = recipe_id
			_banner.text = ""
			refresh(true))
		_recipes.add_child(b)
		if recipe_id == _selected and focus_list:
			UiKit.focus(b)
	for recipe_id: String in Merge.unknown_recipes():      # silhouettes, with where to look
		_recipes.add_child(UiKit.label("???  " + Merge.source_hint(recipe_id), UiKit.WOOD_LIGHT))
	if _charm != "" and Inventory.count(_charm) == 0:
		_charm = ""
	_fill_table()
	_fill_result()


func _fill_table() -> void:
	var r := Merge.recipe(_selected)
	for input: Dictionary in r["inputs"]:
		var row := HBoxContainer.new()
		for i: int in range(int(input["qty"])):
			var slot := PanelContainer.new()
			slot.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCHMENT_DARK, UiKit.WOOD_LIGHT, 1, 3))
			var pic := UiKit.icon(SpriteSheet.item_icon(input["itemId"]))
			if Inventory.count(input["itemId"]) <= i:
				pic.modulate = Color(1, 1, 1, 0.3)       # a missing ingredient shows as a ghost
			slot.add_child(pic)
			row.add_child(slot)
		_table.add_child(row)
		var have := Inventory.count(input["itemId"])
		_table.add_child(UiKit.label("%s  %d / %d" % [GameData.item(input["itemId"])["name"], have, int(input["qty"])],
			UiKit.INK if have >= int(input["qty"]) else UiKit.RED))
	_table.add_child(UiKit.label("Uses the lowest quality first", UiKit.WOOD_LIGHT))
	var clovers := Inventory.count("lucky_clover")
	if not Merge.recipe(_selected)["allowLucky"] or clovers == 0:
		_table.add_child(UiKit.label("Charm slot: empty (Tobin sells Clover)", UiKit.WOOD_LIGHT))
	else:
		var charm := Button.new()
		charm.icon = SpriteSheet.item_icon("lucky_clover")
		charm.toggle_mode = true
		charm.button_pressed = _charm != ""
		charm.text = "Clover in the slot (+%d)" % int(GameData.item("lucky_clover")["lucky"]["bonus"]) if _charm != "" else "Use a Clover (have %d)" % clovers
		charm.pressed.connect(func() -> void:
			_charm = "" if _charm != "" else "lucky_clover"
			refresh(false))
		_table.add_child(charm)
		if _charm != "":
			_table.add_child(UiKit.label("Used up by the attempt, win or lose", UiKit.WOOD_LIGHT))


func _fill_result() -> void:
	var r := Merge.recipe(_selected)
	var out: Dictionary = GameData.item(r["output"]["itemId"])
	var head := HBoxContainer.new()
	head.add_child(UiKit.icon(SpriteSheet.item_icon(out["id"]), 2))
	var names := VBoxContainer.new()
	names.add_child(UiKit.label(out["name"]))
	names.add_child(UiKit.label("worth %d" % int(out["baseValue"]), UiKit.WOOD_LIGHT))
	head.add_child(names)
	_result.add_child(head)
	var chance := Merge.chance(_selected, _charm)
	_result.add_child(UiKit.label("%d%%" % int(chance["total"]), UiKit.GREEN if chance["total"] >= 100.0 else UiKit.WOOD_DARK, UiKit.FONT_BIG))
	_result.add_child(UiKit.label(breakdown_text(chance), UiKit.WOOD_LIGHT))
	_result.add_child(UiKit.label("Fee: %d coins" % Merge.fee(_selected)))
	var fail := UiKit.label(failure_text(_selected, chance), UiKit.WOOD_LIGHT)
	fail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fail.custom_minimum_size = Vector2(186, 0)
	_result.add_child(fail)
	if Merge.story_warning(_selected) != "":
		_result.add_child(UiKit.label(Merge.story_warning(_selected), UiKit.RED))
	var reason := Merge.blocked_reason(_selected)
	var buttons := HBoxContainer.new()
	var go := Button.new()
	go.text = "Merge" if reason == "" else reason
	go.disabled = reason != ""
	go.pressed.connect(func() -> void: _try_merge(1))
	buttons.add_child(go)
	var n := Merge.affordable(_selected)
	if reason == "" and chance["total"] >= 100.0 and n > 1:      # Basic merges support "Merge xN"
		var many := Button.new()
		many.text = "Merge x%d" % n
		many.pressed.connect(func() -> void: _try_merge(n))
		buttons.add_child(many)
	_result.add_child(buttons)


## "Base 65 + Clover 5 + Table 3 + Pity 10 = 83%"
static func breakdown_text(chance: Dictionary) -> String:
	var parts: Array = []
	for term: Dictionary in chance["terms"]:
		parts.append("%s %d" % [term["label"], int(term["value"])])
	var text := " + ".join(parts) + " = %d%%" % int(chance["total"])
	if chance["capped"]:
		text += " (modifiers stop at %d)" % int(chance["cap"])
	return text


## "On failure you keep 1 of 3 Golden Carrots and gain 3 Stardust"
static func failure_text(recipe_id: String, chance: Dictionary) -> String:
	if chance["total"] >= 100.0:
		return "Cannot fail"
	var kept: Array = []
	for input: Dictionary in Merge.recipe(recipe_id)["inputs"]:
		kept.append("%d of %d %ss" % [Merge.refund_qty(int(input["qty"])), int(input["qty"]), GameData.item(input["itemId"])["name"]])
	var text := "On failure you keep " + " and ".join(kept)
	var dust := Merge.stardust_on_fail(recipe_id)
	if dust > 0:
		text += " and gain %d Stardust" % dust
	return text


func _try_merge(times: int) -> void:
	if Merge.needs_confirmation(_selected, _charm):
		_ask_confirmation(times)
	else:
		_do_merge(times)


func _ask_confirmation(times: int) -> void:
	_confirm = PanelContainer.new()
	_confirm.position = Vector2(220, 150)
	var v := VBoxContainer.new()
	_confirm.add_child(v)
	var chance := Merge.chance(_selected, _charm)
	v.add_child(UiKit.label("Merge at %d%%?" % int(chance["total"])))
	if Merge.story_warning(_selected) != "":
		v.add_child(UiKit.label(Merge.story_warning(_selected), UiKit.RED))
	v.add_child(UiKit.label(failure_text(_selected, chance), UiKit.WOOD_LIGHT))
	var row := HBoxContainer.new()
	var yes := Button.new()
	yes.text = "Merge"
	yes.pressed.connect(func() -> void: _do_merge(times))
	var no := Button.new()
	no.text = "Not now"
	no.pressed.connect(func() -> void: refresh(true))
	row.add_child(yes)
	row.add_child(no)
	v.add_child(row)
	add_child(_confirm)
	UiKit.focus(no)


func _do_merge(times: int) -> void:
	var made := 0
	var last: Dictionary = {}
	for i: int in range(times):
		var result := Merge.attempt(_selected, _charm)
		if result.is_empty():
			break
		last = result
		made += int(result["qty"])
	if last.is_empty():
		return
	var item_name: String = GameData.item(last["itemId"])["name"]
	match last["outcome"]:
		"failure":
			Sfx.play("merge_fail")       # a soft puff, never a harsh buzzer
			_banner.text = "It did not take this time. " + failure_text(_selected, {"total": 0.0}).replace("On failure you keep", "You kept").replace("and gain", "and gained")
		"critical":
			Sfx.play("merge_success")
			_banner.text = "Critical! +%d %s" % [made, item_name]
		_:
			Sfx.play("merge_success")
			_banner.text = "+%d %s" % [made, item_name]
	GameState.notice.emit(_banner.text if last["outcome"] != "failure" else "Merge failed: ingredients partly kept")
	refresh(true)
