extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round15.gd"
## Round 16 reuses the Round 15 observer and swaps a probe-local EnemyAI
## subclass after spawning. Product source remains untouched.

const S0_AI := preload("res://tests/analysis/codex_qa_14/qa16_s0_enemy_ai.gd")
const U0_AI := preload("res://tests/analysis/codex_qa_14/qa16_u0_enemy_ai.gd")

var ringout_start_rows: Array[Dictionary] = []

func _run_all() -> void:
	if not ["current", "s0", "u0"].has(variant):
		push_error("Round 16 variant must be current, s0 or u0; got %s" % variant)
		quit(2)
		return
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 16, "variant": variant, "seeds": seeds, "players": player_count,
		"sample_interval": SAMPLE_INTERVAL, "hit_window": HIT_WINDOW,
		"wall_seconds": snappedf(float(Time.get_ticks_usec() - wall_start) / 1000000.0, 0.001),
		"matches": match_rows, "totals": totals, "ringouts": ringout_rows,
		"low_hp_portals": low_hp_rows, "relocations": relocation_rows,
		"target_drop_events": target_drop_rows, "corner_escape_events": corner_escape_rows,
		"recovery_skill_events": recovery_skill_rows,
		"recovery_skill_ask_events": recovery_skill_ask_rows,
		"progress_extension_events": progress_extension_rows,
		"standoff_trace_events": standoff_trace_rows, "dead_band_events": dead_band_rows,
		"recovery_entry_events": recovery_entry_rows, "saved_fall_events": saved_fall_rows,
		"r10_only_fall_events": r10_only_fall_rows,
		"fall_frames": fall_frame_rows, "fall_flips": fall_flip_rows,
		"ringout_details": ringout_detail_rows, "ringout_starts": ringout_start_rows,
		"no_route_details": no_route_detail_rows,
		"fixture_candidates": fixture_candidates, "ab_suppressed_falls": ab_suppressed_rows,
		"no_progress_causes": no_progress_causes,
		"attack_request_frames": attack_request_frames,
		"target_selection_events": target_selection_rows,
		"ultimate_events": ultimate_rows,
		"round16_definitions": {
			"observer": "Round 15 observer plus exact per-victim last PvP/ultimate hit ages at ring-out",
			"s0": "R11 _find_target same-level acceptance; all other AI current",
			"u0": "R11 already-scaled ultimate reach values; all other AI current",
			"ultimate_hit": "PvP damage while attacker ultimate_window_timer is positive"
		}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var out_path := "res://../reports/codex-qa-14/round16-%s-results.json" % variant
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % out_path)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	_print_summary(result)
	print("QA16 variant=%s frames=%d drops=%d ultimates=%d ringout_starts=%d" % [variant, fall_frame_rows.size(), target_drop_rows.size(), ultimate_rows.size(), ringout_start_rows.size()])
	quit(0)

func _run_match(value: int) -> void:
	match_seed = value
	seed(value)
	_reset_match_memory()
	main = load(MAIN_SCENE).instantiate()
	main.bots_only = true
	main.match_seed = value
	main.player_count = player_count
	root.add_child(main)
	await process_frame
	if variant != "current":
		var ai_script: Script = S0_AI if variant == "s0" else U0_AI
		for player in main.players:
			var old_ai = player.ai_controller
			var new_ai = ai_script.new()
			for property in old_ai.get_property_list():
				if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					var property_name := str(property.name)
					new_ai.set(property_name, old_ai.get(property_name))
			player.ai_controller = new_ai
	main.director.realm_state_changed.connect(_on_realm_state_changed)
	main.director.combatant_relocated.connect(_on_relocated)
	for player in main.players:
		player.damaged.connect(_on_damaged)
		player.defeated.connect(_on_defeated)
		player_memory[player.get_instance_id()] = _new_player_memory(player)
	var frame_limit := int(seconds / FRAME_TIME)
	var finished := false
	for _frame in frame_limit:
		await physics_frame
		_observe_frame()
		if main.match_over:
			finished = true
			break
	_finalize_match_episodes()
	var winner: Node = main.get_winner()
	match_rows.append({
		"seed": value, "seconds": snappedf(main.director.match_elapsed, 0.1), "finished": finished,
		"reason": main.director.finish_reason, "winner": winner.character_id if is_instance_valid(winner) else "",
		"ringouts": match_ringouts, "portals": match_portals, "relocations": match_relocations,
		"recovery_success": match_recovery_success, "recovery_fail": match_recovery_fail,
		"recovery_entries": match_recovery_success + match_recovery_fail, "standoffs": match_standoffs
	})
	print("QA16_MATCH variant=%s seed=%d seconds=%.1f ringouts=%d portals=%d recovery=%d/%d standoffs=%d" % [variant, value, main.director.match_elapsed, match_ringouts, match_portals, match_recovery_success, match_recovery_fail, match_standoffs])
	main.queue_free()
	await process_frame
	await process_frame
	main = null

func _new_player_memory(player: Node) -> Dictionary:
	var memory: Dictionary = super._new_player_memory(player)
	memory.qa16_last_pvp_hit = -99.0
	memory.qa16_last_pvp_attacker = ""
	memory.qa16_last_ultimate_hit = -99.0
	memory.qa16_last_ultimate_attacker = ""
	return memory

func _on_damaged(player: Node, amount: float, attacker: Node, source: String) -> void:
	var before := ringout_rows.size()
	var now: float = float(main.director.match_elapsed) if is_instance_valid(main) else 0.0
	var pid := player.get_instance_id()
	if source == "hit" and is_instance_valid(attacker) and attacker.is_in_group("players") and player_memory.has(pid):
		var memory: Dictionary = player_memory[pid]
		memory.qa16_last_pvp_hit = now
		memory.qa16_last_pvp_attacker = str(attacker.character_id)
		if float(attacker.ultimate_window_timer) > 0.0:
			memory.qa16_last_ultimate_hit = now
			memory.qa16_last_ultimate_attacker = str(attacker.character_id)
		player_memory[pid] = memory
	super._on_damaged(player, amount, attacker, source)
	if ringout_rows.size() <= before:
		return
	var final_memory: Dictionary = player_memory.get(pid, {})
	var pvp_age := now - float(final_memory.get("qa16_last_pvp_hit", -99.0))
	var ultimate_age := now - float(final_memory.get("qa16_last_ultimate_hit", -99.0))
	ringout_start_rows.append({
		"seed": match_seed, "time": snappedf(now, 0.01), "victim": str(player.character_id),
		"pvp_hit_within_3s": pvp_age <= 3.0, "pvp_hit_age": snappedf(pvp_age, 0.01),
		"pvp_attacker": str(final_memory.get("qa16_last_pvp_attacker", "")),
		"ultimate_hit_within_3s": ultimate_age <= 3.0, "ultimate_hit_age": snappedf(ultimate_age, 0.01),
		"ultimate_attacker": str(final_memory.get("qa16_last_ultimate_attacker", ""))
	})
