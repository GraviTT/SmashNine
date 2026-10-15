extends SceneTree
## Lead probe (2026-10-15, D39 start-ups): Luna walks in from 110 px and presses J, as in
## test_luna_kit._test_echo_walk_in. Prints how far ahead the target was when the trail struck
## (the bloom follows it only from ECHO_HOME_MIN = 75) and whether the bloom landed.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var aheads := []
	var misses := 0
	for trial in 12:
		var ground := StaticBody2D.new()
		ground.collision_layer = 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(1400, 40)
		shape.shape = rect
		ground.add_child(shape)
		arena.add_child(ground)
		ground.global_position = Vector2(0, 20)
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
		for frame in 8 + trial % 4:
			await physics_frame
		var hits := []
		dummy.damaged.connect(func(_v, amount, _att, _src):
			hits.append(dummy.global_position.x - luna.global_position.x))
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
		aheads.append("%.1f%s" % [hits[0] if hits.size() > 0 else -1.0, "" if hits.size() >= 2 else "(miss)"])
		luna.queue_free()
		dummy.queue_free()
		ground.queue_free()
		await process_frame
	print("trail-hit distance: ", ", ".join(aheads), "  misses ", misses, "/12")
	arena.queue_free()
	await process_frame
	quit(0)
