extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round14.gd"
## Round 15 reuses the Round 14 observer unchanged and writes to a separate
## result path so the accepted Round 14 evidence remains intact.

const QA15_OUT := "res://../reports/codex-qa-14/round15-results.json"

func _run_all() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 15, "variant": "a", "seeds": seeds, "players": player_count,
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
		"round15_definitions": {
			"observer": "Round 14 observer unchanged",
			"ultimate_hit": "PvP damage while the attacker's product ultimate_window_timer is positive"
		}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var file := FileAccess.open(QA15_OUT, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % QA15_OUT)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	_print_summary(result)
	print("QA15 frames=%d drops=%d selections=%d ultimates=%d" % [fall_frame_rows.size(), target_drop_rows.size(), target_selection_rows.size(), ultimate_rows.size()])
	quit(0)
