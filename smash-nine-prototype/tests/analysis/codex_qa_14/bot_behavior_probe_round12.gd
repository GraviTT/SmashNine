extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round11.gd"
## Round 12 adds an independent copy of the round-11 fixed-horizontal-velocity fall
## predictor. Product code remains untouched; this observer compares R10/R11/R12 decisions
## at the same falling frames and follows each disagreement to landing/recovery/ring-out.

const GAME_SCALE = preload("res://scripts/GameScale.gd")
const R11_FALL_PROBE_STEP := 0.1
const R11_FALL_PROBE_STEPS := 10
const R11_FALL_GRAVITY := 1850.0 * GAME_SCALE.GRAVITY * 1.18
const R11_FALL_MAX_SPEED := 980.0 * GAME_SCALE.JUMP_SPEED
const ROUND12_OUT_PATH := "res://../reports/codex-qa-14/round12-results.json"

var r11_only_fall_rows: Array[Dictionary] = []

func _run_all() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 12,
		"seeds": seeds,
		"players": player_count,
		"sample_interval": SAMPLE_INTERVAL,
		"hit_window": HIT_WINDOW,
		"no_progress_definition": "target episode >=3s whose distance never shrank by max(100px, 10% of start distance)",
		"wall_seconds": snappedf(float(Time.get_ticks_usec() - wall_start) / 1000000.0, 0.001),
		"matches": match_rows,
		"totals": totals,
		"ringouts": ringout_rows,
		"low_hp_portals": low_hp_rows,
		"relocations": relocation_rows,
		"target_drop_events": target_drop_rows,
		"corner_escape_events": corner_escape_rows,
		"recovery_skill_events": recovery_skill_rows,
		"recovery_skill_ask_events": recovery_skill_ask_rows,
		"progress_extension_events": progress_extension_rows,
		"standoff_trace_events": standoff_trace_rows,
		"dead_band_events": dead_band_rows,
		"recovery_entry_events": recovery_entry_rows,
		"saved_fall_events": saved_fall_rows,
		"r10_only_fall_events": r10_only_fall_rows,
		"r11_only_fall_events": r11_only_fall_rows,
		"round12_definitions": {
			"saved_fall": "straight-down says void and live R12 accepts; r10_landing/r11_landing record the older predictors at the same frame",
			"r10_only_fall": "R10 accepts and live R12 rejects; r11_landing records whether R11 accepted at the same frame",
			"r11_only_fall": "R11 accepts and live R12 rejects; entered_recovery records whether live R12 recovery began before landing or ring-out",
			"saved_fall_input_trace": "start/last move_input and debug intent plus change/reversal counts observed each physics frame while live R12 continues to accept the fall"
		}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var file := FileAccess.open(ROUND12_OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % ROUND12_OUT_PATH)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("QA14_SUMMARY matches=%d wall=%.1fs ringouts=%d low_hp_portals=%d standoffs=%d" % [match_rows.size(), result.wall_seconds, ringout_rows.size(), low_hp_rows.size(), (totals.standoffs as Array).size()])
	print("QA14_R12_FALLS accepted=%d r10_rejected=%d r11_rejected=%d" % [saved_fall_rows.size(), r10_only_fall_rows.size(), r11_only_fall_rows.size()])
	print("QA14_OUTPUT ", ProjectSettings.globalize_path(ROUND12_OUT_PATH))
	quit(0)

func _new_player_memory(player: Node) -> Dictionary:
	var memory := super._new_player_memory(player)
	memory["r11_only_fall_row"] = -1
	return memory

