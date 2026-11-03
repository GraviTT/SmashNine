extends SceneTree
## Lead capture (2026-11-04, D48): the pixelfx motion effects in the game: Luna idling (her stars),
## then jumping in place and landing (her stardust); Frey running (step dust); Frey's three J cuts
## (sparks after each slash). Frame sequences at 30 fps, camera zoom 2 (1 art px = 2 screen px).
## Windowed run (not headless):
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/motion_fx_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://motion_fx"
var arena: Node2D
var camera: Camera2D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	# 1. Luna idles, jumps in place and lands.
	await _scene(Vector2(0, -110))
	var luna := _fighter("luna", 1, Vector2(0, -2), true)
	await _frames(30)
	var shot := await _record("luna_idle_land", luna, 0, 50)
	Input.action_press("jump")
	shot = await _record("luna_idle_land", luna, shot, 3)
	Input.action_release("jump")
	await _record("luna_idle_land", luna, shot, 52)
	# 2. Frey runs right; the camera follows her.
	await _scene(Vector2(-160, -110))
	var frey := _fighter("frey", 1, Vector2(-320, -2), true)
	await _frames(30)
	shot = await _record("frey_run", frey, 0, 6)
	Input.action_press("move_right")
	shot = await _record("frey_run", frey, shot, 54, true)
	Input.action_release("move_right")
	await _record("frey_run", frey, shot, 16, true)
	# 3. Frey's J chain: three cuts as fast as the combo allows.
	await _scene(Vector2(110, -110))
	frey = _fighter("frey", 1, Vector2(-40, -2), false)
	await _frames(30)
	frey.facing = 1
	shot = await _record("frey_chain", frey, 0, 4)
	for cut in 3:
		while not frey._can_start_attack():
			shot = await _record("frey_chain", frey, shot, 1)
		frey.basic_attack()
	await _record("frey_chain", frey, shot, 44)
	print("CAPTURE_DONE ", out_dir)
	quit(0)

func _scene(look_at: Vector2) -> void:
	if is_instance_valid(arena):
		arena.queue_free()
		await process_frame
	arena = Node2D.new()
	root.add_child(arena)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	arena.add_child(camera)
	camera.make_current()
	camera.global_position = look_at
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 40)
	shape.shape = rect
	body.add_child(shape)
	var look := ColorRect.new()
	look.size = Vector2(4000, 40)
	look.position = Vector2(-2000, -20)
	look.color = Color(0.22, 0.26, 0.34)
	body.add_child(look)
	arena.add_child(body)
	body.global_position = Vector2(0, 20)

func _fighter(character_id: String, player_id: int, at: Vector2, human: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, human)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = not human
	fighter.set_process_unhandled_input(false)
	return fighter

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## Saves `count` shots, one every two physics frames (30 fps), numbered from `first`.
func _record(clip: String, fighter: Node, first: int, count: int, follow := false) -> int:
	var dir := "%s/%s" % [out_dir, clip]
	DirAccess.make_dir_recursive_absolute(dir)
	for index in count:
		await _frames(2)
		if follow:
			camera.global_position.x = fighter.global_position.x + 60.0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%04d.png" % [dir, first + index])
	return first + count
