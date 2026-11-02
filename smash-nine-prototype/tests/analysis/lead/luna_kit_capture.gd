extends SceneTree
## Lead capture (2026-11-03, D45): Luna's new kit with its stand-in art: the star volley and the
## mark, the warp burst, the barrier stopping a wave, the transformation bursting a mark, the Brave
## rush, the grab, the cyclone (spinning and fired) and the star beam.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/luna_kit_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://luna_kit"
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
	# 1. Star volley: four presses at a fighter; the last, big star in flight; the mark over her head.
	await _scene()
	var luna := _fighter("luna", 1, Vector2(-240, -2))
	var foe := _fighter("frey", 2, Vector2(120, -2))
	await _frames(20)
	luna.facing = 1
	for press in 3:
		await _until_ready(luna)
		luna.basic_attack()
	await _until_ready(luna)
	luna.basic_attack()
	await _frames(13)
	await _shot("1_star_volley")
	# 2. Warp: she reappears next to the fighter and bursts.
	await _scene()
	luna = _fighter("luna", 1, Vector2(-260, -2))
	foe = _fighter("frey", 2, Vector2(60, -2))
	await _frames(20)
	luna.facing = 1
	luna.skill_one()
	await _frames(11)
	await _shot("2_warp_burst")
	# 3. Barrier: Rio's wave stops at the rim.
	await _scene()
	luna = _fighter("luna", 1, Vector2(-120, -2))
	var rio := _fighter("rio", 2, Vector2(200, -2))
	await _frames(20)
	luna.skill_two()
	await _frames(20)
	rio.facing = -1
	_wave(rio)
	await _frames(9)
	await _shot("3_barrier")
	# 4. Transformation: the mark on a fighter far off bursts into a 3 s stun.
	await _scene()
	luna = _fighter("luna", 1, Vector2(-300, -2))
	foe = _fighter("frey", 2, Vector2(260, -2))
	await _frames(20)
	foe.apply_star_mark(luna, 10.0)
	luna.ultimate()
	await create_timer(luna.transform_time(8) + 0.06).timeout
	await _shot("4_mark_burst")
	# 5. Brave rush: the dash stops in front of the fighter and strikes.
	await _scene()
	luna = await _brave(Vector2(-200, -2))
	foe = _fighter("frey", 2, Vector2(-40, -2))
	await _frames(30)
	luna.facing = 1
	luna.perform_basic_attack("neutral", Vector2.RIGHT)
	await _frames(7)
	await _shot("5_brave_rush")
	# 6. Grab: the fighter held in front of her.
	await _scene()
	luna = await _brave(Vector2(-200, -2))
	foe = _fighter("frey", 2, Vector2(-40, -2))
	await _frames(30)
	luna.facing = 1
	luna.skill_one()
	await _frames(22)
	await _shot("6_grab")
	# 7. Cyclone spinning, a wave stopped at it.
	await _scene()
	luna = await _brave(Vector2(-120, -2))
	rio = _fighter("rio", 2, Vector2(220, -2))
	await _frames(30)
	luna.facing = 1
	luna.skill_two()
	await _frames(30)
	rio.facing = -1
	_wave(rio)
	await _frames(9)
	await _shot("7_cyclone_spin")
	# 8. The fired cyclone reaching a fighter (stunned, thrown up 2 s later).
	luna.try_skill_two_followup()
	await _frames(14)
	await _shot("8_cyclone_shot")
	# 9. Star beam.
	await _scene()
	luna = await _brave(Vector2(-320, -2))
	foe = _fighter("frey", 2, Vector2(-40, -2))
	await _frames(30)
	luna.facing = 1
	luna.try_ultimate_followup()
	await create_timer(1.2).timeout
	await _shot("9_star_beam")
	quit(0)

## Rio's mana wave as his J sends it (with its art), flying left.
func _wave(rio: Node) -> void:
	var wave: Node = rio._spawn_projectile(Vector2(24, 54), 6, 300, Vector2.LEFT, Color(0.5, 0.85, 1.0, 0.7), 640.0, 0.6)
	wave.set_art(rio.MANA_WAVE_ART, Color.WHITE, 1.0)

func _scene() -> void:
	if is_instance_valid(arena):
		arena.queue_free()
		await process_frame
	arena = Node2D.new()
	root.add_child(arena)
	camera = Camera2D.new()
	arena.add_child(camera)
	camera.make_current()
	camera.global_position = Vector2(0, -150)
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

func _brave(at: Vector2) -> Node:
	var luna := _fighter("luna", 1, at)
	await _frames(10)
	luna._enter_transformation()
	luna.transformation_timer = 60.0
	await _frames(50)
	return luna

func _until_ready(fighter: Node) -> void:
	for frame in 60:
		if fighter._can_start_attack():
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
