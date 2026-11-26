extends SceneTree
## Rio's kit v3 (user 2026-11-18 "제안대로 넣기", D50). Passive "급소": hits from behind deal 1.5x
## (the two air jumps and their mana steps stay). J: the third hit dashes through to the target's
## back and stops at a ledge. K "마검 투척": a sword that sticks in a foe, a wall or mid-air; the
## second K blinks to it (behind a struck foe) and slashes; one throw per airtime. L "그림자
## 받아치기": a stance whose first hit does nothing and sends him behind the attacker; a whiff is
## punished. U "분신 바꿔치기": a decoy and a step back, one swap, a foe's hit bursts it. I "마검
## 난무": gem swords stick in nearby foes; the second I cuts through them all and brings him back,
## or they burst. Bots blink to a stuck sword and cut on their own.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const GAME_SCALE := preload("res://scripts/GameScale.gd")
const SOUL_CARDS := preload("res://scripts/match/SoulCards.gd")
const ATTACK_PATH := "res://scripts/Attack.gd"

## Every scene is played twice: round the world origin and far from it. The tests place and read
## everything through _put and _at, in scene coordinates, so the same numbers hold for both; the
## arena stays on the world origin, as the node that holds the fighters does in a match. A scene
## played only round the origin cannot tell a thing left at (0, 0) from one left in its place:
## the decoy stood at the origin in every match while its tests passed (2026-11-25).
const SCENES: Array[Vector2] = [Vector2.ZERO, Vector2(9000, 6000)]

var arena: Node2D
var scene := Vector2.ZERO
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for origin in SCENES:
		scene = origin
		for test in [_test_air_jumps, _test_air_step_effect, _test_backstab, _test_pierce, _test_pierce_ledge,
				_test_sword_blink, _test_sword_air_and_end, _test_counter, _test_counter_attacker_freed, _test_counter_whiff, _test_decoy, _test_decoy_takes_a_swing,
				_test_flurry, _test_flurry_target_freed, _test_flurry_moved_mid_cut, _test_flurry_burst, _test_bots, _test_third_skill_slot]:
			await test.call()
			await _clear()
			if failed:
				quit(1)
				return
	arena.queue_free()
	await process_frame
	print("Rio kit tests passed (each scene round the origin and at %s)" % SCENES[1])
	quit(0)

func _fail(message: String) -> void:
	push_error("%s (scene at %s)" % [message, scene])
	failed = true

## Where a node stands, and putting it somewhere, in scene coordinates.
func _at(node: Node2D) -> Vector2:
	return node.global_position - scene

func _put(node: Node2D, at: Vector2) -> void:
	node.global_position = scene + at