func _observe_saved_fall(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var active_index := int(memory.get("saved_fall_row", -1))
	if active_index >= 0 and active_index < saved_fall_rows.size():
		_update_saved_fall_trace(saved_fall_rows[active_index], player, snapshot, now)
	var before := saved_fall_rows.size()
	super._observe_saved_fall(player, snapshot, memory, now)
	if saved_fall_rows.size() > before:
		var event: Dictionary = saved_fall_rows[saved_fall_rows.size() - 1]
		event["r10_landing"] = _r10_landing_in_fall(player)
		event["r11_landing"] = _r11_landing_in_fall(player)
		saved_fall_rows[saved_fall_rows.size() - 1] = event
		_update_saved_fall_trace(event, player, snapshot, now)

func _update_saved_fall_trace(event: Dictionary, player: Node, snapshot: Dictionary, now: float) -> void:
	var move_input: float = float(player.get("move_input")) if player.get("move_input") != null else 0.0
	var intent_move: float = float(snapshot.get("move", 0.0))
	if not event.has("start_move_input"):
		event.start_move_input = snappedf(move_input, 0.01)
		event.start_intent_move = snappedf(intent_move, 0.01)
		event.move_input_changes = 0
		event.move_input_reversals = 0
		event.intent_move_changes = 0
		event.intent_move_reversals = 0
	else:
		var previous_move := float(event.get("last_move_input", move_input))
		var previous_intent := float(event.get("last_intent_move", intent_move))
		if absf(move_input - previous_move) > 0.1:
			event.move_input_changes = int(event.move_input_changes) + 1
			if not is_zero_approx(move_input) and not is_zero_approx(previous_move) and signf(move_input) != signf(previous_move):
				event.move_input_reversals = int(event.move_input_reversals) + 1
		if absf(intent_move - previous_intent) > 0.1:
			event.intent_move_changes = int(event.intent_move_changes) + 1
			if not is_zero_approx(intent_move) and not is_zero_approx(previous_intent) and signf(intent_move) != signf(previous_intent):
				event.intent_move_reversals = int(event.intent_move_reversals) + 1
	event.last_time = snappedf(now, 0.01)
	event.last_move_input = snappedf(move_input, 0.01)
	event.last_intent_move = snappedf(intent_move, 0.01)
	event.last_state = str(snapshot.state)
	event.last_reason = str(snapshot.get("reason", ""))
	event.last_position = _vector_row(player.global_position)
	event.last_velocity = _vector_row(player.velocity)
	event.r10_landing_last = _r10_landing_in_fall(player)
	event.r11_landing_last = _r11_landing_in_fall(player)

func _observe_r10_only_fall(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var before := r10_only_fall_rows.size()
	super._observe_r10_only_fall(player, snapshot, memory, now)
	if r10_only_fall_rows.size() > before:
		var event: Dictionary = r10_only_fall_rows[r10_only_fall_rows.size() - 1]
		event["r11_landing"] = _r11_landing_in_fall(player)
		r10_only_fall_rows[r10_only_fall_rows.size() - 1] = event
	_observe_r11_only_fall(player, snapshot, memory, now)

func _observe_r11_only_fall(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var active_index := int(memory.get("r11_only_fall_row", -1))
	if active_index >= 0:
		var event: Dictionary = r11_only_fall_rows[active_index]
		if str(snapshot.state) == "recover" and not bool(event.entered_recovery):
			event.entered_recovery = true
			event.recovery_delay = snappedf(now - float(event.time), 0.01)
			r11_only_fall_rows[active_index] = event
		if player.is_on_floor():
			_finish_r11_only_fall(memory, "landed", now)
		return
	if player.is_on_floor() or player.velocity.y <= 0.0 or (str(snapshot.state) == "recover" and bool(memory.recovery)):
		return
	var r12_landing := bool(player.ai_controller._landing_in_fall(player))
	if r12_landing or not _r11_landing_in_fall(player):
		return
	r11_only_fall_rows.append({
		"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id),
		"outcome": "pending", "realm": int(player.realm_index),
		"position": _vector_row(player.global_position), "velocity": _vector_row(player.velocity),
		"air_jumps_left": int(player.air_jumps_left), "r10_landing": _r10_landing_in_fall(player),
		"entered_recovery": str(snapshot.state) == "recover",
		"recovery_delay": 0.0 if str(snapshot.state) == "recover" else -1.0
	})
	memory.r11_only_fall_row = r11_only_fall_rows.size() - 1

func _r11_landing_in_fall(player: Node) -> bool:
	var at: Vector2 = player.global_position
	var motion: Vector2 = player.velocity
	for step in R11_FALL_PROBE_STEPS:
		motion.y = minf(motion.y + R11_FALL_GRAVITY * R11_FALL_PROBE_STEP, R11_FALL_MAX_SPEED)
		var next: Vector2 = at + motion * R11_FALL_PROBE_STEP
		if bool(player.ai_controller._ray_hits_world(player, at, next)):
			return true
		at = next
	return false

func _finish_r11_only_fall(memory: Dictionary, outcome: String, now: float) -> void:
	var index := int(memory.get("r11_only_fall_row", -1))
	if index < 0 or index >= r11_only_fall_rows.size():
		return
	var event: Dictionary = r11_only_fall_rows[index]
	event.outcome = outcome
	event.duration = snappedf(now - float(event.time), 0.01)
	r11_only_fall_rows[index] = event
	memory.r11_only_fall_row = -1

func _on_damaged(player: Node, amount: float, attacker: Node, source: String) -> void:
	var pid := player.get_instance_id()
	var previous_ringouts := int(player_memory[pid].ringouts) if player_memory.has(pid) else int(player.respawn_count)
	super._on_damaged(player, amount, attacker, source)
	if player_memory.has(pid) and int(player.respawn_count) > previous_ringouts:
		_finish_r11_only_fall(player_memory[pid], "ringout", main.director.match_elapsed)

func _finalize_match_episodes() -> void:
	super._finalize_match_episodes()
	var now: float = main.director.match_elapsed
	for player in main.players:
		if is_instance_valid(player) and player_memory.has(player.get_instance_id()):
			_finish_r11_only_fall(player_memory[player.get_instance_id()], "unfinished", now)
