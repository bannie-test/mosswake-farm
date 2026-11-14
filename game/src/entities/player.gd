class_name Player
extends CharacterBody2D
## The farmer: four-way movement on whole pixels, a context action on the faced tile, and the
## selected seed (design/specs/m1_ui_wireframes.md).

signal target_changed
signal opened(kind: String, info: Dictionary)      ## asks the UI to open a screen
signal seed_changed

const FACING_VEC := {"s": Vector2i(0, 1), "n": Vector2i(0, -1), "e": Vector2i(1, 0), "w": Vector2i(-1, 0)}

var map: Node                       # FarmMap: answers target_at(tile)
var facing := "s"
var target: Dictionary = {}
var selected_seed := ""
var control_enabled := true
var _sprite: AnimatedSprite2D
var _speed := 0.0


func _ready() -> void:
	_speed = float(GameData.config["player"]["moveTilesPerSecond"]) * WorldLayers.TILE
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_sprite = WorldLayers.animated("res://assets/characters/player.png", "idle_s")
	add_child(_sprite)
	var shadow := Sprite2D.new()
	shadow.texture = load(WorldLayers.SHADOW)
	shadow.modulate.a = WorldLayers.SHADOW_OPACITY
	shadow.position = Vector2(1, -2)
	shadow.show_behind_parent = true
	add_child(shadow)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()       # 10x6 capsule at the feet (Appendix A, collision)
	capsule.radius = 3.0
	capsule.height = 10.0
	shape.shape = capsule
	shape.rotation = PI / 2
	shape.position = Vector2(0, -3)
	add_child(shape)
	Inventory.changed.connect(_check_seed)
	_check_seed()


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if control_enabled:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = "e" if dir.x > 0 else "w"
		else:
			facing = "s" if dir.y > 0 else "n"
	velocity = dir.normalized() * _speed
	move_and_slide()
	_animate(dir != Vector2.ZERO)
	_update_target()


func _animate(moving: bool) -> void:
	var side := "e" if facing == "w" else facing      # west is east mirrored in engine
	_sprite.flip_h = facing == "w"
	var anim := ("walk_" if moving else "idle_") + side
	if _sprite.animation != anim:
		_sprite.play(anim)


func tile() -> Vector2i:
	return Vector2i(floori(position.x / WorldLayers.TILE), floori((position.y - 3.0) / WorldLayers.TILE))


func _update_target() -> void:
	var found: Dictionary = map.target_at(tile() + FACING_VEC[facing])
	if found.is_empty():
		found = map.target_at(tile())
	if found != target:
		target = found
		target_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not control_enabled:
		return
	if event.is_action_pressed("act"):
		act()
	elif event.is_action_pressed("seed_next"):
		next_seed()
	elif event.is_action_pressed("backpack"):
		opened.emit("backpack", {})


# ---- seeds
func seeds_held() -> Array:
	var out: Array = []
	for stack: Dictionary in Inventory.state["backpack"]["stacks"]:
		if GameData.item(stack["itemId"])["category"] == "seed" and not out.has(stack["itemId"]):
			out.append(stack["itemId"])
	return out


func _check_seed() -> void:
	var held := seeds_held()
	if not held.has(selected_seed):
		selected_seed = held[0] if not held.is_empty() else ""
	seed_changed.emit()
	target_changed.emit()


func next_seed() -> void:
	var held := seeds_held()
	if held.size() > 1:
		selected_seed = held[(held.find(selected_seed) + 1) % held.size()]
		Sfx.play("ui_click")
		seed_changed.emit()
		target_changed.emit()


# ---- the context action
## The words shown next to the act key for the current target, or "" when there is nothing to do.
func prompt() -> String:
	match target.get("kind", ""):
		"plot":
			match Farm.action_for(target["id"], selected_seed):
				"till": return "Till"
				"plant": return "Plant " + GameData.item(selected_seed)["name"].trim_suffix(" Seeds")
				"water": return "Water"
				"harvest": return "Harvest"
				"clear": return "Clear"
			return ""
		"merge_table":
			return "Merge Table"
		"order_board":
			return "Order board"
		"shop":
			return "%s's cart" % GameData.def("npcs", target["npcId"])["name"].get_slice(" ", 0)
		"housing":
			return GameData.def("buildings", target["buildingId"])["name"]
		"bin":
			return "Shipping bin"
		"bed":
			return "Sleep until morning"
		"build_pad":
			return "Build: " + GameData.def("buildings", target["buildingId"])["name"]
		"field_sale":
			return "Buy this field" if Farm.can_buy_field() else ""
	return ""


func act() -> void:
	match target.get("kind", ""):
		"plot":
			var id: String = target["id"]
			match Farm.action_for(id, selected_seed):
				"till":
					Farm.till(id)
					Sfx.play("till")
				"plant":
					Farm.plant(id, Farm.plant_for_seed(selected_seed))
					Sfx.play("plant")
				"water":
					Farm.water(id)
					Sfx.play("water")
				"harvest":
					if Farm.harvest(id) > 0:
						Sfx.play("harvest")
				"clear":
					Farm.clear(id)
					Sfx.play("till")
			target_changed.emit()
		"":
			pass
		_:
			if prompt() != "":
				opened.emit(target["kind"], target)