func _floor(at: Vector2, width: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	shape.shape = rect
	body.add_child(shape)
	# Placed before it enters the tree: one frame at the origin would push a fighter up.
	body.position = scene + at + Vector2(0, 20)
	arena.add_child(body)
	return body

## Rio as a person (no input read here) unless `bot`; a bot here is a dummy-driven body with his
## own follow-ups (no AI moves).
func _rio(at: Vector2, bot := false, body := "male") -> Node:
	var rio: Node = PLAYER_FACTORY.create("rio", body)
	arena.add_child(rio)
	_put(rio, at)
	rio.setup(CHARACTER_REGISTRY.get_characters()["rio"], 1, not bot)
	rio.ringout_y = 100000.0
	if bot:
		rio.is_dummy = true
	else:
		rio.set_process_unhandled_input(false)
	return rio

func _dummy(player_id: int, at: Vector2, facing: int) -> Node:
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	_put(dummy, at)
	dummy.setup_dummy(player_id)
	dummy.ringout_y = 100000.0
	dummy.facing = facing
	return dummy

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _clear() -> void:
	for child in arena.get_children():
		child.queue_free()
	await process_frame
	await physics_frame

## Polls a condition every physics frame, for up to `timeout` seconds of game time.
func _wait_for(condition: Callable, timeout: float) -> bool:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await physics_frame
		waited += get_root().get_physics_process_delta_time()
	return condition.call()

func _count_attacks(owner: Node) -> int:
	var count := 0
	for node in arena.get_children():
		if node.get_script() != null and node.get_script().resource_path == ATTACK_PATH and node.get("source") == owner:
			count += 1
	return count

func _test_air_jumps() -> void:
	var rio := _rio(Vector2(0, -400))
	if rio.max_air_jumps != 2 or rio.body_type != "male":
		_fail("Rio should start with 2 air jumps and the chosen body (got %d, %s)" % [rio.max_air_jumps, rio.body_type])
		return
	var sky_step: Dictionary = {}
	for card in SOUL_CARDS.CARDS:
		if card.id == "sky_step":
			sky_step = card
	rio.apply_upgrade(sky_step)
	rio.apply_upgrade(sky_step)
	if rio.max_air_jumps != 3:
		_fail("Rio air jumps with two Sky Steps should cap at 3, got %d" % rio.max_air_jumps)

## The extra air jump shows a step plate at the soles (CODEX-VFX-01 candidate a, 2026-10-29):
## the brighter `_last` plate when no air jump is left, raised to the soles of the jump drawing.
func _test_air_step_effect() -> void:
	for body in ["male", "female"]:
		var rio := _rio(Vector2(0, -400), false, body)
		await _frames(2)
		rio.air_jumps_left = rio.max_air_jumps
		var expected := ["rio_air_step", "rio_air_step_last"]
		for jump in 2:
			var before: int = rio.air_jumps_left
			var at: Vector2 = _at(rio)
			rio.jump_buffer_timer = 0.1
			rio.coyote_timer = 0.0
			await physics_frame
			if rio.air_jumps_left != before - 1:
				_fail("Rio (%s) should spend an air jump (left %d -> %d)" % [body, before, rio.air_jumps_left])
				return
			var plate: Node2D = arena.get_node_or_null("Vfx_%s" % expected[jump])
			if plate == null:
				_fail("Rio (%s) air jump %d should show %s" % [body, jump + 1, expected[jump]])
				return
			var rise: float = rio.AIR_STEP_SOLE_RISE[body]
			if _at(plate).distance_to(at - Vector2(0.0, rise)) > 0.5:
				_fail("Rio (%s) air step should start at the soles (plate %s, expected %s)" % [body, _at(plate), at - Vector2(0.0, rise)])
			plate.free()
		rio.queue_free()
		await process_frame

## The same hit deals 1.5x from behind the target (the side it does not face), with a blue X.
func _test_backstab() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(-80, -2))
	var foe := _dummy(10, Vector2(0, -2), 1)
	await _frames(4)
	if not is_equal_approx(rio.damage_scale_against(foe), 1.5):
		_fail("Rio behind a foe facing away should deal 1.5x (got %.2f)" % rio.damage_scale_against(foe))
	foe.hp = foe.max_hp
	foe.apply_hit(rio, 10.0, 0.0, Vector2.RIGHT)
	var behind_loss: float = foe.max_hp - foe.hp
	await _frames(2)
	if arena.get_node_or_null("RioBackstab") == null:
		_fail("A hit from behind should show the backstab mark")
	foe.facing = -1
	foe.hp = foe.max_hp
	foe.apply_hit(rio, 10.0, 0.0, Vector2.RIGHT)
	var front_loss: float = foe.max_hp - foe.hp
	if absf(behind_loss - front_loss * 1.5) > 0.6:
		_fail("A hit from behind should take 1.5x the front hit (%.2f vs %.2f)" % [behind_loss, front_loss])

## The third J dashes through the foe, ends past it and turns to face it; the foe is thrown back
## the way Rio came.
func _test_pierce() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(-60, -2))
	var foe := _dummy(10, Vector2(20, -2), -1)
	await _frames(6)
	rio.facing = 1
	var start: float = _at(rio).x
	for swing in 3:
		await _wait_for(func() -> bool: return rio._can_start_attack(), 1.0)
		rio.perform_basic_attack("neutral", Vector2.RIGHT)
	await _frames(24)
	var moved: float = _at(rio).x - start
	if _at(rio).x <= _at(foe).x or moved < 120.0:
		_fail("The third J should dash through the foe (Rio x %.0f, foe x %.0f, moved %.0f)" % [_at(rio).x, _at(foe).x, moved])
	if rio.facing != -1:
		_fail("After the dash Rio should turn to face the foe he passed")
	if foe.hp >= foe.max_hp or foe.knockback_velocity.x > 0.0:
		_fail("The dash should hit the foe back the way Rio came (hp %.0f, knockback x %.0f)" % [foe.hp, foe.knockback_velocity.x])

