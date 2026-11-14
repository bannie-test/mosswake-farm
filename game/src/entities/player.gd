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
var zone_spirit := ""                 ## the spirit whose zone is being drawn; "" outside zone mode
var zone_corner: Variant = null       ## first corner tile, once marked
var _sprite: AnimatedSprite2D
var _speed := 0.0
var _hold := 0.0
var _busy := 0.0                     ## seconds left of a one-shot animation (work, celebrate)
var _busy_anim := ""


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
	GameState.leveled_up.connect(func(_level: int) -> void: play_once("celebrate", 0.9))
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
	# hold-to-act (accessibility): keep working the plots you walk past
	if control_enabled and Settings.get_value("holdToAct") and Input.is_action_pressed("act") and zone_spirit == "":
		_hold += _delta
		if _hold >= float(GameData.config["player"]["holdRepeatSeconds"]) and target.get("kind", "") == "plot" and prompt() != "":
			_hold = 0.0
			act()
	else:
		_hold = 0.0
	if zone_spirit != "" and dir != Vector2.ZERO:
		target_changed.emit()


## Play a short one-shot animation: "work" when acting on a plot, "celebrate" on a level-up.
func play_once(action: String, seconds: float) -> void:
	_busy = seconds
	_busy_anim = action


func _animate(moving: bool) -> void:
	var side := "e" if facing == "w" else facing      # west is east mirrored in engine
	_sprite.flip_h = facing == "w"
	var anim := ("walk_" if moving else "idle_") + side
	if _busy > 0.0:
		_busy -= get_physics_process_delta_time()
		var once := _busy_anim + "_" + side
		anim = once if _sprite.sprite_frames.has_animation(once) else _busy_anim + "_s"
		if anim.ends_with("_s") and side != "s":
			_sprite.flip_h = false
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
	if zone_spirit != "":
		if zone_corner == null:
			return "Mark the first corner"
		var r := zone_preview()
		return "Set the zone (%d of %d tiles)" % [r.size.x * r.size.y, Spirits.zone_limit(Spirits.find(zone_spirit))]
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
		"research":
			return "Research Station"
		"chest":
			return "Storage Chest"
		"bench":
			return "Spirit Bench"
		"dig":
			return "Dig site"
		"bed":
			return "Sleep until morning"
		"build_pad":
			return "Build: " + GameData.def("buildings", target["buildingId"])["name"]
		"field_sale":
			return "Buy this field" if Farm.can_buy_field() else ""
	return ""


# ---- the zone tool (section 9, Stage D): walk to one corner, mark it, walk to the other, set
func start_zone_mode(instance_id: String) -> void:
	zone_spirit = instance_id
	zone_corner = null
	target_changed.emit()


func cancel_zone_mode() -> void:
	zone_spirit = ""
	zone_corner = null
	target_changed.emit()


func zone_preview() -> Rect2i:
	var a: Vector2i = zone_corner if zone_corner != null else tile()
	var b := tile()
	return Rect2i(mini(a.x, b.x), mini(a.y, b.y), absi(a.x - b.x) + 1, absi(a.y - b.y) + 1)


func act() -> void:
	if zone_spirit != "":
		if zone_corner == null:
			zone_corner = tile()
			Sfx.play("ui_click")
		else:
			var reason := Spirits.zone_blocked(zone_spirit, zone_preview())
			if reason != "":
				GameState.notice.emit(reason)
				return
			Spirits.set_zone(zone_spirit, zone_preview())
			GameState.notice.emit("%s will tend this zone" % Spirits.find(zone_spirit)["name"])
			Sfx.play("plant")
			cancel_zone_mode()
		target_changed.emit()
		return
	match target.get("kind", ""):
		"plot":
			var id: String = target["id"]
			if Farm.action_for(id, selected_seed) != "":
				play_once("work", 0.35)
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
