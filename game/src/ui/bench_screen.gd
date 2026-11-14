class_name BenchScreen
extends Control
## The Spirit Bench (MVP stand-in for the Alchemy Hut and Spirit Workshop): clean the husk by
## hand, revive it, give it a vocation, then look after the spirit: zone, stamina, skill, Sap.

signal zone_requested(instance_id: String)

var _body: VBoxContainer


func _ready() -> void:
	var parts := UiKit.window("Spirit Bench", Vector2(440, 250))
	add_child(parts[0])
	_body = VBoxContainer.new()
	parts[1].add_child(_body)
	for sig: Signal in [Spirits.changed, Inventory.changed, GameState.changed]:
		sig.connect(func() -> void:
			if is_visible_in_tree():
				refresh())


func open() -> void:
	visible = true
	refresh()


func _process(_delta: float) -> void:
	if is_visible_in_tree() and Engine.get_process_frames() % 20 == 0:
		refresh()


func _text(text: String, color: Color = UiKit.INK) -> void:
	var l := UiKit.label(text, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(426, 0)
	_body.add_child(l)


func _clock(ready_at: Variant) -> String:
	var left := maxf(0.0, float(ready_at) - Sim.game_minute)
	return "%d:%02d" % [int(left) / 60, int(left) % 60]


func refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and _body.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_body)
	var buttons: Array = []
	var add := func(key: String, text: String, blocked: String, action: Callable) -> void:
		var b := Button.new()
		b.set_meta("key", key)
		b.text = text if blocked == "" else blocked
		b.disabled = blocked != ""
		b.pressed.connect(action)
		_body.add_child(b)
		buttons.append(b)
	var bench: Dictionary = Spirits.bench
	match bench["stage"]:
		"empty":
			if Spirits.spirits.is_empty() or Inventory.count(Spirits.HUSK_ITEM) > 0:
				_text("An old stone slab, warm to the touch. A sleeping husk could rest here.")
				add.call("place", "Lay the Dormant Husk on the bench", "" if Inventory.count(Spirits.HUSK_ITEM) > 0 else "You have no husk", func() -> void:
					if Spirits.place_husk():
						Sfx.play("plant"))
		"dormant":
			_text("The husk is caked in old mud. Scrub it clean, patch by patch.")
			var row := HBoxContainer.new()
			var husk := UiKit.icon(load("res://assets/items/spirit_husk_dormant.png"), 3)
			row.add_child(husk)
			var left := int(Spirits.cfg()["cleanScrubs"]) - int(bench["scrubs"])
			for i: int in range(left):
				var patch := Button.new()
				patch.set_meta("key", "scrub%d" % i)
				patch.icon = load("res://assets/ui/mud.png")
				patch.tooltip_text = "Scrub"
				patch.custom_minimum_size = Vector2(22, 22)
				patch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				patch.pressed.connect(func() -> void:
					if Spirits.scrub():
						Sfx.play("scrub"))
				row.add_child(patch)
				buttons.append(patch)
			_body.add_child(row)
		"cleaned":
			var row := HBoxContainer.new()
			row.add_child(UiKit.icon(load("res://assets/ui/husk_clean.png"), 3))
			row.add_child(UiKit.label(GameData.text("spirit.clean.done")))
			_body.add_child(row)
			if Inventory.count("spirit_revival_potion") > 0:
				add.call("revive", "Pour the Revival Potion over it", "", func() -> void:
					if Spirits.revive():
						Sfx.play("merge_success"))
			elif bench["brewReadyAt"] != null:
				_text("The Revival Potion is brewing: %s left." % _clock(bench["brewReadyAt"]), UiKit.WOOD_LIGHT)
			else:
				var c: Dictionary = Spirits.potion_recipe()
				var needs: Array = []
				for input: Dictionary in c["inputs"]:
					needs.append("%d %s" % [int(input["qty"]), GameData.item(input["itemId"])["name"]])
				_text("It needs a Revival Potion: %s, %d coins, %d hours to brew." % [", ".join(needs), int(c["coins"]), int(c["hours"])], UiKit.WOOD_LIGHT)
				add.call("brew", "Brew a Revival Potion", Spirits.brew_blocked(), func() -> void:
					if Spirits.brew():
						Sfx.play("plant"))
		"sprout":
			_text("A Sleeping Sprout. It will wake into whatever vocation you offer it; the choice is yours.")
			for spirit_id: String in Spirits.classes():
				var def: Dictionary = GameData.def("spirits", spirit_id)
				var needs: Array = []
				for input: Dictionary in def["charmRecipe"]["inputs"]:
					needs.append("%d %s" % [int(input["qty"]), GameData.item(input["itemId"])["name"]])
				_text("%s charm: %s, %d coins. A %s waters dry plots in its zone." % [def["name"], ", ".join(needs), int(def["charmRecipe"]["coins"]), def["name"]], UiKit.WOOD_LIGHT)
				add.call("wake/" + spirit_id, "Wake it as a %s" % def["name"], Spirits.charm_blocked(spirit_id), func() -> void:
					if Spirits.start_awakening(spirit_id):
						Sfx.play("merge_success"))
		"awakening":
			_text("The sprout is waking: %s left." % _clock(bench["awakenReadyAt"]))
	# the spirits already awake
	for s: Dictionary in Spirits.spirits:
		var def: Dictionary = GameData.def("spirits", s["spiritId"])
		var lv: Dictionary = Spirits.level_def(s)
		var levels: Array = def["levels"]
		var next_xp := " (%d / %d XP)" % [int(s["skillXp"]), int(levels[int(s["skillLevel"])]["xp"])] if int(s["skillLevel"]) < int(s["skillCap"]) else " (top skill for now)"
		_text("%s the %s  -  skill %d%s" % [s["name"], def["name"], int(s["skillLevel"]), next_xp], UiKit.WOOD_DARK)
		var zone := "no zone yet" if s["zone"] == null else "zone %dx%d" % [int(s["zone"]["w"]), int(s["zone"]["h"])]
		_text("%s, %s (up to %d tiles). Stamina %d of %d. Carrying %d water." % [s["state"].capitalize(), zone, int(lv["zoneTiles"]), int(s["stamina"]), int(lv["stamina"]), int(s["carrying"].get("water", 0))])
		var upkeep: Dictionary = def["upkeep"]
		_text("Drowsy: no Sap this morning, so it works at half speed and learns nothing. It will not leave." if Spirits.is_drowsy(s)
			else "Fed today. Each dawn it shares %d Sap with you. You have %d Sap." % [int(upkeep["qtyPerDay"]), Inventory.count(upkeep["itemId"])],
			UiKit.RED if Spirits.is_drowsy(s) else UiKit.WOOD_LIGHT)
		var id: String = s["instanceId"]
		add.call("zone/" + id, "Draw %s's zone on the farm" % s["name"], "" if GameState.is_unlocked("feature_zone_tool") else "The zone tool comes with the story", func() -> void: zone_requested.emit(id))
	if not Spirits.spirits.is_empty() or Shop.craft_known("craft_sap"):
		var n := Shop.craft_affordable("craft_sap")
		add.call("sap", "Press Sap x%d (6 common crops make 2)" % n, "" if n > 0 and Shop.craft_known("craft_sap") else "Sap needs 6 common crops", func() -> void:
			var made := Shop.craft("craft_sap", 1)
			if made > 0:
				GameState.notice.emit("+%d Sap" % made)
				Sfx.play("water"))
	var pick: Button = null
	for b: Button in buttons:
		if not b.disabled and (pick == null or b.get_meta("key") == keep):
			pick = b
	if pick != null:
		UiKit.focus(pick)