## On the ground the dash stops where the floor ends.
func _test_pierce_ledge() -> void:
	_floor(Vector2(-160, 0), 400)
	var rio := _rio(Vector2(0, -2))
	await _wait_for(func() -> bool: return rio.is_on_floor(), 1.0)
	rio.facing = 1
	var start: float = _at(rio).x
	rio._pierce_slash()
	await _frames(14)
	var moved: float = _at(rio).x - start
	# The floor ends 40 px ahead of him.
	if moved > 52.0 or not rio.is_on_floor():
		_fail("The dash should stop at the ledge (moved %.0f px, on floor %s)" % [moved, rio.is_on_floor()])

## The sword sticks in a foe; the second K puts Rio behind it (60 px past its centre on the side it
## does not face), turned to it, and the slash lands as a backstab.
func _test_sword_blink() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(-200, -2))
	var foe := _dummy(10, Vector2(150, -2), -1)
	await _frames(6)
	rio.facing = 1
	rio.perform_skill_one()
	if not await _wait_for(func() -> bool: return is_instance_valid(rio.thrown_sword) and rio.thrown_sword.has_target(), 1.0):
		_fail("The thrown sword should stick in the foe")
		return
	var after_stick: float = foe.hp
	if after_stick >= foe.max_hp:
		_fail("The sword should hit the foe it sticks in")
	await _wait_for(func() -> bool: return rio._can_start_attack(), 1.0)
	if not rio.try_skill_one_followup():
		_fail("The second K should blink to the sword")
		return
	var expected: float = _at(foe).x + rio.BEHIND_OFFSET * GAME_SCALE.COMBAT
	if absf(_at(rio).x - expected) > 2.0 or rio.facing != -1:
		_fail("Rio should appear behind the foe facing it (x %.1f, expected %.1f, facing %d)" % [_at(rio).x, expected, rio.facing])
	await _frames(8)
	if foe.hp >= after_stick:
		_fail("The blink slash should hit the foe")
	if is_instance_valid(rio.thrown_sword):
		_fail("The sword should be gone after the blink")

## A sword that hits nothing stops where its flight ends; in the air there is one throw per
## airtime; the second K goes to the sword.
func _test_sword_air_and_end() -> void:
	var rio := _rio(Vector2(0, -900))
	rio.set_physics_process(false)
	rio.facing = 1
	rio.perform_skill_one()
	if not await _wait_for(func() -> bool: return is_instance_valid(rio.thrown_sword) and rio.thrown_sword.stuck, 1.2):
		_fail("A sword that hits nothing should stop at the end of its flight")
		return
	var sword: Node2D = rio.thrown_sword
	var flight: float = _at(sword).x - _at(rio).x
	var expected: float = rio.SWORD_SPEED * GAME_SCALE.COMBAT * rio.SWORD_FLIGHT
	if absf(flight - expected) > 60.0:
		_fail("The sword should fly about %.0f px (flew %.0f)" % [expected, flight])
	rio.attack_lock_timer = 0.0
	rio.perform_skill_one()
	await _frames(12)
	if rio.thrown_sword != sword:
		_fail("A second throw in the same airtime should not happen")
	var at: Vector2 = _at(sword)
	rio.try_skill_one_followup()
	if _at(rio).distance_to(at - GAME_SCALE.BODY_CENTRE) > 16.0:
		_fail("The second K should bring Rio to the stopped sword (at %s, sword %s)" % [_at(rio), at])

