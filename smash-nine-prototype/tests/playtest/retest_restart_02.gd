extends "res://tests/playtest/real_input_restart.gd"
## CODEX-RETEST-02: the original B -> result -> R input loop, expanded to the
## requested ten R presses. State is only read for measurement.

const RETEST_OUT_RELATIVE := "../reports/codex-tester-02"
const RESTARTS := 10

func _initialize() -> void:
	out_dir = ProjectSettings.globalize_path("res://").path_join(RETEST_OUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(out_dir)
	results = {
		"driver": "real_input_restart",
		"time_scale": 30.0,
		"restart_presses": 0,
		"start_node_counts": [],
		"matches": [],
		"screenshots": []
	}
	call_deferred("_run")

func _run() -> void:
	var first: Node = load(MAIN_SCENE).instantiate()
	first.match_seed = 7301
	root.add_child(first)
	current_scene = first
	await _process_frames(18)
	Engine.time_scale = 30.0
	for cycle in RESTARTS + 1:
		var main: Node = current_scene
		results.start_node_counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		if cycle == 0 or cycle == RESTARTS:
			await _shot("%02d_restart_start_%d" % [20 + cycle * 2, cycle])
		await _tap(KEY_B)
		var frames := 0
		while is_instance_valid(main) and not main.match_over and frames < 1200:
			await physics_frame
			frames += 1
		var winner: Node = main.get_winner() if is_instance_valid(main) else null
		var alive_at_result: int = main.director.get_alive_combatants().size() if is_instance_valid(main) else -1
		var winner_alive_at_result: bool = is_instance_valid(winner) and not winner.is_defeated and winner.hp > 0.0
		var winner_hp_at_result: float = winner.hp if is_instance_valid(winner) else -1.0
		await _process_frames(30)
		var alive_after_wait: int = main.director.get_alive_combatants().size() if is_instance_valid(main) else -1
		var winner_hp_after_wait: float = winner.hp if is_instance_valid(winner) else -1.0
		var match_data: Dictionary = {
			"cycle": cycle,
			"seed": main.match_seed if is_instance_valid(main) else -1,
			"frames_at_30x": frames,
			"result_reached": is_instance_valid(main) and main.match_over,
			"elapsed": snappedf(main.director.match_elapsed, 0.1) if is_instance_valid(main) else -1.0,
			"winner": winner.display_name if is_instance_valid(winner) else "",
			"reason": main.director.finish_reason if is_instance_valid(main) else "",
			"nodes_at_result": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"winner_alive_at_result": winner_alive_at_result,
			"winner_hp_at_result": snappedf(winner_hp_at_result, 0.1),
			"winner_hp_after_wait": snappedf(winner_hp_after_wait, 0.1),
			"alive_at_result": alive_at_result,
			"alive_after_wait": alive_after_wait,
			"result_state_frozen": alive_at_result == alive_after_wait and is_equal_approx(winner_hp_at_result, winner_hp_after_wait)
		}
		results.matches.append(match_data)
		if cycle == 0 or cycle == RESTARTS:
			await _shot("%02d_restart_result_%d" % [21 + cycle * 2, cycle])
		if cycle == RESTARTS:
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
	results["all_winners_alive"] = _all_winners_alive()
	results["all_result_states_frozen"] = _all_result_states_frozen()
	_write_json("real_input_restart.json", results)
	print("PLAYTEST_RESULT ", JSON.stringify(results))
	quit(0)

func _all_results_reached() -> bool:
	for match_data in results.matches:
		if not bool(match_data.result_reached):
			return false
	return results.matches.size() == RESTARTS + 1

func _all_winners_alive() -> bool:
	for match_data in results.matches:
		if not bool(match_data.winner_alive_at_result):
			return false
	return results.matches.size() == RESTARTS + 1

func _all_result_states_frozen() -> bool:
	for match_data in results.matches:
		if not bool(match_data.result_state_frozen):
			return false
	return results.matches.size() == RESTARTS + 1
