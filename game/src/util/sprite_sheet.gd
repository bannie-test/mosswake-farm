class_name SpriteSheet
extends RefCounted
## Builds engine resources from the exported sheets and their JSON sidecars (Appendix A, "Export").

static func sidecar(png_path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(png_path.get_basename() + ".json")
	if text.is_empty():
		return {}
	return JSON.parse_string(text)


## SpriteFrames for a character, animal or spirit sheet: one horizontal strip, tags in the sidecar.
static func frames(png_path: String) -> SpriteFrames:
	var tex: Texture2D = load(png_path)
	var meta := sidecar(png_path)
	var size := Vector2i(int(meta["frameSize"][0]), int(meta["frameSize"][1]))
	var out := SpriteFrames.new()
	out.remove_animation(&"default")
	for anim: String in meta["animations"]:
		var a: Dictionary = meta["animations"][anim]
		out.add_animation(anim)
		out.set_animation_speed(anim, float(a["fps"]))
		out.set_animation_loop(anim, true)
		for i: int in range(int(a["from"]), int(a["to"]) + 1):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * size.x, 0, size.x, size.y)
			out.add_frame(anim, at)
	return out


## One frame of a strip as a texture (crop stages, icons).
static func frame(png_path: String, index: int, size: Vector2i) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = load(png_path)
	at.region = Rect2(index * size.x, 0, size.x, size.y)
	return at


## A TileSet with one atlas source: every 16x16 cell of the strip becomes a tile at (x, 0).
static func tileset(png_path: String, tile := Vector2i(16, 16)) -> TileSet:
	return tileset_multi([png_path], tile)


## A TileSet with one atlas source per sheet; source IDs follow the order of the paths.
static func tileset_multi(png_paths: Array, tile := Vector2i(16, 16)) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = tile
	for i: int in range(png_paths.size()):
		var tex: Texture2D = load(png_paths[i])
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.texture_region_size = tile
		ts.add_source(src, i)
		for x: int in range(tex.get_width() / tile.x):
			src.create_tile(Vector2i(x, 0))
	return ts


## The 16x16 icon of an item; a neutral placeholder when the art does not exist yet.
static func item_icon(item_id: String) -> Texture2D:
	var path := "res://assets/items/%s.png" % item_id
	if ResourceLoader.exists(path):
		return load(path)
	return load("res://assets/ui/coin.png")
