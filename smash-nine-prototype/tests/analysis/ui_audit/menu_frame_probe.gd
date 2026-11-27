extends SceneTree
## How heavy a menu frame is once its scene is loaded (2026-11-27; the system lead saw test_frontend_flow
## take about 45 ms a frame in headless runs). Loads Main, lets it settle, then times a run of frames on
## the title, the select screen, the options and a running match for comparison, and prints the
## mean and the slowest frame in ms. Headless:
##   <godot> --headless --path smash-nine-prototype -s tests/analysis/ui_audit/menu_frame_probe.gd

const MAIN_SCENE := "res://scenes/Main.tscn"
const FRAMES := 300

func _initialize() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _time(label: String) -> void:
	await _frames(60)
	var slowest := 0
	var last := Time.get_ticks_usec()
	var start := last
	for frame in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		slowest = maxi(slowest, now - last)
		last = now
	print("%-10s mean %6.2f ms   slowest %6.2f ms   over %d frames" % [label, (last - start) / 1000.0 / FRAMES, slowest / 1000.0, FRAMES])

func _run() -> void:
	root.size = Vector2i(1280, 720)
	# The engine's own frame with nothing loaded, for a baseline.
	await _time("empty")
	var load_start := Time.get_ticks_usec()
	change_scene_to_file(MAIN_SCENE)
	await _frames(2)
	print("load      %6.1f ms (scene change to the second frame)" % ((Time.get_ticks_usec() - load_start) / 1000.0))
	var main: Node = current_scene
	var menu: Control = main.hud.frontend
	await _time("title")
	# The title with the tree paused (what stays is what processes through pauses).
	paused = true
	await _time("title-paused")
	paused = false
	var counts := {"nodes": 0, "processing": 0, "physics": 0}
	_count(main, counts)
	print("on the title: %d nodes, %d processing, %d in physics process" % [counts.nodes, counts.processing, counts.physics])
	menu.show_select()
	await _time("select")
	menu.show_options()
	await _time("options")
	menu.show_title()
	main._start_match("frey")
	await _time("match")
	quit()

func _count(node: Node, counts: Dictionary) -> void:
	counts.nodes += 1
	if node.is_processing():
		counts.processing += 1
	if node.is_physics_processing():
		counts.physics += 1
	for child in node.get_children():
		_count(child, counts)
