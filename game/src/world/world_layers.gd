class_name WorldLayers
extends Node2D
## The seven map layers of Appendix A ("Tilemap structure"). Z order and Y-sorting are set in
## world.tscn; this script only wires the tilesets and offers helpers for placing things.

const TILE := 16
const GROUND_SHEET := "res://assets/tiles/farm_ground.png"
const DETAIL_SHEET := "res://assets/tiles/farm_ground_detail.png"
const PLOT_SHEET := "res://assets/tiles/farm_plots.png"
const FIELD_SHEET := "res://assets/tiles/farm_field.png"
const SHADOW := "res://assets/props/shadow_small.png"
const SHADOW_OPACITY := 0.35     # Appendix A: cast shadows are a flat shape at 35% opacity

@onready var backdrop: Node2D = $Backdrop
@onready var ground: TileMapLayer = $Ground
@onready var ground_detail: TileMapLayer = $GroundDetail
@onready var plots: TileMapLayer = $Plots
@onready var objects: TileMapLayer = $Objects
@onready var overhead: Node2D = $Overhead
@onready var weather_light: Node2D = $WeatherLight


func _ready() -> void:
	ground.tile_set = SpriteSheet.tileset(GROUND_SHEET)
	ground_detail.tile_set = SpriteSheet.tileset(DETAIL_SHEET)
	plots.tile_set = SpriteSheet.tileset_multi([PLOT_SHEET, FIELD_SHEET])


## Pixel position of the feet point (bottom-centre) of a tile.
static func feet(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE + TILE / 2, (tile.y + 1) * TILE)


## Add an upright thing to the Y-sorted Objects layer. Its origin is at its feet, bottom-centre.
func add_object(node: Node2D, feet_px: Vector2, with_shadow := false) -> Node2D:
	node.position = feet_px
	objects.add_child(node)
	if with_shadow:
		var sh := Sprite2D.new()
		sh.texture = load(SHADOW)
		sh.modulate.a = SHADOW_OPACITY
		sh.position = Vector2(1, -2)
		sh.z_index = -1
		sh.z_as_relative = true
		sh.show_behind_parent = true
		node.add_child(sh)
	return node


## A still sprite anchored at its feet.
static func upright(texture: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.centered = false
	s.offset = Vector2(-texture.get_width() / 2, -texture.get_height())
	return s


## An animated sprite anchored at its feet.
static func animated(sheet_path: String, animation: String) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteSheet.frames(sheet_path)
	var size: Vector2 = s.sprite_frames.get_frame_texture(animation, 0).get_size()
	s.centered = false
	s.offset = Vector2(-size.x / 2, -size.y)
	s.play(animation)
	return s
