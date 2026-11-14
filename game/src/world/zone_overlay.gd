class_name ZoneOverlay
extends Node2D
## Spirit zones show as a faint outline only while the zone tool is held (Appendix A,
## "Readability on a crowded farm").

const EXISTING := Color(0.494, 0.878, 0.761, 0.55)     # spirit glow
const PREVIEW_OK := Color(1.0, 0.914, 0.639, 0.9)
const PREVIEW_BAD := Color(0.851, 0.282, 0.231, 0.9)

var player: Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if player == null or player.zone_spirit == "":
		return
	for s: Dictionary in Spirits.spirits:
		if s["zone"] != null:
			_outline(Spirits.zone_rect(s), EXISTING)
	var r := player.zone_preview()
	_outline(r, PREVIEW_OK if Spirits.zone_blocked(player.zone_spirit, r) == "" else PREVIEW_BAD)


func _outline(tiles: Rect2i, color: Color) -> void:
	var r := Rect2(tiles.position * WorldLayers.TILE, tiles.size * WorldLayers.TILE)
	draw_rect(Rect2(r.position + Vector2(0.5, 0.5), r.size - Vector2(1, 1)), color, false, 1.0)
