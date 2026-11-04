extends SceneTree
## Lead capture (2026-11-04) for the pick cup round of the Frey pilot (CODEX-VFX-07). The same scenes for now / A / B:
##   j    Frey's up and down J on the ground, then her side, up and down J in the air (the ground chain already
##        has its sparks in the game)
##   hit  Frey's J chain twice on a standing fighter: cuts 1 and 2 are normal hits, cut 3 a strong one
## A candidate is drawn over the game as it is: its strip from art/bakeoff/effects/pixelfx/frey/<a|b>/ starts
## where and when the game's slash strip or the struck fighter's hit spark starts. No game code changes.
## Windowed run at the match camera (0.85), one scene and variant per run:
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_frey_pilot_capture.gd -- --out=<dir> --scene=j --variant=a

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const CANDIDATE := "res://../art/bakeoff/effects/pixelfx/frey/%s/%s-%s"
const J_STRIPS := {"up": "frey_jfx_up", "air_up": "frey_jfx_up_air", "down": "frey_jfx_down", "air_down": "frey_jfx_down_air", "air_side": "frey_jfx_side_air"}

var out_dir := "user://cup_frey"
var scene_name := "j"
var variant := "now"
var arena: Node2D
var camera: Camera2D
var frey: Node
var foe: Node
## The move under way, set before Frey starts it ("up", "air_side", "chain3"...).
var move := ""
var strips := {}
var additive := CanvasItemMaterial.new()

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--scene="):
			scene_name = arg.substr(8)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	if scene_name == "hit":
		await _scene_hit()
	else:
		await _scene_j()
	print("CAPTURE_DONE ", out_dir)
	quit(0)

func _stage() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	arena.child_entered_tree.connect(_on_spawned)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	arena.add_child(camera)
	camera.make_current()
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8000, 40)
	shape.shape = rect
	body.add_child(shape)
	var look := ColorRect.new()
	look.size = Vector2(8000, 40)
	look.position = Vector2(-4000, -20)
	look.color = Color(0.22, 0.26, 0.34)
	body.add_child(look)
	arena.add_child(body)
	body.global_position = Vector2(0, 20)

func _fighter(id: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	return fighter

func _scene_j() -> void:
	frey = _fighter("frey", 1, Vector2(0, -2))
	frey.facing = 1
	await _frames(30)
	var shot := await _record(0, 6)
	for step in [["up", false], ["down", false], ["air_side", true], ["air_up", true], ["air_down", true]]:
		if step[1]:
			frey.velocity.y = frey.jump_velocity
			shot = await _record(shot, 7)
		shot = await _until_ready(shot)
		move = step[0]
		frey.perform_basic_attack(move, Vector2.UP if move.ends_with("up") else (Vector2.DOWN if move.ends_with("down") else Vector2.RIGHT))
		shot = await _record(shot, 28)
	await _record(shot, 10)

func _scene_hit() -> void:
	frey = _fighter("frey", 1, Vector2(-70, -2))
	foe = _fighter("rio", 2, Vector2(40, -2))
	frey.facing = 1
	foe.facing = -1
	await _frames(30)
	var shot := await _record(0, 6)
	for round in 2:
		for cut in 3:
			shot = await _until_ready(shot)
			move = "chain%d" % (cut + 1)
			frey.perform_basic_attack("neutral", Vector2.RIGHT)
			shot = await _record(shot, 4)
		shot = await _record(shot, 34)
		# Back in front of her for the second chain.
		frey.global_position = Vector2(-70, -2)
		frey.velocity = Vector2.ZERO
		foe.global_position = Vector2(40, -2)
		foe.velocity = Vector2.ZERO
		foe.hitstun_timer = 0.0
		shot = await _record(shot, 6)
	await _record(shot, 6)

func _until_ready(shot: int) -> int:
	for wait in 60:
		if frey._can_start_attack():
			break
		shot = await _record(shot, 1)
	return shot

## Draws the candidate's strip where the game's own drawing starts.
func _on_spawned(node: Node) -> void:
	if variant == "now" or not (node is AnimatedSprite2D):
		return
	if _atlas_name(node) == "frey_slash" and J_STRIPS.has(move):
		_after_slash.call_deferred(node, J_STRIPS[move])
	elif String(node.name).begins_with("HitSpark_frey") and is_instance_valid(foe) and node.position.distance_to(foe.global_position + Vector2(0, -34)) < 2.0:
		_overlay("frey_hit_after_big" if move == "chain3" else "frey_hit_after", node.position)

## Vfx.spawn places the slash after adding it, so the candidate starts on the next idle moment of this frame.
func _after_slash(node: Node, strip: String) -> void:
	if is_instance_valid(node):
		_overlay(strip, (node as Node2D).global_position)

func _atlas_name(node: AnimatedSprite2D) -> String:
	if node.sprite_frames == null or not node.sprite_frames.has_animation(&"play"):
		return ""
	var frame := node.sprite_frames.get_frame_texture(&"play", 0) as AtlasTexture
	return frame.atlas.resource_path.get_file().get_basename() if frame != null and frame.atlas != null else ""

func _overlay(strip: String, at: Vector2) -> void:
	var data: Array = _strip(strip)
	if data.is_empty():
		return
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = data[0]
	sprite.centered = false
	sprite.offset = -data[1]
	sprite.scale = Vector2(-1.0 if frey.facing < 0 else 1.0, 1.0)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 5
	sprite.material = additive
	arena.add_child(sprite)
	sprite.global_position = at
	sprite.play(&"play")
	sprite.animation_finished.connect(sprite.queue_free)

## [SpriteFrames, anchor] of a candidate strip and its json, or [] when the candidate has none.
func _strip(name: String) -> Array:
	if strips.has(name):
		return strips[name]
	var base := ProjectSettings.globalize_path(CANDIDATE % [variant, name, variant])
	if not FileAccess.file_exists(base + ".png"):
		push_warning("no candidate strip %s" % base)
		strips[name] = []
		return []
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	var texture := ImageTexture.create_from_image(Image.load_from_file(base + ".png"))
	var count := int(meta.frames)
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", float(meta.fps))
	frames.set_animation_loop(&"play", false)
	var width := texture.get_width() / count
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * width, 0, width, texture.get_height())
		frames.add_frame(&"play", frame)
	strips[name] = [frames, Vector2(float(meta.anchor[0]), float(meta.anchor[1]))]
	return strips[name]

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## Saves `count` shots, one every two physics frames (30 fps).
func _record(first: int, count: int) -> int:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for index in count:
		await _frames(2)
		if scene_name == "hit":
			camera.global_position = Vector2(60, -70)
		else:
			camera.global_position = Vector2(frey.global_position.x + 30, -150)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, first + index])
	return first + count
