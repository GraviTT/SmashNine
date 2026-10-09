extends SceneTree
## Luna, 2026-10-10 night (finishing criteria): the passive "별빛 충전" — a precise star echo
## (trail and bloom on the same target) gives a star, a full set of five cuts the ultimate's
## remaining cooldown, and while the ultimate is ready the stars wait; the Brave J chain plays
## the jab, body kick and spinning kick frames of the Brave attack row; the side echo's bloom opens
## on the body its trail struck, so walking in while swinging still lands both (Codex QA-17: 1 of 8);
## a Luna bot whose laser press comes while she is mid-attack presses again until it fires; a
## Brave comet drive (K) that lands cancels its recovery so the jab follows inside the hitstun.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_precise_echo_star()
	await _test_echo_walk_in()
	await _test_full_charge()
	await _test_brave_chain_poses()
	await _test_bot_laser_retry()
	await _test_brave_k_into_jab()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Luna kit tests passed")
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

func _test_precise_echo_star() -> void:
	var ground := _floor(Vector2(0, 0), 1400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	var foe := _fighter("frey", 2, Vector2(100, -2))
	for frame in 20:
		await physics_frame
	luna.facing = 1
	luna.perform_basic_attack("neutral", Vector2.RIGHT)
	for frame in 30:
		await physics_frame
	if int(luna.star_charge) != 1:
		_fail("A side star echo whose trail and bloom both hit the target should give one star (stars %d)" % luna.star_charge)
	# A swing that only reaches with its bloom gives none.
	foe.global_position = Vector2(200, -2)
	for frame in 20:
		await physics_frame
	luna.perform_basic_attack("neutral", Vector2.RIGHT)
	for frame in 30:
		await physics_frame
	if int(luna.star_charge) != 1:
		_fail("A star echo that hits with its bloom only should give no star (stars %d)" % luna.star_charge)
	luna.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame

## Codex QA-17's input: a player holding toward a dummy 110 px away presses J. Luna walks in while
## the swing comes out; the fixed bloom used to open past the target.
func _test_echo_walk_in() -> void:
	var misses := 0
	for trial in 4:
		var ground := _floor(Vector2(0, 0), 1400)
		var luna: Node = PLAYER_FACTORY.create("luna")
		arena.add_child(luna)
		luna.global_position = Vector2(0, -2)
		luna.setup(CHARACTER_REGISTRY.get_characters()["luna"], 1, true)
		luna.ringout_y = 100000.0
		var dummy: Node = PLAYER_FACTORY.create("")
		arena.add_child(dummy)
		dummy.global_position = Vector2(110, -2)
		dummy.setup_dummy(2)
		dummy.ringout_y = 100000.0
		for frame in 8 + trial:
			await physics_frame
		var hits := []
		dummy.damaged.connect(func(_v, amount, _att, _src): hits.append(amount))
		Input.action_press("move_right")
		var press := InputEventAction.new()
		press.action = "basic_attack"
		press.pressed = true
		Input.parse_input_event(press)
		var release := InputEventAction.new()
		release.action = "basic_attack"
		release.pressed = false
		Input.parse_input_event(release)
		for frame in 40:
			await physics_frame
		Input.action_release("move_right")
		if hits.size() < 2:
			misses += 1
		luna.queue_free()
		dummy.queue_free()
		ground.queue_free()
		await process_frame
	if misses > 0:
		_fail("Walking in from 110 px, the side star echo should land its trail and its bloom (%d of 4 missed the bloom)" % misses)

func _test_full_charge() -> void:
	var luna := _fighter("luna", 1, Vector2(0, -400))
	luna.set_physics_process(false)
	luna.ultimate_cooldown_timer = 20.0
	luna.star_charge = 4
	luna._gain_star()
	if int(luna.star_charge) != 0 or absf(float(luna.ultimate_cooldown_timer) - 14.0) > 0.01:
		_fail("The fifth star should cut the ultimate's cooldown by 6 s and be spent (stars %d, cooldown %.1f)" % [luna.star_charge, luna.ultimate_cooldown_timer])
	luna.ultimate_cooldown_timer = 0.0
	luna.star_charge = 4
	luna._gain_star()
	if int(luna.star_charge) != 5:
		_fail("While the ultimate is ready a full set of stars should wait (stars %d)" % luna.star_charge)
	luna.ultimate_cooldown_timer = 30.0
	luna.set_physics_process(true)
	await physics_frame
	await physics_frame
	if int(luna.star_charge) != 0 or float(luna.ultimate_cooldown_timer) > 24.1:
		_fail("Waiting stars should be spent on the next cooldown (stars %d, cooldown %.1f)" % [luna.star_charge, luna.ultimate_cooldown_timer])
	luna.queue_free()
	await process_frame

## Codex QA-17: Brave K -> J connected 0 of 8 (the comet drive's recovery let the target fly off).
func _test_brave_k_into_jab() -> void:
	var ground := _floor(Vector2(0, 0), 1400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	for frame in 20:
		await physics_frame
	luna._enter_transformation()
	for frame in 30:
		await physics_frame
	# The training dummy Codex measured with (lighter than Frey, so the comet drive throws it farther).
	var target: Node = PLAYER_FACTORY.create("")
	arena.add_child(target)
	target.global_position = Vector2(luna.global_position.x + 120.0, -2)
	target.setup_dummy(3)
	target.ringout_y = 100000.0
	for frame in 6:
		await physics_frame
	var hits := []
	target.damaged.connect(func(_v, _amount, _att, _src): hits.append(float(target.hitstun_timer) + float(target.hitstop_timer)))
	luna.facing = 1
	luna.perform_skill_one()
	for frame in 30:
		await physics_frame
		if hits.size() >= 1 and luna._can_start_attack():
			break
	if hits.size() >= 1:
		luna.perform_basic_attack("neutral", Vector2.RIGHT)
		for frame in 20:
			await physics_frame
			if hits.size() >= 2:
				break
	if hits.size() < 2:
		_fail("Brave K then J: the jab should land after a comet drive that hit (%d hits)" % hits.size())
	elif float(hits[1]) < 0.1:
		# Before the cancel the jab only made it with 0.023 s left: frame-perfect, and 0 of 8 in
		# Codex QA-17's input. Now a player has room to press it.
		_fail("Brave K then J: the jab should land with at least 0.1 s of the comet drive's hitstun left (%.3f)" % float(hits[1]))
	luna.queue_free()
	target.queue_free()
	ground.queue_free()
	await process_frame

func _test_bot_laser_retry() -> void:
	var luna := _fighter("luna", 1, Vector2(0, -400))
	luna.set_physics_process(false)
	luna.is_dummy = false
	var ai = luna.ai_controller
	luna._enter_transformation()
	luna.attack_lock_timer = 0.2
	ai.ultimate_followup_timer = 0.05
	for step in 50:
		luna.attack_lock_timer = maxf(float(luna.attack_lock_timer) - 0.016, 0.0)
		ai._update_ultimate_followups(luna, 0.016)
		if bool(luna.transformation_finishing):
			break
	if not bool(luna.transformation_finishing):
		_fail("A Luna bot whose laser press came mid-attack should press again and fire the heart laser")
	luna.queue_free()
	await process_frame

func _test_brave_chain_poses() -> void:
	var ground := _floor(Vector2(0, 0), 1400)
	var luna := _fighter("luna", 1, Vector2(0, -2))
	for frame in 20:
		await physics_frame
	luna._enter_transformation()
	await physics_frame
	var target := _fighter("frey", 3, Vector2(45, -2))
	for frame in 6:
		await physics_frame
	var hits := []
	target.damaged.connect(func(_v, _amount, _att, _src): hits.append(float(target.hitstun_timer)))
	var first_frames: Array[int] = []
	for hit in 3:
		while not luna._can_start_attack():
			await physics_frame
		luna.perform_basic_attack("neutral", Vector2.RIGHT)
		first_frames.append(int(luna.character_sprite.frame))
	for frame in 30:
		await physics_frame
	var true_combo_misses := 0
	for index in range(1, hits.size()):
		if float(hits[index]) <= 0.0:
			true_combo_misses += 1
	if hits.size() < 3:
		_fail("Brave Luna's J chain: all three hits should land on a target 45 px away (%d did)" % hits.size())
	target.queue_free()
	if true_combo_misses > 0:
		_fail("Brave Luna's J chain should be a true combo once the first hit lands: the next hits land inside the target's hitstun (%d did not)" % true_combo_misses)
	if first_frames != [0, 2, 3]:
		_fail("Brave Luna's jab, body kick and spinning kick should start on frames 0, 2 and 3 (got %s)" % [first_frames])
	luna.queue_free()
	ground.queue_free()
	await process_frame
