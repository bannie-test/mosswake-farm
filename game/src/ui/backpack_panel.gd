class_name BackpackPanel
extends Control
## Backpack screen: 8 columns of slots, icon and count, the focused item's name and value below.

const COLUMNS := 8
var _grid: GridContainer
var _detail: Label
var _wallet: Label


func _ready() -> void:
	var parts := UiKit.window("Backpack", Vector2(232, 150))
	add_child(parts[0])
	var body: VBoxContainer = parts[1]
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	body.add_child(_grid)
	_detail = UiKit.label("")
	body.add_child(_detail)
	_wallet = UiKit.label("", UiKit.WOOD_LIGHT)
	body.add_child(_wallet)
	Inventory.changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_visible_in_tree():
		return
	UiKit.clear(_grid)
	var pack: Dictionary = Inventory.state["backpack"]
	var first: Button = null
	for i: int in range(int(pack["slots"])):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(26, 26)
		slot.add_theme_stylebox_override("normal", UiKit.box(UiKit.PARCHMENT_DARK, UiKit.WOOD_LIGHT, 1, 1))
		if i < pack["stacks"].size():
			var stack: Dictionary = pack["stacks"][i]
			var def: Dictionary = GameData.item(stack["itemId"])
			slot.icon = SpriteSheet.item_icon(stack["itemId"])
			slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			slot.text = str(stack["qty"])
			slot.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			var line := "%s x%d" % [def["name"], stack["qty"]]
			if def["sellable"]:
				line += " - worth %d each" % int(def["baseValue"])
			slot.focus_entered.connect(func() -> void: _detail.text = line)
			slot.mouse_entered.connect(func() -> void: _detail.text = line)
			if first == null:
				first = slot
		_grid.add_child(slot)
	_detail.text = "Empty" if first == null else ""
	var wallet: Array = []
	for item_id: String in Inventory.state["wallet"]:
		if int(Inventory.state["wallet"][item_id]) > 0:
			wallet.append("%s %d" % [GameData.item(item_id)["name"], Inventory.state["wallet"][item_id]])
	_wallet.text = "" if wallet.is_empty() else "Wallet: " + ", ".join(wallet)
	if first != null:
		UiKit.focus(first)


func open() -> void:
	visible = true
	refresh()
