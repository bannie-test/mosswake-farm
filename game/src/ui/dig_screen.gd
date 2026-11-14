class_name DigScreen
extends Control
## The dig site (GDD section 9, Stage A): a grid of soil. One dig clears one tile; every cleared
## tile shows a Root-sense mark, so the player triangulates instead of guessing.

const MARK := {"hot": "HOT", "warm": "warm", "cold": "cold", "husk": "HUSK"}
const TINT := {"hot": Color("f2a33a"), "warm": Color("e0b872"), "cold": Color("a9d0e8"), "husk": Color("7ee0c2")}

var _grid: GridContainer
var _info: Label


func _ready() -> void:
	var parts := UiKit.window("Mossy Hollow", Vector2(330, 290))
	add_child(parts[0])
	_info = UiKit.label("")
	parts[1].add_child(_info)
	var legend := UiKit.label("Root-sense: HOT = something sleeps within 1 tile, warm = within 3, cold = farther.", UiKit.WOOD_LIGHT)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.custom_minimum_size = Vector2(316, 0)
	parts[1].add_child(legend)
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	parts[1].add_child(_grid)
	Spirits.dig_changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())
	Inventory.changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())


func open() -> void:
	visible = true
	refresh()


func refresh() -> void:
	var site: Dictionary = Spirits.site()
	var w := int(site["grid"]["w"])
	var total := w * int(site["grid"]["h"])
	var found: bool = Spirits.dig.get("husksFound", 0) >= int(site["husks"])
	_info.text = "Digs left: %d  (%d in the open kit, %d Dig Kits)%s" % [Spirits.digs_available(), int(Spirits.dig.get("digsLeft", 0)), Inventory.count("tool_dig_kit"),
		"    The husk is found." if found else ""]
	for item_id: String in Spirits.loot_left():
		_info.text += "\n%d %s still buried here." % [Spirits.loot_left()[item_id], GameData.item(item_id)["name"]]
	var focused := get_viewport().gui_get_focus_owner()
	var keep := -1
	if focused != null and _grid.is_ancestor_of(focused):
		keep = focused.get_meta("cell", -1)
	UiKit.clear(_grid)
	_grid.columns = w
	var pick: Button = null
	for cell: int in range(total):
		var b := Button.new()
		b.set_meta("cell", cell)
		b.custom_minimum_size = Vector2(38, 26)
		var mark: String = Spirits.dug_mark(cell)
		if mark == "":
			b.text = ""
			b.add_theme_stylebox_override("normal", UiKit.box(Color("96643c"), UiKit.WOOD, 1, 1))
			b.disabled = Spirits.digs_available() < 1
			b.pressed.connect(func() -> void:
				var result: String = Spirits.dig_tile(cell)
				if result != "":
					Sfx.play("harvest" if result == "husk" or not MARK.has(result) else "dig"))
			if not b.disabled and (pick == null or cell == keep):
				pick = b
		else:
			b.disabled = true
			if MARK.has(mark):
				b.text = MARK[mark]
				b.add_theme_stylebox_override("disabled", UiKit.box(TINT[mark], UiKit.WOOD_LIGHT, 1, 1))
				b.add_theme_color_override("font_disabled_color", UiKit.INK)
			else:
				b.icon = SpriteSheet.item_icon(mark)
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				b.add_theme_stylebox_override("disabled", UiKit.box(TINT[Spirits.warmth(cell)], UiKit.WOOD_LIGHT, 1, 1))
		_grid.add_child(b)
	if pick != null:
		UiKit.focus(pick)
