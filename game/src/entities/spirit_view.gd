class_name SpiritView
extends Node2D
## A Tree Spirit on the map. It only shows what the Spirits system decided; spirits have no
## collision, so they never block the player.

const ANIM := {"walking": "walk_s", "working": "work_s", "resting": "sleep_s"}

var instance_id: String
var _sprite: AnimatedSprite2D


func _init(id: String) -> void:
	instance_id = id
	var s: Dictionary = Spirits.find(id)
	_sprite = WorldLayers.animated("res://assets/%s" % GameData.def("spirits", s["spiritId"])["sprite"], "idle_s")
	add_child(_sprite)


func _process(_delta: float) -> void:
	var s: Dictionary = Spirits.find(instance_id)
	if s.is_empty():
		return
	var tile_pos: Vector2 = Spirits.position_of(instance_id)
	position = (tile_pos * WorldLayers.TILE + Vector2(WorldLayers.TILE / 2, WorldLayers.TILE - 2)).round()
	var anim: String = ANIM.get(s["state"], "idle_s")
	if _sprite.animation != anim:
		_sprite.play(anim)
