extends SceneTree
## Lead capture for the pick cup on Rio's kit v3 body rows (CODEX-SKM-08, 2026-11-27): one reel of his moves in a
## realm at the match camera (0.85), against a Frey dummy. "now" plays the rows the game has (the borrowed ones);
## "v1" (or another version) adds each candidate row found at `art/bakeoff/rio/rio_<body>-<row>-<variant>.png`
## (6 frames in 192-px cells) to his SpriteFrames as `rio_<row>`, which his code plays once it is there
## (Rio._kit_pose). No game code or game art changes. A frame every 2 physics frames (30 fps) goes to <out>/####.png.
## Windowed: <godot> --path . --fixed-fps 60 -s tests/analysis/lead/cup_rio_moves_capture.gd -- --out=<dir> --variant=v1 --body=male [--realm=niflheim]
## The reel: J three times (the third dashes through Frey), K (the throw), K again (the blink cut), L (the stance;
## Frey swings into it and Rio counters from behind), U (the decoy step back), I and I again (the flurry cuts).

const PLAYER_FACTORY := preload("res://scripts/PlayerFactory.gd")
const CHARACTER_REGISTRY := preload("res://characters/CharacterRegistry.gd")
const REALM_CATALOG := preload("res://scripts/realms/RealmCatalog.gd")
const CANDIDATE := "res://../art/bakeoff/rio/rio_%s-%s-%s"
const ROWS := ["sword_throw", "counter_stance", "pierce", "decoy_step", "flurry_cut"]
const REALM_SIZE := Vector2(1920, 1080)
const FLOOR_SIZE := Vector2(1400, 52)
const MOVE_CELL := 192

var out_dir := "user://cup_rio_moves"
var variant := "now"
var body := "male"
var realm := "niflheim"
var arena: Node2D
var camera: Camera2D
var rio: Node
var frey: Node
var tick := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
		elif arg.begins_with("--variant="):
			variant = arg.substr(10)
		elif arg.begins_with("--body="):
			body = arg.substr(7)
		elif arg.begins_with("--realm="):
			realm = arg.substr(8)
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(960, 540)
	RenderingServer.set_default_clear_color(Color(0.09, 0.11, 0.17))
	_stage()
	frey = _fighter("frey", "", 2, Vector2(60, -2))
	frey.facing = -1
	rio = PLAYER_FACTORY.create("rio", body)
	rio.position = Vector2(-80, -2)
	arena.add_child(rio)
	rio.setup(CHARACTER_REGISTRY.get_characters()["rio"], 1, true)
	rio.set_process_unhandled_input(false)
	rio.ringout_y = 100000.0
	rio.facing = 1
	if variant != "now":
		print("ADDED ", _add_rows())
	await _idle(30)
	DirAccess.make_dir_recursive_absolute(out_dir)
	# J three times: the third dashes through Frey.
	for swing in 3:
		await _until(func() -> bool: return rio._can_start_attack(), 60)
		rio.perform_basic_attack("neutral", Vector2.RIGHT * rio.facing)
		await _wait(6)
	await _wait(30)
	# K, then K again.
	await _reset_places(-200.0)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.perform_skill_one()
	await _until(func() -> bool: return is_instance_valid(rio.thrown_sword) and rio.thrown_sword.stuck, 90)
	await _wait(24)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.try_skill_one_followup()
	await _wait(36)
	# L: the stance, Frey swings into it, the counter from behind.
	await _reset_places(-90.0)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.counter_cooldown_timer = 0.0
	rio.perform_skill_two()
	await _wait(14)
	rio.apply_hit(frey, 12.0, 300.0, Vector2.LEFT)
	await _wait(36)
	# U: the decoy and the step back.
	await _reset_places(-90.0)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.decoy_cooldown_timer = 0.0
	rio.perform_skill_three()
	await _wait(40)
	# I, then I again: the flurry cuts.
	await _reset_places(-200.0)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.ultimate_cooldown_timer = 0.0
	rio.ultimate()
	await _wait(40)
	await _until(func() -> bool: return rio._can_start_attack(), 60)
	rio.ultimate()
	await _wait(90)
	print("CAPTURE_DONE ", out_dir, " frames ", tick / 2)
	quit(0)

## Rio back on the left facing Frey on the right, between the moves (recorded, so the reel shows the cut).
func _reset_places(rio_x: float) -> void:
	await _wait(4)
	rio.global_position = Vector2(rio_x, -2)
	rio.velocity = Vector2.ZERO
	rio.facing = 1
	frey.global_position = Vector2(60, -2)
	frey.velocity = Vector2.ZERO
	frey.facing = -1
	frey.hp = frey.max_hp
	await _wait(10)

