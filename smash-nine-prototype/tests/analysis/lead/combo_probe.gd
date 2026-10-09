extends SceneTree
## Lead's combo probe (2026-10-10 night, not in run_all; run with --script tests/analysis/lead/combo_probe.gd): hits and hitstun gaps of a
## chain pressed as fast as the attacker can act, against a dummy at a given distance.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

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

func _fighter(id: String, pid: int, at: Vector2) -> Node:
	var f: Node = PLAYER_FACTORY.create(id)
	arena.add_child(f)
	f.global_position = at
	f.setup(CHARACTER_REGISTRY.get_characters()[id], pid, false)
	f.ringout_y = 100000.0
	f.is_dummy = true
	return f

func _chain(attacker_id: String, brave: bool, distance: float, presses: int, defender := "frey", lift := 0.0) -> String:
	var ground := _floor(Vector2(0, 0), 2000)
	var a := _fighter(attacker_id, 1, Vector2(0, -2))
	var d := _fighter(defender, 2, Vector2(distance, -2))
	for frame in 20:
		await physics_frame
	a.facing = 1
	if brave:
		d.global_position = Vector2(1500, -2)
		a._enter_transformation()
		for frame in 30:
			await physics_frame
		d.global_position = Vector2(distance, -2)
		for frame in 4:
			await physics_frame
	if lift > 0.0:
		# The defender was jumping: hit on the way up (the moving-bot case of the round-2 retest).
		d.velocity.y = -lift
		await physics_frame
	var hits: Array = []
	d.damaged.connect(func(_v, amount, _att, _src): hits.append([Engine.get_physics_frames(), amount, float(d.hitstun_timer)]))
	var free_frames := [0]
	var watch := func(): pass
	var pressed := 0
	var frame_count := 0
	var log := []
	while pressed < presses and frame_count < 240:
		if a._can_start_attack():
			a.perform_basic_attack("neutral", Vector2.RIGHT)
			log.append(Engine.get_physics_frames())
			pressed += 1
		await physics_frame
		frame_count += 1
	for frame in 40:
		await physics_frame
	var out := "%s%s vs %s lift=%.0f d=%.0f presses at %s hits %s target_x=%.0f" % [attacker_id, " brave" if brave else "", defender, lift, distance, str(log), str(hits), d.global_position.x]
	a.queue_free()
	d.queue_free()
	ground.queue_free()
	await process_frame
	return out

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for defender in ["frey", "rio", "luna", "nova", "yuki"]:
		print(await _chain("frey", false, 45.0, 3, defender))
	for defender in ["frey", "rio", "luna", "nova", "yuki"]:
		print(await _chain("luna", true, 45.0, 3, defender))
	for lift in [200.0, 400.0, 600.0]:
		for defender in ["rio", "frey"]:
			print(await _chain("frey", false, 45.0, 3, defender, lift))
			print(await _chain("luna", true, 45.0, 3, defender, lift))
	quit(0)
