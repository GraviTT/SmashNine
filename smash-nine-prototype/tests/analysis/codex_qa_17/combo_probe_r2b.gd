extends "res://tests/analysis/codex_qa_17/combo_probe.gd"

## Round 2b independent copy of the Round 1 input probe.
## Product combat state is not assigned during a route. For Brave routes only, the target is
## placed after the transformation burst has ended; that is fixture setup before route input.

func _run() -> void:
	seed(1722)
	var routes := [
		{"character": "frey", "route": "J1-J2-J3", "distance": 45.0, "expected": 3},
		{"character": "frey", "route": "J1-J2-J3", "distance": 60.0, "expected": 3},
		{"character": "frey", "route": "J1-J2-J3", "distance": 120.0, "expected": 3},
		{"character": "frey", "route": "L-spike", "distance": 80.0, "expected": 2},
		{"character": "frey", "route": "L-airJ", "distance": 80.0, "expected": 2},
		{"character": "frey", "route": "K-J", "distance": 150.0, "expected": 2},
		{"character": "frey", "route": "upJ-airUpJ", "distance": 45.0, "expected": 2},
		{"character": "luna", "route": "J-trail-bloom", "distance": 110.0, "expected": 2},
		{"character": "luna", "route": "J-K", "distance": 110.0, "expected": 3},
		{"character": "luna", "route": "L-sweet", "distance": 135.0, "expected": 1},
		{"character": "luna", "route": "Brave-J1-J2-J3", "distance": 45.0, "expected": 3},
		{"character": "luna", "route": "Brave-upJ-airUpJ", "distance": 45.0, "expected": 2},
		{"character": "luna", "route": "Brave-K-J", "distance": 120.0, "expected": 2},
		{"character": "luna", "route": "Brave-L", "distance": 100.0, "expected": 1}
	]
	for spec in routes:
		for moving in [false, true]:
			var trials := TRIALS_BOT if moving else TRIALS_DUMMY
			for trial in trials:
				await _run_trial(spec, moving, trial)
			_release_all()
	var out := {
		"schema": 2,
		"fixed_fps": 60,
		"input_method": "InputEventAction into PlayerBase._unhandled_input frame by frame; fixture target placement only before Brave route",
		"dummy_trials": TRIALS_DUMMY,
		"moving_bot_trials": TRIALS_BOT,
		"fixes": [
			"Brave target placed only after transform burst, landing, hitstun, and attacker recovery",
			"L-spike follow-up pressed while rising_followup_timer > 0 without _can_start_attack",
			"post_final_hit_travel resets when each new hit lands"
		],
		"trials": results,
		"summary": _summarize()
	}
	var path := ProjectSettings.globalize_path("res://../reports/codex-qa-17/round-2-codex/combo-raw-r2b.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	print("QA17_R2B_COMBO_RESULT ", JSON.stringify(out.summary))
	quit(0)

func _run_trial(spec: Dictionary, moving: bool, trial: int) -> void:
	await _new_arena(str(spec.character), float(spec.distance), moving)
	frame = 0
	hit_rows.clear()
	previous_hp = target.hp
	previous_hitstun = target.hitstun_timer
	previous_hitstop = target.hitstop_timer
	recovery_frame = -1
	var route := str(spec.route)
	var stage := 0
	var started := false
	var route_start_position: Vector2
	var final_hit_position: Vector2
	var post_final_hit_travel := 0.0
	if route.begins_with("Brave"):
		_hold("move_right", false)
		_tap("ultimate")
		for warmup in 210:
			await _observe_frame()
			if attacker.transformed and attacker._can_start_attack() and target.is_on_floor() and target.hitstun_timer <= 0.0 and target.hitstop_timer <= 0.0:
				break
		# Allowed fixture setup: the transformation burst is over before route input starts.
		target.global_position = Vector2(attacker.global_position.x + float(spec.distance), -1.0)
		await physics_frame
		_hold("move_right", true)
	hit_rows.clear()
	previous_hp = target.hp
	recovery_frame = -1
	route_start_position = target.global_position
	final_hit_position = target.global_position
	for current in 150:
		frame = current
		if not started:
			started = true
			stage = 1
			_start_route(route)
		else:
			stage = _drive_route(route, stage)
		var hits_before := hit_rows.size()
		await _observe_frame()
		if hit_rows.size() > hits_before:
			final_hit_position = hit_rows[-1].position as Vector2
			post_final_hit_travel = 0.0
		elif not hit_rows.is_empty():
			post_final_hit_travel = maxf(post_final_hit_travel, target.global_position.distance_to(final_hit_position))
		if current > 45 and stage >= _route_stages(route) and attacker.attack_lock_timer <= 0.0 and target.hitstun_timer <= 0.0 and target.hitstop_timer <= 0.0:
			break
	var gaps: Array[int] = []
	for index in range(1, hit_rows.size()):
		gaps.append(int(hit_rows[index].gap_from_previous))
	results.append({
		"character": str(spec.character), "route": route, "moving_bot": moving, "trial": trial,
		"start_distance": float(spec.distance), "expected_hits": int(spec.expected), "hits": hit_rows.size(),
		"connected": hit_rows.size() >= int(spec.expected), "gap_frames": gaps,
		"knockback_distance": snappedf(post_final_hit_travel, 0.1),
		"post_final_hit_travel": snappedf(post_final_hit_travel, 0.1),
		"net_target_displacement": snappedf(target.global_position.distance_to(route_start_position), 0.1),
		"hit_rows": hit_rows.duplicate(true)
	})
	_release_all()
	arena.queue_free()
	await process_frame
	await process_frame

func _drive_route(route: String, stage: int) -> int:
	if route == "L-spike":
		if stage == 1 and attacker.rising_followup_timer > 0.0:
			_tap("skill_2")
			return 2
		return stage
	return super._drive_route(route, stage)
