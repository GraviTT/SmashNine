extends SceneTree
## Lead probe: Luna side star echo, trail + bloom on a dummy, with and without walking toward it.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for walk in [false, true]:
		var line := "walk=%s " % walk
		for distance in [50.0, 70.0, 90.0, 110.0, 130.0, 150.0, 170.0, 190.0]:
			line += "%d:%s " % [int(distance), await _trial(distance, walk)]
		print(line)
	quit(0)

func _trial(distance: float, walk: bool) -> String:
	arena = Node2D.new()
	root.add_child(arena)
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(3000, 40)
	shape.shape = rect
	floor.add_child(shape)
	arena.add_child(floor)
	floor.global_position = Vector2(0, 20)
	var luna: Node = PLAYER_FACTORY.create("luna")
	arena.add_child(luna)
	luna.global_position = Vector2(0, -2)
	luna.setup(CHARACTER_REGISTRY.get_characters()["luna"], 1, false)
	luna.is_dummy = true
	luna.ringout_y = 100000.0
	var dummy: Node = PLAYER_FACTORY.create("")
	arena.add_child(dummy)
	dummy.global_position = Vector2(distance, -2)
	dummy.setup_dummy(2)
	dummy.ringout_y = 100000.0
	for frame in 12:
		await physics_frame
	luna.facing = 1
	var hits := []
	dummy.damaged.connect(func(_v, amount, _att, _src): hits.append(snappedf(float(amount), 0.1)))
	if walk:
		luna.move_input = 1.0
		for frame in 6:
			await physics_frame
	var start_gap: float = dummy.global_position.x - luna.global_position.x
	luna.perform_basic_attack("side", Vector2.RIGHT)
	for frame in 40:
		await physics_frame
	luna.move_input = 0.0
	var result := "%s(gap%d)" % [str(hits.size()), int(start_gap)]
	arena.queue_free()
	await process_frame
	return result
