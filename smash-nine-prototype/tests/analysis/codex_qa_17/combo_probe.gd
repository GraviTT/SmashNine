extends SceneTree

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const FPS := 60.0
const TRIALS_DUMMY := 8
const TRIALS_BOT := 4

var arena: Node2D
var attacker: Node
var target: Node
var frame := 0
var hit_rows: Array[Dictionary] = []
var previous_hp := 0.0
var previous_hitstun := 0.0
var previous_hitstop := 0.0
var recovery_frame := -1
var results: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(1701)
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
		"schema": 1,
		"fixed_fps": 60,
		"input_method": "InputEventAction into PlayerBase._unhandled_input; no combat state mutation",
		"dummy_trials": TRIALS_DUMMY,
		"moving_bot_trials": TRIALS_BOT,
		"trials": results
	}
	var path := ProjectSettings.globalize_path("res://../reports/codex-qa-17/combo-raw.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	print("QA17_COMBO_RESULT ", JSON.stringify(_summarize()))
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
	var route_start_position: Vector2 = target.global_position
	var final_hit_position: Vector2 = target.global_position
	var max_after_hit_distance := 0.0
	var end_frame := 150
	if route.begins_with("Brave"):
		_tap("ultimate")
		for warmup in 90:
			await _observe_frame()
			if attacker.transformed and attacker._can_start_attack():
				break
		hit_rows.clear()
		previous_hp = target.hp
		recovery_frame = -1
	for current in end_frame:
		frame = current
		if not started:
			started = true
			stage = 1
			_start_route(route)
		else:
			stage = _drive_route(route, stage)
		await _observe_frame()
		if not hit_rows.is_empty():
			final_hit_position = hit_rows[-1].position as Vector2
			max_after_hit_distance = maxf(max_after_hit_distance, target.global_position.distance_to(final_hit_position))
		if current > 45 and stage >= _route_stages(route) and attacker.attack_lock_timer <= 0.0 and target.hitstun_timer <= 0.0 and target.hitstop_timer <= 0.0:
			break
	var gaps: Array[int] = []
	for index in range(1, hit_rows.size()):
		gaps.append(int(hit_rows[index].gap_from_previous))
	results.append({
		"character": str(spec.character), "route": route, "moving_bot": moving, "trial": trial,
		"start_distance": float(spec.distance), "expected_hits": int(spec.expected), "hits": hit_rows.size(),
		"connected": hit_rows.size() >= int(spec.expected), "gap_frames": gaps,
		"knockback_distance": snappedf(max_after_hit_distance, 0.1),
		"net_target_displacement": snappedf(target.global_position.distance_to(route_start_position), 0.1),
		"hit_rows": hit_rows.duplicate(true)
	})
	_release_all()
	arena.queue_free()
	await process_frame
	await process_frame

func _new_arena(character: String, distance: float, moving: bool) -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(5000, 100)
	floor_shape.shape = rect
	floor_shape.position = Vector2(0, 50)
	floor.add_child(floor_shape)
	arena.add_child(floor)
	attacker = PLAYER_FACTORY.create(character)
	arena.add_child(attacker)
	attacker.global_position = Vector2(0, -1)
	attacker.setup(CHARACTER_REGISTRY.get_characters()[character], 1, true)
	if moving:
		target = PLAYER_FACTORY.create("rio")
		arena.add_child(target)
		target.global_position = Vector2(distance, -1)
		target.setup(CHARACTER_REGISTRY.get_characters()["rio"], 2, false)
		target.ai_aggression = 0.35
	else:
		target = PLAYER_FACTORY.create("")
		arena.add_child(target)
		target.global_position = Vector2(distance, -1)
		target.setup_dummy(2)
	attacker.ringout_y = 2000.0
	target.ringout_y = 2000.0
	for settle in 8:
		await physics_frame
	_hold("move_right", true)

func _start_route(route: String) -> void:
	if route in ["upJ-airUpJ", "Brave-upJ-airUpJ"]:
		_hold("move_right", false)
		_hold("move_up", true)
	if route in ["L-spike", "L-airJ", "L-sweet", "Brave-L"]:
		_tap("skill_2")
	elif route in ["K-J", "Brave-K-J"]:
		_tap("skill_1")
	else:
		_tap("basic_attack")

func _drive_route(route: String, stage: int) -> int:
	if route == "J1-J2-J3" or route == "Brave-J1-J2-J3":
		if stage < 3 and attacker._can_start_attack():
			_tap("basic_attack")
			return stage + 1
	elif route == "L-spike":
		if stage == 1 and attacker.rising_followup_timer > 0.0 and attacker._can_start_attack():
			_tap("skill_2")
			return 2
	elif route == "L-airJ":
		if stage == 1 and attacker._can_start_attack() and not attacker.is_on_floor():
			_tap("basic_attack")
			return 2
	elif route in ["K-J", "Brave-K-J", "J-K"]:
		if stage == 1 and attacker._can_start_attack():
			_tap("skill_1" if route == "J-K" else "basic_attack")
			return 2
	elif route in ["upJ-airUpJ", "Brave-upJ-airUpJ"]:
		if stage == 1 and attacker._can_start_attack() and not attacker.is_on_floor():
			_tap("basic_attack")
			return 2
	return stage

func _route_stages(route: String) -> int:
	if route in ["J1-J2-J3", "Brave-J1-J2-J3"]:
		return 3
	if route in ["L-spike", "L-airJ", "K-J", "upJ-airUpJ", "J-K", "Brave-upJ-airUpJ", "Brave-K-J"]:
		return 2
	return 1

func _observe_frame() -> void:
	var before_hp: float = float(target.hp) if is_instance_valid(target) else 0.0
	var before_stun: float = float(target.hitstun_timer) if is_instance_valid(target) else 0.0
	var before_stop: float = float(target.hitstop_timer) if is_instance_valid(target) else 0.0
	await physics_frame
	if not is_instance_valid(target):
		return
	if before_stun > 0.0 and target.hitstun_timer <= 0.0 and target.hp == before_hp:
		recovery_frame = frame
	if target.hp < before_hp - 0.001:
		var gap := 999
		if not hit_rows.is_empty():
			if before_stun > 0.0 or before_stop > 0.0:
				gap = -maxi(1, ceili((before_stun + before_stop) * FPS))
			elif recovery_frame >= 0:
				gap = frame - recovery_frame
		hit_rows.append({
			"frame": frame, "damage": snappedf(before_hp - target.hp, 0.01),
			"gap_from_previous": gap, "position": target.global_position,
			"hitstun_after": snappedf(target.hitstun_timer, 0.001),
			"hitstop_after": snappedf(target.hitstop_timer, 0.001)
		})
	previous_hp = target.hp
	previous_hitstun = target.hitstun_timer
	previous_hitstop = target.hitstop_timer

func _tap(action: String) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)

func _hold(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _release_all() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "basic_attack", "skill_1", "skill_2", "ultimate"]:
		Input.action_release(action)

func _summarize() -> Dictionary:
	var groups := {}
	for row in results:
		var key := "%s|%s|%s" % [row.character, row.route, "bot" if row.moving_bot else "dummy"]
		if not groups.has(key):
			groups[key] = {"trials": 0, "connects": 0, "hits": 0, "kb": 0.0, "gaps": []}
		var group: Dictionary = groups[key]
		group.trials += 1
		group.connects += 1 if row.connected else 0
		group.hits += int(row.hits)
		group.kb += float(row.knockback_distance)
		group.gaps.append_array(row.gap_frames)
		groups[key] = group
	for key in groups:
		var group: Dictionary = groups[key]
		group.connect_rate = snappedf(float(group.connects) / float(group.trials), 0.001)
		group.avg_hits = snappedf(float(group.hits) / float(group.trials), 0.01)
		group.avg_knockback_distance = snappedf(float(group.kb) / float(group.trials), 0.1)
	return groups
