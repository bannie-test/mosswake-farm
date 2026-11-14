class_name BinScreen
extends Control
## Shipping bin: put surplus goods in; they are paid at the bin rate at dawn (section 10).

var _list: VBoxContainer
var _foot: Label


func _ready() -> void:
	var parts := UiKit.window("Shipping bin", Vector2(380, 230))
	add_child(parts[0])
	var rate := int(float(GameData.config["economy"]["saleRate"]["bin"]) * 100.0)
	parts[1].add_child(UiKit.label("Goods in the bin are paid at dawn, at %d%% of their value. Orders pay more." % rate, UiKit.WOOD_LIGHT))
	_list = VBoxContainer.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts[1].add_child(_list)
	_foot = UiKit.label("")
	parts[1].add_child(_foot)
	Inventory.changed.connect(_on_changed)
	Shipping.changed.connect(_on_changed)


func open() -> void:
	visible = true
	refresh()


func _on_changed() -> void:
	if is_visible_in_tree():
		refresh()


func refresh() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	var keep := ""
	if focused != null and _list.is_ancestor_of(focused):
		keep = focused.get_meta("key", "")
	UiKit.clear(_list)
	var totals := {}
	for stack: Dictionary in Inventory.state["backpack"]["stacks"]:
		if GameData.item(stack["itemId"])["sellable"]:
			totals[stack["itemId"]] = int(totals.get(stack["itemId"], 0)) + int(stack["qty"])
	var pick: Button = null
	for item_id: String in totals:
		var def: Dictionary = GameData.item(item_id)
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(SpriteSheet.item_icon(item_id)))
		var name_label := UiKit.label("%s x%d" % [def["name"], totals[item_id]])
		name_label.custom_minimum_size = Vector2(130, 0)
		row.add_child(name_label)
		var worth := UiKit.label("%d coins for all" % Shipping.value_of(item_id, int(bin_count(item_id)) + int(totals[item_id])) if false else "%d each" % Shipping.value_of(item_id, 1), UiKit.WOOD_LIGHT)
		worth.custom_minimum_size = Vector2(50, 0)
		row.add_child(worth)
		for qty: int in [1, int(totals[item_id])]:
			var b := Button.new()
			b.set_meta("key", "%s/%d" % [item_id, 1 if qty == 1 else 0])
			b.text = "Ship 1" if qty == 1 else "Ship all"
			b.pressed.connect(func() -> void:
				if Shipping.ship(item_id, qty):
					Sfx.play("plant"))
			row.add_child(b)
			if pick == null or b.get_meta("key") == keep:
				pick = b
		_list.add_child(row)
	if totals.is_empty():
		_list.add_child(UiKit.label("Nothing to ship. Harvest crops or collect from your animals first.", UiKit.WOOD_LIGHT))
	var waiting: Array = []
	for item_id: String in Shipping.bin:
		waiting.append("%d %s" % [int(Shipping.bin[item_id]), GameData.item(item_id)["name"]])
	_foot.text = "In the bin: nothing yet" if waiting.is_empty() else "In the bin: %s. Pays %d coins at dawn." % [", ".join(waiting), Shipping.pending_value()]
	if pick != null:
		UiKit.focus(pick)


func bin_count(item_id: String) -> int:
	return int(Shipping.bin.get(item_id, 0))
