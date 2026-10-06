extends SceneTree
## Real B/R input through four bot matches: initial run plus three restarts.

const MAIN_SCENE := "res://scenes/Main.tscn"
const OUT_RELATIVE := "../reports/codex-tester-01"
const KEY_B := 66
const KEY_R := 82

var out_dir := ""
var held: Dictionary = {}
var results: Dictionary = {
	"driver": "real_input_restart",
	"time_scale": 30.0,
	"restart_presses": 0,
	"start_node_counts": [],
	"matches": [],
	"screenshots": []
}

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	var first: Node = load(MAIN_SCENE).instantiate()
	first.match_seed = 7301
	root.add_child(first)
	current_scene = first
	await _process_frames(18)
	Engine.time_scale = 30.0
	for cycle in 4:
		var main: Node = current_scene
		results.start_node_counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		await _shot("%02d_restart_start_%d" % [20 + cycle * 2, cycle])
		await _tap(KEY_B)
		var frames := 0
		while is_instance_valid(main) and not main.match_over and frames < 1200:
			await physics_frame
			frames += 1
		var match_data: Dictionary = {
			"cycle": cycle,
			"seed": main.match_seed if is_instance_valid(main) else -1,
			"frames_at_30x": frames,
			"result_reached": is_instance_valid(main) and main.match_over,
			"elapsed": snappedf(main.director.match_elapsed, 0.1) if is_instance_valid(main) else -1.0,
			"winner": main.get_winner().display_name if is_instance_valid(main) and is_instance_valid(main.get_winner()) else "",
			"reason": main.director.finish_reason if is_instance_valid(main) else "",
			"nodes_at_result": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		}
		results.matches.append(match_data)
		await _shot("%02d_restart_result_%d" % [21 + cycle * 2, cycle])
		if cycle == 3:
			break
		var old_scene: Node = main
		await _tap(KEY_R)
		results.restart_presses = int(results.restart_presses) + 1
		var wait_frames := 0
		while current_scene == old_scene and wait_frames < 180:
			await process_frame
			wait_frames += 1
		await _process_frames(18)
	_release_all()
	Engine.time_scale = 1.0
	results["node_span"] = _node_span(results.start_node_counts)
	results["all_results_reached"] = _all_results_reached()
	_write_json("real_input_restart.json", results)
	print("PLAYTEST_RESULT ", JSON.stringify(results))
	quit(0)

func _all_results_reached() -> bool:
	for match_data in results.matches:
		if not bool(match_data.result_reached):
			return false
	return results.matches.size() == 4

func _node_span(values: Array) -> int:
	if values.is_empty():
		return -1
	var low: int = int(values[0])
	var high: int = low
	for value in values:
		low = mini(low, int(value))
		high = maxi(high, int(value))
	return high - low

func _tap(keycode: int) -> void:
	_set_key(keycode, true)
	await process_frame
	_set_key(keycode, false)
	await process_frame
	await physics_frame

func _set_key(keycode: int, pressed: bool) -> void:
	if bool(held.get(keycode, false)) == pressed:
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = false
	Input.parse_input_event(event)
	held[keycode] = pressed

func _release_all() -> void:
	for keycode in held.keys():
		if bool(held[keycode]):
			var event := InputEventKey.new()
			event.physical_keycode = int(keycode)
			event.pressed = false
			Input.parse_input_event(event)
	held.clear()

func _process_frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join("%s.png" % shot_name)
	var error := root.get_texture().get_image().save_png(path)
	results.screenshots.append({"name": shot_name, "path": path, "error": error})
	print("saved ", path)

func _write_json(file_name: String, data: Dictionary) -> void:
	var file := FileAccess.open(out_dir.path_join(file_name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
