extends Node
## Input actions (design/specs/m1_ui_wireframes.md). Autoload: Controls.
## Registered in code so the bindings live in one readable place; remapping arrives in M5.

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"act": [KEY_E, KEY_SPACE],
	"seed_next": [KEY_Q],
	"backpack": [KEY_TAB, KEY_I],
	"close": [KEY_ESCAPE],
}


func _ready() -> void:
	for action: String in BINDINGS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in BINDINGS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
