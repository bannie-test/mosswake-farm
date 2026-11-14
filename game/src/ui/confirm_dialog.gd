class_name ConfirmDialog
extends Control
## A small yes / not-now dialog: building, buying a field, sleeping, starting over.

var _panel: PanelContainer


func ask(title: String, lines: Array, action: String, on_yes: Callable, blocked: String = "") -> void:
	UiKit.clear(self)
	var parts := UiKit.window(title, Vector2(260, 0))
	_panel = parts[0]
	add_child(_panel)
	for line: String in lines:
		var l := UiKit.label(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(248, 0)
		parts[1].add_child(l)
	var row := HBoxContainer.new()
	var yes := Button.new()
	yes.text = action if blocked == "" else blocked
	yes.disabled = blocked != ""
	yes.pressed.connect(func() -> void:
		on_yes.call()
		closed.emit())
	var no := Button.new()
	no.text = "Not now"
	no.pressed.connect(func() -> void: closed.emit())
	row.add_child(yes)
	row.add_child(no)
	parts[1].add_child(row)
	visible = true
	_panel.reset_size()
	_panel.position = ((Vector2(640, 360) - _panel.size) / 2.0).round()
	UiKit.focus(no if blocked != "" else yes)

signal closed


func open() -> void:
	visible = true
