extends SceneTree
## Lead capture for the pick cup round 2026-11-05-night (CODEX-VFX-08/09): the same scene for now / A / B of one item.
## A candidate is drawn over the game as it is, where and when its event happens; no game code changes:
##   frey-jump, luna-jump  takeoff from the floor and the air jump, at the feet (a tapped hop, then a held jump
##                         with an air jump at the top)
##   frey-land, luna-land  every landing, small (a fall under 130 px) or big
##   luna-star             each J star: the launch at its spawn point, the trail riding the star
##   luna-hit              each star that hits a standing fighter: the afterglow where its hit spark plays
## Windowed run at the match camera (0.85), one item and variant per run:
## <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_night_capture.gd -- --out=<dir> --item=frey-jump --variant=a

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const STAR_SCRIPT := preload("res://characters/luna/LunaStar.gd")
const CANDIDATE := "res://../art/bakeoff/effects/pixelfx/%s/%s/%s-%s"
const BIG_DROP := 130.0

var out_dir := "user://cup_night"
var item := "frey-jump"
var variant := "now"
var arena: Node2D
var camera: Camera2D
var actor: Node
var foe: Node
var strips := {}
var additive := CanvasItemMaterial.new()
# The actor's floor state, watched every physics frame.
var was_on_floor := true
var last_floor_position := Vector2.ZERO
var top_y := 0.0
var air_frames := 0
var last_air_jumps := 0
# Stars fired, oldest first (true for the big one), and the last afterglow time per foe.
var fired: Array[bool] = []
var last_glow_msec := -100000

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--item="):
			item = arg.substr(7)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	physics_frame.connect(_watch)
	match item:
		"frey-jump", "frey-land":
			await _scene_jumps("frey")
		"luna-jump", "luna-land":
			await _scene_jumps("luna")
		"luna-star":
			await _scene_volley(false)
		"luna-hit":
			await _scene_volley(true)
	print("CAPTURE_DONE ", out_dir)
	quit(0)

func _character() -> String:
	return item.get_slice("-", 0)

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

func _fighter(id: String, player_id: int, at: Vector2, human: bool) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id)
	arena.add_child(fighter)
	fighter.global_position = at
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, human)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = not human
	fighter.set_process_unhandled_input(false)
	return fighter

## A tapped hop, then a held jump with an air jump near the top.
func _scene_jumps(id: String) -> void:
	camera.global_position = Vector2(60, -150)
	actor = _fighter(id, 1, Vector2(0, -2), true)
	actor.facing = 1
	await _frames(30)
	_reset_watch()
	var shot := await _record(0, 10)
	shot = await _press("jump", 1, shot)
	shot = await _until_landed(shot)
	shot = await _record(shot, 12)
	shot = await _press("jump", 12, shot)
	shot = await _record(shot, 6)
	shot = await _press("jump", 1, shot)
	shot = await _until_landed(shot)
	await _record(shot, 24)

## Luna's J volley: three small stars and the big one to the right, then a star up (with a fighter to hit).
func _scene_volley(with_foe: bool) -> void:
	camera.global_position = Vector2(0, -60)
	actor = _fighter("luna", 1, Vector2(-150 if with_foe else -250, -2), false)
	actor.facing = 1
	if with_foe:
		foe = _fighter("rio", 2, Vector2(120, -2), false)
		foe.facing = -1
	await _frames(30)
	var shot := await _record(0, 6)
	for index in 5:
		while not actor._can_start_attack():
			shot = await _record(shot, 1)
		actor.perform_basic_attack("up" if index == 4 and not with_foe else "neutral", Vector2.RIGHT)
		shot = await _record(shot, 2)
	await _record(shot, 40)

## Holds the action for `shots` shots (two physics frames each), recording, then lets go.
func _press(action: String, shots: int, shot: int) -> int:
	Input.action_press(action)
	shot = await _record(shot, shots)
	Input.action_release(action)
	return shot

func _until_landed(shot: int) -> int:
	await _frames(4)
	for wait in 90:
		if actor.is_on_floor():
			break
		shot = await _record(shot, 1)
	return shot

func _reset_watch() -> void:
	was_on_floor = actor.is_on_floor()
	last_floor_position = actor.global_position
	top_y = actor.global_position.y
	air_frames = 0
	last_air_jumps = actor.air_jumps_left

