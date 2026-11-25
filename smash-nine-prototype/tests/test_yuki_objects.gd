extends SceneTree
## Yuki's seal and talismans meet what they are written to meet (2026-11-25).
## - The binding seal (K) is torn by one attack: a foe's real swing, a foe's real shot. Until this
##   date it was a StaticBody2D, and attack and projectile areas (monitorable off) never meet a
##   static body, so nothing ever tore it. Her own talisman passes it; L still sets it off.
## - A talisman meets platforms: a straight one ends at a wall, a dropping one bursts on the floor
##   it lands on. Its area had monitorable off as well, so it flew through every platform.
## Nothing here calls a hit by hand: every hit comes from a press and a real overlap.
## Every scene is played twice, round the world origin and far from it (see test_bot_kits.gd).

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
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
		for test in [_test_seal_stands_where_it_is_placed, _test_swing_tears_the_seal, _test_shot_tears_the_seal, _test_her_talisman_passes_her_seal,
				_test_seal_still_goes_off, _test_straight_talisman_ends_at_a_wall, _test_dropping_talisman_bursts_on_the_floor]:
			await test.call()
			for child in arena.get_children():
				child.queue_free()
			await process_frame
			await physics_frame
	if failed:
		quit(1)
		return
	print("Yuki object tests passed (each scene round the origin and at %s)" % SCENES[1])
	quit(0)

func _fail(message: String) -> void:
	push_error("%s (scene at %s)" % [message, scene])
	failed = true

## Where a node stands, and putting it somewhere, in scene coordinates.
func _at(node: Node2D) -> Vector2:
	return node.global_position - scene

func _put(node: Node2D, at: Vector2) -> void:
	node.global_position = scene + at

## A platform as RealmWorld builds one: a static body in the "platforms" group. `at` is its centre.
func _platform(at: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.add_to_group("platforms")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	body.position = scene + at
	arena.add_child(body)
	return body

func _floor() -> StaticBody2D:
	return _platform(Vector2(0, 20), Vector2(2400, 40))

## A person's fighter with nobody at the keys: it stands, and does what the test presses.
func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	_put(fighter, at)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, true)
	fighter.set_process_unhandled_input(false)
	fighter.ringout_y = 100000.0
	return fighter

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## Yuki on the floor with one seal placed ahead of her by a real K press.
func _yuki_with_a_seal() -> Array:
	_floor()
	var yuki := _fighter("yuki", 1, Vector2(0, -2))
	await _frames(15)
	yuki.facing = 1
	yuki.skill_one()
	await _frames(30)
	var seal: Node2D = yuki.seals[0] if yuki.seals.size() == 1 else null
	if seal == null:
		_fail("Test setup: K should place one seal (%d)" % yuki.seals.size())
	return [yuki, seal]

func _test_seal_stands_where_it_is_placed() -> void:
	var pair: Array = await _yuki_with_a_seal()
	var yuki: Node = pair[0]
	var seal: Node2D = pair[1]
	if seal == null:
		return
	var wanted: Vector2 = _at(yuki) + Vector2(145, -34)
	if _at(seal).distance_to(wanted) > 2.0:
		_fail("The seal should stand 145 px ahead of where Yuki placed it (at %s, wanted %s)" % [_at(seal), wanted])
	await _frames(5)
	if not is_instance_valid(seal) or _at(seal).distance_to(wanted) > 2.0:
		_fail("The seal should stay where it was placed")

func _test_swing_tears_the_seal() -> void:
	var pair: Array = await _yuki_with_a_seal()
	var yuki: Node = pair[0]
	var seal: Node2D = pair[1]
	if seal == null:
		return
	var foe := _fighter("frey", 2, _at(seal) + Vector2(70, 34))
	await _frames(15)
	foe.facing = -1
	foe.basic_attack()
	await _frames(30)
	if is_instance_valid(seal) and not seal.is_queued_for_deletion():
		_fail("A foe's swing 70 px from the seal should tear it (SKILLS.md: one attack tears it)")
	elif not yuki.seals.is_empty():
		_fail("A torn seal should leave Yuki's list (%d left)" % yuki.seals.size())

