extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round13.gd"
## Round 14 reuses the Round 13 variant-A observer and adds two read-only
## measurements requested by the task card: unchecked target selection after
## three failed route checks, and ultimate hits across the full ultimate window.

const QA14_OUT := "res://../reports/codex-qa-14/round14-results.json"

var target_selection_rows: Array[Dictionary] = []
var ultimate_rows: Array[Dictionary] = []
var active_ultimate_rows: Dictionary = {}

func _run_all() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 14, "variant": "a", "seeds": seeds, "players": player_count,
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
		"ringout_details": ringout_detail_rows, "no_route_details": no_route_detail_rows,
		"fixture_candidates": fixture_candidates, "ab_suppressed_falls": ab_suppressed_rows,
		"no_progress_causes": no_progress_causes,
		"attack_request_frames": attack_request_frames,
		"target_selection_events": target_selection_rows,
		"ultimate_events": ultimate_rows,
		"round14_definitions": {
			"unchecked_target": "candidate returned by _find_target only because three earlier candidates failed reachability checks",
			"ultimate_hit": "PvP damage while the attacker's product ultimate_window_timer is positive; an activation hit is counted once even when it deals several hits"
		}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var file := FileAccess.open(QA14_OUT, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % QA14_OUT)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	_print_summary(result)
	print("QA14 frames=%d drops=%d selections=%d ultimates=%d" % [fall_frame_rows.size(), target_drop_rows.size(), target_selection_rows.size(), ultimate_rows.size()])
	quit(0)

func _new_player_memory(player: Node) -> Dictionary:
	var memory: Dictionary = super._new_player_memory(player)
	memory.qa14_target_id = -1
	memory.qa14_target_mode = "none"
	if not player.ultimate_cast.is_connected(_on_ultimate_cast):
		player.ultimate_cast.connect(_on_ultimate_cast)
	return memory

func _observe_frame() -> void:
	super._observe_frame()
	if not is_instance_valid(main):
		return
	var now: float = main.director.match_elapsed
	for player in main.players:
		if not is_instance_valid(player) or not player_memory.has(player.get_instance_id()):
			continue
		var memory: Dictionary = player_memory[player.get_instance_id()]
		var target_value: Variant = player.ai_controller.target
		var target_id: int = int(target_value.get_instance_id()) if is_instance_valid(target_value) else -1
		if target_id != int(memory.qa14_target_id):
			memory.qa14_target_id = target_id
			memory.qa14_target_mode = "none"
			if is_instance_valid(target_value):
				memory.qa14_target_mode = _selection_mode(player, target_value)
				target_selection_rows.append({
					"seed": match_seed, "time": snappedf(now, 0.01),
					"character": str(player.character_id), "target_id": target_id,
					"target_kind": _target_kind(target_value),
					"mode": str(memory.qa14_target_mode)
				})
		player_memory[player.get_instance_id()] = memory

func _selection_mode(player: Node, chosen: Node) -> String:
	var ai: RefCounted = player.ai_controller
	var scored: Array = ai._scored_targets(player)
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var checks := 0
	var own_floor: Vector2 = ai._standing_point(player, player)
	for entry: Array in scored:
		var candidate: Node = entry[1]
		var stands: Vector2 = ai._standing_point(player, candidate)
		if stands == Vector2.INF:
			continue
		if own_floor == Vector2.INF:
			return "unchecked_self_over_void" if candidate == chosen else "not_reproduced"
		if checks >= 3:
			return "unchecked_after_3" if candidate == chosen else "not_reproduced"
		if absf(stands.y - own_floor.y) <= float(ai.NAV_SAME_LEVEL) and (ai._walkable_between(player, own_floor, stands) or absf(stands.x - own_floor.x) <= ai._hit_reach(player)):
			return "checked_same_level" if candidate == chosen else "not_reproduced"
		checks += 1
		if ai._has_route_to(player, stands):
			return "checked_route" if candidate == chosen else "not_reproduced"
	return "not_in_scored"

func _enrich_latest_drop(player: Node, memory: Dictionary, now: float, known_dropped: Node = null) -> void:
	super._enrich_latest_drop(player, memory, now, known_dropped)
	if target_drop_rows.is_empty():
		return
	var row: Dictionary = target_drop_rows[target_drop_rows.size() - 1]
	var dropped_id := int(row.get("target_id", -1))
	row.chosen_without_route_check = dropped_id >= 0 and dropped_id == int(memory.get("qa14_target_id", -2)) and str(memory.get("qa14_target_mode", "")) == "unchecked_after_3"
	row.target_selection_mode = str(memory.get("qa14_target_mode", "unknown")) if dropped_id == int(memory.get("qa14_target_id", -2)) else "unknown"

func _on_ultimate_cast(caster: Node) -> void:
	if not is_instance_valid(main) or not is_instance_valid(caster):
		return
	var row := {
		"seed": match_seed, "time": snappedf(main.director.match_elapsed, 0.01),
		"character": str(caster.character_id), "window": snappedf(float(caster.ultimate_window), 0.01),
		"hit": false, "hit_events": 0, "damage": 0.0, "targets": []
	}
	ultimate_rows.append(row)
	active_ultimate_rows[caster.get_instance_id()] = ultimate_rows.size() - 1

func _on_damaged(player: Node, amount: float, attacker: Node, source: String) -> void:
	super._on_damaged(player, amount, attacker, source)
	if source != "hit" or not is_instance_valid(attacker) or not attacker.is_in_group("players"):
		return
	var pid := attacker.get_instance_id()
	if float(attacker.ultimate_window_timer) <= 0.0 or not active_ultimate_rows.has(pid):
		return
	var index := int(active_ultimate_rows[pid])
	if index < 0 or index >= ultimate_rows.size():
		return
	var row: Dictionary = ultimate_rows[index]
	row.hit = true
	row.hit_events = int(row.hit_events) + 1
	row.damage = snappedf(float(row.damage) + amount, 0.01)
	var target_key := "%d" % player.get_instance_id()
	if not (row.targets as Array).has(target_key):
		(row.targets as Array).append(target_key)