## The first hit in the stance does nothing; he appears behind the attacker and cuts.
func _test_counter() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	var attacker := _dummy(10, Vector2(-80, -2), 1)
	await _frames(6)
	rio.perform_skill_two()
	var before: float = rio.hp
	# Where the attacker stood when it swung (the counter's cut then pushes it away).
	var attacker_x: float = _at(attacker).x
	rio.apply_hit(attacker, 20.0, 600.0, Vector2.RIGHT)
	if rio.hp != before or rio.knockback_velocity.length() > 0.01 or rio.hitstun_timer > 0.0:
		_fail("The counter should take the hit unharmed (hp %.1f -> %.1f)" % [before, rio.hp])
		return
	var attacker_hp: float = attacker.hp
	await _frames(14)
	var expected: float = attacker_x - rio.BEHIND_OFFSET * GAME_SCALE.COMBAT
	if absf(_at(rio).x - expected) > 6.0 or rio.facing != 1:
		_fail("Rio should appear behind the attacker facing it (x %.1f, expected %.1f, facing %d)" % [_at(rio).x, expected, rio.facing])
	if attacker.hp >= attacker_hp:
		_fail("The counter should cut the attacker")
	rio.attack_lock_timer = 0.0
	rio.perform_skill_two()
	if rio.counter_timer > 0.0:
		_fail("The counter should be on cooldown")

## The attacker freed while he is vanished (a monster that dies in that tenth of a second): he
## only dodged. Casting the freed attacker was a script error that left out the short lock a dodge
## ends with (found reading every await in the game code after the flurry's, 2026-11-25).
## The foe's swing is a real one. Its time to land is measured first, so that the stance goes up
## three frames before the hit and the stance's own lock is still long when he comes back.
func _test_counter_attacker_freed() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	var foe: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(foe)
	_put(foe, Vector2(-70, -2))
	foe.setup(CHARACTER_REGISTRY.get_characters()["frey"], 2, false)
	foe.ringout_y = 100000.0
	foe.is_dummy = true
	await _frames(12)
	var before: float = rio.hp
	foe.facing = 1
	foe.basic_attack()
	var lands := 0
	while rio.hp >= before and lands < 60:
		await physics_frame
		lands += 1
	if rio.hp >= before or lands < 5:
		_fail("Test setup: the foe's swing should land on Rio after a start-up (%d frames)" % lands)
		return
	# Back where they stood, the swing over.
	await _frames(40)
	_put(rio, Vector2(0, -2))
	rio.velocity = Vector2.ZERO
	rio.knockback_velocity = Vector2.ZERO
	await _wait_for(func() -> bool: return rio.hitstun_timer <= 0.0 and rio.is_on_floor(), 2.0)
	rio.attack_lock_timer = 0.0
	foe.attack_lock_timer = 0.0
	foe.facing = 1
	foe.basic_attack()
	await _frames(lands - 3)
	rio.skill_two()
	if not await _wait_for(func() -> bool: return rio.counter_triggered, 0.3):
		_fail("Test setup: the foe's swing should land in Rio's stance")
		return
	# He is vanished now; the attacker goes before he comes back.
	foe.queue_free()
	if not await _wait_for(func() -> bool: return not rio.shadow_vanished, 0.5):
		_fail("Rio should come back from the vanish when the attacker is gone")
		return
	await physics_frame
	if rio.is_invulnerable():
		_fail("Back from the vanish he can be hit again")
	if rio.attack_lock_timer > 0.1:
		_fail("With the attacker gone he only dodged: the short lock, not the stance's (lock %.2f)" % rio.attack_lock_timer)

func _test_counter_whiff() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	await _frames(6)
	rio.perform_skill_two()
	await _wait_for(func() -> bool: return rio.counter_timer <= 0.0, 1.0)
	await _frames(2)
	if _count_attacks(rio) != 0 or rio.attack_lock_timer < 0.2:
		_fail("An empty counter should not attack and should leave Rio open (lock %.2f)" % rio.attack_lock_timer)

## A foe's real swing reaches the decoy, bursts it and is hit by the burst. The decoy was a
## static body until 2026-11-24 and no attack area ever met it (attack areas are not monitorable,
## so the physics broadphase treats them as static, and two static objects are never paired).
func _test_decoy_takes_a_swing() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	var foe: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(foe)
	_put(foe, Vector2(70, -2))
	foe.setup(CHARACTER_REGISTRY.get_characters()["frey"], 2, false)
	foe.ringout_y = 100000.0
	foe.is_dummy = true
	await _frames(12)
	rio.facing = 1
	rio.perform_skill_three()
	var decoy: Node2D = rio.decoy
	if not is_instance_valid(decoy):
		_fail("Test setup: U should leave a decoy")
		return
	var hp: float = foe.hp
	foe.facing = -1
	foe.basic_attack()
	await _frames(30)
	if is_instance_valid(decoy):
		_fail("A foe's swing 70 px away should reach the decoy and burst it")
	elif float(foe.hp) >= hp:
		_fail("The burst should hit the foe who struck the decoy (hp %.0f of %.0f)" % [foe.hp, hp])
	elif bool(rio.decoy_swap_ready):
		_fail("A burst decoy cannot be swapped with")

