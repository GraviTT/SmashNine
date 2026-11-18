extends SceneTree
## Lead capture (2026-11-18, D50): Rio's kit v3 with its stand-in art: a backstab mark, the J3
## pierce, the thrown sword stuck in a foe and the blink behind it, the counter stance and the
## counter behind the attacker, the decoy and the step back, the gem swords stuck in two foes and a
## flurry cut.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/rio_kit_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://rio_kit"
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
	# 1. A hit from behind: 1.5x and the blue X.
	await _scene()
	var rio := _rio(Vector2(-90, -2))
	var foe := _fighter("frey", 2, Vector2(0, -2))
	await _frames(20)
	foe.facing = 1
	rio.facing = 1
	rio.basic_attack()
	await _frames(9)
	await _shot("1_backstab")
	# 2. J3 pierce: past the foe, turned to it.
	await _scene()
	rio = _rio(Vector2(-160, -2))
	foe = _fighter("nova", 2, Vector2(-40, -2))
	await _frames(20)
	foe.facing = -1
	rio.facing = 1
	for swing in 3:
		await _until_ready(rio)
		rio.facing = 1
		foe.global_position.x = rio.global_position.x + 90.0
		rio.basic_attack()
	await _frames(10)
	await _shot("2_pierce")
	# 3-4. K: the sword stuck in a foe, then the blink behind it.
	await _scene()
	rio = _rio(Vector2(-260, -2))
	foe = _fighter("luna", 2, Vector2(80, -2))
	await _frames(20)
	foe.facing = -1
	rio.facing = 1
	rio.skill_one()
	for frame in 60:
		if is_instance_valid(rio.thrown_sword) and rio.thrown_sword.stuck:
			break
		await physics_frame
	await _frames(3)
	await _shot("3_sword_stuck")
	await _until_ready(rio)
	rio.try_skill_one_followup()
	await _frames(3)
	await _shot("4_sword_blink")
	# 5-6. L: the stance, then the counter behind the attacker.
	await _scene()
	rio = _rio(Vector2(60, -2))
	var attacker := _fighter("frey", 2, Vector2(-40, -2))
	await _frames(20)
	attacker.facing = 1
	rio.facing = -1
	rio.skill_two()
	await _frames(6)
	await _shot("5_counter_stance")
	rio.apply_hit(attacker, 10.0, 400.0, Vector2.RIGHT)
	await _frames(12)
	await _shot("6_counter_strike")
	# 7. U: the decoy where he stood, Rio stepped back.
	await _scene()
	rio = _rio(Vector2(40, -2))
	foe = _fighter("nova", 2, Vector2(200, -2))
	await _frames(20)
	rio.facing = 1
	rio.skill_three()
	await _frames(4)
	await _shot("7_decoy")
	# 8-9. I: swords stuck in two foes, then a cut behind one.
	await _scene()
	rio = _rio(Vector2(0, -2))
	var near := _fighter("frey", 2, Vector2(200, -2))
	var far := _fighter("luna", 3, Vector2(-240, -2))
	await _frames(20)
	near.facing = -1
	far.facing = 1
	rio.ultimate()
	for frame in 90:
		if rio.flurry_phase == rio.Flurry.WAITING and rio._stuck_flurry_swords() == 6:
			break
		await physics_frame
	await _frames(4)
	await _shot("8_flurry_swords")
	rio.ultimate()
	await _frames(4)
	await _shot("9_flurry_cut")
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
	body.position = Vector2(0, 20)
	arena.add_child(body)

## Rio as a person whose keys nobody presses: no bot follow-ups.
func _rio(at: Vector2) -> Node:
	var rio: Node = PLAYER_FACTORY.create("rio", "male")
	arena.add_child(rio)
	rio.global_position = at
	rio.setup(CHARACTER_REGISTRY.get_characters()["rio"], 1, true)
	rio.set_process_unhandled_input(false)
	rio.ringout_y = 100000.0
	return rio

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
