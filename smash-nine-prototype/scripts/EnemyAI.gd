extends RefCounted

const STATE_WANDER := "wander"
const STATE_PURSUE := "pursue"
const STATE_ENGAGE := "engage"
const STATE_PORTAL := "portal"
const STATE_RECOVER := "recover"

const WORLD_LAYER := 1
const PLAYER_TARGET_RANGE := 5200.0
const MONSTER_TARGET_RANGE := 1500.0
const TARGET_LOCK_TIME := 1.6
const DECISION_TIME_MIN := 0.35
const DECISION_TIME_MAX := 0.7
const ACTION_TIME_MIN := 0.42
const ACTION_TIME_MAX := 0.9
const ATTACK_COOLDOWN_MIN := 0.48
const ATTACK_COOLDOWN_MAX := 1.05
const PORTAL_COOLDOWN := 3.0
const PORTAL_REACHED := 58.0
const JUMP_BUFFER := 0.12

const FLOOR_PROBE_AHEAD := 44.0
const FLOOR_PROBE_DEPTH := 94.0
const SHORT_LANDING_DISTANCE := 118.0
const LONG_LANDING_DISTANCE := 160.0
const LANDING_PATCH_HALF_WIDTH := 24.0
const EDGE_BRAKE_LOOKAHEAD := 0.14
const BLOCKED_PATH_TIME := 0.65
const WAYPOINT_REACHED := 58.0
const STUCK_CHECK_TIME := 1.1
const STUCK_DISTANCE := 20.0
const JUMP_RETRY_TIME := 0.48
const NAV_REPLAN_DISTANCE := 240.0
const NAV_SAME_LEVEL := 92.0
const NAV_HORIZONTAL_REACH := 470.0
const NAV_JUMP_RISE := 185.0
const NAV_JUMP_REACH := 470.0
const NAV_DROP_DEPTH := 360.0
const NAV_DROP_REACH := 470.0
const NAV_DROP_MIN_HORIZONTAL := 86.0
const DROP_PROBE_DEPTH := 390.0

const REALM_WIDTH := 3840.0
const REALM_HEIGHT := 2160.0
const RECOVER_MIN_X := -20.0
const RECOVER_MAX_X := 3860.0
const RECOVER_START_Y := 2160.0
const RECOVER_EXIT_Y := 2100.0
const RECOVER_JUMP_Y := 2200.0

const OFFSCREEN_THINK_MIN := 1.4
const OFFSCREEN_THINK_MAX := 4.5
const OFFSCREEN_STAY_CHANCE := 0.82
const OFFSCREEN_CHASE_CHANCE := 0.38
const OFFSCREEN_WANDER_CHANCE := 0.12

var state: String = STATE_WANDER
var target: Node
var target_lock_timer: float = 0.0
var decision_timer: float = 0.0
var action_timer: float = 0.0
var attack_cooldown: float = 0.0
var portal_cooldown: float = 0.0
var offscreen_timer: float = 0.0

var action: String = "hold"
var last_action: String = ""
var action_direction: float = 1.0
var wander_target: Vector2 = Vector2.ZERO
var waypoint: Vector2 = Vector2.ZERO
var portal_target: Dictionary = {}
var recovery_target: Vector2 = Vector2.ZERO
var recovery_jump_used: bool = false

var stuck_anchor: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var last_commanded_move: float = 0.0
var blocked_direction: float = 0.0
var blocked_timer: float = 0.0
var jump_retry_timer: float = 0.0
var navigation_path: Array[Vector2] = []
var navigation_index: int = 0
var navigation_goal: Vector2 = Vector2.INF
var planned_drop_direction: float = 0.0
var planned_drop_target: Vector2 = Vector2.INF
var row_transition_direction: float = 0.0
var row_transition_target: int = -1

func update(player, delta: float) -> void:
	if player.is_dummy or player.hitstun_timer > 0.0:
		_apply_intent(player, _intent())
		return

	_target_timers(delta)
	_update_stuck(player, delta)

	if _needs_recovery(player):
		_enter_state(STATE_RECOVER)

	if decision_timer <= 0.0 or _must_replan(player):
		_select_state(player)

	var intent: Dictionary = _build_intent(player, delta)
	last_commanded_move = float(intent.get("move", 0.0))
	_apply_intent(player, intent)

