extends SceneTree
## Performance bench: the section 20 load (36 plots planted, 12 animals, 1 spirit) in the real scene.
func _initialize() -> void:
	_go()
## CPU seconds this process has used so far (Linux: utime + stime from /proc/self/stat).
func cpu_seconds() -> float:
	var f := FileAccess.open("/proc/self/stat", FileAccess.READ)
	if f == null:
		return -1.0
	var parts := f.get_line().get_slice(") ", 1).split(" ")
	if parts.size() < 13:
		return -1.0
	return (float(parts[11]) + float(parts[12])) / 100.0


func _go() -> void:
	await process_frame
	OS.low_processor_usage_mode = false      # headless sleeps 6.9 ms per frame otherwise, which hides the real cost
	Engine.max_fps = 0
	var e0 := Time.get_ticks_usec()
	var c0 := cpu_seconds()
	for i in 1200:
		await process_frame
	var empty := (Time.get_ticks_usec() - e0) / 1000.0 / 1200
	var empty_cpu := (cpu_seconds() - c0) * 1000.0 / 1200
	var state: Node = root.get_node("GameState")
	var farm: Node = root.get_node("Farm")
	var animals: Node = root.get_node("Animals")
	var spirits: Node = root.get_node("Spirits")
	var inv: Node = root.get_node("Inventory")
	var scene: Node = load("res://scenes/farm.tscn").instantiate()
	root.add_child(scene)
	for i in 5:
		await physics_frame
	state.player["coins"] = 1000000
	state.player["level"] = 10
	while farm.can_buy_field():
		farm.buy_field()
	state.buildings["bld_barn"] = 1
	state.buildings["bld_coop"] = 2
	state.buildings["bld_spirit_bench"] = 1
	for i in 6:
		animals._spawn("animal_chicken", "adult")
	for i in 2:
		animals._spawn("animal_cow", "adult")
		animals._spawn("animal_sheep", "adult")
	inv.add("seed_carrot", 40)
	inv.add("mat_feed", 500)
	inv.add("mat_sap", 50)
	for plot_id in farm.plots:
		farm.till(plot_id)
		farm.plant(plot_id, "plant_carrot")
		farm.water(plot_id)
	spirits.bench["spiritId"] = "spirit_rootling"
	spirits._finish_awakening()
	spirits.set_zone(spirits.spirits[0]["instanceId"], Rect2i(9, 13, 7, 2))
	scene.map.refresh_all()
	animals.changed.emit()
	print("load: %d plots, %d animals, %d spirits" % [farm.plots.size(), animals.animals.size(), spirits.spirits.size()])
	Input.action_press("move_right")
	for i in 60:
		await process_frame
	# wall time per frame with the full load, against the empty-tree pace measured at the start
	var n := 1200
	var c1 := cpu_seconds()
	var t0 := Time.get_ticks_usec()
	var last := t0
	var worst := 0.0
	for i in n:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		if i == 600:
			Input.action_release("move_right")
			Input.action_press("move_left")
	Input.action_release("move_left")
	var loaded := (Time.get_ticks_usec() - t0) / 1000.0 / n
	var loaded_cpu := (cpu_seconds() - c1) * 1000.0 / n
	var cost := maxf(0.0, loaded_cpu - empty_cpu) if c0 >= 0.0 else maxf(0.0, loaded - empty)
	print("BENCH  CPU per frame: empty tree %.3f ms, full load %.3f ms (headless frames are paced at %.1f ms, so CPU time is the honest measure)" % [empty_cpu, loaded_cpu, empty])
	print("BENCH  empty tree %.3f ms per frame; with 36 plots, 12 animals, 1 spirit and the player walking %.3f ms" % [empty, loaded])
	print("BENCH  game logic adds %.3f ms per frame on this machine (60 fps budget 16.67 ms; rendering not included); slowest single frame %.2f ms" % [cost, worst])
	print("BENCH  objects %d, nodes %d" % [Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	quit(0 if cost < 2.0 else 1)