## A decoy where he stood and a 150 px step back; one swap; a foe's hit bursts it (his does not).
func _test_decoy() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	await _frames(6)
	rio.facing = 1
	var start: Vector2 = _at(rio)
	rio.perform_skill_three()
	var decoy: Node2D = rio.decoy
	if not is_instance_valid(decoy) or _at(decoy).distance_to(start) > 0.5:
		_fail("U should leave a decoy where Rio stood")
		return
	var stepped: float = start.x - _at(rio).x
	var expected: float = rio.DECOY_STEP * GAME_SCALE.WORLD
	if absf(stepped - expected) > 1.0:
		_fail("U should step Rio %.0f px back (stepped %.1f)" % [expected, stepped])
	var spot: Vector2 = _at(rio)
	if not rio.try_skill_three_followup() or _at(rio).distance_to(start) > 0.5 or _at(decoy).distance_to(spot) > 0.5:
		_fail("The second U should swap Rio and the decoy")
	if rio.try_skill_three_followup():
		_fail("The decoy should swap only once")
	if decoy.apply_hit(rio, 10.0, 100.0, Vector2.RIGHT) != false or not is_instance_valid(decoy) or decoy.burst:
		_fail("Rio's own hit should pass through his decoy")
	var foe := _dummy(10, _at(decoy) + Vector2(20, 0), -1)
	await _frames(2)
	decoy.apply_hit(foe, 10.0, 100.0, Vector2.LEFT)
	await _frames(3)
	if is_instance_valid(decoy) or foe.hp >= foe.max_hp:
		_fail("A foe's hit should burst the decoy and the burst should hit the foe (foe hp %.0f)" % foe.hp)
	rio.attack_lock_timer = 0.0
	rio.perform_skill_three()
	if is_instance_valid(rio.decoy):
		_fail("U should be on cooldown")

## Swords stick in both foes; the second I cuts each (Rio cannot be hit meanwhile) and returns him.
func _test_flurry() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	var near := _dummy(10, Vector2(180, -2), -1)
	var far := _dummy(11, Vector2(-260, -2), 1)
	await _frames(6)
	rio.perform_ultimate()
	if not await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.WAITING and rio._stuck_flurry_swords() == 6, 1.5):
		_fail("Six gem swords should stick in the two foes (phase %d, stuck %d)" % [rio.flurry_phase, rio._stuck_flurry_swords()])
		return
	var start: Vector2 = _at(rio)
	var near_hp: float = near.hp
	var far_hp: float = far.hp
	rio.ultimate()
	if rio.flurry_phase != rio.Flurry.CUTTING or not rio.is_invulnerable():
		_fail("The second I should start the cuts with Rio untouchable")
	await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.NONE, 2.0)
	# Checked as he lands back: the cuts push both foes toward him, and a foe at his side then
	# nudges him (soft collision).
	var back_at: Vector2 = _at(rio)
	await _frames(2)
	if near.hp >= near_hp or far.hp >= far_hp:
		_fail("The cuts should hit both foes (near %.0f -> %.0f, far %.0f -> %.0f)" % [near_hp, near.hp, far_hp, far.hp])
	if back_at.distance_to(start) > 6.0:
		_fail("Rio should return to where he pressed I (at %s, start %s)" % [back_at, start])

## A foe freed between two throws (a monster that dies while the swords fly out): the swords
## left go to the foes still there. Handing the freed one on was a script error that stopped the
## cast half-way: the swords left were never thrown, and the I key did nothing until he was next
## hit (soak seed 2002, 2026-11-25).
func _test_flurry_target_freed() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	_dummy(10, Vector2(180, -2), -1)
	var far := _dummy(11, Vector2(-260, -2), 1)
	await _frames(6)
	rio.perform_ultimate()
	# The first sword is out; the second would go to the far foe, which is gone by then.
	far.queue_free()
	if not await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.WAITING, 1.5):
		_fail("The cast should finish when a foe is freed between two throws (phase %d)" % rio.flurry_phase)
		return
	var thrown := 0
	for sword in rio.flurry_swords:
		if is_instance_valid(sword):
			thrown += 1
	if thrown != rio.FLURRY_SWORDS:
		_fail("All six gem swords should be thrown, the later ones at the foe still there (%d thrown)" % thrown)

