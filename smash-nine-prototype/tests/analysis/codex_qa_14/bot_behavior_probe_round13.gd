extends "res://tests/analysis/codex_qa_14/bot_behavior_probe_round11.gd"
## Round 13 extends the proven R11 observer. All additions are read-only except
## variant B, which swaps in a probe-local EnemyAI subclass.

const AB_AI := preload("res://tests/analysis/codex_qa_14/qa13_ab_enemy_ai.gd")
const QA13_OUT_A := "res://../reports/codex-qa-14/round13-a-results.json"
const QA13_OUT_B := "res://../reports/codex-qa-14/round13-b-results.json"
const FLIP_EDGE_GRAZE := 12.0
const FOLLOW_SECONDS := 10.0
const INTENT_HISTORY_SECONDS := 2.0
const QA13_WORLD_LAYER := 1
const QA13_FALL_STEP := 0.1
const QA13_FALL_STEPS := 10
const QA13_FALL_GRAVITY := 1850.0 * 1.5 * 1.18
const QA13_FALL_MAX_SPEED := 980.0 * 1.2

var variant := "a"
var fall_frame_rows: Array[Dictionary] = []
var fall_flip_rows: Array[Dictionary] = []
var ringout_detail_rows: Array[Dictionary] = []
var no_route_detail_rows: Array[Dictionary] = []
var fixture_candidates: Array[Dictionary] = []
var ab_suppressed_rows: Array[Dictionary] = []
var no_progress_causes: Dictionary = {}
var attack_request_frames: Dictionary = {}

func _initialize() -> void:
	var first_seed := 101
	var count := 12
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			first_seed = int(arg.get_slice("=", 1))
		elif arg.begins_with("--count="):
			count = int(arg.get_slice("=", 1))
		elif arg.begins_with("--seconds="):
			seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--players="):
			player_count = int(arg.get_slice("=", 1))
		elif arg.begins_with("--variant="):
			variant = str(arg.get_slice("=", 1)).to_lower()
	for value in range(first_seed, first_seed + count):
		seeds.append(value)
	call_deferred("_run_all")

