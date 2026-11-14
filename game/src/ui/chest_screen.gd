class_name ChestScreen
extends Control
## Storage Chest: move stacks between the backpack and the chest. Stations read from both.

const CHEST := "chest_01"
var _pack: GridContainer
var _chest: GridContainer
var _detail: Label


func _ready() -> void:
	var parts := UiKit.window("Storage Chest", Vector2(520, 250))
	add_child(parts[0])
	parts[1].add_child(UiKit.label("Press a stack to move it. The Merge Table and the Research Station use what is in here too.", UiKit.WOOD_LIGHT))
	var cols := HBoxContainer.new()
	parts[1].add_child(cols)
	_pack = _side(cols, "Backpack")
	_chest = _side(cols, "Chest")
	_detail = UiKit.label("")
	parts[1].add_child(_detail)
	Inventory.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())


func _side(parent: HBoxContainer, title: String) -> GridContainer:
	var v := VBoxContainer.new()
	v.add_child(UiKit.label(title, UiKit.WOOD_DARK))
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	v.add_child(grid)
	parent.add_child(v)
	return grid


func open() -> void:
	visible = true
	refresh()


func refresh() -> void:
	if not Inventory.state["chests"].has(CHEST):
		return
	var first: Button = null
	for side: Array in [[_pack, Inventory.state["backpack"], true], [_chest, Inventory.state["chests"][CHEST], false]]:
		UiKit.clear(side[0])
		var container: Dictionary = side[1]
		for i: int in range(int(container["slots"])):
			var slot := Button.new()
			slot.custom_minimum_size = Vector2(26, 26)
			slot.add_theme_stylebox_override("normal", UiKit.box(UiKit.PARCHMENT_DARK, UiKit.WOOD_LIGHT, 1, 1))
			if i < container["stacks"].size():
				var stack: Dictionary = container["stacks"][i]
				slot.icon = SpriteSheet.item_icon(stack["itemId"])
				slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				slot.text = str(stack["qty"])
				slot.alignment = HORIZONTAL_ALIGNMENT_RIGHT
				var line := "%s x%d" % [GameData.item(stack["itemId"])["name"], stack["qty"]]
				slot.focus_entered.connect(func() -> void: _detail.text = line)
				slot.mouse_entered.connect(func() -> void: _detail.text = line)
				var to_chest: bool = side[2]
				slot.pressed.connect(func() -> void:
					if Inventory.move_stack(CHEST, i, to_chest) > 0:
						Sfx.play("ui_click"))
				if first == null:
					first = slot
			else:
				slot.disabled = true
			side[0].add_child(slot)
	if first != null:
		UiKit.focus(first)