func _test_shot_tears_the_seal() -> void:
	var pair: Array = await _yuki_with_a_seal()
	var seal: Node2D = pair[1]
	if seal == null:
		return
	# Luna's star flies level at the seal from 260 px on its far side.
	var foe := _fighter("luna", 2, _at(seal) + Vector2(260, 34))
	await _frames(15)
	foe.facing = -1
	foe.basic_attack()
	await _frames(45)
	if is_instance_valid(seal) and not seal.is_queued_for_deletion():
		_fail("A foe's shot should tear the seal it reaches")

func _test_her_talisman_passes_her_seal() -> void:
	var pair: Array = await _yuki_with_a_seal()
	var yuki: Node = pair[0]
	var seal: Node2D = pair[1]
	if seal == null:
		return
	var foe := _fighter("frey", 2, _at(seal) + Vector2(160, 34))
	await _frames(15)
	var hp: float = foe.hp
	yuki.attack_lock_timer = 0.0
	yuki.facing = 1
	yuki.basic_attack()
	await _frames(45)
	if not is_instance_valid(seal) or seal.is_queued_for_deletion():
		_fail("Yuki's own talisman should pass through her seal")
	if float(foe.hp) >= hp:
		_fail("Her talisman should fly past her seal and reach the foe behind it")

func _test_seal_still_goes_off() -> void:
	var pair: Array = await _yuki_with_a_seal()
	var yuki: Node = pair[0]
	var seal: Node2D = pair[1]
	if seal == null:
		return
	var foe := _fighter("frey", 2, _at(seal) + Vector2(90, 34))
	await _frames(15)
	var hp: float = foe.hp
	yuki.attack_lock_timer = 0.0
	yuki.skill_two()
	await _frames(80)
	if is_instance_valid(seal) and not seal.is_queued_for_deletion():
		_fail("L should set the seal off: it pulls, bursts and is gone")
	if float(foe.hp) >= hp:
		_fail("The seal's burst should hit the foe standing 90 px from it")

func _test_straight_talisman_ends_at_a_wall() -> void:
	_floor()
	var yuki := _fighter("yuki", 1, Vector2(0, -2))
	# A wall between her and the foe, from the floor up past her head.
	_platform(Vector2(200, -120), Vector2(40, 240))
	var foe := _fighter("frey", 2, Vector2(330, -2))
	await _frames(15)
	var hp: float = foe.hp
	yuki.facing = 1
	yuki.basic_attack()
	var passed := false
	for frame in 50:
		await physics_frame
		for node in get_nodes_in_group("yuki_talismans"):
			if is_instance_valid(node) and _at(node).x > 240.0:
				passed = true
	if passed:
		_fail("A straight talisman should end at a wall, not fly through it")
	if float(foe.hp) < hp:
		_fail("The foe behind the wall should not be hit")

func _test_dropping_talisman_bursts_on_the_floor() -> void:
	_floor()
	var yuki := _fighter("yuki", 1, Vector2(0, -260))
	# Beside where the talisman lands, inside its burst (141 px wide) and outside its own width.
	var foe := _fighter("frey", 2, Vector2(95, -2))
	await _frames(3)
	_put(yuki, Vector2(0, -260))
	yuki.velocity = Vector2.ZERO
	var hp: float = foe.hp
	yuki.facing = 1
	# Air-down J as she plays it: Yuki._spawn_talisman with the air-down numbers.
	yuki._spawn_talisman(Vector2(24, 28), 8, 295, Vector2(0.12, 1.0), 610.0, 1.0, "drop", Vector2(94, 50))
	var burst_at := Vector2.INF
	var deepest := -INF
	for frame in 70:
		await physics_frame
		for node in get_nodes_in_group("yuki_talismans"):
			if not is_instance_valid(node):
				continue
			deepest = maxf(deepest, _at(node).y)
			if burst_at == Vector2.INF and float(node.burst_time) > 0.0:
				burst_at = _at(node)
	if burst_at == Vector2.INF:
		_fail("A dropping talisman should burst on the floor it lands on (it went down to y %.0f, the floor's top is 0)" % deepest)
	elif burst_at.y > 20.0:
		_fail("The burst should be at the floor's top, not below it (y %.0f)" % burst_at.y)
	elif float(foe.hp) >= hp:
		_fail("The burst on the floor should hit the foe standing beside it")
