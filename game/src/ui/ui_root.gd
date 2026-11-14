class_name UiRoot
extends CanvasLayer
## Owns the HUD and the screens; one screen at a time; the player stands still while one is open.

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
	_screens = {"backpack": BackpackPanel.new(), "merge_table": MergeScreen.new(), "order_board": OrderBoard.new()}
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
	if kind == "order_board":
		_screens[kind].open(info.get("npcId", "npc_mara"))
	else:
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
		return
	if event.is_action_pressed("close") or (event.is_action_pressed("backpack") and _open == "backpack"):
		close()
		get_viewport().set_input_as_handled()
