class_name PixelCamera
extends Camera2D
## Follows a target on whole pixels and stops at the map edges (Appendix A, "Camera").

@export var target: Node2D
var map_rect := Rect2i(0, 0, 640, 360)


func _ready() -> void:
	set_map_rect(map_rect)


func set_map_rect(rect: Rect2i) -> void:
	map_rect = rect
	limit_left = rect.position.x
	limit_top = rect.position.y
	limit_right = rect.end.x
	limit_bottom = rect.end.y


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position.round()
