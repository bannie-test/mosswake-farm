class_name ShopScreen
extends Control
## An NPC's shop (shop stock lives on the NPC definition). Locked rows say what unlocks them.

var npc_id := "npc_tobin"
var _list: VBoxContainer
var _title: Label


func _ready() -> void:
	var parts := UiKit.window("Shop", Vector2(360, 230))
	add_child(parts[0])
	_title = UiKit.label("")
	parts[1].add_child(_title)
	_list = VBoxContainer.new()
	parts[1].add_child(_list)
	GameState.changed.connect(_on_changed)
	Inventory.changed.connect(_on_changed)


func open(npc: String) -> void:
	npc_id = npc
	visible = true
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func refresh() -> void:
	var npc: Dictionary = GameData.def("npcs", npc_id)
	_title.text = "%s, %s    You have %d coins" % [npc["name"], npc["role"], GameState.coins()]
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and _list.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_list)
	var first: Button = null
	for entry: Dictionary in Shop.entries(npc_id):
		var row := HBoxContainer.new()
		var is_animal: bool = entry.has("animalId")
		var title: String = GameData.def("animals", entry["animalId"])["species"].capitalize() if is_animal else GameData.item(entry["itemId"])["name"]
		var icon_tex: Texture2D = load("res://assets/ui/heart.png") if is_animal else SpriteSheet.item_icon(entry["itemId"])
		var pic := UiKit.icon(icon_tex)
		pic.custom_minimum_size = Vector2(16, 16)
		row.add_child(pic)
		var name_label := UiKit.label(title)
		name_label.custom_minimum_size = Vector2(110, 0)
		row.add_child(name_label)
		var price := UiKit.label("%d coins" % int(entry["price"]), UiKit.WOOD_LIGHT)
		price.custom_minimum_size = Vector2(54, 0)
		row.add_child(price)
		if not Shop.is_open(entry):
			row.add_child(UiKit.label("Unlocks at: " + Shop.blocked_reason(entry), UiKit.WOOD_LIGHT))
		else:
			for qty: int in ([1] if is_animal else [1, 5]):
				var reason := Shop.blocked_reason(entry, qty)
				var b := Button.new()
				b.set_meta("key", "%s/%d" % [entry["id"], qty])
				b.text = ("Buy" if qty == 1 else "Buy x%d" % qty) if reason == "" or qty > 1 else reason
				b.disabled = reason != ""
				var entry_id: String = entry["id"]
				b.pressed.connect(func() -> void:
					if Shop.buy(npc_id, entry_id, qty):
						Sfx.play("coin"))
				row.add_child(b)
				if not b.disabled and (first == null or b.get_meta("key") == keep):
					first = b
		_list.add_child(row)
	if first != null:
		UiKit.focus(first)