## Runs before every physics step, so it sees the state the last step left.
func _watch() -> void:
	if not is_instance_valid(actor) or not item.ends_with("jump") and not item.ends_with("land"):
		return
	var on_floor: bool = actor.is_on_floor()
	if variant != "now":
		if item.ends_with("jump"):
			if was_on_floor and not on_floor and actor.velocity.y < -50.0:
				_overlay("%s_jump" % _character(), last_floor_position)
			elif not on_floor and actor.air_jumps_left < last_air_jumps:
				_overlay("%s_air_jump" % _character(), actor.global_position)
		elif on_floor and not was_on_floor and air_frames >= 7:
			var drop: float = actor.global_position.y - top_y
			_overlay("%s_land%s" % [_character(), "_big" if drop >= BIG_DROP else ""], actor.global_position)
	if on_floor:
		last_floor_position = actor.global_position
		top_y = actor.global_position.y
		air_frames = 0
	else:
		top_y = minf(top_y, actor.global_position.y)
		air_frames += 1
	was_on_floor = on_floor
	last_air_jumps = actor.air_jumps_left

func _on_spawned(node: Node) -> void:
	if node.get_script() == STAR_SCRIPT:
		_after_star.call_deferred(node)
	elif variant != "now" and item == "luna-hit" and node is AnimatedSprite2D and String(node.name).begins_with("HitSpark_luna") \
			and is_instance_valid(foe) and node.position.distance_to(foe.global_position + Vector2(0, -34)) < 2.0:
		# The big star's burst lands a second hit on the same foe right after the star: one afterglow.
		if Time.get_ticks_msec() - last_glow_msec < 150:
			return
		last_glow_msec = Time.get_ticks_msec()
		var big: bool = fired.pop_front() if not fired.is_empty() else false
		_overlay("luna_hit_after_big" if big else "luna_hit_after", node.position)

## The star is placed and told whether it is big after it joins the tree.
func _after_star(star: Node) -> void:
	if not is_instance_valid(star):
		return
	fired.append(bool(star.big))
	if variant == "now" or item != "luna-star":
		return
	var aim: Vector2 = star.direction
	var big_suffix := "_big" if star.big else ""
	_overlay("luna_star_launch" + big_suffix, (star as Node2D).global_position, aim)
	var trail := _overlay("luna_star_trail" + big_suffix, Vector2.ZERO, aim, star, true)
	if trail != null:
		trail.position = Vector2.ZERO

func _overlay(strip: String, at: Vector2, aim := Vector2.ZERO, parent: Node = null, loop := false) -> AnimatedSprite2D:
	var data: Array = _strip(strip, loop)
	if data.is_empty():
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = data[0]
	sprite.centered = false
	sprite.offset = -data[1]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 5
	if data[2]:
		sprite.material = additive
	if aim == Vector2.ZERO:
		sprite.scale = Vector2(-1.0 if actor.facing < 0 else 1.0, 1.0)
	elif aim.x < 0.0:
		# Drawn toward +x: mirrored and turned by the reversed aim, so up stays up.
		sprite.scale = Vector2(-1.0, 1.0)
		sprite.rotation = (-aim).angle()
	else:
		sprite.rotation = aim.angle()
	(parent if parent != null else arena).add_child(sprite)
	if parent == null:
		sprite.global_position = at
	sprite.play(&"play")
	if not loop:
		sprite.animation_finished.connect(sprite.queue_free)
	return sprite

## [SpriteFrames, anchor, additive] of a candidate strip and its json, or [] when the candidate has none.
func _strip(name: String, loop: bool) -> Array:
	var key := "%s/%s" % [name, loop]
	if strips.has(key):
		return strips[key]
	var base := ProjectSettings.globalize_path(CANDIDATE % [_character(), variant, name, variant])
	if not FileAccess.file_exists(base + ".png"):
		push_warning("no candidate strip %s" % base)
		strips[key] = []
		return []
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	var texture := ImageTexture.create_from_image(Image.load_from_file(base + ".png"))
	var count := int(meta.frames)
	var frames := SpriteFrames.new()
	frames.clear_all()
	frames.add_animation(&"play")
	frames.set_animation_speed(&"play", float(meta.fps))
	frames.set_animation_loop(&"play", loop)
	var width := texture.get_width() / count
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = texture
		frame.region = Rect2(index * width, 0, width, texture.get_height())
		frames.add_frame(&"play", frame)
	strips[key] = [frames, Vector2(float(meta.anchor[0]), float(meta.anchor[1])), str(meta.get("blend", "add")) == "add"]
	return strips[key]

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame

## Saves `count` shots, one every two physics frames (30 fps).
func _record(first: int, count: int) -> int:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for index in count:
		await _frames(2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, first + index])
	return first + count
