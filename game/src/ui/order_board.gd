class_name OrderBoard
extends Control
## Order board for one NPC: a card per delivery slot, with what is needed, what is held and what
## the order pays (GDD section 8).

var npc_id := "npc_mara"
var _head: Label
var _rep: Label
var _cards: HBoxContainer


func _ready() -> void:
	var parts := UiKit.window("Orders", Vector2(440, 170))
	add_child(parts[0])
	var top := HBoxContainer.new()
	parts[1].add_child(top)
	_head = UiKit.label("")
	_head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_head)
	_rep = UiKit.label("", UiKit.WOOD_LIGHT)
	top.add_child(_rep)
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts[1].add_child(_cards)
	Orders.changed.connect(_on_changed)
	Inventory.changed.connect(_on_changed)


func open(npc: String) -> void:
	npc_id = npc
	visible = true
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _process(_delta: float) -> void:
	if is_visible_in_tree() and not Orders.slot_refill_at.is_empty() and Engine.get_process_frames() % 20 == 0:
		refresh()


func refresh() -> void:
	var npc: Dictionary = GameData.def("npcs", npc_id)
	_head.text = "%s, %s" % [npc["name"], npc["role"]]
	var level := GameState.reputation_level(npc_id)
	var thresholds: Array = npc["reputationThresholds"]
	var next := " (%d / %d)" % [GameState.reputation(npc_id), int(thresholds[level])] if level < thresholds.size() else ""
	_rep.text = "Reputation %d%s" % [level, next]
	var focused := get_viewport().gui_get_focus_owner()
	var keep_focus := -1
	if focused != null and _cards.is_ancestor_of(focused):
		keep_focus = focused.get_meta("slot", -1)
	UiKit.clear(_cards)
	var first: Button = null
	for slot: int in range(int(npc["orderRules"]["deliverySlots"])):
		var key := "%s/%d" % [npc_id, slot + 1]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(212, 0)
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCHMENT, UiKit.PARCHMENT_DARK, 1, 4))
		var v := VBoxContainer.new()
		card.add_child(v)
		_cards.add_child(card)
		var order: Dictionary = {}
		for o: Dictionary in Orders.orders:
			if o["slot"] == key:
				order = o
		if order.is_empty():
			var wait := float(Orders.slot_refill_at.get(key, Sim.game_minute)) - Sim.game_minute
			v.add_child(UiKit.label("New order in %d:%02d" % [int(wait) / 60, int(wait) % 60], UiKit.WOOD_LIGHT))
			continue
		var missing: Array = []
		for line: Dictionary in order["lines"]:
			var have := Inventory.count(line["itemId"], int(line["minQuality"]))
			var row := HBoxContainer.new()
			row.add_child(UiKit.icon(SpriteSheet.item_icon(line["itemId"])))
			row.add_child(UiKit.label("%s  %d / %d" % [GameData.item(line["itemId"])["name"], mini(have, int(line["qty"])), int(line["qty"])],
				UiKit.INK if have >= int(line["qty"]) else UiKit.RED))
			v.add_child(row)
			if have < int(line["qty"]):
				missing.append("%d %s" % [int(line["qty"]) - have, GameData.item(line["itemId"])["name"]])
		var rewards: Dictionary = order["rewards"]
		v.add_child(UiKit.label("Pays %d coins, %d XP, +%d reputation" % [rewards["coins"], rewards["xp"], rewards["reputation"]], UiKit.GREEN))
		var bonus: Array = []
		for b: Dictionary in rewards["bonusItems"]:
			bonus.append("%d %s" % [int(b["qty"]), GameData.item(b["itemId"])["name"]])
		if not bonus.is_empty():
			v.add_child(UiKit.label("+ " + ", ".join(bonus), UiKit.GREEN))
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(spacer)
		var button := Button.new()
		button.set_meta("slot", slot)
		button.text = "Deliver" if missing.is_empty() else "Need " + ", ".join(missing)
		button.disabled = not missing.is_empty()
		var order_id: String = order["orderId"]
		button.pressed.connect(func() -> void:
			if Orders.deliver(order_id):
				Sfx.play("coin")
				GameState.notice.emit("Delivered! +%d coins" % int(rewards["coins"])))
		v.add_child(button)
		if not button.disabled and (first == null or slot == keep_focus):
			first = button
	if first != null:
		UiKit.focus(first)
