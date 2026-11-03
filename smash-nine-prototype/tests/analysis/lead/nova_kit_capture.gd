extends SceneTree
## Lead capture (2026-11-03, D47): Nova's new kit with its stand-in art: the chain's stack, the
## orb pulling two fighters, the field (Nova flying, a slowed fighter, a floating monster), the
## beam dragging and slamming, a rooted fighter, the sphere swinging fighters, the launch and the
## sphere's burst.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/nova_kit_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const MONSTER := preload("res://scripts/RealmMonster.gd")

var out_dir := "user://nova_kit"
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
	# 1. The chain's third hit: one stack pip over the fighter.
	await _scene()
	var nova := _fighter("nova", 1, Vector2(-120, -2))
	var foe := _fighter("frey", 2, Vector2(-20, -2))
	await _frames(20)
	nova.facing = 1
	for press in 3:
		await _until_ready(nova)
		foe.global_position = nova.global_position + Vector2(85, 0)
		nova.basic_attack()
	await _frames(14)
	await _shot("1_chain_stack")
	# 2. The orb bursting on a fighter and pulling another in.
	await _scene()
	nova = _fighter("nova", 1, Vector2(-320, -2))
	foe = _fighter("frey", 2, Vector2(0, -2))
	var other := _fighter("rio", 3, Vector2(100, -2))
	await _frames(20)
	nova.facing = 1
	nova.skill_one()
	for frame in 60:
		await physics_frame
		if nova.orb_pull_timer > 0.0:
			break
	await _frames(8)
	await _shot("2_orb_pull")
	# 3. The field: Nova flying in it, a fighter slowed (dim pip), a monster floating.
	await _scene()
	nova = _fighter("nova", 1, Vector2(-40, -2))
	foe = _fighter("luna", 2, Vector2(150, -2))
	var monster := CharacterBody2D.new()
	monster.set_script(MONSTER)
	monster.setup("mossling", 0, Vector2(-200, -40))
	arena.add_child(monster)
	await _frames(30)
	nova.skill_two()
	await _frames(16)
	# A player's Nova (a dummy does not fly), steered by the held key.
	nova.is_dummy = false
	nova.is_human = true
	nova.set_process_unhandled_input(false)
	Input.action_press("move_up")
	await _frames(14)
	Input.action_release("move_up")
	await _frames(20)
	await _shot("3_field")
	# 4. The beam dragging a fighter in.
	await _scene()
	nova = _fighter("nova", 1, Vector2(-300, -2))
	foe = _fighter("frey", 2, Vector2(60, -2))
	await _frames(20)
	nova.facing = 1
	nova.skill_three()
	await _frames(13)
	await _shot("4_beam_drag")
	# 5. The beam slamming a fighter down out of the air.
	await _scene()
	nova = _fighter("nova", 1, Vector2(-300, -2))
	var flyer := _fighter("rio", 2, Vector2(-150, -152))
	flyer._freeze_movement(2.0)
	await _frames(20)
	nova.facing = 1
	nova.ai_controller.aim_direction = Vector2(1, -1).normalized()
	nova.skill_three()
	await _frames(16)
	await _shot("5_beam_slam")
	# 6. A rooted fighter: three pips and the ring at its feet.
	await _scene()
	nova = _fighter("nova", 1, Vector2(-200, -2))
	foe = _fighter("luna", 2, Vector2(40, -2))
	await _frames(20)
	for stack in 3:
		foe.add_gravity_stack(nova)
	await _frames(10)
	await _shot("6_root")
	# 7. The sphere swinging two fighters round it.
	await _scene()
	nova = _fighter("nova", 1, Vector2(0, -2))
	foe = _fighter("frey", 2, Vector2(180, -2))
	other = _fighter("rio", 3, Vector2(-170, -2))
	await _frames(20)
	nova.ultimate()
	await _frames(40)
	await _shot("7_sphere")
	# 8. She circles it and launches; the sphere falls with its catch.
	nova.try_ultimate_followup()
	await _frames(12)
	nova.try_ultimate_followup()
	await _frames(8)
	await _shot("8_launch_fall")
	# 9. The sphere's burst on the floor.
	for frame in 60:
		await physics_frame
		if not nova.sphere_active:
			break
	await _frames(2)
	await _shot("9_sphere_burst")
	quit(0)

func _scene() -> void:
	if is_instance_valid(arena):
		arena.queue_free()
		await process_frame
	arena = Node2D.new()
	root.add_child(arena)
	camera = Camera2D.new()
	arena.add_child(camera)
	camera.make_current()
	camera.global_position = Vector2(0, -160)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2400, 40)
	shape.shape = rect
	body.add_child(shape)
	var look := ColorRect.new()
	look.size = Vector2(2400, 40)
	look.position = Vector2(-1200, -20)
	look.color = Color(0.22, 0.26, 0.34)
	body.add_child(look)
	arena.add_child(body)
	body.global_position = Vector2(0, 20)

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

func _until_ready(fighter: Node) -> void:
	for frame in 60:
		if fighter._can_start_attack() and fighter.is_on_floor():
			return
		await physics_frame

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out_dir, shot_name]
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
