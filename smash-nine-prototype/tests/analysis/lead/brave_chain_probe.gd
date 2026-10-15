extends SceneTree
## Lead probe (2026-10-15, D39 start-ups): Brave Luna's J chain on a target 45 px away, as in
## test_luna_kit._test_brave_chain_poses. Prints, per hit, the frame, the target's distance and the
## hitstun left when it landed, and when each press started.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var frame_no := 0

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

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

func _tick() -> void:
	await physics_frame
	frame_no += 1

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	for trial in 3:
		var ground := _floor(Vector2(0, 0), 1400)
		var luna := _fighter("luna", 1, Vector2(0, -2))
		for frame in 20:
			await _tick()
		luna._enter_transformation()
		await _tick()
		var target := _fighter("frey", 3, Vector2(45, -2))
		for frame in 6 + trial:
			await _tick()
		if OS.get_cmdline_user_args().has("--grounded"):
			while target.hitstun_timer > 0.0 or not target.is_on_floor():
				await _tick()
			for frame in trial:
				await _tick()
		frame_no = 0
		var log := []
		target.damaged.connect(func(_v, amount, _att, _src):
			log.append("hit f%d dmg %.1f dist %.1f hitstun %.3f" % [frame_no, amount, target.global_position.x - luna.global_position.x, target.hitstun_timer]))
		for hit in 3:
			while not luna._can_start_attack():
				await _tick()
				if hit == 2 and trial == 0:
					var who := ""
					if is_instance_valid(luna.last_attack):
						for b in luna.last_attack.get_overlapping_bodies():
							who += "L" if b == luna else ("T" if b == target else str(b.name))
						who += " ax %.1f hit %s" % [luna.last_attack.global_position.x - luna.global_position.x, str(luna.last_attack.hit_targets.size())]
					log.append("  f%d dist %.1f ty %.1f ly %.1f ay %.1f hitstun %.3f %s" % [frame_no, target.global_position.x - luna.global_position.x, target.global_position.y, luna.global_position.y, (luna.last_attack.global_position.y if is_instance_valid(luna.last_attack) else 0.0), target.hitstun_timer, who])
			log.append("press %d f%d dist %.1f target hitstun %.3f" % [hit + 1, frame_no, target.global_position.x - luna.global_position.x, target.hitstun_timer])
			luna.perform_basic_attack("neutral", Vector2.RIGHT)
		for frame in 30:
			await _tick()
		print("trial %d:" % trial)
		for line in log:
			print("  ", line)
		luna.queue_free()
		target.queue_free()
		ground.queue_free()
		await process_frame
	arena.queue_free()
	await process_frame
	quit(0)
