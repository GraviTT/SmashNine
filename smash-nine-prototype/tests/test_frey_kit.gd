extends SceneTree
## Frey's kit (user 2026-11-03): the wing passive (hold jump in the air: hover, then a short
## dash-slash in the held direction, or a drop without one; a tap is still the air jump; not while
## flying from a hit), the K sword wave that slows, the L spike pressed again with or without a
## hit, and the descent light that pulls the fighters it reaches unless they guard. Kept from
## 2026-10-10: the three J hits play different parts of the chain row; a Frey bot re-presses L.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_wing_tap()
	await _test_wing_dash()
	await _test_wing_drop()
	await _test_wing_not_while_launched()
	await _test_sword_wave()
	await _test_spike_without_hit()
	await _test_descent_pull()
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

## A human Frey in the air with her one air jump, nothing under her.
func _airborne_frey() -> Node:
	var frey: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(frey)
	frey.global_position = Vector2(0, -2000)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, true)
	frey.ringout_y = 100000.0
	frey.set_process_unhandled_input(false)
	for frame in 4:
		await physics_frame
	frey.air_jumps_left = frey.max_air_jumps
	return frey

func _release_all() -> void:
	for action in ["jump", "move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)

func _test_wing_tap() -> void:
	var frey: Node = await _airborne_frey()
	Input.action_press("jump")
	for frame in 3:
		await physics_frame
	Input.action_release("jump")
	await physics_frame
	await physics_frame
	if bool(frey.wing_hovering) or int(frey.air_jumps_left) != 0 or float(frey.velocity.y) >= 0.0:
		_fail("A tap of jump in the air should stay Frey's air jump (hovering %s, jumps left %d, vy %.0f)" % [frey.wing_hovering, frey.air_jumps_left, frey.velocity.y])
	_release_all()
	frey.queue_free()
	await process_frame

func _test_wing_dash() -> void:
	var frey: Node = await _airborne_frey()
	Input.action_press("jump")
	for frame in 14:
		await physics_frame
	if not bool(frey.wing_hovering) or int(frey.air_jumps_left) != 0:
		_fail("Holding jump in the air should make Frey hover and spend her air jump (hovering %s, jumps left %d)" % [frey.wing_hovering, frey.air_jumps_left])
	var held: Vector2 = frey.global_position
	Input.action_release("jump")
	Input.action_press("move_right")
	Input.action_press("move_down")
	await physics_frame
	if bool(frey.wing_hovering) and frey.global_position.distance_to(held) > 1.0:
		_fail("Frey should hold still while she hovers")
	var dashed := false
	for frame in 30:
		await physics_frame
		if float(frey.skill_dash_timer) > 0.0:
			dashed = true
			break
	if not dashed:
		_fail("After the hover Frey should dash-slash in the held direction")
	elif frey.skill_dash_velocity.x <= 0.0 or frey.skill_dash_velocity.y <= 0.0:
		_fail("The wing dash should go down-right as held (got %s)" % frey.skill_dash_velocity)
	if not bool(frey.action_locked_until_land) or int(frey.air_jumps_left) != 0:
		_fail("After the wing dash Frey should not jump or attack until she lands")
	_release_all()
	frey.queue_free()
	await process_frame

func _test_wing_drop() -> void:
	var frey: Node = await _airborne_frey()
	Input.action_press("jump")
	for frame in 14:
		await physics_frame
	_release_all()
	for frame in 30:
		await physics_frame
	if float(frey.skill_dash_timer) > 0.0 or bool(frey.action_locked_until_land):
		_fail("With no direction held the hover should end in a plain drop, no dash")
	if float(frey.velocity.y) <= 0.0:
		_fail("After a hover with no direction Frey should fall (vy %.0f)" % frey.velocity.y)
	frey.queue_free()
	await process_frame

func _test_wing_not_while_launched() -> void:
	var frey: Node = await _airborne_frey()
	frey.knockback_velocity = Vector2(600, -400)
	Input.action_press("jump")
	for frame in 14:
		await physics_frame
	if bool(frey.wing_hovering):
		_fail("Frey should not hover while she is flying from a hit")
	_release_all()
	frey.queue_free()
	await process_frame

func _test_sword_wave() -> void:
	var ground := _floor(Vector2(0, 0), 1600)
	var frey := _fighter("frey", 1, Vector2(0, -2))
	var foe := _fighter("luna", 2, Vector2(260, -2))
	for frame in 20:
		await physics_frame
	frey.facing = 1
	frey.perform_skill_one()
	var slowed := false
	for frame in 50:
		await physics_frame
		if float(foe.control_slow_timer) > 1.5:
			slowed = true
			break
	if not slowed:
		_fail("Frey's sword wave should hit a fighter 260 px ahead and slow it for about 2 s (slow %.2f)" % float(foe.control_slow_timer))
	frey.queue_free()
	foe.queue_free()
	ground.queue_free()
	await process_frame
	# Up and down tilt the wave a little.
	for tilt in [["move_up", -1.0], ["move_down", 1.0]]:
		var aimer: Node = PLAYER_FACTORY.create("frey")
		arena.add_child(aimer)
		aimer.global_position = Vector2(4000, -2000)
		aimer.setup(CHARACTER_REGISTRY.get_characters()["frey"], 3, true)
		aimer.set_process_unhandled_input(false)
		aimer.set_physics_process(false)
		aimer.facing = 1
		Input.action_press(tilt[0])
		aimer._sword_wave()
		Input.action_release(tilt[0])
		var waves := arena.get_children().filter(func(node): return node.get_script() != null and node.get_script().resource_path == "res://scripts/Projectile.gd" and node.get("source") == aimer)
		var wave: Node = waves.back()
		if signf(float(wave.direction.y)) != float(tilt[1]) or absf(float(wave.direction.y)) > 0.4:
			_fail("Holding %s should tilt the wave a little that way (direction %s)" % [tilt[0], wave.direction])
		aimer.queue_free()
		await process_frame

func _test_spike_without_hit() -> void:
	var ground := _floor(Vector2(0, 0), 1200)
	var frey := _fighter("frey", 1, Vector2(0, -2))
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
		_fail("The rising cleave should open the second press even with nothing to hit")
	elif not frey.try_skill_two_followup():
		_fail("Pressing L again in the window should swing the big air slash")
	elif not bool(frey.action_locked_until_land):
		_fail("After the big air slash Frey should be open until she lands")
	frey.queue_free()
	ground.queue_free()
	await process_frame

func _test_descent_pull() -> void:
	for guarding in [false, true]:
		var ground := _floor(Vector2(0, 0), 1600)
		var frey := _fighter("frey", 1, Vector2(0, -2))
		var foe := _fighter("luna", 2, Vector2(260, -2))
		for frame in 20:
			await physics_frame
		foe.is_guarding = guarding
		var before: float = foe.global_position.distance_to(frey.global_position)
		frey.perform_ultimate()
		for frame in 20:
			await physics_frame
		var after: float = foe.global_position.distance_to(frey.global_position)
		if not guarding and after > before * 0.5:
			_fail("The descent light should pull a fighter 260 px away toward Frey (%.0f -> %.0f px)" % [before, after])
		if guarding and absf(after - before) > 8.0:
			_fail("A guarding fighter should not be pulled by the descent light (%.0f -> %.0f px)" % [before, after])
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
	# Two frames per hit in the 6-frame chain row (D33): wind-up and cut at 1-2, 3-4, 5-6.
	if first_frames != [0, 2, 4]:
		_fail("The three J hits should start on chain frames 0, 2 and 4 (got %s)" % [first_frames])
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
