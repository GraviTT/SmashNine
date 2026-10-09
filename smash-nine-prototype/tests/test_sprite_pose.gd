extends SceneTree
## Moves that share the one attack row can play their own part of it (2026-10-10): a pose starts
## at its first frame, reaches its last one and holds it until the action ends; then the sprite
## runs at normal speed again.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arena := Node2D.new()
	root.add_child(arena)
	var frey: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(frey)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	frey.is_dummy = true
	frey.ringout_y = 100000.0
	await physics_frame
	var failed := false
	frey._play_sprite_pose(&"attack", 2, 3, 0.3)
	var sprite: AnimatedSprite2D = frey.character_sprite
	if int(sprite.frame) != 2:
		push_error("A pose should start at its first frame (frame %d)" % sprite.frame)
		failed = true
	var reached := false
	for frame in 15:
		await physics_frame
		if int(sprite.frame) == 3:
			reached = true
		if int(sprite.frame) < 2 or (reached and int(sprite.frame) != 3):
			push_error("A pose should stay within its frames and hold the last one (frame %d)" % sprite.frame)
			failed = true
			break
	if not reached:
		push_error("A 0.3 s pose of frames 2-3 should reach frame 3 within 0.25 s")
		failed = true
	for frame in 12:
		await physics_frame
	if absf(float(sprite.speed_scale) - 1.0) > 0.001 or int(frey.sprite_pose_last) != -1:
		push_error("After the action the sprite should run at normal speed again (speed %.2f)" % sprite.speed_scale)
		failed = true
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Sprite pose tests passed")
	quit(0)
