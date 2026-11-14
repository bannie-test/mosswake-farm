class_name UiRoot
extends CanvasLayer
## Owns the HUD and the screens; one screen at a time; the player stands still while one is open.

signal restart_requested

var hud: Hud
var player: Player
var _root: Control
var _screens: Dictionary = {}
var _open := ""


func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UiKit.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	hud = Hud.new()
	_root.add_child(hud)
	_screens = {"backpack": BackpackPanel.new(), "merge_table": MergeScreen.new(), "order_board": OrderBoard.new(),
		"shop": ShopScreen.new(), "research": ResearchScreen.new(), "chest": ChestScreen.new(), "housing": HousingScreen.new(), "bin": BinScreen.new(), "confirm": ConfirmDialog.new()}
	_screens["bench"] = BenchScreen.new()
	_screens["dig"] = DigScreen.new()
	_screens["awaken"] = AwakenScene.new()
	_screens["confirm"].closed.connect(close)
	_screens["awaken"].closed.connect(close)
	_screens["bench"].zone_requested.connect(func(instance_id: String) -> void:
		close()
		player.start_zone_mode(instance_id)
		GameState.notice.emit("Walk to one corner and press E, then to the opposite corner and press E. Esc cancels."))
	Spirits.awakened.connect(func(instance_id: String) -> void:
		open("awaken", {"instanceId": instance_id}))
	for key: String in _screens:
		var screen: Control = _screens[key]
		screen.set_anchors_preset(Control.PRESET_FULL_RECT)
		screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen.visible = false
		_root.add_child(screen)


func bind(p: Player) -> void:
	player = p
	hud.bind(p)
	p.opened.connect(open)


func open(kind: String, info: Dictionary = {}) -> void:
	close()
	_open = kind
	player.control_enabled = false
	Sfx.play("ui_click")
	match kind:
		"awaken":
			_screens[kind].show_for(info["instanceId"])
		"shop":
			_screens[kind].open(info["npcId"])
		"housing":
			_screens[kind].open(info["buildingId"])
		"build_pad":
			_open = "confirm"
			var id: String = info["buildingId"]
			var def: Dictionary = GameData.def("buildings", id)
			_screens["confirm"].ask("Build the " + def["name"], ["Cost: %d coins. You have %d." % [int(def["levels"][0]["coins"]), GameState.coins()]],
				"Build", func() -> void:
					if GameState.build(id):
						Sfx.play("coin")
						GameState.notice.emit(def["name"] + " built"), GameState.build_blocked(id))
		"field_sale":
			_open = "confirm"
			var cost := Farm.next_field_cost()
			_screens["confirm"].ask("Buy this field", ["6 more plots for %d coins. You have %d." % [cost, GameState.coins()]],
				"Buy", func() -> void:
					if Farm.buy_field():
						Sfx.play("coin")
						GameState.notice.emit("New field bought"), "" if GameState.coins() >= cost else "Need %d coins" % cost)
		"bed":
			_open = "confirm"
			_screens["confirm"].ask("Sleep until morning", ["Time skips to 06:00 and the game is saved. Crops, animals and orders carry on while you sleep."],
				"Sleep", func() -> void:
					Sim.sleep_until_dawn()
					SaveGame.save(Session.slot)
					GameState.notice.emit("Good morning. Game saved."))
		"menu":
			_open = "confirm"
			_screens["confirm"].ask("Mosswake Farm", ["The game saves itself at dawn, when you sleep and when you quit.", "Start over? Your saved farm will be replaced."],
				"Start a new farm", func() -> void: restart_requested.emit())
		_:
			_screens[kind].open()
	hud.refresh()


func close() -> void:
	if _open == "":
		return
	_screens[_open].visible = false
	_open = ""
	player.control_enabled = true
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	hud.refresh()


func is_open() -> bool:
	return _open != ""


func _input(event: InputEvent) -> void:
	if _open == "":
		if event.is_action_pressed("close") and player.zone_spirit != "":
			player.cancel_zone_mode()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("close"):
			open("menu")
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("close") or (event.is_action_pressed("backpack") and _open == "backpack"):
		close()
		get_viewport().set_input_as_handled()
