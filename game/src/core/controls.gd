extends Node
## Input actions: keyboard and gamepad (M5). Autoload: Controls.
## Registered in code so the bindings live in one readable place.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"act": [KEY_E, KEY_SPACE],
	"seed_next": [KEY_Q],
	"backpack": [KEY_TAB, KEY_I],
	"close": [KEY_ESCAPE],
}
const PAD_BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"act": [JOY_BUTTON_A],
	"seed_next": [JOY_BUTTON_X],
	"backpack": [JOY_BUTTON_Y],
	"close": [JOY_BUTTON_B, JOY_BUTTON_START],
}
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}
## What to show in prompts for each action, by the device last used.
const LABELS := {"keyboard": {"act": "E", "seed_next": "Q", "backpack": "Tab", "close": "Esc"}, "pad": {"act": "A", "seed_next": "X", "backpack": "Y", "close": "B"}}

signal device_changed

var device := "keyboard"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.4)
		for key: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for button: int in PAD_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
		if PAD_AXES.has(action):
			var ev := InputEventJoypadMotion.new()
			ev.axis = PAD_AXES[action][0]
			ev.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	var now := device
	if event is InputEventKey or event is InputEventMouseButton:
		now = "keyboard"
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		now = "pad"
	if now != device:
		device = now
		device_changed.emit()


func label(action: String) -> String:
	return LABELS[device].get(action, "")
