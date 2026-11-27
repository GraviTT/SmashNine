extends SceneTree
## Quality track 4 (2026-11-27): how many process and physics frames headless Godot runs per
## second of real time in normal mode (no --fixed-fps), with an empty tree and with the game's
## title screen. A test watchdog that counts frames needs this: if headless runs faster than
## 60 frames a second, "seconds x 60" frames is a tighter limit than the old real-time one.
##   <godot> --headless --path . -s tests/analysis/lead/headless_frame_rate_probe.gd
const SECONDS := 3.0

var physics_frames := 0

func _initialize() -> void:
	physics_frame.connect(func() -> void: physics_frames += 1)
	call_deferred("_run")

func _measure(label: String) -> Dictionary:
	var start_usec := Time.get_ticks_usec()
	var start_process := Engine.get_process_frames()
	var start_physics := physics_frames
	while Time.get_ticks_usec() - start_usec < int(SECONDS * 1000000.0):
		await process_frame
	var elapsed := float(Time.get_ticks_usec() - start_usec) / 1000000.0
	return {"what": label, "process_per_s": snappedf(float(Engine.get_process_frames() - start_process) / elapsed, 0.1), "physics_per_s": snappedf(float(physics_frames - start_physics) / elapsed, 0.1)}

func _run() -> void:
	var results: Array = []
	results.append(await _measure("empty tree"))
	change_scene_to_file("res://scenes/Main.tscn")
	for i in 30:
		await process_frame
	results.append(await _measure("title screen"))
	print("HEADLESS_RATE_RESULT ", JSON.stringify({"results": results, "low_processor_sleep_usec": OS.low_processor_usage_mode_sleep_usec, "max_fps": Engine.max_fps, "physics_ticks": Engine.physics_ticks_per_second}))
	quit()
