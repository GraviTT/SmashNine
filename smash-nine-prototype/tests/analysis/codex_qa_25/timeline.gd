extends "res://tests/test_nova_prototype.gd"
const IDLE_NOVA = preload("res://tests/analysis/codex_qa_25/nova_idle.gd")
var trace: Array = []
var errors: Array = []
var startup_mode := "physics"
var poll_mode := "idle"
var out_name := "timeline"
var phase := "slow"
var begin_us := 0
var stall_ms := 0
var stalled := false
var j_start_tick := 0

func stamp(event: String, data: Dictionary = {}) -> void:
	data.event = event
	data.physics_frame = Engine.get_physics_frames()
	data.process_frame = Engine.get_process_frames()
	data.wall_us = Time.get_ticks_usec() - begin_us
	data.phase = phase
	trace.append(data)

func _create_nova(player_id: int, physics_enabled := false) -> Node:
	phase = "slow" if player_id == 1 else "fast"
	var nova: Node = PLAYER_FACTORY.create("nova")
	if startup_mode == "idle": nova.set_script(IDLE_NOVA)
	arena.add_child(nova)
	nova.global_position = Vector2(player_id * 2200.0, 0.0)
	nova.setup(nova_data, player_id, false)
	nova.ringout_y = 100000.0
	nova.set_physics_process(physics_enabled)
	stamp("before_J_call", {"player_id": player_id})
	j_start_tick = Engine.get_physics_frames()
	return nova

func _node_added(node: Node) -> void:
	if node.get_script() == null or node.get_script().resource_path != ATTACK_PATH: return
	var id := node.get_instance_id()
	var created_phase := phase
	stamp("attack_enter", {"id": id})
	node.tree_exiting.connect(func(): stamp("attack_exit", {"id": id, "created_phase": created_phase}))

func _wait_for_source_script(source: Node, script_path: String) -> Node:
	stamp("after_J_call")
	for attempt in 100:
		var found := _find_source_script(source, script_path)
		stamp("poll", {"attempt": attempt, "found": is_instance_valid(found), "id": found.get_instance_id() if is_instance_valid(found) else -1, "queued": found.is_queued_for_deletion() if is_instance_valid(found) else false})
		if is_instance_valid(found): return found
		if stall_ms > 0 and not stalled and phase == "slow" and Engine.get_physics_frames() - j_start_tick >= 2:
			stalled = true
			stamp("synthetic_stall_begin", {"ms": stall_ms})
			OS.delay_msec(stall_ms)
			stamp("synthetic_stall_end")
		if poll_mode == "physics": await physics_frame
		else: await create_timer(0.005).timeout
	return null

func _fail(message: String) -> void:
	errors.append(message)
	stamp("test_fail", {"message": message})
	# Parent would quit immediately; wait to persist the trace and clean up the fixture.

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--startup="): startup_mode = arg.trim_prefix("--startup=")
		elif arg.begins_with("--poll="): poll_mode = arg.trim_prefix("--poll=")
		elif arg.begins_with("--out="): out_name = arg.trim_prefix("--out=")
		elif arg.begins_with("--stall-ms="): stall_ms = int(arg.trim_prefix("--stall-ms="))
	begin_us = Time.get_ticks_usec()
	arena = Node2D.new()
	root.add_child(arena)
	main = MAIN_SCRIPT.new()
	nova_data = CHARACTER_REGISTRY.get_characters()["nova"]
	node_added.connect(_node_added)
	if stall_ms > 0:
		# Synthetic diagnostic only: let the initial eight-step startup catch-up finish,
		# so the deliberate stall can be placed while the J timer is partly elapsed.
		# Keep a disabled distant Nova alive to retain its loaded textures during comparison.
		_create_nova(99)
		await create_timer(0.3).timeout
		trace.clear()
		stamp("synthetic_warmup_complete")
	var ok := await _test_momentum_attack_scaling()
	stamp("momentum_result", {"ok": ok})
	await create_timer(0.3).timeout
	arena.queue_free()
	await process_frame
	main.free()
	var file := FileAccess.open("res://../reports/codex-qa-25/" + out_name + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"startup": startup_mode, "poll": poll_mode, "synthetic_stall_ms": stall_ms, "stall_executed": stalled, "max_fps": Engine.max_fps, "physics_hz": Engine.physics_ticks_per_second, "max_steps": Engine.max_physics_steps_per_frame, "ok": ok, "errors": errors, "trace": trace}, "\t"))
	print("QA25_TIMELINE ", out_name, " ok=", ok, " events=", trace.size(), " errors=", errors)
	quit(0 if ok else 1)
