extends SceneTree
## Frey, 2026-10-10 night (finishing criteria): the spike after a landed rising cleave can be
## pressed (its window used to close inside the cleave's recovery); a launcher that lands marks
## its target and Frey flies faster toward it ("발키리의 추격"); the three J hits play different
## parts of the attack row; a Frey bot re-presses L for the spike.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_spike_and_pursuit()
	await _test_chain_poses()
	await _test_bot_spike()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Frey kit tests passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _floor(at: Vector2, width: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	shape.shape = rect
	body.add_child(shape)
	arena.add_child(body)
	body.global_position = at + Vector2(0, 20)
	return body

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

func _test_spike_and_pursuit() -> void:
	var ground := _floor(Vector2(0, 0), 1200)
	var frey := _fighter("frey", 1, Vector2(0, -2))
	var foe := _fighter("luna", 2, Vector2(70, -2))
	for frame in 20:
		await physics_frame
	frey.facing = 1
	frey.skill_two()
	var window_seen := false
	for frame in 40:
		await physics_frame
		if float(frey.rising_followup_timer) > 0.0:
			window_seen = true
			break
	if not window_seen:
		_fail("Test setup: Frey's rising cleave should land on the target next to her")
	else:
		if frey.pursuit_target != foe or float(frey.pursuit_timer) <= 0.0:
			_fail("A landed rising cleave should mark its target for Frey's pursuit")
		frey.move_input = 1.0
		var toward: float = frey.get_character_movement_multiplier()
		frey.move_input = -1.0
		var away: float = frey.get_character_movement_multiplier()
		if not frey.is_on_floor() and (absf(toward - float(frey.PURSUIT_SPEED)) > 0.001 or absf(away - 1.0) > 0.001):
			_fail("In the air Frey should fly faster toward the marked target only (toward %.2f, away %.2f)" % [toward, away])
		frey.move_input = 0.0
		if not frey.try_skill_two_followup():
			_fail("The spike should start when L is pressed again inside the window after a landed rising cleave")
	frey.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

func _test_chain_poses() -> void:
	var ground := _floor(Vector2(0, 0), 1200)
	var frey := _fighter("frey", 1, Vector2(0, -2))
	for frame in 20:
		await physics_frame
	var target := _fighter("frey", 3, Vector2(45, -2))
	for frame in 6:
		await physics_frame
	var hits := []
	target.damaged.connect(func(_v, _amount, _att, _src): hits.append(float(target.hitstun_timer)))
	var first_frames: Array[int] = []
	for hit in 3:
		while not frey._can_start_attack():
			await physics_frame
		frey.perform_basic_attack("neutral", Vector2.RIGHT)
		first_frames.append(int(frey.character_sprite.frame))
	for frame in 30:
		await physics_frame
	var true_combo_misses := 0
	for index in range(1, hits.size()):
		if float(hits[index]) <= 0.0:
			true_combo_misses += 1
	if hits.size() < 3:
		_fail("Frey's J chain: all three hits should land on a target 45 px away (%d did)" % hits.size())
	target.queue_free()
	if true_combo_misses > 0:
		_fail("Frey's J chain should be a true combo once the first hit lands: the next hits land inside the target's hitstun (%d did not)" % true_combo_misses)
	if first_frames != [0, 1, 2]:
		_fail("The three J hits should start on attack frames 0, 1 and 2 (got %s)" % [first_frames])
	frey.queue_free()
	ground.queue_free()
	await process_frame

func _test_bot_spike() -> void:
	var frey := _fighter("frey", 1, Vector2(0, -400))
	frey.set_physics_process(false)
	frey.is_dummy = false
	var ai = frey.ai_controller
	var spikes := 0
	for trial in 20:
		frey.action_locked_until_land = false
		frey.attack_lock_timer = 0.3
		frey.rising_followup_timer = 0.18
		for step in 10:
			ai.update(frey, 0.016)
			frey.rising_followup_timer = maxf(float(frey.rising_followup_timer) - 0.016, 0.0)
			if bool(frey.action_locked_until_land):
				spikes += 1
				break
		frey.rising_followup_timer = 0.0
		ai.update(frey, 0.016)
	if spikes < 8:
		_fail("A Frey bot should re-press L inside the spike window most of the time (%d of 20)" % spikes)
	frey.queue_free()
	await process_frame