## Moved in the middle of the cuts (a collapse throws him into another realm, a ring-out respawns
## him, practice mode puts him back): the flurry ends where he was put. He used to snap back a
## moment later to where he had pressed I, which after a collapse is a place in the realm that
## fell (found by practice mode's R, 2026-11-26).
func _test_flurry_moved_mid_cut() -> void:
	_floor(Vector2(0, 0), 2400)
	_floor(Vector2(4000, 0), 800)
	var rio := _rio(Vector2(0, -2))
	_dummy(10, Vector2(200, -2), -1)
	await _frames(6)
	rio.perform_ultimate()
	if not await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.WAITING and rio._stuck_flurry_swords() == 6, 1.5):
		_fail("Test setup: six gem swords should stick in the foe")
		return
	rio.ultimate()
	await _frames(3)
	if rio.flurry_phase != rio.Flurry.CUTTING:
		_fail("Test setup: the second I should start the cuts (phase %d)" % rio.flurry_phase)
		return
	# What MatchDirector does to a fighter caught in a collapse.
	var there := scene + Vector2(4000, -2)
	var points: Array[Vector2] = [there]
	rio.reset_for_map(there, points)
	await _frames(40)
	if _at(rio).distance_to(Vector2(4000, -2)) > 40.0:
		_fail("Rio moved in the middle of his cuts should stay where he was put (at %s, put at (4000, -2))" % _at(rio))
	if rio.flurry_phase != rio.Flurry.NONE:
		_fail("The flurry should be over after the move (phase %d)" % rio.flurry_phase)

## Without the second I the stuck swords burst on their foe.
func _test_flurry_burst() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(0, -2))
	var foe := _dummy(10, Vector2(200, -2), -1)
	await _frames(6)
	rio.perform_ultimate()
	if not await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.WAITING and rio._stuck_flurry_swords() == 6, 1.5):
		_fail("Six gem swords should stick in the foe")
		return
	var hp: float = foe.hp
	rio.flurry_timer = 0.05
	await _frames(8)
	if rio.flurry_phase != rio.Flurry.NONE or foe.hp >= hp or not rio.flurry_swords.is_empty():
		_fail("Unused swords should burst on the foe (phase %d, hp %.0f -> %.0f)" % [rio.flurry_phase, hp, foe.hp])

## A bot blinks to its sword in a foe by itself, and cuts its stuck gem swords by itself.
func _test_bots() -> void:
	_floor(Vector2(0, 0), 2400)
	var rio := _rio(Vector2(-200, -2), true)
	var foe := _dummy(10, Vector2(150, -2), -1)
	await _frames(6)
	rio.facing = 1
	rio.perform_skill_one()
	if not await _wait_for(func() -> bool: return _at(rio).x > _at(foe).x, 1.5):
		_fail("A bot should blink behind the foe its sword sticks in (x %.0f)" % _at(rio).x)
		return
	await _wait_for(func() -> bool: return rio._can_start_attack(), 1.0)
	var hp: float = foe.hp
	rio.ultimate_cooldown_timer = 0.0
	rio.ultimate()
	if not await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.CUTTING, 1.5):
		_fail("A bot should cut through its stuck gem swords by itself (phase %d)" % rio.flurry_phase)
		return
	await _wait_for(func() -> bool: return rio.flurry_phase == rio.Flurry.NONE, 2.0)
	if foe.hp >= hp:
		_fail("The bot's cuts should hit the foe")

func _test_third_skill_slot() -> void:
	var rio := _rio(Vector2(0, -400))
	if not rio.has_skill_three():
		_fail("Rio should have a third skill (U)")
	rio.perform_skill_three()
	var cooldown: Vector2 = rio.skill_cooldown("u")
	if not is_equal_approx(cooldown.y, rio.DECOY_COOLDOWN) or cooldown.x <= 0.0:
		_fail("The U slot should show the decoy cooldown (%s)" % cooldown)