func reset(position: Vector2) -> void:
	state = STATE_WANDER
	target = null
	target_lock_timer = 0.0
	decision_timer = 0.0
	action_timer = 0.0
	attack_cooldown = 0.0
	portal_cooldown = 0.0
	offscreen_timer = randf_range(OFFSCREEN_THINK_MIN, OFFSCREEN_THINK_MAX)
	action = "hold"
	last_action = ""
	action_direction = 1.0
	wander_target = Vector2.ZERO
	waypoint = Vector2.ZERO
	portal_target = {}
	recovery_target = Vector2.ZERO
	recovery_jump_used = false
	stuck_anchor = position
	stuck_timer = 0.0
	last_commanded_move = 0.0
	blocked_direction = 0.0
	blocked_timer = 0.0
	jump_retry_timer = 0.0
	navigation_path.clear()
	navigation_index = 0
	navigation_goal = Vector2.INF
	planned_drop_direction = 0.0
	planned_drop_target = Vector2.INF
	row_transition_direction = 0.0
	row_transition_target = -1

func _target_timers(delta: float) -> void:
	decision_timer = maxf(decision_timer - delta, 0.0)
	target_lock_timer = maxf(target_lock_timer - delta, 0.0)
	action_timer = maxf(action_timer - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	portal_cooldown = maxf(portal_cooldown - delta, 0.0)
	blocked_timer = maxf(blocked_timer - delta, 0.0)
	jump_retry_timer = maxf(jump_retry_timer - delta, 0.0)

func _select_state(player) -> void:
	decision_timer = randf_range(DECISION_TIME_MIN, DECISION_TIME_MAX)

	if state == STATE_RECOVER and not _recovery_complete(player):
		return

	if _realm_is_warning(player):
		var escape_portal: Dictionary = _find_portal_target(player)
		if not escape_portal.is_empty():
			portal_target = escape_portal
			_enter_state(STATE_PORTAL)
			return

	_refresh_target(player)
	if is_instance_valid(target):
		var offset: Vector2 = target.global_position - player.global_position
		if _is_in_engage_band(player, offset):
			_enter_state(STATE_ENGAGE)
		else:
			_enter_state(STATE_PURSUE)
		return

	if portal_cooldown <= 0.0 and randf() < 0.1:
		var roaming_portal: Dictionary = _find_portal_target(player)
		if not roaming_portal.is_empty():
			portal_target = roaming_portal
			_enter_state(STATE_PORTAL)
			return

	_enter_state(STATE_WANDER)

func _enter_state(next_state: String) -> void:
	if state == next_state:
		return
	state = next_state
	action_timer = 0.0
	waypoint = Vector2.ZERO
	_clear_navigation_path()
	stuck_timer = 0.0
	if next_state != STATE_PORTAL:
		portal_target = {}
	if next_state == STATE_RECOVER:
		recovery_target = Vector2.ZERO
		recovery_jump_used = false

func _must_replan(player) -> bool:
	if state == STATE_RECOVER:
		return _recovery_complete(player)
	if state == STATE_PORTAL:
		return portal_target.is_empty()
	if is_instance_valid(target) and _target_invalid(player):
		return true
	if stuck_timer >= STUCK_CHECK_TIME:
		_clear_navigation_path()
		return true
	return false

func _build_intent(player, delta: float) -> Dictionary:
	match state:
		STATE_RECOVER:
			return _recover_intent(player)
		STATE_PORTAL:
			return _portal_intent(player)
		STATE_ENGAGE:
			return _engage_intent(player, delta)
		STATE_PURSUE:
			return _pursue_intent(player)
		_:
			return _wander_intent(player)

func _intent(move: float = 0.0, jump: bool = false, attack: String = "") -> Dictionary:
	return {"move": move, "jump": jump, "attack": attack}

func _apply_intent(player, intent: Dictionary) -> void:
	player.move_input = float(intent.get("move", 0.0))
	if bool(intent.get("jump", false)):
		player.jump_buffer_timer = JUMP_BUFFER
	var attack_name: String = str(intent.get("attack", ""))
	if attack_name == "" or player.attack_lock_timer > 0.0:
		return
	match attack_name:
		"basic":
			player.basic_attack()
		"skill_1":
			player.skill_one()
		"skill_2":
			player.skill_two()

func _wander_intent(player) -> Dictionary:
	if wander_target == Vector2.ZERO or player.global_position.distance_to(wander_target) <= WAYPOINT_REACHED:
		wander_target = _choose_wander_point(player)
	var destination: Vector2 = _navigation_destination(player, wander_target)
	return _navigate_to_intent(player, destination)

func _pursue_intent(player) -> Dictionary:
	if not is_instance_valid(target):
		return _wander_intent(player)
	var row_transition_intent: Dictionary = _downward_row_transition_intent(player, target.global_position)
	if not row_transition_intent.is_empty():
		return row_transition_intent
	var destination: Vector2 = _choose_pursuit_destination(player, target.global_position)
	return _navigate_to_intent(player, destination)

func _downward_row_transition_intent(player, target_position: Vector2) -> Dictionary:
	var local_y: float = player.global_position.y - player.realm_origin.y
	var target_local_y: float = target_position.y - player.realm_origin.y
	var current_row: int = clampi(floori(local_y / 720.0), 0, 2)
	var target_row: int = clampi(floori(target_local_y / 720.0), 0, 2)
	if target_row <= current_row:
		row_transition_direction = 0.0
		row_transition_target = -1
		return {}
	if row_transition_target != target_row or is_zero_approx(row_transition_direction):
		var local_x: float = player.global_position.x - player.realm_origin.x
		row_transition_direction = -1.0 if local_x <= REALM_WIDTH * 0.5 else 1.0
		row_transition_target = target_row
		_clear_navigation_path()
	if player.is_on_floor():
		var step_jump: bool = stuck_timer >= 0.45 and jump_retry_timer <= 0.0
		if step_jump:
			jump_retry_timer = JUMP_RETRY_TIME
		return _intent(row_transition_direction, step_jump)
	var local_x: float = player.global_position.x - player.realm_origin.x
	var crossed_outer_edge: bool = local_x < 145.0 or local_x > REALM_WIDTH - 145.0
	var crossed_row_boundary: bool = local_y > float(current_row + 1) * 720.0 + 80.0
	var recovery_jump: bool = player.air_jumps_left > 0 and player.velocity.y > 320.0 and local_y > float(current_row + 1) * 720.0 + 260.0
	var air_direction: float = -row_transition_direction if crossed_outer_edge or crossed_row_boundary else row_transition_direction
	return _intent(air_direction, recovery_jump)

func _engage_intent(player, delta: float) -> Dictionary:
	if not is_instance_valid(target):
		return _wander_intent(player)

	var offset: Vector2 = target.global_position - player.global_position
	var distance_x: float = absf(offset.x)
	var distance_y: float = absf(offset.y)
	var target_direction: float = signf(offset.x)
	if is_zero_approx(target_direction):
		target_direction = float(player.facing)
	else:
		player.facing = signi(int(target_direction))

	if action_timer <= 0.0:
		_choose_engage_action(player, distance_x, distance_y, target_direction)

	var move: float = 0.0
	var jump: bool = false
	match action:
		"approach":
			move = target_direction
		"retreat":
			move = -target_direction
		"cross":
			move = action_direction
		"jump_in":
			move = target_direction
			jump = player.is_on_floor() and (offset.y < -55.0 or not _has_floor_ahead(player, target_direction, FLOOR_PROBE_AHEAD))
		"hold":
			move = 0.0

	var terrain_intent: Dictionary = _terrain_move_intent(player, move, jump, action == "approach" or action == "jump_in")
	var attack_name: String = _choose_attack(player, distance_x, distance_y)
	terrain_intent["attack"] = attack_name
	return terrain_intent

func _choose_engage_action(player, distance_x: float, distance_y: float, target_direction: float) -> void:
	var profile: Dictionary = _combat_profile(player)
	var min_range: float = float(profile.min_range)
	var max_range: float = float(profile.max_range)
	var candidates: Array[String] = []

	if distance_x > max_range:
		candidates = ["approach", "approach", "jump_in"]
	elif distance_x < min_range:
		candidates = ["hold", "hold", "cross", "approach"]
	else:
		candidates = ["hold", "cross", "approach", "jump_in"]

	if distance_y > 120.0:
		candidates = ["approach", "jump_in"]

	action = _pick_non_repeating_action(candidates)
	last_action = action
	action_timer = randf_range(ACTION_TIME_MIN, ACTION_TIME_MAX)
	action_direction = target_direction if randf() < 0.5 else -target_direction

func _pick_non_repeating_action(candidates: Array[String]) -> String:
	var filtered: Array[String] = []
	for candidate in candidates:
		if candidate != last_action:
			filtered.append(candidate)
	if filtered.is_empty():
		filtered = candidates.duplicate()
	var index: int = randi_range(0, filtered.size() - 1)
	return filtered[index]

func _choose_attack(player, distance_x: float, distance_y: float) -> String:
	if attack_cooldown > 0.0 or player.attack_lock_timer > 0.0:
		return ""
	var profile: Dictionary = _combat_profile(player)
	if distance_x > float(profile.attack_range) or distance_y > 115.0:
		return ""

	attack_cooldown = randf_range(ATTACK_COOLDOWN_MIN, ATTACK_COOLDOWN_MAX)
	var roll: float = randf()
	var attack_name: String
	if distance_x < 88.0:
		attack_name = "basic" if roll < 0.82 else "skill_1"
	elif roll < 0.62:
		attack_name = "basic"
	elif roll < 0.88:
		attack_name = "skill_1"
	else:
		attack_name = "skill_2"
	if attack_name == "skill_1" and not _mobility_skill_is_safe(player):
		return "basic" if distance_x <= 195.0 else "skill_2"
	return attack_name

func _mobility_skill_is_safe(player) -> bool:
	if player.character_id != "frey" and player.character_id != "nova":
		return true
	if not player.is_on_floor():
		return false
	var direction: float = float(player.facing)
	var local_x: float = player.global_position.x - player.realm_origin.x
	if direction < 0.0 and local_x < 220.0:
		return false
	if direction > 0.0 and local_x > REALM_WIDTH - 220.0:
		return false
	if _has_floor_ahead(player, direction, 90.0) and _has_floor_ahead(player, direction, 155.0):
		return true
	return _has_landing_patch(player, direction, LONG_LANDING_DISTANCE)

func _combat_profile(_player) -> Dictionary:
	return {"min_range": 65.0, "max_range": 215.0, "attack_range": 235.0}

func _navigate_to_intent(player, destination: Vector2) -> Dictionary:
	var offset: Vector2 = destination - player.global_position
	var direction: float = _direction_to(player.global_position.x, destination.x)
	var wants_jump: bool = offset.y < -48.0
	var allow_drop: bool = offset.y > 72.0
	if allow_drop and player.is_on_floor():
		if planned_drop_target == Vector2.INF or planned_drop_target.distance_to(destination) > WAYPOINT_REACHED:
			planned_drop_direction = 0.0
			planned_drop_target = destination
		if is_zero_approx(planned_drop_direction):
			planned_drop_direction = _choose_drop_direction(player, destination.x)
		if not is_zero_approx(planned_drop_direction):
			direction = planned_drop_direction
	else:
		planned_drop_direction = 0.0
		planned_drop_target = Vector2.INF
	return _terrain_move_intent(player, direction, wants_jump, true, allow_drop)

func _terrain_move_intent(player, direction: float, wants_jump: bool, allow_gap_jump: bool, allow_drop: bool = false) -> Dictionary:
	if is_zero_approx(direction):
		if wants_jump and player.is_on_floor() and jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(0.0, true)
		return _intent()
	if not player.is_on_floor():
		return _intent(direction, false)
	if blocked_timer > 0.0 and signf(direction) == signf(blocked_direction):
		return _intent()
	if stuck_timer >= 0.45 and jump_retry_timer <= 0.0:
		jump_retry_timer = JUMP_RETRY_TIME
		return _intent(direction, true)
	var speed_lookahead: float = absf(player.velocity.x) * EDGE_BRAKE_LOOKAHEAD
	var probe_distance: float = FLOOR_PROBE_AHEAD + speed_lookahead
	if _has_floor_ahead(player, direction, probe_distance):
		if wants_jump and jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(direction, true)
		return _intent(direction)
	if allow_drop:
		return _intent(direction)
	if allow_gap_jump and _has_jump_landing(player, direction):
		if jump_retry_timer <= 0.0:
			jump_retry_timer = JUMP_RETRY_TIME
			return _intent(direction, true)
		return _intent()
	blocked_direction = direction
	blocked_timer = BLOCKED_PATH_TIME
	decision_timer = 0.0
	waypoint = Vector2.ZERO
	_clear_navigation_path()
	if absf(player.velocity.x) > 35.0 and signf(player.velocity.x) == signf(direction):
		return _intent(-direction)
	return _intent()

func _choose_drop_direction(player, destination_x: float) -> float:
	var preferred: float = signf(destination_x - player.global_position.x)
	if is_zero_approx(preferred):
		preferred = float(player.facing)
	var preferred_edge: float = _floor_edge_distance(player, preferred)
	var opposite_edge: float = _floor_edge_distance(player, -preferred)
	if preferred_edge <= opposite_edge + 100.0:
		return preferred
	return -preferred

func _floor_edge_distance(player, direction: float) -> float:
	var foot: Vector2 = player.global_position
	for distance in range(60, 3901, 80):
		var ray_x: float = direction * float(distance)
		if not _ray_hits_world(player, foot + Vector2(ray_x, -55.0), foot + Vector2(ray_x, FLOOR_PROBE_DEPTH)):
			return float(distance)
	return INF

func _has_drop_landing(player, direction: float) -> bool:
	if is_zero_approx(direction):
		return false
	var foot: Vector2 = player.global_position
	for distance in [72.0, 118.0]:
		var ray_x: float = direction * float(distance)
		if _ray_hits_world(player, foot + Vector2(ray_x, 12.0), foot + Vector2(ray_x, DROP_PROBE_DEPTH)):
			return true
	return false

func _has_floor_ahead(player, direction: float, distance: float) -> bool:
	var foot: Vector2 = player.global_position
	var ray_x: float = direction * distance
	return _ray_hits_world(player, foot + Vector2(ray_x, -8.0), foot + Vector2(ray_x, FLOOR_PROBE_DEPTH))

func _has_jump_landing(player, direction: float) -> bool:
	for distance in [SHORT_LANDING_DISTANCE, LONG_LANDING_DISTANCE]:
		if _has_landing_patch(player, direction, float(distance)):
			return true
	return false

func _has_landing_patch(player, direction: float, distance: float) -> bool:
	var foot: Vector2 = player.global_position
	var center_x: float = direction * distance
	var inner_x: float = center_x - direction * LANDING_PATCH_HALF_WIDTH
	var outer_x: float = center_x + direction * LANDING_PATCH_HALF_WIDTH
	var center_hit: bool = _ray_hits_world(player, foot + Vector2(center_x, -90.0), foot + Vector2(center_x, 145.0))
	var inner_hit: bool = _ray_hits_world(player, foot + Vector2(inner_x, -90.0), foot + Vector2(inner_x, 145.0))
	var outer_hit: bool = _ray_hits_world(player, foot + Vector2(outer_x, -90.0), foot + Vector2(outer_x, 145.0))
	return center_hit and inner_hit and outer_hit

func _ray_hits_world(player, from: Vector2, to: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.from = from
	query.to = to
	query.collision_mask = WORLD_LAYER
	query.exclude = [player.get_rid()]
	var result: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	return not result.is_empty()

func _needs_recovery(player) -> bool:
	if state == STATE_RECOVER:
		return not _recovery_complete(player)
	var local_position: Vector2 = player.global_position - player.realm_origin
	if local_position.x < RECOVER_MIN_X or local_position.x > RECOVER_MAX_X:
		return true
	return not player.is_on_floor() and local_position.y > RECOVER_START_Y and player.velocity.y > 0.0

func _recovery_complete(player) -> bool:
	var local_position: Vector2 = player.global_position - player.realm_origin
	return player.is_on_floor() and local_position.y < RECOVER_EXIT_Y and local_position.x >= 0.0 and local_position.x <= REALM_WIDTH

func _recover_intent(player) -> Dictionary:
	if recovery_target == Vector2.ZERO:
		recovery_target = _choose_recovery_point(player)
	var direction: float = _direction_to(player.global_position.x, recovery_target.x)
	var local_y: float = player.global_position.y - player.realm_origin.y
	var jump: bool = false
	if not recovery_jump_used and player.air_jumps_left > 0 and local_y >= RECOVER_JUMP_Y:
		jump = true
		recovery_jump_used = true
	return _intent(direction, jump)

func _choose_recovery_point(player) -> Vector2:
	var best: Vector2 = player.realm_origin + Vector2(REALM_WIDTH * 0.5, 560.0)
	var best_score: float = INF
	for point in player.spawn_points:
		var local_point: Vector2 = point - player.realm_origin
		if local_point.x < 100.0 or local_point.x > REALM_WIDTH - 100.0:
			continue
		var score: float = absf(point.x - player.global_position.x) + maxf(point.y - player.global_position.y, 0.0) * 1.8
		if score < best_score:
			best_score = score
			best = point
	return best

func _portal_intent(player) -> Dictionary:
	if portal_target.is_empty():
		return _intent()
	if _try_use_portal(player):
		portal_target = {}
		portal_cooldown = PORTAL_COOLDOWN
		_enter_state(STATE_WANDER)
		return _intent()
	var center: Vector2 = portal_target.rect.get_center()
	var destination: Vector2 = _navigation_destination(player, center)
	return _navigate_to_intent(player, destination)

func _refresh_target(player) -> void:
	if is_instance_valid(target) and target_lock_timer > 0.0 and not _target_invalid(player):
		return
	target = _find_target(player)
	target_lock_timer = TARGET_LOCK_TIME if is_instance_valid(target) else 0.0

func _find_target(player) -> Node:
	var best: Node = null
	var best_score: float = INF
	for candidate in player.get_tree().get_nodes_in_group("players"):
		if not _is_valid_target_candidate(player, candidate):
			continue
		var offset: Vector2 = candidate.global_position - player.global_position
		var distance: float = offset.length()
		if distance > PLAYER_TARGET_RANGE:
			continue
		var score: float = distance + absf(offset.y) * 0.12
		if score < best_score:
			best_score = score
			best = candidate
	for candidate in player.get_tree().get_nodes_in_group("realm_monsters"):
		if not _is_valid_target_candidate(player, candidate):
			continue
		var offset: Vector2 = candidate.global_position - player.global_position
		var distance: float = offset.length()
		if distance > MONSTER_TARGET_RANGE:
			continue
		var score: float = distance + 320.0 + absf(offset.y) * 0.12
		if score < best_score:
			best_score = score
			best = candidate
	return best

func _target_invalid(player) -> bool:
	if not _is_valid_target_candidate(player, target):
		return true
	var max_range: float = MONSTER_TARGET_RANGE * 1.25 if target.is_in_group("realm_monsters") else PLAYER_TARGET_RANGE * 1.1
	return player.global_position.distance_to(target.global_position) > max_range

func _is_valid_target_candidate(player, candidate: Node) -> bool:
	if not is_instance_valid(candidate) or candidate == player:
		return false
	if candidate.is_in_group("players"):
		if bool(candidate.get("is_dummy")) or bool(candidate.get("is_defeated")):
			return false
	elif candidate.is_in_group("realm_monsters"):
		var hp_value: Variant = candidate.get("hp")
		if hp_value == null or float(hp_value) <= 0.0:
			return false
	else:
		return false
	return int(candidate.get("realm_index")) == player.realm_index and bool(candidate.get("is_realm_active"))

func _is_in_engage_band(player, offset: Vector2) -> bool:
	var profile: Dictionary = _combat_profile(player)
	return absf(offset.x) <= float(profile.max_range) + 70.0 and absf(offset.y) <= 150.0

func _choose_pursuit_destination(player, target_position: Vector2) -> Vector2:
	if absf(target_position.y - player.global_position.y) <= NAV_SAME_LEVEL:
		_clear_navigation_path()
		return target_position
	return _navigation_destination(player, target_position)

func _navigation_destination(player, desired_goal: Vector2) -> Vector2:
	var needs_plan: bool = navigation_path.is_empty() or navigation_index >= navigation_path.size()
	if navigation_goal == Vector2.INF or navigation_goal.distance_to(desired_goal) > NAV_REPLAN_DISTANCE:
		needs_plan = true
	if player.is_on_floor() and navigation_index < navigation_path.size():
		var current_waypoint: Vector2 = navigation_path[navigation_index]
		if current_waypoint.y < player.global_position.y - NAV_JUMP_RISE - 24.0:
			needs_plan = true
	if needs_plan:
		navigation_path = _plan_navigation_path(player, desired_goal)
		navigation_index = 0
		navigation_goal = desired_goal
	while navigation_index < navigation_path.size() and player.global_position.distance_to(navigation_path[navigation_index]) <= WAYPOINT_REACHED:
		navigation_index += 1
	if navigation_index < navigation_path.size():
		return navigation_path[navigation_index]
	return desired_goal

func _plan_navigation_path(player, desired_goal: Vector2) -> Array[Vector2]:
	var parent: Node = player.get_parent()
	if parent == null or not parent.has_method("get_ai_navigation_points_for_realm"):
		return []
	var navigation_points: Array[Vector2] = parent.get_ai_navigation_points_for_realm(player.realm_index)
	if navigation_points.is_empty():
		return []

	var nodes: Array[Vector2] = [player.global_position]
	nodes.append_array(navigation_points)
	var goal_index: int = 1
	var best_goal_score: float = INF
	for index in range(1, nodes.size()):
		var goal_offset: Vector2 = nodes[index] - desired_goal
		var goal_score: float = absf(goal_offset.x) + absf(goal_offset.y) * 1.7
		if goal_score < best_goal_score:
			best_goal_score = goal_score
			goal_index = index

	var open_nodes: Array[int] = [0]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {0: 0.0}
	var f_score: Dictionary = {0: player.global_position.distance_to(nodes[goal_index])}
	while not open_nodes.is_empty():
		var current: int = _lowest_score_node(open_nodes, f_score)
		if current == goal_index:
			return _reconstruct_navigation_path(nodes, came_from, current)
		open_nodes.erase(current)
		for neighbor in nodes.size():
			if neighbor == current or not _navigation_link_is_reachable(nodes[current], nodes[neighbor]):
				continue
			var tentative_score: float = float(g_score.get(current, INF)) + _navigation_link_cost(nodes[current], nodes[neighbor])
			if tentative_score >= float(g_score.get(neighbor, INF)):
				continue
			came_from[neighbor] = current
			g_score[neighbor] = tentative_score
			f_score[neighbor] = tentative_score + nodes[neighbor].distance_to(nodes[goal_index])
			if not open_nodes.has(neighbor):
				open_nodes.append(neighbor)
	return []

func _lowest_score_node(open_nodes: Array[int], scores: Dictionary) -> int:
	var best_node: int = open_nodes[0]
	var best_score: float = float(scores.get(best_node, INF))
	for node in open_nodes:
		var score: float = float(scores.get(node, INF))
		if score < best_score:
			best_score = score
			best_node = node
	return best_node

func _reconstruct_navigation_path(nodes: Array[Vector2], came_from: Dictionary, current: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	while current != 0:
		result.push_front(nodes[current])
		if not came_from.has(current):
			return []
		current = int(came_from[current])
	return result

func _navigation_link_is_reachable(from: Vector2, to: Vector2) -> bool:
	var delta: Vector2 = to - from
	var horizontal: float = absf(delta.x)
	if absf(delta.y) <= NAV_SAME_LEVEL:
		return horizontal <= NAV_HORIZONTAL_REACH
	if delta.y < 0.0:
		return -delta.y <= NAV_JUMP_RISE and horizontal <= NAV_JUMP_REACH
	return delta.y <= NAV_DROP_DEPTH and horizontal >= NAV_DROP_MIN_HORIZONTAL and horizontal <= NAV_DROP_REACH

func _navigation_link_cost(from: Vector2, to: Vector2) -> float:
	var delta: Vector2 = to - from
	var vertical_penalty: float = -delta.y * 0.8 if delta.y < 0.0 else delta.y * 0.25
	return delta.length() + vertical_penalty

func _clear_navigation_path() -> void:
	navigation_path.clear()
	navigation_index = 0
	navigation_goal = Vector2.INF
	planned_drop_direction = 0.0
	planned_drop_target = Vector2.INF

func _choose_wander_point(player) -> Vector2:
	var safe_points: Array[Vector2] = []
	var parent: Node = player.get_parent()
	var available_points: Array[Vector2] = player.spawn_points
	if parent != null and parent.has_method("get_ai_navigation_points_for_realm"):
		available_points = parent.get_ai_navigation_points_for_realm(player.realm_index)
	for point in available_points:
		var local_x: float = point.x - player.realm_origin.x
		var distance: float = player.global_position.distance_to(point)
		if local_x >= 120.0 and local_x <= REALM_WIDTH - 120.0 and distance >= 320.0 and distance <= 1250.0:
			safe_points.append(point)
	if safe_points.is_empty():
		return player.realm_origin + Vector2(REALM_WIDTH * 0.5, 560.0)
	var index: int = randi_range(0, safe_points.size() - 1)
	return safe_points[index]

func _direction_to(from_x: float, to_x: float) -> float:
	if absf(to_x - from_x) <= 38.0:
		return 0.0
	return signf(to_x - from_x)

func _update_stuck(player, delta: float) -> void:
	if stuck_anchor == Vector2.ZERO:
		stuck_anchor = player.global_position
		return
	if absf(last_commanded_move) > 0.01 and player.global_position.distance_to(stuck_anchor) < STUCK_DISTANCE:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		stuck_anchor = player.global_position

func _realm_is_warning(player) -> bool:
	var parent: Node = player.get_parent()
	return parent != null and parent.has_method("_get_realm_state") and parent._get_realm_state(player.realm_index) == "warning"

func _find_portal_target(player) -> Dictionary:
	var parent: Node = player.get_parent()
	if parent == null or not parent.has_method("get_ai_portals_for_realm"):
		return {}
	var portals: Array = parent.get_ai_portals_for_realm(player.realm_index)
	var best: Dictionary = {}
	var best_score: float = INF
	for portal in portals:
		var score: float = player.global_position.distance_to(portal.rect.get_center())
		if portal.destination_state == "warning":
			score += 800.0
		if score < best_score:
			best_score = score
			best = portal
	return best

func _try_use_portal(player) -> bool:
	if portal_target.is_empty() or not player.is_on_floor():
		return false
	var rect: Rect2 = portal_target.rect
	if not rect.grow(PORTAL_REACHED).has_point(player.global_position):
		return false
	var parent: Node = player.get_parent()
	if parent != null and parent.has_method("move_ai_through_portal"):
		parent.move_ai_through_portal(player, portal_target)
		return true
	return false

func update_offscreen_realm(player, delta: float, combatants: Array[Node], portals: Array[Dictionary], current_state: String, get_realm_state: Callable, get_grid_distance: Callable) -> Dictionary:
	offscreen_timer = maxf(offscreen_timer - delta, 0.0)
	if offscreen_timer > 0.0 or portals.is_empty():
		return {}
	offscreen_timer = randf_range(OFFSCREEN_THINK_MIN, OFFSCREEN_THINK_MAX)
	if current_state == "warning":
		return _pick_escape_portal(portals, get_realm_state)

	var local_opponents: Array[Node] = _offscreen_opponents(player, combatants)
	if not local_opponents.is_empty() and randf() < OFFSCREEN_STAY_CHANCE:
		return {}
	var target_realm: int = _offscreen_target_realm(player, combatants)
	if target_realm >= 0 and randf() < OFFSCREEN_CHASE_CHANCE:
		return _portal_toward_realm(portals, target_realm, get_realm_state, get_grid_distance)
	if randf() < OFFSCREEN_WANDER_CHANCE:
		return _random_safe_portal(portals, get_realm_state)
	return {}

func _offscreen_opponents(player, combatants: Array[Node]) -> Array[Node]:
	var result: Array[Node] = []
	for candidate in combatants:
		if candidate != player and is_instance_valid(candidate) and not candidate.is_dummy and not candidate.is_defeated and candidate.realm_index == player.realm_index:
			result.append(candidate)
	return result

func _offscreen_target_realm(player, combatants: Array[Node]) -> int:
	var candidates: Array[Node] = []
	for candidate in combatants:
		if candidate != player and is_instance_valid(candidate) and not candidate.is_dummy and not candidate.is_defeated and candidate.realm_index != player.realm_index:
			candidates.append(candidate)
	if candidates.is_empty():
		return -1
	var index: int = randi_range(0, candidates.size() - 1)
	return candidates[index].realm_index

func _pick_escape_portal(portals: Array[Dictionary], get_realm_state: Callable) -> Dictionary:
	var stable: Array[Dictionary] = []
	for portal in portals:
		if str(get_realm_state.call(portal.destination)) == "stable":
			stable.append(portal)
	return _random_portal(stable if not stable.is_empty() else portals)

func _portal_toward_realm(portals: Array[Dictionary], target_realm: int, get_realm_state: Callable, get_grid_distance: Callable) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = INF
	for portal in portals:
		var score: float = float(get_grid_distance.call(portal.destination, target_realm)) * 100.0
		if str(get_realm_state.call(portal.destination)) == "warning":
			score += 300.0
		if score < best_score:
			best_score = score
			best = portal
	return best

func _random_safe_portal(portals: Array[Dictionary], get_realm_state: Callable) -> Dictionary:
	var safe: Array[Dictionary] = []
	for portal in portals:
		if str(get_realm_state.call(portal.destination)) != "warning":
			safe.append(portal)
	return _random_portal(safe if not safe.is_empty() else portals)

func _random_portal(portals: Array[Dictionary]) -> Dictionary:
	if portals.is_empty():
		return {}
	var index: int = randi_range(0, portals.size() - 1)
	return portals[index]
