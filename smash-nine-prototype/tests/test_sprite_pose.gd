extends SceneTree
## Moves that share the one attack row can play their own part of it (2026-10-10): a pose starts
## at its first frame, reaches its last one and holds it until the action ends; then the sprite
## runs at normal speed again. Readable playback (user 2026-10-15, tempo proposal B): the strike
## drawing comes with the hit at the end of the start-up, every drawing from the strike on shows
## for at least three game frames, the follow-through finishes after the attack lock unless the
## fighter moves, and hitstop freezes the drawing.

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var arena: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error(message)
	failed = true

func _fighter() -> Node:
	var frey: Node = PLAYER_FACTORY.create("frey")
	arena.add_child(frey)
	frey.setup(CHARACTER_REGISTRY.get_characters()["frey"], 1, false)
	frey.is_dummy = true
	frey.ringout_y = 100000.0
	frey.global_position = Vector2(0, -400)
	return frey

func _run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	await _test_pose_holds_last()
	await _test_readable_row()
	await _test_moving_cuts_follow_through()
	await _test_hitstop_freezes_drawing()
	arena.queue_free()
	await process_frame
	if failed:
		quit(1)
		return
	print("Sprite pose tests passed")
	quit(0)

func _test_pose_holds_last() -> void:
	var frey := _fighter()
	await physics_frame
	frey._play_sprite_pose(&"attack", 2, 3, 0.3)
	var sprite: AnimatedSprite2D = frey.character_sprite
	if int(sprite.frame) != 2:
		_fail("A pose should start at its first frame (frame %d)" % sprite.frame)
	var reached := false
	for frame in 15:
		await physics_frame
		if int(sprite.frame) == 3:
			reached = true
		if int(sprite.frame) < 2 or (reached and int(sprite.frame) != 3):
			_fail("A pose should stay within its frames and hold the last one (frame %d)" % sprite.frame)
			break
	if not reached:
		_fail("A 0.3 s pose of frames 2-3 should reach frame 3 within 0.25 s")
	for frame in 12:
		await physics_frame
	if absf(float(sprite.speed_scale) - 1.0) > 0.001 or int(frey.sprite_pose_last) != -1:
		_fail("After the action the sprite should run at normal speed again (speed %.2f)" % sprite.speed_scale)
	frey.queue_free()
	await process_frame

## A fast six-drawing move (Rio's basic attack is 0.05 s start-up + 0.12 s recovery): before,
## the row ran at about 45 drawings a second and was gone before the lock ended.
func _test_readable_row() -> void:
	var frey := _fighter()
	await physics_frame
	var sprite: AnimatedSprite2D = frey.character_sprite
	frey._play_sprite_pose(&"attack", 0, 5, 0.17, 0.05)
	var shown: Array[int] = []
	for frame in 30:
		await physics_frame
		shown.append(int(sprite.frame) if int(frey.sprite_pose_last) >= 0 else -1)
	# The strike (drawing 2) is up when the hit comes out, 3 game frames in.
	if shown[2] != 2:
		_fail("The strike drawing should be up when the hit comes out at the end of the start-up (frames %s)" % [shown])
	for drawing in range(2, 6):
		var count := shown.count(drawing)
		if count < 3:
			_fail("Drawing %d should show for at least 3 game frames (it showed %d: %s)" % [drawing, count, shown])
	if shown.find(5) < 10:
		_fail("The follow-through should run past the 0.17 s lock when the fighter stands still (last drawing at frame %d)" % shown.find(5))
	frey.queue_free()
	await process_frame

func _test_moving_cuts_follow_through() -> void:
	var frey := _fighter()
	await physics_frame
	frey._play_sprite_pose(&"attack", 0, 5, 0.17, 0.05)
	for frame in 11:
		await physics_frame
	if int(frey.sprite_pose_last) < 0:
		_fail("Test setup: the follow-through should still be playing just after the lock")
	frey.move_input = 1.0
	await physics_frame
	await physics_frame
	if int(frey.sprite_pose_last) >= 0:
		_fail("Moving after the attack lock should cut the follow-through")
	frey.move_input = 0.0
	frey.queue_free()
	await process_frame

func _test_hitstop_freezes_drawing() -> void:
	var frey := _fighter()
	await physics_frame
	var sprite: AnimatedSprite2D = frey.character_sprite
	frey._play_sprite_pose(&"attack", 0, 5, 0.3, 0.1)
	for frame in 6:
		await physics_frame
	frey.hitstop_timer = 0.1
	var held := int(sprite.frame)
	for frame in 5:
		await physics_frame
		if int(sprite.frame) != held:
			_fail("Hitstop should freeze the drawing (went %d -> %d)" % [held, sprite.frame])
			break
	frey.queue_free()
	await process_frame
