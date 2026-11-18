extends SceneTree
## Lead capture (2026-11-18, D51): Xion's kit with its stand-in art: a J blast, a point-blank hit,
## the reload roll, the recoil jump, the doppelganger hunting and pinning, the dive, the
## Equilibrium barrage, and the reload ring over her head.
## Windowed run (not headless): <godot> --path . -s tests/analysis/lead/xion_kit_capture.gd -- --out=<dir>

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")

var out_dir := "user://xion_kit"
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
	# 1. J: the blast at a foe 150 px away.
	await _scene()
	var xion := _xion(Vector2(-120, -2))
	var foe := _fighter("frey", 2, Vector2(30, -2))
	await _frames(20)
	xion.facing = 1
	xion.basic_attack()
	await _frames(5)
	await _shot("1_shot")
	# 2. Point blank: 2x and the crimson burst.
	await _scene()
	xion = _xion(Vector2(-20, -2))
	foe = _fighter("nova", 2, Vector2(30, -2))
	await _frames(20)
	xion.facing = 1
	xion.basic_attack()
	await _frames(7)
	await _shot("2_point_blank")
	# 3. K: the roll.
	await _scene()
	xion = _xion(Vector2(-120, -2))
	await _frames(20)
	xion.facing = 1
	xion.ammo = 4
	xion.skill_one()
	await _frames(9)
	await _shot("3_roll")
	# 4. L: every round down, she rises.
	await _scene()
	xion = _xion(Vector2(0, -2))
	foe = _fighter("luna", 2, Vector2(40, -2))
	await _frames(20)
	xion.skill_two()
	await _frames(8)
	await _shot("4_recoil")
	# 5-6. U: the doppelganger hunts the foe she hit, then sits on its head.
	await _scene()
	xion = _xion(Vector2(-260, -2))
	foe = _fighter("rio", 2, Vector2(160, -2))
	await _frames(20)
	xion.facing = 1
	xion.last_hit_foe = foe
	xion.skill_three()
	await _frames(70)
	await _shot("5_double_hunt")
	for frame in 180:
		if foe.is_pinned():
			break
		await physics_frame
	await _frames(10)
	await _shot("6_double_pin")
	# 7. U again: the dive to the doppelganger.
	xion.try_skill_three_followup()
	await _frames(6)
	await _shot("7_dive")
	# 8. I: shots all round, the doppelganger too.
	await _scene()
	xion = _xion(Vector2(-60, -2))
	var left := _fighter("frey", 2, Vector2(-240, -2))
	var right := _fighter("luna", 3, Vector2(200, -2))
	await _frames(20)
	xion.last_hit_foe = right
	xion.skill_three()
	await _frames(40)
	xion.ultimate_cooldown_timer = 0.0
	xion.ultimate()
	await _frames(24)
	await _shot("8_barrage")
	# 9. The reload ring over her head after the last round.
	await _scene()
	xion = _xion(Vector2(0, -2))
	await _frames(20)
	xion.facing = 1
	xion.ammo = 1
	xion.basic_attack()
	await _frames(70)
	await _shot("9_reload")
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

## Xion as a person whose keys nobody presses: no bot follow-ups.
func _xion(at: Vector2) -> Node:
	var xion: Node = PLAYER_FACTORY.create("xion")
	arena.add_child(xion)
	xion.global_position = at
	xion.setup(CHARACTER_REGISTRY.get_characters()["xion"], 1, true)
	xion.set_process_unhandled_input(false)
	xion.ringout_y = 100000.0
	return xion

func _fighter(character_id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(character_id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[character_id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	fighter.invulnerable_timer = 0.0
	return fighter

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out_dir, shot_name]
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
