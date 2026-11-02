extends SceneTree
## Lead capture (2026-11-03, D44): Frey's new kit with its stand-in art: the wing hover, the
## sword wave in flight, the descent light pulling a fighter in, the Valhalla Strike.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/frey_kit_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://frey_kit"
var arena: Node2D
var camera: Camera2D

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	arena = Node2D.new()
	root.add_child(arena)
	camera = Camera2D.new()
	arena.add_child(camera)
	camera.make_current()
	var ground := _floor(Vector2(0, 0), 2400)
	# 1. Wing hover: hold jump in the air.
	var frey := _fighter("frey", 1, Vector2(-200, -260), true)
	camera.global_position = Vector2(-120, -220)
	for frame in 4:
		await physics_frame
	frey.air_jumps_left = frey.max_air_jumps
	Input.action_press("jump")
	for frame in 16:
		await physics_frame
	await _shot("1_wing_hover")
	Input.action_release("jump")
	Input.action_press("move_right")
	for frame in 22:
		await physics_frame
	await _shot("2_wing_dash")
	Input.action_release("move_right")
	frey.queue_free()
	await _settle(30)
	# 2. Sword wave toward a fighter.
	frey = _fighter("frey", 1, Vector2(-260, -2), false)
	var foe := _fighter("luna", 2, Vector2(140, -2), false)
	camera.global_position = Vector2(-40, -120)
	await _settle(20)
	frey.facing = 1
	frey.perform_skill_one()
	for frame in 16:
		await physics_frame
	await _shot("3_sword_wave")
	await _settle(40)
	# 3. Descent light pulling the fighter in.
	foe.global_position = Vector2(60, -2)
	await _settle(10)
	frey.perform_ultimate()
	for frame in 10:
		await physics_frame
	await _shot("4_descent_light")
	for frame in 22:
		await physics_frame
	await _shot("5_descent_slam")
	await _settle(80)
	# 4. Soaring Cleave, then Valhalla Strike.
	frey.attack_lock_timer = 0.0
	frey.skill_two()
	for frame in 18:
		await physics_frame
	frey.try_skill_two_followup()
	for frame in 10:
		await physics_frame
	await _shot("6_valhalla_strike")
	quit(0)

func _floor(at: Vector2, width: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 40)
	shape.shape = rect
	body.add_child(shape)
	var look := ColorRect.new()
	look.size = Vector2(width, 40)
	look.position = Vector2(-width * 0.5, -20)
	look.color = Color(0.22, 0.26, 0.34)
	body.add_child(look)
	arena.add_child(body)
	body.global_position = at + Vector2(0, 20)
	return body

func _fighter(character_id: String, player_id: int, at: Vector2, human: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, human)
	fighter.ringout_y = 100000.0
	fighter.set_process_unhandled_input(false)
	if not human:
		fighter.is_dummy = true
	return fighter

func _settle(frames: int) -> void:
	for frame in frames:
		await physics_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out_dir, shot_name]
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