func _run_all() -> void:
	var wall_start := Time.get_ticks_usec()
	for value in seeds:
		await _run_match(value)
	var result := {
		"schema": 13, "variant": variant, "seeds": seeds, "players": player_count,
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
		"round13_definitions": {
			"fall_frame": "every falling airborne physics frame; first R11 arc collision including collider, step/crossing, point and nearest platform edge",
			"flip_class": "priority: move input, unexpected velocity/hit/wall, edge <=12px, crossing at >=0.85s horizon, other",
			"variant_b": "probe-local EnemyAI suppresses recovery for the whole airborne episode first classified R10-accept/R11-reject",
			"attack_activation": "attack_serial increment; request_frames count every physics frame with a non-empty AI attack intent"
		}
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../reports/codex-qa-14"))
	var out_path := QA13_OUT_B if variant == "b" else QA13_OUT_A
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s" % out_path)
		quit(2)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	_print_summary(result)
	print("QA13 variant=%s frames=%d flips=%d ringout_details=%d no_route=%d suppressed=%d" % [variant, fall_frame_rows.size(), fall_flip_rows.size(), ringout_detail_rows.size(), no_route_detail_rows.size(), ab_suppressed_rows.size()])
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
	if variant == "b":
		for player in main.players:
			var old_ai = player.ai_controller
			var new_ai = AB_AI.new()
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
	print("QA14_MATCH seed=%d seconds=%.1f ringouts=%d portals=%d relocations=%d recovery=%d/%d standoffs=%d" % [value, main.director.match_elapsed, match_ringouts, match_portals, match_relocations, match_recovery_success, match_recovery_fail, match_standoffs])
	main.queue_free()
	await process_frame
	await process_frame
	main = null

func _new_player_memory(player: Node) -> Dictionary:
	var memory: Dictionary = super._new_player_memory(player)
	memory.arc_previous = {}
	memory.arc_flip_indices = []
	memory.intent_history = []
	memory.no_route_pending = []
	memory.last_observed_target_id = -1
	memory.last_ab_serial = 0
	memory.dead_band_capture = {}
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
		var snapshot: Dictionary = player.ai_controller.debug_snapshot(player)
		_observe_intent_history(player, snapshot, memory, now)
		_observe_fall_frame(player, snapshot, memory, now)
		_observe_no_route_followup(player, snapshot, memory, now)
		_observe_attack_request(player, snapshot)
		_observe_ab_suppression(player, memory, now)
		_update_recovery_skill_detail(player, memory, now)
		player_memory[player.get_instance_id()] = memory

func _observe_intent_history(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var history: Array = memory.intent_history
	history.append({"t": snappedf(now, 0.01), "move": snappedf(float(snapshot.move), 0.01), "jump": bool(snapshot.jump), "attack": str(snapshot.attack), "state": str(snapshot.state), "action": str(snapshot.action)})
	while not history.is_empty() and now - float(history[0].t) > INTENT_HISTORY_SECONDS:
		history.pop_front()
	memory.intent_history = history

func _arc_first_hit(player: Node) -> Dictionary:
	var at: Vector2 = player.global_position
	var motion: Vector2 = player.velocity
	for step in QA13_FALL_STEPS:
		motion.y = minf(motion.y + QA13_FALL_GRAVITY * QA13_FALL_STEP, QA13_FALL_MAX_SPEED)
		var next: Vector2 = at + motion * QA13_FALL_STEP
		var query := PhysicsRayQueryParameters2D.create(at, next, QA13_WORLD_LAYER, [player.get_rid()])
		var result: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
		if not result.is_empty():
			var point: Vector2 = result.position
			var edge := _nearest_platform_edge_distance(player, point)
			var collider: Variant = result.get("collider")
			return {"hit": true, "step": step + 1, "crossing": float(step + 1) * QA13_FALL_STEP,
				"point": point, "edge": edge, "collider": str(collider.name) if is_instance_valid(collider) else ""}
		at = next
	return {"hit": false, "step": -1, "crossing": -1.0, "point": Vector2.ZERO, "edge": -1.0, "collider": ""}

func _nearest_platform_edge_distance(player: Node, point: Vector2) -> float:
	var best := INF
	for rect_value in player.ai_controller._platform_rects(player):
		var rect: Rect2 = rect_value
		if point.x >= rect.position.x - 8.0 and point.x <= rect.end.x + 8.0 and absf(point.y - rect.position.y) <= 32.0:
			best = minf(best, minf(absf(point.x - rect.position.x), absf(point.x - rect.end.x)))
	return -1.0 if is_inf(best) else best

func _observe_fall_frame(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	if player.is_on_floor() or player.velocity.y <= 0.0:
		memory.arc_previous = {}
		memory.arc_flip_indices = []
		return
	var hit := _arc_first_hit(player)
	fall_frame_rows.append({"s": match_seed, "t": snappedf(now, 0.01), "c": str(player.character_id), "r": int(player.realm_index),
		"x": snappedf(player.global_position.x, 0.1), "y": snappedf(player.global_position.y, 0.1),
		"vx": snappedf(player.velocity.x, 0.1), "vy": snappedf(player.velocity.y, 0.1), "m": snappedf(float(snapshot.move), 0.01),
		"h": bool(hit.hit), "co": str(hit.collider), "st": int(hit.step), "ct": snappedf(float(hit.crossing), 0.01),
		"hx": snappedf((hit.point as Vector2).x, 0.1), "hy": snappedf((hit.point as Vector2).y, 0.1), "ed": snappedf(float(hit.edge), 0.1)})
	var previous: Dictionary = memory.arc_previous
	if not previous.is_empty() and bool(previous.hit) != bool(hit.hit):
		var move_changed := not is_equal_approx(float(previous.move), float(snapshot.move))
		var expected_vy: float = minf(float(previous.velocity.y) + QA13_FALL_GRAVITY * FRAME_TIME, QA13_FALL_MAX_SPEED)
		var velocity_changed: bool = now - float(memory.last_damage_time) <= 0.25 or player.is_on_wall() or absf(player.velocity.x - float(previous.velocity.x)) > 120.0 or absf(player.velocity.y - expected_vy) > 180.0
		var edge_graze := (bool(previous.hit) and float(previous.edge) >= 0.0 and float(previous.edge) <= FLIP_EDGE_GRAZE) or (bool(hit.hit) and float(hit.edge) >= 0.0 and float(hit.edge) <= FLIP_EDGE_GRAZE)
		var horizon := (bool(previous.hit) and float(previous.crossing) >= 0.85) or (bool(hit.hit) and float(hit.crossing) >= 0.85)
		var cause := "move_input_changed" if move_changed else ("velocity_hit_knockback_wall" if velocity_changed else ("edge_graze" if edge_graze else ("horizon_shift" if horizon else "other")))
		fall_flip_rows.append({"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id), "realm": int(player.realm_index),
			"from_hit": bool(previous.hit), "to_hit": bool(hit.hit), "class": cause, "before_ringout": false,
			"position": _vector_row(player.global_position), "velocity": _vector_row(player.velocity), "move": snappedf(float(snapshot.move), 0.01),
			"previous": _compact_arc(previous), "current": _compact_arc(hit)})
		(memory.arc_flip_indices as Array).append(fall_flip_rows.size() - 1)
	memory.arc_previous = {"hit": bool(hit.hit), "collider": str(hit.collider), "step": int(hit.step), "crossing": float(hit.crossing), "point": hit.point, "edge": float(hit.edge), "move": float(snapshot.move), "velocity": player.velocity}

func _compact_arc(hit: Dictionary) -> Dictionary:
	return {"hit": bool(hit.hit), "collider": str(hit.collider), "step": int(hit.step), "crossing": snappedf(float(hit.crossing), 0.01), "point": _vector_row(hit.point), "edge": snappedf(float(hit.edge), 0.1)}

func _observe_attack_request(player: Node, snapshot: Dictionary) -> void:
	var request := str(snapshot.attack)
	if request == "":
		return
	var attack_type := _current_attack_type(player, snapshot)
	_add_number(attack_request_frames, "%s|%s" % [player.character_id, attack_type], 1.0)

func _observe_ab_suppression(player: Node, memory: Dictionary, now: float) -> void:
	if variant != "b" or player.ai_controller.get("qa13_suppress_serial") == null:
		return
	var serial := int(player.ai_controller.qa13_suppress_serial)
	if serial == int(memory.last_ab_serial):
		var active_index := int(memory.get("ab_row", -1))
		if active_index >= 0 and active_index < ab_suppressed_rows.size() and str(ab_suppressed_rows[active_index].outcome) == "pending" and player.is_on_floor():
			ab_suppressed_rows[active_index].outcome = "landed"
			ab_suppressed_rows[active_index].duration = snappedf(now - float(ab_suppressed_rows[active_index].time), 0.01)
		return
	memory.last_ab_serial = serial
	ab_suppressed_rows.append({"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id), "serial": serial,
		"realm": int(player.realm_index), "position": _vector_row(player.global_position), "velocity": _vector_row(player.velocity),
		"air_jumps_left": int(player.air_jumps_left), "outcome": "pending"})
	memory.ab_row = ab_suppressed_rows.size() - 1

func _observe_progress_drop_edge(player: Node, memory: Dictionary, now: float) -> void:
	var before := target_drop_rows.size()
	super._observe_progress_drop_edge(player, memory, now)
	if target_drop_rows.size() > before:
		_enrich_latest_drop(player, memory, now)

func _observe_target_drop(player: Node, now: float, known_dropped: Node = null, memory: Dictionary = {}) -> void:
	var before := target_drop_rows.size()
	super._observe_target_drop(player, now, known_dropped, memory)
	if target_drop_rows.size() > before:
		_enrich_latest_drop(player, memory, now, known_dropped)

func _enrich_latest_drop(player: Node, memory: Dictionary, now: float, known_dropped: Node = null) -> void:
	var row: Dictionary = target_drop_rows[target_drop_rows.size() - 1]
	if bool(row.get("qa13_enriched", false)):
		return
	row.qa13_enriched = true
	var dropped: Node = known_dropped
	if not is_instance_valid(dropped):
		for candidate in player.ai_controller.ignored_targets:
			if is_instance_valid(candidate):
				dropped = candidate
				break
	if not is_instance_valid(dropped):
		return
	var offset: Vector2 = dropped.global_position - player.global_position
	row.dx = snappedf(offset.x, 0.1)
	row.dy = snappedf(offset.y, 0.1)
	row.target_id = dropped.get_instance_id()
	if str(row.cause) == "no_route":
		var point_info := _reachable_attack_point(player, dropped)
		row.no_route_reason = _no_route_reason(player, dropped, offset, point_info)
		row.reachable_point_within_attack_range = bool(point_info.within)
		row.reachable_point_target_distance = snappedf(float(point_info.distance), 0.1)
		row.reachable_point = _vector_row(point_info.point)
		row.follow = {"new_target_delay": -1.0, "new_target_kind": "", "portal": false, "wander": false, "next_damage_delay": -1.0}
		row.fixture = _capture_fixture(player, dropped, memory)
		no_route_detail_rows.append(row)
		(memory.no_route_pending as Array).append(no_route_detail_rows.size() - 1)
	elif str(row.cause) == "route_not_followed_gap_no_landing":
		fixture_candidates.append({"kind": "gap_no_landing", "seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id),
			"realm": int(player.realm_index), "spot_key": "%d|%d|%d|%d|%d" % [player.realm_index, roundi(player.global_position.x / 50.0) * 50, roundi(player.global_position.y / 50.0) * 50, roundi(dropped.global_position.x / 50.0) * 50, roundi(dropped.global_position.y / 50.0) * 50],
			"fixture": _capture_fixture(player, dropped, memory)})

func _reachable_attack_point(player: Node, target_value: Node) -> Dictionary:
	var best_distance := INF
	var best_point := Vector2.ZERO
	var parent := player.get_parent()
	var points: Array[Vector2] = []
	if parent != null and parent.has_method("get_ai_navigation_points_for_realm"):
		points = parent.get_ai_navigation_points_for_realm(player.realm_index)
	for point in points:
		if player.ai_controller._has_route_to(player, point):
			var distance := point.distance_to(target_value.global_position)
			if distance < best_distance:
				best_distance = distance
				best_point = point
	var attack_range := float(player.ai_controller._combat_profile(player).attack_range)
	return {"within": best_distance <= attack_range, "distance": best_distance if not is_inf(best_distance) else -1.0, "point": best_point}

func _no_route_reason(player: Node, target_value: Node, offset: Vector2, point_info: Dictionary) -> String:
	if offset.y < -float(player.ai_controller.NAV_JUMP_RISE):
		return "rise_over_one_jump"
	if absf(offset.x) > float(player.ai_controller.NAV_GAP_JUMP) and absf(offset.y) <= float(player.ai_controller.NAV_SAME_LEVEL) * 1.5:
		return "gap_wider_than_gap_jump"
	if offset.y > float(player.ai_controller.NAV_DROP_DEPTH) or (offset.y > 0.0 and absf(offset.x) > float(player.ai_controller.NAV_GAP_DROP)):
		return "gap_wider_than_drop"
	if float(point_info.distance) < 0.0 or not bool(point_info.within):
		return "no_navigation_point_near_target"
	return "other"

func _observe_no_route_followup(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var active: Array = []
	for index_value in memory.no_route_pending:
		var index := int(index_value)
		if index < 0 or index >= no_route_detail_rows.size():
			continue
		var row: Dictionary = no_route_detail_rows[index]
		var age := now - float(row.time)
		var follow: Dictionary = row.follow
		var target_value: Variant = player.ai_controller.target
		if float(follow.new_target_delay) < 0.0 and is_instance_valid(target_value) and target_value.get_instance_id() != int(row.target_id):
			follow.new_target_delay = snappedf(age, 0.01)
			follow.new_target_kind = _target_kind(target_value)
		follow.portal = bool(follow.portal) or str(snapshot.state) == "portal"
		follow.wander = bool(follow.wander) or str(snapshot.state) == "wander"
		row.follow = follow
		row.follow_complete = age >= FOLLOW_SECONDS
		no_route_detail_rows[index] = row
		if age < FOLLOW_SECONDS:
			active.append(index)
	memory.no_route_pending = active

func _capture_fixture(player: Node, target_value: Node, memory: Dictionary) -> Dictionary:
	var platforms: Array[Dictionary] = []
	for rect_value in player.ai_controller._platform_rects(player):
		var rect: Rect2 = rect_value
		if rect.get_center().distance_to(player.global_position) <= 800.0 or rect.get_center().distance_to(target_value.global_position) <= 800.0:
			platforms.append({"x": snappedf(rect.position.x, 0.1), "y": snappedf(rect.position.y, 0.1), "w": snappedf(rect.size.x, 0.1), "h": snappedf(rect.size.y, 0.1)})
	var snapshot: Dictionary = player.ai_controller.debug_snapshot(player)
	return {"seed": match_seed, "time": snappedf(main.director.match_elapsed, 0.01), "realm": int(player.realm_index), "platform_rects": platforms,
		"bot": _body_fixture(player), "target": _body_fixture(target_value), "state": str(snapshot.state), "engage_action": str(snapshot.action),
		"profile": player.ai_controller._combat_profile(player).duplicate(true), "blocked_age": snappedf(float(player.ai_controller.blocked_age), 0.01),
		"attack_age": snappedf(float(player.ai_controller.attack_age), 0.01), "navigation_path": _vector_array(player.ai_controller.navigation_path),
		"intents_prior_2s": (memory.intent_history as Array).duplicate(true)}

func _body_fixture(body: Node) -> Dictionary:
	return {"kind": _target_kind(body) if body != null and not body.is_in_group("players") else "player", "character": str(body.get("character_id")) if body.get("character_id") != null else "",
		"position": _vector_row(body.global_position), "velocity": _vector_row(body.velocity if body.get("velocity") != null else Vector2.ZERO),
		"facing": int(body.get("facing")) if body.get("facing") != null else 0, "on_floor": bool(body.is_on_floor()) if body.has_method("is_on_floor") else false}

func _vector_array(values: Array[Vector2]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for value in values:
		rows.append(_vector_row(value))
	return rows

func _observe_dead_band(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var was_empty := (memory.dead_band as Dictionary).is_empty()
	super._observe_dead_band(player, snapshot, memory, now)
	if was_empty and not (memory.dead_band as Dictionary).is_empty() and is_instance_valid(player.ai_controller.target):
		memory.dead_band_capture = _capture_fixture(player, player.ai_controller.target, memory)

func _finalize_dead_band(memory: Dictionary, now: float) -> void:
	var episode: Dictionary = memory.dead_band.duplicate(true)
	var capture: Dictionary = memory.get("dead_band_capture", {}).duplicate(true)
	super._finalize_dead_band(memory, now)
	if not episode.is_empty() and now - float(episode.start) >= DEAD_BAND_MIN_SECONDS and not capture.is_empty():
		fixture_candidates.append({"kind": "inputless_engage", "seed": int(episode.seed), "time": snappedf(float(episode.start), 0.01), "character": str(episode.character), "realm": int(episode.realm), "duration": snappedf(now - float(episode.start), 0.01), "target_kind": str(episode.target_kind), "fixture": capture})
	memory.dead_band_capture = {}

func _observe_recovery_skill_activation(player: Node, snapshot: Dictionary, memory: Dictionary, now: float) -> void:
	var before := (memory.recovery_skill_pending as Array).size()
	super._observe_recovery_skill_activation(player, snapshot, memory, now)
	if (memory.recovery_skill_pending as Array).size() <= before:
		return
	var event: Dictionary = memory.recovery_skill_pending[(memory.recovery_skill_pending as Array).size() - 1]
	var corner := _nearest_ledge_corner(player)
	event.start_position = _vector_row(player.global_position)
	event.ledge_corner = _vector_row(corner)
	event.ledge_dx = snappedf(corner.x - player.global_position.x, 0.1)
	event.ledge_dy = snappedf(corner.y - player.global_position.y, 0.1)
	event.air_jumps_left = int(player.air_jumps_left)
	event.aim = _vector_row(player.ai_controller.aim_direction)
	event.displacement_0_5 = {"x": 0.0, "y": 0.0}
	event.sampled_0_5 = false
	event.hit_within_0_5 = false

func _update_recovery_skill_detail(player: Node, memory: Dictionary, now: float) -> void:
	for event in memory.recovery_skill_pending:
		if not bool(event.get("sampled_0_5", false)) and now - float(event.time) >= 0.5:
			var start := Vector2(float(event.start_position.x), float(event.start_position.y))
			event.displacement_0_5 = _vector_row(player.global_position - start)
			event.sampled_0_5 = true

func _nearest_ledge_corner(player: Node) -> Vector2:
	var best := Vector2.ZERO
	var best_distance := INF
	for rect_value in player.ai_controller._platform_rects(player):
		var rect: Rect2 = rect_value
		for point in [Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y)]:
			var distance: float = player.global_position.distance_to(point)
			if distance < best_distance:
				best_distance = distance
				best = point
	return best

func _observe_target_episode(player: Node, snapshot: Dictionary, memory: Dictionary, phase: String) -> void:
	super._observe_target_episode(player, snapshot, memory, phase)
	if (memory.target_episode as Dictionary).is_empty() or not is_instance_valid(player.ai_controller.target):
		return
	var cause := "pursue_no_closer"
	if float(snapshot.stuck) >= 0.5:
		cause = "stuck"
	elif not player.ai_controller._has_route_to(player, player.ai_controller.target.global_position):
		cause = "no_route"
	elif float(player.ai_controller.blocked_age) < float(player.ai_controller.BLOCKED_MEMORY):
		cause = "blocked_gap"
	elif player.ai_controller._stands_on_other_level(player, player.ai_controller.target):
		cause = "wrong_level"
	var cause_seconds: Dictionary = memory.target_episode.get("cause_seconds", {})
	cause_seconds[cause] = float(cause_seconds.get(cause, 0.0)) + SAMPLE_INTERVAL
	memory.target_episode.cause_seconds = cause_seconds

func _finalize_target_episode(character: String, episode: Dictionary) -> void:
	var qualifies := false
	if not episode.is_empty() and float(episode.seconds) >= NO_PROGRESS_MIN_SECONDS and (float(episode.pursue) >= NO_PROGRESS_MIN_SECONDS or float(episode.far_y) >= NO_PROGRESS_MIN_SECONDS):
		var required := maxf(NO_PROGRESS_MIN_PIXELS, float(episode.start) * 0.1)
		qualifies = float(episode.start) - float(episode.min) < required
	super._finalize_target_episode(character, episode)
	if qualifies:
		for cause in (episode.get("cause_seconds", {}) as Dictionary):
			_add_number(no_progress_causes, "%s|%s" % [character, str(cause)], float(episode.cause_seconds[cause]))

func _on_damaged(player: Node, amount: float, attacker: Node, source: String) -> void:
	var before := ringout_rows.size()
	var now: float = float(main.director.match_elapsed) if is_instance_valid(main) else 0.0
	var pid := player.get_instance_id()
	var memory_before: Dictionary = player_memory.get(pid, {}).duplicate(true)
	var pre := {"position": player.global_position, "velocity": player.velocity, "air_jumps_left": int(player.air_jumps_left),
		"recovery_target": player.ai_controller.recovery_target, "realm": int(player.realm_index), "ringout_y": float(player.ringout_y),
		"blast_left": float(player.blast_left), "blast_right": float(player.blast_right), "skill_ready": bool(player.can_use_skill_one()),
		"attack_lock": float(player.attack_lock_timer), "transformed": bool(player.get("transformed")) if player.get("transformed") != null else false}
	if source == "hit" and not memory_before.is_empty():
		for event in player_memory[pid].get("recovery_skill_pending", []):
			if now - float(event.time) <= 0.5:
				event.hit_within_0_5 = true
	super._on_damaged(player, amount, attacker, source)
	if source == "hit" and is_instance_valid(attacker):
		var attacker_memory: Dictionary = player_memory.get(attacker.get_instance_id(), {})
		for index_value in attacker_memory.get("no_route_pending", []):
			var index := int(index_value)
			if index >= 0 and index < no_route_detail_rows.size():
				var row: Dictionary = no_route_detail_rows[index]
				if float(row.follow.next_damage_delay) < 0.0:
					row.follow.next_damage_delay = snappedf(now - float(row.time), 0.01)
					no_route_detail_rows[index] = row
	if ringout_rows.size() <= before:
		return
	for index_value in memory_before.get("arc_flip_indices", []):
		var flip_index := int(index_value)
		if flip_index >= 0 and flip_index < fall_flip_rows.size():
			fall_flip_rows[flip_index].before_ringout = true
	if variant == "b":
		var ab_index := int(memory_before.get("ab_row", -1))
		if ab_index >= 0 and ab_index < ab_suppressed_rows.size() and str(ab_suppressed_rows[ab_index].outcome) == "pending":
			ab_suppressed_rows[ab_index].outcome = "ringout"
			ab_suppressed_rows[ab_index].duration = snappedf(now - float(ab_suppressed_rows[ab_index].time), 0.01)
	if ["luna", "yuki"].has(str(player.character_id)):
		var position: Vector2 = pre.position
		var recovery_target: Vector2 = pre.recovery_target
		var corner: Vector2 = _nearest_ledge_corner(player)
		var last_hit_age: float = now - float(memory_before.get("last_pvp_hit_received", -99.0))
		var movement_skills: Array[Dictionary] = _luna_yuki_skill_options(player, pre)
		ringout_detail_rows.append({"seed": match_seed, "time": snappedf(now, 0.01), "character": str(player.character_id), "realm": int(pre.realm),
			"last_air_jump_context": str(memory_before.get("last_air_jump_context", "other")), "last_air_jump_age": snappedf(now - float(memory_before.get("last_air_jump_time", -99.0)), 0.01),
			"air_jumps_left": int(pre.air_jumps_left), "position": _vector_row(position), "velocity": _vector_row(pre.velocity),
			"recovery_target_height_above": snappedf(position.y - recovery_target.y, 0.1), "horizontal_to_ledge": snappedf(absf(corner.x - position.x), 0.1),
			"distance_to_blast_line": snappedf(minf(float(pre.ringout_y) - position.y, minf(position.x - float(pre.blast_left), float(pre.blast_right) - position.x)), 0.1),
			"hit_started_it": {"age": snappedf(last_hit_age, 0.01), "source": str(memory_before.get("last_damage_source", "")), "attacker": str(attacker.character_id) if is_instance_valid(attacker) and attacker.is_in_group("players") else "environment"},
			"skills": movement_skills})

func _luna_yuki_skill_options(player: Node, pre: Dictionary) -> Array[Dictionary]:
	if str(player.character_id) == "luna":
		return [
			{"skill": "K/star comet", "moves_fighter": false, "air_effect": "velocity x0.7 while casting", "ready": bool(pre.skill_ready)},
			{"skill": "K/brave comet drive", "moves_fighter": true, "distance": 91.0, "air_effect": "650px/s for 0.14s, only while transformed", "ready": bool(pre.skill_ready) and bool(pre.transformed)},
			{"skill": "L/moon ring", "moves_fighter": false, "air_effect": "vertical velocity x0.5", "ready": float(pre.attack_lock) <= 0.0}
		]
	return [
		{"skill": "K/seal", "moves_fighter": false, "air_effect": "velocity x0.38 while casting", "ready": bool(pre.skill_ready)},
		{"skill": "L/activate", "moves_fighter": false, "air_effect": "none", "ready": float(pre.attack_lock) <= 0.0},
		{"skill": "I/grand ward", "moves_fighter": false, "air_effect": "none", "ready": bool(player.is_ultimate_ready()) and float(pre.attack_lock) <= 0.0}
	]

func _finalize_match_episodes() -> void:
	var now: float = float(main.director.match_elapsed)
	for player in main.players:
		if not is_instance_valid(player) or not player_memory.has(player.get_instance_id()):
			continue
		var memory: Dictionary = player_memory[player.get_instance_id()]
		if variant == "b":
			var ab_index := int(memory.get("ab_row", -1))
			if ab_index >= 0 and ab_index < ab_suppressed_rows.size() and str(ab_suppressed_rows[ab_index].outcome) == "pending":
				ab_suppressed_rows[ab_index].outcome = "landed" if player.is_on_floor() else "unfinished"
				ab_suppressed_rows[ab_index].duration = snappedf(now - float(ab_suppressed_rows[ab_index].time), 0.01)
	super._finalize_match_episodes()
