class_name HousingScreen
extends Control
## Coop or Barn: every animal with its stats, petting, collecting, Feed and the upgrade.
## Nothing about an animal is hidden (pillar 3).

var building_id := "bld_coop"
var _body: VBoxContainer
var _title: Label


func _ready() -> void:
	var parts := UiKit.window("Animals", Vector2(560, 250))
	add_child(parts[0])
	_title = UiKit.label("")
	parts[1].add_child(_title)
	_body = VBoxContainer.new()
	parts[1].add_child(_body)
	Animals.changed.connect(_on_changed)
	Inventory.changed.connect(_on_changed)
	GameState.changed.connect(_on_changed)


func open(building: String) -> void:
	building_id = building
	visible = true
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func _process(_delta: float) -> void:
	if is_visible_in_tree() and Engine.get_process_frames() % 30 == 0:
		refresh()


func refresh() -> void:
	var def: Dictionary = GameData.def("buildings", building_id)
	var housed: Array = Animals.housed_in(building_id)
	_title.text = "%s (level %d)    %d of %d places    Feed in the silo: %d" % [def["name"], GameState.building_level(building_id), housed.size(), Animals.capacity(building_id), Inventory.count("mat_feed")]
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and _body.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_body)
	var buttons: Array = []
	var top := HBoxContainer.new()
	var ready := Animals.products_ready(building_id)
	var collect := Button.new()
	collect.set_meta("key", "collect")
	collect.text = "Collect all (%d ready)" % ready
	collect.disabled = ready == 0
	collect.pressed.connect(func() -> void:
		var got: Dictionary = Animals.collect_all(building_id)
		for item_id: String in got:
			GameState.notice.emit("+%d %s" % [got[item_id], GameData.item(item_id)["name"]])
		if not got.is_empty():
			Sfx.play("harvest"))
	top.add_child(collect)
	buttons.append(collect)
	var feed_n := Shop.craft_affordable("craft_feed")
	var feed := Button.new()
	feed.set_meta("key", "feed")
	feed.text = "Make %d Feed" % feed_n if feed_n > 0 else "Feed needs 2 Wheat"
	feed.disabled = feed_n == 0
	feed.pressed.connect(func() -> void:
		var made := Shop.craft("craft_feed", feed_n)
		if made > 0:
			GameState.notice.emit("+%d Feed" % made)
			Sfx.play("plant"))
	top.add_child(feed)
	buttons.append(feed)
	var next := GameState.next_building_level(building_id)
	if not next.is_empty():
		var up := Button.new()
		up.set_meta("key", "upgrade")
		var reason := GameState.build_blocked(building_id)
		up.text = "Upgrade to %d places (%d coins)" % [int(next["effects"]["capacity"]), int(next["coins"])]
		up.tooltip_text = reason
		up.disabled = reason != ""
		up.pressed.connect(func() -> void:
			if GameState.build(building_id):
				Sfx.play("coin"))
		top.add_child(up)
		buttons.append(up)
	_body.add_child(top)
	if housed.is_empty():
		_body.add_child(UiKit.label("No animals yet. Tobin sells them at his cart by the gate.", UiKit.WOOD_LIGHT))
	for a: Dictionary in housed:
		var adef: Dictionary = GameData.def("animals", a["animalId"])
		var row := HBoxContainer.new()
		var who := UiKit.label("%s  %s %s" % [a["name"], a["stage"], adef["species"]])
		who.custom_minimum_size = Vector2(118, 0)
		row.add_child(who)
		var stats := UiKit.label("Fed %d  Happy %d  Health %d" % [int(a["hunger"]), int(a["happiness"]), int(a["health"])],
			UiKit.RED if a["hunger"] <= 0.0 or Animals.is_sick(a) else UiKit.INK)
		stats.custom_minimum_size = Vector2(132, 0)
		row.add_child(stats)
		var product: String = GameData.item(adef["renewable"]["itemId"])["name"]
		var status := "%s ready" % product if Animals.has_product(a) else "%s %d%%" % [product, int(a["productionProgress"] * 100.0)]
		if a["stage"] in ["baby", "juvenile"]:
			status = "growing up"
		elif a["hunger"] <= 0.0:
			status = "hungry: no %s" % product.to_lower()
		elif Animals.is_sick(a):
			status = "sick: needs Feed and rest"
		var st := UiKit.label(status, UiKit.GREEN if Animals.has_product(a) else UiKit.WOOD_LIGHT)
		st.custom_minimum_size = Vector2(110, 0)
		row.add_child(st)
		var pet := Button.new()
		pet.set_meta("key", "pet/" + a["instanceId"])
		var petted: bool = int(a["pettedDay"]) == Sim.day() or a["stage"] == "baby"
		pet.text = "Petted" if int(a["pettedDay"]) == Sim.day() else "Pet"
		pet.disabled = petted
		var instance_id: String = a["instanceId"]
		pet.pressed.connect(func() -> void:
			if Animals.pet(instance_id):
				Sfx.play("ui_click"))
		row.add_child(pet)
		buttons.append(pet)
		_body.add_child(row)
	var pick: Button = null
	for b: Button in buttons:
		if not b.disabled and (pick == null or b.get_meta("key") == keep):
			pick = b
	if pick != null:
		UiKit.focus(pick)
