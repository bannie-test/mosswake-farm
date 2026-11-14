class_name OrderBoard
extends Control
## The order board: every met NPC's delivery orders, a card per slot, with what is needed, what
## is held and what the order pays (GDD section 8). Orders can be dismissed without penalty.

const CARD_WIDTH := 196

var _grid: GridContainer
var _story: VBoxContainer


func _ready() -> void:
	var parts := UiKit.window("Order board", Vector2(616, 300))
	add_child(parts[0])
	_story = VBoxContainer.new()
	parts[1].add_child(_story)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts[1].add_child(_grid)
	Orders.changed.connect(_on_changed)
	Inventory.changed.connect(_on_changed)
	Quests.changed.connect(_on_changed)


func open(_npc: String = "") -> void:
	visible = true
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _process(_delta: float) -> void:
	if is_visible_in_tree() and not Orders.slot_refill_at.is_empty() and Engine.get_process_frames() % 20 == 0:
		refresh()


func refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and _grid.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	if focused != null and _story.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_grid)
	UiKit.clear(_story)
	var pick: Button = null
	# story quests: what each NPC is asking for, and the hand-over for deliver steps
	for e: Dictionary in Quests.active:
		var q: Dictionary = Quests.def(e["questId"])
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(load("res://assets/ui/quest.png")))
		var text := UiKit.label("%s - %s: %s" % [GameData.def("npcs", q["giver"])["name"].get_slice(" ", 0), Quests.title(e["questId"]), Quests.step_text(e)], UiKit.WOOD_DARK)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		if Quests.current_step(e)["type"] == "deliver":
			var give := Button.new()
			give.set_meta("key", "story/" + e["questId"])
			give.text = "Hand over"
			give.disabled = not Quests.can_deliver(e["questId"])
			var quest_id: String = e["questId"]
			give.pressed.connect(func() -> void:
				if Quests.deliver(quest_id):
					Sfx.play("level_up"))
			row.add_child(give)
			if not give.disabled and (pick == null or give.get_meta("key") == keep):
				pick = give
		_story.add_child(row)
	if not Orders.board_open():
		_grid.add_child(UiKit.label("No orders yet. Mara will post them here once you have helped her.", UiKit.WOOD_LIGHT))
		if pick != null:
			UiKit.focus(pick)
		return
	var slots := 0
	for npc_id: String in GameData.ids("npcs"):
		if Unlocks.npc_met(npc_id):
			slots = maxi(slots, int(GameData.def("npcs", npc_id)["orderRules"]["deliverySlots"]))
	for slot: int in range(slots):
		for npc_id: String in GameData.ids("npcs"):
			if not Unlocks.npc_met(npc_id):
				continue
			var npc: Dictionary = GameData.def("npcs", npc_id)
			var key := "%s/%d" % [npc_id, slot + 1]
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(CARD_WIDTH, 124)
			card.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCHMENT, UiKit.PARCHMENT_DARK, 1, 4))
			var v := VBoxContainer.new()
			card.add_child(v)
			_grid.add_child(card)
			var level := GameState.reputation_level(npc_id)
			var thresholds: Array = npc["reputationThresholds"]
			var rep := "rep %d (%d/%d)" % [level, GameState.reputation(npc_id), int(thresholds[level])] if level < thresholds.size() else "rep %d" % level
			v.add_child(UiKit.label("%s  -  %s" % [npc["name"].get_slice(" ", 0), rep], UiKit.WOOD_DARK))
			var order: Dictionary = {}
			for o: Dictionary in Orders.orders:
				if o["slot"] == key:
					order = o
			if order.is_empty():
				var wait := maxf(0.0, float(Orders.slot_refill_at.get(key, Sim.game_minute)) - Sim.game_minute)
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
			v.add_child(UiKit.label("Pays %d coins, %d XP, +%d rep" % [rewards["coins"], rewards["xp"], rewards["reputation"]], UiKit.GREEN))
			var spacer := Control.new()
			spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			v.add_child(spacer)
			var row2 := HBoxContainer.new()
			var button := Button.new()
			button.set_meta("key", key)
			button.text = "Deliver" if missing.is_empty() else "Need " + missing[0] + ("..." if missing.size() > 1 else "")
			button.disabled = not missing.is_empty()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			var order_id: String = order["orderId"]
			button.pressed.connect(func() -> void:
				if Orders.deliver(order_id):
					Sfx.play("coin")
					GameState.notice.emit("Delivered! +%d coins" % int(rewards["coins"])))
			row2.add_child(button)
			var skip := Button.new()
			skip.set_meta("key", key + "/skip")
			skip.text = "Skip"
			skip.tooltip_text = "Dismiss this order. A new one comes later; there is no penalty."
			skip.pressed.connect(func() -> void: Orders.dismiss(order_id))
			row2.add_child(skip)
			v.add_child(row2)
			if not button.disabled and (pick == null or key == keep):
				pick = button
			elif pick == null and key + "/skip" == keep:
				pick = skip
	if pick != null:
		UiKit.focus(pick)
