class_name AwakenScene
extends Control
## The short scene at the end of an awakening: the spirit opens its eyes and takes its tool
## (GDD section 9, Stage C). It is the high point of the MVP and gets the screen to itself.

var _sprite: TextureRect
var _lines: VBoxContainer
var _frames: Array = []
var _t := 0.0


func show_for(instance_id: String) -> void:
	UiKit.clear(self)
	var s: Dictionary = Spirits.find(instance_id)
	var def: Dictionary = GameData.def("spirits", s["spiritId"])
	var shade := ColorRect.new()
	shade.color = Color(UiKit.INK, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var parts := UiKit.window("%s the %s" % [s["name"], def["name"]], Vector2(300, 0))
	add_child(parts[0])
	var sheet := "res://assets/%s" % def["sprite"]
	var size := Vector2i(24, 24)
	_frames = [SpriteSheet.frame(sheet, 3, size), SpriteSheet.frame(sheet, 3, size), SpriteSheet.frame(sheet, 0, size), SpriteSheet.frame(sheet, 1, size), SpriteSheet.frame(sheet, 0, size)]
	_sprite = UiKit.icon(_frames[0], 4)
	_sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parts[1].add_child(_sprite)
	_lines = VBoxContainer.new()
	parts[1].add_child(_lines)
	for line: String in [GameData.text("spirit.awaken.line1"), GameData.text("spirit.awaken.line2") % s["name"]]:
		var l := UiKit.label(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(288, 0)
		_lines.add_child(l)
	var ok := Button.new()
	ok.text = "Welcome, %s" % s["name"]
	ok.pressed.connect(func() -> void: closed.emit())
	parts[1].add_child(ok)
	_t = 0.0
	visible = true
	parts[0].reset_size()
	parts[0].position = ((Vector2(640, 360) - parts[0].size) / 2.0).round()
	UiKit.focus(ok)
	Sfx.play("level_up")

signal closed


func open() -> void:
	visible = true


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _frames.is_empty():
		return
	_t += delta
	_sprite.texture = _frames[mini(_frames.size() - 1, int(_t / 0.7))] if _t < 3.5 else _frames[2 + int(_t / 0.4) % 2]
