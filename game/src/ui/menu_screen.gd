class_name MenuScreen
extends Control
## Pause menu with the settings: volumes, large text, hold-to-act, fullscreen, new farm, quit.

signal restart_requested
signal closed

var _body: VBoxContainer
var _confirming := false


func _ready() -> void:
	var parts := UiKit.window("Mosswake Farm", Vector2(300, 0))
	add_child(parts[0])
	_body = parts[1]
	parts[0].position = Vector2(170, 60)


func open() -> void:
	visible = true
	_confirming = false
	refresh("resume")


func _slider(label_text: String, key: String) -> void:
	var row := HBoxContainer.new()
	var l := UiKit.label(label_text)
	l.custom_minimum_size = Vector2(120, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.set_meta("key", key)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.1
	s.value = Settings.get_value(key)
	s.custom_minimum_size = Vector2(150, 12)
	s.value_changed.connect(func(v: float) -> void:
		Settings.set_value(key, v)
		if key == "sfx":
			Sfx.play("ui_click"))
	row.add_child(s)
	_body.add_child(row)


func _toggle(label_text: String, key: String, help: String) -> void:
	var b := CheckButton.new()
	b.set_meta("key", key)
	b.text = label_text
	b.tooltip_text = help
	b.button_pressed = Settings.get_value(key)
	b.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	_body.add_child(b)


func refresh(focus_key: String) -> void:
	while _body.get_child_count() > 2:
		var c := _body.get_child(2)
		_body.remove_child(c)
		c.queue_free()
	var resume := Button.new()
	resume.set_meta("key", "resume")
	resume.text = "Back to the farm"
	resume.pressed.connect(func() -> void: closed.emit())
	_body.add_child(resume)
	_body.add_child(UiKit.label("Settings", UiKit.WOOD_LIGHT))
	_slider("Music", "music")
	_slider("Sound effects", "sfx")
	_toggle("Large text", "largeText", "Bigger letters on every screen.")
	_toggle("Hold to keep acting", "holdToAct", "Hold the act key or button to till, plant, water and harvest as you walk.")
	_toggle("Fullscreen", "fullscreen", "")
	_body.add_child(UiKit.label("The game saves itself at dawn, when you sleep and when you quit.", UiKit.WOOD_LIGHT))
	var again := Button.new()
	again.set_meta("key", "new")
	again.text = "Start a new farm..." if not _confirming else "Really replace your saved farm? Press again"
	again.pressed.connect(func() -> void:
		if _confirming:
			restart_requested.emit()
		else:
			_confirming = true
			refresh("new"))
	_body.add_child(again)
	var quit := Button.new()
	quit.set_meta("key", "quit")
	quit.text = "Save and quit"
	quit.pressed.connect(func() -> void:
		Session.autosave()
		get_tree().quit())
	_body.add_child(quit)
	for child: Node in _body.get_children():
		if child is Control and child.get_meta("key", "") == focus_key:
			UiKit.focus(child)
