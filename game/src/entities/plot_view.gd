class_name PlotView
extends Node2D
## What the player sees of one plot (GDD section 4, "Player experience"): the stage sprite, a
## moisture ring under the plant, and a sparkle when the crop is Mature.

const CROP_FRAME := Vector2i(16, 32)
const FRAME_HARVESTED := 5
const FRAME_WITHERED := 6
const RING_FULL := Color("6d9fd1")
const RING_LOW := Color("f2a33a")
const LOW_MOISTURE := 30.0          # the level at which a Rootling would water (job_water_plots)

var plot_id: String
var _crop: Sprite2D
var _sparkle: AnimatedSprite2D
var _moisture := 0.0
var _show_ring := false


func _init(id: String) -> void:
	plot_id = id
	_crop = Sprite2D.new()
	_crop.centered = false
	_crop.offset = Vector2(-CROP_FRAME.x / 2, -CROP_FRAME.y)
	add_child(_crop)
	_sparkle = WorldLayers.animated("res://assets/fx/mature_sparkle.png", "sparkle")
	_sparkle.position = Vector2(0, -6)
	_sparkle.visible = false
	add_child(_sparkle)


func refresh() -> void:
	var p: Dictionary = Farm.plot(plot_id)
	var planted: bool = p["plantId"] != null
	_crop.visible = planted
	if planted:
		var frame := FRAME_WITHERED if p["state"] == "withered" else Farm.stage_index(p)
		_crop.texture = SpriteSheet.frame("res://assets/crops/%s.png" % p["plantId"], frame, CROP_FRAME)
	_sparkle.visible = p["state"] == "mature"
	_show_ring = planted and p["state"] != "withered"
	_moisture = p["moisture"]
	queue_redraw()


func _process(_delta: float) -> void:
	if _show_ring:
		var m: float = Farm.plot(plot_id)["moisture"]
		if absf(m - _moisture) >= 2.0:
			_moisture = m
			queue_redraw()


func _draw() -> void:
	if not _show_ring:
		return
	# an ellipse under the plant; the lit part is the share of moisture left
	var steps := 16
	var lit := int(round(_moisture / 100.0 * steps))
	var col := RING_FULL if _moisture >= LOW_MOISTURE else RING_LOW
	for i: int in range(steps):
		if i < lit:
			var a := TAU * i / steps - PI / 2
			var pt := Vector2(round(cos(a) * 6.0), round(sin(a) * 2.5) - 4.0)
			draw_rect(Rect2(pt, Vector2(1, 1)), col)