## Each candidate row becomes `rio_<row>` in his SpriteFrames: its fps from the .json, else the card's.
func _add_rows() -> Array[String]:
	var added: Array[String] = []
	var frames: SpriteFrames = rio.character_sprite.sprite_frames
	var card_fps := {"sword_throw": 20.0, "counter_stance": 15.0, "pierce": 20.0, "decoy_step": 16.0, "flurry_cut": 24.0}
	for row in ROWS:
		var base := CANDIDATE % [body, row, variant]
		var path := ProjectSettings.globalize_path(base + ".png")
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(path)
		if image == null or image.is_empty():
			continue
		var fps := float(card_fps.get(row, 20.0))
		var meta_path := ProjectSettings.globalize_path(base + ".json")
		if FileAccess.file_exists(meta_path):
			var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
			if meta is Dictionary:
				fps = float(meta.get("fps", fps))
		var texture := ImageTexture.create_from_image(image)
		var animation := StringName("rio_%s" % row)
		if frames.has_animation(animation):
			frames.remove_animation(animation)
		frames.add_animation(animation)
		frames.set_animation_speed(animation, fps)
		frames.set_animation_loop(animation, false)
		for index in int(image.get_width() / MOVE_CELL):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(index * MOVE_CELL, 0, MOVE_CELL, MOVE_CELL)
			frames.add_frame(animation, atlas)
		added.append(row)
	return added

func _wait(count: int) -> void:
	for frame in count:
		await physics_frame
		tick += 1
		if tick % 2 == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%04d.png" % [out_dir, tick / 2 - 1])

func _until(condition: Callable, limit: int) -> void:
	for frame in limit:
		if condition.call():
			return
		await _wait(1)

func _idle(count: int) -> void:
	for frame in count:
		await physics_frame

func _stage() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	var dir := "res://assets/art/realm_%s" % realm
	var map := _realm_map(dir)
	var art: Dictionary = map.get("art", {})
	var layer := 0
	for name in ["bg_far", "bg_mid"]:
		var texture := load("%s/%s.png" % [dir, name]) as Texture2D
		if texture == null:
			continue
		var rect := TextureRect.new()
		rect.texture = texture
		rect.position = Vector2(-REALM_SIZE.x * 0.5, -REALM_SIZE.y * 0.62)
		rect.size = REALM_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.z_index = -19 + layer
		arena.add_child(rect)
		layer += 1
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, float(art.get("dim", 0.0)))
	shade.position = Vector2(-REALM_SIZE.x * 0.5, -REALM_SIZE.y * 0.62)
	shade.size = REALM_SIZE
	shade.z_index = -19 + layer
	arena.add_child(shade)
	camera = Camera2D.new()
	camera.zoom = Vector2(0.85, 0.85)
	arena.add_child(camera)
	camera.make_current()
	camera.global_position = Vector2(-40, -130)
	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = FLOOR_SIZE
	shape.shape = box
	floor_body.add_child(shape)
	var floor_art := load("%s/platform_main.png" % dir) as Texture2D
	if floor_art != null:
		var strip := NinePatchRect.new()
		strip.texture = floor_art
		strip.patch_margin_left = int(art.get("cap_main", 16))
		strip.patch_margin_right = int(art.get("cap_main", 16))
		strip.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		strip.position = -box.size * 0.5
		strip.size = box.size
		floor_body.add_child(strip)
	var accent: Color = map.get("accent", Color.WHITE)
	var edge := ColorRect.new()
	edge.color = Color(accent.r, accent.g, accent.b, 0.72)
	edge.size = Vector2(FLOOR_SIZE.x, 5.0)
	edge.position = -FLOOR_SIZE * 0.5
	floor_body.add_child(edge)
	floor_body.position = Vector2(0, FLOOR_SIZE.y * 0.5)
	arena.add_child(floor_body)

func _realm_map(dir: String) -> Dictionary:
	for map in REALM_CATALOG.build_maps():
		if str(map.get("art", {}).get("dir", "")) == dir:
			return map
	return {}

func _fighter(id: String, body_type: String, player_id: int, at: Vector2) -> Node:
	var fighter: Node = PLAYER_FACTORY.create(id, body_type)
	fighter.position = at
	arena.add_child(fighter)
	fighter.setup(CHARACTER_REGISTRY.get_characters()[id], player_id, false)
	fighter.ringout_y = 100000.0
	fighter.is_dummy = true
	fighter.invulnerable_timer = 0.0
	fighter.set_process_unhandled_input(false)
	return fighter
